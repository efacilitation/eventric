describe 'AggregateRepository', ->
  AggregateRepository = eventric.require 'AggregateRepository'
  AggregateRoot       = eventric.require 'AggregateRoot'


  describe '#findById', ->

    Foo = null
    aggregateRepository = null
    EventStoreStub = null
    beforeEach ->
      class EventStore
        find: ->
        save: ->
      EventStoreStub = sinon.createStubInstance EventStore

      class Foo extends AggregateRoot

      aggregateRepository = new AggregateRepository EventStoreStub
      aggregateRepository.registerClass 'Foo', Foo


    it 'should return a instantiated Aggregate', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo

    it 'should ask the EventStore for DomainEvents matching the AggregateId', ->
      aggregateRepository.findById 'Foo', 42, ->
      expect(EventStoreStub.find.calledWith('Foo', {'aggregate.id': 42})).to.be.true

    it 'should return the Aggregate matching the given Id with all DomainEvents applied', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo
        expect(aggregate.name).to.equal 'John'