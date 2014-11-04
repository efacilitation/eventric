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

.config (templateEngine) ->
  linebreak =
    name: 'linebreak'
    process:  (string) ->
      return string.replace /(?:\r\n|\r|\n)/g, '<br>' if string
  templateEngine.filters.push linebreak
  return

.config (log, readFilesProcessor, templateFinder, computePathsProcessor, writeFilesProcessor) ->
  # Basics
  log.level = 'debug'


  # Define
  readFilesProcessor.basePath = path.resolve __dirname, '../..'
  readFilesProcessor.sourceFiles = [
    {
      include: 'build/node/src/**/*.js'
    }
  ]


  # Configurate the template settings (location and patterns)
  templateFinder.templateFolders.unshift(path.resolve(packagePath, 'templates'));
  templateFinder.templatePatterns = [
    '${ doc.template }',
    '${ doc.docType }.template.json'
  ]


  # Define Dist-Folder
  writeFilesProcessor.outputFolder = 'build/docs'
  return

.config (debugDumpProcessor) ->
  debugDumpProcessor.$enabled = true
  return

.config (computePathsProcessor) ->
  computePathsProcessor.pathTemplates.push
    docTypes: ["js"]
    pathTemplate: "js.template"
    outputPathTemplate: "apis/${module}/${codeName}.json"
  return


















