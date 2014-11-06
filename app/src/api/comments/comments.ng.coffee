commentsModule = angular.module("eventric.app.api.comments", [])

.directive "comments", ($window, $location) ->
  restrict: "E"
  scope:
    disqus_shortname: "@disqusShortname"
    disqus_identifier: "@disqusIdentifier"
    disqus_title: "@disqusTitle"
    disqus_url: "@disqusUrl"

  template: "<div id=\"disqus_thread\"></div>"
  link: (scope) ->
    # put the config variables into separate global vars so that the Disqus script can see them
    $window.disqus_shortname = scope.disqus_shortname
    $window.disqus_identifier = scope.disqus_identifier
    $window.disqus_title = scope.disqus_title
    $window.disqus_url = $location.absUrl()

    # get the remote Disqus script and insert it into the DOM
    dsq = document.createElement("script")
    dsq.type = "text/javascript"
    dsq.async = true
    dsq.src = "//" + scope.disqus_shortname + ".disqus.com/embed.js"
    (document.getElementsByTagName("head")[0] or document.getElementsByTagName("body")[0]).appendChild dsq

    if window.DISQUS
      window.DISQUS.reset
        reload: true
        config: ->
          @page.identifier = scope.disqus_identifier
          @page.url = $location.absUrl()
          @page.title = scope.disqus_title
          return


    return


module.exports = commentsModule.name