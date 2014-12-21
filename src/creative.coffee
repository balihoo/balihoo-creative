
fs       = require 'fs'
path     = require 'path'
colors   = require 'colors'
chokidar = require 'chokidar'

console.log "Balihoo Web Designer Toolkit".blue

# argv = require('minimist') process.argv.slice(2)

# Project level configuration file
configPath = '.balihoo-creative.json'

# Return an object representation the files in the assets/ dir
scanAssetsDir = ->
  walk = (cdir, parent = null) ->
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
        value = if ext is 'mustache' then fs.readFileSync(assetPath, encoding:'utf8') else assetPath
        dir[key] = value unless key.length is 0
    dir
  walk process.cwd() + "/assets";

# If this is a brand new project then go ahead and set it up
if not fs.existsSync configPath
  # By default, use the current working directory as the project name
  projectName = path.basename process.cwd()
  console.log "Setting up new project: #{projectName.green}".yellow
  config =
    name: projectName
    description: ''
    index: 'index'
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
        fs.createReadStream(srcPath).pipe(fs.createWriteStream(destPath));

  # Recursively copy all the template files into the current project 
  rcopy __dirname + '/../template', process.cwd(), '  '


# Start with an up to date view of the assets directory
config.assets = scanAssetsDir()
fs.writeFileSync configPath, JSON.stringify(config, null, "  ")
console.log config.assets

# Now, watch the asset directory and see if any files change, add or delete
# We don't really care what happens to the directory, we'll just recompute all
chokidar.watch('./assets', ignoreInitial:yes).on 'all', (event, path)->
  config.assets = scanAssetsDir()
  console.log config.assets
 

