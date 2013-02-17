helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Models = require './models'
_ = require 'underscore'

# painter subclass should implement Draw(coords) Move(coords) and Remove() methods
Painter = exports.Painter = Backbone.Model.extend4000
    initialize: ->
        
        if not @gameview then @gameview = @get 'gameview'
        if not @state then @state = @get 'state'
            
        @gameview.pinstances[@state.id] = @
        @state.on 'del', => @remove()

    draw: (coords,size) -> console.log "draw", @state.point.coords(), @state.name
    
    remove: -> throw 'not implemented'
    
    move: -> throw 'not implemented'

# very simmilar to game model, maybe should share the superclass with it
GameView = exports.GameView = exports.View = Backbone.Model.extend4000
    initialize: ->
        @game = @get 'game'
        @painters = {}
        @pinstances = {} # per stateview instance dict        

        _start = =>
            # game should hook only on create to create new point view
            # and point views should deal with their own state changes and deletions/garbage collection
            @game.on 'set', (state,point) => @drawPoint point
            @game.on 'del', (state,point) => @drawPoint point
            @game.on 'move', (state,point,from) =>
                console.log 'from', from.coords(), 'to', point.coords()
                @drawPoint point

            @game.each (point) => @drawPoint point

            setInterval @tick.bind(@), 100

        # stupid trick for start to be called after initialize function for other subclasses is completed
        # need some kind of better extend4000 function that takes those things into account.. 
        _.defer _start

    tick: ->  @trigger 'tick'
        
    # painters should be called like the states, that's how the view looks them up
    definePainter: (definitions...) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            definitions.push { name: name = definitions.shift() }
        else name = _.last(definitions).name # or figure out the name from the last definition

        @painters[name] = Backbone.Model.extend4000.apply Backbone.Model, definitions

    getPainter: (state) ->
        if painter = @pinstances[state.id] then return painter
        painterclass = @painters[state.name]
        if not painterclass then painterclass = @painters['unknown']
        return painterclass.extend4000 state: state, gameview: @
            
    drawPoint: (point) ->
        view = new PointView(@,point)
        view.draw()
    
exports.PointView = PointView = Models.Point.extend4000
    initialize: (gameview,point) ->
        @gameview = gameview
        @point = point
        # redraw a point when world view has changed
        #gameview.on 'pan', => @draw()
        #gameview.on 'zoom', => @draw()
        
        # redraw a point when states in it have changed
        #point.on 'add', (state) => console.log 'ADD', point.coords(), state.name; @draw()
        #point.on 'del', (state) => console.log 'DEL', point.coords(), state.name; @draw()
        #point.on 'move', (state) => console.log 'MOVE', point.coords(), state.name; @draw()

    specialPainters: -> {} # override me

    # fetches a painter for a state at this point, or instantiates a new one
    # painter: (painter) ->
    #    if localpainter = @has(painter.prototype.name) then return localpainter
    #    return new painter state: state, view: @
        
    # looks at states at a particular point and finds painters for those states.
    # figures out a correct painter order and applies eliminations..
    # spits out an array of painters
    # point > [ painter, painter, ... ]
    #
    draw: (point) ->   
        _applyEliminations = (painters) ->
            dict = helpers.makedict painters, (painter) -> helpers.objorclass painter, 'name'
            _.map painters, (painter) ->
                if eliminates = helpers.objorclass painter, 'eliminates'
                    helpers.maybeiterate eliminates, (name) -> delete dict[name]
            helpers.makelist dict

        _sortf = (painter) -> helpers.objorclass painter, 'zindex'
            
        _applyOrder = (painters) -> _.sortBy painters, _sortf
        
        _instantiate = (painters) -> _.map painters, (painter) -> if painter.constructor is Function then new painter() else painter

        painters = @point.map (state) => @gameview.getPainter(state)
        #painters = @specialPainters(painters) # empty doesn't have to be a specific state..
        painters = _applyEliminations(painters)
        painters = _applyOrder(painters)
        painters = _instantiate(painters)

        #console.log JSON.stringify(_.map painters, (painter) -> [ _sortf(painter), helpers.objorclass(painter, 'state').name ])

        # remove() removed painter instances?, it should call cancel() on all in() calls for that painter..
        _.map painters, (painter) => painter.draw(@point)

        