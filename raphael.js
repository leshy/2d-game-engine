// Generated by CoffeeScript 1.8.0
(function() {
  var $, Backbone, Color, DirectionPainter, GameView, Image, MetaPainter, OrientationPainter, Raphael, RaphaelPainter, Sprite, View, coordsDecorator, decorate, decorators, helpers, v, validator, _,
    __slice = [].slice;

  _ = require('underscore');

  helpers = require('helpers');

  Backbone = require('backbone4000');

  validator = require('validator2-extras');

  v = validator.v;

  decorators = require('decorators');

  decorate = decorators.decorate;

  $ = require('jquery-browserify');

  View = require('./views');

  Raphael = require('raphael-browserify');

  coordsDecorator = function(targetf, coords) {
    if (!coords) {
      coords = this.gameview.translate(this.state.point.coords());
    }
    return targetf.call(this, coords);
  };

  GameView = exports.GameView = View.GameView.extend4000({
    initialize: function() {
      var calculateSizes, el;
      el = this.get('el');
      this.paper = Raphael(el.get(0), "100%", "100%");
      window.paper = this.paper;
      calculateSizes = (function(_this) {
        return function() {
          var elHeight, elWidth, gameHeight, gameWidth, sizex, sizey;
          elHeight = $(_this.paper.canvas).height();
          elWidth = $(_this.paper.canvas).width();
          gameHeight = _this.game.get('height');
          gameWidth = _this.game.get('width');
          sizey = Math.floor(elHeight / gameHeight);
          sizex = Math.floor(elWidth / gameWidth);
          if (sizex > sizey) {
            _this.size = sizey;
          } else {
            _this.size = sizex;
          }
          console.log("elHeight: ", elHeight, gameHeight, _this.size);
          console.log("elWidth: ", elWidth, gameWidth, _this.size);
          _this.size_offsetx = Math.floor((elWidth - (_this.size * gameWidth)) / 2);
          return _this.size_offsety = Math.floor((elHeight - (_this.size * gameHeight)) / 2);
        };
      })(this);
      calculateSizes();
      this.zMarkers = {};
      return this.on('definePainter', (function(_this) {
        return function(painter) {
          var forwardMarker, marker, zindex, _findForwardMarker;
          if (painter.prototype.zindex == null) {
            return;
          }
          zindex = painter.prototype.zindex;
          _findForwardMarker = function(marker) {
            var sorted;
            sorted = _.sortBy(_this.zMarkers, function(sortMarker, index) {
              return index;
            });
            return _.find(sorted, function(checkMarker) {
              return checkMarker.index > marker.index;
            });
          };
          if (!_this.zMarkers[zindex]) {
            _this.zMarkers[zindex] = marker = $("<marker index='" + zindex + "'></marker>");
            marker.index = zindex;
            if (!(forwardMarker = _findForwardMarker(marker))) {
              $(_this.paper.canvas).append(marker);
            } else {
              forwardMarker.before(marker);
            }
          }
          return console.log("DEFINEPAINTER", painter.prototype.name, painter.prototype.zindex);
        };
      })(this));
    },
    translate: function(coords) {
      return [this.size_offsetx + (coords[0] * this.size), this.size_offsety + (coords[1] * this.size)];
    }
  });

  RaphaelPainter = View.Painter.extend4000({
    draw: function(point) {
      var _ref;
      if (((_ref = this.state) != null ? _ref.mover : void 0) && this.rendering) {
        return this.rendering.toFront();
      }
      return this.render(this.gameview.translate(point.coords()), this.gameview.size);
    }
  });

  Image = exports.Image = RaphaelPainter.extend4000({
    offset: [0, 0],
    size: [1, 1],
    animate: function() {
      var animation;
      if (this.animating) {
        this.stopAnimate();
      }
      this.animating = true;
      animation = {};
      if (this.state.direction.x) {
        animation.x = this.rendering.attrs.x + this.state.direction.x * this.state.speed * this.cellSize * 100;
      }
      if (this.state.direction.y) {
        animation.y = this.rendering.attrs.y + this.state.direction.y * this.state.speed * this.cellSize * 100;
      }
      this.animation = this.rendering.animate(animation, this.state.point.game.tickspeed * 100);
      return this.ticker = setInterval(((function(_this) {
        return function() {
          _this.rendering.node.style.display = 'none';
          _this.rendering.node.offsetHeight;
          return _this.rendering.node.style.display = 'block';
        };
      })(this)), 15);
    },
    stopAnimate: function() {
      this.animating = false;
      clearInterval(this.ticker);
      return this.rendering.stop();
    },
    render: function(coords, cellSize) {
      var c, size, src, _ref, _ref1, _ref2, _ref3;
      if (c = (_ref = this.state) != null ? (_ref1 = _ref.point) != null ? _ref1.coords() : void 0 : void 0) {
        coords = this.gameview.translate(c);
      }
      if (!coords) {
        coords = this.coords;
      } else {
        this.coords = coords;
      }
      if (!cellSize) {
        cellSize = this.cellSize;
      } else {
        this.cellSize = cellSize;
      }
      if ((_ref2 = this.state) != null ? _ref2.mover : void 0) {
        console.log('coords', coords, this.cellSize, this.state.coordinates);
        coords = helpers.squish(coords, this.state.coordinates, function(coord, subCoord) {
          return Math.round(coord + (cellSize * (subCoord - 0.5)));
        });
      }
      coords = helpers.squish(coords, this.offset, function(coord, offset) {
        if (!offset) {
          return coord;
        }
        return coord + (offset * cellSize);
      });
      size = helpers.squish([cellSize, cellSize], this.size, function(size, cell) {
        return size * cell;
      });
      if (!this.rendering) {
        this.rendering = this.gameview.paper.image(src = this.getpic(), coords[0], coords[1], size[0], size[1]);
        if (this.rotation) {
          this.rendering.rotate(this.rotation);
        }
        if (this.zindex != null) {
          this.gameview.zMarkers[this.zindex].after(this.rendering);
        } else {
          this.rendering.toBack();
        }
        if ((_ref3 = this.state) != null ? _ref3.mover : void 0) {
          this.on('remove', (function(_this) {
            return function() {
              var _ref4, _ref5;
              if ((_ref4 = _this.rendering) != null) {
                _ref4.stop();
              }
              if ((_ref5 = _this.rendering) != null) {
                _ref5.remove();
              }
              return clearInterval(_this.ticker);
            };
          })(this));
        }
        this.on('remove', (function(_this) {
          return function() {
            if (_this.rendering) {
              _this.rendering.remove();
              return delete _this.rendering;
            }
          };
        })(this));
      }
      if (!this.state) {
        return;
      }
      if (this.rendering.attrs.x !== coords[0] || this.rendering.attrs.y !== coords[1]) {
        this.move(coords);
      }
      if (this.state.speed && !this.state.direction.stop()) {
        return this.animate();
      } else {
        return this.stopAnimate();
      }
    },
    getpic: function() {
      return '/pic/' + (this.pic || this.name) + '.png';
    },
    move: function(coords) {
      console.log('need to move rendering to new coords', coords);
      window.rendering = this.rendering;
      this.rendering.attr({
        x: coords[0],
        y: coords[1]
      });
      this.rendering.node.style.display = 'none';
      this.rendering.node.offsetHeight;
      return this.rendering.node.style.display = 'block';
    },
    images: function() {
      return [this.getpic()];
    }
  });

  Sprite = exports.Sprite = Image.extend4000({
    initialize: function() {
      this.frame_pics = [];
      _.times(this.frames, (function(_this) {
        return function(frame) {
          return _this.frame_pics.push('/pic/' + (_this.pic || _this.name) + frame + ".png");
        };
      })(this));
      if (this.frame === void 0) {
        this.frame = 0;
      }
      console.log('init sprite with frame', this.frame);
      if (this.gameview) {
        this.tick();
      }
      return this.on('remove', (function(_this) {
        return function() {
          return _this.stopListening();
        };
      })(this));
    },
    getpic: function() {
      return this.frame_pics[this.frame];
    },
    tick: function() {
      this.scheduleTick();
      if (!this.rendering) {
        return;
      }
      if (this.frame > this.frame_pics.length - 1) {
        if (this.once) {
          this.stopListening();
          return;
        }
        this.frame = 0;
      }
      this.rendering.attr({
        src: this.getpic()
      });
      return this.frame++;
    },
    scheduleTick: function() {
      if (this.speed) {
        return this["in"](Math.floor(1 / this.speed), (function(_this) {
          return function() {
            return _this.tick();
          };
        })(this));
      } else {
        return this.nextTick((function(_this) {
          return function() {
            return _this.tick();
          };
        })(this));
      }
    },
    images: function() {
      return this.frame_pics;
    }
  });

  Color = exports.Color = RaphaelPainter.extend4000({
    render: decorate(coordsDecorator, function(coords) {
      this.rendering = this.gameview.paper.rect(coords[0], coords[1], this.gameview.size, this.gameview.size).attr({
        'opacity': .5,
        'stroke-width': 1,
        stroke: this.color,
        fill: this.color
      });
      return this.on('remove', (function(_this) {
        return function() {
          if (_this.rendering) {
            _this.rendering.remove();
            return delete _this.rendering;
          }
        };
      })(this));
    }),
    move: decorate(coordsDecorator, function(coords) {
      return this.rendering.attr({
        x: coords[0],
        y: coords[1]
      });
    })
  });

  MetaPainter = exports.MetaPainter = RaphaelPainter.extend4000({
    initialize: function() {
      return this.on('remove', (function(_this) {
        return function() {
          return _this.repr.remove();
        };
      })(this));
    },
    reprChange: function() {
      var cls, oldRepr;
      cls = this.decideRepr();
      if (this.repr.constructor !== cls) {
        oldRepr = this.repr;
        this.repr.remove();
        this.repr = new cls({
          gameview: this.gameview,
          state: this.state
        });
        return this.render.apply(this, this.args);
      }
    },
    inherit: function() {
      return helpers.dictFromArray(['frame'], (function(_this) {
        return function(attr) {
          return [attr, _this[attr]];
        };
      })(this));
    },
    render: function() {
      var args, cls;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.trigger('render');
      this.args = args;
      if (!this.repr) {
        cls = this.decideRepr();
        this.repr = new cls(_.extend(this.inherit(), {
          gameview: this.gameview,
          state: this.state
        }));
      }
      return this.repr.render.apply(this.repr, args);
    },
    decideRepr: function() {
      throw 'override me';
    }
  });

  DirectionPainter = exports.DirectionPainter = MetaPainter.extend4000({
    decideRepr: function() {
      return this.reprs[(this.state.direction || this.state.get('direction')).string()];
    }
  });

  OrientationPainter = exports.OrientationPainter = MetaPainter.extend4000({
    decideRepr: function() {
      return this.reprs[this.state.get('direction').orientation()];
    }
  });

}).call(this);
