
fs        = require 'fs'
fpath     = require 'path'
mime      = require 'mime'
colors    = require 'colors'
parser    = require './urlparser'
chokidar  = require 'chokidar'
mustache  = require 'mustache'
{EventEmitter}  = require 'events'

# Set up logging
Messages  = require './messages'
msg = new Messages 'CONSOLE'

merge = (src, dest) ->
  for key, val of src
    dest[key] = val

is_es = (req) ->
  accept = req.headers.accept || ''
  req.method is 'GET' && (!!~accept.indexOf('text/event-stream') || !!~accept.indexOf('text/x-dom-event-stream'))

class Console extends EventEmitter
  constructor: (@options = path: '$console', config: null) ->
    @pushing = no
    @options = if typeof options is 'string' then path: options else options
    @content = {}
    @clients = []
    @samples = {}
    @indexPage = 'index.mustache'
    @refreshCount = 0
    @timer
    @sse = (require 'sse-stream')("/#{@options.path}")
    msg.debug "Instantiating console at #{@options.path.yellow}"

    # Load in the static files used to build the console
    @assetPath = fpath.join __dirname, '..', 'console'
    @scan()
    msg.debug "Watching console files at #{@assetPath.yellow}"
    chokidar.watch(@assetPath, {ignoreInitial: yes, interval: 50}).on 'all', (event, path) =>
      msg.debug "File change event #{event} on #{path.yellow}"
      if not @ignoreFile path
        msg.debug "Console file updated, rescan and reload console in browser"
        if @timer then clearTimeout @timer
        @needScan()
      else
        msg.debug "Ignore console file change #{path.yellow}"

    # If the options file is updated then reload the console
    if @options.config
      @options.config.on 'update', => @send 'reload' unless @pushing
    if @options.formbuilder
      @options.formbuilder.on 'progress', (message) => @send 'dialog', message
      @options.formbuilder.on 'complete', => @send 'closedialog'

  ignoreFile: (fileName) ->
    fpath.basename(fileName).match /^\./

  needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @rescan, 200

  rescan: =>
    @scan()
    @send 'reload'

  # Update the files 
  scan: (baseDir = process.cwd()) =>
    base = @assetPath
    msg.debug "Scanning for files in #{base.yellow}"
    if not fs.existsSync base
      throw "No console directory at #{base}"
    content = {}
    for fileName in fs.readdirSync base
      msg.debug "Found file #{fileName.yellow}"
      dataPath = fpath.join base, fileName
      ext = fpath.extname fileName
      key = fpath.basename fileName
      if not @ignoreFile fileName
        data = fs.readFileSync dataPath
        type = mime.lookup dataPath
        msg.debug "Adding console file #{key.yellow}"
        content[key] = type: type, content: data
      else
        msg.debug "Ignoring file #{fileName.yellow}"
    @content = content

  updateSamples: (samples) =>
    msg.debug "Samples updated, sending new samples to web clients"
    @samples = samples
    @refresh()

  install: (server) =>
    # Inject the sse request handler
    msg.debug "Injecting console request handler into HTTP server"
    @sse.install server

    # When a browser connects, keep track of it
    @sse.on 'connection', (client) =>
      @clients.push client
      msg.debug "New console connection detected. Total clients #{(''+@clients.length).yellow}"
      @send 'refresh', @samples, client

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
        if request?.ifstatic
          msg.debug "Console request for static file #{request.static.yellow}"
          content = @content[request.static]
          if content
            res.writeHead 200, 'Content-Type': content.type
            res.end content.content
          else
            res.writeHead 404
            res.end JSON.stringify error: "Unknown console static file request #{request.static.yellow}"
        else
          msg.debug "Serving up console html content"
          res.writeHead 200, 'Content-Type': 'text/html'
          if @options.config
            try
              context = static: "/#{@options.path}/static"
              merge @options.config.getContext(), context
              res.end mustache.render "#{@content[@indexPage].content}", context
            catch err
              res.end @content[@indexPage].content +
                "<script>alert('Error rendering console/#{@indexPage}#{err}');</script>"
          else
            res.end @content[@indexPage].content
      # If the requested page is "push" then push the form to form builder
      else if request.page is '$push' && not is_es req
        body = []
        req.on 'data', (data) =>
          body.push data
        .on 'end', =>
          body = Buffer.concat(body).toString()
          environment = body.replace 'env=', ''
          @initiateFormPush environment
        .on 'error', (error) =>
          msg.error "Failed to push the form to Form Builder: #{error.message}"
        res.end "Push request received"
      else # fall back to server's default request handlers
        msg.debug "Forwarding request for #{req.url.yellow}"
        l.call server, req, res for l in listeners

    server.once 'listening', =>
      @emit 'ready'

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

  handleRefresh: =>
    if @timer then clearTimeout @timer
    @timer = null
    msg.debug "Sending refresh message. Queue size #{@refreshCount}"
    @refreshCount = 0
    @send 'refresh', @samples

  refresh: =>
    # Don't send refresh immediately, bundle it up with other adjacent refreshes
    @refreshCount++
    if @timer then clearTimeout @timer
    @timer = setTimeout @handleRefresh, 400
    msg.debug "Queued refresh request ##{@refreshCount}"

  initiateFormPush: (env) =>
    @send 'opendialog', 'Form Push In Progress...'
    @options.formbuilder.push(env)

module.exports = (options) -> new Console options

