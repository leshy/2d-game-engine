Backbone = require 'backbone4000'
comm = require 'comm/clientside'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'


exports.Point = Point = class Point
    constructor: ([@x,@y],@host) -> @states = {}
    
    modifier: (coords) -> @host.point [@x + coords[0], @y + coords[1]]

    direction: (direction) -> @modifier.apply @, direction.coords()
        
    up:    -> @modifier [1,0]
    down:  -> @modifier [-1,0]
    left:  -> @modifier [0,-1]
    right: -> @modifier [0,1]

    coords: -> [@x,@y]

    push: (state) ->
        # commented out for the speed.. makes sure that another point isn't already in its place,
        # and if it is it takes and uses its states dict...
        # 
        #if not anotherpoint = @host.point(@).empty() then @states = anotherpoint.states
        if state.constructor is String then state = new @host.state[state]
        if @empty() then @host.push(@)
        if not @has(state) then @states[state.name] = state else throw "state " + state.name + " already exists at this point"
        state.point = @
        if state.start then state.start()
        @host.trigger 'set', @, state
        @

    empty: -> helpers.isEmpty @states

    each: (callback) -> _.each(@states,callback)

    has: (statename) ->
        if statename.constructor != String then statename = statename.name
        return @states[statename]

    # make sure to somehow delete a point from a field if all the states are removed from it..
    remove: (removestates...) ->
        toremove = helpers.todict removestates
        kickedout = []
        @states = helpers.hashfilter @states, (val,name) -> if toremove[name] then kickedout.push val; return undefined else return val
        _.map kickedout, (state) => @host.trigger 'del',@,state
        # remove yourself from the field if you are empty
        if @empty() then @host.remove(@)
        
    removeall: -> @remove.apply(@,_.keys(@states))

    #getIndex: -> if not @index then @index = @host.getIndex(@) else @index
    collide: (thing) -> thing.get('name')
    
exports.Field = Field = Backbone.Model.extend4000
    initialize: ->
        @points = {}

        pointDecorator = (fun,args...) =>
            if args[0].constructor != Point then args[0] = @point(args[0])
            fun.apply(@,args)

        @getIndex = decorators.decorate(pointDecorator,@getIndex)
        #@point = decorators.decorate(pointDecorator,@point)
        
    # decorator takes care of everything with this one..
    point: (point) ->
        if point.constructor is Array then point = new Point(point,@)
        if ret = @points[@getIndex(point) ] then ret else point

    remove: (point) -> delete @points[@getIndex(point)]

    push: (point) -> @points[@getIndex(point)] = point
            
    getIndex: (point) -> point.x + (point.y * @get ('width'))
        
    getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

    each: (callback) -> _.times @get('width') * @get('height'), (i) => callback @point(@getIndexRev(i))

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
    #initialize : ->
        #@when 'point', (point) => @set game: point.host

    place: (states...) -> @point.push.apply(@point,states)

    replace: (state) -> @remove(); @point.push(state)

    move: (where) -> @point.move(@, where)

    remove: -> @point.remove @name

    in: (n,callback) -> @point.host.onOnce 'tick_' + (@point.host.tick + n), => callback()
    
exports.Game = Game = comm.MsgNode.extend4000 Field,
    initialize: ->
        @controls = {}
        @state = {}
        @tickspeed = 50
        
        @tick = 0

        @subscribe { ctrl: { k: true, s: true }}, (msg,reply) =>
            console.log(msg.json())
            reply.end()

    dotick: () ->
        @tick++
        @trigger('tick_' + @tick)

    tickloop: () ->
        @dotick()
        @timeout = setTimeout @tickloop.bind(@), @tickspeed

    start: ->
        @tickloop()

    stop: -> clearTimeout(@timeout)

    defineState: (name, definition...) ->
        definition.push { name: name }
        @state[name] = State.extend4000.apply(State,definition)


exports.Direction = Direction = class Direction
    constructor: (@x,@y) -> true

    reverse: -> @x *= -1 or @y *= -1
        
    up:    -> @set [1,0]
    down:  -> @set [-1,0]
    left:  -> @set [0,-1]
    right: -> @set [0,1]

    coords: -> [ @x, @y ]

    set: (@x,@y) -> @

    string: -> 
        if @x is 1 then return 'up'
        if @x is -1 then return 'down'
        if @y is -1 then return 'left'
        if @y is 1 then return 'right'
        if not @x and not @y  then return 'stop'


