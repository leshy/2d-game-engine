_ = require 'underscore'
Backbone = require 'backbone4000'
preloadjs = require 'PreloadJS-browserify'
validator = require 'validator2-extras'; v = validator.v
views = require './views'

exports.preloaderMixin = validator.ValidatedModel.extend4000
#    superValidator: v().Constructor(views.GameView)
    validator:
        # start requesting as soon as you have an element in a queue
        autopreload: v().Default(true).Boolean(),
        # load view images when view is first shown (useful for large games)
        lazypreload: v().Default(false).Boolean() 

    initialize: ->
        @preloadQueue = new preloadjs.LoadQueue useXHR: true # init preload queue
    
        handleFileLoad = (event) ->
            event.result.style.visibility = 'hidden'
            if event.item.type is preloadjs.LoadQueue.IMAGE then $(document.body).append(event.result)
                
        @preloadQueue.addEventListener("fileload", handleFileLoad);

        @on 'definePainter', (painterclass) => @preloadPainter(painterclass) # hook on definepainter
        
        _.map @painters, (painterclass) => @preloadPainter(painterclass) # preload existing painters

    preloadPainter: (painterclass) ->
        painter = new painterclass()
        images = painter.images()
        _.map images, (image) => @preloadQueue.loadFile image


