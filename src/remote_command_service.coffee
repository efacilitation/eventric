_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'

class RemoteCommandService

  # TODO "register*Class*" is the wrong terminology here, since its actually an instance
  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_remoteService) ->

  createAggregate: (aggregateName, callback) ->
    @rpc
      class: 'CommandService'
      method: 'createAggregate'
      params: [
        aggregateName
      ]
      -> callback null


  commandAggregate: (aggregateName, aggregateId, commandName, commandParams, callback) ->
    @rpc
      class: 'CommandService'
      method: 'commandAggregate'
      params: [
        aggregateName,
        aggregateId,
        commandName,
        commandParams
      ]
      -> callback null


  rpc: (payload, callback) ->
    @_remoteService.rpc 'RemoteCommandService', payload, ->
      callback null


  handle: (payload, callback) ->

    instance = @getClass payload.class
    if not instance
      err = new Error "Tried to handle RPC class with not registered Class #{payload.class}"
      return callback err, null

    if payload.method not of instance
      err = new Error "RPC method #{payload.method} not found on Class #{payload.class}"
      return callback err, null

    instance[payload.method] payload.params..., (err, result) ->
      return callback err, null if err
      callback null, result


module.exports = RemoteCommandService