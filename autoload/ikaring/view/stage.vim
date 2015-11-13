" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:HTML = g:ikaring#vital.import('Web.HTML')

let s:view = {}

function! s:view.content(args) abort
  let agent = ikaring#get_agent()
  let html = agent.get_file('https://splatoon.nintendo.net/schedule')
  let dom = s:HTML.parse(html)
  let contents = dom.find({'class': 'contents'})

  let lines = ['ステージ情報']
  let sep = repeat('-', 30)

  let fes = contents.childNode({'class': 'festival'})
  if empty(fes)
    let nodes = contents.childNodes()
    while 3 <= len(nodes)
      let [date, regular, gachi] = remove(nodes, 0, 2)
      let lines += [sep, date.value(), '']

      let maps = s:get_map_names(regular)
      let lines += ['レギュラーマッチ'] + maps + ['']

      let rule = s:get_gachi_rule(gachi)
      let maps = s:get_map_names(gachi)
      let lines += [printf('ガチマッチ (%s)', rule)] + maps + ['']
    endwhile
  else
    let lines += [sep, 'フェス開催中！']
    let date = contents.find({'class': 'stage-schedule'})
    let teams = s:get_fes_teams(contents)
    let maps = s:get_map_names(contents)
    let lines += [date.value(), join(teams, ' VS '), ''] + maps
  endif

  return lines
endfunction

function! s:get_map_names(dom) abort
  let map_nodes = a:dom.findAll({'class': 'map-name'})
  return map(map_nodes, '"- " . v:val.value()')
endfunction

function! s:get_gachi_rule(dom) abort
  return a:dom.find({'class': 'rule-description'}).value()
endfunction

function! s:get_fes_teams(dom) abort
  let teams = a:dom.findAll({'class': 'festival-team-info'})
  return map(teams, 'v:val.value()')
endfunction

function! ikaring#view#stage#new() abort
  return deepcopy(s:view)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
