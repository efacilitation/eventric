coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
commonjs    = require 'gulp-wrap-commonjs'
uglify      = require 'gulp-uglify'
rimraf      = require 'rimraf'
runSequence = require 'run-sequence'
mergeStream = require 'merge-stream'

module.exports = (gulp) ->
  gulp.task 'build', (next) ->
    runSequence 'build:clean', 'build:helper', 'build:src', 'build:release', next

  gulp.task 'build:clean', (next) ->
    rimraf './build', next

  gulp.task 'build:helper', ->
    gulp.src('+(src)/+(helper)/*.js')
      .pipe(gulp.dest('build/node'))

  gulp.task 'build:src', ->
    gulp.src(['index.coffee', '+(src)/*.coffee'])
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/node'))

  gulp.task 'build:release', ->
    cjs = gulp.src('node_modules/commonjs-require/commonjs-require.js')

    src = gulp.src('build/node/**/*.js')
      .pipe(commonjs(
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/build/node", 'eventric'
          path = path.replace /.js$/, ''
          return path
        ))

    nm = gulp.src([
      'node_modules/es6-promise/dist/promise-1.0.0.js'
    ])
      .pipe(commonjs(
        pathModifier: (filePath) ->
          matches = filePath.match /(bower_components|node_modules)\/(.*?)\//
          moduleName = matches[2]
          moduleName
      ))

    mergeStream cjs, src, nm
      .pipe(concat('eventric.js'))
      .pipe(gulp.dest('.'))
      .pipe(uglify())
      .pipe(concat('eventric-min.js'))
      .pipe(gulp.dest('.'))
