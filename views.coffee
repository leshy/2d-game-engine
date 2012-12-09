helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
Models = require './models'
_ = require 'underscore'

# painter is a per state view
View = exports.View = Backbone.Model.extend4000
    initialize: ->
        @model = @get 'model'
        @repr = new Models.Field { width: @model.get('width'), height: @model.get('height') }
        
        @model.on 'set', (point,state) => @pointadd point, state
        @model.on 'del', (point,state) => @repr.point(point.coords()).remove(state.name)
        @repr.on  'del', (point,raphaelobject) => raphaelobject.remove()
        @repr.on  'set', (point,painter) => painter.draw()

        if not @painters then @painters = {}

        #@model.each (point) => @drawpoint(point) # draw an initial model

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

        painters = point.map (state) => @painter(state)

        #console.log("painters",painters)
        
        #_.map painters, (painter) -> painter.draw() # should care about eliminations and ordering
        painters

    painter: (state) ->
        #console.log "WILL INIT",state.name,@painters[state.name]
        x = new @painters[state.name] state: state, view: @
        #console.log("PAINER",state.name)
        x
        
    # finds appropriate painter order for a point, and paints them onto canvas
    # point > [ painter instance, painter instance ]
    drawpoint: (point) ->
        reprpoint = @repr.point point.coords()
        _.map @getpainters(point), (painter) => reprpoint.push(painter)

    # painters should be called like the states, that's how the view looks them up
    definePainter: (definitions...) ->
        # just a small sintax sugar first argument is optionally a name for the painter
        if _.first(definitions).constructor == String
            _.last(definitions).name = name = definitions.shift()
        else
            name = _.last(definitions).name # or figure out the name from the last definition

        console.log('definepainter',name)            
        @painters[name] = Backbone.Model.extend4000.apply Backbone.Model, definitions

