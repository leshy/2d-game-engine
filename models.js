// Generated by LiveScript 1.4.0
(function(){
  var Backbone, _, helpers, decorators, ClockListener, Clock, StatesFromTags, State, Point, Field, Game, Direction, slice$ = [].slice;
  Backbone = require('backbone4000/extras');
  _ = require('underscore');
  helpers = require('helpers');
  decorators = require('decorators');
  ClockListener = exports.ClockListener = Backbone.Model.extend4000({
    'in': function(n, callback){
      if (!(this.clockParent.tick + n)) {
        throw new Error("clocklistener doesn't have a parent", n, this.name);
      }
      return this.listenToOnceOff(this.clockParent, 'tick_' + (this.clockParent.tick + n), callback);
    },
    onTick: function(n, callback){
      return this.listenToOnceOff(this.clockParent, 'tick_' + n, callback);
    },
    nextTick: function(callback){
      return this['in'](1, callback);
    },
    eachTick: function(callback){
      return this.listenTo(this.clockParent, 'tick', callback);
    },
    getTick: function(){
      return this.clockParent.tick;
    }
  });
  Clock = exports.Clock = ClockListener.extend4000({
    initialize: function(options){
      this.clockParent = this;
      return _.extend(this, {
        tickspeed: 50,
        tick: 0
      }, this.get('options') || {}, options);
    },
    dotick: function(){
      this.tick++;
      this.trigger('tick', this.tick);
      return this.trigger('tick_' + this.tick);
    },
    tickloop: function(){
      this.dotick();
      return this.timeout = setTimeout(this.tickloop.bind(this), this.tickspeed);
    },
    stopTickloop: function(){
      return clearTimeout(this.timeout);
    },
    getTick: function(){
      return this.tick;
    }
  });
  StatesFromTags = function(f){
    var args, this$ = this;
    args = slice$.call(arguments, 1);
    args = _.map(args, function(arg){
      if (arg.constructor === String) {
        return this$.find(arg);
      } else {
        return arg;
      }
    });
    args = _.flatten(args);
    return f.apply(this, args);
  };
  exports.State = State = Backbone.Tagged.extend4000(ClockListener, {
    initialize: function(){
      var this$ = this;
      return this.when('point', function(point){
        this$.point = point;
        this$.on('change:point', function(model, point){
          return this$.point = point;
        });
        this$.clockParent = point.game;
        if (!this$.id) {
          this$.id = this$.get('id');
        }
        if (!this$.id) {
          this$.set({
            id: this$.id = point.game.nextid()
          });
        }
        point.game.byid[this$.id] = this$;
        if (this$.start) {
          return this$.start();
        }
      });
    },
    sound: function(name){
      return this.point.game.sound(this, name);
    },
    place: function(){
      var states;
      states = slice$.call(arguments);
      return this.point.push.apply(this.point, states);
    },
    replace: function(state){
      this.remove();
      return this.point.push(state);
    },
    move: function(where){
      return this.point.move(this, where);
    },
    remove: function(){
      var ref$, key$, ref1$;
      this.point.remove(this);
      return ref1$ = (ref$ = this.point.game.byid)[key$ = this.id], delete ref$[key$], ref1$;
    },
    cancel: function(callback){
      return this.point.game.off(null, callback);
    },
    each: function(callback){
      return callback(this.name);
    },
    msg: function(msg){
      msg == null && (msg = {});
      return this.point.game.trigger('message', this, msg);
    },
    show: function(){
      return this.name;
    },
    render: function(){
      if (this.repr) {
        return this.repr;
      } else {
        return _.first(this.name);
      }
    }
  });
  exports.Point = Point = Backbone.Tagged.extend4000(ClockListener, {
    initialize: function(arg$, game){
      var this$ = this;
      this.x = arg$[0], this.y = arg$[1];
      this.game = game;
      this.clockParent = this.game;
      this.tags = {};
      this.states = new Backbone.Collection();
      if (!this.id) {
        this.id = this.get('id');
      }
      if (!this.id) {
        this.set({
          id: this.id = this.game.getIndex(this)
        });
      }
      this.states.on('add', function(state){
        this$._addstate(state);
        return this$.trigger('set', state);
      });
      this.states.on('remove', function(state){
        this$._delstate(state);
        state.trigger('del');
        return this$.trigger('del', state);
      });
      this.on('move', function(state){
        return this$._addstate(state);
      });
      this.on('moveaway', function(state){
        return this$._delstate(state);
      });
      this.states.on('addTag', function(tag){
        return this$._addTag(tag);
      });
      this.states.on('delTag', function(tag){
        return this$._delTag(tag);
      });
      this.on('del', function(state){
        return this$.game.trigger('del', state, this$);
      });
      this.on('set', function(state){
        return this$.game.trigger('set', state, this$);
      });
      return this.on('move', function(state, from){
        return this$.game.trigger('move', state, this$, from);
      });
    },
    _addstate: function(state){
      var this$ = this;
      this.game.push(this);
      state.set({
        point: this
      });
      return _.map(state.tags, function(v, tag){
        return this$._addTag(tag);
      });
    },
    _delstate: function(state){
      var this$ = this;
      if (!this.states.length) {
        this.game.remove(this);
      }
      return _.map(state.tags, function(v, tag){
        return this$._delTag(tag);
      });
    },
    _addTag: function(tag){
      if (!this.tags[tag]) {
        this.tags[tag] = 1;
        this.trigger('addTag', tag);
        return this.trigger('addTag:' + tag, this);
      } else {
        return this.tags[tag]++;
      }
    },
    _delTag: function(tag){
      this.tags[tag]--;
      if (this.tags[tag] === 0) {
        delete this.tags[tag];
        this.trigger('delTag', tag);
        return this.trigger('delTag:' + tag, this);
      }
    },
    modifier: function(coords){
      if (coords.constructor !== Array) {
        coords = coords.coords();
      }
      return this.game.point([this.x + coords[0], this.y + coords[1]]);
    },
    direction: function(direction){
      return this.modifier(direction);
    },
    find: function(tag){
      return this.states.find(function(state){
        return state.tags[tag];
      });
    },
    filter: function(tag){
      return this.states.filter(function(state){
        return state.tags[tag];
      });
    },
    up: function(){
      return this.modifier([0, -1]);
    },
    down: function(){
      return this.modifier([0, 1]);
    },
    left: function(){
      return this.modifier([-1, 0]);
    },
    right: function(){
      return this.modifier([1, 0]);
    },
    upRight: function(){
      return this.modifier([1, -1]);
    },
    upLeft: function(){
      return this.modifier([-1, -1]);
    },
    downRight: function(){
      return this.modifier([1, 1]);
    },
    downLeft: function(){
      return this.modifier([-1, 1]);
    },
    distance: function(point){
      if (!point) {
        return Infinity;
      }
      return Math.abs(point.x - this.x) + Math.abs(point.y - this.y);
    },
    randomWalk: function(){
      return this.modifier([h.random([-1, 0, 1]), h.random([-1, 0, 1])]);
    },
    outside: function(){
      if (this.x < 0 || this.y < 0) {
        return true;
      }
      if (this.y > this.game.get('height') - 1 || this.x > this.game.get('width') - 1) {
        return true;
      }
      return false;
    },
    coords: function(){
      return [this.x, this.y];
    },
    add: function(state, options){
      if (state.constructor === String) {
        state = new this.game.state[state];
      }
      this.states.add(state, options);
      return this;
    },
    dir: function(){
      return this.states.map(function(state){
        return state.name;
      });
    },
    dirtags: function(){
      return _.keys(this.tags);
    },
    push: function(state, options){
      return this.add(state, options);
    },
    map: function(){
      var args;
      args = slice$.call(arguments);
      return this.states.map.apply(this.states, args);
    },
    each: function(){
      var args;
      args = slice$.call(arguments);
      return this.states.each.apply(this.states, args);
    },
    empty: function(){
      return helpers.isEmpty(this.models);
    },
    tagmap: function(callback){
      return _.map(this.tags, function(n, tag){
        return callback(tag);
      });
    },
    remove: decorators.decorate(StatesFromTags, function(){
      var states, this$ = this;
      states = slice$.call(arguments);
      return _.map(states, function(state){
        return this$.states.remove(state);
      });
    }),
    removeall: function(){
      var results$ = [];
      while (this.states.length) {
        results$.push(this.states.pop());
      }
      return results$;
    },
    move: function(state, newPoint){
      this.states.remove(state, {
        silent: true
      });
      if (newPoint.constructor !== Point) {
        if (newPoint.constructor === Direction) {
          newPoint = this.modifier(newPoint);
        }
        if (newPoint.constructor === Array) {
          newPoint = this.game.point(newPoint);
        }
      }
      newPoint.push(state, {
        silent: true
      });
      newPoint.trigger('move', state, this);
      state.trigger('move', newPoint);
      return this.trigger('moveaway', state, newPoint);
    },
    show: function(){
      return this.states.map(function(state){
        return state.show();
      });
    },
    render: function(){
      var state;
      if (state = this.states.last()) {
        return state.render();
      } else {
        return ".";
      }
    }
  });
  exports.Field = Field = Backbone.Model.extend4000({
    initialize: function(){
      var pointDecorator, this$ = this;
      this.points = {};
      pointDecorator = function(fun){
        var args;
        args = slice$.call(arguments, 1);
        if (args[0].constructor !== Point) {
          args[0] = this$.point(args[0]);
        }
        return fun.apply(this$, args);
      };
      return this.getIndex = decorators.decorate(pointDecorator, this.getIndex);
    },
    point: function(point){
      var ret;
      if (point.constructor === Array) {
        point = new Point(point, this);
      }
      if (ret = this.points[point.id]) {
        return ret;
      } else if (point.game === this) {
        return point;
      } else {
        return new Point(point.coords(), this);
      }
    },
    remove: function(point){
      var ref$, key$, ref1$;
      if (point) {
        return ref1$ = (ref$ = this.points)[key$ = this.getIndex(point)], delete ref$[key$], ref1$;
      }
    },
    push: function(point){
      return this.points[this.getIndex(point)] = point;
    },
    getIndex: function(point){
      return point.x + point.y * this.get('width');
    },
    getIndexRev: function(i){
      var width;
      width = this.get('width');
      return [i % width, Math.floor(i / width)];
    },
    map: function(callback){
      var ret;
      ret = [];
      this.each(function(data){
        return ret.push(callback(data));
      });
      return ret;
    },
    eachFull: function(callback){
      return this.map(callback);
    },
    each: function(callback){
      var this$ = this;
      return _.times(this.get('width') * this.get('height'), function(i){
        return callback(this$.point(this$.getIndexRev(i)));
      });
    },
    show: function(callback){
      return helpers.dictMap(this.points, function(point, index){
        return point.show();
      });
    },
    render: function(){
      var colors, data, flip, colorFlip, this$ = this;
      colors = require('colors');
      data = "  ";
      flip = false;
      colorFlip = function(text){
        var flip;
        if (flip) {
          flip = false;
          return colors.yellow(text);
        } else {
          flip = true;
          return colors.green(text);
        }
      };
      _.times(this.get('width'), function(y){
        return data += colorFlip(helpers.pad(y, 2, '0'));
      });
      data += "  x (width)\n\n";
      _.times(this.get('height'), function(y){
        var row;
        row = [' '];
        _.times(this$.get('width'), function(x){
          return row.push(this$.point([x, y]).render());
        });
        return data += colorFlip(helpers.pad(y, 2, '0')) + " " + row.join(' ') + "\n";
      });
      data += "\ny (height)\n";
      return data;
    }
  });
  exports.Game = Game = Field.extend4000(Clock, {
    initialize: function(){
      this.controls = {};
      this.state = {};
      this.tick = 0;
      this.stateid = 1;
      this.ended = false;
      return this.byid = {};
    },
    sound: function(state, name){
      return this.trigger('sound', state, name);
    },
    nextid: function(state){
      return this.stateid++;
    },
    stop: function(){
      return this.end();
    },
    end: function(data){
      this.stopTickloop();
      if (!this.ended) {
        this.trigger('end', data);
      }
      return this.ended = true;
    },
    start: function(options, callback){
      var this$ = this;
      options == null && (options = {});
      if (this.ended) {
        callback('This game has already ended');
        return;
      }
      _.extend(this, options);
      this.tickloop();
      return this.on('end', function(data){
        return helpers.cbc(callback, data);
      });
    },
    defineState: function(){
      var definitions, lastdef, name, start, initialize;
      definitions = slice$.call(arguments);
      lastdef = {};
      if (_.first(definitions).constructor === String) {
        lastdef.name = name = definitions.shift();
      } else {
        name = _.last(definitions).name;
      }
      lastdef.tags = {};
      lastdef.tags[name] = true;
      start = [];
      initialize = [];
      _.map(definitions, function(definition){
        if (definition.start) {
          start.push(definition.start);
        }
        if (definition.initialize) {
          initialize.push(definition.initialize);
        }
        return helpers.maybeiterate(definition.tags, function(tag, v){
          if (tag) {
            return lastdef.tags[tag] = true;
          }
        });
      });
      lastdef.start = helpers.joinF.apply(this, start);
      definitions.push(lastdef);
      return this.state[name] = State.extend4000.apply(State, definitions);
    }
  });
  exports.Direction = Direction = Direction = (function(){
    Direction.displayName = 'Direction';
    var prototype = Direction.prototype, constructor = Direction;
    function Direction(x, y){
      this.x = x;
      this.y = y;
    }
    prototype.reverse = function(){
      return this.x *= -1 || (this.y *= -1);
    };
    prototype.up = function(){
      return this.set(0, -1);
    };
    prototype.down = function(){
      return this.set(0, 1);
    };
    prototype.left = function(){
      return this.set(-1, 0);
    };
    prototype.right = function(){
      return this.set(1, 0);
    };
    prototype.turnLeft = function(){
      return new Direction(this.y, -this.x);
    };
    prototype.turnRight = function(){
      return new Direction(-this.y, this.x);
    };
    prototype.coords = function(){
      return [this.x, this.y];
    };
    prototype.relevant = function(){
      return function(coords){
        if (!this.x) {
          return coords[1];
        } else {
          return coords[0];
        }
      };
    };
    prototype.set = function(x, y){
      this.x = x;
      this.y = y;
      return this;
    };
    prototype.string = function(){
      if (this.y === -1) {
        return 'up';
      }
      if (this.y === 1) {
        return 'down';
      }
      if (this.x === -1) {
        return 'left';
      }
      if (this.x === 1) {
        return 'right';
      }
      if (!this.x && !this.y) {
        return 'stop';
      }
    };
    prototype.flip = function(){
      return new Direction(-this.x, -this.y);
    };
    prototype.stop = function(){
      if (!this.x && !this.y) {
        return true;
      } else {
        return false;
      }
    };
    prototype.horizontal = function(){
      if (this.x) {
        return true;
      } else {
        return false;
      }
    };
    prototype.vertical = function(){
      if (this.y) {
        return true;
      } else {
        return false;
      }
    };
    prototype.forward = function(){
      if (this.x > 0 || this.y > 0) {
        return true;
      } else {
        return false;
      }
    };
    prototype.backward = function(){
      if (this.x < 0 || this.y < 0) {
        return true;
      } else {
        return false;
      }
    };
    prototype.orientation = function(){
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
  }());
}).call(this);
