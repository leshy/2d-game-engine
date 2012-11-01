(function() {
  var $, comm;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  $ = require('jquery-browserify');
  comm = require('comm/clientside');
  exports.KeyControler = comm.MsgNode.extend4000({
    initialize: function() {
      var actions, state;
      this.pass();
      state = {};
      actions = this.get('actions');
      $(document).keydown(__bind(function(event) {
        var key;
        if (!(key = actions[event.keyCode])) {
          return;
        }
        if (state[key]) {
          return;
        }
        state[key] = true;
        return this.msg({
          ctrl: {
            k: key,
            s: 'd'
          }
        });
      }, this));
      return $(document).keyup(__bind(function(event) {
        var key;
        key = event.keyCode;
        if (!(key = actions[event.keyCode])) {
          return;
        }
        if (!(state[key] != null)) {
          return;
        }
        delete state[key];
        return this.msg({
          ctrl: {
            k: key,
            s: 'u'
          }
        });
      }, this));
    }
  });
}).call(this);
