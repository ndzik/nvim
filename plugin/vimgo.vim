set updatetime=500
let g:go_diagnostics_level = 2 "" errors + warnings
let g:go_highlight_diagnostic_errors = 1
let g:go_highlight_diagnostic_warnings = 1
autocmd FileType go let b:go_fmt_options = {
      \ 'gofmt': '-s',
      \ 'goimports': '-local ' .
      \ trim(system('cd '. shellescape(expand('%:h')) .' && go list -m;')),
      \ }
let g:go_imports_autosave = 1
let g:go_fmt_command = "goimports"
let g:go_auto_type_info = 1
set autowrite
autocmd FileType go nmap <leader>c <Plug>(go-coverage-toggle)
autocmd FileType go nmap <leader>i <Plug>(go-info)
autocmd FileType go nmap <leader>t :TagbarToggle<CR>
let g:go_imports_autosave = 1
let g:go_auto_type_info = 1
set updatetime=100
let g:go_auto_sameids = 0

"" Highlighting
autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4

let g:go_debug_breakpoint_sign_text = ''
let g:go_debug_windows = {
      \ 'vars':       'rightbelow 60vnew',
      \ 'stack':      'rightbelow 10new',
\ }
