(function() {
  var Backbone, game, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore');
  game = require('./models');
  Backbone = require('backbone4000');
  exports.Point = {
    setUp: function(callback) {
      this.game = new game.Game({
        width: 25,
        height: 25
      });
      this.game.defineState('Wall', {
        tags: {
          'nogo': true
        }
      });
      this.game.defineState('Player1', {
        tags: {
          'p1': true
        }
      });
      this.game.defineState('Bomb', {
        tags: {
          'nogo': true
        }
      });
      this.point = this.game.point([3, 5]);
      return callback();
    },
    push: function(test) {
      var cnt, wall1, wall2;
      this.point.push(wall1 = new this.game.state.Wall());
      this.point.push(wall2 = new this.game.state.Wall());
      cnt = 0;
      this.point.each(__bind(function(state) {
        cnt++;
        return test.equals(state.constructor, wall1.constructor);
      }, this));
      test.equals(cnt, 2);
      return test.done();
    },
    push_events: function(test) {
      var cnt, wall1, wall2;
      cnt = 0;
      this.point.states.on('add', __bind(function(state) {
        cnt++;
        return test.equals(state.constructor, wall1.constructor);
      }, this));
      this.point.push(wall1 = new this.game.state.Wall());
      this.point.push(wall2 = new this.game.state.Wall());
      test.equals(cnt, 2);
      return test.done();
    },
    tag_propagation: function(test) {
      var wall1, wall2, wall3;
      this.point.push(wall1 = new this.game.state.Wall());
      this.point.push(wall2 = new this.game.state.Wall());
      this.point.push(wall3 = new this.game.state.Wall());
      wall1.addtag('testtag');
      test.equals(this.point.has('testtag'), true);
      test.equals(this.point.has('testtag2'), false);
      test.equals(wall1.has('testtag'), true);
      test.equals(wall1.has('testtag2'), false);
      test.equals(wall2.has('testtag'), false, 'tag change leaked through instances');
      return test.done();
    },
    tagdict_forking: function(test) {
      var wall1, wall2, wall3;
      this.point.push(wall1 = new this.game.state.Wall());
      this.point.push(wall2 = new this.game.state.Wall());
      this.point.push(wall3 = new this.game.state.Wall());
      wall1.addtag('testtag');
      test.equals(wall2.tags === wall3.tags, true);
      test.equals(wall1.tags !== wall2.tags, true);
      return test.done();
    },
    render: function(test) {
      var p1, wall1, wall2;
      this.point.push(wall1 = new this.game.state.Wall());
      this.point.push(wall2 = new this.game.state.Wall());
      this.point.push(p1 = new this.game.state.Player1());
      test.deepEqual(this.point.render(), ['Wall', 'Wall', 'Player1']);
      return test.done();
    }
  };
  exports.Field = {
    setUp: function(callback) {
      this.game = new game.Game({
        width: 25,
        height: 25
      });
      this.game.defineState('state1', {});
      this.game.defineState('state2', {});
      this.game.defineState('state3', {});
      return callback();
    },
    setget: function(test) {
      var point1, point2;
      point1 = this.game.point([3, 4]).push('state1');
      point2 = this.game.point([3, 4]).push(new this.game.state.state2());
      test.deepEqual(this.game.point([3, 4]).map(function(state) {
        return state.name;
      }), ['state1', 'state2']);
      return test.done();
    },
    has: function(test) {
      var point1;
      point1 = this.game.point([3, 4]).push('state1');
      test.equals(point1.has('state1'), true, 'state1 is missing!');
      test.equals(point1.has('state2'), false, 'state2 has been found but it should be missing');
      return test.done();
    },
    duplicate: function(test) {
      var point1;
      point1 = this.game.point([3, 4]).push('state1').push('state2');
      test.deepEqual(this.game.point([3, 4]).map(function(state) {
        return state.name;
      }), ['state1', 'state2']);
      point1.push('state1');
      return test.done();
    },
    directionmodifiers: function(test) {
      var point1, point2;
      point1 = this.game.point([3, 4]).push('state1');
      point2 = this.game.point([3, 5]).push('state2');
      test.equals(Boolean(point1.down().has('state2')), true);
      test.equals(Boolean(point2.direction(new game.Direction().up()).has('state1')), true);
      return test.done();
    },
    remove: function(test) {
      var point1;
      point1 = this.game.point([3, 4]);
      test.equals(_.keys(this.game.points).length, 0, 'not empty when started?');
      point1.push('state1');
      test.equals(_.keys(this.game.points).length, 1);
      point1.push('state2');
      point1.push('state2');
      point1.push('state3');
      test.equals(point1.states.length, 4);
      test.equals(_.keys(this.game.points).length, 1);
      point1.remove('state1');
      test.equals(point1.states.length, 3);
      test.equals(_.keys(this.game.points).length, 1);
      point1.removeall();
      test.equals(_.keys(this.game.points).length, 0, 'removeall failed?');
      return test.done();
    },
    render: function(test) {
      var point1, point2;
      point1 = this.game.point([3, 4]).push('state1');
      point1 = this.game.point([3, 4]).push('state3');
      point2 = this.game.point([8, 9]).push(new this.game.state.state2());
      test.deepEqual(this.game.render(), {
        '103': ['state1', 'state3'],
        '233': ['state2']
      });
      return test.done();
    }
  };
  /*
  exports.View = 
      setUp: (callback) ->
          
          @game = new game.Game {width:25,height:25}
          
          @game.defineState 'state1', {}
          @game.defineState 'state2', {}
          @game.defineState 'state3', {}
          @game.defineState 'state4', {}
  
          @painter = Backbone.Model.extend4000 {}
          
          @gameview = new game.View { game: @game }
          @gameview.definePainter 'state1', game.Painter, { x: 'sprite1' }
          @gameview.definePainter 'state2', game.Painter, { x: 'sprite2', eliminates: 'state1' }
          @gameview.definePainter 'state3', game.Painter, { x: 'sprite3' }
          @gameview.definePainter 'unknown', game.Painter, { x: 'unknown' }
          
          callback()
  
      test1: (test) ->        
          @game.point([2,2]).push 'state1'
          @game.point([2,2]).push 'state2'
  
          #console.log @gameview.pinstances
          
          test.done()
  
  */
}).call(this);
