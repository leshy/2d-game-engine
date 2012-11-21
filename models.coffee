Backbone = require 'backbone4000'
comm = require 'comm/clientside'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'

exports.Point = Point = class Point
    constructor: ([@x,@y],@host) -> @states = {}
    
    modifier: (coords) -> @host.point [@x + coords[0], @y + coords[1]]

    direction: (direction) -> @modifier direction.coords()
        
    up:    -> @modifier [0,-1]
    down:  -> @modifier [0,1]
    left:  -> @modifier [-1,0]
    right: -> @modifier [1,0]
    
    coords: -> [@x,@y]

    push: (state,silent) ->
        # commented out for the speed.. makes sure that another point isn't already in its place,
        # and if it is it takes and uses its states dict...
        # 
        #if not anotherpoint = @host.point(@).empty() then @states = anotherpoint.states
        if state.constructor == String then state = new @host.state[state]
        if @empty() then @host.push(@)
            
        if not @has(state) then @states[state.name] = state
        else
            if @states[state.name].constructor != Array then @states[state.name] = [@states[state.name]]
            @states[state.name].push(state)
            
        state.point = @
        if state.start then state.start()
        if not silent then @host.trigger 'set', @, state
        @

    empty: -> helpers.isEmpty @states

    each: (callback) -> _.each(@states,callback)

    # maybe I should have an iterator mixin that builds those functions from each function..
    map: (callback) -> _.map(@states,callback) 
    filter: (callback) -> _.map(@states,callback)

    has: (statenames...) ->
        res = []
        _.map statenames, (statename) =>
            if statename.constructor != String then statename = statename.name
            if state = @states[statename] then res.push(state)

        if res.length is 0 then return undefined else if res.length is 1 then return res[0] else return res

    # make sure to somehow delete a point from a field if all the states are removed from it..
    remove: (state,silent) ->
        kickedout = []
        @states = helpers.hashfilter @states, (val,name) ->
            res = []
            helpers.maybeiterate val, (val) ->
                if name != state and val != state then res.push(val) else kickedout.push(val)
                    
            if not res.length
                return undefined
            else if res.length is 1
                return res[0]
            else
                return res
                
        if not silent then _.map kickedout, (state) => @host.trigger 'del',@,state
        # remove yourself from the field if you are empty
        if @empty() then @host.remove(@)
        kickedout
        
    removeall: -> @remove.apply(@,_.keys(@states))

    move: (state,where) ->
        @remove(state.name,true)
        where = @modifier(where.coords())
        where.push(state,true)

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
    place: (states...) -> @point.push.apply(@point,states)

    replace: (state) -> @remove(); @point.push(state)

    move: (where) -> @point.move(@, where)

    remove: -> @point.remove @

    in: (n,callback) -> @point.host.onOnce 'tick_' + (@point.host.tick + n), => callback()
    
    cancel: (callback) -> @point.host.off null, callback



    
exports.Game = Game = comm.MsgNode.extend4000 Field,
    initialize: ->
        @controls = {}
        @state = {}
        @tickspeed = 50
        
        @tick = 0

        #@subscribe { ctrl: { k: true, s: true }}, (msg,reply) =>
            #console.log(msg.json())
        #    reply.end()

    dotick: () ->
        @tick++
        @trigger('tick_' + @tick)

    tickloop: () ->
        @dotick()
        @timeout = setTimeout @tickloop.bind(@), @tickspeed

    start: -> @tickloop()

    stop: -> clearTimeout(@timeout)

    defineState: (name, definition...) ->
        definition.push { name: name }
        @state[name] = State.extend4000.apply(State,definition)


exports.Direction = Direction = class Direction
    constructor: (@x,@y) -> true

    reverse: -> @x *= -1 or @y *= -1
        
    up:    -> @set 0,-1
    down:  -> @set 0,1
    left:  -> @set -1,0
    right: -> @set 1,0

    coords: -> [ @x, @y ]

    set: (@x,@y) -> @

    string: -> 
        if @x is 1 then return 'up'
        if @x is -1 then return 'down'
        if @y is -1 then return 'left'
        if @y is 1 then return 'right'
        if not @x and not @y  then return 'stop'


