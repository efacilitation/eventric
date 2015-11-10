describe 'eventric', ->

  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'

  Context = null

  beforeEach ->
    Context = require './context'


  describe '#context', ->

    it 'should generate a new eventric context', ->
      context = eventric.context 'context'
      expect(context).to.be.an.instanceOf Context


    it 'should subscribe to all domain events of the context', ->
      sandbox.spy Context::, 'subscribeToAllDomainEvents'
      context = eventric.context 'context'
      expect(context.subscribeToAllDomainEvents).to.have.been.called


    it 'should delegate any event from the context to all remote endpoints', (done) ->
      contextName = 'context'
      domainEvent = domainEventSpecHelper.createDomainEvent 'SomeDomainEvent'
      domainEvent.context = contextName
      sandbox.stub(Context::, 'subscribeToAllDomainEvents').yields domainEvent

      inmemoryRemoteEndpoint = require('eventric-remote-inmemory').endpoint
      sandbox.stub inmemoryRemoteEndpoint, 'publish'

      eventric.context contextName

      setTimeout ->
        expect(inmemoryRemoteEndpoint.publish).to.have.been.calledWith contextName, 'SomeDomainEvent', domainEvent
        expect(inmemoryRemoteEndpoint.publish).to.have.been.calledWith contextName, 'SomeDomainEvent', sinon.match.string,
          domainEvent
        done()


  describe '#getRegisteredContextNames', ->

    it 'should return all names of all registered contexts', ->
      eventric.context 'context1'
      eventric.context 'context2'
      contextNames = eventric.getRegisteredContextNames()
      expect(contextNames).to.deep.equal ['context1', 'context2']


  describe '#generateUuid', ->

    it 'should ask the uuid generator to generate a uuid', ->
      uuidGenerator = require './uuid_generator'
      sandbox.spy uuidGenerator, 'generateUuid'
      eventric.generateUuid()
      expect(uuidGenerator.generateUuid).to.have.been.called
