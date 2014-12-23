
fs        = require 'fs'
colors    = require 'colors'
parser    = require './urlparser'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'


is_es = (req) ->
  accept = req.headers.accept || ''
  req.method is 'GET' && (!!~accept.indexOf('text/event-stream') || !!~accept.indexOf('text/x-dom-event-stream'))

class Console extends EventEmitter
  constructor: (@options = path: '/$console') ->
    @clients = []
    @options = if typeof options is 'string' then path: options else options
    @sse = (require 'sse-stream')(@options.path)

    # Load in the static HTML used to build the console
    # If it is updated then reload it and refresh all clients
    consoleFile = __dirname + '/../console.html' 
    @consoleContent = fs.readFileSync consoleFile
    chokidar.watch(consoleFile, ignoreInitial: yes).on 'change', (event, path) =>
      console.log 'Reloading the console HTML'.red
      @consoleContent = fs.readFileSync consoleFile
      @reload()

   install: (server) =>
    # Inject the sse request handler
    @sse.install server

    # When a browser connects, keep track of it
    @sse.on 'connection', (client) =>
      @clients.push client
      @send 'navigate', path: '/'

      # Remove clients that close
      client.on 'end', =>
        @clients.splice @clients.indexOf(client), 1

    # Plug into the server to capture request for the console
    listeners = server.listeners 'request'
    server.removeAllListeners 'request'
    server.on 'request', (req, res) =>
      console.log "SERVER REQUEST".green, req.url
      request = parser.parse req.url
      # If the $console is requested then serve it up
      if request.path is @options.path && not is_es req
        res.writeHead 200, 'Content-Type': 'text/html'
        res.end @consoleContent
      else # fall back to server's default events
        l.call server, req, res for l in listeners

    server.once 'listening', => @emit 'ready'
    @install = -> throw new Error 'cannot install console twice'

  send: (event, data = null, client = null) =>
    msg = JSON.stringify
      event: event,
      data: data

    console.log "SSE MESSAGE".blue
    console.dir msg
    if client
      client.write msg
    else
      client.write msg for client in @clients

  reload: =>
    @send 'reload'

  refresh: =>
    @send 'refresh'

module.exports = (options) -> new Console options

