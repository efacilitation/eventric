describe 'eventric', ->

  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'

  Context = null
  Remote = null

  beforeEach ->
    Context = require './context'
    Remote = require './remote'


  describe '#setLogger', ->

    it 'should set a logger', ->
      logger = eventric.getLogger()
      CustomLogger = class CustomLogger
        setLogLevel: ->
        debug: ->
        warn: ->
        info: ->
        error: ->
      customLogger = new CustomLogger
      eventric.setLogger customLogger
      expect(eventric.getLogger()).to.be.equal customLogger


  describe '#getLogger', ->

    it 'should get the logger', ->
      logger = eventric.getLogger()
      expect(logger).to.be.equal require './logger'


  describe '#setLogLevel', ->

    it 'should set the log level for the logger', ->
      logger = require './logger'
      sandbox.spy logger, 'setLogLevel'
      eventric.setLogLevel 'warn'
      expect(logger.setLogLevel).to.have.been.calledWith 'warn'


  describe '#context', ->

    it 'should generate a new eventric context', ->
      context = eventric.context 'context'
      expect(context).to.be.an.instanceOf Context


    it 'should subscribe to all domain events of the context', ->
      sandbox.spy Context::, 'subscribeToAllDomainEvents'
      context = eventric.context 'context'
      expect(context.subscribeToAllDomainEvents).to.have.been.called


    it 'should delegate any event from the context to all remote endpoints', (done) ->
      domainEvent = domainEventSpecHelper.createDomainEvent 'SomeDomainEvent'
      contextName = domainEvent.context
      sandbox.stub(Context::, 'subscribeToAllDomainEvents').yields domainEvent

      inmemoryRemoteEndpoint = require('eventric-remote-inmemory').endpoint
      sandbox.stub inmemoryRemoteEndpoint, 'publish'

      eventric.context contextName

      setTimeout ->
        expect(inmemoryRemoteEndpoint.publish).to.have.been.calledWith contextName, 'SomeDomainEvent', domainEvent
        expect(inmemoryRemoteEndpoint.publish).to.have.been.calledWith contextName, 'SomeDomainEvent', sinon.match.string,
          domainEvent
        done()


  describe '#remoteContext', ->

    it 'should throw an error given no context name', ->
      expect(-> eventric.remoteContext null ).to.throw Error, /Missing context name/


    it 'should return the remote context for a given context name', ->
      remoteContext = eventric.remoteContext 'ContextName'
      expect(remoteContext).to.be.an.instanceOf Remote


    it 'should cache remote contexts by context name', ->
      remote1 = eventric.remoteContext 'ContextName'
      remote2 = eventric.remoteContext 'ContextName'
      expect(remote1).to.equal remote2


    it 'should not set a default remote client on the returned remote context given no default client was set before', ->
      inmemoryRemote = require 'eventric-remote-inmemory'
      remoteContext = eventric.remoteContext 'ContextName'
      expect(remoteContext._client).to.equal inmemoryRemote.client


    it 'should set the default remote client on the returned remote context given a default client was set before', ->
      remoteClient = {}
      eventric.setDefaultRemoteClient remoteClient
      remoteContext = eventric.remoteContext 'ContextName'
      expect(remoteContext._client).to.equal remoteClient


  describe '#setDefaultRemoteClient', ->

    it 'should remember the default remote client', ->
      remoteClient = {}
      eventric.setDefaultRemoteClient remoteClient
      expect(eventric._defaultRemoteClient).to.equal remoteClient


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
