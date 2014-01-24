eventric = require 'eventric'

AggregateEntityCollection = eventric 'AggregateEntityCollection'

class MixinSetGet

  _set: (key, value) ->
    @_props ?= {}
    @_propsChanged ?= {}

    if @_shouldTrackChangePropertiesFor value
     @_propsChanged[key] = value

    @_props[key] = value


  _get: (key) ->
    @_props[key]


  _shouldTrackChangePropertiesFor: (value) ->
    @_trackPropsChanged and value not instanceof AggregateEntityCollection


module.exports = MixinSetGet