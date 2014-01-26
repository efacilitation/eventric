_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class RemoteService

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_adapter) ->

  rpc: (payload) ->
    @_adapter.rpc payload


module.exports = RemoteService