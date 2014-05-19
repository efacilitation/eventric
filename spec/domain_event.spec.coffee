describe 'DomainEvent', ->
  domainEvent     = null
  domainEventData = null

  beforeEach ->
    DomainEvent = eventric 'DomainEvent'
    domainEventData =
      name: 'somethingHappened'
      aggregate:
        id: 42
        name: 'SomeAggregate'
        changed:
          props:
            name: 'John'
          entities:
            some: 'thing'
          collections:
            another: 'thing'

    domainEvent = new DomainEvent domainEventData


  describe '#getAggregateChanges', ->
    describe 'given no parameter', ->
      it 'should return the whole changed object', ->
        expect(domainEvent.getAggregateChanges()).to.deep.equal domainEventData.aggregate.changed


    describe 'given props as parameter', ->
      it 'should return the changed props', ->
        expect(domainEvent.getAggregateChanges 'props').to.deep.equal domainEventData.aggregate.changed.props


    describe 'given entities as parameter', ->
      it 'should return the changed entities', ->
        expect(domainEvent.getAggregateChanges 'entities').to.deep.equal domainEventData.aggregate.changed.entities


    describe 'given collections as parameter', ->
      it 'should return the changed collections', ->
        expect(domainEvent.getAggregateChanges 'collections').to.deep.equal domainEventData.aggregate.changed.collections


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

