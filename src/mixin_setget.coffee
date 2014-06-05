eventric = require 'eventric'

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
    @_trackPropsChanged and key != 'id'


module.exports = MixinSetGet