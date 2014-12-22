
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

# Singleton attribute
assetDir = null

# Determine if a file should be ignored
ignoreFile = (path) ->
  /^\./.test(path) || /\/\./.test(path) || /~$/.test(path)

# Create an event emitter for watching file changes
class Watcher extends EventEmitter
  ignoreConfigChange = no

  # Watch the assets directory and see if any files change, add or delete
  # We don't really care what happens to the directory, we'll just recompute all
  watch: (assetDir = 'assets') =>
    console.log "Watching directory: ".yellow +  "./#{assetDir}/".green
    chokidar.watch("./#{assetDir}/", ignoreInitial: yes).on 'all', (event, path)=>
      console.log event, path
      if /\.balihoo-creative\.json$/.test path
        if @ignoreConfigChange
          @ignoreConfigChange = no
        else
          @emit 'config'
      else if ignoreFile path || not /^assets\//.test path
        return
      else
        @ignoreConfigChange = yes
        @emit 'update'
    # Return the event emitter for chainable 'on' calls
    @

module.exports = (assetDirectory) ->
  assetDir = assetDirectory

  # Recursively copy files from srcDir to destDir
  rcopy: (srcDir, destDir, indent) ->
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

  # Create a watcher and expose its watch function
  watch: (new Watcher assetDir).watch
  
  # Return an object representation the files in the assets/ dir
  scan: (baseDir = process.cwd()) ->
    partials = {}
    validFiles = {}
    base = baseDir + "/" + assetDir

    walk = (cdir) ->
      dir = {}
      for fileName in fs.readdirSync cdir
        assetPath = "#{cdir}/#{fileName}"
        if not ignoreFile assetPath
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
              partials[key] = fs.readFileSync(assetPath, encoding:'utf8')
            else
              validFiles["./#{assetDir}#{rel}"] = fs.readFileSync assetPath
              dir[key] = "/_#{rel}"
      dir
    assets = walk base
    [assets, partials, validFiles]

