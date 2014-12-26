
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'

class ConfigManager extends EventEmitter
  constructor: (@configPath) ->
    @config = {}
    @ingoreNextUpdate = false
    @loadConfig()
    console.log "Watching file: ".yellow +  "./#{@configPath}/".green
    chokidar.watch(@configPath, ignoreInitial: yes).on 'change', (event, path) =>
      @loadConfig()
      @emit 'update'

  loadConfig: ->
    if not fs.existsSync @configPath
      # By default, use the current working directory as the project name
      projectName = path.basename process.cwd()
      console.log "Setting up new config for: #{projectName.green}".yellow
      @config =
        name: projectName
        description: ''
        pages: ['index']
        template: 'main'
        port: 8088
    else
      console.log "Loading project config file #{@configPath.gray}"
      @config = JSON.parse fs.readFileSync(@configPath, encoding:'utf8')

  saveConfig: ->
    fs.writeFileSync @configPath, JSON.stringify(@config, null, '  ')

  updateAssets: (assets) ->
    @config.assets = assets
    @saveConfig()

  getAssets: -> @config.assets

  hasPage: (page) -> page in @config.pages

  getPage: (page) -> @config.pages[page]

  getTemplate: -> @config.template

  getPort: -> @config.port

module.exports = (configPath) -> new ConfigManager configPath

