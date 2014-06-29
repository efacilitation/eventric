eventric = require 'eventric'

_  = eventric.require 'HelperUnderscore'

class RemoteBoundedContext

  constructor: (@_remoteService) ->
    @_boundedContextObjs = {}


  # --- CLIENT ---
  command: (boundedContextName, command, callback) ->
    @rpc
      boundedContextName: boundedContextName
      method: 'command'
      params: command
      callback


  query: (boundedContextName, query, callback) ->
    @rpc
      boundedContextName: boundedContextName
      method: 'query'
      params: query
      callback


  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteBoundedContext', payload, callback


  # -- SERVER ---
  handle: (payload, callback) ->
    boundedContext = @getBoundedContextObj payload.boundedContextName
    if not boundedContext
      err = new Error "Tried to handle RPC class with not registered boundedContext #{payload.boundedContextName}"
      return callback err, null

    if payload.method   not of boundedContext
      err = new Error "RPC method #{payload.method} not found on Class #{payload.boundedContextName}"
      return callback err, null

    boundedContext[payload.method] payload.params, callback


  registerBoundedContextObj: (boundedContextName, boundedContextObj) ->
    @_boundedContextObjs[boundedContextName] = boundedContextObj


  getBoundedContextObj: (boundedContextName) ->
    @_boundedContextObjs[boundedContextName]


module.exports = RemoteBoundedContext
