eventric = require 'eventric'
Clone = eventric.require 'HelperClone'
_ = eventric.require 'HelperUnderscore'


# polyfill .isArray
Array.isArray or (Array.isArray = (a) ->
  "" + a isnt a and {}.toString.call(a) is "[object Array]"
)


ObjectDiff =
  getDifferences: (oldObject, newObject) ->
    diff = []
    @_getPathsDeletedAndChangedFrom oldObject, newObject, diff
    @_getPathsAddedFrom newObject, oldObject, diff
    diff


  _getPathsDeletedAndChangedFrom: (oldObject, newObject, diff, path = []) ->
    _.each oldObject, (val, key) =>
      eachPath = Clone path

      valueType = typeof val
      if valueType == 'object' && Array.isArray val
        valueType = 'array'

      if valueType == 'function'
        # we ignore functions
        return true

      eachPath.push
        key: key
        valueType: valueType

      check = @_checkPathAgainstObjectVal eachPath, newObject, val
      switch check.code
        when 'PATH_DOES_NOT_EXIST'
          diff.push
            type: 'deleted'
            path: eachPath

        when 'PATH_EXISTS_BUT_VALUE_DIFFERS'
          diff.push
            type: 'changed'
            path: eachPath
            value: check.value

        when 'PATH_EXISTS'
          if _.isObject val
            @_getPathsDeletedAndChangedFrom val, newObject, diff, eachPath

        when 'PATH_EXISTS_AND_VALUE_MATCHES' then # do nothing

      return true


  _getPathsAddedFrom: (newObject, oldObject, diff, path = []) ->
    _.each newObject, (val, key) =>
      eachPath = Clone path

      valueType = typeof val
      if valueType == 'object' && Array.isArray val
        valueType = 'array'

      if valueType == 'function'
        # we ignore functions
        return true

      eachPath.push
        key: key
        valueType: valueType

      check = @_checkPathAgainstObjectVal eachPath, oldObject, val
      switch check.code
        when 'PATH_DOES_NOT_EXIST'
          # does not exists in the old object, so it got added
          diff.push
            type: 'added'
            path: eachPath
            value: val
        else
          if _.isObject val
            @_getPathsAddedFrom val, oldObject, diff, eachPath


  _checkPathAgainstObjectVal: (path, obj, val) ->
    objLevelRef = obj
    for pathObj in path
      objLevelRef = objLevelRef[pathObj.key]
      if objLevelRef is undefined
        return {
          code: 'PATH_DOES_NOT_EXIST'
        }

    # check value only if its not an object
    if !(_.isObject objLevelRef)
      if objLevelRef == val
        return {
          code: 'PATH_EXISTS_AND_VALUE_MATCHES'
        }
      else
        return {
          code: 'PATH_EXISTS_BUT_VALUE_DIFFERS'
          value: objLevelRef
        }

    return {
      code: 'PATH_EXISTS'
    }


  applyDifferences: (object, differences) ->
    for diffObj in differences
      lastPathObj = diffObj.path.pop()
      objectRef = object
      for pathObj in diffObj.path
        if !objectRef[pathObj.key]
          switch pathObj.valueType
            when 'object'
              objectRef[pathObj.key] = {}
            when 'array'
              objectRef[pathObj.key] = []

        objectRef = objectRef[pathObj.key]

      switch diffObj.type
        when 'added', 'changed'
          objectRef[lastPathObj.key] = diffObj.value
        when 'deleted'
          delete objectRef[lastPathObj.key]

    object


module.exports = ObjectDiff