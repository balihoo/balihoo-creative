
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

# Constants for tool version specific features
# NOTE: When adding features, ALWAYS start at 1 or increment the version by 1.
toolSettings =
  modelCodeVersion:
    ASSETS_KEYED_WITH_UNDERSCORE_EXTENSION: 1

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
    ConfigManager.checkToolVersionMeetsCreativeConfigFeatures()

  needReload: ->
    if @timer then clearTimeout @timer
    @timer = setTimeout @loadCreativeConfig, 200
  
  loadFormbuilderConfig: ->
    try
      @formbuilderConfig = require ConfigManager.formbuilderConfigPath
    catch e
      console.warn 'Warning: form builder config file not found or incorrectly formatted'.yellow
      console.warn 'You will not be able to push creatives to form builder'.yellow
      console.warn 'To create a form builder config file, exit and run "balihoo-creative --fbconfig"'.yellow

  loadCreativeConfig: ->
    if not fs.existsSync @creativeConfigPath
      throw new RequirementMissingError "Creative config file not found: #{@creativeConfigPath}"

    msg.debug "Loading project config file #{@creativeConfigPath.yellow}"
    ConfigManager.creativeConfig = JSON.parse fs.readFileSync(@creativeConfigPath, encoding:'utf8')
    @emit 'update'

  saveCreativeConfig: ->
    msg.debug "Saving config file #{@creativeConfigPath.yellow}"
    fs.writeFileSync @creativeConfigPath, JSON.stringify(ConfigManager.creativeConfig, null, '  ')

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
      toolSettings:
        modelCodeVersion: Object.keys(toolSettings.modelCodeVersion).length #assume most recent feature
        
    fs.writeFileSync creativeConfigPath, JSON.stringify(creativeConfig, null, '  ')

  hasPage: (page) -> page in ConfigManager.creativeConfig.pages

  getPage: (page) -> ConfigManager.creativeConfig.pages[page]

  getTemplate: -> ConfigManager.creativeConfig.template

  getPort: -> ConfigManager.creativeConfig.port

  # get the accumulation of creative and form builder configs for this environment only
  getContext: (env) ->
    context = clone ConfigManager.creativeConfig
    delete context.environments
    context.env = {}
    extend context.env, clone ConfigManager.creativeConfig.environments[env]
    if @formbuilderConfig
      extend context.env, clone @formbuilderConfig.environments[env]
    context
    
  # Get info on all pushable environments. Just info pertinent to displaying.
  getAllEnvironmentsForSelector: ->
    envsObj = {} #use an object to grab a unique list of common environment names
    for key of ConfigManager.creativeConfig?.environments
      if @formbuilderConfig?.environments[key]
        envsObj[key] = true
      else
        console.warn "Config environment #{key} exists in creative config but not form builder config"
    for key of @formbuilderConfig?.environments
      if ConfigManager.creativeConfig?.environments[key]
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
    ConfigManager.creativeConfig.creativeFormId = formid
    fs.writeFileSync @creativeConfigPath, JSON.stringify(ConfigManager.creativeConfig, null, '  ')
    
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
  @creativeConfig = {} #will be read by other processes

  # Check that the creative config has specific features.  Returns boolean.
  @creativeConfigHasFeature:
    assetsKeyedWithUnderscoreExtension: ->
      (ConfigManager.creativeConfig.toolSettings?.modelCodeVersion or 0) >=
        toolSettings.modelCodeVersion.ASSETS_KEYED_WITH_UNDERSCORE_EXTENSION
  
  # Check that all the toolSettings specified in the creative config can be met by this version of the creative tool.
  @checkToolVersionMeetsCreativeConfigFeatures: ->
    for settingName, settingValue of ConfigManager.creativeConfig.toolSettings
      # Make sure we know about all the toolSettings in the creative config. If not, a newer version of the tool added them.
      unless toolSettings[settingName]?
        throw new Error "Creative Config toolSetting \"#{settingName}\" is unknown to this version of the balihoo-creative tool."
      # Make sure that the the version of this setting in the config file is supported by this tool.
      toolMaxSupported = Object.keys(toolSettings[settingName]).length
      if toolMaxSupported < settingValue
        throw new Error "Creative Config toolSetting \"#{settingName}\" value #{settingValue} is newer than this version of the balihoo-creative tool supports (#{toolMaxSupported}).  Please upgrade the tool to a newer version before editing this creative."

      


module.exports = ConfigManager