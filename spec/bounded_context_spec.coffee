describe 'BoundedContext', ->

  expect         = require 'expect.js'
  sinon          = require 'sinon'
  eventric       = require 'eventric'

  CommandService           = eventric 'CommandService'
  ReadAggregateRepository  = eventric 'ReadAggregateRepository'
  BoundedContext           = eventric 'BoundedContext'

  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the command service with the correct parameters', ->
        commandServiceMock = sinon.createStubInstance CommandService
        readAggregateRepositoryMock = sinon.createStubInstance ReadAggregateRepository

        boundedContext = new BoundedContext
          name: 'example'
          commandService: commandServiceMock
          readAggregateRepository: readAggregateRepositoryMock
        id = 42
        params = {foo: 'bar'}
        boundedContext.command 'Aggregate:function', id, params
        expect(commandServiceMock.commandAggregate.calledWith 'Aggregate', id, 'function', params).to.be.ok()


    describe 'has a registered handler', ->
      it 'should execute the command handler'


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should execute the query directly on the repository'


    describe 'has a registered handler', ->
      it 'should execute the query handler'