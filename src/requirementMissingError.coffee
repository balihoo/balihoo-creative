

# Just a typed error so we can identify problems that can be solved by initializing a new project

module.exports = class RequirementMissingError extends Error
  # required for instanceof to work
  constructor: (@message) ->
  