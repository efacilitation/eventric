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


    it 'should return the correct result', ->
      exampleContext.query 'getExample', id: 1
      .then (result) ->
        expect(result).to.deep.equal queryResult


    describe 'given a query handler rejects with an error', ->
      dummyError = null

      beforeEach ->
        dummyError = new Error 'dummy error'


      it 'should re-throw an error with a descriptive message given the query handler triggers an error', ->
        exampleContext.addQueryHandlers
          getExampleWithError: ->
            new Promise ->
              throw dummyError

        exampleContext.query 'getExampleWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'getExampleWithError'
          expect(error.message).to.contain '{"foo":"bar"}'


      it 'should re-throw an error with a descriptive message given the query handler throws a synchronous error', ->
        exampleContext.addQueryHandlers
          getExampleWithError: (params) ->
            throw dummyError

        exampleContext.query 'getExampleWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'getExampleWithError'
          expect(error.message).to.contain '{"foo":"bar"}'


      it 'should make it possible to access the original error message given the query handler triggers an error', ->
        exampleContext.addQueryHandlers
          getExampleWithError: (params) ->
            new Promise ->
              throw dummyError

        exampleContext.query 'getExampleWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.originalErrorMessage).to.equal 'dummy error'


      it 'should throw a generic error given the query handler rejects without an error', ->
        exampleContext.addQueryHandlers
          getExampleWithoutError: (params) ->
            return Promise.reject()

        exampleContext.query 'getExampleWithoutError', foo: 'bar'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'getExampleWithoutError'
          expect(error.message).to.contain '{"foo":"bar"}'
