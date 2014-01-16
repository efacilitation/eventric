module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Configure a mochaTest task
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'

        src: [
          'spec/**/*_spec.coffee'
        ]

    # Configure watcher
    watch:
      tests:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest']