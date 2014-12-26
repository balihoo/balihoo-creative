
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

class AssetManager extends EventEmitter
  constructor: (@assetsDir = 'assets') ->
    @assets = {}
    @partials = {}
    @staticFiles = {}
    @isAsset = new RegExp "^#{@assetsDir}/"
    console.log "Scanning directory: ".yellow +  "./#{@assetsDir}/".green
    @scan()
    console.log "Watching directory: ".yellow +  "./#{@assetsDir}/".green
    chokidar.watch("./#{@assetsDir}/", ignoreInitial: yes).on 'all', (event, path) =>
      console.log event, path
      if not @ignoreFile(path) && @isAsset.test(path)
        @scan()
        @emit 'update'

   scan: (baseDir = process.cwd()) ->
    base = process.cwd() + "/" + @assetsDir
    # If there is no assets directory, then we should build one
    if not fs.existsSync base
      console.log "Creating directory #{base}".yellow
      fs.mkdirSync base
      @rcopy __dirname + '/../template/assets/', base

    @staticFiles = {}
    @partials = {}

    walk = (cdir) =>
      dir = {}
      for fileName in fs.readdirSync cdir
        assetPath = "#{cdir}/#{fileName}"
        if not @ignoreFile assetPath
          stat = fs.statSync assetPath
          if stat.isDirectory()
            # Asset directory key is directory name
            dir[fileName] = walk assetPath
          else
            # Asset's key is file name without extension
            key = fileName.replace /\.[^/.]+$/, ''
            ext = (fileName.substr key.length + 1).toLowerCase()
            rel = assetPath.substr base.length
            if ext is 'mustache'
              @partials[key] = fs.readFileSync(assetPath, encoding:'utf8')
            else
              @staticFiles[rel] =
                path: "./#{@assetsDir}#{rel}" 
                data: fs.readFileSync assetPath
              dir[key] = "/_#{rel}"
      dir
    @assets = walk base

  ignoreFile: (path) ->
    /^\./.test(path)  || # Ignore files that start with .
    /\/\./.test(path) || # Ignore files that start with /.
    /~$/.test(path)      # Ignore files that end in ~

  rcopy: (srcDir, destDir, indent = '  ') ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"

      stat = fs.statSync srcPath
      if stat.isDirectory()
        console.log "#{indent}#{fileName}/".white
        fs.mkdirSync destPath unless fs.existsSync destPath
        @rcopy srcPath, destPath, indent + '  ' 
      else if not fileName.match /\.swp$/
        console.log "#{indent}  #{fileName}".white
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  getAssetDir: -> @assetDir

  getAssets: -> @assets

  hasPartial: (name) -> @partials.hasOwnProperty name

  getPartial: (name) -> @partials[name]

  getPartials: -> @partials

  hasStaticFile: (name) -> @staticFiles.hasOwnProperty(name.substr 2)

  getStaticFile: (name) -> @staticFiles[name.substr 2]

module.exports = AssetManager

