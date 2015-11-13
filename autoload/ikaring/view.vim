" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:views = {}

function! ikaring#view#load() abort
  let list = globpath(&runtimepath, 'autoload/ikaring/view/*.vim', 1, 1)
  let view_names = map(list, 'fnamemodify(v:val, ":t:r")')
  for view_name in view_names
    let view = ikaring#view#{view_name}#new()
    call ikaring#view#register(view_name, view)
  endfor
endfunction

function! ikaring#view#register(name, view) abort
  let s:views[a:name] = a:view
endfunction

function! ikaring#view#get(name) abort
  return get(s:views, a:name, {})
endfunction

function! ikaring#view#names() abort
  return keys(s:views)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
