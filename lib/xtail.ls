require! http
require! fs
require! express
require! child_process.spawn
require! daemon
require! LiveScript
require! validator.sanitize
require! 'prelude-ls'.concat
socketio = require 'socket.io'

require! './tail'

camelCase = (flag) -> 
  flag.split '-' .reduce (str, word) ->
    str + word.0.toUpperCase! + word.slice 1

# Parse arguments
program = require 'commander'
  ..version (require '../package.json').version
  ..usage '[options] [file ...]'
  ..option '-p, --port <port>', 'server port, default 9001', Number, 9001
  ..option '-l, --lines <number>', 'number on lines stored in browser, default 2000', Number, 2000
  ..option '-d, --daemonize', 'run as daemon'
  ..option '--pid-path <path>', 'if run as deamon file that will store the process ID, default /var/run/frontail.pid', String, '/var/run/frontail.pid'
  ..option '--log-path <path>', 'if run as deamon file that will be used as a log, default /dev/null', String, '/dev/null'
  ..parse process.argv

if program.args.length is 0
  console.error 'Arguments needed, use --help'
  process.exit!
else
  files = program.args

if program.daemonize
  all_opts = {[opt.name! |> camelCase, opt.short or opt.long] for name, opt of program.options}
  daemon_opts = 
    for name, kw of all_opts 
    when name not in <[ version daemonize pidPath logPath ]>
    and program[name]
      [kw, program[name]]
  logFile = fs.openSync program.logPath, 'a'
  proc = daemon.daemon do
    __filename
    (daemon_opts |> concat) ++ files
    stdout: logFile
    stderr: logFile
  
  fs.writeFileSync program.pidPath, proc.pid
else
  # Server setup

  # Read index html and replace title
  err, data <~ fs.readFile __dirname + '/index.html'
  throw err if err
  index-html = data.toString('utf-8').replace //__TITLE__//g, 'tail -F ' + files.join ' '

  rack = require('asset-rack')
  assets = new rack.Rack do
    * new rack.Asset do
        url: '/tail'
        contents: index-html
        mimetype: 'text/html'
      new rack.DynamicAssets do
        type: rack.LessAsset
        urlPrefix: '/css'
        dirname: __dirname + '/assets/css'
      new rack.DynamicAssets do
        type: rack.BrowserifyAsset
        urlPrefix: '/js'
        dirname: __dirname + '/assets/js'
        options:
          #compress: true
          extensionHandlers:
            * ext: 'ls'
              handler: (body, filename) ->
                try
                  LiveScript.compile body, { filename, bare: true }
                catch
                  w.emit 'syntaxError', e
            ...

  app = express!
    ..use assets
    ..get '/', (req, res) ->
      res.redirect '/tail'

  server = (http.createServer app).listen program.port
  io = socketio.listen server, {log: false}
  io.sockets.on 'connection', (socket) ->
    socket.emit 'options:lines', program.lines
    tailer = new tail.Tailer files[0]
    tailer.on 'lines', (lines) ->
      lines = [sanitize(line).xss! for line in lines]
      socket.emit 'lines', lines
    tailer.start!

