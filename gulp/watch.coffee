module.exports = (gulp) ->
  gulp.task 'watch', ->
    gulp.watch [
      '+(src|spec)/**/*.+(coffee|js)'
    ], ['specs']
    return
