gutil         = require 'gulp-util'
child_process = require 'child_process'

module.exports = (name, command, next = ->) ->
  child_process.exec(
    command
    (error, stdout, stderr) ->
      if error and error.code
        customError =
          message: "Failed: #{name}"

        gutil.log stdout
        gutil.log stderr
        gutil.log gutil.colors.red error
        gutil.log gutil.colors.red customError.message
        gutil.beep()
        if process.env.NODE_ENV isnt 'vagrant'
          process.exit 1
      else

        gutil.log stdout
        gutil.log stderr
        gutil.log gutil.colors.green "Finished: #{name}"
        next()
  )