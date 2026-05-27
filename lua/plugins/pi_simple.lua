local M = {
  bufnr = nil,
  winnr = nil,
}

local function is_window_valid()
  return M.winnr and vim.api.nvim_win_is_valid(M.winnr)
end

local function is_buffer_valid()
  return M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr)
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

  return table.concat(lines, "\n")
end

function M.close_window()
  if is_window_valid() then
    pcall(vim.api.nvim_win_close, M.winnr, true)
  end
  if is_buffer_valid() then
    pcall(vim.api.nvim_buf_delete, M.bufnr, { force = true })
  end
  M.winnr = nil
  M.bufnr = nil
end

local function normalize_lines(items)
  local out = {}
  for _, item in ipairs(items or {}) do
    local text = tostring(item or "")
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    local parts = vim.split(text, "\n", { plain = true })
    for _, part in ipairs(parts) do
      out[#out + 1] = part
    end
  end
  if #out == 0 then
    out = { "" }
  end
  return out
end

local function get_pi_defaults_from_settings()
  local config_dir = vim.env.PI_CODING_AGENT_DIR or "~/.pi/agent"
  local settings_path = vim.fn.expand(config_dir .. "/settings.json")

  local ok_read, settings_raw = pcall(vim.fn.readfile, settings_path)
  if not ok_read or not settings_raw or #settings_raw == 0 then
    return nil, nil
  end

  local ok_decode, settings = pcall(vim.json.decode, table.concat(settings_raw, "\n"))
  if not ok_decode or type(settings) ~= "table" then
    return nil, nil
  end

  local provider = settings.defaultProvider
  local model = settings.defaultModel
  if type(provider) ~= "string" then provider = nil end
  if type(model) ~= "string" then model = nil end

  return provider, model
end

local function get_pi_title()
  local provider, model = get_pi_defaults_from_settings()
  if model and model ~= "" then
    if provider and provider ~= "" and not model:find("/", 1, true) then
      return string.format(" Pi (%s/%s) ", provider, model)
    end
    return string.format(" Pi (%s) ", model)
  end

  if provider and provider ~= "" then
    return string.format(" Pi (%s) ", provider)
  end

  return " Pi "
end

local function open_window(title, lines)
  M.close_window()

  local width = math.min(120, math.max(60, math.floor(vim.o.columns * 0.7)))
  local height = math.min(30, math.max(10, math.floor(vim.o.lines * 0.6)))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  M.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[M.bufnr].buftype = "nofile"
  vim.bo[M.bufnr].bufhidden = "wipe"
  vim.bo[M.bufnr].swapfile = false
  vim.bo[M.bufnr].filetype = "markdown"

  M.winnr = vim.api.nvim_open_win(M.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })

  vim.wo[M.winnr].wrap = true
  vim.wo[M.winnr].linebreak = true

  local safe_lines = normalize_lines(lines)

  vim.bo[M.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, safe_lines)
  vim.bo[M.bufnr].modifiable = false

  vim.keymap.set("n", "q", function() require("plugins.pi_simple").close_window() end, { buffer = M.bufnr, silent = true })
end

function M.ask_selection()
  local selection = get_visual_selection()
  if not selection or selection == "" then
    vim.notify("No visual selection found", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Ask pi > " }, function(query)
    if not query or query == "" then
      return
    end

    open_window(get_pi_title(), { "Thinking..." })

    local prompt = table.concat({
      "You are given selected code as context.",
      "Answer the user query concisely and clearly.",
      "",
      "User query:",
      query,
      "",
      "Selected context:",
      selection,
    }, "\n")

    local cmd = { "pi", prompt }

    vim.system(cmd, { text = true }, vim.schedule_wrap(function(result)
      local output = result.stdout or ""
      local err = result.stderr or ""

      if result.code ~= 0 then
        open_window(" Pi Error ", {
          "pi command failed",
          "",
          "exit code: " .. tostring(result.code),
          err,
        })
        return
      end

      if output == "" then
        output = "(No output from pi)"
      end

      local lines = { "# Pi Response", "", output, "", "---", "Press q to close" }
      open_window(get_pi_title(), lines)
    end))
  end)
end

vim.api.nvim_create_user_command("PiSimpleAskSelection", M.ask_selection, { force = true })
vim.api.nvim_create_user_command("PiSimpleClose", M.close_window, { force = true })

return M
