fs              = require 'fs'
colors          = require 'colors'
scanner         = require './assetscanner'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

class Watcher extends EventEmitter

  ignoreConfigChange = no

  # Watch the assets directory and see if any files change, add or delete
  # We don't really care what happens to the directory, we'll just recompute all
  watch: (assetDir = 'assets') ->
    console.log "Watching directory: ".yellow +  "./#{assetDir}/".green
    chokidar.watch("./#{assetDir}/", ignoreInitial: yes).on 'all', (event, path)=>
      console.log event, path
      if /\.balihoo-creative\.json$/.test path
        if @ignoreConfigChange
          @ignoreConfigChange = no
        else
          @emit 'config'
      else if scanner.ignoreFile path || not /^assets\//.test path
        return
      else
        @ignoreConfigChange = yes
        @emit 'update'
    @

module.exports = new Watcher

