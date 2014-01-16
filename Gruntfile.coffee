module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'

  # Configure a mochaTest task
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'
        src: ['spec/**/*_spec.coffee']

    karma:
      unit:
        configFile: 'karma.conf.coffee'

    # Configure watcher
    watch:
      client:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['karma']

      server:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest']

      hybrid:
        files: ['src/**/*.coffee', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest', 'karma']