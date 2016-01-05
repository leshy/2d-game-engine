// Generated by CoffeeScript 1.9.3
(function() {
  var Backbone, Game, GameClient, _, h;

  Backbone = require('backbone4000');

  Game = require('game/models');

  h = require('helpers');

  _ = require('underscore');

  GameClient = exports.GameClient = Backbone.Model.extend4000({
    initialize: function() {
      return this.subscribe({
        changes: Array
      }, (function(_this) {
        return function(msg) {
          return _this.applyChanges(msg.changes);
        };
      })(this));
    },
    applyChanges: function(changes) {
      return _.map(changes, (function(_this) {
        return function(change) {
          return _this.applyChange(change);
        };
      })(this));
    },
    applyChange: function(change) {
      var attrs, point, ref, ref1, ref2, state;
      if (change.a === 'set') {
        attrs = {
          id: change.id
        };
        if (change.o) {
          attrs = _.extend(attrs, change.o);
        }
        point = this.point(change.p);
        point.push(state = new this.state[change.s](attrs));
      }
      if (change.a === 'del') {
        if ((ref = this.byid[change.id]) != null) {
          ref.remove();
        }
      }
      if (change.a === 'move') {
        if ((ref1 = this.byid[change.id]) != null) {
          ref1.move(this.point(change.p));
        }
      }
      if (change.a === 'msg') {
        if ((ref2 = this.byid[change.id]) != null) {
          ref2.trigger('message', change.m);
        }
      }
      if (change.a === 'end') {
        return h.wait(50, (function(_this) {
          return function() {
            return _this.end(change.winner);
          };
        })(this));
      }
    },
    nextid: function(state) {
      return "c" + this.stateid++;
    }
  });

}).call(this);
