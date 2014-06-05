describe 'DomainEvent', ->
  domainEvent     = null
  domainEventData = null

  beforeEach ->
    DomainEvent = eventric.require 'DomainEvent'
    domainEventData =
      name: 'somethingHappened'
      aggregate:
        id: 42
        name: 'SomeAggregate'
        changed:
          name: 'John'

    domainEvent = new DomainEvent domainEventData


  describe '#getAggregateChanges', ->
    it 'should return the changes', ->
      expect(domainEvent.getAggregateChanges()).to.deep.equal domainEventData.aggregate.changed


  describe '#getTimestamp', ->
    it 'should return a timestamp', ->
      expect(domainEvent.getTimestamp()).to.be.an 'number'


  describe '#getName', ->
    it 'should return the event name', ->
      expect(domainEvent.getName()).to.equal domainEventData.name


  describe '#getAggregateId', ->
    it 'should return the aggregate id', ->
      expect(domainEvent.getAggregateId()).to.equal domainEventData.aggregate.id


  describe '#getAggregateName', ->
    it 'should return the aggregate name', ->
      expect(domainEvent.getAggregateName()).to.equal domainEventData.aggregate.name

