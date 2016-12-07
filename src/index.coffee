
opn       = require 'opn'
server    = require './server'
configManager = require './configmanager'
assetManager = require './assetmanager'
testManager = require './testmanager'
sampleManager = require './samplemanager'
RequirementMissingError = require './requirementMissingError'

argv = (require 'minimist')(process.argv.slice 2)

# Set up logging
Messages  = require './messages'
Messages.setLevel if argv.v? then 'DEBUG' else 'INFO'
msg = new Messages 'MAIN'

msg.info "*** Balihoo Web Designer Toolkit ***".blue

if argv.help
  msg.info "Command line options:"
  msg.info "  --help : display this message."
  msg.info "  --fbconfig : create a new form builder config file for pushing creatives."
  msg.info "  --new : create a new tutorial example website in this directory."
  msg.info "When run without any parameters, the tool will start a web server and open your browser to a development console showing the web page content in this directory."
else if argv.fbconfig
  msg.info "Creating new form builder config file at #{configManager.formbuilderConfigPath}"
  configManager.createFormbuilderConfig (err) ->
    if err
      msg.error "Failed! - #{err}".red
    else
      msg.info "Success!"
      msg.info "This file now needs to be edited with your own credentials before you can push files to form builder."
else if argv.new
  msg.info 'Creating new project default files.'
  assetManager.createNewFromTemplate()
  testManager.createNewFromTemplate()
  sampleManager.createNewFromTemplate()
  configManager.createNewFromTemplate()
  msg.info 'Complete.'
else
  try
    opn server.start()
  catch e
    if e instanceof RequirementMissingError
      msg.error "Requirement missing: #{e.message}"
      msg.error "You can create default requirements with the --new switch"
      process.exit 1
    else
      throw e
