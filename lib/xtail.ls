require! http
require! fs
require! connect
require! child_process.spawn
require! daemon
require! validator.sanitize
require! 'prelude-ls'.concat
socketio = require 'socket.io'

camelCase = (flag) -> 
  flag.split '-' .reduce (str, word) ->
    str + word.0.toUpperCase! + word.slice 1

# Parse arguments
program = require 'commander'
  ..version (require '../package.json').version
  ..usage '[options] [file ...]'
  ..option '-p, --port <port>', 'server port, default 9001', Number, 9001
  ..option '-n, --number <number>', 'starting lines number, default 10', Number, 10
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
  app = connect!
    .use connect.static(__dirname + '/assets')
    .use (req, res) ->
      fs.readFile __dirname + '/index.html', (err, data) ->
        if err
          res.writeHead 500, {'Content-Type': 'text/plain'}
          res.end 'Interal error'
        else
          res.writeHead 200, {'Content-Type': 'text/html'}
          res.end ((data.toString 'utf-8').replace //__TITLE__//g, 'tail -F ' + files.join ' '), 'utf-8'

  server = (http.createServer app).listen program.port
  io = socketio.listen server, {log: false}
  io.sockets.on 'connection', (socket) ->
    socket.emit 'options:lines', program.lines
    tail = spawn 'tail', ['-n', program.number].concat files
    tail.stdout.on 'data', (data) ->
      lines = (sanitize data.toString 'utf-8').xss!.split '\n'
      lines.pop!
      socket.emit 'lines', lines
  tail = spawn 'tail', ['-F'].concat files
  tail.stdout.on 'data', (data) ->
    lines = (sanitize data.toString 'utf-8').xss!.split '\n'
    lines.pop!
    io.sockets.emit 'lines', lines
