helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Models = require './models'
_ = require 'underscore'

# painter subclass should implement Draw(coords) Move(coords) and Remove() methods
Painter = exports.Painter = Backbone.Model.extend4000
    initialize: ->
        if not @gameview then @gameview = @get 'gameview' # wtf.. why.. why?
        if not @state then @state = @get 'state'

        if not @gameview or not @state then return # painter needs to be able to be instantiated without models (preloader needs to be able to call images() on it) .. this init function sucks.. fix it..

        @gameview.pinstances[@state.id] = @
        @state.on 'del', => @remove()
        @state.on 'del', => delete @gameview.pinstances[@state.id]
        
        # 'when' somehow doesn't work.. figure it out..
        # 
        #@when 'gameview', (gameview) => 
        #    @gameview = gameview
        #    @gameview.pinstances[@state.id] = @
        #@when 'state', (state) =>
        #    @state = state
        #    state.on 'del', => @remove()

    draw: (coords,size) -> console.log "draw", @state.point.coords(), @state.name
    
    remove: -> throw 'not implemented'
    
    move: -> throw 'not implemented'

    images: -> [] # painters can dump the images they use.. preloader uses this
    
# very simmilar to game model, maybe should share the superclass with it
GameView = exports.GameView = exports.View = Backbone.Model.extend4000
    initialize: ->
        @game = @get 'game'
        @painters = {} # name -> painter class map
        
        @pinstances = {} # per stateview instance dict
        @spinstances = {} # per point special painter instance dict

        _start = =>
            # game should hook only on create to create new point view
            # and point views should deal with their own state changes and deletions/garbage collection
            @game.on 'set', (state,point) =>
                #console.log 'set',state.render(), point.coords()
                @drawPoint point
            @game.on 'del', (state,point) =>
                #console.log 'del',state.render(), point.coords()
                @drawPoint point
            @game.on 'move', (state,point,from) =>
                #console.log 'move', state.render(), 'to', point.coords()
                @drawPoint point # how come I don't need to redraw point from?

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
        @painters[name] = painter = Backbone.Model.extend4000.apply Backbone.Model, definitions
        @trigger 'definePainter', painter
        painter
    
    # game keeps the collection of all state view instances (painters) for all the visible states in the game
    # so that different point views can fetch state views and draw them in themselves when states get moved..
    # (I don't want to reinstantiate state views for speed and as they might have internal variables that are relevant)
    getPainter: (state) ->
        if painter = @pinstances[state.id] then return painter
        painterclass = @painters[state.name]
        if not painterclass then painterclass = @painters['unknown']
        console.log 'extending painter with ', state.name
        return painterclass.extend4000 state: state, gameview: @
                
    specialPainters: (painters) -> painters
                        
    drawPoint: (point) ->
        _applyEliminations = (painters) ->
            dict = helpers.makedict painters, (painter) -> helpers.objorclass painter, 'name'
            _.map painters, (painter) ->
                if eliminates = helpers.objorclass painter, 'eliminates'
                    helpers.maybeiterate eliminates, (name) -> delete dict[name]
            helpers.makelist dict

        _sortf = (painter) -> helpers.objorclass painter, 'zindex'
            
        _applyOrder = (painters) -> _.sortBy painters, _sortf
        
        _instantiate = (painters) -> _.map painters, (painter) ->
            if painter.constructor is Function then new painter()
            else if painter.constructor is String then new @painters[painter] gameview: @
            else painter
        
        painters = point.map (state) => @getPainter(state)
        
        painters = @specialPainters(painters) # this needs to be redone.. sometime. I'm rerendering specialpainters each time the point gets rerendered..
        painters = _applyEliminations(painters)
        painters = _applyOrder(painters)
        painters = _instantiate(painters)
       
#        console.log JSON.stringify(_.map painters, (painter) -> [ _sortf(painter), helpers.objorclass(painter, 'state').name ])
        
        #remove() removed painter instances?, it should call cancel() on all in() calls for that painter..
        _.map painters, (painter) => painter.draw(point)

