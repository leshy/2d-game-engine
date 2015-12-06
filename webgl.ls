require! {
  jquery: $
  helpers: h
  underscore: _
  three: THREE
  backbone4000: Backbone  
}
OrbitControls = require('three-orbit-controls')(THREE)

View = require './views'

GameView = exports.GameView = View.GameView.extend4000 do
  setLight: -> @light.position.set @camera.position.x, @camera.position.y, @camera.position.z
  render: ->
    window.gameView = @
    
    el = @get('el')
    @renderer = new THREE.WebGLRenderer( antialias: true, alpha: false )
    @renderer.setClearColor( 0x000000 )
    @renderer.shadowMapEnabled = true;
    @renderer.shadowMapType = THREE.PCFSoftShadowMap;
    @renderer.shadowMapSoft = true;

    @renderer.shadowCameraNear = 0.1;
    @renderer.shadowCameraFar = 100
    @renderer.shadowCameraFov = 90;

    @renderer.setSize( window.innerWidth, window.innerHeight );
    
    camera = @camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 100 );
    camera.position.set( 8.6, -5.5, 11 );
    camera.lookAt(new THREE.Vector3( 8.6, -5.5, 0 ))
    @el.append @renderer.domElement

    @scene = new THREE.Scene()
#    @scene.fog = new THREE.Fog( 0x59472b, 1000, 3000 );

        
    directionalLight = new THREE.DirectionalLight( 0xffffff, 0.8 );
    directionalLight.position.set( 100,100,100 );
    @scene.add( directionalLight );

              
    @scene.add new THREE.AmbientLight( 0xaaaaaa )

    addSL = ~> 
      spotLight = new THREE.SpotLight( 0xffffff );
      spotLight.position.set( 15, -15, 1 );

      spotLight.intensity = 5
      spotLight.castShadow = true;
      spotLight.shadowDarkness = 0.9
      spotLight.shadowCameraVisible = true;

      spotLight.shadowMapWidth = 1024;
      spotLight.shadowMapHeight = 1024;

      spotLight.shadowCameraNear = 500;
      spotLight.shadowCameraFar = 4000;
      spotLight.shadowCameraFov = 30;

      @scene.add spotLight

    #addSL!


        
#    light = @light = new THREE.SpotLight( 0xffffff, 1, 0, Math.PI / 2, 1 );
#    light.position.set( 10, -10, 4 );
#    light.target.position.set( -10, 10, 1 );
#    light.shadowCameraNear = true;
#    light.castShadow = true;
#    light.shadowCameraVisible = true;
    
#    @scene.add( light );

    controls = new OrbitControls( camera, @renderer.domElement );
    controls.enableDamping = true;
    controls.dampingFactor = 0.25;
    controls.enableZoom = true;
    controls.enableRotate = true;
    controls.target = new THREE.Vector3( 8.6, -5.5, 0 )

    render = ~>      
      controls.update();
      @renderer.render @scene, camera
      h.wait 25, -> requestAnimationFrame render
      
    render!
    
  translate: (coords) ->
    coords = _.clone(coords)
    coords[1] = - coords[1]
    coords.push 1
    coords


Painter = View.Painter.extend4000 do
  draw: (point) -> true
  
  remove: -> @gameview.scene.remove( @element );

exports.Cube = Painter.extend4000 do
  getPos: (point) ->
    
  draw: (point) ->
    if not @element
      
      opts = {}

      if @texture then opts.map = @texture
      if @bmap then opts.bumpMap = @bmap
      if @color then opts.color = @color
        
      shape = @shape or [ 1, 1, 1 ]
      geometry = new THREE.BoxGeometry shape[0], shape[1], shape[2]
      
      @element = new THREE.Mesh geometry, new THREE.MeshPhongMaterial( opts )
      if @shadow then @element.castShadow = true
      if @shadowR then @element.receiveShadow = true
      @gameview.scene.add @element


    position = @gameview.translate point.coords()
    if @offset then position = h.squish position, @offset, (c1,c2) -> c1 + c2
    
    @element.position.x = position[0]
    @element.position.y = position[1]
    @element.position.z = position[2]
    
