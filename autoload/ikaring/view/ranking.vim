" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:JSON = g:ikaring#vital.import('Web.JSON')

let s:view = {}

function! s:view.content(args) abort
  let agent = ikaring#get_agent()
  let json = agent.get_file('https://splatoon.nintendo.net/ranking/index.json')
  let data = s:JSON.decode(json)

  let lines = ['ランキング']
  let sep = repeat('-', 30)
  for [title, key] in [
  \   ['レギュラーマッチ', 'regular'], ['ガチマッチ', 'gachi']
  \ ]
    call ikaring#friend#add(data[key])
    let lines += [sep] + s:ranking_lines(title, data[key]) + ['']
  endfor
  call ikaring#friend#save()
  return lines
endfunction

function! s:view.init() abort
  nnoremap <silent> <buffer> <Plug>(ikaring-open-profile)
  \                          :<C-u>call <SID>open_profile()<CR>
  nmap <buffer> <CR> <Plug>(ikaring-open-profile)
endfunction

function! s:open_profile() abort
  let username = matchstr(getline('.'), '^\s*\d\+:\s*\d\+\s*\zs.\+$')
  if username !=# ''
    call ikaring#open('profile', [username])
  endif
endfunction

function! s:ranking_lines(title, data) abort
  let lines = [a:title, '']
  let lines += map(copy(a:data), '
  \   printf("%2d: %4d  %s",
  \     join(v:val.rank, ""),
  \     join(v:val.score, ""),
  \     v:val.mii_name)
  \ ')
  return lines
endfunction

function! ikaring#view#ranking#new() abort
  return deepcopy(s:view)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
