local utils = require("utils")

-- Keymapping for built-in stuff.
utils.map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
utils.map('n', '<leader>gc', '<cmd>Telescope git_commits<cr>')
utils.map('n', '<leader>gs', '<cmd>Telescope git_status<cr>')
utils.map('n', '<leader>fm', '<cmd>Telescope man_pages<cr>')

utils.map('n', '<leader>er', '<cmd>Telescope lsp_workspace_diagnostics<cr>')
utils.map('n', '<leader>im', '<cmd>Telescope lsp_implementations<cr>')

-- Filebrowser
utils.map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')

-- TODO: Add a check or PR to Telescope to check, that `ripgrep` and `fd` are
-- properly installed on the system, otherwise this command will always fail
-- with a cryptic error message.
utils.map('n', '<leader>fg', '<cmd>lua require("telescope.builtin").grep_string({ search = vim.fn.input("Grepping > ") })<cr>')

-- Give each manpage section a keybind `<leader>m<section_number>`.
-- TODO: Add some kind of hint reminding me to update `mandb`.
for _, v in pairs({1, 2, 3, 4, 5, 6, 7, 8, 9}) do
    local map = string.format('<leader>m%s', v)
    local cmd = string.format('<cmd>lua require("telescope.builtin").man_pages({ sections = { "%s" } })<cr>', v)
    utils.map('n', map, cmd)
end

-- Keymapping for custom telescope functions.
utils.map('n', '<leader>gb', '<cmd>lua require("plugins.telescope.common").git_branches()<cr>')
utils.map('n', '<leader>ev', '<cmd>lua require("plugins.telescope.common").search_dotfiles("$HOME/.config/nvim")<cr>')
utils.map('n', '<leader>ff', '<cmd>lua require("plugins.telescope.common").find_files()<cr>')

-- Git worktree stuff.
utils.map('n', '<leader>gw', '<cmd>lua require("telescope").extensions.git_worktree.git_worktrees()<cr>')
