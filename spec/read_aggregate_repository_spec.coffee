describe 'ReadAggregateRepositorySpec', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'

  sandbox = null

  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    class FooReadAggregate extends ReadAggregateRoot

    readAggregateRepository = null

    beforeEach ->
      adapter =
        findById: ->
      readAggregateRepository = new ReadAggregateRepository adapter, FooReadAggregate


    it 'should return a instantiated ReadAggregate', ->
      expect(readAggregateRepository.findById(1)).to.be.a FooReadAggregate

    it 'should ask the adapter for the AggregateData', ->
      adapter_findById = sandbox.spy readAggregateRepository._adapter, 'findById'
      readAggregateRepository.findById 27
      expect(adapter_findById.calledWith(27)).to.be.ok()

    it 'should return a instantiated ReadAggregate containing the applied AggregateData', ->
      sandbox.stub readAggregateRepository._adapter, 'findById', -> id: 1, name: 'Foo'
      readAggregate = readAggregateRepository.findById 1
      expect(readAggregate.name).to.be 'Foo'