eventric = require 'eventric'

_  = eventric.require 'HelperUnderscore'

class RemoteMicroContext

  constructor: (@_remoteService) ->
    @_microContextObjs = {}


  # --- CLIENT ---
  command: (microContextName, command, callback) ->
    @rpc
      microContextName: microContextName
      method: 'command'
      params: command
      callback


  query: (microContextName, query, callback) ->
    @rpc
      microContextName: microContextName
      method: 'query'
      params: query
      callback


  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteMicroContext', payload, callback


  # -- SERVER ---
  handle: (payload, callback) ->
    microContext = @getMicroContextObj payload.microContextName
    if not microContext
      err = new Error "Tried to handle RPC class with not registered microContext #{payload.microContextName}"
      return callback err, null

    if payload.method   not of microContext
      err = new Error "RPC method #{payload.method} not found on Class #{payload.microContextName}"
      return callback err, null

    microContext[payload.method] payload.params, callback


  registerMicroContextObj: (microContextName, microContextObj) ->
    @_microContextObjs[microContextName] = microContextObj


  getMicroContextObj: (microContextName) ->
    @_microContextObjs[microContextName]


module.exports = RemoteMicroContext
