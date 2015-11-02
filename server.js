// Generated by CoffeeScript 1.9.3
(function() {
  var Backbone, Game, GameServer, _, helpers;

  Backbone = require('backbone4000');

  Game = require('game/models').Game;

  _ = require('underscore');

  helpers = require('helpers');

  GameServer = exports.GameServer = Backbone.Model.extend4000({
    initialize: function() {
      this.setHook = this.setHook.bind(this);
      this.delHook = this.delHook.bind(this);
      return this.moveHook = this.moveHook.bind(this);
    },
    start: function() {
      return this.startNetworkTicker();
    },
    stopNetworkTicker: function() {
      clearTimeout(this.timeout);
      delete this.log;
      this.off('set', this.setHook);
      this.off('del', this.delHook);
      this.off('move', this.moveHook);
      this.off('message', this.msgHook);
      this.off('attr', this.attrHook);
      return this.off('end', this.endHook);
    },
    startNetworkTicker: function() {
      this.log = [];
      this.on('set', this.setHook);
      this.on('del', this.delHook);
      this.on('move', this.moveHook);
      this.on('message', this.msgHook);
      this.on('attr', this.attrHook);
      this.on('end', this.endHook);
      this.each((function(_this) {
        return function(point) {
          return point.each(function(state) {
            return _this.setHook(state);
          });
        };
      })(this));
      return this.networkTickLoop();
    },
    snapshot: function() {
      var log;
      log = [];
      this.each((function(_this) {
        return function(point) {
          return point.each(function(state) {
            var entry;
            if (entry = _this.setData(state)) {
              return log.push(entry);
            }
          });
        };
      })(this));
      return log;
    },
    setData: function(state) {
      var entry;
      if (state.nosync || state.noset) {
        return;
      }
      entry = {
        a: 'set',
        p: state.point.coords(),
        id: state.id,
        s: state.name
      };
      if (state.syncattributes) {
        entry.o = helpers.dictMap(state.syncattributes, function(val, key) {
          return state.get(key);
        });
      }
      return entry;
    },
    setHook: function(state) {
      var entry;
      if (entry = this.setData(state)) {
        return this.log.push(entry);
      }
    },
    delHook: function(state) {
      if (state.nosync || state.nodel) {
        return;
      }
      return this.log.push({
        a: 'del',
        id: state.id
      });
    },
    moveHook: function(state, pointto) {
      if (state.nosync || state.nomove) {
        return;
      }
      return this.log.push({
        a: 'move',
        id: state.id,
        p: pointto.coords()
      });
    },
    msgHook: function(state, msg) {
      return this.log.push({
        a: 'msg',
        id: state.id,
        m: msg
      });
    },
    attrHook: function(state, change) {
      return this.log.push({
        a: 'attr',
        id: state.id,
        c: change
      });
    },
    endHook: function(winner) {
      return this.log.push({
        a: 'end',
        winner: winner
      });
    },
    networkTickLoop: function() {
      this.networkTick();
      return this.networkTickTimeout = setTimeout(this.networkTickLoop.bind(this), 50);
    },
    networkTick: function() {
      var log;
      if (this.log.length === 0) {
        return;
      }
      log = this.log;
      this.log = [];
      return this.send({
        tick: this.tick,
        changes: log
      });
    },
    send: function(msg) {
      return this.trigger('msg', msg);
    }
  });

}).call(this);
