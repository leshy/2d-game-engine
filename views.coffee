helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v

Game = require 'models.coffee'

Sprite = exports.Sprite = Backbone.Model.extend4000(
    validator.MakeAccessors
        once: v().Default(true).Boolean()
        loop: v().Default(true).Boolean()
        frames: v().Default(0).Number()
        speed: v().Number()
        path: v().String()
    defaults:
        loop: true
        frames: 0
        speed: 1
    initialize: -> true
    bla: -> true
)


PointView = Backbone.Model.extend4000
    initialize: -> true
        

SpriteView = PointView.extend4000()

DirectionSpriteView = PointView.extend4000
    initialize: -> true
        
        

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

        painters = {}
        point.each (state) => painters[state.name] = @painter[state.name]
        
        _applyEliminations(painters)
        _applyOrder(painters)

    # finds appropriate painter order for a point, and paints them onto canvas
    # point > [ painter instance, painter instance ]
    drawpoint: (point) ->
        reprpoint = @repr.point point.coords()
        _.map @getpainters(point), (painter) => reprpoint.push(painter.visual)

    definePainter: (name, options) ->
        if options.visual then options.visual.set statename: name
        @painter[name] = options
        
MakeSprite = exports.MakeSprite = (frames) -> new Sprite().frames(frames)
