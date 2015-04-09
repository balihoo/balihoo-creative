
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
    chokidar.watch(@configPath, {persistent: yes, ignoreInitial: yes, interval: 50}).on 'change', (event, path) =>
      msg.debug 'Config file updated'
      @needReload()

   needReload: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @loadConfig, 200

  loadConfig: =>
    if not fs.existsSync @configPath
      # By default, use the current working directory as the project name
      projectName = path.basename process.cwd()
      msg.info "Creating config for: #{projectName.yellow}"
      @config =
        name: projectName
        description: ''
        channel: 'Local Websites'
        creativeFormId: 209
        companionFormId: 208
        pages: ['index', 'assets', 'urls', 'sampledata', 'test', 'config', 'notfound']
        template: 'main'
        port: 8088
      @saveConfig()
    else
      msg.debug "Loading project config file #{@configPath.yellow}"
      @config = JSON.parse fs.readFileSync(@configPath, encoding:'utf8')
    @emit 'update'

  saveConfig: ->
    msg.debug "Saving config file #{@configPath.yellow}"
    fs.writeFileSync @configPath, JSON.stringify(@config, null, '  ')

  hasPage: (page) -> page in @config.pages

  getPage: (page) -> @config.pages[page]

  getTemplate: -> @config.template

  getPort: -> @config.port

  getContext: -> @config

module.exports = (configPath) -> new ConfigManager configPath

