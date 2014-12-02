Backbone = require 'backbone4000'
Game = require('game/models').Game
_ = require 'underscore'
helpers = require 'helpers'

#
# mixin for a game model - will transmit state changes
# subclass of this has to implement communication methods:
# 
# send(json_object)
# and
# subscribe ??? -- subscriptionman2 ???
# 

GameSever = exports.GameServer = Backbone.Model.extend4000
    initialize: ->
        @setHook = @setHook.bind @
        @delHook = @delHook.bind @
        @moveHook = @moveHook.bind @

    stopNetworkTicker: ->
        clearTimeout(@timeout)
        @log = undefined
        @off 'set', @setHook
        @off 'del', @delHook
        @off 'move', @moveHook

    startNetworkTicker: ->
        @log = []
        @on 'set', @setHook
        @on 'del', @delHook
        @on 'move', @moveHook        
        @each (point) => point.each (state) => @setHook(state)
        @networkTickLoop()

    setHook: (state) -> # maybe state render should take care of syncattributes and not this f
        if state.nosync or state.noset then return
        entry = { a: 'set', p: state.point.coords(), id: state.id, s: state.render() }
        if state.syncattributes then entry.o = helpers.dictMap state.syncattributes, (val,key) -> state.get(key)
        @log.push entry

    delHook: (state) ->
        if state.nosync or state.nodel then return
        @log.push { a: 'del', id: state.id }
            
    moveHook: (state,pointto) ->
        if state.nosync or state.nomove then return
        @log.push { a: 'move', p: pointto.coords(), id: state.id }
            
    networkTickLoop: ->
        @networkTick()
        @networkTickTimeout = setTimeout @networkTickLoop.bind(@), 50
    
    networkTick: ->
        if @log.length is 0 then return
        log = @log
        @log = []
        @send { game: @id, tick: @tick, changes: log }
        
    send: (msg) ->
        console.warn "game server trying to send, but no send method is implemented"
