_ = require 'underscore'
game = require './models'
Backbone = require 'backbone4000'

exports.Point =
    setUp: (callback) ->
        @game = new game.Game width: 25, height: 25
        @game.defineState 'Wall', { tags: [ 'nogo' ] }
        @game.defineState 'Player1', { tags: [ 'p1' ] }
        @game.defineState 'Bomb', { tags: [ 'nogo'] } 

        @point = @game.point [3, 5]
        callback()
        
    push: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()

        cnt = 0
        @point.each (state) => cnt++; test.equals(state.constructor,wall1.constructor)
        
        test.equals(cnt,2)
        test.done()

    push_events: (test) ->
        cnt = 0
        @point.states.on 'add', (state) => cnt++; test.equals(state.constructor,wall1.constructor)
        
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        
        test.equals(cnt,2)
        test.done()

    tag_subscription: (test) ->
        wall1 = new @game.state.Wall()
        check = false
        @point.once 'addtag:Wall', -> check = true
        wall1.addtag('bla')
        @point.once 'addtag:bla', ->
            test.equals check, true
            test.done()
        
        @point.push wall1

    tag_basic: (test) ->
        wall1 = new @game.state.Wall()
        test.equals wall1.hasTag('Wall'), true, 'no name tag'
        test.equals wall1.hasTag('nogo'), true, 'no tag'
        test.done()
        
    tag_propagation: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        @point.push wall3 = new @game.state.Wall()

        wall1.addtag('testtag')
        test.equals wall1.hasTag('testtag'), true, 'testtag not found on state'
        test.equals @point.hasTag('testtag'), true, 'no testtag'
        test.equals @point.hasTag('testtag2'), false, 'testtag2 found???'
        test.equals wall1.hasTag('testtag2'), false, 'testtag2 at wall1 found???'
        test.equals wall2.hasTag('testtag'), false, 'tag change leaked through instances'

        test.done()

    tagdict_forking: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        @point.push wall3 = new @game.state.Wall()

        wall1.addtag('testtag')
        
        test.equals wall2.tags is wall3.tags, true
        test.equals wall1.tags isnt wall2.tags, true

        test.done()

    show: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        @point.push p1 = new @game.state.Player1()
        test.deepEqual @point.show(), [ 'Wall', 'Wall', 'Player1' ]

        test.done()



exports.Field =
    setUp: (callback) ->
        @game = new game.Game {width:25,height:25}
        @game.defineState 'state1', {}
        @game.defineState 'state2', {}
        @game.defineState 'state3', {}        
        callback()
        
    setget: (test) ->
        point1 = @game.point([3,4]).push('state1')
        point2 = @game.point([3,4]).push(new @game.state.state2())
        
        test.deepEqual @game.point([3,4]).map((state) -> state.name), [ 'state1', 'state2' ]
        test.done()

    has: (test) ->
        point1 = @game.point([3,4]).push('state1')
        test.equals point1.hasTag('state1'), true, 'state1 is missing!'
        test.equals point1.hasTag('state2'), false, 'state2 has been found but it should be missing'
        test.done()
    
    duplicate: (test) ->
        point1 = @game.point([3,4]).push('state1').push('state2')
        test.deepEqual @game.point([3,4]).map((state) -> state.name), [ 'state1', 'state2' ]
        #test.equals point1.hasTag('state1').constructor, @game.state.state1
        point1.push('state1')
        #test.equals point1.hasTag('state1').constructor, Array
        test.done()
        
    directionmodifiers: (test) ->
        point1 = @game.point([3,4]).push('state1')
        point2 = @game.point([3,5]).push('state2')
        test.equals Boolean(point1.down().hasTag('state2')), true
        test.equals Boolean(point2.direction(new game.Direction().up()).hasTag('state1')), true
        test.done()

    remove: (test) ->
        point1 = @game.point([3,4])
        test.equals _.keys(@game.points).length, 0, 'not empty when started?'
        point1.push 'state1'
        test.equals _.keys(@game.points).length, 1
        point1.push 'state2'
        point1.push 'state2'
        point1.push 'state3'
        test.equals point1.states.length, 4
        test.equals _.keys(@game.points).length, 1
        point1.remove 'state1'
        test.equals point1.states.length, 3
        test.equals _.keys(@game.points).length, 1
        point1.removeall()
        test.equals _.keys(@game.points).length, 0, 'removeall failed?'
        test.done()

    show: (test) ->
        point1 = @game.point([3,4]).push('state1')
        point1 = @game.point([3,4]).push('state3')
        point2 = @game.point([8,9]).push(new @game.state.state2())
        test.deepEqual @game.show(), { '103': [ 'state1', 'state3' ], '233': [ 'state2' ] }
        test.done()

###
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

###