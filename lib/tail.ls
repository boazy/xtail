require! events
require! fs

class Tailer extends events.EventEmitter
  (@filename, @line-separator='\n', @encoding='utf-8') ->
    @watcher = null
    @last-line = ''

  start: ~>
    if not @watcher
      err, @old-stats <~ fs.stat @filename
      throw err if err
      @changed 0, @old-stats.size
      @watcher = fs.watch @filename, {persistent: false}, (event, filename) ~>
        if event == 'change'
          err, stats <~ fs.stat @filename
          console.log "Tail encountered error while reading file status: #{err}" if err
          @changed @old-stats.size, stats.size
          @old-stats = stats

  stop: ~>
    if @watcher
      @watcher.close!
      @watcher = null

  changed: (start, end) ~>
    stream = fs.createReadStream @filename, start: start, end: end, encoding: @encoding
    stream.on 'error', (err) ->
      console.log "Tail encountered error while reading from file: #{err}"
    stream.on 'data', (data) ~>
      data = @last-line + data
      lines = data.split @line-separator
      @last-line = lines.pop!
      @emit "lines" lines

exports.Tailer = Tailer
