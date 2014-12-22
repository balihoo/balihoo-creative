
fs        = require 'fs'
opn       = require 'opn'
sse       = (require 'sse-stream')('/updates')
path      = require 'path'
colors    = require 'colors'
server    = require './server'
parser    = require './urlparser'
assets    = (require './assetmanager')('assets')

console.log "Balihoo Web Designer Toolkit".blue

# Set up some global variables
config = {}
partials = {}
validFiles = {}

# Project level configuration file
configPath = './assets/.balihoo-creative.json'

# Load in the static HTML that is the console
consoleContent = fs.readFileSync __dirname + '/../console.html'

# If there is no assets directory, then we should build one
if not fs.existsSync './assets/'
  console.log 'Creating an assets/ directory'.yellow
  needAssets = true
  fs.mkdirSync './assets/'

# If this is a brand new project then go ahead and set it up
if not fs.existsSync configPath
  # By default, use the current working directory as the project name
  projectName = path.basename process.cwd()
  console.log "Setting up new project: #{projectName.green}".yellow
  config =
    name: projectName
    description: ''
else
  console.log "Found existing project config file #{configPath.gray}"
  config = JSON.parse fs.readFileSync configPath, encoding:'utf8'

# If the asset directory doesn't already exist, then create one
if needAssets
  # Recursively copy all the template files into the current project 
  console.log "Creating a project skeleton in #{__dirname}/../template".yellow
  assets.rcopy __dirname + '/../template', process.cwd(), '  '

parseConfig = ->
  console.log "Reparsing config"
  config = JSON.parse fs.readFileSync configPath, encoding:'utf8'

rescan = ->
  console.log "Scanning assets"
  [config.assets, partials, validFiles] = assets.scan()
  server.update config, partials, validFiles
  if not config.port? then config.port = 8088
  if not config.template? then config.template = 'main'
  if not config.pages? then config.pages = ['index']

saveConfig = ->
  console.log "Saving config file".green
  fs.writeFileSync configPath, JSON.stringify(config, null, "  ")

# Start with an up to date view of the assets directory
rescan()
saveConfig()

httpserver = server.create config, partials, validFiles

clients = []
sse.install httpserver
sse.on 'connection', (client) ->
  clients.push client
  client.write '/'

  client.on 'end', ->
    clients.splice clients.indexOf(client), 1

refreshClients = ->
  client.write 'refresh' for client in clients

console.log "Opening console in web browser".inverse
opn "http://localhost:#{config.port}/$console"

assets.watch()
  .on 'config', -> f() for f in [parseConfig, rescan, refreshClients]
  .on 'update', -> f() for f in [rescan, saveConfig, refreshClients]

