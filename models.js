(function() {
  var Backbone, Direction, Field, Game, Point, State, comm, decorators, helpers, _;
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
      this.states = {};
    }
    Point.prototype.modifier = function(coords) {
      return this.host.point([this.x + coords[0], this.y + coords[1]]);
    };
    Point.prototype.direction = function(direction) {
      return this.modifier.apply(this, direction.coords());
    };
    Point.prototype.up = function() {
      return this.modifier([1, 0]);
    };
    Point.prototype.down = function() {
      return this.modifier([-1, 0]);
    };
    Point.prototype.left = function() {
      return this.modifier([0, -1]);
    };
    Point.prototype.right = function() {
      return this.modifier([0, 1]);
    };
    Point.prototype.coords = function() {
      return [this.x, this.y];
    };
    Point.prototype.push = function(state) {
      if (state.constructor === String) {
        state = new this.host.state[state];
      }
      if (this.empty()) {
        this.host.push(this);
      }
      if (!this.has(state)) {
        this.states[state.name] = state;
      } else {
        throw "state " + state.name + " already exists at this point";
      }
      return this;
    };
    Point.prototype.empty = function() {
      return helpers.isEmpty(this.states);
    };
    Point.prototype.has = function(statename) {
      if (statename.constructor !== String) {
        statename = statename.name;
      }
      return Boolean(this.states[statename]);
    };
    Point.prototype.remove = function() {
      var removestates, toremove;
      removestates = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      toremove = helpers.todict(removestates);
      this.states = helpers.hashfilter(this.states, function(val, name) {
        if (toremove[name]) {} else {
          return val;
        }
      });
      if (this.empty()) {
        return this.host.remove(this);
      }
    };
    Point.prototype.removeall = function() {
      return this.remove(_.keys(this.states));
    };
    Point.prototype.collide = function(thing) {
      return thing.get('name');
    };
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
          args[0] = this.point(args[0]);
        }
        return fun.apply(this, args);
      }, this);
      return this.getIndex = decorators.decorate(pointDecorator, this.getIndex);
    },
    point: function(point) {
      var ret;
      if (point.constructor === Array) {
        point = new Point(point, this);
      }
      if (ret = this.points[this.getIndex(point)]) {
        return ret;
      } else {
        return point;
      }
    },
    remove: function(point) {
      return delete this.points[this.getIndex(point)];
    },
    push: function(point) {
      return this.points[this.getIndex(point)] = point;
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
  exports.State = State = Backbone.Model.extend4000({
    initialize: function() {
      return this.when('point', __bind(function(point) {
        return this.set({
          game: point.host
        });
      }, this));
    },
    place: function() {
      var states;
      states = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.point.push.apply(this.point, states);
    },
    replace: function() {
      var states;
      states = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.point.push.apply;
    },
    move: function(where) {
      return this.point.move(this, where);
    },
    remove: function() {
      return this.point.remove(this);
    },
    "in": function(n, callback) {
      return this.game.triggerOnce('tick_' + this.game.tick + n, __bind(function() {
        return callback();
      }, this));
    },
    remove: function() {
      return this.point.remove();
    }
  });
  exports.Game = Game = comm.MsgNode.extend4000(Field, {
    initialize: function() {
      this.controls = {};
      this.state = {};
      this.tickspeed = 100;
      this.tickn = 0;
      this.subscribe({
        ctrl: {
          k: true,
          s: true
        }
      }, __bind(function(msg, reply) {
        console.log(msg.json());
        return reply.end();
      }, this));
      return this.on('set', function(point, state) {
        return state.set({
          point: point
        });
      });
    },
    dotick: function(n) {
      this.tick++;
      return this.trigger('tick_' + this.tick);
    },
    tickloop: function(n) {
      return this.dotick();
    },
    start: function() {
      return this.tickloop();
    },
    stop: function() {
      return clearTimeout(this.timeout);
    },
    defineState: function() {
      var definition, name;
      name = arguments[0], definition = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      definition.push({
        name: name
      });
      return this.state[name] = State.extend4000.apply(State, definition);
    }
  });
  exports.Direction = Direction = Direction = (function() {
    function Direction(x, y) {
      this.x = x;
      this.y = y;
      true;
    }
    Direction.prototype.reverse = function() {
      return this.x *= -1 || (this.y *= -1);
    };
    Direction.prototype.up = function() {
      return this.set([1, 0]);
    };
    Direction.prototype.down = function() {
      return this.set([-1, 0]);
    };
    Direction.prototype.left = function() {
      return this.set([0, -1]);
    };
    Direction.prototype.right = function() {
      return this.set([0, 1]);
    };
    Direction.prototype.coords = function() {
      return [this.x, this.y];
    };
    Direction.prototype.set = function(x, y) {
      this.x = x;
      this.y = y;
      return this;
    };
    Direction.prototype.string = function() {
      if (this.x === 1) {
        return 'up';
      }
      if (this.x === -1) {
        return 'down';
      }
      if (this.y === -1) {
        return 'left';
      }
      if (this.y === 1) {
        return 'right';
      }
      if (!this.x && !this.y) {
        return 'stop';
      }
    };
    return Direction;
  })();
}).call(this);
