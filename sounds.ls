require! {
  howler
  helpers: h
  underscore: _
  backbone4000: Backbone
}

HowlerSounds = exports.HowlerSounds = Backbone.Model.extend4000 do
  rootUrl: 'sounds'
  maxDistance: 15
  event: (event, state) ->
    if sounds = @sounds[state.name]?[event]
      if player = state?point?game?player
        distance = state.point.distance(player.point)
        console.log 'distance is', distance
        volume = (@maxDistance - distance) / distance
        if volume < 0 then volume = 0
        if volume > 1 then volume = 1
        console.log 'volime is', volume
      else
        volume = 1
        
      sound = h.random(sounds)
      sound.volume(volume)
      sound.play()
    
  initialize: (options) ->
    @set options
    _.extend @, options
    
    if @sounds?
      @sounds = h.dictMap @sounds, (stateEvents, stateName) ~> 
        h.dictMap stateEvents, (value, event) ~> 
          soundNames = x = switch value?@@
            | Boolean => [ stateName + h.capitalize(event) ]
            | String => [ value ]
            | Number => _.times value, (n) -> stateName + h.capitalize(event) + n
            | Array => value

          _.map soundNames, (soundName) ~>
            soundPath = h.path(@rootUrl, soundName) + ".ogg"
            new howler.Howl urls: [ soundPath ]
          
    @when 'game', (game) ~>
      @game = game
      _.defer ~>
        
        game.on 'set', (state, point) ~> @event 'set', state
        game.on 'del', (state, point) ~> @event 'del', state

  

