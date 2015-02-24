###*
* @name Repository
* @module Repository
* @description
*
* The Repository is responsible for creating, saving and finding Aggregates
###
class Repository

  constructor: (params, @_eventric) ->
    @_aggregateName  = params.aggregateName
    @_AggregateRoot  = params.AggregateRoot
    @_context        = params.context
    @_eventric       = params.eventric

    @_command = {}
    @_aggregateInstances = {}
    @_store = @_context.getDomainEventsStore()


  ###*
  * @name findById
  * @module Repository
  * @description Find an aggregate by its id
  *
  * @param {String} aggregateId The AggregateId of the Aggregate to be found
  ###
  findById: (aggregateId, callback = ->) =>  new Promise (resolve, reject) =>
    @_findDomainEventsForAggregate aggregateId, (err, domainEvents) =>
      if err
        callback err, null
        reject err
        return

      if not domainEvents.length
        err = "No domainEvents for #{@_aggregateName} Aggregate with #{aggregateId} available"
        @_eventric.log.error err
        callback err, null
        reject err
        return

      aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateRoot
      aggregate.applyDomainEvents domainEvents
      aggregate.id = aggregateId
      aggregate.root.$id = aggregateId
      aggregate.root.$save = =>
        @save aggregate.id

      commandId = @_command.id ? 'nocommand'
      @_aggregateInstances[commandId] ?= {}
      @_aggregateInstances[commandId][aggregateId] = aggregate

      callback null, aggregate.root
      resolve aggregate.root


  _findDomainEventsForAggregate: (aggregateId, callback) ->
    @_store.findDomainEventsByAggregateId aggregateId, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0
      callback null, domainEvents


  ###*
  * @name create
  * @module Repository
  * @description Create an Aggregate
  ###
  create: (params) =>  new Promise (resolve, reject) =>
    aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateRoot
    aggregate.id = @_eventric.generateUid()

    if typeof aggregate.root.create isnt 'function'
      err = "No create function on aggregate"
      @_eventric.log.error err
      reject new Error err

    aggregate.root.$id = aggregate.id
    aggregate.root.$save = =>
      @save aggregate.id

    # TODO: needs refactoring
    commandId = @_command.id ? 'nocommand'
    @_aggregateInstances[commandId] ?= {}
    @_aggregateInstances[commandId][aggregate.id] = aggregate

    createPromise = new Promise (resolve, reject) =>
      if aggregate.root.create.length <= 1
        aggregate.root.create params
        resolve()

      else
        aggregate.root.create params,
          resolve: resolve
          reject: reject

    createPromise
    .then ->
      resolve aggregate.root
    .catch (err) ->
      reject err


  ###*
  * @name save
  * @module Repository
  * @description Save the Aggregate
  *
  * @param {String} aggregateId The AggregateId of the Aggregate to be saved
  ###
  save: (aggregateId, callback=->) =>  new Promise (resolve, reject) =>
    commandId = @_command.id ? 'nocommand'
    aggregate = @_aggregateInstances[commandId][aggregateId]
    if not aggregate
      err = "Tried to save unknown aggregate #{@_aggregateName}"
      @_eventric.log.error err
      err = new Error err
      callback? err, null
      reject err
      return

    domainEvents = aggregate.getDomainEvents()
    if domainEvents.length < 1
      err = "Tried to save 0 DomainEvents from Aggregate #{@_aggregateName}"
      @_eventric.log.debug err, @_command
      err = new Error err
      callback? err, null
      reject err
      return

    @_eventric.log.debug "Going to Save and Publish #{domainEvents.length} DomainEvents from Aggregate #{@_aggregateName}"

    # TODO: this should be an transaction to guarantee consistency
    @_eventric.eachSeries domainEvents, (domainEvent, next) =>
      domainEvent.command = @_command
      @_store.saveDomainEvent domainEvent
      .then =>
        @_eventric.log.debug "Saved DomainEvent", domainEvent
        next null
    , (err) =>
      if err
        callback err, null
        reject err
      else
        @_eventric.eachSeries domainEvents, (domainEvent, next) =>
          @_eventric.log.debug "Publishing DomainEvent", domainEvent
          @_context.getEventBus().publishDomainEvent domainEvent
          .then ->
            next()
        , (err) =>
          if err
            callback err, null
            reject err
          else
            resolve aggregate.id
            callback null, aggregate.id



  ###*
  * @name setCommand
  * @module Repository
  * @description Set the command which is currently processed
  *
  * @param {Object} command The command Object
  ###
  setCommand: (command) ->
    @_command = command


module.exports = Repository
