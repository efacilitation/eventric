path    = require("canonical-path")
Package = require('dgeni').Package
fs      = require 'fs'

testingPackage = new Package('eventric', [
  require 'dgeni-packages/base'
  require 'dgeni-packages/jsdoc'
  require 'dgeni-packages/nunjucks'
])

testingPackage.config (log, readFilesProcessor, templateFinder, renderDocsProcessor, writeFilesProcessor) ->

  log.level = 'debug'

  readFilesProcessor.basePath = path.resolve __dirname, '..'
  readFilesProcessor.sourceFiles = [
    {
      include: 'build/node/src/*.js'
    }
  ]

  templateFinder.templateFolders.unshift path.resolve __dirname
  templateFinder.templatePatterns.unshift 'function.md'

  writeFilesProcessor.$enabled = false


singleFileRenderer =
  name: 'foobar'
  $runAfter: ['writing-files']
  $runBefore: ['files-written']
  $process: (readme) ->
    fakePromise =
      then: (@resolve) ->
      catch: ->
    fs.readFile 'docs/layout.md', (error, layout) ->
      content = readme.reduce ((p, c) -> p + c.renderedContent), ''
      readme = layout.toString().replace '{{content}}', content
      fs.writeFile 'API.md', readme, -> fakePromise.resolve()

    fakePromise

testingPackage.processor singleFileRenderer

module.exports = testingPackage