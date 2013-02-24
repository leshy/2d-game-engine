Backbone = require 'backbone4000'
Game = require 'game/models'
comm = require 'comm/clientside'
_ = require 'underscore'

# mixin for a game model - will receive state changes
GameClient = exports.GameClient = comm.MsgNode.extend4000
    initialize: ->
        @subscribe { game: @id, changes: 'Array' }, (msg,reply,next,transmit) =>
            reply.end()
            _.map msg.changes, (change) => @applychange change

    applychange: (change) ->
        if change.a is 'set'
            attrs = { id: change.id }
            if change.o then attrs = _.extend attrs, change.o
            @point(change.p).push state = new @state[change.s](attrs)
            console.log 'received new state',state.render(),attrs
            #if state.start then state.start()
            
        if change.a is 'del' then console.log 'received del', change.id; @byid[change.id].remove()
        if change.a is 'move'
            console.log 'move', change
            @byid[change.id].move @point(change.p)
        
        
    nextid: (state) -> "c" + @stateid++