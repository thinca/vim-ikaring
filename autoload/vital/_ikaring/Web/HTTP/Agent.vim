let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:_vital_loaded(V) abort
  let s:HTML = a:V.import('Web.HTML')
  let s:HTTP = a:V.import('Web.HTTP')
  let s:Jar = a:V.import('Web.HTTP.CookieJar')
  let s:URI = a:V.import('Web.URI')
endfunction

function! s:_vital_depends() abort
  return ['Web.HTTP', 'Web.HTTP.CookieJar', 'Web.HTML', 'Web.URI']
endfunction

function! s:new(...) abort
  let config = a:0 ? a:1 : {}
  let agent = deepcopy(s:Agent)
  let agent._page = s:_blank_page(agent)
  let agent._config = config
  let agent._cookie = s:Jar.new()
  return agent
endfunction


" ===================================================================
" Agent

let s:Agent = {
\ }

function! s:Agent.add_auth(url, username, password) abort
  " TODO
endfunction

function! s:Agent.page() abort
  return self._page
endfunction

function! s:Agent.url() abort
  return self.page().url()
endfunction

function! s:Agent.get(url) abort
  return self._go(self._make_settings('GET', a:url))
endfunction

function! s:Agent.get_file(url) abort
  let res = self._request(self._make_settings('GET', a:url))
  return res.content
endfunction

function! s:Agent.cookie_jar(...) abort
  if a:0
    let self._cookie = a:1
  endif
  return self._cookie
endfunction

function! s:Agent.last_response() abort
  return get(self, '_last_response', {})
endfunction

function! s:Agent.on_error(res) abort
  throw printf('vital: Web.HTTP.Agent: %03d %s',
  \            a:res.status, a:res.statusText)
endfunction

function! s:Agent._make_settings(method, url, ...) abort
  let options = a:0 ? a:1 : {}
  let settings = {
  \   'url' : a:url,
  \   'method' : a:method,
  \ }
  let uri = s:URI.new(a:url)
  let settings.headers = self._make_request_headers(uri, options)
  return settings
endfunction

function! s:Agent._make_request_headers(uri, options) abort
  let headers = {}

  let headers['Host'] = a:uri.host()

  if has_key(self._config, 'user_agent')
    let headers['User-Agent'] = self._config.user_agent
  endif

  if has_key(a:options, 'referer')
    let headers['Referer'] = a:options.referer
  elseif !self.page().is_blank()
    let headers['Referer'] = self.url()
  endif

  let cookie = self._cookie.build_http_header(a:uri.to_string())
  if cookie !=# ''
    let headers = {'Cookie': cookie}
  endif

  return headers
endfunction

function! s:Agent._go(settings) abort
  let res = self._request(a:settings)
  call self._set_page(res)
endfunction

function! s:Agent._request(settings) abort
  let a:settings.maxRedirect = 0
  if has_key(self._config, 'client')
    let a:settings.client = self._config.client
  endif

  let res = s:HTTP.request(a:settings)
  let res.request = a:settings
  let self._last_response = res

  call self._cookie.add_from_headers(res.header, a:settings.url)
  let headers = s:_parse_headers(res.header)

  if has_key(headers, 'location')
    return self._redirect(a:settings, res, headers['location'])
  endif

  let status_head = res.status / 100
  if status_head == 4 || status_head == 5
    call self.on_error(res)
  endif

  return res
endfunction

function! s:Agent._redirect(origin_settings, response, url) abort
  let method = a:origin_settings.method
  if a:response.status == 303
    let method = 'GET'
  endif
  let options = {'referer': a:origin_settings.url}
  let settings = self._make_settings(method, a:url, options)
  return self._request(settings)
endfunction

function! s:Agent._set_page(response) abort
  " TODO: Check Content-Type
  let url = a:response.request.url
  let content = a:response.content
  let self._page = s:new_page(self, url, content)
endfunction


" ===================================================================
" Page

function! s:new_page(agent, url, content) abort
  let page = deepcopy(s:Page)
  let page._agent = a:agent
  let page._url = a:url
  let page._body = s:HTML.parse(a:content)
  let page._content = a:content
  return page
endfunction

function! s:_blank_page(agent) abort
  let page = deepcopy(s:Page)
  return page
endfunction

let s:Page = {}

function! s:Page.url() abort
  return get(self, '_url', 'about:blank')
endfunction

function! s:Page.is_blank() abort
  return !has_key(self, '_url')
endfunction


function! s:Page.forms() abort
  let forms = self._body.findAll('form')
  return map(forms, 's:new_form(self._agent, v:val)')
endfunction

function! s:Page.links() abort
  let forms = self._body.findAll('a')
  return map(forms, 's:new_link(self._agent, v:val)')
endfunction

" ===================================================================
" Form
function! s:new_form(agent, dom) abort
  let form = deepcopy(s:Form)
  let form._agent = a:agent
  let form._dom = a:dom
  return form
endfunction

let s:Form = {}

function! s:Form.field(name) abort
  let fields = self._fields_dict()
  if !has_key(fields, a:name)
    throw 'vital: Web.Agent: Form has no field "' . a:name . '"'
  endif
  return fields[a:name]
endfunction

function! s:Form.fields() abort
  return values(self._fields_dict())
endfunction

function! s:Form._fields_dict() abort
  if has_key(self, '_fields')
    return self._fields
  endif
  let inputs = self._dom.findAll('input')
  call filter(inputs, 'has_key(v:val.attr, "name")')

  let fields = {}
  for input in inputs
    let fields[input.attr.name] = s:new_field(self._agent, input)
  endfor
  let self._fields = fields
  return self._fields
endfunction

function! s:Form.set_param(name, value) abort
  let field = self.field(a:name)
  call field.value(a:value)
endfunction

function! s:Form.get_params() abort
  let params = {}
  let fields = self.fields()
  for field in fields
    if field.type() ==# 'checkbox'
      if field.has_value()
        let params[field.name()] = field.value()
      endif
    else
      let params[field.name()] = field.value()
    endif
  endfor
  return params
endfunction

function! s:Form.submit() abort
  let param = self.get_params()
  let method = get(self._dom.attr, 'method', 'POST')
  let url = self._dom.attr.action
  let settings = self._agent._make_settings(method, url)
  let settings.data = param
  let settings.contentType = 'application/x-www-form-urlencoded'
  call self._agent._request(settings)
endfunction


" ===================================================================
" Field

function! s:new_field(agent, dom) abort
  let field = deepcopy(s:Field)
  let field._agent = a:agent
  let field._dom = a:dom
  return field
endfunction

let s:Field = {}

function! s:Field.type() abort
  return tolower(self._dom.attr.type)
endfunction

function! s:Field.name() abort
  return self._dom.attr.name
endfunction

function! s:Field.has_value() abort
  return has_key(self._dom.attr, 'value')
endfunction

function! s:Field.value(...) abort
  if a:0
    let self._dom.attr.value = a:1
  else
    return get(self._dom.attr, 'value', '')
  endif
endfunction


" ===================================================================
" Link

function! s:new_link(agent, dom) abort
  let link = deepcopy(s:Link)
  let link._agent = a:agent
  let link._dom = a:dom
  return link
endfunction

let s:Link = {}

function! s:Link.click() abort
  let url = self._dom.attr['href']
  call self._agent.get(url)
endfunction

" ===================================================================
" Utils

function! s:_parse_headers(headers) abort
  let header = {}
  for h in a:headers
    let matched = matchlist(h, '^\([^:]\+\):\s*\(.*\)$')
    if !empty(matched)
      let [name, value] = matched[1 : 2]
      let header[tolower(name)] = value
    endif
  endfor
  return header
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
