class UidGenerator

  generateUid: (delimiter = "-") ->
    # http://stackoverflow.com/a/12223573
    return @_s4() + @_s4() + delimiter + @_s4() + delimiter + @_s4() + delimiter + @_s4() + delimiter + @_s4() + @_s4() + @_s4()


  _s4: ->
    (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

module.exports = new UidGenerator