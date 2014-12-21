
fs        = require 'fs'
qs        = require 'querystring'
path      = require 'path'
colors    = require 'colors'
chokidar  = require 'chokidar'
mustache  = require 'mustache'
parseURL  = (require 'url').parse

console.log "Balihoo Web Designer Toolkit".blue

# argv = require('minimist') process.argv.slice(2)

# Project level configuration file
configPath = '.balihoo-creative.json'

# Return an object representation the files in the assets/ dir
scanAssetsDir = ->
  partials = {}
  walk = (cdir) ->
    dir = {}
    for fileName in fs.readdirSync cdir
      assetPath = "#{cdir}/#{fileName}"
      stat = fs.statSync assetPath
      if stat.isDirectory()
        # Asset directory key is directory name
        dir[fileName] = walk assetPath
      else
        # Asset's key is file name without extension
        key = fileName.replace /\.[^/.]+$/, ''
        ext = (fileName.substr key.length + 1).toLowerCase()
        if ext is 'mustache'
          partials[key] = fs.readFileSync(assetPath, encoding:'utf8')
        else
          dir[key] = assetPath
    dir
  assets = walk process.cwd() + "/assets"
  [assets, partials]

# If this is a brand new project then go ahead and set it up
if not fs.existsSync configPath
  # By default, use the current working directory as the project name
  projectName = path.basename process.cwd()
  console.log "Setting up new project: #{projectName.green}".yellow
  config =
    name: projectName
    description: ''
    main: 'index'
else
  console.log "Found existing project config file #{configPath.gray}"
  config = JSON.parse fs.readFileSync configPath, encoding:'utf8'

# If the asset directory doesn't already exist, then create one
if not fs.existsSync './assets'
  # Recursively copy files from srcDir to destDir
  rcopy = (srcDir, destDir, indent) ->
    for fileName in fs.readdirSync srcDir
      srcPath = "#{srcDir}/#{fileName}"
      destPath = "#{destDir}/#{fileName}"

      stat = fs.statSync srcPath
      if stat.isDirectory()
        console.log "#{indent}#{fileName}/".white
        fs.mkdirSync destPath unless fs.existsSync destPath
        rcopy srcPath, destPath, indent + '  ' 
      else
        console.log "#{indent}  #{fileName}".white
        fs.writeFileSync(destPath, fs.readFileSync(srcPath))

  # Recursively copy all the template files into the current project 
  rcopy __dirname + '/../template', process.cwd(), '  '


# Start with an up to date view of the assets directory
[config.assets, partials] = scanAssetsDir()
fs.writeFileSync configPath, JSON.stringify(config, null, "  ")

main = if config.main? then config.main else 'index'

parseRequest = (url) ->
  parts = parseURL url

  # Start with the parsed querystring
  result = qs.parse parts.query

  # Get all of the parts of the path with empty parts removed
  path = (part for part in parts.pathname.split /\// when part.length > 0)

  # The page is the directory of the path or 'index'
  page = if path.length > 0 then path.shift() else 'index'
  result.page = {}
  result.page[page] = true

  # The remaining directory parts are key/value pairs
  # If an odd number remain, the last key's has value is undefined
  for p in [0...path.length] by 2
    result[path[p]] = {}
    if path.length > p + 1
      result[path[p]][path[p+1]] = true
    else
      result[path[p]] = undefined
  result

base = "http://localhost:8089/"
context =
  request: parseRequest base
  assets: config.assets
  partials: partials

html = mustache.render context.partials[main], context
console.log html

###

# Now, watch the asset directory and see if any files change, add or delete
# We don't really care what happens to the directory, we'll just recompute all
chokidar.watch('./assets', ignoreInitial:yes).on 'all', (event, path)->
  config.assets = scanAssetsDir()
  console.log config.assets
 
###
