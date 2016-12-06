
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
RequirementMissingError = require './requirementMissingError'

# Set up logging
Messages  = require './messages'
msg = new Messages 'SAMPLE'
sampleDirDefault = 'sampledata'
  
class SampleManager extends EventEmitter

  constructor: (@sampleDir = sampleDirDefault) ->
    msg.debug 'Instantiating samplemanager'
    @samples = {}
    msg.debug "Watching directory: #{@sampleDir.yellow}"
    @scan()
    chokidar.watch(@sampleDir, {ignoreInitial: yes, interval: 50}).on 'all', (event, path)=>
      msg.debug "Observed #{event} at path #{path.yellow}"
      if /\.json$/.test path
        msg.debug "Handling change to #{path.yellow}"
        @needScan()
      else
        msg.debug "Ignoring change to #{path.yellow}"

  @copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = path.join srcDir, fileName
      destPath = path.join destDir, fileName

      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.json$/
        msg.debug "  #{fileName.white}"
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @scan, 200
    
  @createNewFromTemplate: (sampleDir = sampleDirDefault) ->
    base = path.join process.cwd(), sampleDir
    if fs.existsSync base
      msg.warn "Sample data directory already exists at #{base}"
      return
    msg.info "Creating sample data directory at #{base.yellow}"
    fs.mkdirSync base
    msg.debug "Copying example sample data files to #{base.yellow}"
    SampleManager.copy path.normalize(__dirname + '/../tutorial/sampledata/'), base

  scan: ->
    base = path.join process.cwd(), @sampleDir
    if not fs.existsSync base
      throw new RequirementMissingError "Sample data directory not found: #{base}"
    @samples = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.json$/
        dataPath = path.join base, fileName
        msg.debug "Found sample file #{dataPath.yellow}"
        ext = path.extname fileName
        key = path.basename fileName, ext
        try
          data = JSON.parse fs.readFileSync(dataPath, encoding:'utf8')
          @samples[key] = data
        catch err
          msg.error "Unable to parse sample file #{dataPath}:\n#{err}"
      else
        msg.debug "Ignoring file #{fileName.yellow}"
    @emit 'update'

  hasSample: (key) -> @samples.hasOwnProperty key

  getSample: (key) -> @samples[key]

  getSamples: -> @samples

module.exports = SampleManager
 
