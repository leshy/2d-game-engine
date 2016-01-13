Backbone = require 'backbone4000'
Game = require 'game/models'
h = require 'helpers'
_ = require 'underscore'

# mixin for a game model - will receive state changes
GameClient = exports.GameClient = Backbone.Model.extend4000 do
    initialize: ->
      @on 'message', (state, msg) ~>
        @send { a: 'msg', m: msg, id: state.id }
    
    # this should be overrriden or event bound when implementing a concrete transport protocol
    send: (msg) -> @trigger 'send', msg
    
    receive: (data) -> @applyChanges data.changes
      
    applyChanges: (changes) ->
      _.map changes, (change) ~> @applyChange change

    applyChange: (change) ->
        if change.a is 'set'
            attrs = { id: change.id }
            if change.o then attrs = _.extend attrs, change.o
            point = @point change.p
            point.push state = new @state[change.s](attrs)

        switch change.a
          | 'del'  => @byid[change.id]?.remove()
          | 'move' => # small ugly hack, parsing/generating of these messages should be moved to individual states
            state = @byid[change.id]
            if state?nomove then return
            else state?move @point(change.p)
            
          | 'msg'  => @byid[change.id]?.trigger 'message', change.m
          | 'end'  => h.wait 50, => @end change.winner

    nextid: (state) -> "c" + @stateid++

