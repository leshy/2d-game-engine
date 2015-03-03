_ = require 'underscore'
helpers = require 'helpers'
Game = require 'game/models'
colors = require 'colors'

exports.mover = {
    initialize: (options) ->
        console.log "mover init",options
        _.extend @, {
            coordinates: [ 0.5, 0.5]
            speed: 0
            direction: new Game.Direction(0,0)
        }, options

    start: ->
        @movementChange()
        
    display: ->
        @movementChange()
        x = Math.round(@coordinates[0] * 40)
        y = Math.round(@coordinates[1] * 20)
        ret = ""

        _.times 20, (cy)  ->
            res = []
            _.times 40, (cx) ->
                res.push if cx is x and cy is y then colors.green("♙") else colors.grey("∘")
            ret += "       " + res.join("") + "\n"
        
        ret + "       " + colors.red(@point.coords()) + " | " + colors.yellow(@coordinates) + "\n"
                
    # will calculate when the object will come to the point center given some speed and direction, used to decide if object is allowed to keep going
    centerEta: (direction, speed) ->
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            if direction is 0 then return Infinity
            if direction > 0 then return (0.5 - coordinate) / speed
            return (coordinate - 0.5) / speed
        Math.ceil(_.reduce eta, ((min,x) -> if x < min and x >= 0 then x else min), Infinity)
        
    # will calculate when the object will pass the point boundary given some speed and direction
    boundaryEta: (direction, speed) ->
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            if direction is 0 then Infinity
            else if direction > 0 then (1 - coordinate) / speed
            else coordinate / speed
        _.reduce eta, ((min,x) -> if x < min then x else min), Infinity
        
    movementChange: ->
        if @doSubMove then @doSubMove()
        @scheduleMove()
        console.log 'MSG',@direction.string(), @coordinates
        @msg { d: @direction.coords(), speed: @speed, c: @coordinates }
        
    scheduleMove: ->
        @unsubscribeMoves()
                
        eta = Math.ceil(@boundaryEta(@direction, @speed))
        if eta is Infinity then return
        
        @uSubMove  = @in eta, @doSubMove = @makeSubMover(@direction,@speed)
        
        if (centerEta = @centerEta(@direction, @speed)) < eta
            console.log 'centereta', @point.game.tick, centerEta, @coordinates, @speed
            @uCenterEvent = @in centerEta, => @trigger('center')
            
    unsubscribeMoves: ->
        if @doSubMove then delete @doSubMove
        if @uSubMove then @uSubMove(); delete @uSubMove
        if @uCenterEvent then @uCenterEvent(); delete @uCenterEvent
    
    makeSubMover: (direction, speed) ->
        startTime = @point.game.tick
        =>
            delete @doSubMove
            ticks = @point.game.tick - startTime
            @subMove direction, speed, ticks
            @scheduleMove()

    subMove: (direction, speed, time) ->
        if not time then return
        console.log @point.game.tick + " " + colors.yellow('move'), @coordinates, colors.green(direction.string()), speed, time
        @coordinates = helpers.squish direction.coords(), @coordinates, (direction,coordinate) => coordinate += direction * speed * time

        if (movePoint = @point.direction( _.map @coordinates, (c) -> if c >= 1 then 1 else if c <= 0 then -1 else 0 )) isnt @point
            @coordinates = _.map @coordinates, (c) -> if c >= 1 then c - 1 else if c <= 0 then c + 1 else c
            console.log 'moved from', @point.coords(),'to', movePoint.coords(), @coordinates
            @move movePoint
}

