# http://stackoverflow.com/a/2117523/192107
class UuidGenerator

  _uuidTemplate: 'xxxxxxxx-xxxx-4xxx-vxxx-xxxxxxxxxxxx'

  generateUuid: ->
    uuid = @_uuidTemplate.replace /[xv]/g, (characterToReplace) ->
      randomNumber = Math.floor Math.random() * 16
      if characterToReplace is 'x'
        return randomNumber.toString 16
      else
        variant = randomNumber & 0x3 | 0x8
        return variant.toString 16

    return uuid


module.exports = new UuidGenerator
