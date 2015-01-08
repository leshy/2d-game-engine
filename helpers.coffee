_ = require 'underscore'
helpers = require 'helpers'
Game = require 'game/models'

exports.mover = {         
    initialize: (options) ->
        _.extend @, {
            coordinates: [ 0.5, 0.5]
            speed: 0
            direction: new Game.Direction(0,0)
        }, options

    start: -> @scheduleMove()

    movementChange: ->
        if @doSubMove
            # some other movement is already scheduled, unschedule it
            # move as much as you are supposed to until now,
            # and schedule new movement
            @unsub()
            @doSubMove()
            delete @doSubMove

        else @scheduleMove()

    scheduleMove: ->
        eta = @boundaryEta(@direction, @speed)
        if eta is Infinity then return
        @unsub  = @in Math.ceil(eta), @doSubMove = @makeMover()

    makeMover: (direction=@direction,speed=@speed) ->
        startTime = @point.game.tick
        =>
            ticks = @point.game.tick - startTime
            @subMove direction, speed, ticks
            @scheduleMove()

    # will calculate when the object will pass the point boundary given some speed and direction
    boundaryEta: (direction, speed) ->
        eta = helpers.squish direction.coords(), @coordinates, (direction,coordinate) =>
            if direction > 0 then (1 - coordinate) / speed
            else coordinate / speed

        _.reduce eta, ((max,x) -> if x > max then x else max), 0

    # will calculate position depending on direction and time
    subMove: (direction, speed, time) ->
        @coordinates = helpers.squish direction.coords(), @coordinates, (direction,coordinate) => coordinate += direction * speed * time

        if (movePoint = @point.direction( _.map @coordinates, (c) -> if c >= 1 then 1 else if c <= 0 then -1 else 0 )) isnt @point
            @coordinates = _.map @coordinates, (c) -> if c >= 1 then c - 1 else if c <= 0 then c + 1 else c
            @move movePoint

        #@coordinates = _.map @coordinates, (c) -> helpers.round(c)

}