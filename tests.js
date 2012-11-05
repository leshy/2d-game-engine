(function() {
  var game, _;
  _ = require('underscore');
  game = require('./models');
  exports.field = {
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
      test.deepEqual(_.keys(this.game.point([3, 4]).states), ['state1', 'state2']);
      return test.done();
    },
    has: function(test) {
      var point1;
      point1 = this.game.point([3, 4]).push('state1');
      test.equals(point1.has('state1'), true);
      test.equals(point1.has('state2'), false);
      test.equals(point1.has(new this.game.state.state1()), true);
      test.equals(point1.has(new this.game.state.state2()), false);
      return test.done();
    },
    duplicate: function(test) {
      var point1;
      point1 = this.game.point([3, 4]).push('state1').push('state2');
      test.deepEqual(_.keys(this.game.point([3, 4]).states), ['state1', 'state2']);
      try {
        return point1.push('state1');
      } catch (err) {
        return test.done();
      }
    },
    directionmodifiers: function(test) {
      var point1, point2;
      point1 = this.game.point([3, 4]).push('state1');
      point2 = this.game.point([2, 4]).push('state2');
      test.equals(point1.down().has('state2'), true);
      test.equals(point2.direction(new game.Direction().up()).has('state1'), true);
      return test.done();
    }
  };
}).call(this);
