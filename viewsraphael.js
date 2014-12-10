(function() {
  var Backbone, DirectionPainter, GameView, ImagePainter, MetaPainter, Painter, Sprite, coordsDecorator, decorate, decorators, helpers, raphael, v, validator, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore');
  helpers = require('helpers');
  Backbone = require('backbone4000');
  validator = require('validator2-extras');
  v = validator.v;
  decorators = require('decorators');
  decorate = decorators.decorate;
  GameView = require('view.coffee');
  raphael = require('raphael-browserify');
  coordsDecorator = function(targetf) {
    return function(coords) {
      if (!coords) {
        coords = this.game.translate(this.state.point.coords);
      }
      return targetf(coords);
    };
  };
  exports.View = GameView.View.extend4000({
    initialize: function() {
      var sizex, sizey;
      this.paper = raphael(this.el, "100%", "100%");
      sizey = Math.floor(this.paper.canvas.clientHeight / this.model.get('height')) - 2;
      sizex = Math.floor(this.paper.canvas.clientWidth / this.model.get('width')) - 2;
      if (sizex > sizey) {
        return this.size = sizey;
      } else {
        return this.size = sizex;
      }
    },
    translate: function(coords) {
      return _.map(coords, __bind(function(a) {
        return a * this.size;
      }, this));
    }
  });
  Painter = Backbone.Model.extend4000({
    initialize: function() {
      return this.when('state', __bind(function(state) {
        this.state = state;
        state.on('move', __bind(function() {
          return this.draw();
        }, this));
        return state.on('remove', __bind(function() {
          return this.remove();
        }, this));
      }, this));
    }
  });
  Sprite = Backbone.Painter.extend4000(true);
  ImagePainter = Painter.extend4000({
    draw: decorate(coordsDecorator)
  }, function(coords) {
    var src;
    return this.rendering = this.game.paper.image(src = 'pic/' + name + '.png', coords[0], coords[1], this.game.size, this.game.size);
  }, {
    move: decorate(coordsDecorator)
  }, function(coords) {
    return this.rendering.attr({
      x: coords[0],
      y: coords[1]
    });
  }, {
    remove: function() {
      return this.rendering.remove();
    }
  });
  MetaPainter = Painter.extend4000({
    initialize: true
  });
  DirectionPainter = MetaPainter.extend4000({
    initialize: function() {
      return this.when('state', __bind(function(state) {
        return state.on('change:direction', __bind(function(direction) {
          return this.directionchange(direction);
        }, this));
      }, this));
    },
    draw: function() {
      return this.rendering = this.directionRepr();
    },
    move: function() {
      return this.rendering.move();
    },
    remove: function() {
      return this.rendering.remove();
    },
    directionRepr: function() {
      return new this[this.state.get('direction').string()]({
        game: this.game,
        state: this.state
      });
    },
    directionchange: function(direction) {
      if (this.rendering) {
        this.remove();
        return this.draw();
      }
    }
  });
}).call(this);
