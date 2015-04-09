
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

  publish: ->
    @emit 'progress', "Starting the publish process"

    # Turn object to coffee - does not properly support arrays
    toCoffeeString = (obj, tabs = '  ') =>
      result = ''
      if obj && typeof obj is 'object'
        if Object.keys(obj).length > 0
          for k, v of obj
            result += "\n" + tabs + JSON.stringify(k) + ": " + toCoffeeString(v, tabs + '  ')
        else
          result += "{}"
      else
        @emit 'progress', "#{obj}"
        result = JSON.stringify obj
      result

    config = @config.getContext()

    form =
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
      model: """"imports.companion.inject root
      
      field 'request', visible: no, value: data.request

      field 'assets', visible: no, value:
      """ + toCoffeeString @assets.getAssets()
      partials: _.omit @assets.getPartials(), @config.getTemplate()
      preview: null
      testdata: @samples.getSample 'default'

    @emit 'complete'

    ###
    dam.saveForm config.creativeFormId, form, (err, response) ->
      console.log "ERROR", err
    ###
 
    ###
    dam.uploadFile '/tmp/mytest.txt', (err, response) =>
      console.dir err
      console.dir response
      @emit 'complete'
    ###

module.exports = (options) -> new Publisher options

