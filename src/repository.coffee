class Repository

  _classes: {}

  registerClass: (className, Class) ->
    @_classes[className] = Class

  getClass: (className) ->
    return false unless className of @_classes
    @_classes[className]


module.exports = Repository
