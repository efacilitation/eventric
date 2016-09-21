module.exports =

  _logLevel: 1
  setLogLevel: (logLevel) ->
    @_logLevel = switch logLevel
      when 'debug' then 0
      when 'warn' then 1
      when 'info' then 2
      when 'error' then 3

  debug: ->
    return if @_logLevel > 0
    console['log'] arguments...

  warn: ->
    return if @_logLevel > 1
    console['log'] arguments...

  info: ->
    return if @_logLevel > 2
    console['log'] arguments...

  error: ->
    return if @_logLevel > 3
    console['log'] arguments...
