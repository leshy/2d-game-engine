_ = require 'underscore'
helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v

GameView = require 'view.coffee'
raphael = require 'raphael-browserify'

exports.View = GameView.View.extend4000
    initialize: -> 
        @paper = raphael @el, "100%", "100%"
    
        sizey = Math.floor(@paper.canvas.clientHeight / @model.get('height') ) - 2
        sizex = Math.floor(@paper.canvas.clientWidth / @model.get('width') ) - 2

        if sizex > sizey then @size = sizey else @size = sizex

    translate: (coords) ->
        return _.map coords, (a) => a * @size


# painter subclass should implement Draw(coords) Move(coords) and Remove() methods
Painter = Backbone.Model.extend4000
    initialize: ->
        @when 'state' (state) =>
            @state = state
            state.on 'move' => @_draw (state.point.coords)
            state.on 'remove' => @_draw (state.point.coords)
            
    _draw: (coords,rest...) ->
        if not coords then coords = @state.point.coords
        coords = @game.translate coords
        @draw.apply @,[coords].concat(rest)


ImagePainter = Painter.extend4000
    draw: (coords) ->
        if not @rendering then
            @rendering = @game.paper.image(src='pic/' + name + '.png', c[0], c[1], @game.size, @game.size)
        else
            @move(coords)

    remove: (coords) -> @rendering.remove()

    move: (coords) -> @rendering.attr { x: coords[0], y: coords[1] }


# matches different states of a model and renders the appropriate painter
MetaPainter = Painter.extend4000
    initialize: true

# should somehow use metapainter for this..
DirectionPainter = MetaPainter.extend4000
    initialize: -> @when 'state' (state) => state.on 'change:direction' (direction) => @directionchange(direction)

    directionRepr: () -> return new @[@state.get('direction').string()]( game: @game )
    
    draw: (coords) -> if not @rendering then @rendering = @directionRepr() else @rendering.move(coords)
    
    directionchange: (direction) -> if @rendering then @rendering.remove(); @draw()
    
    remove: -> @rendering.remove()
        
 