class Logger

  LOG_LEVELS:
    error: 0
    warn: 1
    info: 2
    debug: 3


  constructor: ->
    @setLogLevel 'warn'


  setLogLevel: (logLevel) ->
    if @LOG_LEVELS[logLevel] is undefined
      throw new Error 'Logger: No valid log level'
    @_logLevel = @LOG_LEVELS[logLevel]


  error: ->
    console['error'] arguments...


  warn: ->
    return if @_logLevel < 1
    console['warn'] arguments...


  info: ->
    return if @_logLevel < 2
    console['info'] arguments...


  debug: ->
    return if @_logLevel < 3
    console['log'] arguments...


module.exports = new Logger
