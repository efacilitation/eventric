describe 'InMemory Store Adapter', ->
  inmemoryStore = null

  contextFake = null

  beforeEach ->
    contextFake = name: 'exampleContext'
    InMemoryStore = require './store_inmemory'
    inmemoryStore = new InMemoryStore()


  afterEach ->
    sandbox.restore()


  describe '#initialize', ->

    it 'should should resolve without an error', ->
      initializePromise = inmemoryStore.initialize contextFake
      .then ->
        expect(initializePromise).to.be.ok


  describe '#saveDomainEvent', ->

    beforeEach ->
      inmemoryStore.initialize contextFake


    it 'should save the domain event', (done) ->
      sampleDomainEvent = name: 'SomethingHappened'
      inmemoryStore.saveDomainEvent sampleDomainEvent
      .then ->
        inmemoryStore.findDomainEventsByName 'SomethingHappened', (error, domainEvents) ->
          expect(domainEvents.length).to.equal 1
          expect(domainEvents[0]).to.equal sampleDomainEvent
          done()


    it 'should resolve with the saved domain event which has a domain event id', ->
      inmemoryStore.saveDomainEvent {}
      .then (savedDomainEvent) ->
        expect(savedDomainEvent.id).to.be.an.integer


    it 'should assign an ascending integer to each saved domain as id', ->
      saveDomainEventPromises = []
      for i in [0...1000]
        saveDomainEventPromises.push inmemoryStore.saveDomainEvent {}
      Promise.all saveDomainEventPromises
      .then (domainEvents) ->
        domainEvents.map((domainEvent) -> domainEvent.id).forEach (domainEventId, index) ->
          expect(domainEventId).to.equal index + 1


  describe '#findDomainEventsByName', ->

    beforeEach ->
      inmemoryStore.initialize contextFake


    it 'should call back with domain events with a matching name', (done) ->
      domainEvent = name: 'SomethingHappened'
      inmemoryStore.saveDomainEvent domainEvent
      .then ->
        inmemoryStore.findDomainEventsByName 'SomethingHappened', (error, domainEvents) ->
          expect(domainEvents.length).to.equal 1
          expect(domainEvents[0]).to.equal domainEvent
          done()


    it 'should call back without domain events with another name', (done) ->
      domainEvent = name: 'SomethingElseHappened'
      inmemoryStore.saveDomainEvent domainEvent
      .then ->
        inmemoryStore.findDomainEventsByName 'SomethingHappened', (error, domainEvents) ->
          expect(domainEvents.length).to.equal 0
          done()


    it 'should call back with domain events matching any name given an array of names', (done) ->
      domainEvent1 = name: 'SomethingHappened'
      domainEvent2 = name: 'SomethingElseHappened'
      Promise.all [
        inmemoryStore.saveDomainEvent domainEvent1
        inmemoryStore.saveDomainEvent domainEvent2
      ]
      .then ->
        inmemoryStore.findDomainEventsByName ['SomethingHappened', 'SomethingElseHappened'], (error, domainEvents) ->
          expect(domainEvents.length).to.equal 2
          expect(domainEvents[0]).to.equal domainEvent1
          expect(domainEvents[1]).to.equal domainEvent2
          done()


  describe '#findDomainEventsByAggregateId', ->

    beforeEach ->
      inmemoryStore.initialize contextFake


    it 'should call back with domain events with a matching aggregate id', (done) ->
      domainEvent = aggregate: id: 42
      inmemoryStore.saveDomainEvent domainEvent
      .then ->
        inmemoryStore.findDomainEventsByAggregateId 42, (error, domainEvents) ->
          expect(domainEvents.length).to.equal 1
          expect(domainEvents[0]).to.equal domainEvent
          done()


    it 'should call back without domain events with another aggregate id', (done) ->
      domainEvent = aggregate: id: 43
      inmemoryStore.saveDomainEvent domainEvent
      .then ->
        inmemoryStore.findDomainEventsByAggregateId 42, (error, domainEvents) ->
          expect(domainEvents.length).to.equal 0
          done()


    it 'should call back with domain events matching any aggregrate id given an array of aggregate ids', (done) ->
      domainEvent1 = aggregate: id: 42
      domainEvent2 = aggregate: id: 43
      Promise.all [
        inmemoryStore.saveDomainEvent domainEvent1
        inmemoryStore.saveDomainEvent domainEvent2
      ]
      .then ->
        inmemoryStore.findDomainEventsByAggregateId [42, 43], (error, domainEvents) ->
          expect(domainEvents.length).to.equal 2
          expect(domainEvents[0]).to.equal domainEvent1
          expect(domainEvents[1]).to.equal domainEvent2
          done()


  describe '#findDomainEventsByNameAndAggregateId', ->

    beforeEach ->
      inmemoryStore.initialize contextFake


    it 'should call back with domain events with a matching aggregate id and a matching name', (done) ->
      domainEvent =
        name: 'SomethingHappened'
        aggregate: id: 42
      inmemoryStore.saveDomainEvent domainEvent
      .then ->
        inmemoryStore.findDomainEventsByNameAndAggregateId 'SomethingHappened', 42, (error, domainEvents) ->
          expect(domainEvents.length).to.equal 1
          expect(domainEvents[0]).to.equal domainEvent
          done()


    it 'should call back without domain events with another aggregate id or name', (done) ->
      domainEvent1 =
        name: 'SomethingElseHappened'
        aggregate: id: 42
      domainEvent2 =
        name: 'SomethingHappened'
        aggregate: id: 43
      Promise.all [
        inmemoryStore.saveDomainEvent domainEvent1
        inmemoryStore.saveDomainEvent domainEvent2
      ]
      .then ->
        inmemoryStore.findDomainEventsByNameAndAggregateId 'SomethingHappened', 42, (error, domainEvents) ->
          expect(domainEvents.length).to.equal 0
          done()


    it 'should call back with all domain events matching any name and the aggregate id given an array of names', (done) ->
      domainEvent1 =
        name: 'SomethingHappened'
        aggregate: id: 42
      domainEvent2 =
        name: 'SomethingElseHappened'
        aggregate: id: 42
      Promise.all [
        inmemoryStore.saveDomainEvent domainEvent1
        inmemoryStore.saveDomainEvent domainEvent2
      ]
      .then ->
        inmemoryStore.findDomainEventsByNameAndAggregateId ['SomethingHappened', 'SomethingElseHappened'], 42, (error, domainEvents) ->
          expect(domainEvents.length).to.equal 2
          expect(domainEvents[0]).to.equal domainEvent1
          expect(domainEvents[1]).to.equal domainEvent2
          done()


    it 'should call back with all domain events matching the name and any aggregate id given an array of ids', (done) ->
      domainEvent1 =
        name: 'SomethingHappened'
        aggregate: id: 42
      domainEvent2 =
        name: 'SomethingHappened'
        aggregate: id: 43
      Promise.all [
        inmemoryStore.saveDomainEvent domainEvent1
        inmemoryStore.saveDomainEvent domainEvent2
      ]
      .then ->
        inmemoryStore.findDomainEventsByNameAndAggregateId 'SomethingHappened', [42, 43], (error, domainEvents) ->
          expect(domainEvents.length).to.equal 2
          expect(domainEvents[0]).to.equal domainEvent1
          expect(domainEvents[1]).to.equal domainEvent2
          done()