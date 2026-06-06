local M = {
  active_sink = nil,
  sinks = {},
  prompt_bufnr = nil,
  prompt_winnr = nil,
}

local PROTOCOL_VERSION = 1
local REQUEST_TIMEOUT_MS = 5000

local function uv()
  return vim.uv or vim.loop
end

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO)
  end)
end

local function agent_dir()
  return vim.fn.expand(vim.env.PI_CODING_AGENT_DIR or "~/.pi/agent")
end

local function sink_registry_dir()
  return agent_dir() .. "/sinks"
end

local function read_json_file(path)
  local ok_read, lines = pcall(vim.fn.readfile, path)
  if not ok_read or not lines or #lines == 0 then
    return nil
  end

  local ok_decode, value = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(value) ~= "table" then
    return nil
  end

  value.descriptor_path = path
  return value
end

local function path_exists(path)
  return type(path) == "string" and uv().fs_stat(path) ~= nil
end

local function process_alive(pid)
  if type(pid) ~= "number" then
    return false
  end

  local ok, result = pcall(uv().kill, pid, 0)
  return ok and result == 0
end

local function is_live_sink(sink)
  return type(sink) == "table"
    and sink.version == PROTOCOL_VERSION
    and type(sink.id) == "string"
    and type(sink.socket) == "string"
    and type(sink.token) == "string"
    and path_exists(sink.socket)
    and process_alive(sink.pid)
end

local function current_buffer_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":p")
end

local function relative_to_cwd(path)
  if not path or path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":~:.")
end

local function sink_label(sink)
  local name = sink.sessionName or sink.session_name
  local cwd = sink.cwd or "?"
  local suffix = name and name ~= "" and (" — " .. name) or ""
  return string.format("%s  [%s]%s", sink.id or "unknown", cwd, suffix)
end

function M.discover_sinks()
  local dir = sink_registry_dir()
  local pattern = dir .. "/*.json"
  local files = vim.fn.glob(pattern, false, true)
  local sinks = {}

  for _, path in ipairs(files or {}) do
    local sink = read_json_file(path)
    if is_live_sink(sink) then
      sinks[#sinks + 1] = sink
    end
  end

  table.sort(sinks, function(a, b)
    return tonumber(a.updatedAt or a.createdAt or 0) > tonumber(b.updatedAt or b.createdAt or 0)
  end)

  M.sinks = sinks
  return sinks
end

local function find_sink_by_id(id)
  for _, sink in ipairs(M.discover_sinks()) do
    if sink.id == id then
      return sink
    end
  end
  return nil
end

function M.select_sink(callback)
  local sinks = M.discover_sinks()

  if #sinks == 0 then
    M.active_sink = nil
    notify("No live Pi nvim sinks found", vim.log.levels.WARN)
    if callback then callback(nil) end
    return
  end

  if #sinks == 1 then
    M.active_sink = sinks[1]
    notify("Using Pi sink " .. M.active_sink.id)
    if callback then callback(M.active_sink) end
    return
  end

  vim.ui.select(sinks, {
    prompt = "Select Pi sink",
    format_item = sink_label,
  }, function(choice)
    if not choice then
      if callback then callback(nil) end
      return
    end
    M.active_sink = choice
    notify("Using Pi sink " .. choice.id)
    if callback then callback(choice) end
  end)
end

function M.attach()
  M.select_sink()
end

function M.list_sinks()
  local sinks = M.discover_sinks()
  if #sinks == 0 then
    notify("No live Pi nvim sinks found", vim.log.levels.WARN)
    return
  end

  local lines = {}
  for _, sink in ipairs(sinks) do
    local marker = M.active_sink and M.active_sink.id == sink.id and "*" or " "
    lines[#lines + 1] = string.format("%s %s", marker, sink_label(sink))
  end
  notify(table.concat(lines, "\n"))
end

local function ensure_sink(callback)
  if M.active_sink then
    local live = find_sink_by_id(M.active_sink.id)
    if live then
      M.active_sink = live
      callback(live)
      return
    end
    M.active_sink = nil
  end

  M.select_sink(callback)
end

local function get_visual_selection()
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")

  local l1, c1 = start_pos[1], start_pos[2]
  local l2, c2 = end_pos[1], end_pos[2]
  if l1 == 0 or l2 == 0 then return nil end

  if (l1 > l2) or (l1 == l2 and c1 > c2) then
    l1, l2 = l2, l1
    c1, c2 = c2, c1
  end

  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  if not lines or #lines == 0 then return nil end

  lines[1] = string.sub(lines[1], c1 + 1)
  lines[#lines] = string.sub(lines[#lines], 1, c2 + 1)

  return {
    text = table.concat(lines, "\n"),
    range = {
      start = { l1, c1 },
      ["end"] = { l2, c2 },
    },
  }
end

local get_buffer_diagnostics

local function request_source()
  local path = current_buffer_path()
  return {
    client = "nvim",
    cwd = uv().cwd(),
    buffer = path,
    relativePath = relative_to_cwd(path),
    filetype = vim.bo.filetype,
  }
end

local function snapshot_context_options(opts)
  opts = vim.deepcopy(opts or {})
  opts.source = request_source()
  opts.buffer_path = opts.source.buffer
  if opts.diagnostics then
    opts.diagnostics_context = get_buffer_diagnostics()
  end
  return opts
end

local function diagnostic_severity_name(severity)
  local names = {
    [vim.diagnostic.severity.ERROR] = "error",
    [vim.diagnostic.severity.WARN] = "warning",
    [vim.diagnostic.severity.INFO] = "info",
    [vim.diagnostic.severity.HINT] = "hint",
  }
  return names[severity] or tostring(severity or "unknown")
end

get_buffer_diagnostics = function()
  local diagnostics = vim.diagnostic.get(0)
  if not diagnostics or #diagnostics == 0 then
    return nil
  end

  local items = {}
  for _, diagnostic in ipairs(diagnostics) do
    items[#items + 1] = {
      severity = diagnostic_severity_name(diagnostic.severity),
      source = diagnostic.source,
      code = diagnostic.code,
      message = diagnostic.message,
      range = {
        start = { (diagnostic.lnum or 0) + 1, diagnostic.col or 0 },
        ["end"] = { (diagnostic.end_lnum or diagnostic.lnum or 0) + 1, diagnostic.end_col or diagnostic.col or 0 },
      },
    }
  end

  return {
    kind = "diagnostics",
    path = current_buffer_path(),
    items = items,
  }
end

local function build_request(sink, message, opts)
  opts = opts or {}
  local path = opts.buffer_path or current_buffer_path()
  local context = {}

  if opts.selection and opts.selection.text and opts.selection.text ~= "" then
    context[#context + 1] = {
      kind = "selection",
      path = path,
      range = opts.selection.range,
      text = opts.selection.text,
    }
  end

  if opts.diagnostics_context then
    context[#context + 1] = opts.diagnostics_context
  end

  return {
    version = PROTOCOL_VERSION,
    id = string.format("nvim-%d-%d", os.time(), math.random(100000, 999999)),
    token = sink.token,
    type = "prompt",
    delivery = opts.delivery or "auto",
    message = message,
    context = context,
    source = opts.source or request_source(),
  }
end

local function send_to_socket(sink, request)
  local pipe = uv().new_pipe(false)
  local timer = uv().new_timer()
  local response_chunks = {}
  local finished = false

  local function cleanup()
    if finished then return end
    finished = true

    if timer then
      pcall(timer.stop, timer)
      pcall(timer.close, timer)
    end
    if pipe then
      pcall(pipe.read_stop, pipe)
      pcall(pipe.shutdown, pipe)
      pcall(pipe.close, pipe)
    end
  end

  timer:start(REQUEST_TIMEOUT_MS, 0, function()
    cleanup()
    notify("Pi sink request timed out", vim.log.levels.ERROR)
  end)

  pipe:connect(sink.socket, function(connect_err)
    if connect_err then
      cleanup()
      notify("Failed to connect to Pi sink: " .. tostring(connect_err), vim.log.levels.ERROR)
      return
    end

    pipe:read_start(function(read_err, chunk)
      if read_err then
        cleanup()
        notify("Pi sink read failed: " .. tostring(read_err), vim.log.levels.ERROR)
        return
      end

      if chunk then
        response_chunks[#response_chunks + 1] = chunk
        return
      end

      local raw = table.concat(response_chunks, "")
      cleanup()

      local ok_decode, response = pcall(vim.json.decode, raw)
      if not ok_decode or type(response) ~= "table" then
        notify("Pi sink returned invalid response", vim.log.levels.ERROR)
        return
      end

      if response.ok then
        notify(string.format("Sent to Pi sink %s (%s)", response.sinkId or sink.id, response.delivery or "accepted"))
      else
        notify("Pi sink rejected request: " .. tostring(response.error or "unknown error"), vim.log.levels.ERROR)
      end
    end)

    local encoded = vim.json.encode(request) .. "\n"
    pipe:write(encoded, function(write_err)
      if write_err then
        cleanup()
        notify("Pi sink write failed: " .. tostring(write_err), vim.log.levels.ERROR)
      end
    end)
  end)
end

local function is_window_valid(winnr)
  return winnr and vim.api.nvim_win_is_valid(winnr)
end

local function is_buffer_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

function M.close_prompt()
  if is_window_valid(M.prompt_winnr) then
    pcall(vim.api.nvim_win_close, M.prompt_winnr, true)
  end
  if is_buffer_valid(M.prompt_bufnr) then
    pcall(vim.api.nvim_buf_delete, M.prompt_bufnr, { force = true })
  end
  M.prompt_winnr = nil
  M.prompt_bufnr = nil
end

local function prompt_title(opts)
  local parts = { "Pi Prompt" }
  if opts.selection then
    parts[#parts + 1] = "selection"
  end
  if opts.diagnostics_context then
    parts[#parts + 1] = "diagnostics"
  end
  return " " .. table.concat(parts, " + ") .. " "
end

local function normalized_prompt_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  while #lines > 0 and lines[1]:match("^%s*$") do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines, #lines)
  end
  return table.concat(lines, "\n")
end

local function open_prompt(opts, on_submit)
  M.close_prompt()

  local width = math.min(100, math.max(50, math.floor(vim.o.columns * 0.65)))
  local height = math.min(18, math.max(8, math.floor(vim.o.lines * 0.35)))
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)

  M.prompt_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[M.prompt_bufnr].buftype = "nofile"
  vim.bo[M.prompt_bufnr].bufhidden = "wipe"
  vim.bo[M.prompt_bufnr].swapfile = false
  vim.bo[M.prompt_bufnr].filetype = "markdown"

  M.prompt_winnr = vim.api.nvim_open_win(M.prompt_bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = prompt_title(opts),
    title_pos = "center",
    footer = "Esc then Enter/C-s: send • q/Esc: cancel",
    footer_pos = "center",
  })

  vim.wo[M.prompt_winnr].wrap = true
  vim.wo[M.prompt_winnr].linebreak = true
  vim.api.nvim_buf_set_lines(M.prompt_bufnr, 0, -1, false, { "" })

  local function submit()
    if not is_buffer_valid(M.prompt_bufnr) then return end
    local text = normalized_prompt_text(M.prompt_bufnr)
    if not text:match("%S") then
      notify("Pi prompt is empty", vim.log.levels.WARN)
      return
    end
    M.close_prompt()
    on_submit(text)
  end

  local function cancel()
    M.close_prompt()
  end

  local keymap_opts = { buffer = M.prompt_bufnr, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", submit, keymap_opts)
  vim.keymap.set("n", "q", cancel, keymap_opts)
  vim.keymap.set("n", "<Esc>", cancel, keymap_opts)
  vim.keymap.set("i", "<C-s>", submit, keymap_opts)
  vim.keymap.set("i", "<C-c>", cancel, keymap_opts)

  vim.cmd("startinsert")
end

local function ask_with_context(opts)
  opts = snapshot_context_options(opts)
  open_prompt(opts, function(query)
    ensure_sink(function(sink)
      if not sink then return end
      local request = build_request(sink, query, opts)
      send_to_socket(sink, request)
    end)
  end)
end

function M.ask()
  ask_with_context({})
end

function M.ask_diagnostics()
  ask_with_context({ diagnostics = true })
end

function M.ask_selection()
  local selection = get_visual_selection()
  if not selection or selection.text == "" then
    notify("No visual selection found", vim.log.levels.WARN)
    return
  end

  ask_with_context({ selection = selection })
end

function M.ask_selection_diagnostics()
  local selection = get_visual_selection()
  if not selection or selection.text == "" then
    notify("No visual selection found", vim.log.levels.WARN)
    return
  end

  ask_with_context({ selection = selection, diagnostics = true })
end

vim.api.nvim_create_user_command("PiSinkAttach", M.attach, { force = true })
vim.api.nvim_create_user_command("PiSinkList", M.list_sinks, { force = true })
vim.api.nvim_create_user_command("PiSinkAsk", M.ask, { force = true })
vim.api.nvim_create_user_command("PiSinkAskDiagnostics", M.ask_diagnostics, { force = true })
vim.api.nvim_create_user_command("PiSinkAskSelection", M.ask_selection, { force = true, range = true })
vim.api.nvim_create_user_command("PiSinkAskSelectionDiagnostics", M.ask_selection_diagnostics, { force = true, range = true })

vim.defer_fn(function()
  local sinks = M.discover_sinks()
  if #sinks == 1 then
    M.active_sink = sinks[1]
    notify("Using Pi sink " .. M.active_sink.id)
  elseif #sinks > 1 then
    M.select_sink()
  end
end, 200)

return M
