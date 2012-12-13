_ = require 'underscore'
helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
decorators = require 'decorators'; decorate = decorators.decorate

# painter is made concrete by subclassing abstract painter
View = require('./views'); Painter = View.Painter 

raphael = require 'raphael-browserify'

# will figure out coordinates argument for a painter method, if it didn't receive them already
coordsDecorator = (targetf,coords) ->
    if not coords then coords = @view.translate @state.point.coords()
    targetf.call(@,coords)

GameView = exports.GameView = View.GameView.extend4000
    initialize: ->
        @paper = raphael @get('el'), "100%", "100%" # create raphael paper

        # calculate size for points
        sizey = Math.floor(@paper.canvas.clientHeight / @model.get('height') ) - 2
        sizex = Math.floor(@paper.canvas.clientWidth / @model.get('width') ) - 2
        if sizex > sizey then @size = sizey else @size = sizex
        
        # hook window onresize event, and trigger gameview.pan event to redraw the game
        # TODO

    # convert abstract game coordinates to concrete raphael paper coordinates
    translate: (coords) ->
        return _.map coords, (a) => a * @size

Sprite = exports.Sprite = {}

Image = exports.Image = Painter.extend4000
    draw: decorate( coordsDecorator, (coords) ->
        if @rendering then @move(coords)
        else @rendering = @view.paper.image(src='pic/' + @name + '.png', coords[0], coords[1], @view.size, @view.size))
    
    move: decorate( coordsDecorator, (coords) -> console.log('move called',coords); @rendering.attr { x: coords[0], y: coords[1] })
    
    remove: -> @rendering.remove()

Color = exports.Color = Painter.extend4000
    draw: decorate coordsDecorator, (coords) -> @rendering = @view.paper.rect(coords[0], coords[1], @view.size, @view.size).attr( 'opacity': .7, 'stroke-width': 1, stroke: @color, fill: @color)
    move: decorate coordsDecorator, (coords) -> @rendering.attr { x: coords[0], y: coords[1] }    
    remove: -> @rendering.remove()

# matches different states of a model and renders the appropriate painter
Meta = exports.Meta = Painter.extend4000
    initialize: true

# should somehow use metapainter for this..
Direction = exports.Direction = Meta.extend4000
    initialize: ->
        console.log('dierectasf')
        @when 'state', (state) => state.on 'change:direction', (direction) => @directionchange(direction)
    
    draw: -> @rendering = @directionRepr()
    move: -> @rendering.move()
    remove: -> @rendering.remove()

    directionRepr: () -> return new @[@state.get('direction').string()]( view: @view, state: @state )
    directionchange: (direction) -> if @rendering then @remove(); @draw()

