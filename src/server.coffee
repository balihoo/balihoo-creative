
fs        = require 'fs'
http      = require 'http'
mime      = require 'mime'
colors    = require 'colors'
parser    = require './urlparser'
mustache  = require 'mustache'

# Set up logging
Messages  = require './messages'
Messages.source = 'SERVER'
Messages.setLevel 'DEBUG'
msg = new Messages

instance = null

merge = (src, dest) ->
  for key, val of src
    dest[key] = val

exports.start = (options) =>
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
      try
        page = mustache.render @assets.getPartial('404'), context, @assets.getPartials()
      catch err
        page = "Error compiling template for 404.mustache:<pre>#{err}</pre>"
      res.end page
    else
      res.end 'Page Not Found'

  instance = http.createServer (req, res) =>
    context =
      request: parser.parse req.url
      assets: @assets.getAssets()

    ### Web Server Responses ###

    # 1) If this is one of our configured pages, serve it up
    if @config.hasPage context.request.page
      # Inject the sample data - always try to inject 'default.json' first
      if @samples.hasSample 'default' then merge @samples.getSample('default'), context
      # Then try to inject the selected sample data (based on __sample querystring param)
      selectedSample = if context.request.q?.__sample then context.request.q.__sample else 'default'
      if selectedSample isnt 'default' and @samples.hasSample selectedSample
        merge @samples.getSample(selectedSample), context
      context['$tests'] = @tests.get context.request.page, selectedSample

      if @assets.hasPartial @config.getTemplate()
        res.writeHead 200, 'Content-Type': 'text/html'
        try
          page = mustache.render @assets.getPartial(@config.getTemplate()), context, @assets.getPartials()
        catch err
          page = "Error compiling #{context.request.page}.mustache:<pre>#{err}</pre>"
        res.end page
      else
        res.writeHead 500, 'Content-Type': 'text/html'
        res.end "Unable to render page; missing #{@config.getTemplate()}.mustache"

    # 2) _ is a special page that indicates static content
    else if context.request.ifpage._? && @assets.hasStaticFile(context.request.path)
      staticFile = @assets.getStaticFile(context.request.path)
      res.writeHead 200, 'Content-Type': mime.lookup staticFile.path
      res.end staticFile.data

    # 3) Can't find the requested content
    else
      notfound res, context

  @console.install instance

  for manager in [@assets, @samples, @tests, @config]
    manager.on 'update', @console.refresh

  @assets.on 'update', =>
    msg.debug "Assets updated, updating config"
    @config.updateAssets @assets.getAssets()

  msg.info "Starting server on port #{@config.getPort()}"
  instance.listen @config.getPort()

  "http://localhost:#{@config.getPort()}/$console"

