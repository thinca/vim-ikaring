" The Vim plugin for ikaring.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:HTML = g:ikaring#vital.import('Web.HTML')
let s:Math = g:ikaring#vital.import('Math')

let s:view = {}

function! s:view.content(args) abort
  let agent = ikaring#get_agent()
  let url = 'https://splatoon.nintendo.net/profile'
  if !empty(a:args)
    if a:args =~# '^\x\{32}$'
      let id = a:args
    else
      let id = ikaring#friend#id_by_name(a:args)
    endif
    if id !=# ''
      let url .= '/' . id
    endif
  endif
  let time = reltime()
  let html = agent.get_file(url)
  let dom = s:HTML.parse(html)
  let contents = dom.find({'class': 'contents'})

  let lines = ['プロフィール']
  let sep = repeat('-', 30)

  let user_info = s:user_info(contents)
  if empty(user_info)
    let lines += [sep, 'parse error', sep, dom.toString()]
    return lines
  endif

  let lines += [
  \   '',
  \   sep,
  \   user_info.username,
  \   printf('ランク: %s', user_info.rank),
  \   printf('ウデマエ: %s', user_info.udemae),
  \   '',
  \ ]

  let weapon = s:weapon(contents)
  let lines += [printf('%-6S: %s', 'ブキ', weapon)]

  let protections = s:protections(contents)
  if empty(protections)
    let lines += [sep, 'parse error', sep, dom.toString()]
    return lines
  endif
  for [name, parts] in [
  \   ['アタマ', 'head'],
  \   ['フク', 'clothes'],
  \   ['クツ', 'shoes']]
    let data = protections[parts]
    let custom = map(copy(data.gearpowers.custom), '"[" . v:val . "]"')
    let lines += [
    \   printf('%-6S: %s [%s]', name, data.gear, data.gearpowers.main),
    \   '        ' . join(custom, '/')
    \ ]
  endfor

  let lines += ['', sep, '今まで塗った面積', '']
  let painted_weapons = s:painted_weapons(contents)
  let lines += map(copy(painted_weapons),
  \     'printf("%-28S %7dp", v:val.weapon, v:val.point)')
  let sum = s:Math.sum(map(copy(painted_weapons), 'v:val.point'))
  let lines += ['', printf('%-28S %7dp', '合計', sum)]

  return lines
endfunction

function! s:view.complete() abort
  return ikaring#friend#names()
endfunction

function! s:user_info(dom) abort
  let user_info = a:dom.find({'class': 'equip-user-info'})
  let username = user_info.find({'class': 'profile-username'}).value()
  let statuses = map(user_info.findAll('p'), 'v:val.value()')
  if len(statuses) != 2
    return {}
  endif
  let [rank, udemae] = statuses
  return {
  \   'username': username,
  \   'rank': rank,
  \   'udemae': udemae,
  \ }
endfunction

function! s:weapon(dom) abort
  let weapon_dom = a:dom.find({'class': 'equip-user-weapon'})
  return s:weapon_name(weapon_dom.find('div'))
endfunction

function! s:protections(dom) abort
  let protections_dom = a:dom.find({'class': 'equip-user-protections'})
  let equips_dom = protections_dom.childNodes()
  let protections = {}
  for equip_dom in equips_dom
    let parts = matchstr(equip_dom.attr['class'], '\C^equip-\zs\w\+')
    let protections[parts] = s:protection(equip_dom)
  endfor
  return protections
endfunction

function! s:protection(dom) abort
  let doms = a:dom.childNodes()
  let gear = s:gear_name(doms[0])
  let main_gearpower = s:gearpower_name(doms[1].find('div'))
  let custom_gearpowers = map(doms[2].findAll('div'), 's:gearpower_name(v:val)')
  return {
  \   'gear': gear,
  \   'gearpowers': {
  \     'main': main_gearpower,
  \     'custom': custom_gearpowers,
  \   }
  \ }
endfunction

function! s:painted_weapons(dom) abort
  let weapons_dom = a:dom.find({'class': 'equip-painted-rank'})
  return map(weapons_dom.findAll('li'), 's:painted_weapon(v:val)')
endfunction

function! s:painted_weapon(dom) abort
  let weapon_dom = a:dom.find({'class': 'equip-painted-weapon'}).find('div')
  let weapon = s:weapon_name(weapon_dom)
  let point = a:dom.find({'class': 'equip-painted-point-number'}).value() - 0
  return {
  \   'weapon': weapon,
  \   'point': point,
  \ }
endfunction

function! s:weapon_name(dom) abort
  return ikaring#id2name#weapon(s:equip_id(a:dom))
endfunction

function! s:gear_name(dom) abort
  return ikaring#id2name#gear(s:equip_id(a:dom))
endfunction

function! s:gearpower_name(dom) abort
  return ikaring#id2name#gearpower(s:gearpower_id(a:dom))
endfunction

function! s:equip_id(dom) abort
  return matchstr(a:dom.attr['style'], '\C/equipment/\zs\w\+')
endfunction

function! s:gearpower_id(dom) abort
  return matchstr(a:dom.attr['style'], '\C/gearpower/svg/\zs\w\+')
endfunction

function! ikaring#view#profile#new() abort
  return deepcopy(s:view)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
