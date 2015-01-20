_ = require 'underscore'
helpers = require 'helpers'
Game = require 'game/models'
colors = require 'colors'
exports.mover = {
    initialize: (options) ->
        _.extend @, {
            coordinates: [ 0.5, 0.5]
            speed: 0
            direction: new Game.Direction(0,0)
        }, options
        
        console.log 'mover init', @direction, @speed

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
        
    start: ->
        @scheduleMove()
        
        
    movementChange: ->
        if @doSubMove
            # some other movement is already scheduled, unschedule it
            # move as much as you are supposed to until now,
            # and schedule new movement
            @unsub()
            @doSubMove()
            delete @doSubMove

        else @scheduleMove()
        
        @set speed: @speed, direction: @direction, coordinates: @coordinates        
        @msg { d: @direction.coords(), speed: @speed, c: @coordinates }

    centeredCoord: (coord) ->
        distance = (coord) -> Math.abs(coord - 0.5)
        d = distance(coord)
        if d < distance(coord + @speed) and d < distance(coord - @speed) then true else false
            
    centered: (direction) ->
        not _.reject(@coordinates, (coordinate) => @centeredCoord(coordinate)).length

    scheduleMove: ->
        eta = @nextCheck(@direction, @speed)
        console.log 'schedulemove', eta, @direction.string(), @direction.coords()
        if eta is Infinity then return
        if @unsub then @unsub()
        @unsub  = @in Math.ceil(eta), @doSubMove = @makeMover()
        if @centered() then @trigger 'centered'
            
    makeMover: (direction=@direction,speed=@speed) ->
        startTime = @point.game.tick
        =>
            ticks = @point.game.tick - startTime
            @subMove direction, speed, ticks
            @scheduleMove()

    nextCheck: (direction, speed) ->
        check = undefined
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            
            if direction is 0 then return undefined
            
            if direction > 0
                if coordinate < 0.5 then return _.bind(@centerEta,@) else return _.bind(@boundaryEta,@)
                    
            if direction < 0
                if coordinate > 0.5 then return _.bind(@centerEta,@) else return _.bind(@boundaryEta,@)

        f = _.find eta, (x) -> x
        
        if not f then Infinity else f(direction,speed)
        
    # will calculate when the object will come to the point center given some speed and direction, used to decide if object is allowed to keep going
    centerEta: (direction, speed) ->
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            if direction is 0 then Infinity
            else if direction > 0 then (0.5 - coordinate) / speed
            else (coordinate - 0.5) / speed
        _.reduce eta, ((min,x) -> if x < min then x else min), Infinity
        
    # will calculate when the object will pass the point boundary given some speed and direction
    boundaryEta: (direction, speed) ->
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            if direction is 0 then Infinity
            else if direction > 0 then (1 - coordinate) / speed
            else coordinate / speed

        _.reduce eta, ((min,x) -> if x < min then x else min), Infinity

    # will calculate position depending on direction and time
    subMove: (direction, speed, time) ->
        if not time then return
        console.log @point.game.tick + " " + colors.yellow('move'), @coordinates, colors.green(direction.string()), speed, time
        @coordinates = helpers.squish direction.coords(), @coordinates, (direction,coordinate) => coordinate += direction * speed * time

        if (movePoint = @point.direction( _.map @coordinates, (c) -> if c >= 1 then 1 else if c <= 0 then -1 else 0 )) isnt @point
            @coordinates = _.map @coordinates, (c) -> if c >= 1 then c - 1 else if c <= 0 then c + 1 else c
            console.log 'moved from', @point.coords(),'to', movePoint.coords(), @coordinates
            @move movePoint
            console.log 'did the move work?', @point.coords(), movePoint.coords(), @coordinates

        #@coordinates = _.map @coordinates, (c) -> helpers.round(c)

}
