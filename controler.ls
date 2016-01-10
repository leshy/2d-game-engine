if not window then window = {}
Backbone = require 'backbone4000'
$ = require 'jquery'
validator = require 'validator2-extras'

exports.KeyControler = Backbone.Model.extend4000 validator.ValidatedModel, do
  validator: { actions: 'Object' }

  send: ->
    if @game then @game.trigger 'ctrl', it

  initialize: ->
    state = {}
    actions = @get 'actions'
    
    @when 'game', ~> @game = it
    
    $(document).keydown (event) ~>
      #console.log event.keyCode
      event.preventDefault()
      if not key = actions[event.keyCode] then return 
      if state[key] then return
      state[key] = true
      @send { k: key, s: 'd'}
      
    $(document).keyup (event) ~>
      event.preventDefault()
      key = event.keyCode
      if not key = actions[event.keyCode] then return
      if not state[key]? then return
      delete state[key]
      @send { k: key, s: 'u'}

  end: ->
    $(document).off('keydown')
    $(document).off('keyup')
    @trigger 'end'
    
