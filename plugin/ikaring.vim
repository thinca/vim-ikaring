" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_ikaring')
  finish
endif
let g:loaded_ikaring = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=* -bang -complete=customlist,ikaring#cmd_complete
\        Ikaring call ikaring#command(<q-args>, <bang>0)

augroup plugin-ikaring
  autocmd!
  autocmd BufReadCmd  ikaring://* call ikaring#_read(expand('<amatch>'))
augroup END



let &cpoptions = s:save_cpo
unlet s:save_cpo
