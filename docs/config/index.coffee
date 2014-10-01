path    = require("canonical-path")
Package = require('dgeni').Package
fs      = require 'fs'

packagePath = __dirname

module.exports = new Package('eventric', [
  require 'dgeni-packages/base'
  require 'dgeni-packages/jsdoc'
  require 'dgeni-packages/nunjucks'
])

# Require processors
.processor(require('./processors/pages-data'))
.processor(require('./processors/index-page'))


.config (log, readFilesProcessor, templateFinder, computePathsProcessor, writeFilesProcessor) ->
  # Basics
  log.level = 'debug'
  

  # Define 
  readFilesProcessor.basePath = path.resolve __dirname, '../..'
  readFilesProcessor.sourceFiles = [
    {
      include: 'build/node/src/*.js'
    }
  ]
  

  # Configurate the template settings (location and patterns)
  templateFinder.templateFolders.unshift(path.resolve(packagePath, 'templates'));
  templateFinder.templatePatterns = [
    '${ doc.template }',
    '${ doc.docType }.template.js'
    '${ doc.docType }.template.html'
  ]


  # Define Dist-Folder 
  writeFilesProcessor.outputFolder = 'build/docs/views'
  return
