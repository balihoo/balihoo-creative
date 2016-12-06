
fs              = require 'fs'
path            = require 'path'
colors          = require 'colors'
coffee          = require 'coffee-script'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
RequirementMissingError = require './requirementMissingError'
Convert   = require 'ansi-to-html'
convert   = new Convert newLine: yes

# Set up logging
Messages  = require './messages'
msg = new Messages 'TESTS'
testDirDefault = 'test'

class TestManager extends EventEmitter
  constructor: (@testDir = testDirDefault) ->
    msg.debug 'Instantiating testmanager'
    @tests = {}
    @scan()
    msg.debug "Watching directory: #{@testDir.yellow}"
    chokidar.watch(@testDir, {ignoreInitial: yes, interval: 50}).on 'all', (event, path) =>
      msg.debug "Observed event #{event} on path #{path.yellow}"
      if /\.coffee$/.test path
        msg.debug "Handling event #{event} on path #{path.yellow}"
        @needScan()
      else
        msg.debug "Ignoring event #{event} on path #{path.gray}"

  # Copy files from srcDir to destDir
  @copy: (srcDir, destDir) ->
    for fileName in fs.readdirSync srcDir
      srcPath = path.join srcDir, fileName
      destPath = path.join destDir, fileName
      stat = fs.statSync srcPath
      if not stat.isDirectory() && fileName.match /\.coffee$/
        msg.debug "  #{fileName.white}"
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  needScan: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @scan, 200
    
  @createNewFromTemplate: (testDir = testDirDefault) ->
    base = path.join process.cwd(), testDir
    if fs.existsSync base
      msg.warn "Test directory already exists at #{base}"
      return
    msg.info "Creating test directory and copying example tests in #{base.yellow}"
    fs.mkdirSync base
    TestManager.copy path.normalize(__dirname + '/../tutorial/test/'), base

  # Update the files 
  scan: (baseDir = process.cwd()) =>
    base = path.join baseDir, @testDir 
    msg.debug "Scanning for test files in #{base.yellow}"
    if not fs.existsSync base
      throw new RequirementMissingError "Test directory not found: #{base}"
    tests = {}
    for fileName in fs.readdirSync base
      if fileName.match /\.coffee$/
        dataPath = path.join base, fileName
        ext = path.extname fileName
        key = path.basename fileName, ext
        coffeeCode = fs.readFileSync dataPath, encoding:'utf8'
        msg.debug "Adding test #{key} based on file #{dataPath.yellow}"
        tests[key] = {}
        try
          tests[key].code = coffee.compile coffeeCode
        catch e
          msg.error "Unable to compile test file #{dataPath}: #{e}"
          tests[key].error = """
            Error while compiling test file #{dataPath}:
            #{(convert.toHtml "#{e}").replace /(?:\r\n|\r|\n)/g, '<br/>'}
          """
      else
        msg.debug "Ignoring file #{fileName.yellow}"
    @tests = tests
    @emit 'update'

  iftests: (k) =>
    if @tests[k]?.code
      msg.debug "Found test code for #{k}"
      """
        QUnit.module("#{k}");
        #{@tests[k].code}
      """
    else
      msg.debug "No tests for #{k}"
      ''

  get: (page, sample) ->
    key = "#{page}.#{sample}"
    msg.debug "Assembling tests for #{key}"
    # Assemble tests in main, main.sample, page, page.sample
    testCode = @iftests("main") + @iftests("main.#{sample}") +
      @iftests(page) + @iftests("#{page}.#{sample}")
    if @tests[key]?.error
      msg.error "Unable to render tests for #{key} because: #{@tests[key].error}"
      """
        <hr/>
        <div style="background-color:black;color:green;">
          <code style="white-space: pre;">
            #{@tests[key].error}
          </code>
        </div>
      """
    else if testCode.length > 0
      """
        <div id="qunit"></div>
        <div id="qunit-fixture"></div>
        <style>
          .qunit-dialog .ui-dialog-titlebar {
            display: none;
          }
        </style>
        <script src="//code.jquery.com/qunit/qunit-1.16.0.js"></script>
        <link rel="stylesheet" href="//code.jquery.com/qunit/qunit-1.16.0.css">
        <link rel="stylesheet" href="//code.jquery.com/ui/1.11.2/themes/smoothness/jquery-ui.css">
        <script>
          QUnit.config.scrolltop = false;
          QUnit.done(function(details){
            if(parent && typeof parent.testsDone === 'function') {
              details.qunit = document.getElementById('qunit');
              parent.testsDone(details)
            }
          });
          window.onbeforeunload = function() {
            if(parent && typeof parent.clearTestResults === 'function') {
              parent.clearTestResults();
            }
          }
          #{testCode}
        </script>
      """
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

