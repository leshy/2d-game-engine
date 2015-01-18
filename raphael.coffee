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
        #@paper = raphael el.get(0), el.width(), el.height() # create raphael paper
        @paper = raphael el.get(0), "100%", "100%" # create raphael paper        
        window.paper = @paper

        calculateSizes = =>
            # calculate size for points
            elHeight = $(@paper.canvas).height()
            elWidth = $(@paper.canvas).width()
            gameHeight = @game.get('height')
            gameWidth = @game.get('width')

            sizey = Math.floor(elHeight / gameHeight)
            sizex = Math.floor(elWidth / gameWidth)
            if sizex > sizey then @size = sizey else @size = sizex

            console.log "elHeight: ", elHeight, gameHeight, @size
            console.log "elWidth: ", elWidth, gameWidth, @size
            @size_offsetx = Math.floor((elWidth - (@size * gameWidth)) / 2)
            @size_offsety = Math.floor((elHeight - (@size * gameHeight)) / 2)

        calculateSizes()
        
        # hook window onresize event, and trigger gameview.pan event to redraw the game
        # TODO
        
#        $(window).resize =>
#            calculateSizes()
#            @rerender()
            
#    rerender: ->
#        _.map @pinstances, (painter) -> painter.render()
        
    # convert abstract game coordinates to concrete raphael paper coordinates
    translate: (coords) -> [ @size_offsetx + (coords[0] * @size),  @size_offsety + (coords[1] * @size) ]

# generic raphael painter, it just translates in game abstract coordinates to raphael coordinates
RaphaelPainter = View.Painter.extend4000
    draw: (point) ->
        if @state?.mover and @rendering then return
        console.log '>> ' + @state?.name + ' draw called'            
        @render @gameview.translate(point.coords()), @gameview.size

Image = exports.Image = RaphaelPainter.extend4000
    animate: ->
        if @animating then @stopAnimate()
        @animating = true
        animation = {}
        if @state.direction.x then animation.x = @rendering.attrs.x + @state.direction.x * @state.speed * @cellSize * 100
        if @state.direction.y then animation.y = @rendering.attrs.y + @state.direction.y * @state.speed * @cellSize * 100
        @animation = @rendering.animate animation, 5000
        @ticker = setInterval (=>
            @rendering.node.style.display='none'
            @rendering.node.offsetHeight # no need to store this anywhere, the reference is enough
            @rendering.node.style.display='block'
            ), 15
        
            
    stopAnimate: ->
        @animating = false
        clearInterval @ticker
        @rendering.stop()
        

    render: (coords, cellSize) ->
        if c = @state?.point?.coords() then coords = @gameview.translate(c)
        console.log 'coords',c
        if not coords then coords = @coords else @coords = coords
        if not cellSize then cellSize = @cellSize else @cellSize = cellSize
        
        # is this the first time this state has been rendered?
        #console.log 'painter render', @name, 'for state', @state?.name
        if @name is "Player" then console.log 'player state: ',@state
        if @state?.mover
            console.log 'coords',coords, @cellSize, @state.coordinates
            coords = helpers.squish coords, @state.coordinates, (coord,subCoord) -> Math.round(coord + (cellSize * (subCoord - 0.5)))
            
            console.log 'coordsafter',coords
        
        if not @rendering

            @rendering = @gameview.paper.image(src=@getpic(), coords[0], coords[1], @gameview.size, @gameview.size); @rendering.toFront();
            if @rotation then @rendering.rotate @rotation
            if @state?.mover then @state.on 'movementChange', =>
                console.log 'movementchange rerender'
                @render()
            return
        
        # do we need to move our rendering? 
        if @rendering.attrs.x != coords[0] or @rendering.attrs.y != coords[1] then @move(coords)
        if @state.speed and not @state.direction.stop() then @animate() else @stopAnimate()
            
        # bring us to front..
        @rendering.toFront()

    getpic: -> '/pic/' + (@pic or @name) + '.png'
    
    move: (coords) ->
        console.log 'need to move rendering to new coords', coords
        window.rendering = @rendering
        @rendering.attr { x: coords[0], y: coords[1] }
        @rendering.node.style.display='none'
        @rendering.node.offsetHeight # no need to store this anywhere, the reference is enough
        @rendering.node.style.display='block'

        #@rendering.hide()
        #helpers.wait 20, => @rendering.show()

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
    render: decorate coordsDecorator, (coords) -> @rendering = @gameview.paper.rect(coords[0], coords[1], @gameview.size, @gameview.size).attr( 'opacity': .5, 'stroke-width': 1, stroke: @color, fill: @color)
    move: decorate coordsDecorator, (coords) -> @rendering.attr { x: coords[0], y: coords[1] }
    remove: -> @rendering.remove()

# matches different states of a model and renders the appropriate painter
MetaPainter = exports.MetaPainter = RaphaelPainter.extend4000
    render: (coords) ->
        console.log "METAPAINTER RENDER", @state, @
        if not @repr
            cls = @decideRepr()
            @repr = new cls { gameview: @gameview, state: @state }
        @repr.render(coords)
        
    remove: -> @repr.remove()
        
    decideRepr: -> throw 'override me'
        
DirectionPainter = exports.DirectionPainter = MetaPainter.extend4000
    decideRepr: -> @reprs[@state.get('direction').string()]

OrientationPainter = exports.OrientationPainter = MetaPainter.extend4000
    decideRepr: -> @reprs[@state.get('direction').orientation()]

#TransformPainter = exports.TransformPainter = Backbone.Model.extend4000
#    render: (coords) ->
#        @repr 

