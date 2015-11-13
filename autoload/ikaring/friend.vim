" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:friends = {}

function! ikaring#friend#add(friends) abort
  call ikaring#friend#load()
  for friend in a:friends
    let s:friends[friend.hashed_id] = {
    \   'hashed_id': friend.hashed_id,
    \   'mii_name': friend.mii_name,
    \   'mii_url': friend.mii_url,
    \ }
  endfor
endfunction

function! ikaring#friend#list() abort
  call ikaring#friend#load()
  return values(s:friends)
endfunction

function! ikaring#friend#names() abort
  return map(ikaring#friend#list(), 'v:val.mii_name')
endfunction

function! ikaring#friend#id_by_name(name) abort
  let friends = ikaring#friend#list()
  let fit = filter(copy(friends), 'v:val.mii_name ==# a:name')
  if !empty(fit)
    return fit[0].hashed_id
  endif
  let match = filter(copy(friends), 'v:val.mii_name =~# a:name')
  if !empty(match)
    return match[0].hashed_id
  endif
  return ''
endfunction

function! ikaring#friend#save() abort
  if empty(s:friends)
    return
  endif
  let file = ikaring#_cache('friends.dat')
  call writefile(map(values(s:friends), 'string(v:val)'), file)
endfunction

function! ikaring#friend#load() abort
  if !empty(s:friends)
    return
  endif
  let file = ikaring#_cache('friends.dat')
  if filereadable(file)
    let lines = readfile(file)
    let s:friends = {}
    for line in lines
      let friend = eval(line)
      let s:friends[friend.hashed_id] = friend
    endfor
  endif
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
