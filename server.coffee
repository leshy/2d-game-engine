Backbone = require 'backbone4000'
Game = require('./models').Game
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

    start: ->
        @startNetworkTicker()

    stopNetworkTicker: ->
        clearTimeout @timeout
        delete @log

        @off 'set', @setHook
        @off 'del', @delHook
        @off 'move', @moveHook
        @off 'message', @msgHook
        @off 'attr', @attrHook
        @off 'end', @endHook

    startNetworkTicker: ->
        @log = []

        @on 'set', @setHook
        @on 'del', @delHook
        @on 'move', @moveHook
        @on 'message', @msgHook
        @on 'attr', @attrHook
        @on 'end', @endHook

        @each (point) => point.each (state) => @setHook(state)
        @networkTickLoop()

    snapshot: ->
        log = []
        @each (point) => point.each (state) =>
            if entry = @setData(state) then log.push entry
        return log

    setData: (state) ->
        if state.nosync or state.noset then return
        entry = { a: 'set', p: state.point.coords(), id: state.id, s: state.name }

        if state.syncattributes then entry.o = helpers.dictMap state.syncattributes, (val,key) -> state.get(key)
        entry

    setHook: (state) -> # maybe state render should take care of syncattributes and not this f
        if entry = @setData(state) then @log.push entry

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

    endHook: (winner) ->
        @log.push { a: 'end', winner: winner }

    networkTickLoop: ->
        @networkTick()
        @networkTickTimeout = setTimeout @networkTickLoop.bind(@), 50

    networkTick: ->
        if @log.length is 0 then return
        log = @log
        @log = []
        @send { tick: @tick, changes: log }

    # these two are overrriden or events bound to when implementing a concrete transport protocol
    send: (msg) -> @trigger 'send', msg

    receive: (msg, player) ->
      if msg.id
        @byid[msg.id]?.trigger 'message', msg.m, player

      @trigger 'receive', msg, player
