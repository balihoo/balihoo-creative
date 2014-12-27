
fs        = require 'fs'
http      = require 'http'
mime      = require 'mime'
colors    = require 'colors'
parser    = require './urlparser'
mustache  = require 'mustache'

# Set up logging
Messages  = require './messages'
msg = new Messages 'SERVER'

instance = null

merge = (src, dest) ->
  for key, val of src
    dest[key] = val

exports.start = (options) =>
  msg.debug 'Setting up HTTP server'
  options  = options || {}
  @assets  = options.assets  || new (require './assetmanager')('assets')
  @config  = options.config  || new (require './configmanager')('./.balihoo-creative.json')
  @tests   = options.tests   || new (require './testmanager')('tests')
  @samples = options.samples || new (require './samplemanager')('sampledata')
  @console = options.console || new (require './console')('$console')

  @config.updateAssets @assets.getAssets()
  @console.updateSamples @samples.getSamples()

  notfound = (res, context) =>
    res.writeHead 404, 'Content-Type': 'text/html'
    if @assets.hasPartial '404'
      msg.debug "Rending custom 404 page"
      try
        page = mustache.render @assets.getPartial('404'), context, @assets.getPartials()
      catch err
        page = "Error compiling template for 404.mustache:<pre>#{err}</pre>"
        msg.error page
      res.end page
    else
      msg.warn "Custom 404 page not found. Please create " + "404.mustache".yellow
      res.end 'Page Not Found'

  instance = http.createServer (req, res) =>
    msg.debug "Handling request #{req.url.yellow}"
    context =
      request: parser.parse req.url
      assets: @assets.getAssets()

    ### Web Server Responses ###

    # 1) If this is one of our configured pages, serve it up
    if @config.hasPage context.request.page
      msg.debug "Trying to render #{context.request.page.yellow}"

      # Inject the sample data - always try to inject 'default.json' first
      if @samples.hasSample 'default'
        merge @samples.getSample('default'), context
      else
        msg.warn "Unable to find default sample data file " + "samples/default.json".yellow

      # Then try to inject the selected sample data (based on __sample querystring param)
      selectedSample = if context.request.q?.__sample then context.request.q.__sample else 'default'
      if selectedSample isnt 'default'
        if @samples.hasSample selectedSample
          merge @samples.getSample(selectedSample), context
        else if not context.request.q?.__sample
          msg.debug "No sample file requested"
        else
          msg.warn "Request for unknown sample file #{context.request.q.__sample.yellow}"

      # Add $tests to the context to inject tests in the page
      context['$tests'] = @tests.get context.request.page, selectedSample

      templateName = @config.getTemplate()
      if @assets.hasPartial templateName
        msg.debug "Rendering mustache template using #{templateName.yellow}"
        res.writeHead 200, 'Content-Type': 'text/html'
        try
          page = mustache.render @assets.getPartial(@config.getTemplate()), context, @assets.getPartials()
        catch err
          page = "Error compiling #{context.request.page}.mustache:<pre>#{err}</pre>"
          msg.error page
        res.end page
      else
        msg.error "Unable to render page; missing " + "#{@config.getTemplate()}.mustache".yellow
        res.writeHead 500, 'Content-Type': 'text/html'
        res.end "Unable to render page; missing #{@config.getTemplate()}.mustache"

    # 2) _ is a special page that indicates static content
    else if context.request.ifpage._? && @assets.hasStaticFile(context.request.path)
      msg.debug "Rendering static content for #{context.request.path.yellow}"
      staticFile = @assets.getStaticFile(context.request.path)
      res.writeHead 200, 'Content-Type': mime.lookup staticFile.path
      res.end staticFile.data

    # 3) Can't find the requested content
    else
      msg.warn "Requested content not found #{req.url.yellow}"
      notfound res, context

  @console.install instance

  for manager in [@assets, @samples, @tests, @config]
    msg.debug "Listening for updates on #{manager.constructor.name.yellow}"
    manager.on 'update', @console.refresh

  @assets.on 'update', =>
    msg.debug "Assets updated, updating config"
    @config.updateAssets @assets.getAssets()

  msg.info "Starting server on port #{@config.getPort()}"
  instance.listen @config.getPort()

  "http://localhost:#{@config.getPort()}/$console"

