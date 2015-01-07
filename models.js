// Generated by CoffeeScript 1.8.0
(function() {
  var Backbone, Direction, Field, Game, Point, State, StatesFromTags, Tagged, decorators, helpers, _,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Backbone = require('backbone4000');

  _ = require('underscore');

  helpers = require('helpers');

  decorators = require('decorators');

  Tagged = Backbone.Model.extend4000({
    has: function() {
      var tags;
      tags = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return !_.find(tags, (function(_this) {
        return function(tag) {
          return !_this.tags[tag];
        };
      })(this));
    },
    hasor: function() {
      var tags;
      tags = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return _.find(_.keys(this.tags), function(tag) {
        return __indexOf.call(tags, tag) >= 0;
      });
    }
  });

  StatesFromTags = function() {
    var args, f;
    f = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    args = _.map(args, (function(_this) {
      return function(arg) {
        if (arg.constructor === String) {
          return _this.find(arg);
        } else {
          return arg;
        }
      };
    })(this));
    args = _.flatten(args);
    return f.apply(this, args);
  };

  exports.State = State = Tagged.extend4000({
    initialize: function() {
      return this.when('point', (function(_this) {
        return function(point) {
          if (!_this.id) {
            _this.id = _this.get('id');
          }
          if (!_this.id) {
            _this.set({
              id: _this.id = point.game.nextid()
            });
          }
          point.game.byid[_this.id] = _this;
          if (_this.start) {
            return _this.start();
          }
        };
      })(this));
    },
    place: function() {
      var states;
      states = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.point.push.apply(this.point, states);
    },
    replace: function(state) {
      this.remove();
      return this.point.push(state);
    },
    move: function(where) {
      return this.point.move(this, where);
    },
    remove: function() {
      this.point.remove(this);
      return delete this.point.game.byid[this.id];
    },
    "in": function(n, callback) {
      return this.point.game.onceOff('tick_' + (this.point.game.tick + n), (function(_this) {
        return function() {
          return callback();
        };
      })(this));
    },
    cancel: function(callback) {
      return this.point.game.off(null, callback);
    },
    each: function(callback) {
      return callback(this.name);
    },
    forktags: function() {
      if (this.constructor.prototype.tags === this.tags) {
        return this.tags = helpers.copy(this.tags);
      }
    },
    deltag: function(tag) {
      this.forktags();
      delete this.tags[tag];
      return this.trigger('deltag', tag);
    },
    addtag: function(tag) {
      this.forktags();
      this.tags[tag] = true;
      return this.trigger('addtag', tag);
    },
    render: function() {
      if (this.repr) {
        return this.repr;
      } else {
        return _.first(this.name);
      }
    }
  });

  exports.Point = Point = Tagged.extend4000({
    initialize: function(_arg, game) {
      this.x = _arg[0], this.y = _arg[1];
      this.game = game;
      this.tags = {};
      this.states = new Backbone.Collection();
      this.states.on('add', (function(_this) {
        return function(state) {
          _this._addstate(state);
          return _this.trigger('set', state);
        };
      })(this));
      this.states.on('remove', (function(_this) {
        return function(state) {
          _this._delstate(state);
          state.trigger('del');
          return _this.trigger('del', state);
        };
      })(this));
      this.on('move', (function(_this) {
        return function(state) {
          return _this._addstate(state);
        };
      })(this));
      this.on('moveaway', (function(_this) {
        return function(state) {
          return _this._delstate(state);
        };
      })(this));
      this.states.on('addtag', (function(_this) {
        return function(tag) {
          return _this._addtag(tag);
        };
      })(this));
      this.states.on('deltag', (function(_this) {
        return function(tag) {
          return _this._deltag(tag);
        };
      })(this));
      this.on('del', (function(_this) {
        return function(state) {
          return _this.game.trigger('del', state, _this);
        };
      })(this));
      this.on('set', (function(_this) {
        return function(state) {
          return _this.game.trigger('set', state, _this);
        };
      })(this));
      return this.on('move', (function(_this) {
        return function(state, from) {
          return _this.game.trigger('move', state, _this, from);
        };
      })(this));
    },
    _addstate: function(state) {
      this.game.push(this);
      state.point = this;
      state.set({
        point: this
      });
      return _.map(state.tags, (function(_this) {
        return function(v, tag) {
          return _this._addtag(tag);
        };
      })(this));
    },
    _delstate: function(state) {
      if (!this.states.length) {
        this.game.remove(this);
      }
      return _.map(state.tags, (function(_this) {
        return function(v, tag) {
          return _this._deltag(tag);
        };
      })(this));
    },
    _addtag: function(tag) {
      if (!this.tags[tag]) {
        return this.tags[tag] = 1;
      } else {
        return this.tags[tag]++;
      }
    },
    _deltag: function(tag) {
      this.tags[tag]--;
      if (this.tags[tag] === 0) {
        return delete this.tags[tag];
      }
    },
    modifier: function(coords) {
      if (coords.constructor !== Array) {
        coords = coords.coords();
      }
      return this.game.point([this.x + coords[0], this.y + coords[1]]);
    },
    direction: function(direction) {
      return this.modifier(direction.coords());
    },
    find: function(tag) {
      return this.states.find(function(state) {
        return state.tags[tag];
      });
    },
    filter: function(tag) {
      return this.states.filter(function(state) {
        return state.tags[tag];
      });
    },
    up: function() {
      return this.modifier([0, -1]);
    },
    down: function() {
      return this.modifier([0, 1]);
    },
    left: function() {
      return this.modifier([-1, 0]);
    },
    right: function() {
      return this.modifier([1, 0]);
    },
    coords: function() {
      return [this.x, this.y];
    },
    add: function(state, options) {
      if (state.constructor === String) {
        state = new this.game.state[state];
      }
      this.states.add(state, options);
      return this;
    },
    dir: function() {
      return this.states.map(function(state) {
        return state.name;
      });
    },
    dirtags: function() {
      return _.keys(this.tags);
    },
    push: function(state, options) {
      return this.add(state, options);
    },
    map: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.states.map.apply(this.states, args);
    },
    each: function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.states.each.apply(this.states, args);
    },
    empty: function() {
      return helpers.isEmpty(this.models);
    },
    tagmap: function(callback) {
      return _.map(this.tags, function(n, tag) {
        return callback(tag);
      });
    },
    remove: decorators.decorate(StatesFromTags, function() {
      var states;
      states = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return _.map(states, (function(_this) {
        return function(state) {
          return _this.states.remove(state);
        };
      })(this));
    }),
    removeall: function() {
      var _results;
      _results = [];
      while (this.states.pop()) {
        _results.push(true);
      }
      return _results;
    },
    move: function(state, where) {
      this.states.remove(state, {
        silent: true
      });
      if (where.constructor !== Point) {
        if (where.constructor === Direction) {
          where = this.modifier(where);
        }
        if (where.constructor === Array) {
          where = this.game.point(where);
        }
      }
      where.push(state, {
        silent: true
      });
      where.trigger('move', state, this);
      return this.trigger('moveaway', state, where);
    },
    render: function() {
      var state;
      if (state = this.states.last()) {
        return state.render();
      } else {
        return ".";
      }
    }
  });

  exports.Field = Field = Backbone.Model.extend4000({
    initialize: function() {
      var pointDecorator;
      this.points = {};
      pointDecorator = (function(_this) {
        return function() {
          var args, fun;
          fun = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          if (args[0].constructor !== Point) {
            args[0] = _this.point(args[0]);
          }
          return fun.apply(_this, args);
        };
      })(this);
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
        if (point.game === this) {
          return point;
        } else {
          return new Point(point.coords(), this);
        }
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
    map: function(callback) {
      var ret;
      ret = [];
      this.each(function(data) {
        return ret.push(callback(data));
      });
      return ret;
    },
    eachFull: function(callback) {
      return this.map(callback);
    },
    each: function(callback) {
      return _.times(this.get('width') * this.get('height'), (function(_this) {
        return function(i) {
          return callback(_this.point(_this.getIndexRev(i)));
        };
      })(this));
    },
    render: function() {
      var data;
      data = "  ";
      _.times(this.get('width'), (function(_this) {
        return function(y) {
          return data += helpers.pad(y, 2, ' ');
        };
      })(this));
      data += " x (width)\n";
      _.times(this.get('height'), (function(_this) {
        return function(y) {
          var row;
          row = [];
          _.times(_this.get('width'), function(x) {
            return row.push(_this.point([x, y]).render());
          });
          return data += helpers.pad(y, 2) + " " + row.join(' ') + "\n";
        };
      })(this));
      data += "y (height)\n";
      return data;
    }
  });

  exports.Game = Game = Field.extend4000({
    initialize: function() {
      this.controls = {};
      this.state = {};
      this.tickspeed = 50;
      this.tick = 0;
      this.stateid = 1;
      this.ended = false;
      return this.byid = {};
    },
    nextid: function(state) {
      return this.stateid++;
    },
    dotick: function() {
      this.tick++;
      return this.trigger('tick_' + this.tick);
    },
    tickloop: function() {
      this.dotick();
      return this.timeout = setTimeout(this.tickloop.bind(this), this.tickspeed);
    },
    end: function(data) {
      if (!this.ended) {
        this.trigger('end', data);
      }
      return this.ended = true;
    },
    start: function(callback) {
      if (this.ended) {
        callback('This game has already ended');
        return;
      }
      this.tickloop();
      return this.on('end', (function(_this) {
        return function(data) {
          _this.stop();
          return helpers.cbc(callback, data);
        };
      })(this));
    },
    stop: function() {
      return clearTimeout(this.timeout);
    },
    defineState: function() {
      var definitions, lastdef, name;
      definitions = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      lastdef = {};
      if (_.first(definitions).constructor === String) {
        lastdef.name = name = definitions.shift();
      } else {
        name = _.last(definitions).name;
      }
      lastdef.tags = {};
      lastdef.tags[name] = true;
      _.map(definitions, function(definition) {
        return helpers.maybeiterate(definition.tags, function(tag, v) {
          if (tag) {
            return lastdef.tags[tag] = true;
          }
        });
      });
      definitions.push(lastdef);
      return this.state[name] = State.extend4000.apply(State, definitions);
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
      return this.set(0, -1);
    };

    Direction.prototype.down = function() {
      return this.set(0, 1);
    };

    Direction.prototype.left = function() {
      return this.set(-1, 0);
    };

    Direction.prototype.right = function() {
      return this.set(1, 0);
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

    Direction.prototype.orientation = function() {
      if (this.x === 1) {
        return 'vertical';
      }
      if (this.x === -1) {
        return 'vertical';
      }
      if (this.y === -1) {
        return 'horizontal';
      }
      if (this.y === 1) {
        return 'horizontal';
      }
      if (!this.x && !this.y) {
        return 'stop';
      }
    };

    return Direction;

  })();

}).call(this);