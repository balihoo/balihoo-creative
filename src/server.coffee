
fs        = require 'fs'
http      = require 'http'
mime      = require 'mime'
colors    = require 'colors'
parser    = require './urlparser'
mustache  = require 'mustache'
tests     = new (require './testmanager')('test')

instance = null

merge = (src, dest) ->
  for key, val of src
    dest[key] = val

exports.update = (config, partials, validFiles, samples) =>
  @config = config
  @partials = partials
  @validFiles = validFiles
  @samples = samples

exports.create = (config, partials, validFiles, samples) =>
  @update config, partials, validFiles, samples

  notfound = (res, context) =>
    res.writeHead 404, 'Content-Type': 'text/html'
    if @partials.hasOwnProperty '404'
      try
        page = mustache.render @partials['404'], context, @partials
      catch err
        page = "Error compiling template for 404.mustache:<pre>#{err}</pre>"
      res.end page
    else
      res.end 'Page Not Found'

  instance = http.createServer (req, res) =>
    context =
      request: parser.parse req.url
      assets: @config.assets

    ### Web Server Responses ###

    # 1) If this is one of our configured pages, serve it up
    if context.request.page in @config.pages
      # Inject the sample data - always try to inject 'default.json' first
      if @samples['default'] then merge @samples['default'], context
      # Then try to inject the selected sample data (based on __sample querystring param)
      selectedSample = if context.request.q?.__sample then context.request.q.__sample else 'default'
      if selectedSample isnt 'default' and @samples[selectedSample]
        merge @samples[selectedSample], context
      context['$tests'] = tests.get context.request.page, selectedSample

      res.writeHead 200, 'Content-Type': 'text/html'
      try
        page = mustache.render @partials[@config.template], context, @partials
      catch err
        page = "Error compiling #{context.request.page}.mustache:<pre>#{err}</pre>"
      res.end page

    # 2) _ is a special page that indicates static content
    else if context.request.ifpage._?
      assetFile = './assets' + context.request.path.substring 2
      if @validFiles.hasOwnProperty assetFile
        res.writeHead 200, 'Content-Type': mime.lookup assetFile
        res.end @validFiles[assetFile]

    # 3) Can't find the requested content
    else
      notfound res, context

  instance.listen @config.port
  instance

