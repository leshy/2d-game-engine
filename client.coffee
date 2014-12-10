Backbone = require 'backbone4000'
Game = require 'game/models'
_ = require 'underscore'

# mixin for a game model - will receive state changes
GameClient = exports.GameClient = Backbone.Model.extend4000
    initialize: ->
        @subscribe { changes: Array }, (msg) =>
            _.map msg.changes, (change) => @applychange change

        @subscribe { end: true }, (msg) =>
            _.defer => @end(msg.end)
        
    applychange: (change) ->
        if change.a is 'set'
            attrs = { id: change.id }
            if change.o then attrs = _.extend attrs, change.o
            @point(change.p).push state = new @state[change.s](attrs)
            
        if change.a is 'del' then @byid[change.id].remove()
        if change.a is 'move'then @byid[change.id].move @point(change.p)
                
    nextid: (state) -> "c" + @stateid++

