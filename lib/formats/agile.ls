require! events
require! fs
require! validator.sanitize
{zip, listToObj} = require('prelude-ls')

default-sanitizer = (data) -> sanitize(data).xss!

format-spec-regex = /#\s+Format:\s+(.*)/

class AgileParser extends events.EventEmitter
  ({@sanitizer=default-sanitizer}={}) ->
    @columns = null
    @delimiter = \\t

  parse-comment: !(line) ->
    format = format-spec-regex.exec line ?.1 ?.split @delimiter
    if format
      idx = format.index-of 'Timestamp'
      @timestamp-column = if (idx < 0) then null else idx
      if idx < 0
        @timestamp-column
      else
        @timestamp-column = idx
        format.splice idx, 1
      @columns = format
      @emit 'format', @columns

  parse-lines: !(lines) ->
    for line in lines
      if line.0 == '#'
        # This line is a comment
        @parse-comment line
      else if @columns
        #fields = zip @columns, (line.split \\t) |> listToObj
        #fields.Message = @sanitizer fields.Message
        fields = (line.split \\t)
        @emit 'record' do
          timestamp: if @timestamp-column isnt null then fields.splice(@timestamp-column, 1)[0] else 'Never' # Extract timestamp from record
          fields: fields

module.exports = AgileParser
