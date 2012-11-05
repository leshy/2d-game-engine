_ = require 'underscore'

exports.field =
    setUp: (callback) ->
        game = require './models'
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
        test.equals point1.has('state1'), true
        test.equals point1.has('state2'), false
        test.equals point1.has(new @game.state.state1()), true
        test.equals point1.has(new @game.state.state2()), false
        test.done()
    
    duplicate: (test) ->
        point1 = @game.point([3,4]).push('state1').push('state2')
        test.deepEqual _.keys(@game.point([3,4]).states), [ 'state1', 'state2' ]
        try
            point1.push('state1')
        catch err
            test.done()
        

