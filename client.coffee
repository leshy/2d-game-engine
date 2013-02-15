Backbone = require 'backbone4000'
Game = require 'game/models'
comm = require 'comm/clientside'
_ = require 'underscore'

# mixin for a game model - will receive state changes
GameClient = exports.GameClient = comm.MsgNode.extend4000
    initialize: ->
        @subscribe { game: @id, changes: 'Array' }, (msg,reply,next,transmit) =>
            reply.end()
            _.map msg.changes, @applychange.bind(@)

    applychange: (change) ->
        if change.a is 'set' then @point(change.p).push new @state[change.s]
            
        
