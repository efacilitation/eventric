// Meta data used by the AngularJS docs app
angular.module('pagesData', [])
  .value('DOC_PAGES', {{ doc.pages | json }});