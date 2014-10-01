var _ = require('lodash');

module.exports = function generatePageData() {
  return {
    $runAfter: ['paths-computed'],
    $runBefore: ['rendering-docs'],
    $process: function(docs) { 

      pageData = []

      for (var i = docs.length - 1; i >= 0; i--) {
        var doc = docs[i];

        _pageDataObject = {
          "name": doc.name,
          "module": doc.module,
          "docType": doc.docType
        }

        pageData.push(_pageDataObject);
      };

      docs.push({
        docType: 'pages-data',
        id: 'pages-data',
        template: 'pages-data.template.js',
        outputPath: '../scripts/pages-data.js',
        pages: pageData
      });
    }
  };
};