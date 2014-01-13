describe 'AggregateRoot', ->

  expect        = require 'expect'
  eventric      = require 'eventric'
  AggregateRoot = eventric 'AggregateRoot'

  enderAggregate = null
  beforeEach ->
    class EnderAggregate extends AggregateRoot
      @prop 'name'

    enderAggregate = new EnderAggregate

  describe '#create', ->

    it 'should generate an id', ->
      enderAggregate.create()
      expect(enderAggregate.id).to.be.ok()

  describe '#generateDomainEventAndClearChanges', ->
    eventName = null
    beforeEach ->
      enderAggregate.name = 'John'
      eventName = 'somethingHappend'

    it 'should create an event, add it to _domainEvents, include changes and clear the changes afterwards', ->
      enderAggregate.generateDomainEventAndClearChanges eventName

      expect(enderAggregate.getDomainEvents()[0].name).to.be eventName
      expect(enderAggregate.getDomainEvents()[0].aggregate.changed.props.name).to.be enderAggregate.name
      expect(enderAggregate._propsChanged).to.eql {}

    describe 'given param includeAggregateChanges is set to false', ->

      it 'then it should NOT include and clear the  changes', ->
        enderAggregate.generateDomainEventAndClearChanges eventName, {includeAggregateChanges: false}

        expect(enderAggregate.getDomainEvents()[0].name).to.be eventName
        expect(enderAggregate.getDomainEvents()[0].aggregate.changed).to.be undefined
        expect(enderAggregate._propsChanged).to.not.eql {}

  describe '#getDomainEvents', ->

    it 'should return the accumulated domainEvents', ->
      enderAggregate._domainEvents = ['someEvent']
      domainEvents = enderAggregate.getDomainEvents()
      expect(domainEvents.length).to.be 1
