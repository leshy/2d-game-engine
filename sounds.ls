require! {
  howler
  helpers: h
  underscore: _
  backbone4000: Backbone
}

HowlerSounds = exports.HowlerSounds = Backbone.Model.extend4000 do
  rootUrl: 'sounds'
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
        
        game.on 'set', (state, point) ~>
          if sounds = @sounds[state.name]?set
            sound = h.random(sounds)
            sound.play()
            
        game.on 'del', (state, point) ~>
          if sounds = @sounds[state.name]?del
            sound = h.random(sounds)
            sound.play()

        game.on 'sound', (state, sound) ->
          if sound = @sounds[state.name]?[sound] then sound.play()
            
        @music = new howler.Howl urls: ['/sounds/music.mp3']
        game.once 'tick', ~>
          @music.play!
          game.once 'end', ~> @music.fadeOut 0, 1000, ~> @music.stop!


