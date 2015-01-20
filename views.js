// Generated by CoffeeScript 1.8.0
(function() {
  var Backbone, GameView, Models, Painter, helpers, v, validator, _,
    __slice = [].slice;

  helpers = require('helpers');

  Backbone = require('backbone4000');

  validator = require('validator2-extras');

  v = validator.v;

  Models = require('./models');

  _ = require('underscore');

  Painter = exports.Painter = Models.ClockListener.extend4000({
    initialize: function(options) {
      this.set(options);
      _.extend(this, options);
      if (!this.gameview) {
        this.gameview = this.get('gameview');
      }
      this.clockParent = this.gameview;
      if (!this.state) {
        this.state = this.get('state');
      }
      if (!this.point) {
        this.point = this.get('point');
      }
      if (this.name === 'Player') {
        console.log("IM A PLAYER, STATE IS", this.state, this);
      }
      if (this.state) {
        this.gameview.pInstances[this.state.id] = this;
        this.on('remove', (function(_this) {
          return function() {
            return delete _this.gameview.pInstances[_this.state.id];
          };
        })(this));
      } else if (this.point) {
        helpers.dictpush(this.gameview.spInstances, String(this.point.coords()), this);
        this.on('remove', (function(_this) {
          return function() {
            return helpers.dictpop(_this.gameview.spInstances, String(_this.point.coords()), _this);
          };
        })(this));
      }
      if (!this.gameview || !this.state) {
        return;
      }
      return this.state.on('del', (function(_this) {
        return function() {
          _this.remove();
          delete _this.gameview.pInstances[_this.state.id];
          return _this.gameview.drawPoint(_this.state.point);
        };
      })(this));
    },
    draw: function(coords, size) {
      return console.log("draw", this.state.point.coords(), this.state.name);
    },
    remove: function() {
      return this.trigger('remove');
    },
    move: function() {
      throw 'not implemented';
    },
    images: function() {
      return [];
    }
  });

  GameView = exports.GameView = exports.View = Backbone.Model.extend4000(Models.Clock, {
    initialize: function() {
      var _start;
      this.game = this.get('game');
      this.painters = {};
      this.pInstances = {};
      this.spInstances = {};
      _start = (function(_this) {
        return function() {
          _this.game.on('set', function(state, point) {
            return _this.drawPoint(point);
          });
          _this.game.on('del', function(state, point) {
            return _this.drawPoint(point);
          });
          _this.game.on('move', function(state, point, from) {
            return _this.drawPoint(point);
          });
          _this.game.each(function(point) {
            return _this.drawPoint(point);
          });
          return _this.tickloop();
        };
      })(this);
      return _.defer(_start);
    },
    definePainter: function() {
      var definitions, name, painter;
      definitions = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (_.first(definitions).constructor === String) {
        definitions.push({
          name: name = definitions.shift()
        });
      } else {
        name = _.last(definitions).name;
      }
      this.painters[name] = painter = Backbone.Model.extend4000.apply(Backbone.Model, definitions);
      this.trigger('definePainter', painter);
      return painter;
    },
    getPainter: function(state) {
      var painter, painterclass;
      if (painter = this.pInstances[state.id]) {
        return painter;
      }
      painterclass = this.painters[state.name];
      if (!painterclass) {
        painterclass = this.painters['unknown'];
      }
      return painterclass.extend4000({
        state: state
      });
    },
    getExistingSpecialPainters: function(point) {
      return this.spInstances[point.id];
    },
    specialPainters: function(painters) {
      return painters;
    },
    drawPoint: function(point) {
      var painters, _applyEliminations, _applyOrder, _instantiate, _sortf, _specialPainters;
      _applyEliminations = function(painters) {
        var dict;
        dict = helpers.makedict(painters, function(painter) {
          return helpers.objorclass(painter, 'name');
        });
        _.map(painters, function(painter) {
          var eliminates;
          if (eliminates = helpers.objorclass(painter, 'eliminates')) {
            return helpers.maybeiterate(eliminates, function(name) {
              painter = dict[name];
              if (typeof painter === 'object') {
                painter.remove();
              }
              return delete dict[name];
            });
          }
        });
        return helpers.makelist(dict);
      };
      _sortf = function(painter) {
        return helpers.objorclass(painter, 'zindex');
      };
      _applyOrder = function(painters) {
        return _.sortBy(painters, _sortf);
      };
      _instantiate = (function(_this) {
        return function(painters) {
          return _.map(painters, function(painter) {
            if (painter.constructor === Function) {
              return new painter({
                gameview: _this,
                point: point
              });
            } else if (painter.constructor === String) {
              return new _this.painters[painter]({
                gameview: _this,
                point: point
              });
            } else {
              return painter;
            }
          });
        };
      })(this);
      _specialPainters = (function(_this) {
        return function(painters, point) {
          var existingKeep, existingPainters, existingRemove, newAdd, newPainters, _ref;
          existingPainters = _this.spInstances[String(point.coords())] || [];
          newPainters = _this.specialPainters(painters, point);
          _ref = helpers.difference(existingPainters, newPainters, (function(x) {
            return x.name;
          }), (function(x) {
            return x.prototype.name;
          })), existingKeep = _ref[0], existingRemove = _ref[1], newAdd = _ref[2];
          _.each(existingRemove, function(painter) {
            return painter.remove();
          });
          return painters.concat(existingKeep, newAdd);
        };
      })(this);
      painters = point.map((function(_this) {
        return function(state) {
          return _this.getPainter(state);
        };
      })(this));
      painters = _specialPainters(painters, point);
      painters = _applyEliminations(painters);
      painters = _applyOrder(painters);
      painters = _instantiate(painters);
      return _.map(painters, (function(_this) {
        return function(painter) {
          return painter.draw(point);
        };
      })(this));
    }
  });

}).call(this);
