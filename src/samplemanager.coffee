
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

# Set up logging
Messages  = require './messages'
msg = new Messages 'SAMPLE'

class SampleManager extends EventEmitter

  constructor: (@sampleDir) ->
    msg.debug 'Instantiating samplemanager'
    @samples = {}
    msg.debug "Watching directory: #{@sampleDir.yellow}"
    @scan()
    chokidar.watch("./#{@sampleDir}/", {ignoreInitial: yes, interval: 50}).on 'all', (event, path)=>
      msg.debug "Observed #{event} at path #{path.yellow}"
      if /\.json$/.test path
        msg.debug "Handling change to #{path.yellow}"
        @needScan()
      else
        msg.debug "Ignoring change to #{path.yellow}"

  copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"

      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.json$/
        msg.debug "  #{fileName.white}"
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

   needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @scan, 200

  scan: (baseDir = process.cwd()) =>
    base = baseDir + "/" + @sampleDir 
    if not fs.existsSync base
      msg.info "Creating samples directory at #{base.yellow}"
      fs.mkdirSync base
      msg.debug "Copying example sample files to #{base.yellow}"
      @copy __dirname + '/../template/sampledata/', base
    @samples = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.json$/
        dataPath = "#{base}/#{fileName}"
        msg.debug "Found sample file #{dataPath.yellow}"
        key = fileName.replace /\.[^/.]+$/, ''
        try
          data = JSON.parse fs.readFileSync(dataPath, encoding:'utf8')
          @samples[key] = data
      else
        msg.debug "Ignoring file #{fileName.yellow}"
    @emit 'update'

  hasSample: (key) -> @samples.hasOwnProperty key

  getSample: (key) -> @samples[key]

  getSamples: -> @samples

module.exports = SampleManager
 
