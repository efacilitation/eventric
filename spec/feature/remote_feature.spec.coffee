describe 'Remote Feature', ->
  exampleContext  = null
  doSomethingStub = null
  beforeEach (done) ->
    doSomethingStub = sandbox.stub()

    exampleContext = eventric.context 'Example'
    exampleContext.addCommandHandlers
      DoSomething: (params, callback) ->
        doSomethingStub()
        callback()

    exampleContext.initialize ->
      done()


  describe 'given we created and initialized some example context', ->
    it 'then it should be able to receive commands over a remote', (done) ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()


  describe 'given we created and initialized some example context with a custom remote endpoint', ->
    customRemoteBridge = null
    beforeEach ->
      class CustomRemoteTransportEndpoint
        constructor: (@_handleRPCRequest) ->
          customRemoteBridge = (rpcRequest) =>
            @_handleRPCRequest rpcRequest

      eventric.addRemoteTransportEndpoint 'custom', CustomRemoteTransportEndpoint


    it 'then it should be able to receive commands over the custom remote transport', (done) ->
      class CustomRemoteTransportClient
        rpc: (rpcRequest) ->
          customRemoteBridge rpcRequest

      exampleRemote = eventric.remote 'Example'
      exampleRemote.addTransport 'custom', CustomRemoteTransportClient
      exampleRemote.set 'default transport', 'custom'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()
