
Promise   = require 'bluebird'
colors    = require 'colors'
_         = require 'underscore'
{EventEmitter}  = require 'events'
request = require 'request'

# Set up logging
Messages  = require './messages'
msg = new Messages 'FORMBUILDER'

# Save forms to form builder
class Forms
  constructor: (@emit, @assets, @samples) ->
  config: (@config) ->
    @envRequest = Promise.promisify request.defaults
      baseUrl: @config.env.url
      auth:
        username: @config.env.username
        password: @config.env.password
        
  checkForFormBuilderError: (errorMsgLead) ->
    (incomingMessage) ->
      if Array.isArray incomingMessage
        incomingMessage = incomingMessage[0]
      Promise.try ->
        if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
          try
            body = JSON.parse incomingMessage.body
            err = new Error body.message
            err.code = body.code
            return Promise.reject err
          catch error
            return Promise.reject new Error "#{errorMsgLead} (#{incomingMessage.statusCode}): #{incomingMessage.body.message or JSON.stringify incomingMessage.body}"
        return incomingMessage

  # Utility functions for querying the existing form
  getForm: (formid, version = 1) ->
    @envRequest "/forms/#{formid}/version/#{version}", {
      method: 'GET'
    }
    .then @checkForFormBuilderError "Error getting form"
  
  getFormVersion: (creativeFormId) ->
    @getForm creativeFormId
    .then (incomingMessage) ->
      formData = JSON.parse(incomingMessage.body)
      return formData.versions[0].version

  getUpdatedDate: (creativeFormId, formVersion) ->
    @getForm creativeFormId, formVersion
    .then (incomingMessage) ->
      formData = JSON.parse(incomingMessage.body)
      return formData.versions[0].updated

  getStatus: (creativeFormId) ->
    @getForm creativeFormId
    .then (incomingMessage) ->
      formData = JSON.parse(incomingMessage.body)
      return formData.versions[0].status

  # Functions that save or update the form on form builder
  saveNewForm: (urls) ->
    @emit 'progress', 'Creating new form...'
    creativeForm = @generateForm urls
    @envRequest "/forms", {
      method: 'POST'
      json: creativeForm
    }
    .then @checkForFormBuilderError "Error creating new form"
    .then (incomingMessage) =>
      creativeFormId = incomingMessage.body.formid
      @emit 'progress', 'Saved new creative form and draft.'
      @emit 'progress', '***Form ID: ' + creativeFormId + '***'
      @config.setCreativeFormId creativeFormId #todo: make this work, and env specific

  saveNewDraft: (creativeFormId, urls) ->
    @getFormVersion(creativeFormId)
    .then (formVersion) =>
      @getUpdatedDate(creativeFormId, formVersion)
    .then (updatedDate) =>
      creativeForm = @generateForm urls, updatedDate
      @envRequest "/forms/#{creativeFormId}/version", {
        method: 'POST'
        json: creativeForm
      }
    .then @checkForFormBuilderError "Error creating new draft version"
    .then =>
      @emit 'progress', 'Created new draft version of creative form.'
      @emit 'progress', '***Form ID: ' + creativeFormId + '***'

  saveExistingDraft: (creativeFormId, urls) ->
    formVersion = null
    @getFormVersion(creativeFormId)
    .then (vers) =>
      formVersion = vers
      @getUpdatedDate(creativeFormId, formVersion)
    .then (updatedDate) =>
      creativeForm = @generateForm urls, updatedDate
      @envRequest "/forms/#{creativeFormId}/version/#{formVersion}", {
        method: 'PUT'
        json: creativeForm
      }
    .then @checkForFormBuilderError "Error saving form"
    .then =>
      @emit 'progress', 'Updated existing draft of creative form.'
      @emit 'progress', '***Form ID: ' + creativeFormId + '***'

  # Generate new form parameters
  generateForm: (urls, updated = '') ->
    if @config.env.companionFormId isnt 0
      imports = [
        importformid: @config.env.companionFormId
        namespace: 'companion'
      ]
    else
      imports = []

    testData = _.extend
      urlParts:
        q: {}
        path: '/index/'
        page: 'index'
        ifpage:
          index: true
    , @samples.getSample 'default'
    
    name: @config.name
    channel: @config.channel
    brands: @config.brands
    type: 'Creative'
    description: @config.description
    endpoint: @config.env.endpoint
    imports: imports
    layout: @assets.getPartial @config.template
    listsource: null
    model: """imports.companion.inject root

    field 'document', visible: no

    field 'tacticId', visible: no

    field 'locationKey', visible: no

    field 'urlParts', visible: no

    field 'assets', visible: no, value: #{@toCoffeeString @assets.getAssets(), urls}
    """
    partials: _.omit @assets.getPartials(), @config.template
    preview: null
    testdata: JSON.stringify testData, null, '  '
    updated: updated
#    client: 'creative_tool'

# Turn object to coffee - does not properly support arrays
  toCoffeeString: (obj, urls, tabs = '  ') ->
    result = ''
    if obj && typeof obj is 'object'
      if Object.keys(obj).length > 0
        for k, v of obj
          result += "\n" + tabs + JSON.stringify(k) + ": " + @toCoffeeString(v, urls, tabs + '  ')
      else
        result += "{}"
    else
      result = JSON.stringify urls[obj]
    result
    
  # Push the form to form builder.  The method of doing so depends on its current state on the server.
  push: (urls) ->
    @emit 'progress', 'Done uploading static assets.'
    @emit 'progress', 'Saving creative form...'

    creativeFormId = @config.env.creativeFormId
    companionFormId = @config.env.companionFormId

    if companionFormId is 0
      @emit 'progress', "***"
      @emit 'progress', "Warning: Companion form not found."
      @emit 'progress', "Please create a companion form to associate with this creative form."
      @emit 'progress', "***"

    if creativeFormId is 0
      @saveNewForm(urls)
    else
      @getStatus(creativeFormId)
      .then (formStatus) =>
        if formStatus == 'Published'
          @saveNewDraft(creativeFormId, urls)
        else
          @saveExistingDraft(creativeFormId, urls)

            
# upload assets to the fb dam
class Assets
  constructor: (@emit, @assets) ->
    @dam = require 'balihoo-dam-client'
    @dam.uploadFileAsync = Promise.promisify @dam.uploadFile
  config: (config) ->
    @dam.config formbuilder:config.env
  uploadAssets: ->
    urls = {}
    uploadFile = (asset, path) =>
      @dam.uploadFileAsync path
      .then (result) =>
        @emit 'progress', (if result.fileExists then "Found " else "Uploaded ") + asset
        urls[asset] = result.url
        return {
          asset: asset
          path: path
          result: result
        }

    uploads = []
    uploadHelper = (obj) =>
      if obj && typeof obj is 'object'
        uploadHelper v for k, v of obj
      else
        uploads.push uploadFile obj, @assets.getStaticFile(obj).path

    uploadHelper @assets.getAssets()

    @emit 'progress', "Uploading #{uploads.length} static assets..."
    new Promise (resolve, reject) =>
      Promise.all(uploads)
      .then ->
        resolve urls
      .error (reason) ->
        reject "Upload of static assets failed because: #{reason}"
  

class FormBuilder extends EventEmitter
  constructor: (options = {}) ->
    msg.debug "Instantiating FormBuilder"
    @assets = options.assets || throw "FormBuilder requires assets"
    @config = options.config || throw "FormBuilder requires config"
    @samples = options.samples|| throw "FormBuilder requires samples"
    @assetClient = new Assets @emit.bind(@), @assets
    @formsClient = new Forms @emit.bind(@), @assets, @samples

  push: (env) ->
    @emit 'progress', "Starting the push process"
    
    configWithContext = @config.getContext env
    @assetClient.config configWithContext
    @formsClient.config configWithContext

    @assetClient.uploadAssets()
    .then (urls) =>
      @formsClient.push urls
    .catch (error) =>
      @emit 'progress', error.toString()
    .finally =>
      @emit 'complete'

module.exports = (options) -> new FormBuilder options

