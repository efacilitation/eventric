var _ = require('lodash');

module.exports = function generatePageData() {
  return {
    $runAfter: ['paths-computed'],
    $runBefore: ['rendering-docs'],
    $process: function(docs) {

      var pageData = {}

      for (var i = docs.length - 1; i >= 0; i--) {
        var doc = docs[i];
        if(doc.name && doc.module ) {
          pageData[doc.module] = pageData[doc.module] || [];
          pageData[doc.module].push({
            'name' :  doc.name,
            'module' :  doc.module
          });
        }
      }

      docs.push({
        docType: 'pages-data',
        id: 'pages-data',
        template: 'pages-data.template.js',
        outputPath: 'scripts/pages-data.js',
        pages: pageData
      });
    }
  };
};