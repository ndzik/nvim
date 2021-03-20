"" Make vim-airline compatible with vimdevicons.
let g:airline#extensions#whitespace#enabled = 0
let g:airline_theme='wombat'

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.crypt = ''
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.spell = '暈'
let g:airline_symbols.notexists = ''
let g:airline_symbols.whitespace = 'Ξ'
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.readonly = ''
