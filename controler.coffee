if not window then window = {}
$ = require 'jquery-browserify'
comm = require 'comm/clientside'
validator = require 'validator2-extras'

exports.KeyControler = comm.MsgNode.extend4000 validator.ValidatedModel,
    validator: { actions: 'Object' }
    
    initialize: ->
        @pass()
        state = {}
        actions = @get 'actions'

        $(document).keydown (event) =>
            if not key = actions[event.keyCode] then return
            if state[key] then return
            state[key] = true
            @msg({ ctrl: { k: key, s: 'd'}})
            
        $(document).keyup (event) =>
            key = event.keyCode
            if not key = actions[event.keyCode] then return
            if not state[key]? then return
            delete state[key]
            @msg({ ctrl: { k: key, s: 'u'}})

