h = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Models = require './models'
_ = require 'underscore'

# painter subclass should implement Draw(coords) Move(coords) and Remove() methods
Painter = exports.Painter = Models.ClockListener.extend4000 do
    id: ->
      if @state then @state.id # I'm a state painter ( wait what about metapainters and multiple painters per state?)
      else String(@point.coords())# I'm a special painter

    initialize: (options) ->

        # preloader uses this to tell the painter to avoid normal init,
        # (preloader needs to call painter.images() - this is kinda ugly - maybe this should be a class function?
        if options is false then return

        @set options
        _.extend @, options

        @clockParent = @gameview

        # am I a state painter?
        if @state
            @listenToOnce @state, 'del', ~>
                @remove()
                @gameview.drawPoint @state.point

        # am I a special painter?
        else if @point then true

        # wtf am I?
        else throw "I didn't get a point or a state, wtf. my name is #{@name}"

        id = @id()
        h.dictpush(@gameview.pInstances, String(id), @)
        @on 'remove', ~> delete @gameview.pInstances[id]

    draw: (coords,size) -> throw 'not implemented'

    remove: -> @trigger 'remove'

    move: -> throw 'not implemented'

    # painters can dump the images they use..
    # preloader uses this // this should be called 'files' and moved to specific view implementation?
    images: -> []

# very simmilar to game model, maybe should share the superclass with it
GameView = exports.GameView = exports.View = Backbone.Model.extend4000 Models.Clock, do
    stop: -> @end!
    end: ->
      if @game? then @stopListening @game
      @stopTickloop()

    initialize: ->
        @painters = {} # name -> painter class map

        @pInstances = {} # per stateview instance dict

        @when 'game', (game) ~>
            @game = game
            # stupid trick to give priority to subclasses
            # need some kind of better extend4000 function that takes those things into account..
            _.defer ~>
                # game should hook only on create to create new point view
                # and point views should deal with their own state changes and deletions/garbage collectio
                game.on 'set', (state, point) ~> @drawPoint point
                game.on 'del', (state, point) ~> @drawPoint point
                game.on 'move', (state, point, from) ~> @drawPoint point

                game.each (point) ~> @drawPoint point
                game.once 'end', ~> @end()

                @tickloop()

    # painters should be called like the states, that's how the view looks them up
    definePainter: (...definitions) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            definitions.push { name: name = definitions.shift() }
        else name = _.last(definitions).name # or figure out the name from the last definition
        @painters[name] = painter = Backbone.Model.extend4000.apply Backbone.Model, definitions
        @trigger 'definePainter', painter
        painter

    # game keeps the collection of all state view instances (painters) for all the visible states in the game
    # so that different point views can fetch state views and draw them in themselves when states get moved..
    # (I don't want to reinstantiate state views for speed and as they might have internal variables that are relevant)
    getPainter: (state) ->
        if painter = @pInstances[state.id] then return painter
        painterclass = @painters[state.name]
        if not painterclass then painterclass = @painters.Unknown
        return painterclass.extend4000 state: state

    specialPainters: (painters) -> painters

    drawPoint: (point) ->
        _applyEliminations = (painters) ->
            dict = h.makedict painters, (painter) -> h.objorclass painter, 'name'
            _.map painters, (painter) ->
                if eliminates = h.objorclass painter, 'eliminates'
                    h.maybeiterate eliminates, (name) ->
                        painter = dict[name]
                        if typeof(painter) is 'object' then painter.remove()
                        delete dict[name]

            h.makelist dict

        _sortf = (painter) -> h.objorclass painter, 'zindex'

        _applyOrder = (painters) -> _.sortBy painters, _sortf

        _instantiate = (painters) ~> _.map painters, (painter) ~>
            if painter.constructor is Function then new painter gameview: @, point: point
            else if painter.constructor is String then new @painters[painter] gameview: @, point: point
            else painter

        _specialPainters = (painters,point) ~>
            existingPainters = @pInstances[String(point.coords())] or []
            newPainters = @specialPainters(painters, point)
            [ existingKeep, existingRemove, newAdd ] = h.difference existingPainters, newPainters, ((x) -> x.name), ((x) -> x::name)
            _.each existingRemove, (painter) -> painter.remove()
            return painters.concat existingKeep, newAdd

        painters = point.map (state) ~> @getPainter(state)
        painters = _specialPainters(painters, point)
        painters = _applyEliminations(painters)
        painters = _applyOrder(painters)
        painters = _instantiate(painters)

        #remove() removed painter instances?, it should call cancel() on all in() calls for that painter..
        _.map painters, (painter) ~> painter.draw(point)

# advanced painters
MultiPainter = exports.MultiPainter = Painter.extend4000 do
    initialize: ->
        @on 'remove', ~> @reprs.each (repr) -> repr.remove()

    draw: (point) ->
      @render @gameview.translate(point.coords()), @gameview.size

    render: (...args) ->
      @reprs.each (repr) -> repr.render.apply repr, args

# matches different states of a model and renders the appropriate painter
MetaPainter = exports.MetaPainter = Painter.extend4000 do
    initialize: ->
        @on 'remove', ~> @repr.remove()

    reprChange: ->
      @repr.remove()
      delete @repr
      @draw.apply @, @point

    inherit: -> h.dictFromArray [ 'frame' ], (attr) ~> [ attr, @[attr] ]

    draw: (@point) ->
      if not @repr
        cls = @decideRepr()
        @repr = new cls _.extend @inherit(), { gameview: @gameview, state: @state }
        
      console.log @name, "DRAW", @repr.name, @point.coords()
      @repr.draw.call @repr, @point

    decideRepr: -> throw 'override me'

DirectionPainter = exports.DirectionPainter = MetaPainter.extend4000 do
    decideRepr: -> @reprs[(@state.direction or @state.get('direction')).string()]

OrientationPainter = exports.OrientationPainter = MetaPainter.extend4000 do
    decideRepr: -> @reprs[@state.get('direction').orientation()]
