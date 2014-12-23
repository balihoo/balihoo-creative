
http      = require 'http'
mime      = require 'mime'
colors    = require 'colors'
parser    = require './urlparser'
mustache  = require 'mustache'

instance = null

exports.update = (config, partials, validFiles) =>
  @config = config
  @partials = partials
  @validFiles = validFiles

exports.create = (config, partials, validFiles) =>
  @update config, partials, validFiles

  notfound = (res, context) =>
    res.writeHead 404, 'Content-Type': 'text/html'
    if @partials.hasOwnProperty '404'
      res.end(mustache.render @partials['404'], context, @partials)
    else
      res.end 'Page Not Found'

  instance = http.createServer (req, res) =>
    context =
      request: parser.parse req.url
      assets: @config.assets

    ### Web Server Responses ###

    # 1) If this is one of our configured pages, serve it up
    if context.request.page in @config.pages
      res.writeHead 200, 'Content-Type': 'text/html'
      res.end(mustache.render @partials[@config.template], context, @partials)

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

