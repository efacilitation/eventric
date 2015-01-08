###*
* @name GlobalProjection
* @module GlobalProjection
* @description
*
* GlobalProjection can handle multiple DomainEvents on multiple contexts
###
class GlobalProjectionService

  constructor: (@_eventric) ->
    @_globalContext = false
    @_projections = {}
    
  add: (name, ProjectionClass, params) ->
    @_getGlobalContext().then (globalContext) =>
      globalContext.addProjection name, ProjectionClass
      globalContext.initializeProjectionInstance(name).then (projectionId) =>
        projection = globalContext.getProjectionInstance projectionId
        
        contextList = @_getContextsFromProjection projection
        for contextName in contextList
          subContext = @_eventric.getContext contextName
          if not subContext then throw new Error("Context #{contextName} doesn't exists")
          
          contextEvents = @_getEventsForContext projection, contextName
          subProjection = {}
          
          for eventName in contextEvents
            subProjection['handle'+eventName] = projection["from#{contextName}_handle#{eventName}"].bind(projection)
              
          subProjectionName = "_globalProjection_#{name}"
          subContext.addProjection subProjectionName, subProjection
          
          if subContext._initialized then subContext.initializeProjectionInstance subProjectionName, params
          
    
  _getGlobalContext: () ->
    new Promise (resolve, reject) =>
      if @_globalContext
          resolve @_globalContext
      
      @_globalContext = @_eventric.context 'GlobalProjectionsContext'
      @_globalContext.initialize().then =>
        resolve @_globalContext
      .catch (err) =>
        reject err
  
  _getContextsFromProjection: (projection) ->
    contextList = []
    for key, value of projection
      if (key.indexOf 'from') is 0 and (typeof value is 'function')
        contextName = key.replace /^from/, ''
        contextName = contextName.replace /_.*$/, ''
        contextList.push contextName
    
    return contextList
  
  _getEventsForContext: (projection, contextName) ->
    eventList = []
    for key, value of projection
      if (key.indexOf "from#{contextName}_handle") is 0 and (typeof value is 'function')
        contextName = key.replace "from#{contextName}_handle", ''
        eventList.push contextName
    
    return eventList
    

module.exports = GlobalProjectionService