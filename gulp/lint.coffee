coffeelint = require 'gulp-coffeelint'
runSequence = require 'run-sequence'

module.exports = (gulp) ->
  aTaskHasErrors = false

  gulp.task 'lint', (callback) ->
    runSequence 'lint:coffee', ->
      if aTaskHasErrors
        process.exit 1
      callback()


  gulp.task 'lint:coffee', ->

    class CoffeelintReporter
      constructor: (@errorReport) ->

      publish: ->
        if @errorReport.hasError()
          aTaskHasErrors = true

    gulp.src [
        'src/**/*.coffee'
        'gulp/**/*.coffee'
      ]
      .pipe coffeelint()
      .pipe(coffeelint.reporter())
      .pipe(coffeelint.reporter CoffeelintReporter)
