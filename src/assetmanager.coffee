
fs        = require 'fs'
path      = require 'path'
colors    = require 'colors'

# Recursively copy files from srcDir to destDir
exports.rcopy = rcopy = (srcDir, destDir, indent) ->
  for fileName in fs.readdirSync srcDir
    srcPath = "#{srcDir}/#{fileName}"
    destPath = "#{destDir}/#{fileName}"

    stat = fs.statSync srcPath
    if stat.isDirectory()
      console.log "#{indent}#{fileName}/".white
      fs.mkdirSync destPath unless fs.existsSync destPath
      rcopy srcPath, destPath, indent + '  ' 
    else if not fileName.match /\.swp$/
      console.log "#{indent}  #{fileName}".white
      fs.writeFileSync(destPath, fs.readFileSync(srcPath))

