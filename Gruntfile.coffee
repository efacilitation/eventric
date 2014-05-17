module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-wrap-commonjs'
  grunt.loadNpmTasks 'grunt-symbolic-link'

  # Configure a mochaTest task
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'
        src: [
          'spec/**/*_spec.coffee'
        ]

    karma:
      unit:
        configFile: 'karma.conf.coffee'

    # Configure watcher
    watch:
      client:
        files: ['src/**/*.+(coffee|js)', 'spec/**/*_spec.coffee']
        tasks: ['karma', 'build']

      server:
        files: ['src/**/*.+(coffee|js)', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest', 'build']

      hybrid:
        files: ['src/**/*.+(coffee|js)', 'spec/**/*_spec.coffee']
        tasks: ['mochaTest', 'karma', 'build']


    commonjs:
      modules:
        options:
          pathReplace: (path) ->
            path = path.replace 'src', 'eventric'

        cwd: '.'
        src: ['src/**/*.+(coffee|js)']
        dest: 'tmp/'

    coffee:
      glob_to_multiple:
        expand: true
        flatten: true
        cwd: 'tmp/src'
        src: ['*.coffee']
        dest: 'tmp/src'
        ext: '.js'

    concat:
      dist:
        src: ['tmp/**/*.js'],
        dest: 'dist/eventric.js',

    symlink:
      eventric:
        target: '..'
        link: 'node_modules/eventric'
        options:
          overwrite: true
          force: true

    clean: ['tmp']

  grunt.registerTask 'build', ['commonjs', 'coffee', 'concat', 'clean']
  grunt.registerTask 'spec:client', ['karma']
  grunt.registerTask 'spec:server', ['mochaTest']
  grunt.registerTask 'spec', ['symlink', 'spec:server', 'spec:client']
