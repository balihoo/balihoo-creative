
fs    = require 'fs'
path  = require 'path'
colors = require 'colors'

console.log "Balihoo Web Designer Toolkit".blue

# argv = require('minimist') process.argv.slice(2)

# Project level configuration file
configPath = '.balihoo-creative.json'

scanAssetsDir = ->
  walk = (cdir) ->
    dir = {}
    for fileName in fs.readdirSync cdir
      assetPath = "#{cdir}/#{fileName}"
      stat = fs.statSync assetPath
      if stat.isDirectory()
        dir[fileName] = walk assetPath
      else
        dir[(fileName.replace /\.[^/.]+$/, '')] = assetPath
    dir
  walk process.cwd() + "/assets";

# If this is a brand new project then go ahead and set it up
if not fs.existsSync configPath
  console.log "No project config file #{configPath.gray}"

  # By default, use the current working directory as the project name
  projectName = path.basename process.cwd()
  console.log "Setting up new project: #{projectName.green}".yellow

  # Recursive copy function
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

  config =
    name: projectName
    description: ''

else
  console.log "Updating project config file #{configPath.gray}"
  config = JSON.parse fs.readFileSync configPath, encoding:'utf8'

config.assets = scanAssetsDir()
fs.writeFileSync configPath, JSON.stringify(config, null, "  ")

