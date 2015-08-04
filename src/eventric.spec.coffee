describe 'eventric', ->

  describe '#generateUid', ->

    it 'should ask the uid generator to generate a unique id', ->
      uidGenerator = require './uid_generator'
      sandbox.spy uidGenerator, 'generateUid'
      eventric.generateUid()
      expect(uidGenerator.generateUid).to.have.been.called