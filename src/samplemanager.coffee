
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

class SampleManager extends EventEmitter

  constructor: (@sampleDir) ->
    @samples = {}
    console.log "Watching directory: ".yellow +  "./#{@sampleDir}/".green
    chokidar.watch("./#{@sampleDir}/", ignoreInitial: yes).on 'all', (event, path)=>
      console.log event, path
      if /\.json$/.test path
        @scan()
        @emit 'update'

  copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"

      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.json$/
        console.log "  #{fileName}".white
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  scan: (baseDir = process.cwd()) ->
    base = baseDir + "/" + @sampleDir 
    @samples = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.json$/
        dataPath = "#{base}/#{fileName}"
        key = fileName.replace /\.[^/.]+$/, ''
        try
          data = JSON.parse fs.readFileSync(dataPath, encoding:'utf8')
          @samples[key] = data

  hasSample: (key) -> @samples.hasOwnProperty key

  getSample: (key) -> @samples[key]

module.exports = SampleManager
 
