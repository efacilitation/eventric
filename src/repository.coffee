_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class Repository

  _.extend @prototype, MixinRegisterAndGetClass::


module.exports = Repository
