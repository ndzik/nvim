local M = {
  ns = vim.api.nvim_create_namespace("intent"),
  artifact = nil,
  artifact_path = nil,
  items_by_id = {},
  qf_index_to_id = {},
  selected_item_id = nil,
  detail_bufnr = nil,
  detail_winnr = nil,
  picker_open = false,
  watch_timer = nil,
  watch_path = nil,
  watch_mtime = nil,
  watch_latest = false,
}

local open_picker

-- Public API / commands exposed by this module:
--   :IntentRender {path}      -> load one exported Intent JSON artifact
--   :IntentRenderLatest       -> load the newest ~/.pi/agent/intents/*/latest.json
--   :IntentWatchStart [path]  -> poll and render a JSON artifact, or newest latest.json
--   :IntentWatchStop          -> stop Intent artifact polling
--   :IntentPick               -> open the Telescope item picker
--   :IntentQuickfix           -> put items into quickfix
--   :IntentDetail             -> show detail for the selected/current item
--   :IntentNext / :IntentPrev -> jump between resolved anchors
--   :IntentClear              -> clear rendered state
-- The helpers below are grouped by the private concern they support.

-- Basic utilities ------------------------------------------------------------

local function uv()
  return vim.uv or vim.loop
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function agent_dir()
  return vim.fn.expand(vim.env.PI_CODING_AGENT_DIR or "~/.pi/agent")
end

local function read_json_file(path)
  local ok_read, lines = pcall(vim.fn.readfile, path)
  if not ok_read or not lines or #lines == 0 then
    return nil, "failed to read " .. tostring(path)
  end

  local ok_decode, value = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(value) ~= "table" then
    return nil, "failed to decode JSON from " .. tostring(path)
  end

  return value, nil
end

local function path_mtime(path)
  local stat = type(path) == "string" and uv().fs_stat(path) or nil
  if not stat or not stat.mtime then return nil end
  return (stat.mtime.sec or 0) * 1000000000 + (stat.mtime.nsec or 0)
end

local function normalize_path(path)
  if not path or path == "" then return nil end
  return vim.fn.fnamemodify(path, ":p")
end

local function join_path(base, child)
  if not base or base == "" then return child end
  return base:gsub("/$", "") .. "/" .. child:gsub("^/", "")
end

-- Artifact path helpers ------------------------------------------------------

local function artifact_cwd(artifact)
  if type(artifact) == "table" and type(artifact.source) == "table" and type(artifact.source.cwd) == "string" then
    return artifact.source.cwd
  end
  return nil
end

local function artifact_source_path(artifact)
  if type(artifact) == "table" and type(artifact.source) == "table" and type(artifact.source.path) == "string" then
    return artifact.source.path
  end
  return nil
end

local function resolve_artifact_path(artifact, path)
  if type(path) ~= "string" or path == "" then return nil end
  if vim.fn.fnamemodify(path, ":p") == path or path:sub(1, 1) == "/" then
    return normalize_path(path)
  end
  local cwd = artifact_cwd(artifact)
  if cwd and cwd ~= "" then
    return normalize_path(join_path(cwd, path))
  end
  return normalize_path(path)
end

-- Intent item helpers --------------------------------------------------------

local function operation_kind(operation)
  if type(operation) == "table" and type(operation.kind) == "string" then
    return operation.kind
  end
  return "?"
end

local function item_label(item)
  return string.format("[%s/%s] %s", tostring(item.role or "?"), operation_kind(item.operation), tostring(item.summary or ""))
end

local function picker_label(item)
  return string.format(
    "[%s/%s/%s] %s — %s",
    tostring(item.role or "?"),
    operation_kind(item.operation),
    tostring(item.status or "?"),
    tostring(item.id or "?"),
    tostring(item.summary or "")
  )
end

local function item_resolution(item)
  if type(item) == "table" and type(item.resolution) == "table" then
    return item.resolution
  end
  return { status = "unresolved", reason = "missing resolution" }
end

local function is_resolved(item)
  return item_resolution(item).status == "resolved"
end

local function item_resolved_path(artifact, item)
  local resolution = item_resolution(item)
  if resolution.status ~= "resolved" or type(resolution.path) ~= "string" then
    return nil
  end
  return resolve_artifact_path(artifact, resolution.path)
end

local function item_start_position(item)
  local resolution = item_resolution(item)
  local range = type(resolution.range) == "table" and resolution.range or nil
  local start = range and range.start or nil
  local line = type(start) == "table" and tonumber(start.line) or nil
  local column = type(start) == "table" and tonumber(start.column) or nil
  return math.max(line or 1, 1), math.max(column or 1, 1)
end

local function validate_artifact(artifact)
  if type(artifact) ~= "table" then
    return false, "artifact must be a JSON object"
  end
  if artifact.schema ~= "intent-export" then
    return false, "unsupported intent schema: " .. tostring(artifact.schema)
  end
  if artifact.schemaVersion ~= 0 then
    return false, "unsupported intent schemaVersion: " .. tostring(artifact.schemaVersion)
  end
  if type(artifact.items) ~= "table" then
    return false, "artifact.items must be an array"
  end
  return true, nil
end

-- State cleanup --------------------------------------------------------------

local function clear_detail()
  if M.detail_winnr and vim.api.nvim_win_is_valid(M.detail_winnr) then
    pcall(vim.api.nvim_win_close, M.detail_winnr, true)
  end
  if M.detail_bufnr and vim.api.nvim_buf_is_valid(M.detail_bufnr) then
    pcall(vim.api.nvim_buf_delete, M.detail_bufnr, { force = true })
  end
  M.detail_winnr = nil
  M.detail_bufnr = nil
end

local function clear_extmarks()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_clear_namespace, bufnr, M.ns, 0, -1)
    end
  end
end

local function reset_state(keep_artifact)
  clear_detail()
  clear_extmarks()
  M.items_by_id = {}
  M.qf_index_to_id = {}
  M.selected_item_id = nil
  M.picker_open = false
  if not keep_artifact then
    M.artifact = nil
    M.artifact_path = nil
  end
end

local function buffer_path_matches(artifact, bufnr, item)
  local buffer_path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
  local item_path = item_resolved_path(artifact, item)
  return buffer_path ~= nil and item_path ~= nil and buffer_path == item_path
end

-- Inline extmark rendering ---------------------------------------------------

local function role_highlight(role)
  local highlights = {
    entrypoint = "DiagnosticInfo",
    context = "Comment",
    work = "DiagnosticHint",
    invariant = "DiagnosticOk",
    risk = "DiagnosticWarn",
    test = "DiagnosticInfo",
    question = "DiagnosticWarn",
    review = "DiagnosticInfo",
  }
  return highlights[role] or "Comment"
end

local function wrap_text(text, width)
  text = tostring(text or "")
  width = math.max(width or 80, 20)
  local lines = {}

  for raw_line in text:gmatch("[^\n]+") do
    local current = ""
    for word in raw_line:gmatch("%S+") do
      if current == "" then
        current = word
      elseif #current + 1 + #word <= width then
        current = current .. " " .. word
      else
        lines[#lines + 1] = current
        current = word
      end
    end
    if current ~= "" then
      lines[#lines + 1] = current
    end
  end

  if #lines == 0 then
    lines[1] = ""
  end

  return lines
end

local function intent_virtual_lines(item)
  local win_width = math.max(vim.api.nvim_win_get_width(0), 40)
  local text_width = math.max(math.min(win_width - 10, 96), 30)
  local label = string.format("󰐕 intent [%s/%s]: ", tostring(item.role or "?"), operation_kind(item.operation))
  local summary_lines = wrap_text(tostring(item.summary or item.id or "item"), text_width - #label)
  local lines = {}
  local highlight = role_highlight(item.role)

  for index, line in ipairs(summary_lines) do
    if index == 1 then
      lines[#lines + 1] = {
        { label, "NonText" },
        { line, highlight },
      }
    else
      lines[#lines + 1] = {
        { string.rep(" ", #label), "NonText" },
        { line, highlight },
      }
    end
  end

  return lines
end

local function render_extmarks_for_buffer(bufnr)
  local artifact = M.artifact
  if not artifact then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  pcall(vim.api.nvim_buf_clear_namespace, bufnr, M.ns, 0, -1)

  for _, item in ipairs(artifact.items or {}) do
    if is_resolved(item) and buffer_path_matches(artifact, bufnr, item) then
      local line, column = item_start_position(item)
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local lnum0 = math.max(math.min(line, line_count), 1) - 1
      local col0 = math.max(column - 1, 0)
      pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, lnum0, col0, {
        virt_lines = intent_virtual_lines(item),
        virt_lines_above = false,
        hl_mode = "combine",
      })
    end
  end
end

local function render_extmarks()
  clear_extmarks()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      render_extmarks_for_buffer(bufnr)
    end
  end
end

-- Quickfix rendering ---------------------------------------------------------

local function quickfix_fallback_path(artifact)
  local source_path = artifact_source_path(artifact)
  if source_path and source_path ~= "" then return source_path end
  return M.artifact_path or ""
end

local function build_quickfix_items(artifact, items)
  local qf_items = {}
  M.qf_index_to_id = {}

  for index, item in ipairs(items or artifact.items or {}) do
    local resolution = item_resolution(item)
    local filename = quickfix_fallback_path(artifact)
    local lnum, col = 1, 1

    if resolution.status == "resolved" then
      filename = item_resolved_path(artifact, item) or filename
      lnum, col = item_start_position(item)
    end

    if resolution.status ~= "resolved" then
      local suffix = resolution.reason and (" (" .. resolution.status .. ": " .. resolution.reason .. ")") or (" (" .. resolution.status .. ")")
      qf_items[#qf_items + 1] = {
        filename = filename,
        lnum = lnum,
        col = col,
        text = item_label(item) .. suffix,
      }
    else
      qf_items[#qf_items + 1] = {
        filename = filename,
        lnum = lnum,
        col = col,
        text = item_label(item),
      }
    end

    M.qf_index_to_id[index] = item.id
  end

  return qf_items
end

local function render_quickfix(artifact, items, open_window)
  local title = "Intent: " .. tostring((artifact.plan and artifact.plan.title) or M.artifact_path or "plan")
  local selected_items = items or artifact.items or {}
  vim.fn.setqflist({}, "r", {
    title = title,
    items = build_quickfix_items(artifact, selected_items),
  })
  if open_window and #selected_items > 0 then
    vim.cmd("copen")
  end
end

-- Artifact rendering entry points -------------------------------------------

local function index_items(artifact)
  M.items_by_id = {}
  for _, item in ipairs(artifact.items or {}) do
    if type(item.id) == "string" then
      M.items_by_id[item.id] = item
    end
  end
end

local function render_artifact(artifact, artifact_path, opts)
  opts = opts or {}
  local ok, err = validate_artifact(artifact)
  if not ok then
    notify(err, vim.log.levels.ERROR)
    return false
  end

  reset_state(true)
  M.artifact = artifact
  M.artifact_path = artifact_path
  index_items(artifact)
  render_extmarks()

  notify(string.format("Rendered Intent plan (%d items)", #(artifact.items or {})))

  if opts.open_picker and open_picker and #vim.api.nvim_list_uis() > 0 then
    open_picker()
  end

  return true
end

function M.render(path, opts)
  opts = opts or { open_picker = true }
  if opts.open_picker == nil then opts.open_picker = true end
  path = vim.fn.expand(path or "")
  if path == "" then
    notify("IntentRender requires a JSON artifact path", vim.log.levels.ERROR)
    return
  end

  local artifact, err = read_json_file(path)
  if not artifact then
    notify(err, vim.log.levels.ERROR)
    return
  end

  return render_artifact(artifact, normalize_path(path), opts)
end

function M.quickfix(items)
  if not M.artifact then
    notify("No Intent artifact loaded", vim.log.levels.WARN)
    return
  end
  render_quickfix(M.artifact, items, true)
end

local function stop_watch_timer()
  if M.watch_timer then
    pcall(function()
      M.watch_timer:stop()
      M.watch_timer:close()
    end)
  end
  M.watch_timer = nil
  M.watch_path = nil
  M.watch_mtime = nil
  M.watch_latest = false
end

function M.clear()
  stop_watch_timer()
  reset_state(false)
  vim.fn.setqflist({}, "r", { title = "Intent", items = {} })
  notify("Intent cleared")
end

local function newest_latest_json()
  local files = vim.fn.glob(agent_dir() .. "/intents/*/latest.json", false, true)
  local newest_path = nil
  local newest_mtime = nil

  for _, path in ipairs(files or {}) do
    local mtime = path_mtime(path)
    if mtime and (not newest_mtime or mtime > newest_mtime) then
      newest_path = path
      newest_mtime = mtime
    end
  end

  return newest_path, newest_mtime
end

function M.render_latest(opts)
  local path = newest_latest_json()
  if not path then
    notify("No Intent latest.json found under " .. agent_dir() .. "/intents", vim.log.levels.WARN)
    return
  end
  return M.render(path, opts)
end

local function watch_target()
  if M.watch_latest then
    local path = newest_latest_json()
    return path and normalize_path(path) or nil
  end
  return M.watch_path
end

local function render_watch_target_if_changed(force)
  local path = watch_target()
  if not path then return end

  local mtime = path_mtime(path)
  if force or path ~= M.watch_path or (mtime and mtime ~= M.watch_mtime) then
    M.watch_path = path
    M.watch_mtime = mtime
    M.render(path, { open_picker = false })
  end
end

function M.watch_start(path)
  stop_watch_timer()

  local expanded = vim.fn.expand(path or "")
  M.watch_latest = expanded == ""
  M.watch_path = M.watch_latest and nil or normalize_path(expanded)

  if M.watch_latest and not newest_latest_json() then
    notify("No Intent latest.json found under " .. agent_dir() .. "/intents", vim.log.levels.WARN)
    stop_watch_timer()
    return false
  end

  if not M.watch_latest and not path_mtime(M.watch_path) then
    notify("Intent watch target does not exist: " .. tostring(M.watch_path), vim.log.levels.ERROR)
    stop_watch_timer()
    return false
  end

  render_watch_target_if_changed(true)

  M.watch_timer = uv().new_timer()
  M.watch_timer:start(1000, 1000, vim.schedule_wrap(function()
    render_watch_target_if_changed(false)
  end))

  notify("Intent watch started: " .. (M.watch_latest and "newest latest.json" or tostring(M.watch_path)))
  return true
end

function M.watch_stop(opts)
  local was_watching = M.watch_timer ~= nil
  stop_watch_timer()
  if not (opts and opts.quiet) then
    notify(was_watching and "Intent watch stopped" or "Intent watch was not running")
  end
end

-- Current item selection and detail popup -----------------------------------

local function current_qf_item()
  local ok, qf = pcall(vim.fn.getqflist, { idx = 0, items = 0 })
  if not ok or type(qf) ~= "table" then return nil end
  local idx = tonumber(qf.idx) or 0
  local item_id = M.qf_index_to_id[idx]
  if item_id and M.items_by_id[item_id] then
    return M.items_by_id[item_id]
  end
  return nil
end

local function current_buffer_item()
  local artifact = M.artifact
  if not artifact then return nil end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]

  for _, item in ipairs(artifact.items or {}) do
    if is_resolved(item) and buffer_path_matches(artifact, bufnr, item) then
      local resolution = item_resolution(item)
      local range = resolution.range or {}
      local start = range.start or {}
      local finish = range["end"] or start
      local start_line = tonumber(start.line) or 1
      local end_line = tonumber(finish.line) or start_line
      if cursor_line >= start_line and cursor_line <= end_line then
        return item
      end
    end
  end

  return nil
end

local function current_item()
  if M.selected_item_id and M.items_by_id[M.selected_item_id] then
    return M.items_by_id[M.selected_item_id]
  end
  return current_qf_item() or current_buffer_item()
end

local function inspect_inline(value)
  if value == nil then return "nil" end
  return vim.inspect(value, { newline = " ", indent = "" })
end

local function detail_lines(item)
  local lines = {
    "# Intent Item",
    "",
    "id: " .. tostring(item.id or ""),
    "role: " .. tostring(item.role or ""),
    "operation: " .. inspect_inline(item.operation),
    "status: " .. tostring(item.status or ""),
    "priority: " .. tostring(item.priority or ""),
    "",
    "## Summary",
    tostring(item.summary or ""),
  }

  if item.detail then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Detail"
    for _, line in ipairs(vim.split(tostring(item.detail), "\n", { plain = true })) do
      lines[#lines + 1] = line
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Dependencies"
  lines[#lines + 1] = inspect_inline(item.dependsOn)
  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Anchor"
  lines[#lines + 1] = inspect_inline(item.anchor)
  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Resolution"
  lines[#lines + 1] = inspect_inline(item.resolution)

  return lines
end

local function open_detail(item)
  if not item then
    notify("No Intent item selected", vim.log.levels.WARN)
    return
  end

  if item.id then M.selected_item_id = item.id end
  clear_detail()

  local width = math.min(100, math.max(60, math.floor(vim.o.columns * 0.65)))
  local height = math.min(24, math.max(10, math.floor(vim.o.lines * 0.55)))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  M.detail_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[M.detail_bufnr].buftype = "nofile"
  vim.bo[M.detail_bufnr].bufhidden = "wipe"
  vim.bo[M.detail_bufnr].swapfile = false
  vim.bo[M.detail_bufnr].filetype = "markdown"

  M.detail_winnr = vim.api.nvim_open_win(M.detail_bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Intent Detail ",
    title_pos = "center",
  })

  vim.wo[M.detail_winnr].wrap = true
  vim.wo[M.detail_winnr].linebreak = true

  vim.bo[M.detail_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(M.detail_bufnr, 0, -1, false, detail_lines(item))
  vim.bo[M.detail_bufnr].modifiable = false

  vim.keymap.set("n", "q", clear_detail, { buffer = M.detail_bufnr, silent = true })
  vim.keymap.set("n", "<Esc>", clear_detail, { buffer = M.detail_bufnr, silent = true })
end

function M.detail()
  local item = current_item()
  if not item then
    notify("No Intent item at current picker/quickfix/cursor location", vim.log.levels.WARN)
    return
  end
  open_detail(item)
end

local function jump_to_item(item)
  if not item then return false end
  if item.id then M.selected_item_id = item.id end

  if not is_resolved(item) then
    open_detail(item)
    return false
  end

  local path = item_resolved_path(M.artifact, item)
  if not path then
    open_detail(item)
    return false
  end

  clear_detail()
  local line, column = item_start_position(item)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  pcall(vim.api.nvim_win_set_cursor, 0, { line, math.max(column - 1, 0) })
  render_extmarks_for_buffer(vim.api.nvim_get_current_buf())
  return true
end

local function copy_item_summary(item)
  if not item then return end
  local path = item_resolved_path(M.artifact, item)
  local text = table.concat({ tostring(item.id or ""), path or "", tostring(item.summary or "") }, " ")
  vim.fn.setreg('+', text)
  vim.fn.setreg('"', text)
  notify("Copied Intent item: " .. tostring(item.id or item.summary or "item"))
end

-- Telescope picker -----------------------------------------------------------

local function telescope_modules()
  local ok_pickers, pickers = pcall(require, "telescope.pickers")
  local ok_finders, finders = pcall(require, "telescope.finders")
  local ok_actions, actions = pcall(require, "telescope.actions")
  local ok_state, action_state = pcall(require, "telescope.actions.state")
  local ok_previewers, previewers = pcall(require, "telescope.previewers")
  local ok_sorters, sorters = pcall(require, "telescope.sorters")

  if ok_pickers and ok_finders and ok_actions and ok_state and ok_previewers and ok_sorters then
    return {
      pickers = pickers,
      finders = finders,
      actions = actions,
      action_state = action_state,
      previewers = previewers,
      sorters = sorters,
    }
  end

  return nil
end

local function anchor_search_text(anchor)
  if type(anchor) ~= "table" then return "" end
  local parts = {}
  for key, value in pairs(anchor) do
    parts[#parts + 1] = tostring(key)
    parts[#parts + 1] = tostring(value)
  end
  return table.concat(parts, " ")
end

local function item_search_text(item)
  local resolution = item_resolution(item)
  return table.concat({
    tostring(item.id or ""),
    tostring(item.role or ""),
    operation_kind(item.operation),
    tostring(item.status or ""),
    tostring(item.priority or ""),
    tostring(item.summary or ""),
    tostring(item.detail or ""),
    anchor_search_text(item.anchor),
    tostring(resolution.path or ""),
    tostring(resolution.reason or ""),
  }, " ")
end

local function source_order_sorter(sorters)
  return sorters.Sorter:new({
    scoring_function = function(_, prompt, entry)
      if not prompt or prompt == "" then
        return entry.index or 1
      end

      local haystack = string.lower(tostring(entry.ordinal or entry.display or ""))
      local needle = string.lower(prompt)
      if haystack:find(needle, 1, true) then
        return entry.index or 1
      end

      for token in needle:gmatch("%S+") do
        if not haystack:find(token, 1, true) then
          return -1
        end
      end

      return entry.index or 1
    end,
  })
end

local function picker_entries(artifact)
  local entries = {}
  for index, item in ipairs(artifact.items or {}) do
    local line, column = item_start_position(item)
    entries[#entries + 1] = {
      index = index,
      value = item,
      display = picker_label(item),
      ordinal = item_search_text(item),
      filename = item_resolved_path(artifact, item),
      lnum = line,
      col = column,
    }
  end
  return entries
end

local function selected_picker_item(action_state)
  local entry = action_state.get_selected_entry()
  return entry and entry.value or nil
end

local function picker_manager_items(action_state, prompt_bufnr)
  local ok_picker, picker = pcall(action_state.get_current_picker, prompt_bufnr)
  local items = {}

  if ok_picker and picker and picker.manager and picker.manager.iter then
    local ok_iter = pcall(function()
      for entry in picker.manager:iter() do
        if entry and entry.value then
          items[#items + 1] = entry.value
        end
      end
    end)
    if ok_iter and #items > 0 then
      return items
    end
  end

  return M.artifact and (M.artifact.items or {}) or {}
end

local function make_previewer(previewers)
  return previewers.new_buffer_previewer({
    title = "Intent detail",
    define_preview = function(self, entry)
      local item = entry and entry.value or nil
      if not item then return end
      vim.bo[self.state.bufnr].filetype = "markdown"
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, detail_lines(item))

      if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
        vim.wo[self.state.winid].wrap = true
        vim.wo[self.state.winid].linebreak = true
        vim.wo[self.state.winid].breakindent = true
      end
    end,
  })
end

local function close_picker_if_open()
  local closed = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    local filetype = vim.bo[bufnr].filetype
    if filetype == "TelescopePrompt" or filetype == "TelescopeResults" or filetype == "TelescopePreview" then
      pcall(vim.api.nvim_win_close, win, true)
      closed = true
    end
  end
  if closed then M.picker_open = false end
  return closed
end

open_picker = function()
  if not M.artifact then
    notify("No Intent artifact loaded", vim.log.levels.WARN)
    return
  end

  if #vim.api.nvim_list_uis() == 0 then
    notify("Intent picker requires an interactive UI; use :IntentQuickfix in headless mode", vim.log.levels.WARN)
    return
  end

  local telescope = telescope_modules()
  if not telescope then
    notify("Telescope is unavailable; use :IntentQuickfix instead", vim.log.levels.WARN)
    M.quickfix()
    return
  end

  local title = "Intent keys: <CR> jump/detail  <C-j>/<C-k> next/prev  <C-d> detail  <C-q> quickfix  <C-y> copy"

  M.picker_open = true

  telescope.pickers.new({}, {
    prompt_title = title,
    finder = telescope.finders.new_table({
      results = picker_entries(M.artifact),
      entry_maker = function(entry) return entry end,
    }),
    sorter = source_order_sorter(telescope.sorters),
    previewer = make_previewer(telescope.previewers),
    attach_mappings = function(prompt_bufnr, map)
      local function close_prompt()
        M.picker_open = false
        telescope.actions.close(prompt_bufnr)
      end

      local function jump_or_detail()
        local item = selected_picker_item(telescope.action_state)
        close_prompt()
        jump_to_item(item)
      end

      local function detail()
        local item = selected_picker_item(telescope.action_state)
        close_prompt()
        open_detail(item)
      end

      local function quickfix()
        local items = picker_manager_items(telescope.action_state, prompt_bufnr)
        close_prompt()
        M.quickfix(items)
      end

      local function copy()
        local item = selected_picker_item(telescope.action_state)
        copy_item_summary(item)
      end

      map("i", "<CR>", jump_or_detail)
      map("n", "<CR>", jump_or_detail)
      map("i", "<C-j>", telescope.actions.move_selection_next)
      map("n", "<C-j>", telescope.actions.move_selection_next)
      map("i", "<C-k>", telescope.actions.move_selection_previous)
      map("n", "<C-k>", telescope.actions.move_selection_previous)
      map("i", "<C-d>", detail)
      map("n", "<C-d>", detail)
      map("i", "<C-q>", quickfix)
      map("n", "<C-q>", quickfix)
      map("i", "<C-y>", copy)
      map("n", "<C-y>", copy)
      return true
    end,
  }):find()
end

function M.pick()
  open_picker()
end

function M.toggle_latest()
  if close_picker_if_open() then
    return
  end
  M.picker_open = false
  M.render_latest({ open_picker = true })
end

-- Relative navigation --------------------------------------------------------

local function item_index(target)
  if not target or not M.artifact then return nil end
  for index, item in ipairs(M.artifact.items or {}) do
    if item == target or (target.id and item.id == target.id) then
      return index
    end
  end
  return nil
end

local function selected_item_index()
  if M.selected_item_id and M.items_by_id[M.selected_item_id] then
    return item_index(M.items_by_id[M.selected_item_id])
  end
  return item_index(current_buffer_item()) or item_index(current_qf_item())
end

local function ensure_artifact_loaded()
  if M.artifact then return true end
  return M.render_latest({ open_picker = false }) == true
end

local function jump_relative(delta)
  if not ensure_artifact_loaded() then return end

  local items = M.artifact.items or {}
  if #items == 0 then
    notify("Intent artifact has no items", vim.log.levels.WARN)
    return
  end

  local current_index = selected_item_index()
  local start_index
  if current_index then
    start_index = current_index + delta
  elseif delta > 0 then
    start_index = 1
  else
    start_index = #items
  end

  local index = start_index
  while index >= 1 and index <= #items do
    if is_resolved(items[index]) and item_resolved_path(M.artifact, items[index]) then
      jump_to_item(items[index])
      return
    end
    index = index + delta
  end

  if delta > 0 then
    notify("No next resolved Intent item", vim.log.levels.WARN)
  else
    notify("No previous resolved Intent item", vim.log.levels.WARN)
  end
end

function M.next()
  jump_relative(1)
end

function M.prev()
  jump_relative(-1)
end

-- Autocommands and user commands --------------------------------------------

vim.api.nvim_create_augroup("IntentRenderer", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = "IntentRenderer",
  callback = function(args)
    render_extmarks_for_buffer(args.buf)
  end,
})

vim.api.nvim_create_user_command("IntentRender", function(opts)
  M.render(opts.args, { open_picker = true })
end, { force = true, nargs = 1, complete = "file" })

vim.api.nvim_create_user_command("IntentRenderLatest", function()
  M.render_latest({ open_picker = true })
end, { force = true })

vim.api.nvim_create_user_command("IntentClear", function()
  M.clear()
end, { force = true })

vim.api.nvim_create_user_command("IntentWatchStart", function(opts)
  M.watch_start(opts.args)
end, { force = true, nargs = "?", complete = "file" })

vim.api.nvim_create_user_command("IntentWatchStop", function()
  M.watch_stop()
end, { force = true })

vim.api.nvim_create_user_command("IntentPick", function()
  M.pick()
end, { force = true })

vim.api.nvim_create_user_command("IntentQuickfix", function()
  M.quickfix()
end, { force = true })

vim.api.nvim_create_user_command("IntentDetail", function()
  M.detail()
end, { force = true })

vim.api.nvim_create_user_command("IntentNext", function()
  M.next()
end, { force = true })

vim.api.nvim_create_user_command("IntentPrev", function()
  M.prev()
end, { force = true })

return M
