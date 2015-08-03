class WebpackConfig

  getDefaultConfiguration: ->
    module:
      loaders: [
        {test: /\.coffee$/i, loader: 'coffee-loader'}
      ]
    resolve:
      extensions: ['', '.js', '.coffee']


module.exports = new WebpackConfig