describe 'eventric', ->

  describe '#generateUuid', ->

    it 'should ask the uuid generator to generate a uuid', ->
      uuidGenerator = require './uuid_generator'
      sandbox.spy uuidGenerator, 'generateUuid'
      eventric.generateUuid()
      expect(uuidGenerator.generateUuid).to.have.been.called
