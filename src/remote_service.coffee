_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class RemoteService

  # TODO "class" is the wrong terminology here
  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_adapter) ->

  rpc: (payload) ->
    @_adapter.rpc payload

  handle: (payload, callback) ->
    instance = @getClass payload.class
    instance[payload.method] payload.params..., (err, status) ->
      return callback err, null if err
      callback null, status


module.exports = RemoteService