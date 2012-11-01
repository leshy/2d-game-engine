(function() {
  var Backbone, Field, Game, Point, ViewField, comm, decorators, helpers, _;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Backbone = require('backbone4000');
  comm = require('comm/clientside');
  _ = require('underscore');
  helpers = require('helpers');
  decorators = require('decorators');
  exports.Point = Point = Point = (function() {
    function Point(_arg, host) {
      this.x = _arg[0], this.y = _arg[1];
      this.host = host;
      true;
    }
    Point.prototype.modifier = function(coords) {
      return new Point(this.x + x, this.y + y, this.field);
    };
    Point.prototype.up = function() {
      return this.modifier(1, 0);
    };
    Point.prototype.down = function() {
      return this.modifier(-1, 0);
    };
    Point.prototype.left = function() {
      return this.modifier(0, -1);
    };
    Point.prototype.right = function() {
      return this.modifier(0, 1);
    };
    Point.prototype.stuff = function() {
      return this.host.stuff(this);
    };
    Point.prototype.getIndex = function() {
      if (!this.index) {
        return this.index = this.host.getIndex(this);
      } else {
        return this.index;
      }
    };
    Point.prototype.replaceStuff = Point;
    return Point;
  })();
  exports.Field = Field = Backbone.Model.extend4000({
    initialize: function() {
      var pointDecorator;
      this.points = {};
      pointDecorator = __bind(function() {
        var args, fun;
        fun = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (args[0].constructor !== Point) {
          args[0] = this.getPoint(args[0]);
        }
        return fun.apply(this, args);
      }, this);
      this.getIndex = decorators.decorate(pointDecorator, this.getIndex);
      this.stuff = decorators.decorate(pointDecorator, this.stuff);
      this.setPoint = decorators.decorate(pointDecorator, this.setPoint);
      this.delPoint = decorators.decorate(pointDecorator, this.delPoint);
      return this.movePoint = decorators.decorate(pointDecorator, this.movePoint);
    },
    getPoint: function(coords) {
      return new Point(coords, this);
    },
    getIndex: function(point) {
      return point.x + (point.y * this.get('width'));
    },
    getIndexRev: function(i) {
      var width;
      width = this.get('width');
      return [i % width, Math.floor(i / width)];
    },
    stuff: function(point) {
      return this.points[point.getIndex()];
    },
    delPoint: function(point) {
      var index, stuff;
      if (stuff = this.points[index = point.getIndex()]) {
        this.trigger('del', point, stuff);
        return delete this.points[index];
      }
    },
    setPoint: function(point, newstuff) {
      var index, oldstuff;
      index = this.getIndex(point);
      if (oldstuff = this.points[index]) {
        this.delPoint(point);
      }
      if (newstuff) {
        this.points[index] = newstuff;
        this.trigger('set', point, newstuff);
      }
      return point;
    },
    each: function(callback) {
      return _.times(this.get('width') * this.get('height'), __bind(function(i) {
        return callback(this.getPoint(this.getIndexRev(i)));
      }, this));
    },
    eachFull: function(callback) {
      return _.map(this.points, __bind(function(point, index) {
        return callback(this.getPoint(this.getindexRev(index)));
      }, this));
    }
  });
  exports.ViewField = ViewField = Field.extend4000({
    initialize: function() {
      return this.on('replace', __bind(function(point, oldstuff) {
        return oldstuff.remove();
      }, this));
    }
  });
  exports.Game = Game = comm.MsgNode.extend4000(Field, {
    initialize: function() {
      return this.subscribe({
        ctrl: {
          k: true,
          s: true
        }
      }, function(msg, reply) {
        console.log(msg.json());
        return reply.end();
      });
    },
    tick: function() {
      return true;
    }
  });
}).call(this);
