describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  DomainEvent = eventric.require 'DomainEvent'

  it 'should inject the $emitDomainEvent method into the aggregate root', ->
    exampleRoot = {}
    myAggregate = new Aggregate {}, 'MyAggregate', sandbox.stub().returns exampleRoot

    expect(exampleRoot.$emitDomainEvent).to.be.ok


  describe '#emitDomainEvent', ->
    it 'should call a handle method on the aggregate based on the DomainEvent Name', ->
      class SomethingHappened
        constructor: sandbox.stub()
      exampleContext =
        getDomainEvent: sandbox.stub().returns SomethingHappened

      class ExampleRoot
        handleSomethingHappened: sandbox.stub()

      myAggregate = new Aggregate exampleContext, 'MyAggregate', ExampleRoot
      myAggregate.emitDomainEvent 'SomethingHappened', some: 'properties'

      applyCall = ExampleRoot::handleSomethingHappened.getCall 0
      expect(applyCall.args[0]).to.be.an.instanceof DomainEvent
      expect(applyCall.args[0].payload).to.be.an.instanceof SomethingHappened


  describe '#applyDomainEvents', ->
    it 'should call the handle function of the given DomainEvent', ->
      class ExampleRoot
        handleSomethingHappened: sandbox.stub()

      domainEvent = new DomainEvent
        name: 'SomethingHappened'

      myAggregate = new Aggregate {}, 'MyAggregate', ExampleRoot
      myAggregate.applyDomainEvents [domainEvent]

      expect(ExampleRoot::handleSomethingHappened).to.have.been.calledWith sinon.match.instanceOf DomainEvent


  describe '#command', ->
    it 'should call an aggregate method based on the given commandName together with the arguments', ->
      someParameters = [
        'something'
      ]

      class Foo
        someMethod: sandbox.stub()
      myAggregate = new Aggregate {}, 'MyAggregate', Foo

      command =
        name: 'someMethod'
        params: someParameters
      myAggregate.command command
      .then =>
        expect(Foo::someMethod).to.have.been.calledWith command.params...


    it 'should callback with error if the command does not exist in the root', (done) ->
      class Foo
      myAggregate = new Aggregate {}, 'MyAggregate', Foo

      myAggregate.command
        name: 'someMethod'
        params: []
      .catch (error) =>
        expect(error).to.be.an.instanceof Error
        done()


    it 'should handle non array params automatically', ->
      class Foo
        someMethod: sandbox.stub()
      myAggregate = new Aggregate {}, 'MyAggregate', Foo

      myAggregate.command
        name: 'someMethod'
        params: 'foo'
      .then =>
        expect(Foo::someMethod).to.have.been.calledWith 'foo'
