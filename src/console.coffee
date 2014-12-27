
fs        = require 'fs'
colors    = require 'colors'
parser    = require './urlparser'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

# Set up logging
Messages  = require './messages'
msg = new Messages 'CONSOLE'

is_es = (req) ->
  accept = req.headers.accept || ''
  req.method is 'GET' && (!!~accept.indexOf('text/event-stream') || !!~accept.indexOf('text/x-dom-event-stream'))

class Console extends EventEmitter
  constructor: (@options = path: '$console') ->
    @options = if typeof options is 'string' then path: options else options
    @clients = []
    @samples = {}
    @sse = (require 'sse-stream')("/#{@options.path}")
    msg.debug "Instantiating console at #{@options.path.yellow}"

    # Load in the static HTML used to build the console
    # If it is updated then reload it and refresh all clients
    consoleFile = __dirname + '/../console.html' 
    @consoleContent = fs.readFileSync consoleFile
    chokidar.watch(consoleFile, ignoreInitial: yes).on 'change', (event, path) =>
      msg.debug "Console file updated, reloading console in browser"
      @consoleContent = fs.readFileSync consoleFile
      @send 'reload'

   updateSamples: (samples) =>
    msg.debug "Samples updated, sending new samples to web clients"
    @samples = samples
    @send 'samples', @samples

   install: (server) =>
    # Inject the sse request handler
    msg.debug "Injecting console request handler into HTTP server"
    @sse.install server

    # When a browser connects, keep track of it
    @sse.on 'connection', (client) =>
      @clients.push client
      msg.debug "New console connection detected. Total clients #{(''+@clients.length).yellow}"
      @send 'samples', @samples, client

      # Remove clients that close
      client.once 'close', =>
        @clients.splice @clients.indexOf(client), 1
        msg.debug "Console close detected. Total clients #{(''+@clients.length).yellow}"

    # Plug into the server to capture request for the console
    listeners = server.listeners 'request'
    server.removeAllListeners 'request'
    server.on 'request', (req, res) =>
      request = parser.parse req.url

      # If the $console page is requested then serve it up
      if request.page is @options.path && not is_es req
        if request?.ifdata
          res.writeHead 200, 'Content-Type': 'application/json'
          msg.debug "Console request for data #{request.data.yellow}"
          res.end JSON.stringify switch request.data
            when 'samples' then @samples
            else error: "Unknown console data request #{request.data}"
        else
          msg.debug "Serving up console html content"
          res.writeHead 200, 'Content-Type': 'text/html'
          res.end @consoleContent
      else # fall back to server's default events
        msg.debug "Forwarding request for #{req.url.yellow}"
        l.call server, req, res for l in listeners

    server.once 'listening', => @emit 'ready'
    @install = -> throw new Error 'cannot install console twice'

  send: (event, data = null, client = null) =>
    message = JSON.stringify
      event: event,
      data: data

    if client
      msg.debug "Sending event to single client #{event.yellow}"
      client.write message
    else
      msg.debug "Sending #{event} to total clients: #{(''+@clients.length).yellow}"
      client.write message for client in @clients

  refresh: =>
    @send 'refresh'

module.exports = (options) -> new Console options

