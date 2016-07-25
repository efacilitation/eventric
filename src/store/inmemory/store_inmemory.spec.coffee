describe 'InMemory Store Adapter', ->
  InMemoryStore = require './store_inmemory'
  inmemoryStore = null

  sampleDomainEvent =
    name: 'SomethingHappened'
    aggregate:
      id: 42
      name: 'Example'

  sampleContext = name: 'exampleContext'
  storageKey = "#{sampleContext.name}.DomainEvents"
  projectionName = "#{sampleContext.name}.Projections"

  before ->
    inmemoryStore = new InMemoryStore()


  afterEach ->
    sandbox.restore()


  describe '#initialize', ->

    it 'should should resolve without an error', ->
      inmemoryStore.initialize sampleContext


  describe '#saveDomainEvent', ->

    beforeEach ->
      inmemoryStore.initialize sampleContext.name


    it 'should save the given domain event', (done) ->
      inmemoryStore.saveDomainEvent sampleDomainEvent
      .then ->
        inmemoryStore.findDomainEventsByName 'SomethingHappened', (error, domainEvents) ->
          expect(domainEvents.length).to.equal 1
          expect(domainEvents[0]).to.equal sampleDomainEvent
          done()


    it 'should resolve with the saved domain event which then has an id', (done) ->
      inmemoryStore.saveDomainEvent sampleDomainEvent
      .then (savedDomainEvent) ->
        expect(savedDomainEvent.id).to.be.an.integer
        done()


  describe '#findDomainEventsByName', ->

    beforeEach ->
      inmemoryStore.initialize sampleContext.name
      .then ->
        inmemoryStore.saveDomainEvent sampleDomainEvent


    it 'should find the previously saved domain event by name', (done) ->
      inmemoryStore.findDomainEventsByName 'SomethingHappened', (error, domainEvents) ->
        expect(domainEvents.length).to.equal 1
        expect(domainEvents[0]).to.equal sampleDomainEvent
        done()


    it 'should find the previously saved domainevent by array', (done) ->
      inmemoryStore.findDomainEventsByName ['SomethingHappened'], (error, domainEvents) ->
        expect(domainEvents.length).to.equal 1
        expect(domainEvents).to.deep.equal [
          sampleDomainEvent
        ]
        done()


  describe '#findDomainEventsByAggregateId', ->

    beforeEach ->
      inmemoryStore.initialize sampleContext.name
      .then ->
        inmemoryStore.saveDomainEvent sampleDomainEvent


    it 'should find the previously saved domain event by id', (done) ->
      inmemoryStore.findDomainEventsByAggregateId 42, (error, domainEvents) ->
        expect(domainEvents).to.deep.equal [
          sampleDomainEvent
        ]
        done()


    it 'should find the previously saved domain event by array', (done) ->
      inmemoryStore.findDomainEventsByAggregateId [42], (error, domainEvents) ->
        expect(domainEvents).to.deep.equal [
          sampleDomainEvent
        ]
        done()


  describe '#findDomainEventsByNameAndAggregateId', ->

    beforeEach ->
      inmemoryStore.initialize sampleContext.name
      .then ->
        inmemoryStore.saveDomainEvent sampleDomainEvent


    it 'should find the previously saved domain event', (done) ->
      inmemoryStore.findDomainEventsByNameAndAggregateId 'SomethingHappened', 42, (error, domainEvents) ->
        expect(domainEvents).to.deep.equal [
          sampleDomainEvent
        ]
        done()


    it 'should find the previously saved domain event by array', (done) ->
      inmemoryStore.findDomainEventsByNameAndAggregateId ['SomethingHappened'], [42], (error, domainEvents) ->
        expect(domainEvents).to.deep.equal [
          sampleDomainEvent
        ]
        done()
