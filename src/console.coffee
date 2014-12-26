
fs        = require 'fs'
colors    = require 'colors'
parser    = require './urlparser'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'


is_es = (req) ->
  accept = req.headers.accept || ''
  req.method is 'GET' && (!!~accept.indexOf('text/event-stream') || !!~accept.indexOf('text/x-dom-event-stream'))

class Console extends EventEmitter
  constructor: (@options = path: '$console') ->
    @options = if typeof options is 'string' then path: options else options
    @clients = []
    @samples = {}
    @sse = (require 'sse-stream')("/#{@options.path}")

    # Load in the static HTML used to build the console
    # If it is updated then reload it and refresh all clients
    consoleFile = __dirname + '/../console.html' 
    @consoleContent = fs.readFileSync consoleFile
    chokidar.watch(consoleFile, ignoreInitial: yes).on 'change', (event, path) =>
      console.log 'Reloading the console HTML'.red
      @consoleContent = fs.readFileSync consoleFile
      @send 'reload'

   updateSamples: (samples) =>
    @samples = samples
    @send 'samples', @samples

   install: (server) =>
    # Inject the sse request handler
    @sse.install server

    # When a browser connects, keep track of it
    @sse.on 'connection', (client) =>
      @clients.push client
      @send 'samples', @samples, client

      # Remove clients that close
      client.on 'end', =>
        @clients.splice @clients.indexOf(client), 1

    # Plug into the server to capture request for the console
    listeners = server.listeners 'request'
    server.removeAllListeners 'request'
    server.on 'request', (req, res) =>
      request = parser.parse req.url

      # If the $console is requested then serve it up
      if request.page is @options.path && not is_es req
        if request?.ifdata
          res.writeHead 200, 'Content-Type': 'application/json'
          res.end JSON.stringify switch request.data
            when 'samples' then @samples
            else error: "Unknown console data request #{request.data}"
        else
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

    if client
      client.write msg
    else
      client.write msg for client in @clients

  refresh: =>
    @send 'refresh'

module.exports = (options) -> new Console options

