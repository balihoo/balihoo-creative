
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
    #todo: DRY all the request stuff by setting @envRequest to request.defaults with baseUrl, auth
  getForm: (formid, version = 1, cb) ->
    request "#{@config.env.url}/forms/#{formid}/version/#{version}", {
      method: 'GET'
      auth:
        username: @config.env.username
        password: @config.env.password
    }, (error, incomingMessage, response) ->
      if error
        return cb error
      if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
        try
          body = JSON.parse incomingMessage.body
          err = new Error body.message
          err.code = body.code
          return cb err
        catch ex
          console.log incomingMessage.body
          return cb new Error "Error getting form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
      cb error, incomingMessage, response
  
  saveForm: (formid, version, form, cb) ->
    request "#{@config.env.url}/forms/#{formid}/version/#{version}", {
      method: 'PUT'
      json: form
      auth:
        username: @config.env.username
        password: @config.env.password
    }, (error, incomingMessage, response) ->
      if error
        return cb error
      if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
        try
          body = JSON.parse incomingMessage.body
          err = new Error body.message
          err.code = body.code
          return cb err
        catch ex
          console.log incomingMessage.body
          return cb new Error "Error saving form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
      cb error, incomingMessage, response
  
  newForm: (form, cb) ->
    request "#{@config.env.url}/forms", {
      method: 'POST'
      json: form
      auth:
        username: @config.env.username
        password: @config.env.password
    }, (error, incomingMessage, response) ->
      if error
        return cb error
      if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
        try
          body = JSON.parse incomingMessage.body
          err = new Error body.message
          err.code = body.code
          return cb err
        catch ex
          console.log incomingMessage.body
          return cb new Error "Error creating new form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
      cb error, incomingMessage, response
  
  publishForm: (formid, form, cb) ->
    request "#{@config.env.url}/forms/#{formid}/version/1/publish", {
      method: 'POST'
      json: form
      auth:
        username: @config.env.username
        password: @config.env.password
    }, (error, incomingMessage, response) ->
      if error
        return cb error
      if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
        try
          body = JSON.parse incomingMessage.body
          err = new Error body.message
          err.code = body.code
          return cb err
        catch ex
          console.log incomingMessage.body
          return cb new Error "Error saving form (#{incomingMessage.statusCode}): #{incomingMessage.body}"
      cb error, incomingMessage, response
  
  newDraft: (formid, form, cb) ->
    request "#{@config.env.url}/forms/#{formid}/version", {
      method: 'POST'
      json: form
      auth:
        username: @config.env.username
        password: @config.env.password
    }, (error, incomingMessage, response) ->
      if error
        return cb error
      if incomingMessage.statusCode // 100 isnt 2 #not a 2xx response
        try
          body = JSON.parse incomingMessage.body
          err = new Error body.message
          err.code = body.code
          return cb err
        catch ex
          console.log incomingMessage.body
          return cb new Error "Error creating new form (#{incomingMessage.statusCode}): #{incomingMessage.body.message}"
      cb error, incomingMessage, response
      
  # todo: DRY this promise creation stuff by moving/combining with function above
  getFormVersion: (creativeFormId) ->
    new Promise (resolve, reject) =>
      @getForm creativeFormId, null, (err, incomingMessage, response) =>
        if (err)
          reject err
        else
          formData = JSON.parse(incomingMessage.body)
          formVersion = formData.versions[0].version
          resolve formVersion

  getUpdatedDate: (creativeFormId, formVersion) ->
    new Promise (resolve, reject) =>
      @getForm creativeFormId, formVersion, (err, incomingMessage, response) =>
        if (err)
          reject err
        else
          formData = JSON.parse(incomingMessage.body)
          updatedDate = formData.versions[0].updated
          resolve updatedDate

  getStatus: (creativeFormId) ->
    new Promise (resolve, reject) =>
      @getForm creativeFormId, null, (err, incomingMessage, response) =>
        if (err)
          reject err
        else
          formData = JSON.parse(incomingMessage.body)
          formStatus = formData.versions[0].status
          resolve formStatus

  saveNewForm: (creativeFormId, urls) ->
    @emit 'progress', 'Creating new form...'
    creativeForm = @generateForm urls
    @newForm creativeForm, (err, incomingMessage, response) =>
      creativeFormId = incomingMessage.body.formid
      if err
        @emit 'progress', 'Failed to save new creative form:'
        @emit 'progress', "savenewform: " + err.toString()
        console.log "ERROR", err
      else
        @emit 'progress', 'Saved new creative form.'
        @emit 'progress', '***Form ID: ' + creativeFormId + '***'
        @config.setCreativeFormId creativeFormId #todo: make this work, and env specific
        @emit 'complete'

  saveNewDraft: (creativeFormId, urls) ->
    @getFormVersion(creativeFormId).then (formVersion) =>
      @getUpdatedDate(creativeFormId, formVersion).then (updatedDate) =>
        creativeForm = @generateForm urls, updatedDate
        @newDraft creativeFormId, creativeForm, (err, incomingMessage, response) =>
          if err
            @emit 'progress', 'Failed to save creative form:'
            @emit 'progress', "savenewdraft:" + err.toString()
            console.log "ERROR", err
          else
            @emit 'progress', 'Saved creative form.'
            @emit 'progress', '***Form ID: ' + creativeFormId + '***'
            @emit 'complete'

  saveExistingDraft: (creativeFormId, urls) ->
    @getFormVersion(creativeFormId).then (formVersion) =>
      @getUpdatedDate(creativeFormId, formVersion).then (updatedDate) =>
        creativeForm = @generateForm urls, updatedDate
        @saveForm creativeFormId, formVersion, creativeForm, (err, incomingMessage, response) =>
          if err
            @emit 'progress', 'Failed to save creative form:'
            @emit 'progress', "saveexistingdraft: " + err.toString()
            console.log "ERROR", err
          else
            @emit 'progress', 'Saved creative form.'
            @emit 'progress', '***Form ID: ' + creativeFormId + '***'
            @emit 'complete'

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
      @saveNewForm(creativeFormId, urls)
    else
      @getStatus(creativeFormId).then (formStatus) =>
        if formStatus == 'Published'
          @saveNewDraft(creativeFormId, urls)
        else
          @saveExistingDraft(creativeFormId, urls)

            
# upload assets to the fb dam
class Assets
  constructor: (@emit, @assets) ->
    @dam = require 'balihoo-dam-client'
  config: (config) ->
    @dam.config formbuilder:config.env
  uploadAssets: ->
    urls = {}
    #todo: why in the world are we primisfying our own function? Do Promise.try
    uploadFile = Promise.promisify (asset, path, cb) =>
      @dam.uploadFile path, (err, result) =>
        if err
          return cb err
        @emit 'progress', (if result.fileExists then "Found " else "Uploaded ") + asset
        urls[asset] = result.url
        cb err,
          asset: asset
          path: path
          result: result

    uploads = []
    uploadHelper = (obj) =>
      if obj && typeof obj is 'object'
        uploadHelper v for k, v of obj
      else
        uploads.push uploadFile obj, @assets.getStaticFile(obj).path

    uploadHelper @assets.getAssets()

    @emit 'progress', "Uploading #{uploads.length} static assets..."
    new Promise (resolve, reject) =>
      Promise.all(uploads).then (assets) ->
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
    .error (reason) =>
      console.log 'stuff error'
      @emit 'progress', 'push: ' + reason.toString()
      @emit 'complete'

module.exports = (options) -> new FormBuilder options

