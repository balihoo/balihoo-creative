
opn       = require 'opn'
server    = require './server'

argv = (require 'minimist')(process.argv.slice 2)

console.log "*** Balihoo Web Designer Toolkit ***".blue

# Set up logging
Messages  = require './messages'
Messages.setLevel if argv.v? then 'DEBUG' else 'INFO'

opn server.start()

