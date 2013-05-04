jQuery = $ = require \jquery
require 'jquery.datatables'

const KEY_ESC   = 27
const KEY_SLASH = 191

options =
  lines: Math.Infinity

# Is page is scrolled to bottom
scorlled-bottom = ->
  currentScroll = document.documentElement.scrollTop || document.body.scrollTop
  totalHeight = document.body.offsetHeight
  clientHeight = document.documentElement.clientHeight
  totalHeight <= currentScroll + clientHeight

# Write new data to displayed log
write-to-log = !(data) ->
  wasScrolledBottom = scorlled-bottom!
  div = document.createElement 'div'
  p = document.createElement 'p'
  p.className = 'inner-line'
  p.innerHTML = data
  div.className = 'line'
  div.addEventListener 'click', !->
    if (@className.indexOf 'selected') is -1 then @className += ' selected' else @className = @className.replace //selected//g, ''
  div.appendChild p
  filter-element div
  log-container.appendChild div
  log-container.removeChild log-container.children.0 if log-container.children.length > options.lines
  if wasScrolledBottom then window.scrollTo 0, document.body.scrollHeight

just_once = (callback) ->
  called = false
  !(...) ->
    if not called
      called = true
      callback ...

$ document .ready !->
  table-options =
    bPaginate: false
    bLengthChange: false
    bFilter: true
    bSort: false
    bInfo: false
    bAutoWidth: false
    sDom: \t
    aaData: []
    aoColumns:
      * sTitle: 'Timestamp'
      * sTitle: 'Message'

  table-html = $ \#log .html!
  table = null
  reset-table = !->
    table-div = $ \#log
    if (table-div.children!.length > 0)
      table-div.empty!
    table-div.append table-html
    table := $ \#log-table .dataTable table-options
  reset-table!

  socket = new io.connect
    ..on 'options', !(new-options) ->
      options <<< new-options

    ..on 'format', just_once !(columns) ->
      columns = ['Timestamp'] ++ columns
      table-options.aoColumns = [{sTitle: name} for name in columns]
      reset-table!
      $ \#log .show!

    ..on 'record', !(record) ->
      table.fnAddData [[record.timestamp] ++ record.fields]

  filter-input = $ \#filter-input

  $ document .keyup (event) ->
    if $(document.active-element).attr('id') != 'filter-input'
      if event.key-code == KEY_SLASH
        filter-input.focus!
        event.prevent-default!

  filter-input.keyup (event) ->
      if event.key-code == KEY_ESC
        @value = ''
      table.fnFilter @value
