game = require './models'

exports.field = 
    getIndex: (test) ->
        f = new game.Field {width:25,height:25}
        test.done()
    
    setget: (test) ->
        f = new game.Field {width:25,height:25}
        point1 = f.setPoint [3,4],'hi'
        point2 = f.setPoint [8,9],'hi2'

        test.equals f.stuff([3,4]), 'hi'
        test.equals point1.stuff(), 'hi'
        test.equals point2.stuff(), 'hi2'
        test.equals f.stuff([8,9]), 'hi2'
        test.equals f.stuff([8,10]), undefined
        test.done()


