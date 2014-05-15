eventric = require 'eventric'

_                        = eventric 'HelperUnderscore'
MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteBoundedContext

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->


  # TODO: split into client class
  command: (boundedContextName, commandName, commandPayload, callback) ->
    @rpc
      class: 'BoundedContext'
      method: 'command'
      params:
        boundedContextName: boundedContextName
        methodName: commandName
        methodParams: commandPayload
      callback


  # TODO: split into client class
  query: (boundedContextName, queryName, queryPayload, callback) ->
    @rpc
      class: 'BoundedContext'
      method: 'query'
      params:
        boundedContextName: boundedContextName
        methodName: queryName
        methodParams: queryPayload
      callback

  # TODO: split into client class
  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteBoundedContext', payload, callback


  # TODO: split into server class
  handle: (payload, callback) ->
    boundedContext = @getClass payload.params.boundedContextName
    if not boundedContext
      err = new Error "Tried to handle RPC class with not registered boundedContext #{payload.params[0]}"
      return callback err, null

    if payload.method   not of boundedContext
      err = new Error "RPC method #{payload.method} not found on Class #{payload.params[0]}"
      return callback err, null

    methodParams =
      name: payload.params.methodName
      params: payload.params.methodParams
    boundedContext[payload.method] methodParams, callback


module.exports = RemoteBoundedContext
