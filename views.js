(function() {
  var BackboneB, helpers, raphael;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  BackboneB = require('backbone-browserify');
  helpers = require('helpers');
  raphael = require('raphael-browserify');
  exports.GameView = BackboneB.View.extend({
    initialize: function() {
      this.paper = raphael(this.el, "100%", "100%");
      this.size = Math.floor(this.paper.canvas.clientHeight / this.model.get('height')) - 2;
      this.spacing = 0;
      this.model.on('change:data', this.redraw.bind(this));
      this.initdraw();
      return this.redraw();
    },
    initdraw: function() {
      this.repr = new ViewField({
        width: this.model.get('width'),
        height: this.model.get('height')
      });
      return this.model.each(__bind(function(point) {
        var c;
        c = this.coords(point);
        this.paper.rect(c[0], c[1], this.size, this.size, 0).attr({
          'opacity': 0.4,
          'stroke-width': 1,
          stroke: 'black'
        });
        return this.drawpoint(point);
      }, this));
    },
    drawpoint: function(point) {
      var stuff;
      stuff = point.stuff();
      if (!(stuff != null)) {
        return;
      }
      return this.repr.setPoint(point, this.getrepr(point, stuff));
    },
    getrepr: function(point, stuff) {
      var c, reprs;
      c = this.coords(point);
      reprs = {
        1: 'red',
        2: 'blue',
        3: 'green',
        4: 'orange'
      };
      return this.paper.rect(c[0] + 3, c[1] + 3, this.size - 3, this.size - 3, 0).attr({
        'opacity': 1.0,
        'stroke-width': 1,
        stroke: reprs[stuff]
      });
    },
    coords: function(point) {
      return [5 + (point.x * (this.size + this.spacing)), 5 + (point.y * (this.size + this.spacing))];
    },
    redraw: function() {
      return true;
    }
  });
}).call(this);
