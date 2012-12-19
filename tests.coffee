_ = require 'underscore'
game = require './index'
Backbone = require 'backbone4000'

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
        
        test.deepEqual @game.point([3,4]).map((state) -> state.name), [ 'state1', 'state2' ]
        test.done()

    has: (test) ->
        point1 = @game.point([3,4]).push('state1')
        test.equals point1.has('state1'), true, 'state1 is missing!'
        test.equals point1.has('state2'), false, 'state2 has been found but it should be missing'
        test.done()
    
    duplicate: (test) ->
        point1 = @game.point([3,4]).push('state1').push('state2')
        test.deepEqual @game.point([3,4]).map((state) -> state.name), [ 'state1', 'state2' ]
        #test.equals point1.has('state1').constructor, @game.state.state1
        point1.push('state1')
        #test.equals point1.has('state1').constructor, Array
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
        wall = @game.defineState 'Wall', { tags: { 'nogo': true } }
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
            
    tag_propagation: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        @point.push wall3 = new @game.state.Wall()

        wall1.addtag('testtag')

        test.equals @point.has('testtag'), true
        test.equals @point.has('testtag2'), false
        test.equals wall1.has('testtag'), true
        test.equals wall1.has('testtag2'), false
        test.equals wall2.has('testtag'), false, 'tag change leaked through instances'

        test.done()

    tagdict_forking: (test) ->
        @point.push wall1 = new @game.state.Wall()
        @point.push wall2 = new @game.state.Wall()
        @point.push wall3 = new @game.state.Wall()

        wall1.addtag('testtag')
        
        test.equals wall2.tags is wall3.tags, true
        test.equals wall1.tags isnt wall2.tags, true

        test.done()



#exports.sprite =
#    setUp: (callback) ->
#        @sprite = new game.Sprite()
#        callback()
#    accessors: (test) ->
#        @sprite.loop()
#        test.equals @sprite.get('loop'), true
#       test.done()


