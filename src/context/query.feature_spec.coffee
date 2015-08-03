describe 'Query Feature', ->

  describe 'given the context was not initialized yet', ->
    it 'should callback with an error including the context name and command name', ->
      someContext = eventric.context 'ExampleContext'
      someContext.query 'getSomething'
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'ExampleContext'
        expect(error.message).to.contain 'getSomething'


  describe 'given the query has no matching query handler', ->
    it 'should callback with an error', ->
      someContext = eventric.context 'ExampleContext'
      someContext.initialize()
      .then ->
        someContext.query 'getSomething'
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error


  describe 'given we created and initialized some example context including a query handler', ->
    exampleContext = null
    queryResult = null

    beforeEach ->
      queryResult = {}
      exampleContext = eventric.context 'exampleContext'

      exampleContext.addQueryHandlers
        getExample: (params) ->
          queryResult

      exampleContext.initialize()


    describe 'when we query the context', ->
      it 'then the query should return the correct result', ->
        exampleContext.query 'getExample', id: 1
        .then (result) ->
          expect(result).to.deep.equal queryResult
