coffee      = require 'gulp-coffee'
mocha       = require 'gulp-mocha'
gutil       = require 'gulp-util'
del         = require 'del'
webpack     = require 'webpack-stream'
runSequence = require 'run-sequence'
fs          = require 'fs'
spawn       = require('child_process').spawn

require 'coffee-loader'

module.exports = (gulp) ->
  lastSpecError = false
  gulp.task 'specs', (next) ->
    runSequence 'symlink', 'specs:server', 'specs:client', 'specs:client', ->
      next()

  mochaProcess = null
  gulp.task 'specs:server', (next) ->
    glob = [
      'src/setup.spec.coffee'
      'src/**/*.coffee'
      ]

    options = [
      '--compilers'
      'coffee:coffee-script/register'
      '--reporter'
      'spec'
    ]
    if mochaProcess and mochaProcess.kill
      mochaProcess.kill()
    mochaProcess = spawn(
      'node_modules/.bin/mocha'
      options.concat(glob)
      {}
    )
    mochaProcess.stdout.on 'data', (data) ->
      process.stdout.write data.toString()
    mochaProcess.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    mochaProcess.on 'close', (code) ->
      if code is 0
        gutil.log gutil.colors.green "Finished: mocha server"
        next()
      else
        errorMessage = "Failed: mocha server"
        gutil.log gutil.colors.red errorMessage
        gutil.beep()
        if process.env.CI
          process.exit 1
        else
          next()

  gulp.task 'specs:client', ->
    runSequence 'specs:client:clean', 'specs:client:build', 'specs:client:run'


  gulp.task 'specs:client:clean', (next) ->
    del './dist', force: true, next


  gulp.task 'specs:client:build', ->
    gulp.src [
      'src/**/*.coffee'
    ]
    .pipe webpack
      module:
        loaders: [
          {test: /\.coffee$/i, loader: 'coffee-loader'}
        ]
      resolve:
        extensions: ['', '.js', '.coffee']
    .pipe gulp.dest 'dist/specs'


  gulp.task 'specs:client:run', (next) ->
    executeChildProcess = require './helper/child_process'
    executeChildProcess(
      'Karma specs'
      'node_modules/karma/bin/karma start'
      next
    )
