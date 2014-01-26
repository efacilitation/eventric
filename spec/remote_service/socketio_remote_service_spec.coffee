describe 'SocketIORemoteService', ->

  _        = require 'underscore'
  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  socketIOClient = require 'socket.io-client'

  SocketIORemoteService = eventric 'SocketIORemoteService'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#rpc', ->

    it 'should emit the given payload over socket.io-client', (done) ->

      socketIOClientStub = sandbox.stub socketIOClient
      socketIOClientStub.emit = sandbox.stub()

      socketIORemoteService = new SocketIORemoteService socketIOClient

      rpcPayload =
        some: 'payload'

      socketIORemoteService.rpc rpcPayload, ->

        expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.ok()
        done()