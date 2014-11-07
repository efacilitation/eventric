spawn   = require('child_process').spawn
gutil   = require 'gulp-util'

SIGTERM_CODE = 143

module.exports = (name, command, args, options = {}, callback = ->) ->
  errorMessage = ''
  childProcess = spawn command, args, options

  childProcess.on 'close', (code) ->
    if code is 0
      gutil.log gutil.colors.green "Finished: #{name}"
      callback()
    else if code isnt SIGTERM_CODE and code isnt null
      errorMessage = "Failed: #{name}"
      gutil.log gutil.colors.red errorMessage
      gutil.beep()
      if process.env.NODE_ENV isnt 'vagrant'
        process.exit 1
      callback()

  childProcess