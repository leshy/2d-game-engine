// Generated by CoffeeScript 1.8.0
(function() {
  var Game, colors, helpers, _;

  _ = require('underscore');

  helpers = require('helpers');

  Game = require('game/models');

  colors = require('colors');

  exports.mover = {
    initialize: function(options) {
      _.extend(this, {
        coordinates: [0.5, 0.5],
        speed: 0,
        direction: new Game.Direction(0, 0)
      }, options);
      return console.log('mover init', this.direction, this.speed);
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
    start: function() {
      return this.scheduleMove();
    },
    movementChange: function() {
      if (this.doSubMove) {
        this.unsub();
        this.doSubMove();
        delete this.doSubMove;
      } else {
        this.scheduleMove();
      }
      this.set({
        speed: this.speed,
        direction: this.direction,
        coordinates: this.coordinates
      });
      return this.msg({
        d: this.direction.coords(),
        speed: this.speed,
        c: this.coordinates
      });
    },
    centeredCoord: function(coord) {
      var d, distance;
      distance = function(coord) {
        return Math.abs(coord - 0.5);
      };
      d = distance(coord);
      if (d < distance(coord + this.speed) && d < distance(coord - this.speed)) {
        return true;
      } else {
        return false;
      }
    },
    centered: function(direction) {
      return !_.reject(this.coordinates, (function(_this) {
        return function(coordinate) {
          return _this.centeredCoord(coordinate);
        };
      })(this)).length;
    },
    scheduleMove: function() {
      var eta;
      eta = this.nextCheck(this.direction, this.speed);
      console.log('schedulemove', eta, this.direction.string(), this.direction.coords());
      if (eta === Infinity) {
        return;
      }
      if (this.unsub) {
        this.unsub();
      }
      this.unsub = this["in"](Math.ceil(eta), this.doSubMove = this.makeMover());
      if (this.centered()) {
        return this.trigger('centered');
      }
    },
    makeMover: function(direction, speed) {
      var startTime;
      if (direction == null) {
        direction = this.direction;
      }
      if (speed == null) {
        speed = this.speed;
      }
      startTime = this.point.game.tick;
      return (function(_this) {
        return function() {
          var ticks;
          ticks = _this.point.game.tick - startTime;
          _this.subMove(direction, speed, ticks);
          return _this.scheduleMove();
        };
      })(this);
    },
    nextCheck: function(direction, speed) {
      var check, eta, f;
      check = void 0;
      eta = helpers.squish(direction.coords(), this.coordinates, (function(_this) {
        return function(direction, coordinate) {
          if (direction === 0) {
            return void 0;
          }
          if (direction > 0) {
            if (coordinate < 0.5) {
              return _.bind(_this.centerEta, _this);
            } else {
              return _.bind(_this.boundaryEta, _this);
            }
          }
          if (direction < 0) {
            if (coordinate > 0.5) {
              return _.bind(_this.centerEta, _this);
            } else {
              return _.bind(_this.boundaryEta, _this);
            }
          }
        };
      })(this));
      f = _.find(eta, function(x) {
        return x;
      });
      if (!f) {
        return Infinity;
      } else {
        return f(direction, speed);
      }
    },
    centerEta: function(direction, speed) {
      var eta;
      eta = helpers.squish(direction.coords(), this.coordinates, (function(_this) {
        return function(direction, coordinate) {
          if (direction === 0) {
            return Infinity;
          } else if (direction > 0) {
            return (0.5 - coordinate) / speed;
          } else {
            return (coordinate - 0.5) / speed;
          }
        };
      })(this));
      return _.reduce(eta, (function(min, x) {
        if (x < min) {
          return x;
        } else {
          return min;
        }
      }), Infinity);
    },
    boundaryEta: function(direction, speed) {
      var eta;
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
      return _.reduce(eta, (function(min, x) {
        if (x < min) {
          return x;
        } else {
          return min;
        }
      }), Infinity);
    },
    subMove: function(direction, speed, time) {
      var movePoint;
      if (!time) {
        return;
      }
      console.log(this.point.game.tick + " " + colors.yellow('move'), this.coordinates, colors.green(direction.string()), speed, time);
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
        console.log('moved from', this.point.coords(), 'to', movePoint.coords(), this.coordinates);
        return this.move(movePoint);
      }
    }
  };

}).call(this);
