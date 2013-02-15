Backbone = require 'backbone4000'
Game = require 'game/models'

GameSever = exports.GameServer = Game.Game.extend4000
    initialize: ->
        @setHook = @setHook.bind @
        @delHook = @delHook.bind @
        @moveHook = @moveHook.bind @

    stopNetworkTicker: ->
        clearTimeout(@timeout)
        
        @log = []
        @off 'set', @setHook
        @off 'del', @delHook
        @off 'move', @moveHook

    startNetworkTicker: ->
        @log = []
        @on 'set', @setHook
        @on 'del', @delHook
        @on 'move', @moveHook

        @each (point) => point.each (state) => @send { a: 'set', p: point.coords(), s: state.render() }
        
        @networkTickLoop()

    setHook: (state,point) =>
        console.log onsole.log 'set'.magenta, state
        @log.push { a: 'set', p: point.coords(), s: state.render() }

    delHook: (state,point) =>
        console.log 'del'.magenta, state
        @log.push { a: 'del', p: point.coords(), s: state.render() }
            
    moveHook: (state,pointfrom,pointto) =>
        console.log 'move'.magenta, state
        @log.push { a: 'move', pf: pointfrom.coords(), p: pointto.coords(), s: state.render() }
            
    networkTickLoop: ->
        @networkTick()
        @networkTickTimeout = setTimeout @networkTickLoop.bind(@), 500
    
    networkTick: ->
        log = @log
        @log = []
        console.log (log)
        @send { game: @id, tick: @tick, changes: log }
        

        