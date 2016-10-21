
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
clone = require 'clone'
extend = require 'extend'
#todo: this is probably NOT the place to store this config file. Also should be optional
formbuilderConfig  = require('../config').formbuilder

# Set up logging
Messages  = require './messages'
msg = new Messages 'CONFIG'

class ConfigManager extends EventEmitter
  constructor: (@creativeConfigPath) ->
    msg.debug 'Instantiating configmanager'
    @creativeConfig = {}
    @ingoreNextUpdate = false
    @loadCreativeConfig()
    msg.debug "Watching config file: #{@creativeConfigPath.yellow}"
    chokidar.watch(@creativeConfigPath, {persistent: yes, ignoreInitial: yes, interval: 50}).on 'change', (event, path) =>
      msg.debug 'Config file updated'
      @needReload()
    @workingDir = path.basename process.cwd()

  needReload: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @loadCreativeConfig, 200

  loadCreativeConfig: ->
    if not fs.existsSync @creativeConfigPath
      # By default, use the current working directory as the project name
      msg.info "Creating config for: #{@workingDir.yellow}"
      @creativeConfig =
        name: @workingDir
        description: ''
        channel: 'Local Websites'
        brands: []
        environments:
          dev:
            creativeFormId: 0
            companionFormId: 0
            endpoint: 0
          stage:
            creativeFormId: 0
            companionFormId: 0
            endpoint: 0
          prod:
            creativeFormId: 0
            companionFormId: 0
            endpoint: 0
        pages: ['index', 'assets', 'urls', 'sampledata', 'test', 'config', 'notfound']  #todo: why all these as default?
        template: 'main'
        port: 8088
      @saveCreativeConfig()
    else
      msg.debug "Loading project config file #{@creativeConfigPath.yellow}"
      @creativeConfig = JSON.parse fs.readFileSync(@creativeConfigPath, encoding:'utf8')
    @emit 'update'

  saveCreativeConfig: ->
    msg.debug "Saving config file #{@creativeConfigPath.yellow}"
    fs.writeFileSync @creativeConfigPath, JSON.stringify(@creativeConfig, null, '  ')

  hasPage: (page) -> page in @creativeConfig.pages

  getPage: (page) -> @creativeConfig.pages[page]

  getTemplate: -> @creativeConfig.template

  getPort: -> @creativeConfig.port

  # get the accumulation of creative and form builder configs for this environment only
  getContext: (env) ->
    context = clone @creativeConfig
    delete context.environments
    context.env = {}
    extend context.env, clone @creativeConfig.environments[env]
    extend context.env, clone formbuilderConfig.environments[env]
    context

  # Updates .balihoo-creative.json with the new form ID returned from Form Builder
  #todo: this is broken!!! never updated when convert to multi-environment
  setCreativeFormId: (formid) ->
    @creativeConfig.creativeFormId = formid
    fs.writeFileSync @creativeConfigPath, JSON.stringify(@creativeConfig, null, '  ')

module.exports = (configPath) -> new ConfigManager configPath

