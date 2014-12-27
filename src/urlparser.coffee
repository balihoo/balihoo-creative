qs        = require 'querystring'
path      = require 'path'
parseURL  = (require 'url').parse

fixKey = (str) ->
  str.replace(/\s+/g, '_').toLowerCase()

exports.parse = (url, defaultIndex = 'index') ->
  # Break the url into various pieces
  parts = parseURL url

  # Start with the parsed querystring
  query = {}
  query[fixKey k] = v for k,v of qs.parse parts.query
  result = q: query

  # Add the full path
  result.path = parts.pathname

  # Get all of the parts of the path with empty parts removed
  path = (part for part in parts.pathname.split /\// when part.length > 0)

  # The page is the directory of the path or defaultIndex
  result.page = if path.length > 0 then path.shift().toLowerCase() else defaultIndex
  result.ifpage = {}
  result.ifpage[result.page] = true

  # The remaining directory parts are key/value pairs
  # If an odd number of path parts, the last key has value of undefined
  for p in [0...path.length] by 2
    key = fixKey unescape path[p]
    ifkey = "if#{key}"
    result[ifkey] = {}
    if path.length > p + 1
      val = unescape path[p+1]
      result[ifkey][val] = true
      result[key] = val
    else
      result[ifkey] = undefined
      result[key] = undefined
  result

