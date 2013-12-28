describe 'AggregateRoot', ->

  expect = require 'expect'
  AggregateRoot = require('eventric')('AggregateRoot')

  describe '#_domainEvent', ->
    eventName = null
    a = null

    beforeEach ->
      class A extends AggregateRoot
        @prop 'name'

      a = new A()
      a.name = 'John'

      eventName = 'somethingHappend'

    it 'should create an event, add it to _domainEvents, include changes and clear the changes afterwards', ->
      a._domainEvent eventName

      expect(a._domainEvents[0].name).to.be eventName
      expect(a._domainEvents[0].changed.props.name).to.be a.name
      expect(a._propsChanged).to.eql {}

    describe 'given param includeChanges is set to false', ->

      it 'then it should NOT include and clear the changes', ->
        a._domainEvent eventName, {includeChanges: false}

        expect(a._domainEvents[0].name).to.be eventName
        expect(a._domainEvents[0].changed).to.be undefined
        expect(a._propsChanged).to.not.eql {}

  describe '#getDomainEvents', ->

    it 'should return the accumulated domainEvents', ->
      class MyAggregate extends AggregateRoot
          myAggregateFunction: ->
            @_domainEvent 'myDomainEvent'

      myAggregate = new MyAggregate
      myAggregate.myAggregateFunction()
      domainEvents = myAggregate.getDomainEvents()
      expect(domainEvents.length).to.be 1
