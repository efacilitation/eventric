path = require("canonical-path")
module.exports = (config) ->
  require("dgeni-packages/jsdoc") config
  require("dgeni-packages/nunjucks") config

  config.set "logging.level", "debug"
  config.prepend "rendering.templateFolders", [path.resolve(__dirname, "templates")]
  config.prepend "rendering.templatePatterns", ["common.template.html"]
  config.set "source.projectPath", "."
  config.set "source.files", [
    pattern: "build/node/src/*.js"
    basePath: path.resolve(__dirname, "..")
  ]

  config.set "rendering.outputFolder", "../build/"
  config.set "rendering.contentsFolder", "docs"
  config