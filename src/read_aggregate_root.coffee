_        = require 'underscore'
Backbone = require 'backbone'

class ReadAggregateRoot
  constructor: (@_props = {}) ->

  toJSON: ->
    _.clone @_props

  @prop = (propName, desc) ->
    Object.defineProperty @::, propName, _.defaults desc || {},
      get: -> @_props[propName]
      set: (val) ->
        @_props = {} unless @_props
        if @[propName] isnt val
          @_props[propName] = val
          @trigger "change:#{propName}"

  @props = (propNames...) ->  @prop(propName) for propName in propNames

  @prop 'id'

_.extend ReadAggregateRoot.prototype, Backbone.Events

module.exports = ReadAggregateRoot