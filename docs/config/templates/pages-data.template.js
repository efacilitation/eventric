// Meta data used by the AngularJS docs app
angular.module('pagesData', [])
  .value('API_OVERVIEW', {{ doc.pages | json }});