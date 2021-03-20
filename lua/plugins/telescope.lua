local actions = require("telescope.actions")
local utils = require("utils")

-- Telescope bindings.
utils.map('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
utils.map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
utils.map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
utils.map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
utils.map('n', '<leader>gc', '<cmd>Telescope git_commits<cr>')
utils.map('n', '<leader>gs', '<cmd>Telescope git_status<cr>')
utils.map('n', '<leader>gb', '<cmd>Telescope git_branches<cr>')

-- Telescope configuration. Here one can override several defaults and register
-- custom keybinds, which are local to the telescope window.
require('telescope').setup {
    defaults = {
        file_sorter = require("telescope.sorters").get_fzy_sorter,
        prompt_prefix = '> ',
        color_devicons = true,

        file_previewer   = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer   = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist,
            },
        }
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        }
    }
}

require('telescope').load_extension("fzy_native")

local M = {}
M.search_dotfiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = "$HOME/.config/nvim",
    })
end

M.git_branches = function()
    require("telescope.builtin").git_branches({
        attach_mappings = function(_, map)
            map('i', '<c-d>', actions.git_delete_branch)
            map('n', '<c-d>', actions.git_delete_branch)
            return true
        end
    })
end

return M
