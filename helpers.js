// Generated by CoffeeScript 1.7.1
(function() {
  var Game, colors, helpers, _;

  _ = require('underscore');

  helpers = require('helpers');

  Game = require('game/models');

  colors = require('colors');

  exports.mover = {
    initialize: function(options) {
      console.log("mover init", options);
      return _.extend(this, {
        coordinates: [0.5, 0.5],
        speed: 0,
        direction: new Game.Direction(0, 0)
      }, options);
    },
    start: function() {
      return this.movementChange();
    },
    display: function() {
      var ret, x, y;
      this.movementChange();
      x = Math.round(this.coordinates[0] * 40);
      y = Math.round(this.coordinates[1] * 20);
      ret = "";
      _.times(20, function(cy) {
        var res;
        res = [];
        _.times(40, function(cx) {
          return res.push(cx === x && cy === y ? colors.green("♙") : colors.grey("∘"));
        });
        return ret += "       " + res.join("") + "\n";
      });
      return ret + "       " + colors.red(this.point.coords()) + " | " + colors.yellow(this.coordinates) + "\n";
    },
    centerEta: function(direction, speed) {
      var eta;
      eta = helpers.squish(direction.coords(), this.coordinates, (function(_this) {
        return function(direction, coordinate) {
          if (direction === 0) {
            return Infinity;
          }
          if (direction > 0) {
            return (0.5 - coordinate) / speed;
          }
          return (coordinate - 0.5) / speed;
        };
      })(this));
      console.log(this.point.game.tick, 'centereta ::', eta);
      return Math.ceil(_.reduce(eta, (function(min, x) {
        if (x < min && x >= 0) {
          return x;
        } else {
          return min;
        }
      }), Infinity));
    },
    boundaryEta: function(direction, speed) {
      var eta, res;
      eta = helpers.squish(direction.coords(), this.coordinates, (function(_this) {
        return function(direction, coordinate) {
          if (direction === 0) {
            return Infinity;
          } else if (direction > 0) {
            return (1 - coordinate) / speed;
          } else {
            return coordinate / speed;
          }
        };
      })(this));
      console.log(this.point.game.tick, 'boundaryeta ::', eta);
      return res = _.reduce(eta, (function(min, x) {
        if (x < min) {
          return x;
        } else {
          return min;
        }
      }), Infinity);
    },
    movementChange: function() {
      if (this.doSubMove) {
        this.doSubMove();
      }
      this.scheduleMove();
      console.log(this.point.game.tick, colors.green('MSG'), this.direction.string(), {
        d: this.direction.coords(),
        speed: this.speed,
        c: this.coordinates
      });
      return this.msg({
        d: this.direction.coords(),
        speed: this.speed,
        c: this.coordinates
      });
    },
    scheduleMove: function() {
      var centerEta, eta;
      this.unsubscribeMoves();
      eta = Math.ceil(this.boundaryEta(this.direction, this.speed));
      if (eta === Infinity) {
        return;
      }
      this.uSubMove = this["in"](eta, this.doSubMove = this.makeSubMover(this.direction, this.speed));
      if ((centerEta = this.centerEta(this.direction, this.speed)) < eta) {
        console.log(this.point.game.tick, this.point.game.tick, 'centereta', centerEta, this.coordinates, this.speed);
        return this.uCenterEvent = this["in"](centerEta, (function(_this) {
          return function() {
            return _this.trigger('center');
          };
        })(this));
      }
    },
    unsubscribeMoves: function() {
      if (this.doSubMove) {
        delete this.doSubMove;
      }
      if (this.uSubMove) {
        this.uSubMove();
        delete this.uSubMove;
      }
      if (this.uCenterEvent) {
        this.uCenterEvent();
        return delete this.uCenterEvent;
      }
    },
    makeSubMover: function(direction, speed) {
      var startTime;
      startTime = this.point.game.tick;
      return (function(_this) {
        return function() {
          var ticks;
          delete _this.doSubMove;
          ticks = _this.point.game.tick - startTime;
          _this.subMove(direction, speed, ticks);
          return _this.scheduleMove();
        };
      })(this);
    },
    subMove: function(direction, speed, time) {
      var movePoint;
      if (!time) {
        return;
      }
      console.log(this.point.game.tick + " " + colors.yellow('move'), this.coordinates, this.point.coords(), colors.green(direction.string()), speed, time);
      this.coordinates = helpers.squish(direction.coords(), this.coordinates, (function(_this) {
        return function(direction, coordinate) {
          return coordinate += direction * speed * time;
        };
      })(this));
      if ((movePoint = this.point.direction(_.map(this.coordinates, function(c) {
        if (c >= 1) {
          return 1;
        } else if (c <= 0) {
          return -1;
        } else {
          return 0;
        }
      }))) !== this.point) {
        this.coordinates = _.map(this.coordinates, function(c) {
          if (c >= 1) {
            return c - 1;
          } else if (c <= 0) {
            return c + 1;
          } else {
            return c;
          }
        });
        console.log(this.point.game.tick, 'moved from', this.point.coords(), 'to', movePoint.coords(), this.coordinates);
        return this.move(movePoint);
      }
    }
  };

}).call(this);
