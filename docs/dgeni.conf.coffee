path    = require("canonical-path")
Package = require('dgeni').Package

module.exports = new Package('privacly', [
  require('dgeni-packages/jsdoc'),
  require('dgeni-packages/nunjucks')
])

.config (log, readFilesProcessor, templateFinder, writeFilesProcessor) ->

  log.level = 'debug'

  readFilesProcessor.basePath = path.resolve(__dirname, '..')

  readFilesProcessor.sourceFiles = [
    {
      include: 'build/node/src/*.js'
    }
  ]

  templateFinder.templateFolders.unshift(path.resolve(__dirname, 'templates'))
  templateFinder.templatePatterns.unshift('common.template.html')

  writeFilesProcessor.outputFolder  = 'build/docs/'