describe 'domain event id generator', ->
  domainEventIdGenerator = null

  describe '#generateId', ->

    beforeEach ->
      sandbox.stub Date, 'now'
      domainEventIdGenerator = require './'


    it 'should return the current microsecond timestamp', ->
      Date.now.returns 1000000000000
      id = domainEventIdGenerator.generateId()
      expect(id).to.equal 1000000000000000


    it 'should increment the counter given there are two domain events with same microsecond timestamp', ->
      Date.now.returns 1000000000000
      domainEventIdGenerator.generateId()
      id = domainEventIdGenerator.generateId()
      expect(id).to.equal 1000000000000001


    it 'should reset the counter given the last microsecond timestamp is not equal the generated microsecond timestamp', ->
      Date.now.returns 1000000000000
      domainEventIdGenerator.generateId()
      domainEventIdGenerator.generateId()

      Date.now.returns 1000000000001
      id = domainEventIdGenerator.generateId()
      expect(id).to.equal 1000000000001000
