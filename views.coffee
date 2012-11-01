BackboneB = require 'backbone-browserify'
helpers = require 'helpers'
raphael = require 'raphael-browserify'

exports.GameView = BackboneB.View.extend
    initialize: ->
        @paper = raphael @el, "100%", "100%"
        @size = Math.floor(@paper.canvas.clientHeight /  @model.get('height') ) - 2
        @spacing = 0
        @model.on 'change:data', @redraw.bind(@)
        @initdraw()
        @redraw()
        
    initdraw: ->
        @repr = new ViewField { width: @model.get('width'), height: @model.get('height') }
        @model.each (point) =>
            c = @coords(point)
            @paper.rect(c[0], c[1], @size, @size, 0 ).attr( 'opacity': 0.4, 'stroke-width': 1, stroke: 'black' )
            @drawpoint(point)

    drawpoint: (point) ->
        stuff = point.stuff()
        if not stuff? then return
        @repr.setPoint point, @getrepr(point,stuff)

    getrepr: (point,stuff) ->
        c = @coords(point)
        reprs = { 1: 'red', 2: 'blue', 3: 'green', 4: 'orange' }
        @paper.rect(c[0] + 3, c[1] + 3, @size - 3, @size - 3, 0 ).attr( 'opacity': 1.0, 'stroke-width': 1, stroke: reprs[stuff] )
    
    coords: (point) -> [ 5 + ( point.x * ( @size + @spacing )), 5 + ( point.y * ( @size + @spacing )) ]

    redraw: -> true
        #@paper.clear()
        #@paper.circle(320, 240, 60).animate({fill: "#223fa3", stroke: "#000", "stroke-width": 80, "stroke-opacity": 0.5}, 2000)
