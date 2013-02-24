_ = require 'underscore'
Backbone = require 'backbone4000'
preloadjs = require 'PreloadJS-browserify'
validator = require 'validator2-extras'; v = validator.v
views = require './views'

exports.preloaderMixin = validator.ValidatedModel.extend4000
#    superValidator: v().Constructor(views.GameView)
    validator:
        autopreload: v().Default(true).Boolean(), # start requesting as soon as you have an element in a queue
        lazypreload: v().Default(false).Boolean() # load view images when view is first shown (useful for large games)

    initialize: ->
        @preloadQueue = new preloadjs.LoadQueue(true) # init preload queue

        @on 'definePainter', (painterclass) => @preloadPainter(painterclass) # hook on definepainter
        
        _.map @painters, (painterclass) => @preloadPainter(painterclass) # preload existing painters
        
#    preloadPainter: (painterclass) -> true
        painter = new painterclass()
        #_.map painter.images(), (image) => console.log 'loading',image; @preloadQueue.loadFile image
            
