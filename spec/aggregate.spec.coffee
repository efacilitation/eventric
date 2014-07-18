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
      exampleMicroContext =
        getDomainEvent: sandbox.stub().returns SomethingHappened

      class ExampleRoot
        handleSomethingHappened: sandbox.stub()

      myAggregate = new Aggregate exampleMicroContext, 'MyAggregate', ExampleRoot
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
