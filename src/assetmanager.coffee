
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
RequirementMissingError = require './requirementMissingError'
configManager = require './configmanager'

# Set up logging
Messages  = require './messages'
msg = new Messages 'ASSETS'
assetsDirDefault = 'assets'

class AssetManager extends EventEmitter
  constructor: (@assetsDir = assetsDirDefault) ->
    msg.debug 'Instantiating assetmanager'
    @assets = {}
    @partials = {}
    @staticFiles = {}
    @isAsset = new RegExp "^#{path.join @assetsDir, '/'}"
    msg.debug "Scanning directory: #{@assetsDir.yellow}"
    @scan()
    msg.debug "Watching directory #{@assetsDir.yellow}"
    chokidar.watch("#{@assetsDir}", {ignoreInitial: yes, interval: 50}).on 'all', (event, path) =>
      msg.debug "Observed #{event}:#{path}"
      if not @ignoreFile(path) && @isAsset.test(path)
        msg.debug "Handling #{event}:#{path}"
        @needScan()
      else
        msg.debug "Ignored #{event}:#{path}"

   needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @scan, 200

   scan: (baseDir = process.cwd()) =>
    msg.debug "Scanning for asset files in #{baseDir.yellow}"
    base = path.join process.cwd(), @assetsDir
    # If there is no assets directory, then we should build one
    if not fs.existsSync base
      throw new RequirementMissingError "Assets directory not found: #{base}"

    @staticFiles = {}
    @partials = {}

    walk = (cdir, prefix = '') =>
      dir = {}
      for fileName in fs.readdirSync cdir
        assetPath = path.join cdir, fileName
        if not @ignoreFile assetPath
          stat = fs.statSync assetPath
          if stat.isDirectory()
            msg.debug "Found directory #{assetPath.yellow}"
            # Asset directory key is directory name
            dir[fileName] = walk assetPath, "#{prefix}#{path.basename assetPath}-"
          else
            msg.debug "Found file #{assetPath.yellow}"
            # Asset's key is file name without extension
            ext = path.extname fileName
            key = path.basename fileName, ext
            rel = assetPath.substr base.length
            if ext is '.mustache'
              key = prefix+key
              msg.debug "Adding partial #{key.yellow}"
              @partials[key] = fs.readFileSync(assetPath, encoding:'utf8')
            else
              msg.debug "Adding static file #{key.yellow}"
              @staticFiles[rel] =
                path: "#{@assetsDir}#{rel}" 
                data: fs.readFileSync assetPath
              dir[key] = "/_#{rel}"
        else
          msg.debug "Ignoring #{assetPath.gray}"
      dir
    @assets = walk base
    @emit 'update'

  ignoreFile: (path) ->
    /^\./.test(path)  || # Ignore files that start with .
    /[\/\\]\./.test(path) || # Ignore files that start with /.
    /~$/.test(path)      # Ignore files that end in ~
  
  @createNewFromTemplate: (assetsDir = assetsDirDefault) ->
    base = path.join process.cwd(), assetsDir
    if fs.existsSync base
      msg.warn "Assets directory already exists at #{base}"
      return
    msg.info "Creating assets directory #{base.yellow}"
    fs.mkdirSync base
    msg.debug "Copying example asset files to #{base.yellow}"
    AssetManager.rcopy path.normalize(__dirname + '/../tutorial/assets/'), base

  @rcopy: (srcDir, destDir, indent = '  ') ->
    for fileName in fs.readdirSync srcDir
      srcPath = path.join srcDir, fileName
      destPath = path.join destDir, fileName

      stat = fs.statSync srcPath
      if stat.isDirectory()
        msg.debug "#{indent}#{fileName.white}"
        fs.mkdirSync destPath unless fs.existsSync destPath
        AssetManager.rcopy srcPath, destPath, indent + '  ' 
      else if not fileName.match /\.swp$/
        msg.debug "#{indent}  #{fileName.white}"
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))
      else
        msg.debug "#{indent}-ignored:#{fileName.gray}"

  getAssetDir: -> @assetDir

  getAssets: -> @assets

  hasPartial: (name) -> @partials.hasOwnProperty name

  getPartial: (name) -> @partials[name]

  getPartials: -> @partials

  hasStaticFile: (name) -> @staticFiles.hasOwnProperty(name.substr 2)

  getStaticFile: (name) -> @staticFiles[name.substr 2]

module.exports = AssetManager

