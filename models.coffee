Backbone = require 'backbone4000'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'

#
# states and points have tags.. here are some tag operations
# 
Tagged = Backbone.Model.extend4000
    has: (tags...) -> not _.find(tags, (tag) => not @tags[tag])    
    hasor: (tags...) -> _.find _.keys(@tags), (tag) -> tag in tags
    
#
# decorator for point functions to be able to receive tags instead of states, and automatically translate those tags to particular states under that point
# 
StatesFromTags = (f,args...) ->
    args = _.map args, (arg) => if arg.constructor is String then @find(arg) else arg
    args = _.flatten args
    f.apply @, args

#
# place - create a new state in current point
# replace - replace the state with some other state
# remove - remove the state
# move (direction or point) - move the state to some other point
# in (x, callback) - trigger a callback after x number of ticks
# cancel (?) - cancel a tick callback SOMEHOW
# 
# tag operations
# 
# has(tags...)
# addtag(tags...)
# deltag(tags...)
# each(callback) - iterate through tags
#
exports.State = State = Tagged.extend4000
    initialize: ->
        @when 'point', (point) =>
            @point = point
            if not @id
                @id = point.game.nextid()
                #console.log("new state",@id, @name)
                if @start then @start()

    place: (states...) -> @point.push.apply(@point,states)
    
    replace: (state) -> @remove(); @point.push(state)
    
    move: (where) -> @point.move(@, where)
    
    remove: -> @point.remove @; @trigger 'del'
    
    in: (n,callback) -> @point.game.onOnce 'tick_' + (@point.game.tick + n), => callback()
    
    cancel: (callback) -> @point.game.off null, callback
    
    each: (callback) ->
        callback(@name)
        
    # will create a new tags object for this particular state instance.
    forktags: -> if @constructor::tags is @tags then @tags = helpers.copy @tags
        
    deltag: (tag) ->
        @forktags()
        delete @tags[tag]
        @trigger 'deltag', tag
    
    addtag: (tag) ->
        @forktags()
        @tags[tag] = true
        @trigger 'addtag', tag

    render: -> @name

#
# has (tags...) - check if point has all of those tags
# hasor (tags...) - check if point has any of those tags
# direction(direction) - return another point in this direction
# 
# right now local tags dictionary is updated automatically
# when tags of states change or states are added
# this could also be done each time that data is requested, or lazily (I could cache)
# is this relevant/should I benchmark?
#
exports.Point = Point = Tagged.extend4000
    initialize: ([@x,@y],@game) ->
        @tags = {}
        @states = new Backbone.Collection()
        
        @states.on 'add', (state) =>
            @game.push(@)
            state.set point: @
            _.map state.tags, (v,tag) => @_addtag tag
            @trigger 'set', state

        @states.on 'remove', (state) =>
            if not @states.length then @game.remove(@)
            _.map state.tags, (v,tag) => @_deltag tag
            @trigger 'del', state

        # states can dinamically change their tags
        @states.on 'addtag', (tag) => @_addtag tag
        @states.on 'deltag', (tag) => @_deltag tag

        @on 'del', (state) => @game.trigger 'del', state, @
        @on 'set', (state) => @game.trigger 'set', state, @
        @on 'movefrom', (state,where) => @game.trigger 'move', state, @, where

    _addtag: (tag) ->
        if not @tags[tag] then @tags[tag] = 1 else @tags[tag]++

    _deltag: (tag) ->
        @tags[tag]--
        if @tags[tag] is 0 then delete @tags[tag]

    # operations for finding other points
    modifier: (coords) -> @game.point [@x + coords[0], @y + coords[1]]
    
    direction: (direction) -> @modifier direction.coords()

    find: (tag) -> @states.find (state) -> state.tags[tag]

    filter: (tag) -> @states.filter (state) -> state.tags[tag]

    up:    -> @modifier [0,-1]
    down:  -> @modifier [0,1]
    left:  -> @modifier [-1,0]
    right: -> @modifier [1,0]

    # general point operations            
    coords: -> [@x,@y]

    add: (state) ->
        state.point = @
        if state.constructor == String then state = new @game.state[state]
        @states.add(state); @

    dir: -> @states.map (state) -> state.name
    
    dirtags: -> _.keys @tags

    push: (state) -> @add(state)

    map: (args...) -> @states.map.apply @states, args

    each: (args...) -> @states.each.apply @states, args
                                    
    empty: -> helpers.isEmpty @models
    
    tagmap: (callback) -> _.map @tags, (n,tag) -> callback(tag)

    remove: decorators.decorate( StatesFromTags, (states...) -> _.map states, (state) => @states.remove(state) )

    removeall: -> true while @states.pop()    
    
    move: (state,where) ->
        @remove(state)
        where = @modifier(where.coords())
        where.push(state)
        where.trigger 'moveto', state, @
        @trigger 'movefrom', state, where

    render: -> @states.map (state) -> state.render()
            
#
# needs width and height attributes
# holds bunch of points together
#
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
        if point.constructor is Array then point = new Point(point, @)
        if ret = @points[ @getIndex(point) ] then ret
        else
            if point.game is @ then point else new Point point.coords(), @

    remove: (point) -> delete @points[@getIndex(point)]

    push: (point) -> @points[@getIndex(point)] = point
    
    getIndex: (point) -> point.x + (point.y * @get ('width'))
        
    getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

    map: (callback) ->
        ret = []
        @each (data) -> ret.push(callback(data))
        ret

    eachFull: (callback) -> @map(callback)

    each: (callback) -> _.times @get('width') * @get('height'), (i) => callback @point(@getIndexRev(i))

    render: (callback) -> helpers.hashmap @points, (point,index) -> point.render()
        

#
# used to define possible states, has tickloop controls, field width/height, and this is what main game views hook to
# 
exports.Game = Game = Field.extend4000
    initialize: ->
        @controls = {}
        @state = {}
        @tickspeed = 50        
        @tick = 0
        @stateid = 0
        @ended = false

    nextid: -> @stateid++

    dotick: ->
        @tick++
        @trigger('tick_' + @tick)

    tickloop: ->
        @dotick()
        @timeout = setTimeout @tickloop.bind(@), @tickspeed

    end: ->
        @trigger 'end'
        @ended = true
    
    start: (callback) ->
        if @ended then callback 'This game has already ended'; return
        #@each (point) => point.each (state) => if state.start then state.start()
        @tickloop()
        @on 'end', =>
            @stop()
            helpers.cbc callback
            
    stop: -> clearTimeout(@timeout)

    defineState: (definitions...) ->
        lastdef = {}
        # just a small sintax sugar, first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            lastdef.name = name = definitions.shift()
        else name = _.last(definitions).name # or figure out the name from the last definition

        # this will chew through the tags of definitions and create a propper tags object
        lastdef.tags = {}

        lastdef.tags[name] = true
        
        _.map definitions, (definition) ->
            helpers.maybeiterate definition.tags, (tag,v) ->
                if tag then lastdef.tags[tag] = true

        definitions.push(lastdef)
        
        @state[name] = State.extend4000.apply(State,definitions)
    
#
# as close as you can get to a 2D vector in a world of bomberman.
# 
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

    orientation: -> 
        if @x is 1 then return 'vertical'
        if @x is -1 then return 'vertical'
        if @y is -1 then return 'horizontal'
        if @y is 1 then return 'horizontal'
        if not @x and not @y  then return 'stop'
