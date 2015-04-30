if not window then window = {}
Backbone = require 'backbone4000'
$ = require 'jquery-browserify'
validator = require 'validator2-extras'

exports.KeyControler = Backbone.Model.extend4000 validator.ValidatedModel,
    validator: { actions: 'Object' }
    
    send: ->
        console.warn "controler trying to send, but no send method is implemented"

    initialize: ->
        state = {}
        actions = @get 'actions'

        $(document).keydown (event) =>
            #console.log event.keyCode
            if not key = actions[event.keyCode] then return
            if state[key] then return
            state[key] = true
            @send ctrl: { k: key, s: 'd'}
            
        $(document).keyup (event) =>
            key = event.keyCode
            if not key = actions[event.keyCode] then return
            if not state[key]? then return
            delete state[key]
            @send ctrl: { k: key, s: 'u'}

    end: ->
        $(document).off('keydown')
        $(document).off('keyup')
        @trigger 'end'
