// Generated by CoffeeScript 1.9.1
(function() {
  var Backbone, _, helpers, preloadjs, v, validator, views;

  _ = require('underscore');

  Backbone = require('backbone4000');

  preloadjs = require('PreloadJS-browserify');

  validator = require('validator2-extras');

  v = validator.v;

  views = require('./views');

  helpers = require('helpers');

  exports.preloaderMixin = validator.ValidatedModel.extend4000({
    validator: {
      autopreload: v().Default(true).Boolean(),
      lazypreload: v().Default(false).Boolean()
    },
    initialize: function() {
      var handleFileLoad;
      this.preloadQueue = new preloadjs.LoadQueue({
        useXHR: true,
        loadNow: false
      });
      handleFileLoad = function(event) {
        event.result.style.display = 'none';
        if (event.item.type === preloadjs.LoadQueue.IMAGE) {
          return $("#preload").append(event.result);
        }
      };
      this.preloadQueue.on("fileload", handleFileLoad);
      _.map(this.painters, (function(_this) {
        return function(painterclass) {
          return _this.preloadPainter(painterclass);
        };
      })(this));
      this.on('definePainter', (function(_this) {
        return function(painterclass) {
          return _this.preloadPainter(painterclass);
        };
      })(this));
      if (this.get('autopreload')) {
        return this.preload();
      }
    },
    preload: function(callback) {
      this.preloadQueue.load();
      return this.preloadQueue.on("complete", function() {
        return helpers.cbc(callback);
      });
    },
    preloadPainter: function(painterclass) {
      var images, painter;
      painter = new painterclass();
      images = painter.images();
      return _.map(images, (function(_this) {
        return function(image) {
          return _this.preloadQueue.loadFile(image);
        };
      })(this));
    }
  });

}).call(this);
