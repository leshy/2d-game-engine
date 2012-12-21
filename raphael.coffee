_ = require 'underscore'
helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
decorators = require 'decorators'; decorate = decorators.decorate

# painter is made concrete by subclassing abstract painter
View = require('./views'); 

raphael = require 'raphael-browserify'

# will figure out coordinates argument for a painter method, if it didn't receive them already
coordsDecorator = (targetf,coords) ->
    if not coords then coords = @gameview.translate @state.point.coords()
    targetf.call(@,coords)

GameView = exports.GameView = View.GameView.extend4000
    initialize: ->
        @paper = raphael @get('el'), "100%", "100%" # create raphael paper
        
        # calculate size for points
        sizey = Math.floor(@paper.canvas.clientHeight / @game.get('height') ) - 2
        sizex = Math.floor(@paper.canvas.clientWidth / @game.get('width') ) - 2
        if sizex > sizey then @size = sizey else @size = sizex
        
        # hook window onresize event, and trigger gameview.pan event to redraw the game
        # TODO
        
    # convert abstract game coordinates to concrete raphael paper coordinates
    translate: (coords) ->
        return _.map coords, (a) => a * @size




# generic raphael painter, it just translates in game abstract coordinates to raphael coordinates
RaphaelPainter = View.Painter.extend4000
    draw: (point) ->
        @render @gameview.translate(point.coords())




Sprite = exports.Sprite = {}

Image = exports.Image = RaphaelPainter.extend4000
    render: decorate( coordsDecorator, (coords) ->
        if @rendering then @move(coords)
            
        else @rendering = @gameview.paper.image(src='pic/' + @name + '.png', coords[0], coords[1], @gameview.size, @gameview.size))
    
    move: decorate( coordsDecorator, (coords) -> console.log('move called',coords); @rendering.attr { x: coords[0], y: coords[1] })
    
    remove: -> @rendering.remove()

Color = exports.Color = RaphaelPainter.extend4000
    render: decorate coordsDecorator, (coords) -> @rendering = @gameview.paper.rect(coords[0], coords[1], @gameview.size, @gameview.size).attr( 'opacity': .7, 'stroke-width': 1, stroke: @color, fill: @color)
    move: decorate coordsDecorator, (coords) -> @rendering.attr { x: coords[0], y: coords[1] }    
    remove: -> @rendering.remove()

# matches different states of a model and renders the appropriate painter
Meta = exports.Meta = RaphaelPainter.extend4000
    initialize: true

# should somehow use metapainter for this..
Direction = exports.Direction = Meta.extend4000
    initialize: ->
        console.log('dierectasf')
        @when 'state', (state) => state.on 'change:direction', (direction) => @directionchange(direction)    
    render: -> @rendering = @directionRepr()
    move: -> @rendering.move()
    remove: -> @rendering.remove()

    directionRepr: () -> return new @[@state.get('direction').string()]( view: @gameview, state: @state )
    directionchange: (direction) -> if @rendering then @remove(); @draw()

