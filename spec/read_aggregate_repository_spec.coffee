describe 'ReadAggregateRepositorySpec', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'

  class ReadFoo extends ReadAggregateRoot

  sandbox = null
  readAggregateRepository = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    adapter =
      _findDomainEventsByAggregateId: -> []
      _findAggregateIdsByDomainEventCriteria: -> []

    readAggregateRepository = new ReadAggregateRepository adapter, ReadFoo

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    it 'should return a instantiated ReadAggregate', ->
      expect(readAggregateRepository.findById(1)).to.be.a ReadFoo

    it 'should ask the adapter for the DomainEvents matching the AggregateId', ->
      adapterSpy = sandbox.spy readAggregateRepository._adapter, '_findDomainEventsByAggregateId'
      readAggregateRepository.findById 27
      expect(adapterSpy.calledWith(27)).to.be.ok()

    it 'should return a instantiated ReadAggregate containing the applied DomainEvents', ->
      testEvent =
        name: 'testEvent'
        metaData:
          id: 1
          name: 'FooAggregate'
        _changed:
          props:
            name: 'John'

      sandbox.stub readAggregateRepository._adapter, '_findDomainEventsByAggregateId', ->
        [ testEvent ]

      readAggregate = readAggregateRepository.findById 1
      expect(readAggregate.name).to.be 'John'


  describe '#findByIds', ->

    it 'should call findById for every given id', ->
      findByIdStub = sandbox.stub readAggregateRepository, 'findById'
      readAggregateRepository.findByIds [1, 2]
      expect(findByIdStub.calledTwice).to.be.ok()

  describe '#find', ->

    criteria = null
    findByIdStub = null
    adapterStub = null
    beforeEach ->
      criteria = {}
      findByIdStub = sandbox.stub readAggregateRepository, 'findById', -> new ReadFoo
      adapterStub = sandbox.stub readAggregateRepository._adapter, '_findAggregateIdsByDomainEventCriteria', -> [42]

    it 'should ask the adapter for the AggregateIds matching the DomainEvent-Criteria', ->
      # stub _findAggregateIdsByDomainEventCriteria to return an example AggregateId
      readAggregateRepository.find criteria
      expect(adapterStub.calledWith criteria).to.be.ok()

    it 'should call findById for every aggregateId found', ->
      readAggregateRepository.find criteria
      expect(findByIdStub.calledWith 42).to.be.ok()

    it 'should return ReadAggregate instances based on the given query-criteria', ->
      readAggregates = readAggregateRepository.find criteria
      expect(readAggregates.length).to.be 1
      expect(readAggregates[0]).to.be.a ReadFoo