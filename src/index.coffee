
opn       = require 'opn'
server    = require './server'

# Set up logging
Messages  = require './messages'
Messages.setLevel 'DEBUG'

console.log "*** Balihoo Web Designer Toolkit ***".blue
opn server.start()

