(function() {
  var Backbone, Game, GameSever;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Backbone = require('backbone4000');
  Game = require('game/models');
  GameSever = exports.GameSever = Game.Game.extend4000({
    initialize: function() {
      this.setHook = this.setHook.bind(this);
      this.delHook = this.delHook.bind(this);
      return this.moveHook = this.moveHook.bind(this);
    },
    stopNetworkTicker: function() {
      clearTimeout(this.timeout);
      this.log = [];
      this.off('set', this.setHook);
      this.off('del', this.delHook);
      return this.off('move', this.moveHook);
    },
    startNetworkTicker: function() {
      this.log = [];
      this.on('set', this.setHook);
      this.on('del', this.delHook);
      this.on('move', this.moveHook);
      this.each(__bind(function(point) {
        return point.each(__bind(function(state) {
          return this.send({
            a: 'set',
            p: point.coords(),
            s: state.render()
          });
        }, this));
      }, this));
      return this.networkTickLoop();
    },
    setHook: __bind(function(state, point) {
      console.log(onsole.log('set'.magenta, state));
      return this.log.push({
        a: 'set',
        p: point.coords(),
        s: state.render()
      });
    }, this),
    delHook: __bind(function(state, point) {
      console.log('del'.magenta, state);
      return this.log.push({
        a: 'del',
        p: point.coords(),
        s: state.render()
      });
    }, this),
    moveHook: __bind(function(state, pointfrom, pointto) {
      console.log('move'.magenta, state);
      return this.log.push({
        a: 'move',
        pf: pointfrom.coords(),
        p: pointto.coords(),
        s: state.render()
      });
    }, this),
    networkTickLoop: function() {
      this.networkTick();
      return this.networkTickTimeout = setTimeout(this.networkTickLoop.bind(this), 500);
    },
    networkTick: function() {
      var log;
      log = this.log;
      this.log = [];
      console.log(log);
      return this.send({
        game: this.id,
        tick: this.tick,
        changes: log
      });
    }
  });
}).call(this);
