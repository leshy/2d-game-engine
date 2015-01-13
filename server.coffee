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

GameServer = exports.GameServer = Backbone.Model.extend4000
    initialize: ->
        @setHook = @setHook.bind @
        @delHook = @delHook.bind @
        @moveHook = @moveHook.bind @

    stopNetworkTicker: ->
        clearTimeout(@timeout)
        delete @log
        @off 'set', @setHook
        @off 'del', @delHook
        @off 'move', @moveHook
        @off 'message', @msgHook
        @on 'attr', @attrHook
                
    startNetworkTicker: ->
        @log = []
        
        @on 'set', @setHook
        @on 'del', @delHook
        @on 'move', @moveHook        
        @on 'message', @msgHook
        @on 'attr', @attrHook
        
        @each (point) => point.each (state) => @setHook(state)
        @networkTickLoop()

    setHook: (state) -> # maybe state render should take care of syncattributes and not this f
        if state.nosync or state.noset then return
        entry = { a: 'set', p: state.point.coords(), id: state.id, s: state.name }
        if state.syncattributes then entry.o = helpers.dictMap state.syncattributes, (val,key) -> state.get(key)
        @log.push entry

    delHook: (state) ->
        if state.nosync or state.nodel then return
        @log.push { a: 'del', id: state.id }
            
    moveHook: (state,pointto) ->
        if state.nosync or state.nomove then return
        @log.push { a: 'move', id: state.id, p: pointto.coords() }
        
    msgHook: (state,msg) ->
        @log.push { a: 'msg', id: state.id, m: msg }

    attrHook: (state,change) ->
        @log.push { a: 'attr', id: state.id, c: change }
                                    
    networkTickLoop: ->
        @networkTick()
        @networkTickTimeout = setTimeout @networkTickLoop.bind(@), 50
    
    networkTick: ->
        if @log.length is 0 then return
        log = @log
        @log = []
        @send { tick: @tick, changes: log }
        
    send: (msg) ->
        console.warn "game server trying to send, but no send method is implemented"
