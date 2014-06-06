describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  enderAggregate  = null
  beforeEach ->
    class EnderAggregateRootStub
    aggregateDefinition =
      root: EnderAggregateRootStub
    enderAggregate = new Aggregate 'EnderAggregate', aggregateDefinition


  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate.applyProps
        name: 'John'
      eventName = 'somethingHappend'


    it 'should create a DomainEvent including changes', ->
      enderAggregate.generateDomainEvent eventName
      expect(enderAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(enderAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        name: 'John'


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


  describe '#getMetaData', ->
    it 'should return an object including the MetaData of the Entity', ->
      myEntity = new Aggregate 'MyEntity', root: class Foo
      myEntity.id = 1

      expect(myEntity.getMetaData()).to.deep.equal
        id: 1
        name: 'MyEntity'


  describe '#getChanges', ->
    it 'should return changes to nested properties from the given entity', ->
      myEntity = new Aggregate 'myEntity', root: class Foo, name: 'Willy'
      myEntity.applyProps
        some:
          thing:
            name: 'John'

      expect(myEntity.getChanges()).to.deep.equal
        some:
          thing:
            name: 'John'


    it 'should return a change to a property even if its the same value', ->
      myEntity = new Aggregate 'myEntity', root: class Foo, name: 'Willy'
      myEntity.applyProps
        name: 'Willy'

      expect(myEntity.getChanges()).to.deep.equal
        name: 'Willy'


  describe '#clearChanges', ->
    it 'should clear all changes', ->
      a1 = new Aggregate 'A1', root: class Foo
      a1.id = 1
      a1.applyProps
        name: 'John'
      a1.clearChanges()
      expect(a1.getChanges()).to.deep.equal {}


  describe '#applyChanges', ->
    it 'should apply given changes to properties and not track the changes', ->
      myEntity = new Aggregate 'MyEntity', root: class Foo

      props =
        name: 'ChangedJohn'
        nested:
          structure: 'foo'
      myEntity.applyChanges props

      json = myEntity.toJSON()
      expect(json.name).to.equal 'ChangedJohn'
      expect(json.nested.structure).to.equal 'foo'
      expect(myEntity.getChanges()).to.deep.equal {}
