Backbone = require 'backbone4000'
comm = require 'comm/clientside'
_ = require 'underscore'
helpers = require 'helpers'
decorators = require 'decorators'

exports.Point = Point = class Point
    constructor: ([@x,@y],@host) -> true
    modifier: (coords) -> new Point(@x + x, @y + y, @field)
    up:    -> @modifier(1,0)
    down:  -> @modifier(-1,0)
    left:  -> @modifier(0,-1)
    right: -> @modifier(0,1)
    stuff: -> @host.stuff(@)
    replaceStuff: @


exports.Field = Field = Backbone.Model.extend4000
    initialize: ->
        @points = {}

        pointDecorator = (fun,args...) =>
            if args[0].constructor != Point then args[0] = @getPoint(args[0])
            fun.apply(@,args)

        @getIndex = decorators.decorate(pointDecorator,@getIndex)
        @stuff = decorators.decorate(pointDecorator,@stuff)
        @setPoint = decorators.decorate(pointDecorator,@setPoint)
        
    getIndex: (point) ->
        point.x + (point.y * @get ('width'))
        
    getIndexRev: (i) -> width = @get('width'); [ i % width, Math.floor(i / width) ]

    stuff: (point) -> @points[@getIndex point]
    
    getPoint: (coords) -> new Point(coords, @)
    
    setPoint: (point,newstuff) ->
        index = @getIndex point
        if oldstuff = @points[index] then this.trigger('replace', point, oldstuff, newstuff)
        @points[index] = newstuff
        this.trigger('set', point, newstuff)
        point

    each: (callback) -> _.times @get('width') * @get('height'), (i) => callback @getPoint(@getIndexRev(i))
    eachFull: (callback) ->
        _.map @points, (point,index) => callback @getPoint(@getindexRev(index))
        


exports.ViewField = ViewField = Field.extend4000
    initialize: ->
        @on 'replace', (point,oldstuff) =>
            oldstuff.remove()

exports.Game = Game = comm.MsgNode.extend4000 Field,
    initialize: ->
        @subscribe { ctrl: { k: true, s: true }}, (msg,reply) ->
            console.log(msg.json())
            reply.end()
    tick: ->
        true

