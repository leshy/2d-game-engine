Backbone = require 'backbone4000'
Game = require('game/models').Game
comm = require('comm/clientside')
_ = require 'underscore'

# mixin for a game model - will transmit state changes
GameSever = exports.GameServer = comm.MsgNode.extend4000
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
        
        #@each (point) => point.each (state) => @setHook(state)
        
        @networkTickLoop()

    setHook: (state) -> 
        console.log 'set'.magenta, state.name
        @log.push { a: 'set', p: state.point.coords(), id: state.id, s: state.render() }

    delHook: (state) -> 
        console.log 'del'.magenta, state
        @log.push { a: 'del', id: state.id }
            
    moveHook: (state,pointfrom,pointto) -> 
        console.log 'move'.magenta, state
        @log.push { a: 'move', p: pointto.coords(), id: state.id }
            
    networkTickLoop: ->
        @networkTick()
        @networkTickTimeout = setTimeout @networkTickLoop.bind(@), 500
    
    networkTick: ->
        log = @log
        @log = []
        console.log (log)
        @send { game: @id, tick: @tick, changes: log }
        
