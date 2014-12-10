(function() {
  var _;
  _ = require('underscore');
  _.extend(exports, require('./models'));
  _.extend(exports, require('./views'));
  _.extend(exports, require('./controler'));
  exports.Raphael = require('./raphael');
}).call(this);
