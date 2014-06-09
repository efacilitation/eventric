describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  myAggregate  = null
  beforeEach ->
    class MyAggregateStub
    aggregateDefinition =
      root: MyAggregateStub
    myAggregate = new Aggregate 'MyAggregate', aggregateDefinition


  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      myAggregate.applyProps
        some:
          ones:
            name: 'John'
      eventName = 'somethingHappend'


    it 'should create a DomainEvent including changes', ->
      myAggregate.generateDomainEvent eventName
      expect(myAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        some:
          ones:
            name: 'John'


    it 'should include the change even if the value was already present', ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo, name: 'Willy'
      myAggregate.applyProps
        name: 'Willy'

      myAggregate.generateDomainEvent()
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        name: 'Willy'


  describe '#getDomainEvents', ->
    it 'should return the accumulated domainEvents', ->
      myAggregate._domainEvents = ['someEvent']
      domainEvents = myAggregate.getDomainEvents()
      expect(domainEvents.length).to.equal 1


  describe '#applyChanges', ->
    it 'should apply given changes to properties and not track the changes', ->
      myAggregate = new Aggregate 'MyEntity', root: class Foo

      props =
        name: 'ChangedJohn'
        nested:
          structure: 'foo'
      myAggregate.applyChanges props

      json = myAggregate.toJSON()
      expect(json.name).to.equal 'ChangedJohn'
      expect(json.nested.structure).to.equal 'foo'
      myAggregate.generateDomainEvent()
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.be.undefined


  describe '#clearChanges', ->
    it 'should clear all changes', ->
      myAggregate = new Aggregate 'A1', root: class Foo
      myAggregate.id = 1
      myAggregate.applyProps
        name: 'John'
      myAggregate.clearChanges()
      myAggregate.generateDomainEvent()
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.be.undefined
