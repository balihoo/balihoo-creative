
Promise   = require 'bluebird'
dam       = require 'balihoo-dam-client'
colors    = require 'colors'
_         = require 'underscore'
{EventEmitter}  = require 'events'

# Set up logging
Messages  = require './messages'
msg = new Messages 'PUBLISHER'

class Publisher extends EventEmitter
  constructor: (options = {}) ->
    msg.debug "Instantiating Publisher"
    @assets = options.assets || throw "Publisher requires assets"
    @config = options.config || throw "Publisher requres config"
    @samples= options.samples|| throw "Publisher requres samples"

    dam.config
      formbuilder:
        url: 'https://fb.dev.balihoo-cloud.com'
        username: 'username'
        password: 'password'

  uploadAssets: ->
    urls = {}
    uploadFile = Promise.promisify (asset, path, cb) =>
      dam.uploadFile path, (err, result) =>
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

  publish: ->
    @emit 'progress', "Starting the publish process"

    @uploadAssets().then (urls) =>
      @emit 'progress', 'Done uploading static assets.'
      form = @generateForm urls
      @emit 'progress', 'Saving creative form'
      dam.saveForm @config.getContext().creativeFormId, form, (err, response) =>
        if err
          @emit 'progress', 'Failed to save creative form' + err
          console.log "ERROR", err
        else
          @emit 'progress', 'Saved creative form'
          @emit 'complete'
    .error (reason) =>
      @emit 'progress', reason
      @emit 'complete'

  generateForm: (urls) ->
    config = @config.getContext()

    testData = _.extend
      request:
        q: {}
        path: '/index/'
        page: 'index'
        ifpage:
          index: true
    , @samples.getSample 'default'

    name: config.name
    channel: config.channel
    brands: ['demo']
    type: 'Creative'
    description: config.description
    endpoint: 205
    imports: [
      importformid: config.companionFormId
      namespace: 'companion'
    ]
    layout: @assets.getPartial @config.getTemplate()
    listsource: null
    model: """imports.companion.inject root
    
    field 'request', visible: no, value: data.request

    field 'assets', visible: no, value: #{@toCoffeeString @assets.getAssets(), urls}
    """
    partials: _.omit @assets.getPartials(), @config.getTemplate()
    preview: null
    testdata: JSON.stringify testData, null, '  '

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

module.exports = (options) -> new Publisher options

