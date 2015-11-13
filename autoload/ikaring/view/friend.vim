" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:MODES = {
\   'offline': 'オフライン',
\   'online': 'オンライン',
\   'playing': 'Splatoon プレイ中',
\   'regular': 'レギュラーマッチでイカしてるぜ！',
\   'gachi': 'ガチマッチでウデだめししてるぜ！',
\   'tag': 'タッグマッチでガチってるぜ！',
\   'private': 'プライベートマッチで自由に楽しんでるぜ！',
\   'fes': 'フェスマッチでお祭りさわぎ！',
\ }

let s:JSON = g:ikaring#vital.import('Web.JSON')
let s:json_url = 'https://splatoon.nintendo.net/friend_list/index.json'

let s:view = {}
let s:sep = repeat('-', 30)

function! s:view.content(args) abort
  let agent = ikaring#get_agent()
  let json = agent.get_file(s:json_url)
  let data = s:JSON.decode(json, {'use_token': 1})

  let lines = ['フレンドリスト']

  if empty(data)
    return lines + [s:sep, 'オンラインのフレンドがいません']
  endif

  call ikaring#friend#add(data)
  call ikaring#friend#save()

  for friend in data
    let lines += [s:sep] + s:friend_lines(friend) + ['']
  endfor

  return lines
endfunction

function! s:view.init() abort
  nnoremap <silent> <buffer> <Plug>(ikaring-open-profile)
  \                          :<C-u>call <SID>open_profile()<CR>
  nmap <buffer> <CR> <Plug>(ikaring-open-profile)
endfunction

function! s:friend_lines(friend) abort
  let lines = [
  \   a:friend.mii_name,
  \   get(s:MODES, a:friend.mode, a:friend.mode),
  \ ]
  if a:friend.intention.id isnot s:JSON.null
    let id = a:friend.intention.id
    let url = 'https://splatoon.nintendo.net/user_intention/' . id
    let lines += [
    \   printf('募集中: %s', url)
    \ ]
  endif
  return lines
endfunction

function! s:open_profile() abort
  if line('$') <= 3
    return
  endif
  let lnum = line('.')
  if getline(lnum - 1) ==# s:sep
    call ikaring#open('profile', [getline(lnum)])
  endif
endfunction

function! ikaring#view#friend#new() abort
  return deepcopy(s:view)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
