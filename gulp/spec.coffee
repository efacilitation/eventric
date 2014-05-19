karma = require 'gulp-karma'
mocha = require 'gulp-mocha'

runSequence = require 'run-sequence'
fs          = require 'fs'

module.exports = (gulp) ->
  gulp.task 'spec', ->
    runSequence 'spec:server', 'spec:client'

  gulp.task 'spec:server', ->
    if !fs.existsSync 'node_modules/eventric'
      fs.symlinkSync '../src', 'node_modules/eventric', 'dir'

    gulp.src('spec/**/*.coffee')
      .pipe(mocha(reporter: 'spec'))

  gulp.task 'spec:client', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
