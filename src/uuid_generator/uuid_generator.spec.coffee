describe 'uuid generator', ->

  describe '#generateUuid', ->

    it 'should generate a rfc4122 version 4 compliant uuid', ->
      uuidGenerator = require './'
      uuid = uuidGenerator.generateUuid()
      expect(uuid).to.match /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
