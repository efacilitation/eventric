coffee      = require 'gulp-coffee'
concat      = require 'gulp-concat'
commonjs    = require 'gulp-wrap-commonjs'
uglify      = require 'gulp-uglify'
rimraf      = require 'rimraf'
runSequence = require 'run-sequence'

module.exports = (gulp) ->
  gulp.task 'build', (next) ->
    runSequence 'build:clean', 'build:helper', 'build:src', 'build:release', next

  gulp.task 'build:clean', ->
    rimraf './build', ->
      console.log 'wat'

  gulp.task 'build:helper', ->
    gulp.src('+(src)/+(helper)/*.js')
      .pipe(gulp.dest('build/node'))

  gulp.task 'build:src', ->
    gulp.src(['index.coffee', '+(src)/*.coffee'])
      .pipe(coffee({bare: true}))
      .pipe(gulp.dest('build/node'))

  gulp.task 'build:release', ->
    gulp.src('build/node/**/*.js')
      .pipe(commonjs(
        pathModifier: (path) ->
          path = path.replace "#{process.cwd()}/build/node", 'eventric'
          path = path.replace /.js$/, ''
          return path
        ))
      .pipe(concat('eventric.js'))
      .pipe(gulp.dest('build/release'))
      .pipe(uglify())
      .pipe(concat('eventric-min.js'))
      .pipe(gulp.dest('build/release'))
