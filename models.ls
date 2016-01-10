Backbone = require 'backbone4000/extras'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'

#
# states, points, and painters subscribe to clocks
#
ClockListener = exports.ClockListener = Backbone.Model.extend4000 do
  in: (n, callback) ->
    if not (@clockParent.tick + n) then throw new Error "clocklistener doesn't have a parent", n, @name
    @listenToOnceOff @clockParent, 'tick_' + (@clockParent.tick + n), callback

  onTick: (n, callback) ->
    @listenToOnceOff @clockParent, 'tick_' + (n), callback

  nextTick: (callback) -> @in 1, callback
  eachTick: (callback) -> @listenTo @clockParent, 'tick', callback
  getTick: -> @clockParent.tick


#
# game engine, and render engine have seperate clocks
#
Clock = exports.Clock = ClockListener.extend4000 do
  initialize: (options) ->
    @clockParent = @
    _.extend @, { tickspeed: 50, tick: 0 }, (@get('options') or {}), options

  dotick: ->
    @tick++
    @trigger 'tick', @tick
    @trigger 'tick_' + @tick

  tickloop: ->
    @dotick()
    @timeout = setTimeout @tickloop.bind(@), @tickspeed

  stopTickloop: ->
    clearTimeout @timeout

  getTick: -> @tick

#
# decorator for point functions to be able to receive tags instead of states, and automatically translate those tags to particular states under that point
#
StatesFromTags = (f,...args) ->
  args = _.map args, (arg) ~> if arg.constructor is String then @find(arg) else arg
  args = _.flatten args
  f.apply @, args

#
# State - represents states with tags within some point
#
# place - create a new state in current point
# replace - replace the state with some other state
# remove - remove the state
# move (direction or point) - move the state to some other point
# in (x, callback) - trigger a callback after x number of ticks
# cancel (?) - cancel a tick callback SOMEHOW
exports.State = State = Backbone.Tagged.extend4000 ClockListener, do
  initialize: ->
    @when 'point', (point) ~>
      @point = point
      @on 'change:point', (model,point) ~> @point = point
      @clockParent = point.game
      if not @id then @id = @get 'id'
      if not @id then @set id: @id = point.game.nextid()

      point.game.byid[@id] = @
      if @start then @start()

  sound: (name) -> @point.game.sound(@,name)

  place: (...states) -> @point.push.apply(@point,states)

  replace: (state) -> @remove(); @point.push(state)

  move: (where) -> @point.move @, where

  remove: ->
    @point.remove @;
    delete @point.game.byid[@id]

  cancel: (callback) -> @point.game.off null, callback

  each: (callback) ->
    callback(@name)

  msg: (msg = {}) ->
    @point.game.trigger 'message', @, msg

  show: -> @name

  render: -> if @repr then @repr else _.first(@name)

# Point - holds states, hosted within a field
#
# direction(direction) - return another point in this direction
#
# right now local tags dictionary is updated automatically
# when tags of states change or states are added
# this could also be done each time that data is requested, or lazily (I could cache)
# is this relevant/should I benchmark?
exports.Point = Point = Backbone.Tagged.extend4000 ClockListener, do
  initialize: ([@x,@y],@game) ->
    @clockParent = @game
    @tags = {}
    @states = new Backbone.Collection()

    if not @id then @id = @get('id')
    if not @id then @set id: @id = @game.getIndex(@)

    @states.on 'add', (state) ~> @_addstate(state); @trigger 'set', state
    @states.on 'remove', (state) ~> @_delstate(state); state.trigger 'del'; @trigger 'del', state

    @on 'move', (state) ~> @_addstate(state)
    @on 'moveaway', (state) ~> @_delstate(state)

    # states can dinamically change their tags
    @states.on 'addTag', (tag) ~> @_addTag tag
    @states.on 'delTag', (tag) ~> @_delTag tag

    @on 'del', (state) ~> @game.trigger 'del', state, @
    @on 'set', (state) ~> @game.trigger 'set', state, @
    @on 'move', (state,from) ~> @game.trigger 'move', state, @, from

  # called by @states collection automatically, or by move, manually
  _addstate: (state) ->
    @game.push(@)
    state.set point: @
    _.map state.tags, (v,tag) ~> @_addTag tag

  # called by @states collection automatically, or by move, manually
  _delstate: (state) ->
    if not @states.length then @game.remove(@)
    _.map state.tags, (v,tag) ~> @_delTag tag

  _addTag: (tag) ->
    if not @tags[tag]
      @tags[tag] = 1
      @trigger 'addTag', tag
      @trigger 'addTag:' + tag, @
    else @tags[tag]++

  _delTag: (tag) ->
    @tags[tag]--
    if @tags[tag] is 0
      delete @tags[tag]
      @trigger 'delTag', tag
      @trigger 'delTag:' + tag, @

  # operations for finding other points
  modifier: (coords) -> # I can take a direction or a point
    if coords.constructor isnt Array then coords = coords.coords();
    #console.log 'applying direction', coords, ' to ', @coords()
    @game.point [@x + coords[0], @y + coords[1]]

  direction: (direction) -> @modifier direction

  find: (tag) -> @states.find (state) -> state.tags[tag]

  filter: (tag) -> @states.filter (state) -> state.tags[tag]

  up:  -> @modifier [0,-1]
  down:  -> @modifier [0,1]
  left:  -> @modifier [-1,0]
  right: -> @modifier [1,0]
  upRight: -> @modifier [1,-1]
  upLeft: -> @modifier [-1,-1]
  downRight: -> @modifier [ 1, 1 ]
  downLeft: -> @modifier [ -1, 1 ]

  distance: (point) ->
    if not point then return Infinity
    return Math.abs(point.x - @x) + Math.abs(point.y - @y)

  randomWalk: -> @modifier [ h.random([-1,0,1]), h.random([-1,0,1]) ]

  outside: ->
    if (@x < 0) or (@y < 0) then return true
    if (@y > @game.get('height') - 1) or (@x > @game.get('width') - 1) then return true
    return false

  # general point operations
  coords: -> [@x, @y]

  add: (state, options) ->
    if state.constructor == String then state = new @game.state[state]
    @states.add(state, options); @

  dir: -> @states.map (state) -> state.name

  dirtags: -> _.keys @tags

  push: (state,options) -> @add(state,options)

  map: (...args) -> @states.map.apply @states, args

  each: (...args) -> @states.each.apply @states, args

  empty: -> helpers.isEmpty @models

  tagmap: (callback) -> _.map @tags, (n,tag) -> callback(tag)

  remove: decorators.decorate( StatesFromTags, (...states) -> _.map states, (state) ~> @states.remove(state) )

  removeall: ->
    while @states.length
      @states.pop()

  move: (state, newPoint) ->
    @states.remove(state, silent: true)

    # newPoint can be a direction or a point
    if newPoint.constructor isnt Point
      if newPoint.constructor is Direction then newPoint = @modifier(newPoint) # if I get a direction, I'll apply it to self
      if newPoint.constructor is Array then newPoint = @game.point(newPoint) # if I get an array I'll supnewPointe that its a point

    newPoint.push(state, silent: true)

    newPoint.trigger 'move', state, @
    state.trigger 'move', newPoint
    @trigger 'moveaway', state, newPoint

  show: -> @states.map (state) -> state.show()
  render: ->
    if state = @states.last() then state.render() else "."


# Field is a collection of discrete points containing objects (@points)
#
# needs width and height attributes
# holds bunch of points together

exports.Field = Field = Backbone.Model.extend4000 do
  initialize: ->
    @points = {}

    pointDecorator = (fun,...args) ~>
      if args[0].constructor != Point then args[0] = @point(args[0])
      fun.apply(@,args)

    @getIndex = decorators.decorate(pointDecorator,@getIndex)

  # will fetch point from the field, or construct a new one if it isn't defined
  point: (point) ->
    if point.constructor is Array then point = new Point(point, @)
    if ret = @points[ point.id ] then ret
    else if point.game is @ then point else new Point(point.coords(), @)

  remove: (point) -> if point then delete @points[@getIndex(point)]

  push: (point) -> @points[@getIndex(point)] = point

  getIndex: (point) -> point.x + (point.y * @get ('width'))

  getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

  map: (callback) ->
    ret = []
    @each (data) -> ret.push(callback(data))
    ret

  eachFull: (callback) -> @map(callback)

  each: (callback) -> _.times @get('width') * @get('height'), (i) ~> callback @point @getIndexRev(i)

  show: (callback) -> helpers.dictMap @points, (point,index) -> point.show()

  # this was used for debugging, will return a string repr of the field,
  # I know, a proper game view with ASCII output might have been better.
  render: ->
    colors = require 'colors'
    data = "  "

    flip = false
    colorFlip = (text) -> if flip then flip = false; return colors.yellow text else flip= true; return colors.green text

    _.times @get('width'), (y) ~>
      data += colorFlip helpers.pad(y,2,'0')

    data += "  x (width)\n\n"

    _.times @get('height'), (y) ~>
      row = [' ']
      _.times @get('width'), (x) ~> row.push @point([x,y]).render()
      data += colorFlip(helpers.pad(y,2,'0')) + " " + row.join(' ') + "\n"

    data += "\ny (height)\n"
    data

#
# brings everything together, acts as a field and a clock, (tickloop controls, field width/height)
# used to define possible states, and this is what main game views hook to.
#
exports.Game = Game = Field.extend4000 Clock, do
  initialize: ->
    @controls = {}
    @state = {}
    @tick = 0
    @stateid = 1
    @ended = false
    @byid = {}

  sound: (state,name) ->
    @trigger 'sound', state, name

  nextid: (state) -> @stateid++

  stop: -> @end()

  end: (data) ->
    @stopTickloop()
    if not @ended then @trigger 'end', data
    @ended = true

  start: (options = {}, callback) ->
    if @ended then callback 'This game has already ended'; return
    _.extend @, options

    @tickloop()

    @on 'end', (data) ~> helpers.cbc callback, data
  
  defineState: (...definitions) ->
    lastdef = {}
    # just a small sintax sugar, first argument is optionally a name for the painter
    if _.first(definitions).constructor == String
      lastdef.name = name = definitions.shift()
    else name = _.last(definitions).name # or figure out the name from the last definition

    # this will chew through the tags of definitions and create a propper tags object
    lastdef.tags = {}

    lastdef.tags[name] = true

    start = []
    initialize = []

    _.map definitions, (definition) ->
      if definition.start then start.push definition.start
      if definition.initialize then initialize.push definition.initialize
      helpers.maybeiterate definition.tags, (tag,v) ->
        if tag then lastdef.tags[tag] = true

    # extend4000 already does this
    #lastdef.initialize = helpers.joinF.apply @, initialize
    lastdef.start = helpers.joinF.apply @, start

    definitions.push(lastdef)

    @state[name] = State.extend4000.apply(State,definitions)

#
# as close as you can get to a 2D vector in a world of bomberman.
#
exports.Direction = Direction = class Direction
  (@x, @y) ->

  reverse: -> @x *= -1 or @y *= -1

  up:  -> @set 0,-1
  down:  -> @set 0,1
  left:  -> @set -1,0
  right: -> @set 1,0

  turnLeft: -> new Direction @y, -@x
  turnRight: -> new Direction -@y, @x

  coords: -> [ @x, @y ]

  relevant: -> (coords) -> if not @x then coords[1] else coords[0]

  set: (@x,@y) -> @

  string: ->
    if @y is -1 then return 'up'
    if @y is 1 then return 'down'
    if @x is -1 then return 'left'
    if @x is 1 then return 'right'
    if not @x and not @y then return 'stop'

  flip: -> return new Direction(-@x, -@y)

  stop: -> if not @x and not @y then true else false

  horizontal: ->  if @x then true else false
  vertical: ->  if @y then true else false

  forward: -> if @x > 0 or @y > 0 then true else false
  backward: -> if @x < 0 or @y < 0 then true else false

  orientation: ->
    if @x is 1 then return 'vertical'
    if @x is -1 then return 'vertical'
    if @y is -1 then return 'horizontal'
    if @y is 1 then return 'horizontal'
    if not @x and not @y then return 'stop'
