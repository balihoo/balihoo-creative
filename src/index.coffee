
opn       = require 'opn'
server    = require './server'
configManager = require './configmanager'

argv = (require 'minimist')(process.argv.slice 2)

console.log "*** Balihoo Web Designer Toolkit ***".blue

# Set up logging
Messages  = require './messages'
Messages.setLevel if argv.v? then 'DEBUG' else 'INFO'
  
if argv.config
  console.log "Creating new form builder config file at #{configManager.formbuilderConfigPath}"
  configManager.createFormbuilderConfig (err) ->
    if err
      console.error "Failed! - #{err}".red
    else
      console.log "Success!"
      console.log "This file now needs to be edited with your own credentials before you can push files to form builder."
else if argv.new
  console.log 'todo: Creating new project'
else
  #todo: err if not initialized
  opn server.start()

