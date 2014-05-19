watch = require 'gulp-watch'

module.exports = (gulp) ->
  gulp.task 'watch', ->
    gulp.watch [
      '+(src|spec)/**/*.coffee'
    ], ['spec']
    return