helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Game = require './models'


# painter is a per state view
View = exports.View = Backbone.Model.extend4000
    initialize: ->
        @model = @get 'model'
        @repr = new Game.Field { width: @model.get('width'), height: @model.get('height') }

        @model.on 'set', (point,state) => @pointadd point, state
        @model.on 'del', (point,state) => @repr.point(point.coords()).remove(state.name)
        @repr.on  'del', (point,raphaelobject) => raphaelobject.remove()
        @repr.on  'set', (point,painter) => painter.paint point # something like this..

        @model.each (point) => @drawpoint(point) # draw an initial model

    # looks at states at a particular point and finds painters for those states.
    # figures out a correct painter order and applies eliminations..
    # spits out an array of painters
    # point > [ painter, painter, ... ]
    getpainters: (point) ->
        _applyEliminations = (painters) ->
            _.map painters (name, painter) ->
                helpers.maybeiterate painter.eliminates (todelete) ->
                    if (todelete) then delete painters[todelete]
                        
        _applyOrder = (painters) ->
            order = _.values painters
            order.sort (painter) -> return painter.zindex

        #painters = {}
        #point.each (state) => painters[state.name] = @painter[state.name]
        _applyEliminations(painters)
        _applyOrder(painters)
        
        painters = point.map (state) => @painter(state)
        _.map painters, (painter) -> painter.draw() # should care about eliminations and ordering

    painter: (state) ->
        new @painters[state.name] state: state

    # finds appropriate painter order for a point, and paints them onto canvas
    # point > [ painter instance, painter instance ]
    drawpoint: (point) ->
        reprpoint = @repr.point point.coords()
        _.map @getpainters(point), (painter) => reprpoint.push(painter.visual)

    # painters should be called like the states, that's how the view looks them up
    definePainter: (definitions...) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            _.last(definitions).name = name = definitions.shift()
        else
            name = _.last(definitions).name # or figure out the name from the last definition
            
        @painters[name] = Backbone.Model.extend4000.apply Backbone.Model, definitions

