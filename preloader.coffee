_ = require 'underscore'
Backbone = require 'backbone4000'
preloadjs = require 'PreloadJS-browserify'
validator = require 'validator2-extras'; v = validator.v
views = require './views'
helpers = require 'helpers'

exports.preloaderMixin = validator.ValidatedModel.extend4000
#    superValidator: v().Constructor(views.GameView)
    validator:
        # start requesting as soon as you have an element in a queue
        autopreload: v().Default(true).Boolean(),
        # load view images when view is first shown (useful for large games)
        lazypreload: v().Default(false).Boolean()

    initialize: ->
        @preloadQueue = new preloadjs.LoadQueue useXHR: false, loadNow: false # init preload queue

        handleFileLoad = (event) ->
            event.result.style.display = 'none'
            if event.item.type is preloadjs.LoadQueue.IMAGE
                $("#preload").append event.result

        @preloadQueue.on "fileload", handleFileLoad

        _.map @painters, (painterclass) => @preloadPainter(painterclass) # preload existing painters
        @on 'definePainter', (painterclass) => @preloadPainter(painterclass) # hook on definepainter

        if @get 'autopreload' then @preload()

    preload: (callback, callbackProgress) ->
        $('body').append("<div style='display: none;' id='#preload' />")
        @preloadQueue.load()
        @preloadQueue.on "complete", -> helpers.cbc callback
        if callbackProgress then @preloadQueue.on "progress", (event) ->
            callbackProgress event.progress

    preloadPainter: (painterclass) ->
        painter = new painterclass false
        images = painter.images()
        _.map images, (image) => @preloadQueue.loadFile image
