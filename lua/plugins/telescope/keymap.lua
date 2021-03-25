local utils = require("utils")

-- Keymapping for built-in stuff.
utils.map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
utils.map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
utils.map('n', '<leader>gc', '<cmd>Telescope git_commits<cr>')
utils.map('n', '<leader>gs', '<cmd>Telescope git_status<cr>')

utils.map('n', '<leader>ho', '<cmd>Telescope hoogle<cr>')

-- Keymapping for custom telescope functions.
utils.map('n', '<leader>fg', '<cmd>lua require("telescope.builtin").grep_string({ search = vim.fn.input("Grepping > ") })<cr>')
utils.map('n', '<leader>gb', '<cmd>lua require("plugins.telescope.common").git_branches()<cr>')
utils.map('n', '<leader>ev', '<cmd>lua require("plugins.telescope.common").search_dotfiles("$HOME/.config/nvim")<cr>')
utils.map('n', '<leader>ff', '<cmd>lua require("plugins.telescope.common").find_files()<cr>')
