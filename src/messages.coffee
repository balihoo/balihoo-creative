
require 'colors'

_levels =
  DEBUG: 0
  INFO:  1
  WARN:  2
  ERROR: 3

class Messages

  @level = _levels['DEBUG']
  @source = 'SYSTEM'

  @setLevel: (level = 'INFO') ->
    level = level.toUpperCase()
    @level = if level of _levels
      _levels[level]
    else
      console.error "Unrecognized logging level #{level}, using 'DEBUG' instead"
      _levels['DEBUG']

  @print: (msg, level = _levels['INFO']) ->
    if level >= @level
      msg = "#{@source}\t#{msg}"
      switch level
        when _levels['DEBUG'] then console.log msg.cyan
        when _levels['INFO']  then console.log msg
        when _levels['WARN']  then console.log msg.magenta
        when _levels['ERROR'] then console.error msg.red

  debug: (msg) -> Messages.print msg, _levels['DEBUG']
  info : (msg) -> Messages.print msg, _levels['INFO']
  warn : (msg) -> Messages.print msg, _levels['WARN']
  error: (msg) -> Messages.print msg, _levels['ERROR']

module.exports = Messages

