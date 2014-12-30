
fs              = require 'fs'
path            = require 'path'
colors          = require 'colors'
coffee          = require 'coffee-script'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
Convert   = require 'ansi-to-html'
convert   = new Convert newLine: yes

# Set up logging
Messages  = require './messages'
msg = new Messages 'TESTS'

class TestManager extends EventEmitter
  constructor: (@testDir = 'test') ->
    msg.debug 'Instantiating testmanager'
    @tests = {}
    @scan()
    msg.debug "Watching directory: #{@testDir.yellow}"
    chokidar.watch("./#{@testDir}/", {ignoreInitial: yes, interval: 50}).on 'all', (event, path) =>
      msg.debug "Observed event #{event} on path #{path.yellow}"
      if /\.coffee$/.test path
        msg.debug "Handling event #{event} on path #{path.yellow}"
        @needScan()
      else
        msg.debug "Ignoring event #{event} on path #{path.gray}"

  # Copy files from srcDir to destDir
  copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"
      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.coffee$/
        msg.debug "  #{fileName.white}"
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

   needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @scan, 200

  # Update the files 
  scan: (baseDir = process.cwd()) =>
    base = baseDir + "/" + @testDir 
    msg.debug "Scanning for test files in #{base.yellow}"
    if not fs.existsSync base
      msg.info "Creating test directory and copying example tests in #{base.yellow}"
      fs.mkdirSync base
      @copy __dirname + '/../template/test/', base
    tests = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.coffee$/
        dataPath = "#{base}/#{fileName}"
        key = fileName.replace /\.[^/.]+$/, ''
        coffeeCode = fs.readFileSync(dataPath, encoding:'utf8')
        msg.debug "Adding test #{key} based on file #{dataPath.yellow}"
        try
          scriptCode = coffee.compile coffeeCode
          # Inject the unit testing framework
          tests[key] = """
            <link rel="stylesheet" href="//code.jquery.com/qunit/qunit-1.16.0.css">
            <div id="qunit"></div>
            <div id="qunit-fixture"></div>
            <script src="//code.jquery.com/qunit/qunit-1.16.0.js"></script>
            <script>#{scriptCode}</script>
          """
        catch e
          msg.error "Unable to compile test file #{dataPath}: #{e}"
          errorMessage = (convert.toHtml "#{e}").replace /(?:\r\n|\r|\n)/g, '<br/>'
          tests[key] = """
            <hr/>
            <div style="background-color:black;color:green;">
              <code style="white-space: pre;">
                Error while compiling test file #{dataPath}:
                #{errorMessage}
              </code>
            </div>
          """
      else
        msg.debug "Ignoring file #{fileName.yellow}"
    @tests = tests
    @emit 'update'

  get: (page, sample) ->
    key = "#{page}.#{sample}"
    if @tests[key]
      @tests[key]
    else
      msg.warn "No test file defined for page '#{page}' and sample '#{sample}'"
      restult = """
        <hr/>
        <div style="background-color: #EE5757;color:#000">
          <p>
            No test file found for page '#{page}' and sample '#{sample}'.
          </p><p>
            Please create a test suite at '#{@testDir}/#{page}.#{sample}.coffee'
          </p>
        </div>
      """

module.exports = TestManager

