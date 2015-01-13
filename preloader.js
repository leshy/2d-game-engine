// Generated by CoffeeScript 1.3.3
(function() {
  var Backbone, preloadjs, v, validator, views, _;

  _ = require('underscore');

  Backbone = require('backbone4000');

  preloadjs = require('PreloadJS-browserify');

  validator = require('validator2-extras');

  v = validator.v;

  views = require('./views');

  exports.preloaderMixin = validator.ValidatedModel.extend4000({
    validator: {
      autopreload: v().Default(true).Boolean(),
      lazypreload: v().Default(false).Boolean()
    },
    initialize: function() {
      var handleFileLoad,
        _this = this;
      this.preloadQueue = new preloadjs.LoadQueue({
        useXHR: true
      });
      handleFileLoad = function(event) {
        event.result.style.visibility = 'hidden';
        if (event.item.type === preloadjs.LoadQueue.IMAGE) {
          return $(document.body).append(event.result);
        }
      };
      this.preloadQueue.addEventListener("fileload", handleFileLoad);
      this.on('definePainter', function(painterclass) {
        return _this.preloadPainter(painterclass);
      });
      return _.map(this.painters, function(painterclass) {
        return _this.preloadPainter(painterclass);
      });
    },
    preloadPainter: function(painterclass) {
      var images, painter,
        _this = this;
      painter = new painterclass();
      images = painter.images();
      return _.map(images, function(image) {
        return _this.preloadQueue.loadFile(image);
      });
    }
  });

}).call(this);
