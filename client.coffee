Backbone = require 'backbone4000'
Game = require 'game/models'

GameClient = exports.GameClient = Game.Game.extend4000
    initialize: ->
        @subscribe { game: @id, changes: 'Array' }, (msg,reply,next,transmit) =>
            reply.end()
            _.map msg.changes, @applychange.bind(@)

    applychange: (change) ->
        if change.a is 'set' then true # something... 
        
