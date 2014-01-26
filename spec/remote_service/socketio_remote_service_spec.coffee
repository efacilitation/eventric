describe 'SocketIORemoteService', ->

  _        = require 'underscore'
  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  SocketIORemoteService = eventric 'SocketIORemoteService'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#rpc', ->

    rpcPayload = null
    socketIORemoteService = null
    socketIOClientStub = null

    beforeEach ->
      socketIOClientStub = sandbox.stub()
      socketIOClientStub.emit = sandbox.stub()
      socketIOClientStub.on = sandbox.stub().yields {some: 'data'}
      socketIORemoteService = new SocketIORemoteService socketIOClientStub

      rpcPayload =
        some: 'payload'


    it 'should emit the given payload as rpc request over socket.io-client', ->
      socketIORemoteService.rpc rpcPayload, ->
      expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.ok()

    it 'should callback on rpc response', (done) ->
      socketIORemoteService.rpc rpcPayload, (data) ->
        expect(data).to.eql {some: 'data'}
        done()