-- Options and settings regarding highlighting.
local utils = require("utils")
local cmd = vim.cmd

utils.opt('o', "hlsearch", true)
utils.opt('w', "number", true)
utils.opt('w', "relativenumber", true)
utils.opt('o', "background", "dark")
utils.opt('w', "cursorline", true)
utils.opt('w', "colorcolumn", "80")

cmd "colorscheme mustard"

cmd "syntax enable"
cmd "hi CursorLine cterm=NONE ctermbg=236"
cmd "hi Folded ctermfg=2 ctermbg=233"

cmd "hi Pmenu ctermbg=233 ctermfg=228"
cmd "hi SignColumn ctermbg=0"
cmd "hi TabLineFill term=bold cterm=bold ctermfg=1 ctermbg=0"
cmd "hi TabLineSel term=bold cterm=bold"
cmd "hi Search cterm=bold ctermbg=none ctermfg=220"
cmd "hi MatchParen term=bold cterm=bold ctermbg=none ctermfg=39"
cmd "hi Conceal ctermbg=235"
cmd "hi SpellBad cterm=bold ctermfg=235 ctermbg=167"
cmd "hi SpellRare cterm=bold ctermfg=70 ctermbg=0"
cmd "hi Warning term=underline cterm=underline ctermfg=Yellow"
cmd "au TextYankPost * lua vim.highlight.on_yank {on_visual = false}"
