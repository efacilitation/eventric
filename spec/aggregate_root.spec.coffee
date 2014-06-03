describe 'AggregateRoot', ->
  AggregateRoot             = eventric.require 'AggregateRoot'
  AggregateEntity           = eventric.require 'AggregateEntity'
  AggregateEntityCollection = eventric.require 'AggregateEntityCollection'
  enderAggregate = null
  beforeEach ->
    enderAggregate = new AggregateRoot 'EnderAggregate'


  describe '#initialize', ->
    it 'should generate an id', ->
      enderAggregate.initialize()
      expect(enderAggregate.id).to.be.string


  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate.name = 'John'
      eventName = 'somethingHappend'


    it 'should create a DomainEvent including changes', ->
      enderAggregate.generateDomainEvent eventName
      expect(enderAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(enderAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        props:
          name: enderAggregate.name
        collections: {}
        entities: {}


    describe 'given param includeAggregateChanges is set to false', ->
      it 'then it should NOT include and clear the  changes', ->
        enderAggregate.generateDomainEvent eventName, {includeAggregateChanges: false}
        expect(enderAggregate.getDomainEvents()[0].name).to.equal eventName
        expect(enderAggregate.getDomainEvents()[0].aggregate.changed).to.equal undefined


  describe '#getDomainEvents', ->
    it 'should return the accumulated domainEvents', ->
      enderAggregate._domainEvents = ['someEvent']
      domainEvents = enderAggregate.getDomainEvents()
      expect(domainEvents.length).to.equal 1


  describe '#getSnapshot', ->
    it 'should return the current state as special "_snapshot"-DomainEvent', ->
      myThingsEntity = new AggregateEntity 'MyThingsEntity', name: 'NotWayne'
      myThingsEntity.id = 2
      myThingsEntity.name = 'Wayne'

      enderAggregate.id = 42
      enderAggregate.name = 'John'
      enderAggregate.things = new AggregateEntityCollection

      enderAggregate.things.add myThingsEntity

      snapshotEvent = enderAggregate.getSnapshot()
      expect(snapshotEvent.getAggregateChanges()).to.deep.equal
        props:
          name: 'John'
        entities: {}
        collections:
          things: [ {
            id: 2
            name: 'MyThingsEntity'
            changed:
              props:
                name: 'Wayne'
              entities: {}
              collections: {}
          } ]