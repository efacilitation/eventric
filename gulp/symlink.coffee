symlink   = require 'gulp-symlink'

module.exports = (gulp) ->
  gulp.task 'symlink', ->
    gulp.src './'
    .pipe symlink(
      'node_modules/eventric'
      force: true
    )