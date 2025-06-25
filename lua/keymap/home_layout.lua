-- Require your existing utils helper
local utils = require("utils")

-- Global variable to track if the layout is active
vim.g.home_layout_active = 0

-- This table holds the key remappings for your layout.
-- Format: { physical_output, vim_action }
local home_mappings = {
  { "r", "h" }, -- Physical H -> outputs 'r' -> should do 'h' (left)
  { "h", "j" }, -- Physical J -> outputs 'h' -> should do 'j' (down)
  { "n", "k" }, -- Physical K -> outputs 'n' -> should do 'k' (up)
  { "i", "l" }, -- Physical L -> outputs 'i' -> should do 'l' (right)
}

-- Sets the keymaps for your custom layout
local function set_mappings()
  local opts = { silent = true }
  for _, mapping in ipairs(home_mappings) do
    local lhs = mapping[1]
    local rhs = mapping[2]
    -- Set mappings for normal and visual mode using your helper
    utils.map('n', lhs, rhs, opts)
    utils.map('v', lhs, rhs, opts)
  end
end

-- Clears the keymaps to restore default behavior
local function clear_mappings()
  for _, mapping in ipairs(home_mappings) do
    local lhs = mapping[1]
    -- Use pcall to ignore errors if a mapping doesn't exist
    pcall(vim.api.nvim_del_keymap, 'n', lhs)
    pcall(vim.api.nvim_del_keymap, 'v', lhs)
  end
end

-- Command to enable your custom layout mappings
vim.api.nvim_create_user_command('HomeLayoutEnable', function()
  if vim.g.home_layout_active == 1 then
    print("Home layout is already active.")
    return
  end
  vim.g.home_layout_active = 1
  set_mappings()
  print("Home layout enabled.")
end, {})

-- Command to disable your custom layout mappings
vim.api.nvim_create_user_command('HomeLayoutDisable', function()
  if vim.g.home_layout_active == 0 then
    print("Home layout is not active.")
    return
  end
  vim.g.home_layout_active = 0
  clear_mappings()
  print("Home layout disabled.")
end, {})

-- You could optionally create a toggle command for convenience
vim.api.nvim_create_user_command('HomeLayoutToggle', function()
    if vim.g.home_layout_active == 1 then
        vim.cmd('HomeLayoutDisable')
    else
        vim.cmd('HomeLayoutEnable')
    end
end, {})



