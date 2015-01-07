// Generated by CoffeeScript 1.4.0
(function() {
  var Backbone, GameView, Models, Painter, helpers, v, validator, _,
    __slice = [].slice;

  helpers = require('helpers');

  Backbone = require('backbone4000');

  validator = require('validator2-extras');

  v = validator.v;

  Models = require('./models');

  _ = require('underscore');

  Painter = exports.Painter = Backbone.Model.extend4000({
    initialize: function() {
      var _this = this;
      if (!this.gameview) {
        this.gameview = this.get('gameview');
      }
      if (!this.state) {
        this.state = this.get('state');
      }
      if (!this.gameview || !this.state) {
        return;
      }
      this.gameview.pinstances[this.state.id] = this;
      this.state.on('del', function() {
        return _this.remove();
      });
      return this.state.on('del', function() {
        return delete _this.gameview.pinstances[_this.state.id];
      });
    },
    draw: function(coords, size) {
      return console.log("draw", this.state.point.coords(), this.state.name);
    },
    remove: function() {
      throw 'not implemented';
    },
    move: function() {
      throw 'not implemented';
    },
    images: function() {
      return [];
    }
  });

  GameView = exports.GameView = exports.View = Backbone.Model.extend4000({
    initialize: function() {
      var _start,
        _this = this;
      this.game = this.get('game');
      this.painters = {};
      this.pinstances = {};
      this.spinstances = {};
      _start = function() {
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
        return setInterval(_this.tick.bind(_this), 100);
      };
      return _.defer(_start);
    },
    tick: function() {
      return this.trigger('tick');
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
      if (painter = this.pinstances[state.id]) {
        return painter;
      }
      painterclass = this.painters[state.name];
      if (!painterclass) {
        painterclass = this.painters['unknown'];
      }
      return painterclass.extend4000({
        state: state,
        gameview: this
      });
    },
    specialPainters: function(painters) {
      return painters;
    },
    drawPoint: function(point) {
      var painters, _applyEliminations, _applyOrder, _instantiate, _sortf,
        _this = this;
      _applyEliminations = function(painters) {
        var dict;
        dict = helpers.makedict(painters, function(painter) {
          return helpers.objorclass(painter, 'name');
        });
        _.map(painters, function(painter) {
          var eliminates;
          if (eliminates = helpers.objorclass(painter, 'eliminates')) {
            return helpers.maybeiterate(eliminates, function(name) {
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
      _instantiate = function(painters) {
        return _.map(painters, function(painter) {
          if (painter.constructor === Function) {
            return new painter();
          } else if (painter.constructor === String) {
            return new this.painters[painter]({
              gameview: this
            });
          } else {
            return painter;
          }
        });
      };
      painters = point.map(function(state) {
        return _this.getPainter(state);
      });
      painters = this.specialPainters(painters);
      painters = _applyEliminations(painters);
      painters = _applyOrder(painters);
      painters = _instantiate(painters);
      return _.map(painters, function(painter) {
        return painter.draw(point);
      });
    }
  });

}).call(this);