
fs        = require 'fs'
colors    = require 'colors'

exports.ignoreFile = ignoreFile = (path) ->
  /^\./.test(path) || /\/\./.test(path) || /~$/.test(path)

# Return an object representation the files in the assets/ dir
exports.scan = (baseDir = process.cwd(), assetDir = 'assets') ->
  partials = {}
  validFiles = {}
  base = baseDir + "/" + assetDir

  walk = (cdir) ->
    dir = {}
    for fileName in fs.readdirSync cdir
      assetPath = "#{cdir}/#{fileName}"
      if not ignoreFile assetPath
        stat = fs.statSync assetPath
        if stat.isDirectory()
          # Asset directory key is directory name
          dir[fileName] = walk assetPath
        else
          # Asset's key is file name without extension
          key = fileName.replace /\.[^/.]+$/, ''
          ext = (fileName.substr key.length + 1).toLowerCase()
          rel = assetPath.substr base.length
          if ext is 'mustache'
            partials[key] = fs.readFileSync(assetPath, encoding:'utf8')
          else
            validFiles["./#{assetDir}#{rel}"] = fs.readFileSync assetPath
            dir[key] = "/_#{rel}"
    dir
  assets = walk base
  [assets, partials, validFiles]

