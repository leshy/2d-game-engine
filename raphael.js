// Generated by CoffeeScript 1.8.0
(function() {
  var $, Backbone, Color, DirectionPainter, GameView, Image, MetaPainter, OrientationPainter, RaphaelPainter, Sprite, View, coordsDecorator, decorate, decorators, helpers, raphael, v, validator, _,
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

  raphael = require('raphael-browserify');

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
      this.paper = raphael(el.get(0), "100%", "100%");
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
      return calculateSizes();
    },
    translate: function(coords) {
      return [this.size_offsetx + (coords[0] * this.size), this.size_offsety + (coords[1] * this.size)];
    }
  });

  RaphaelPainter = View.Painter.extend4000({
    draw: function(point) {
      var _ref;
      if (((_ref = this.state) != null ? _ref.mover : void 0) && this.rendering) {
        return;
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
      this.animation = this.rendering.animate(animation, 5000);
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
      var c, size, src, _applyOffset, _ref, _ref1, _ref2, _ref3;
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
      _applyOffset = (function(_this) {
        return function(coords) {
          return coords = helpers.squish(coords, _this.offset, function(coord, offset) {
            if (!offset) {
              return coord;
            }
            return coord + (offset * cellSize);
          });
        };
      })(this);
      coords = _applyOffset(coords);
      size = helpers.squish([cellSize, cellSize], this.size, function(size, cell) {
        return size * cell;
      });
      if (!this.rendering) {
        this.rendering = this.gameview.paper.image(src = this.getpic(), coords[0], coords[1], size[0], size[1]);
        this.rendering.toFront();
        if (this.rotation) {
          this.rendering.rotate(this.rotation);
        }
        if ((_ref3 = this.state) != null ? _ref3.mover : void 0) {
          this.state.on('movementChange', (function(_this) {
            return function() {
              console.log('movementchange rerender');
              return _this.render();
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
        return;
      }
      if (!this.state) {
        return;
      }
      if (this.rendering.attrs.x !== coords[0] || this.rendering.attrs.y !== coords[1]) {
        this.move(coords);
      }
      if (this.state.speed && !this.state.direction.stop()) {
        this.animate();
      } else {
        this.stopAnimate();
      }
      return this.rendering.toFront();
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
      this.frame = 0;
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
    render: function() {
      var args, cls;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!this.repr) {
        cls = this.decideRepr();
        this.repr = new cls({
          gameview: this.gameview,
          state: this.state
        });
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
