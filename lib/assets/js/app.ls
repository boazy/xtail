jQuery = $ = require \jquery
require 'jquery.datatables'

const KEY_ESC   = 27
const KEY_SLASH = 191

socket = null

# HTML DOM elements
log-container = null
filter-input-box = null

# Current filter value
filter-value = ''

options =
  lines: Math.Infinity

# Hides element if doesn't contain filter value
filter-element = !(element) ->
  pattern = new RegExp filter-value, 'i'
  if pattern.test element.textContent then element.style.display = '' else element.style.display = 'none'

# Filter all log lines based on `filter-value`
filter-logs = !->
  log-table.fnFilter filter-value
  # collection = log-container.childNodes
  # i = collection.length
  # return if i == 0
  # while i
  #   filter-element collection[i - 1]
  #   i -= 1
  # window.scrollTo 0, document.body.scrollHeight

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

# DOM ready handler
# $ !->
#   socket := new io.connect

#   socket.on 'options', !(new-options) -> 
#     options <<< new-options

#   # Handle new lines sent by server
#   socket.on 'lines', !(lines) ->
#     for line in lines
#       write-to-log line

#   log-container := (document.getElementsByClassName 'log').0
#   filter-input-box := (document.getElementsByClassName 'query').0
#   filter-input-box.focus!
#   filter-input-box.addEventListener 'keyup', !(e) ->
#     if e.keyCode is KEY_ESC
#       @value = ''
#       filter-value := ''
#     else
#       filter-value := @value
#     filter-logs!

$ document .ready !->
  table = $ \#log .dataTable do
    bPaginate: false
    bLengthChange: false
    bFilter: true
    bSort: false
    bInfo: false
    bAutoWidth: false
    sDom: \t
    aaData:
        [ "Trident", "Internet Explorer 4.0", "Win 95+", 4, "X" ]
        [ "Trident", "Internet Explorer 5.0", "Win 95+", 5, "C" ]
        [ "Trident", "Internet Explorer 5.5", "Win 95+", 5.5, "A" ]
        [ "Trident", "Internet Explorer 6.0", "Win 98+", 6, "A" ]
        [ "Trident", "Internet Explorer 7.0", "Win XP SP2+", 7, "A" ]
        [ "Gecko", "Firefox 1.5", "Win 98+ / OSX.2+", 1.8, "A" ]
        [ "Gecko", "Firefox 2", "Win 98+ / OSX.2+", 1.8, "A" ]
        [ "Gecko", "Firefox 3", "Win 2k+ / OSX.3+", 1.9, "A" ]
        [ "Webkit", "Safari 1.2", "OSX.3", 125.5, "A" ]
        [ "Webkit", "Safari 1.3", "OSX.3", 312.8, "A" ]
        [ "Webkit", "Safari 2.0", "OSX.4+", 419.3, "A" ]
        [ "Webkit", "Safari 3.0", "OSX.4+", 522.1, "A" ]
    aoColumns:
        * sTitle: "Engine"
        * sTitle: "Browser"
        * sTitle: "Platform"
        * sTitle: "Version"
          sClass: "center"
        * sTitle: "Grade"
          sClass: "center"

  rows = []
  for i from 1 to 1000
    rows.push ["Blink", "Chrome #{i}", "Ubuntu 99.99", i, "A"]

  table.fnAddData rows

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

