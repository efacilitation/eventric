eventric = require 'eventric'

_  = eventric.require 'HelperUnderscore'

class RemoteContext

  constructor: (@_remoteService) ->
    @_contextObjs = {}


  # --- CLIENT ---
  command: (contextName, command, callback) ->
    @rpc
      contextName: contextName
      method: 'command'
      params: command
      callback


  query: (contextName, query, callback) ->
    @rpc
      contextName: contextName
      method: 'query'
      params: query
      callback


  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteContext', payload, callback


  # -- SERVER ---
  handle: (payload, callback) ->
    context = @getContextObj payload.contextName
    if not context
      err = new Error "Tried to handle RPC class with not registered context #{payload.contextName}"
      return callback err, null

    if payload.method   not of context
      err = new Error "RPC method #{payload.method} not found on Class #{payload.contextName}"
      return callback err, null

    context[payload.method] payload.params, callback


  registerContextObj: (contextName, contextObj) ->
    @_contextObjs[contextName] = contextObj


  getContextObj: (contextName) ->
    @_contextObjs[contextName]


module.exports = RemoteContext
