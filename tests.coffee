_ = require 'underscore'
game = require './index'
exports.field =
    setUp: (callback) ->
        @game = new game.Game {width:25,height:25}
        @game.defineState 'state1', {}
        @game.defineState 'state2', {}
        @game.defineState 'state3', {}        
        callback()
        
    setget: (test) ->
        point1 = @game.point([3,4]).push('state1')
        point2 = @game.point([3,4]).push(new @game.state.state2())
        test.deepEqual _.keys(@game.point([3,4]).states), [ 'state1', 'state2' ]
        test.done()

    has: (test) ->
        point1 = @game.point([3,4]).push('state1')
        test.equals Boolean(point1.has('state1')), true, 'state1 is missing!'
        test.equals Boolean(point1.has('state2')), false, 'state2 has been found but it should be missing'
        test.equals Boolean(point1.has(new @game.state.state1())), true
        test.equals Boolean(point1.has(new @game.state.state2())), false
        test.done()
    
    duplicate: (test) ->
        point1 = @game.point([3,4]).push('state1').push('state2')
        test.deepEqual _.keys(@game.point([3,4]).states), [ 'state1', 'state2' ]
        test.equals point1.has('state1').constructor, @game.state.state1
        point1.push('state1')
        test.equals point1.has('state1').constructor, Array
        test.done()
        
    directionmodifiers: (test) ->
        point1 = @game.point([3,4]).push('state1')
        point2 = @game.point([3,5]).push('state2')
        test.equals Boolean(point1.down().has('state2')), true
        test.equals Boolean(point2.direction(new game.Direction().up()).has('state1')), true
        test.done()

    remove: (test) ->
        point1 = @game.point([3,4])
        test.equals _.keys(@game.points).length, 0
        point1.push 'state1'
        test.equals _.keys(@game.points).length, 1
        point1.push 'state2'
        test.equals _.keys(@game.points).length, 1
        point1.remove 'state1' 
        test.equals _.keys(@game.points).length, 1
        point1.removeall()
        test.equals _.keys(@game.points).length, 0
        test.done()

exports.Point =
    setUp: (callback) ->
        @game = new game.Game width: 25, height: 25
        @game.defineState 'Wall', { tags: { 'nogo': true } }        
        @point = @game.point [0, 0]
        callback()
        
    test1: (test) ->
        @point.push new @game.state.Wall()
        @point.push 'Wall'
        console.log(@point)
        test.done()
    



#exports.sprite =
#    setUp: (callback) ->
#        @sprite = new game.Sprite()
#        callback()
#    accessors: (test) ->
#        @sprite.loop()
#        test.equals @sprite.get('loop'), true
#       test.done()


