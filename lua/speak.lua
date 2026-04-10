local M = {}

local function get_visual_selection()
  -- Visual marks: start '< and end '>
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos   = vim.api.nvim_buf_get_mark(0, ">")

  local l1, c1 = start_pos[1], start_pos[2]
  local l2, c2 = end_pos[1], end_pos[2]
  if l1 == 0 or l2 == 0 then return nil end

  -- Normalize order
  if (l1 > l2) or (l1 == l2 and c1 > c2) then
    l1, l2 = l2, l1
    c1, c2 = c2, c1
  end

  -- nvim_buf_get_lines is 0-based, end-exclusive
  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  if not lines or #lines == 0 then return nil end

  -- Slice to exact selection (byte indices; fine for ASCII/code)
  lines[1]     = string.sub(lines[1], c1 + 1)
  lines[#lines]= string.sub(lines[#lines], 1, c2 + 1)

  local text = table.concat(lines, "\n")
  -- Remove control chars (keep newline/tab optional; here: strip all)
  text = text:gsub("[%c]", " ")
  text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  if text == "" then return nil end
  return text
end

function M.speak_visual()
  local text = get_visual_selection()
  if not text then return end

  -- No shell. Calls /usr/bin/say directly.
  vim.system({ "say", text }, { detach = true }, function(_) end)
end

return M
