Backbone = require 'backbone4000'
Game = require 'game/models'
h = require 'helpers'
_ = require 'underscore'

# mixin for a game model - will receive state changes
GameClient = exports.GameClient = Backbone.Model.extend4000
    initialize: ->
        @subscribe { changes: Array }, (msg) =>
            @applyChanges(msg.changes)

    applyChanges: (changes) ->
        _.map changes, (change) => @applyChange change

    applyChange: (change) ->
        if change.a is 'set'
            attrs = { id: change.id }
            if change.o then attrs = _.extend attrs, change.o

            point = @point(change.p)
            point.push state = new @state[change.s](attrs)

        if change.a is 'del'  then @byid[change.id]?.remove()
        if change.a is 'move' then @byid[change.id]?.move @point(change.p)
        if change.a is 'msg'  then @byid[change.id]?.trigger 'message', change.m
        if change.a is 'end'  then h.wait 50, => @end change.winner

    nextid: (state) -> "c" + @stateid++
