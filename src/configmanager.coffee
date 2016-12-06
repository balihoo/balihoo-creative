
fs        = require 'fs'
path      = require 'path'
mkdirp = require 'mkdirp'
colors    = require 'colors'
chokidar        = require 'chokidar'
{EventEmitter}  = require 'events'
RequirementMissingError = require './requirementMissingError'
clone = require 'clone'
extend = require 'extend'

# Set up logging
Messages  = require './messages'
msg = new Messages 'CONFIG'
creativeConfigPathDefault = './.balihoo-creative.json'

class ConfigManager extends EventEmitter
  constructor: (@creativeConfigPath = creativeConfigPathDefault) ->
    msg.debug 'Instantiating configmanager'
    @ingoreNextUpdate = false
    msg.debug "Watching creative config file: #{@creativeConfigPath.yellow}"
    chokidar.watch(@creativeConfigPath, {persistent: yes, ignoreInitial: yes, interval: 50}).on 'change', (event, path) =>
      msg.debug 'Config file updated'
      @needReload()
    @loadFormbuilderConfig()
    @loadCreativeConfig()

  needReload: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @loadCreativeConfig, 200
  
  loadFormbuilderConfig: ->
    try
      @formbuilderConfig = require ConfigManager.formbuilderConfigPath
    catch e
      console.warn 'Warning: form builder config file not found or incorrectly formatted'.yellow
      console.warn 'You will not be able to push creatives to form builder'.yellow
      console.warn 'To create a form builder config file, exit and run "balihoo-creative --config"'.yellow

  loadCreativeConfig: ->
    if not fs.existsSync @creativeConfigPath
      throw new RequirementMissingError "Creative config file not found: #{@creativeConfigPath}"

    msg.debug "Loading project config file #{@creativeConfigPath.yellow}"
    @creativeConfig = JSON.parse fs.readFileSync(@creativeConfigPath, encoding:'utf8')
    @emit 'update'

  saveCreativeConfig: ->
    msg.debug "Saving config file #{@creativeConfigPath.yellow}"
    fs.writeFileSync @creativeConfigPath, JSON.stringify(@creativeConfig, null, '  ')

  @createNewFromTemplate: (creativeConfigPath = creativeConfigPathDefault) ->
    # By default, use the current working directory as the project name
    workingDir = path.basename process.cwd()
    if fs.existsSync creativeConfigPath
      msg.warn "Creative config file already exists at #{creativeConfigPath}"
      return
    msg.info "Creating config for: #{workingDir.yellow}"
    creativeConfig =
      name: workingDir
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
    fs.writeFileSync creativeConfigPath, JSON.stringify(creativeConfig, null, '  ')

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
    if @formbuilderConfig
      extend context.env, clone @formbuilderConfig.environments[env]
    context
    
  # Get info on all pushable environments. Just info pertinent to displaying.
  getAllEnvironmentsForSelector: ->
    envsObj = {} #use an object to grab a unique list of common environment names
    for key of @creativeConfig?.environments
      if @formbuilderConfig?.environments[key]
        envsObj[key] = true
      else
        console.warn "Config environment #{key} exists in creative config but not form builder config"
    for key of @formbuilderConfig?.environments
      if @creativeConfig?.environments[key]
        envsObj[key] = true
      else
        console.warn "Config environment #{key} exists in form builder config but not creative config"
    # Now transform it into an array of objects describing each env
    envsArray = []
    for key of envsObj
      envsArray.push {
        name: key
        displayName: @formbuilderConfig.environments[key].displayName or switch key
          when 'dev' then 'Development'
          when 'stage' then 'Stage'
          when 'prod' then 'Production'
          else key
        isProd: @formbuilderConfig.environments[key].url.indexOf('fb.balihoo-cloud.com') >= 0
      }
    envsArray

  # Updates .balihoo-creative.json with the new form ID returned from Form Builder
  #todo: this is broken!!! never updated when convert to multi-environment
  setCreativeFormId: (formid) ->
    @creativeConfig.creativeFormId = formid
    fs.writeFileSync @creativeConfigPath, JSON.stringify(@creativeConfig, null, '  ')
    
  ###
  # STATICS
  ###

  @formbuilderConfigPath: process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME'] + #user home
    "/.config/balihoo-creative/formbuilder.json"
  @createFormbuilderConfig: (cb) ->
    configFileContents =
      environments:
        dev:
          url: "https://fb.dev.balihoo-cloud.com"
          username: "--Your Stormpath API Key ID--"
          password: "--Your Stormpath API Key Secret--"
        stage:
          url: "https://fb.stage.balihoo-cloud.com"
          username: "--Your Stormpath API Key ID--"
          password: "--Your Stormpath API Key Secret--"
        prod:
          url: "https://fb.balihoo-cloud.com"
          username: "--Your Stormpath API Key ID--"
          password: "--Your Stormpath API Key Secret--"
    mkdirp path.dirname(ConfigManager.formbuilderConfigPath), (err) ->
      if err then return cb err
      fs.writeFile ConfigManager.formbuilderConfigPath, JSON.stringify(configFileContents, null, 2), flag:'wx', (err) ->
        if err
          if err.code is 'EEXIST'
            return cb new Error "Config file already exists."
          else
            return cb err
        cb()


module.exports = ConfigManager