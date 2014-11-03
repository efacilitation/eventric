// Meta data used by the AngularJS docs app
require('angularjs');
angular.module('pagesData', [])
  .value('API_OVERVIEW', {{ doc.pages | json }});