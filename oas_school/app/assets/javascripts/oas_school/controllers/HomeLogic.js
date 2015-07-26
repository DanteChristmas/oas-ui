'use strict';

angular.module('oasWeb')
  .controller('HomeLogicCtrl', ['$scope', '$route', '$log', '$location', '$window', '$timeout', '$controller', 'MediaRepoService', 'NewsRepoService', 'SocialRepoService', 'EventRepoService',
  function ($scope, $route, $log, $location, $window, $timeout, $controller, MediaRepoService, NewsRepoService, SocialRepoService, EventRepoService) {

//test
    var _helper = {
      isSet: function(property){
        return typeof property !== 'undefined' && property !== null && property !== '';
      },

      mixWallContent: function (social, media, articles) {
        var maxLength = Math.max(social.length, media.length, articles.length);
        var result = [];
        for(var i = 0; i < maxLength; i++) {
          if(_helper.isSet(social[i])) {
            result.push(social[i]);
          }
          if(_helper.isSet(media[i])) {
            result.push(media[i]);
          }
          if(_helper.isSet(articles[i])) {
            result.push(articles[i]);
          }
        }

        return result;
      },

      getAll: function(options){
        //TODO: get a setting id for KSU
        // options.settingId = '53c8b767ef8693a3f12d1e30';

        MediaRepoService.get(options).then(function(mediaContent){ NewsRepoService.get(options)
          .then(function(newsContent){ SocialRepoService.get(options)
            .then(function(socialContent){
              var content = _helper.mixWallContent(socialContent, mediaContent, newsContent);
              $scope.$broadcast('content-wall-response', content);
            });
          });
        });
      },

      getMedia: function(options){
        MediaRepoService.get(options).then(function (content) {
          $scope.$broadcast('content-wall-response', content);
        });
      },

      getNews: function(options){
        NewsRepoService.get(options).then(function (content) {
          $scope.$broadcast('content-wall-response', content);
        });
      },

      getSocial: function(options){
        //TODO: get settingId for KSU
        // options.settingId = '53c8b767ef8693a3f12d1e30';

        SocialRepoService.get(options).then(function (content) {
          $scope.$broadcast('content-wall-response', content);
        });
      },

      getScheduleRibbon: function (options) {
        options.page = _helper.isSet(options.page) ? options.page : 1;

        EventRepoService.get(options).then(
          function (data) {
            $scope.$broadcast('schedule-ribbon-response', data);
          },
          function (error) {
            $log.info('Error when trying to get schedule ribbon data: ' + error);
          }
        );
      }
    };


    var controller = {
      init: function(){
        controller.redirectHashBang();
        controller.getBaseCtrl();
        controller.setDefaults();
        controller.bindEvents();
      },

      redirectHashBang: function(){
        var hash = $location.path();

        if(_helper.isSet(hash)){
          var fullPath = $location.url();
          var query = fullPath.indexOf('?') > - 1 ? '?' + fullPath.split('?')[1] : '';
          var url = '?_escaped_fragment_=' + hash.replace('/!', '') + query;

          $window.location = url;
        }
      },

      setDefaults: function () {
        $scope.sportFilter = _helper.isSet($scope.sportFilter) ? $scope.sportFilter : "";
      },

      getBaseCtrl: function() {
        angular.extend(this, $controller('HomeCtrl', {$scope: $scope}));
      },

      bindEvents: function(){
        $scope.$on('sportFilterUpdated', function (event, code) {
          $scope.sportFilter = code;
        });

        $scope.$on('contentFilterUpdated', function (event, code) {
          $scope.contentFilter = code;
        });

        $scope.$on('content-wall-request', function (event, options) {
          options.page = _helper.isSet(options.page) ? options.page : 1;

          if(_helper.isSet(options.contentType)){
            if(options.contentType === 'video'){
              options.limit = 12;
              _helper.getMedia(options);
            } else if(options.contentType === 'news'){
              options.limit = 12;
              _helper.getNews(options);
            } else if(options.contentType === 'social'){
              options.limit = 12;
              _helper.getSocial(options);
            }
          } else {
            options.limit = 4;
            _helper.getAll(options);
          }
        });

        $scope.$on('schedule-ribbon-request', function (event, options) {
          _helper.getScheduleRibbon(options);
        });
      }
    };


    controller.init();

  }
]);
