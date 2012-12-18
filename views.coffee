helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Models = require './models'
_ = require 'underscore'

# painter subclass should implement Draw(coords) Move(coords) and Remove() methods
Painter = exports.Painter = Backbone.Model.extend4000
    initialize: ->
        @when 'view', (view) => @view = view
                
        @when 'state', (state) =>
            @state = state
            state.on 'move', => @draw()
            state.on 'remove', => @remove()
            
    draw: (coords,size) -> throw 'not implemented'
    
    remove: -> throw 'not implemented'
    
    move: -> throw 'not implemented'

# very simmilar to game model, maybe should share the superclass with it
GameView = exports.GameView = Backbone.Model.extend4000
    initialize: ->
        @game = @get 'game'
        
        @game.on 'set', (point,state) => @pointadd point, state
        @game.on 'del', (point,state) => @point(point).remove(state.name)
        #@repr.on  'del', (point,raphaelobject) => raphaelobject.remove()
        #@repr.on  'set', (point,painter) => painter.draw()

        @painters = {}

    # painters should be called like the states, that's how the view looks them up
    definePainter: (definitions...) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            definitions.push { name: name = definitions.shift() }
        else name = _.last(definitions).name # or figure out the name from the last definition
        
        @painters[name] = Backbone.Model.extend4000.apply Backbone.Model, definitions

    drawPoint: (point) ->
        view = new PointView(@,point)
        view.draw()


exports.PointView = PointView = Models.Point.extend4000
    initialize: (gameview,point) ->
        @gameview = gameview
        @point = point
        
        # redraw a point when world view has changed
        gameview.on 'pan', => @draw()
        gameview.on 'zoom', => @draw()
        
        # redraw a point when states in it have changed
        point.on 'add', => @draw()
        point.on 'del', => @draw()
        point.on 'move', => @draw()

    specialPainters: -> {} # override me

    # fetches a painter for a state at this point, or instantiates a new one
    # painter: (painter) ->
    #    if localpainter = @has(painter.prototype.name) then return localpainter
    #    return new painter state: state, view: @
        
    # looks at states at a particular point and finds painters for those states.
    # figures out a correct painter order and applies eliminations..
    # spits out an array of painters
    # point > [ painter, painter, ... ]
    draw: (point) ->
        _applyEliminations = (painters) ->
            _.map painters, (name, painter) ->
                helpers.maybeiterate painter.eliminates, (todelete) ->
                    if (todelete) then delete painters[todelete]

        _applyOrder = (painters) ->
            order = _.values painters
            order.sort (painter) -> return painter.zindex        
        
        painters = {}

        # prepare potential painters for each state
        @point.each (state) =>
            console.log(state.get('id'))
            if painter = @has(state.name) then return painters[state.name] = painter
            if painter = @gameview.painters[state.name] then return painters[state.name] = painter

        # remove painters that we won't need (delete representations)
        @each (painter) -> if not painters[painter.name] then @remove(painter)

        # special painters (shadows, and such)
        painters = _.extend painters, @specialPainters()

        # eliminations
        _applyEliminations(painters)

        # propper z indexing
        painters = _applyOrder(painters)


        # instantiate the ones that haven't been instantiated,
        # and draw them in a correct order
        #painters = _.map painters, (painter) ->
        #    if painter.constructor == Function then painter = new painter state: state, view: @
        #    @push(painter) 
        #    painter.draw()


