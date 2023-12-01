-- Common neovim configuration.
local utils = require("utils")

local cmd = vim.cmd
local indent = 2

-- Options for editor behaviour.
cmd "filetype plugin indent on"

utils.opt('b', "tabstop", indent)
utils.opt('b', "shiftwidth", indent)
utils.opt('b', "expandtab", true)
utils.opt('b', "smartindent", true)
utils.opt('o', "hidden", true)
utils.opt('o', "ignorecase", true)
utils.opt('o', "smartcase", true)
utils.opt('o', "so", 10)
utils.opt('o', "shiftround", true)
utils.opt('o', "splitbelow", true)
utils.opt('o', "splitright", true)
utils.opt('o', "wildmenu", true)
utils.opt('o', "showcmd", true)
utils.opt('o', "path", "**")
utils.opt('o', "confirm", true)
utils.opt('o', "cmdheight", 2)
utils.opt('o', "clipboard", "unnamed,unnamedplus")

-- Options for completion behaviour.
utils.opt('o', "completeopt", "menu,menuone,noselect")
utils.opt('o', "shortmess", "at")

-- Options for folding behaviour.
utils.opt('w', "foldmethod", "syntax")
utils.opt('w', "foldnestmax", 10)
utils.opt('w', "foldenable", false)
utils.opt('w', "foldlevel", 2)

-- Options for copilot, code-suggestions things.
utils.letg('copilot_enabled', false)
