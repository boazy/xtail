const KEY_ESC = 27

socket = null

# HTML DOM elements
log-container = null
filter-input-box = null

# Current filter value
filter-value = ''

options =
  lines: Math.Infinity

# Hides element if doesn't contain filter value
filter-element = (element) ->
  pattern = new RegExp filter-value, 'i'
  if pattern.test element.textContent then element.style.display = '' else element.style.display = 'none'

# Filter all log lines based on `filter-value`
filter-logs = ->
  collection = log-container.childNodes
  i = collection.length
  return  if i is 0
  while i
    filter-element collection[i - 1]
    i -= 1
  window.scrollTo 0, document.body.scrollHeight

# Is page is scrolled to bottom
scorlled-bottom = ->
  currentScroll = document.documentElement.scrollTop || document.body.scrollTop
  totalHeight = document.body.offsetHeight
  clientHeight = document.documentElement.clientHeight
  totalHeight <= currentScroll + clientHeight

# Write new data to displayed log
write-to-log = (data) ->
  wasScrolledBottom = scorlled-bottom!
  div = document.createElement 'div'
  p = document.createElement 'p'
  p.className = 'inner-line'
  p.innerHTML = data
  div.className = 'line'
  div.addEventListener 'click', ->
    if (@className.indexOf 'selected') is -1 then @className += ' selected' else @className = @className.replace //selected//g, ''
  div.appendChild p
  filter-element div
  log-container.appendChild div
  log-container.removeChild log-container.children.0 if log-container.children.length > options.lines
  if wasScrolledBottom then window.scrollTo 0, document.body.scrollHeight

# DOM ready handler
$ ->
  socket := new io.connect

  socket.on 'options', (new-options) -> 
    options <<< new-options

  # Handle new lines sent by server
  socket.on 'lines', (lines) ->
    for line in lines
      write-to-log line

  log-container := (document.getElementsByClassName 'log').0
  filter-input-box := (document.getElementsByClassName 'query').0
  filter-input-box.focus!
  filter-input-box.addEventListener 'keyup', (e) ->
    if e.keyCode is KEY_ESC
      @value = ''
      filter-value := ''
    else
      filter-value := @value
    filter-logs!

