
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

# Set up logging
Messages  = require './messages'
msg = new Messages 'CONFIG'

class ConfigManager extends EventEmitter
  constructor: (@configPath) ->
    msg.debug 'Instantiating configmanager'
    @config = {}
    @ingoreNextUpdate = false
    @loadConfig()
    msg.debug "Watching config file: #{@configPath.yellow}"
    chokidar.watch(@configPath, ignoreInitial: yes).on 'change', (event, path) =>
      msg.debug 'Config file updated'
      @loadConfig()
      @emit 'update'

  loadConfig: ->
    if not fs.existsSync @configPath
      # By default, use the current working directory as the project name
      projectName = path.basename process.cwd()
      msg.info "Creating config for: #{projectName.yellow}"
      @config =
        name: projectName
        description: ''
        pages: ['index']
        template: 'main'
        port: 8088
    else
      msg.debug "Loading project config file #{@configPath.yellow}"
      @config = JSON.parse fs.readFileSync(@configPath, encoding:'utf8')

  saveConfig: ->
    msg.debug "Saving config file #{@configPath.yellow}"
    fs.writeFileSync @configPath, JSON.stringify(@config, null, '  ')

  updateAssets: (assets) ->
    msg.debug "Updating assets section of config file"
    @config.assets = assets
    @saveConfig()

  getAssets: -> @config.assets

  hasPage: (page) -> page in @config.pages

  getPage: (page) -> @config.pages[page]

  getTemplate: -> @config.template

  getPort: -> @config.port

module.exports = (configPath) -> new ConfigManager configPath

