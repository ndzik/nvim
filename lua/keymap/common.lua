local utils = require("utils")

utils.map('n', '<Space>', '<Nop>')
utils.map('t', '<Esc>', '<C-\\><C-n>')
utils.map('n', '<Backspace>', '<C-^>')

-- Easily move through quickfix and locallist.
utils.map('n', '<C-j>', '<cmd>lnext<cr>')
utils.map('n', '<C-k>', '<cmd>lprev<cr>')
utils.map('n', '<C-l>', '<cmd>cnext<cr>')
utils.map('n', '<C-h>', '<cmd>cprev<cr>')

-- Vimux integration.
utils.map('n', '<leader>vq', '<cmd>VimuxCloseRunner<CR>')
utils.map('n', '<leader>vi', '<cmd>VimuxInspectRunner<CR>')
utils.map('n', '<leader>vp', '<cmd>VimuxPromptCommand<CR>')
utils.map('n', '<leader>vl', '<cmd>VimuxRunLastCommand<CR>')

-- Nerd-Tree bindings.
utils.map('n', '<leader>nt', '<cmd>NERDTreeToggle<enter>')
utils.map('n', '<leader>nf', '<cmd>NERDTreeFocus<enter>')

-- Tmux integration.
local opts = { silent = true }
utils.map('n', '<C-w><C-h>', '<cmd>TmuxNavigateLeft<cr>', opts)
utils.map('n', '<C-w><C-j>', '<cmd>TmuxNavigateDown<cr>', opts)
utils.map('n', '<C-w><C-k>', '<cmd>TmuxNavigateUp<cr>', opts)
utils.map('n', '<C-w><C-l>', '<cmd>TmuxNavigateRight<cr>', opts)

-- Vimux global options.
vim.api.nvim_set_var("tmux_navigator_no_mappings", 1)
vim.api.nvim_set_var("tmux_navigator_save_on_switch", 1)

-- Window related mappings.
utils.map('n', '<C-c>', '<C-W>c')
utils.map('n', '-', '<C-W>s<C-W><Down>')
utils.map('n', '<Bar>', '<C-W>v<C-W><Right>')

-- Copilot integration.
utils.map('i', '<Left>', '<Plug>(copilot-next)')
utils.map('i', '<Right>', '<Plug>(copilot-previous)')
utils.map('i', '<Down>', '<Plug>(copilot-dismiss)')
