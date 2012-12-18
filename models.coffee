Backbone = require 'backbone4000'
comm = require 'comm/clientside'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'

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
# tagadd(tags...)
# tagdel(tags...)
# each(callback) - iterate through tags

exports.State = State = Backbone.Model.extend4000
    tags: []
    
    initialize: ->
        @when 'point', (point) =>
            @point = point
            @id = point.game.nextid()
            if @start then @start()
            @tags = helpers.copy @get 'tags'

    place: (states...) -> @point.push.apply(@point,states)
    
    replace: (state) -> @remove(); @point.push(state)
    
    move: (where) -> @point.move(@, where)
    
    remove: -> @point.remove @; @trigger 'remove'
    
    in: (n,callback) -> @point.host.onOnce 'tick_' + (@point.host.tick + n), => callback()
    
    cancel: (callback) -> @point.host.off null, callback
    
    each: (callback) ->
        callback(@name)
        if @
        
    has: (tag) -> true

    # will create a new tags object for this particular state instance.
    forktags: -> @constructor::tags is @tags then @tags = helpers.clone @tags
        
    tagdel: (tag) ->
        @forktags()
        delete @tags[tag]
        @trigger 'tagdel', tag
    
    tagadd: (tag) -> true
        @forktags()
        @tags[tag] = true
        @trigger 'tagadd', tagis


# has (tags...) - check if point has all of those tags
# hasor (tags...) - check if point has any of those tags
# direction(direction) - return another point in this direction
# 

exports.Point = Point = Backbone.Collection.extend4000
    initialize: ([@x,@y],@game) ->        

        @on 'add' (state) =>
            _.map state.tags, (v,tag) => @_tagadd tag

        @on 'remove' (state) =>
            _.map state.tags, (v,tag) => @_tagdel tag

        # states can dinamically change their tags
        @on 'tagadd' (tag) => @_tagadd tag
        @on 'tagdel' (tag) => @_tagdel tag

        @on 'reset' (options) =>
            _.map options.previousModels, (state) => @trigger 'remove', state
            
    _tagadd: (tag) ->
        if not @tags[tag] then @tags[tag] = 1 else @tags[tag] ++        

    _tagdel: (tag) ->
        @tags[tag] --
        if @tags[tag] is 0 then delete @tags[tag]

    # operations for finding other points
    modifier: (coords) -> @game.point [@x + coords[0], @y + coords[1]]
    
    direction: (direction) -> @modifier direction.coords()
    
    up:    -> @modifier [0,-1]
    down:  -> @modifier [0,1]
    left:  -> @modifier [-1,0]
    right: -> @modifier [1,0]

    # general point operations            
    coords: -> [@x,@y]

    push: (state) ->
        state.point = @
        if state.constructor == String then state = new @game.state[state]
        Backbone.Collection.prototype.push.apply @, state
            
    empty: -> helpers.isEmpty @models
    
    tagmap: (callback) _.map @tags, (n,tag) -> callback(tag)
    
    has: (tags...) -> _.find _.keys(@tags), (tag) -> not tag in tags

    hasor: (tags...) -> _.find _.keys(@tags), (tag) -> tag in tags

    move: (state,where) ->
        @remove(state.name)
        where = @modifier(where.coords())
        where.push(state)
        where.trigger 'moveto', state
        @trigger 'movefrom', state
        
    
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
        if ret = @points[@getIndex(point) ] then ret
        else
            if point.game is @ then point else new Point point.coords(), @

    remove: (point) -> delete @points[@getIndex(point)]

    push: (point) -> @points[@getIndex(point)] = point
    
    getIndex: (point) -> point.x + (point.y * @get ('width'))
        
    getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

    each: (callback) -> _.times @get('width') * @get('height'), (i) => callback @point(@getIndexRev(i))

    eachFull: (callback) ->
        _.map @points, (point,index) => callback @getPoint(@getindexRev(index))


    
exports.Game = Game = comm.MsgNode.extend4000 Field,
    initialize: ->
        @controls = {}
        @state = {}
        @tickspeed = 50        
        @tick = 0
        @stateid = 0

        #@subscribe { ctrl: { k: true, s: true }}, (msg,reply) =>
            #console.log(msg.json())
        #    reply.end()

    nextid: () -> @stateid ++

    dotick: () ->
        @tick++
        @trigger('tick_' + @tick)

    tickloop: () ->
        @dotick()
        @timeout = setTimeout @tickloop.bind(@), @tickspeed

    start: -> @tickloop()

    stop: -> clearTimeout(@timeout)

    defineState: (definitions...) ->
        lastdef = {}
        # just a small sintax sugar, first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            lastdef.name = name = definitions.shift() }
        else name = _.last(definitions).name # or figure out the name from the last definition


        # this will chew through the tags of definitions and create a propper tags object
        lastdef.tags = {}
        _.map definitions, (definition) ->
            maybeiterate definition.tags, (tag) ->
                if tag then lastdef.tags[tag] = true

        definitions.push(lastdef)
        
        @state[name] = State.extend4000.apply(State,definitions)

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


