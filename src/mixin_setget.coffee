eventric = require 'eventric'

AggregateEntityCollection = eventric 'AggregateEntityCollection'

class MixinSetGet

  _set: (key, value) ->
    @_props ?= {}
    @_propsChanged ?= {}

    if @_shouldTrackChangePropertiesFor key, value
     @_propsChanged[key] = value

    @_props[key] = value


  _get: (key) ->
    @_props[key]


  _shouldTrackChangePropertiesFor: (key, value) ->
    @_trackPropsChanged and value not instanceof AggregateEntityCollection and key != 'id'


module.exports = MixinSetGet