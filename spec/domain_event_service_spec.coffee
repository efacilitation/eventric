describe 'DomainEventService', ->

  sinon      = require 'sinon'
  expect     = require 'expect'

  DomainEventService = require('eventric')('DomainEventService')

  describe '#handle', ->

    it 'should call _applyChanges with given DomainEvents on active matching ReadModels', ->

      class ExampleReadModel
        _applyChanges: sinon.stub()

      exampleReadModel = new ExampleReadModel

      DomainEventService.handlers =
        'Example':
          1: [
            exampleReadModel
          ]

      domainEvent =
        name: 'testEvent'
        data:
          id: 1
          model: 'Example'
        changed:
          props:
            name: 'John'

      DomainEventService.handle [domainEvent]

      expect(exampleReadModel._applyChanges.calledOnce).to.be.ok()

