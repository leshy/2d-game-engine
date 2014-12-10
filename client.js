// Generated by CoffeeScript 1.8.0
(function() {
  var Backbone, Game, GameClient, _;

  Backbone = require('backbone4000');

  Game = require('game/models');

  _ = require('underscore');

  GameClient = exports.GameClient = Backbone.Model.extend4000({
    initialize: function() {
      this.subscribe({
        changes: Array
      }, (function(_this) {
        return function(msg) {
          return _.map(msg.changes, function(change) {
            return _this.applychange(change);
          });
        };
      })(this));
      return this.subscribe({
        end: true
      }, (function(_this) {
        return function(msg) {
          return _.defer(function() {
            return _this.end(msg.end);
          });
        };
      })(this));
    },
    applychange: function(change) {
      var attrs, state;
      if (change.a === 'set') {
        attrs = {
          id: change.id
        };
        if (change.o) {
          attrs = _.extend(attrs, change.o);
        }
        this.point(change.p).push(state = new this.state[change.s](attrs));
      }
      if (change.a === 'del') {
        this.byid[change.id].remove();
      }
      if (change.a === 'move') {
        return this.byid[change.id].move(this.point(change.p));
      }
    },
    nextid: function(state) {
      return "c" + this.stateid++;
    }
  });

}).call(this);
