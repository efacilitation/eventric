class BoundedContextService
  _boundedContexts: {}

  load: (name, location) ->
    boundedContext = require location
    boundedContext.initialize()

    @_boundedContexts[name] = boundedContext


  get: (name) ->
    @_boundedContexts[name]


module.exports = new BoundedContextService