Backbone = require 'backbone4000'
comm = require 'comm/clientside'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'



exports.Point = Point = class Point
    constructor: ([@x,@y],@host) -> @states = {}
    
    modifier: (coords) -> @host.point(@x + x, @y + y)    
    direction: (direction) -> @modifier.apply @, direction.coords()
    
    up:    -> @modifier(1,0)
    down:  -> @modifier(-1,0)
    left:  -> @modifier(0,-1)
    right: -> @modifier(0,1)

#    push: decorators.decorate decorators.multiArg, (state) -> if not @has(state) then @states[state.name] = state else throw "state " + state.name + " already exists at this point"

    has: (statename) ->
        if statename.constructor is not String then statename = statename.name
        return Boolean(@states[statename])

    # make sure to somehow delete a point from a field if all the states are removed from it..
    remove: (removestates...) ->
        toremove = helpers.todict(removestates)
        @states = helpers.hashfilter @states (val,name) -> if toremove[name] then return undefined else return val

    removeall: -> @host.delPoint(@)


        
    move: (state,direction) ->

    getIndex: -> if not @index then @index = @host.getIndex(@) else @index
    collide: (thing) -> thing.get('name')    
    
exports.Field = Field = Backbone.Model.extend4000
    initialize: ->
        @points = {}

        pointDecorator = (fun,args...) =>
            if args[0].constructor != Point then args[0] = @getPoint(args[0])
            fun.apply(@,args)

        @getIndex = decorators.decorate(pointDecorator,@getIndex)
        #@point = decorators.decorate(pointDecorator,@point)
        
    # decorator takes care of everything with this one..
    point: (point) ->
        
        
    getIndex: (point) -> point.x + (point.y * @get ('width'))
        
    getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

    stuff: (point) -> @points[point.getIndex()]
    
    each: (callback) -> _.times @get('width') * @get('height'), (i) => callback @getPoint(@getIndexRev(i))
    eachFull: (callback) ->
        _.map @points, (point,index) => callback @getPoint(@getindexRev(index))


# place
# replace
# remove
# move (direction or point)
# collide

# on
# in

exports.State = State = Backbone.Model.extend4000
    initialize : ->
        @when 'point', (point) => @set game: point.host


    place: (states...) -> @point.push.apply(@point,states)

    replace: (states...) -> @point.push.apply

    move: (where) -> @point.move(@, where)

    remove: -> @point.remove(@)
    
                        
    in: (n,callback) -> @game.triggerOnce('tick_' + @game.tick + n, => callback())
    
        
    remove: -> @point.remove()

exports.Game = Game = comm.MsgNode.extend4000 Field,
    initialize: ->
        @controls = {}
        @state = {}
        @tickspeed = 100
        
        @tickn = 0

        @subscribe { ctrl: { k: true, s: true }}, (msg,reply) =>
            console.log(msg.json())
            reply.end()

        @on 'set', (point,state) ->
            state.set point: point

    dotick: (n) ->
        @tick ++
        @trigger('tick_' + @tick)

    tickloop: (n) ->
        @dotick()
        # fix this line
        #@timeout = setTimeout(=> @tickloop(), @tickspeed) 

    start: ->
        @tickloop()

    stop: -> clearTimeout(@timeout)

    defineState: (name, definition...) ->
        definition.push { name: name }
        @state[name] = State.extend4000.apply(State,definition)


exports.Direction = Direction = class Direction
    constructor: (@x,@y) -> true

    reverse: -> @x *= -1 or @y *= -1

    left:  -> @set -1,  0
    right: -> @set  1,  0
    down:  -> @set  0, -1
    up:    -> @set  0,  1

    coords: -> [ @x, @y ]

    set: (@x,@y) ->  true

    string: -> 
        if @x is -1 then return 'left'
        if @x is 1 then return 'right'
        if @y is -1 then return 'down'
        if @y is 1 then return 'up'
        if not @x and not @y  then return 'stop'


