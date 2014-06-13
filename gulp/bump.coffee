bump = require 'gulp-bump'

module.exports = (gulp) ->
  gulp.task 'bump:minor', ->
    gulp.src('./*.json')
    .pipe bump(type: 'minor')
    .pipe gulp.dest('./')

  gulp.task 'bump:patch', ->
    gulp.src('./*.json')
    .pipe bump(type: 'patch')
    .pipe gulp.dest('./')