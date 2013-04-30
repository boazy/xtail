require! csv
require! events
require! fs
require! validator.sanitize
{zip, listToObj} = require('prelude-ls')

default-sanitizer = (data) -> sanitize(data).xss!

format-spec-regex = /#\s+Format:\s+(.*)/

class AgileParser extends events.EventEmitter
  ({@sanitizer=default-sanitizer}={}) ->
    @field-names = null
    @delimiter = \\t

  parse-comment: (line) ->
    format = format-spec-regex.exec line ?.1 ?.split @delimiter
    @field-names = format if format

  parse-lines: (lines) ->
    for line in lines
      if line.0 == '#'
        # This line is a comment
        @parse-comment line
      else if @field-names
        fields = zip @field-names, (line.split \\t) |> listToObj
        fields.Message = @sanitizer fields.Message
        @emit 'record' do
          timestamp: delete fields.Timestamp
          fields: fields

module.exports = AgileParser
