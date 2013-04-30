require! browserify
require! child_process.spawn
require! daemon
require! express
require! fs
require! http
require! LiveScript
require! validator.sanitize
require! 'prelude-ls'.concat
socketio = require 'socket.io'
browserify-shim = require 'browserify-shim'
{BrowserifyAsset} = require './utils/browserify'

require! './tail'
AgileParser = require('./formats/agile')

camelCase = (flag) -> 
  flag.split '-' .reduce (str, word) ->
    str + word.0.toUpperCase! + word.slice 1

# Parse arguments
program = require 'commander'
  .version (require '../package.json').version
  .usage '[options] [file ...]'
  .option '-p, --port <port>', 'server port, default 9001', Number, 9001
  .option '-l, --lines <number>', 'number on lines stored in browser, default 2000', Number, 2000
  .option '-d, --daemonize', 'run as daemon'
  .option '--pid-path <path>', 'if run as deamon file that will store the process ID, default /var/run/frontail.pid', String, '/var/run/frontail.pid'
  .option '--log-path <path>', 'if run as deamon file that will be used as a log, default /dev/null', String, '/dev/null'
  .parse process.argv

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
        type: rack.StylusAsset
        urlPrefix: '/css'
        dirname: __dirname + '/assets/css'
      new rack.DynamicAssets do
        type: BrowserifyAsset
        urlPrefix: '/js'
        dirname: __dirname + '/assets/js'
        options:
          #compress: true
          transforms: [ \liveify ]
          create: ->
            browserify-shim do
              browserify!
              jquery:
                path: './vendor/jquery.js'
                exports: '$'

  app = express!
    ..use assets
    ..get '/', (req, res) ->
      res.redirect '/tail'

  server = (http.createServer app).listen program.port
  io = socketio.listen server, {log: false}
  io.sockets.on 'connection', (socket) ->
    socket.emit 'options' do
      lines: program.lines
    parser = new AgileParser
      ..on 'record', (record) ->
        socket.emit 'lines', [record.timestamp + ' - ' + record.fields.Message]
    tailer = new tail.Tailer files[0]
      ..on 'lines', (lines) ->
        parser.parse-lines lines
    tailer.start!

