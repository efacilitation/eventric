var _ = require('lodash');

module.exports = function generateIndexPagesProcessor() {
  return {
    $runAfter: ['paths-computed'],
    $runBefore: ['rendering-docs'],
    $process: function(docs) {

      var pageData = _(docs)
        .map(function(doc) {
          return _.pick(doc, ['name', 'area', 'path', 'id', 'template', 'docType']);
        })
        .indexBy('path')
        .value();
      
      docs.push({
        docType: 'indexPage',
        id: 'index-page',
        template: 'index-page.template.html',
        outputPath: '../_index.html',
        pages: pageData
      });

    }
  };
};