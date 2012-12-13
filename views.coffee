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
GameView = exports.GameView = Backbone.Model.extend4000 Field,
    initialize: ->
        @model = @get 'model'
        
        @model.on 'set', (point,state) => @pointadd point, state
        @model.on 'del', (point,state) => @point(point).remove(state.name)
        @repr.on  'del', (point,raphaelobject) => raphaelobject.remove()
        @repr.on  'set', (point,painter) => painter.draw()

        @painters = {}

    # painters should be called like the states, that's how the view looks them up
    definePainter: (definitions...) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            definitions.push { name: definitions.shift() }
        else name = _.last(definitions).name # or figure out the name from the last definition
        
        @painters[name] = Backbone.Model.extend4000.apply Backbone.Model, definitions
    
exports.PointView = class PointView extends Models.point
    constructor: (gameview,point) ->
        @gameview = gameview
        @point = point
        
        # redraw a point when world view has changed
        gameview.on 'pan' => @draw()
        gameview.on 'zoom' => @draw()
        
        # redraw a point when states in it have changed
        point.on 'add' => @draw()
        point.on 'del' => @draw()
        point.on 'move' => @draw()

    draw: -> _.map @getpainters, (painter) -> painter.draw()

    # fetches a painter for a state at this point, or instantiates a new one
    painter: (state) ->
        if painter = @has(state.name) then return painter
        return new @gameview.painters[state.name] state: state, view: @
        
    # looks at states at a particular point and finds painters for those states.
    # figures out a correct painter order and applies eliminations..
    # spits out an array of painters
    # point > [ painter, painter, ... ]            
    getpainters: (point) ->
        _applyEliminations = (painters) ->
            _.map painters, (name, painter) ->
                helpers.maybeiterate painter.eliminates (todelete) ->
                    if (todelete) then delete painters[todelete]
                        
        _applyOrder = (painters) ->
            order = _.values painters
            order.sort (painter) -> return painter.zindex

        #painters = {}
        #point.each (state) => painters[state.name] = @painter[state.name]
        _applyEliminations(painters)
        _applyOrder(painters)
        
        point.map (state) => @push(@painter(state))
