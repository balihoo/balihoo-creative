
fs              = require 'fs'
path            = require 'path'
colors          = require 'colors'
coffee          = require 'coffee-script'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
Convert   = require 'ansi-to-html'
convert   = new Convert newLine: yes

class TestManager extends EventEmitter
  constructor: (@testDir = 'test') ->
    @tests = {}
    @scan()
    console.log "Watching directory: ".yellow +  "./#{@testDir}/".green
    chokidar.watch("./#{@testDir}/", ignoreInitial: yes).on 'all', (event, path) =>
      console.log event, path
      if /\.coffee$/.test path
        @scan()
        @emit 'update'

  # Copy files from srcDir to destDir
  copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"
      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.coffee$/
        console.log "  #{fileName}".white
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  # Update the files 
  scan: (baseDir = process.cwd()) ->
    base = baseDir + "/" + @testDir 
    if not fs.existsSync base
      fs.mkdirSync base
      @copy __dirname + '/../template/test/', base
    tests = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.coffee$/
        dataPath = "#{base}/#{fileName}"
        key = fileName.replace /\.[^/.]+$/, ''
        coffeeCode = fs.readFileSync(dataPath, encoding:'utf8')
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
    @tests = tests

  get: (page, sample) ->
    key = "#{page}.#{sample}"
    if @tests[key]
      @tests[key]
    else
      console.log "#{page} -- #{sample}"
      console.dir @tests
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

