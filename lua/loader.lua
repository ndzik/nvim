local api = vim.api

local M = {
  buf = nil,
  win = nil,
}

function M.close_window()
  if M.buf and api.nvim_buf_is_valid(M.buf) then
    api.nvim_buf_delete(M.buf, { force = true })
  end
  M.buf = nil
  M.win = nil
end

function M.install()
  if not M.doInstall then
    print("Please pass define a `loader.doInstall` function.")
    return
  end

  M.close_window()
  M.doInstall()
end

function M.open_window()
  M.buf = api.nvim_create_buf(false, true) -- create new empty buffer

  vim.bo[M.buf].bufhidden = 'wipe'

  -- get dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    focusable = true
  }

  api.nvim_buf_set_lines(M.buf, 0, -1, false, {
    "Setup",
    "",
    "Are you sure you want to continue? This setup will use `curl` to install",
    "`vim-plug` and afterwards install all required plugins.",
    "If this is the case press 'y' and enjoy this setup (:",
    "",
    "If you changed your mind press 'q' or 'n' to exit the process and make",
    "sure to clean your `.config/nvim` directory before starting nvim again."
  })

  -- We bind the actions to the current buffer, because there is no reason to
  -- keep using VIM with this config if the user is not interested in using it
  -- anyway.
  api.nvim_buf_set_keymap(M.buf,
  'n',
  'y',
  ':lua require("loader").install()<cr>',
  { nowait = true, noremap = true, silent = true }
  )
  api.nvim_buf_set_keymap(M.buf,
  'n',
  '<CR>',
  ':lua require("loader").install()<cr>',
  { nowait = true, noremap = true, silent = true }
  )
  api.nvim_buf_set_keymap(M.buf,
  'n',
  'n',
  ':lua require("loader").close_window()<cr>',
  { nowait = true, noremap = true, silent = true }
  )
  api.nvim_buf_set_keymap(M.buf,
  'n',
  'q',
  ':lua require("loader").close_window()<cr>',
  { nowait = true, noremap = true, silent = true }
  )

  -- and finally create it with buffer attached
  M.win = api.nvim_open_win(M.buf, true, opts)
  api.nvim_set_current_win(M.win)
  api.nvim_set_current_buf(M.buf)

  -- On startup, focus can be stolen by other initialization events.
  -- Re-assert focus on the next scheduler tick.
  vim.schedule(function()
    if M.win and api.nvim_win_is_valid(M.win) then
      api.nvim_set_current_win(M.win)
    end
    if M.buf and api.nvim_buf_is_valid(M.buf) then
      api.nvim_set_current_buf(M.buf)
    end
  end)
end

function M.setup()
  if M.isNotInstalled() then
    return M.open_window()
  end
  M.default()
end

return M
