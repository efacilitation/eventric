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
      expect(enderAggregate._id).to.be.ok()

  describe '#_domainEvent', ->
    eventName = null
    beforeEach ->
      enderAggregate.name = 'John'
      eventName = 'somethingHappend'

    it 'should create an event, add it to _domainEvents, include changes and clear the changes afterwards', ->
      enderAggregate._domainEvent eventName

      expect(enderAggregate._domainEvents[0].name).to.be eventName
      expect(enderAggregate._domainEvents[0].changed.props.name).to.be enderAggregate.name
      expect(enderAggregate._propsChanged).to.eql {}

    describe 'given param includeChanges is set to false', ->

      it 'then it should NOT include and clear the changes', ->
        enderAggregate._domainEvent eventName, {includeChanges: false}

        expect(enderAggregate._domainEvents[0].name).to.be eventName
        expect(enderAggregate._domainEvents[0].changed).to.be undefined
        expect(enderAggregate._propsChanged).to.not.eql {}

  describe '#getDomainEvents', ->

    it 'should return the accumulated domainEvents', ->
      enderAggregate._domainEvents = ['someEvent']
      domainEvents = enderAggregate.getDomainEvents()
      expect(domainEvents.length).to.be 1
