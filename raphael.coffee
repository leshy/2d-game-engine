_ = require 'underscore'
helpers = require 'helpers'
Backbone = require 'backbone4000'
validator = require 'validator2-extras'; v = validator.v
decorators = require 'decorators'; decorate = decorators.decorate
$ = require 'jquery-browserify'

# painter is made concrete by subclassing abstract painter
View = require './views'
raphael = require 'raphael-browserify'

# will figure out coordinates argument for a painter method, if it didn't receive them already
coordsDecorator = (targetf,coords) ->
    if not coords then coords = @gameview.translate @state.point.coords()
    targetf.call(@,coords)

GameView = exports.GameView = View.GameView.extend4000
    initialize: ->
        el = @get('el')
        @paper = raphael el.get(0), el.width(), el.height() # create raphael paper
        window.paper = @paper
        
        # calculate size for points
        sizey = Math.floor(@paper.canvas.clientHeight / @game.get('height'))
        sizex = Math.floor(@paper.canvas.clientWidth / @game.get('width'))
        if sizex > sizey then @size = sizey else @size = sizex

        @size_offset = Math.round((@paper.canvas.clientWidth - (@size * game.get('width'))) / 2)
        
        # hook window onresize event, and trigger gameview.pan event to redraw the game
        # TODO
        
    # convert abstract game coordinates to concrete raphael paper coordinates
    translate: (coords) ->
        return _.map coords, (a) => @size_offset + (a * @size)

# generic raphael painter, it just translates in game abstract coordinates to raphael coordinates
RaphaelPainter = View.Painter.extend4000
    draw: (point) ->
        @render @gameview.translate(point.coords())

Image = exports.Image = RaphaelPainter.extend4000
    render: (coords) ->
        # is this the first time this state has been rendered?
        if not @rendering
            @rendering = @gameview.paper.image(src=@getpic(), coords[0], coords[1], @gameview.size, @gameview.size); @rendering.toFront();
            if @rotation then @rendering.rotate @rotation
            return
        # do we need to move our rendering? 
        if @rendering.attrs.x != coords[0] or @rendering.attrs.y != coords[1] then @move(coords)
        # bring us to front..
        @rendering.toFront()

    getpic: -> '/pic/' + (@pic or @name) + '.png'
    
    move: (coords) -> @rendering.attr { x: coords[0], y: coords[1] }

    images: -> [ @getpic() ]
            
    remove: -> @rendering.remove()
    
Sprite = exports.Sprite = Image.extend4000
    initialize: ->
        @frame_pics = []
        _.times @frames, (frame) =>
            @frame_pics.push '/pic/' + (@pic or @name) + frame + ".png"
        @frame = 0
        if @gameview then @listenTo @gameview,'tick', => @tick()

    getpic: -> @frame_pics[@frame]

    remove: ->
        @stopListening()
        Image.prototype.remove.call @
    
    tick: ->
        if not @rendering then return
        if @frame > @frame_pics.length - 1
            if @once then @stopListening(); return
            @frame = 0
        @rendering.attr src: @getpic()
        @frame++

    images: -> @frame_pics
    
Color = exports.Color = RaphaelPainter.extend4000
    render: decorate coordsDecorator, (coords) -> @rendering = @gameview.paper.rect(coords[0], coords[1], @gameview.size, @gameview.size).attr( 'opacity': .7, 'stroke-width': 1, stroke: @color, fill: @color)
    move: decorate coordsDecorator, (coords) -> @rendering.attr { x: coords[0], y: coords[1] }    
    remove: -> @rendering.remove()

# matches different states of a model and renders the appropriate painter
MetaPainter = exports.MetaPainter = RaphaelPainter.extend4000
    render: (coords) ->
        if not @repr
            cls = @decideRepr()
            @repr = new cls { gameview: @gameview, state: @state }
        @repr.render(coords)
        
    remove: -> @repr.remove()
        
    decideRepr: -> throw 'override me'
        
DirectionPainter = exports.DirectionPainter = MetaPainter.extend4000
    decideRepr: () -> @reprs[@state.get('direction').string()]

OrientationPainter = exports.OrientationPainter = MetaPainter.extend4000
    decideRepr: () -> @reprs[@state.get('direction').orientation()]

#TransformPainter = exports.TransformPainter = Backbone.Model.extend4000
#    render: (coords) ->
#        @repr 
        


