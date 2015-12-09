" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpoptions
set cpoptions&vim

let g:ikaring#vital = vital#of('ikaring')
let s:Agent = g:ikaring#vital.import('Web.HTTP.Agent')
let s:BM = g:ikaring#vital.import('Vim.BufferManager')
let s:manager = s:BM.new({'opener': 'new'}, 'g:ikaring#opener')

let g:ikaring#cache_directory =
\   get(g:, 'ikaring#cache_directory', expand('~/.cache/ikaring_vim'))

function! ikaring#_read(path) abort
  let path_data = s:parse_path(a:path)
  let view = ikaring#view#get(path_data.view)
  try
    let lines = view.content(path_data.args)
  catch /^vital: Web.HTTP.Agent: \d\+/
    let agent = ikaring#get_agent()
    let res = agent.last_response()
    if res.status == 503
      let lines = ['メンテナンス中です']
    else
      let lines = [
      \   res.status . ' ' . res.statusText,
      \   '何かがおかしいようです。',
      \   '再ログイン(:Ikaring!)を試してみてください。',
      \ ]
    endif
  endtry
  setlocal modifiable noreadonly
  silent 1 put =lines
  keepjumps silent 1 delete _
  if has_key(view, 'init')
    call view.init()
  endif

  setlocal nomodifiable readonly buftype=nofile
  setlocal nonumber norelativenumber nolist
  setlocal noswapfile nomodeline colorcolumn=
endfunction

function! ikaring#cmd_complete(lead, cmd, pos) abort
  let head = a:cmd[: a:pos - 1]
  let arg = matchstr(head, '^.\{-}I\%[karing]\s\+\zs.*')
  if arg =~# '^\w*$'
    let candidates = ikaring#view#names()
  else
    let view_name = matchstr(arg, '^\w\+')
    let view = ikaring#view#get(view_name)
    let candidates = has_key(view, 'complete') ? view.complete() : []
  endif
  return filter(candidates, 'v:val =~? "^" . a:lead')
endfunction

function! ikaring#command(args, bang) abort
  if a:bang
    call ikaring#clear_auth()
  endif
  let args = split(a:args, '\s\+')
  let view = get(args, 0, 'friend')
  call ikaring#open(view, args[1 :])
endfunction

function! ikaring#open(view, args) abort
  let path = 'ikaring://' . a:view
  if !empty(a:args)
    let path .= '/' . join(a:args, '/')
  endif
  call s:manager.open(path)
endfunction

function! ikaring#get_agent() abort
  if !exists('s:agent')
    let s:agent = s:login()
  endif
  return s:agent
endfunction

function! ikaring#clear_auth() abort
  let cookie_file = s:cookie_file()
  if filereadable(cookie_file)
    call delete(cookie_file)
  endif
  unlet! s:agent
endfunction

function! ikaring#_cache(path) abort
  if !isdirectory(g:ikaring#cache_directory)
    call mkdir(g:ikaring#cache_directory, 'p')
  endif
  return g:ikaring#cache_directory . '/' . a:path
endfunction

function! s:parse_path(path)
  let list = matchlist(a:path, '\v^ikaring:[\\/]{2}%((\w+)%([\\/](.+))?)?$')
  return {'view': get(list, 1, ''), 'args': get(list, 2, '')}
endfunction

function! s:login() abort
  let agent = s:Agent.new()
  let cookie_file = s:cookie_file()
  if filereadable(cookie_file)
    sandbox let data = eval(join(readfile(cookie_file), ''))
    call agent.cookie_jar().import(data)
  endif
  call agent.get('https://splatoon.nintendo.net/')
  if agent.url() =~# '/sign_in'
    call agent.get('https://splatoon.nintendo.net/users/auth/nintendo')
    let form = agent.page().forms()[0]
    call form.set_param('username', s:username())
    call form.set_param('password', s:password())
    call form.submit()
  endif
  call writefile([string(agent.cookie_jar().export(1))], cookie_file)
  return agent
endfunction

function! s:cookie_file() abort
  return ikaring#_cache('cookie.dat')
endfunction

function! s:username() abort
  if exists('g:ikaring#username')
    return g:ikaring#username
  endif
  return input('[ikaring] Input your NNID username:')
endfunction

function! s:password() abort
  if exists('g:ikaring#password')
    return g:ikaring#password
  endif
  return inputsecret('[ikaring] Input your NNID password:')
endfunction

call ikaring#view#load()


let &cpoptions = s:save_cpo
unlet s:save_cpo
