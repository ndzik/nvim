local actions = require("telescope.actions")

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
        },

        hoogle = {
            browser_cmd = "firefox -P search",
        },
    }
}

require('telescope').load_extension("fzy_native")
require('telescope').load_extension("hoogle")
require('telescope').load_extension("git_worktree")

local M = {}

-- set_ignorepattern receives a regex string, which will be used to ignore
-- patterns for `Telescope.find_files()`.
M.set_ignore_pattern = function(pattern)
    M.ignorePattern = { pattern }
end

-- search_dotfiles allows you to configure your neovim configuration by fuzzing
-- over your configuration folder.
M.search_dotfiles = function(configPath)
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = configPath,
        file_ignore_patterns = { "plugged/.*" }
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

M.find_files = function()
    require("telescope.builtin").find_files({
        file_ignore_patterns = M.ignorePattern
    })
end

return M
