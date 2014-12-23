
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

# Singleton attribute
sampleDir = null

# Create an event emitter for watching file changes
class Watcher extends EventEmitter

  # Watch the sample data directory and see if any files change, add or delete
  watch: (sampleDir = 'sampledata') =>
    console.log "Watching directory: ".yellow +  "./#{sampleDir}/".green
    chokidar.watch("./#{sampleDir}/", ignoreInitial: yes).on 'all', (event, path)=>
      console.log event, path
      if /\.json$/.test path
        @emit 'update'
    # Return the event emitter for chainable 'on' calls
    @

module.exports = (sampleDirectory) ->
  sampleDir = sampleDirectory

  # Copy files from srcDir to destDir
  copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"

      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.json$/
        console.log "  #{fileName}".white
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  # Create a watcher and expose its watch function
  watch: (new Watcher sampleDir).watch
  
  # Return an object representation of the files 
  scan: (baseDir = process.cwd()) ->
    base = baseDir + "/" + sampleDir 
    samples = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.json$/
        dataPath = "#{base}/#{fileName}"
        key = fileName.replace /\.[^/.]+$/, ''
        try
          data = JSON.parse(fs.readFileSync(dataPath, encoding:'utf8'))
          samples[key] = data
    samples

