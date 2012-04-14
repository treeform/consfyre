# window and document holders
$win = $(window)
$doc = $(document)


b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape

# our current size
width = 1000
height = 600

# canvas holder
$fg = undefined

world = undefined
ctx = undefined

# keys are nothing more then a hash table
# with up and down state
# this allows modules to look them up during simulation
# instead of sending descrete events
keys = {}
# shift keys are keys pressed with shift
# shift allows keys to stick untill pressed and relased again
shift_keys = {}
$doc.keydown (e) ->
  #console.log e, keys
  keys[e.which] = true
  shift_keys[e.which] = e.shiftKey

$doc.keyup (e) ->
  if not shift_keys[e.which]
    keys[e.which] = false

# loader
ships = new Image()
ships.src = "./data/ships2.png"

fire1 = new Audio()
fire1.src = './data/fire1.wav'

thruster1 = new Audio()
thruster1.src = './data/thruster1.wav'

intro = new Audio()
intro.src = './data/hallow-drone-by-dj-chronos.ogg'

# random number from a to b
r = (a, b) -> Math.random()*(b-a) + a

# define better animaiton loop
requestFrame =
  window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  (cb) -> window.setTimeout(cb, 1000/60)

# resize the canvas to match window
# called mainly to clear the window
resize = ->
  width = $win.width()
  height = $win.height()
  $fg.attr "width", width
  $fg.attr "height", height

# creates a world
createWorld = ->
  worldAABB = new Box2D.Collision.b2AABB()
  s = 2000
  #worldAABB.minVertex.Set -s, -s
  #worldAABB.maxVertex.Set s, s
  # no gravity this is space!
  gravity = new b2Vec2(0, 0)
  doSleep = true
  world = new Box2D.Dynamics.b2World(worldAABB, gravity, doSleep)
  return world

# creates a frictionless ball
createBall = (world, x, y, s, d) ->
  bodyDef = new b2BodyDef()
  bodyDef.type = b2Body.b2_dynamicBody;
  fixDef = new b2FixtureDef()
  fixDef.density = 1.0;
  fixDef.friction = 0.5;
  fixDef.restitution = 0.2;
  fixDef.shape = new b2CircleShape(s)
  bodyDef.position.x = x;
  bodyDef.position.y = y;
  body = world.CreateBody(bodyDef)
  body.CreateFixture(fixDef)
  console.log body
  return body


# creates a physical object from tile grid
# TODO: optimize the number of sub rectangles created
createGrid = (world, ship) ->
  # cube defintion, 0,0 to 1,1
  cube = [[0,0],[1,0],[1,1],[0,1]]
  # create compisle poly body
  polyBd = new b2BodyDef()
  polyBd.userData = ship

  #polyBd.type = b2Body.b2_dynamicBody

  # set body position
  polyBd.position.Set(ship.x, ship.y)
  body = world.CreateBody(polyBd)

  # for each row tile grid
  for xrow, py in ship.grid
    start_px = null
    for e, px in xrow

      make = (end_px) ->
        #console.log "end", end_px, py
        # if tile is defined
        # make a square at that location
        fixDef = new b2FixtureDef()

        fixDef.shape = new b2PolygonShape()
        # user data is the tile we used
        fixDef.userData = [start_px, py, end_px]

        points = [
          new b2Vec2((start_px)*16, (py)*16),
          new b2Vec2((end_px)*16, (py)*16),
          new b2Vec2((end_px)*16, (py+1)*16),
          new b2Vec2((start_px)*16, (py+1)*16)
        ]

        fixDef.shape.SetAsArray(points, 4)
        # set dencity of the tile
        fixDef.density = 1.0
        # add the tile to the composite shape
        body.CreateFixture(fixDef)

        start_px = null


      if e and start_px == null
        #console.log "start", px, py
        start_px = px

      if not e and start_px != null
        make(px)
    if start_px != null
      make(px)


  # add a little friction to space
  body.m_linearDamping = 0.99
  body.m_angularDamping = 0.99
  body.m_mass = 1

  #console.log "made", body.m_userData
  ship.body = body
  return body

box = undefined


draw_thing = (body, thing) ->

    # save and tranlsate body into local cordiates
    ctx.save()
    pos = body.GetPosition()
    ctx.translate(pos.x, pos.y)
    ctx.rotate(body.GetAngle())

    console.log body

    blah()




    ###
    # follow each shape in a linked list
    sh = body.m_fixtureList
    if sh and sh.m_radius
      # draw a debug circle
      ctx.beginPath()
      ctx.arc(0,0,sh.m_radius,0,Math.PI*2,true)
      ctx.lineTo(0,0)
      ctx.closePath()
      ctx.lineWidth= 1
      ctx.fillStyle = "#777777"
      ctx.fill()
      ctx.strokeStyle = "#BBBBBB"
      ctx.stroke()
    else
      # draw a grid of tiles
      # keep drawing the tiles till we run out
      while sh

        # get module slice at this shape
        [start_x, at_y, end_x] = sh.GetUserData()

        for at_x in [start_x...end_x]
          #console.log at_y, at_x
          module = thing.grid[at_y][at_x]

          # compute plate cordiantes
          tx = module.tile[0]*16
          ty = module.tile[1]*16

          # save tile's position
          m_x = (at_x - (start_x+end_x-1)/2)*16
          module.x = m_x + sh.m_shape.m_centroid.x
          module.y = + sh.m_shape.m_centroid.y
          ctx.save()
          ctx.translate(module.x, module.y)

          # draw image
          if module.direction == S
            # nothing
          else if module.direction == N
            ctx.rotate(180/180*Math.PI)
          else if module.direction == E
            ctx.rotate(-90/180*Math.PI)
          else if module.direction == W
            ctx.rotate(90/180*Math.PI)

          #console.log "at", module.x, module.y
          ctx.drawImage(ships, tx,ty, 16, 16, -8, -8, 16,16)
          ctx.restore()



        # follow onto next sub object
        sh = sh.m_next
    ###
    ctx.restore()

    thing.sim()


draw = ->



  # get canvas
  fg_canvas = $fg[0]
  # fast clear
  resize()
  # get context
  ctx = fg_canvas.getContext('2d')


  ctx.save()
  pos = box.GetPosition()
  camera_x = -pos.x+width/2
  camera_y = -pos.y+height/2
  ctx.translate(camera_x, camera_y)

  world.DrawDebugData();


  ctx.strokeStyle = "#040"
  for x in [-2...2]
    for y in [-2...2]
      ctx.strokeRect(x*500, y*500, 500-5, 500-5)

  console.log "list", world.GetBodyList()
  # follow linked list of bodies
  for body in world.GetBodyList()
    thing = body.GetUserData()
    if thing
      draw_thing(body, thing)
    else
      console.log body
      blah()

  world.Step(1/60, 1);
  ctx.restore()

  ctx.font = "16px EarthMomma"
  ctx.fillStyle = "#FFF"
  ctx.fillText("Consfyre .01a", 32, 32)
  ctx.fillStyle = "#AAA"
  ctx.font = "8px EarthMomma"
  ctx.fillText("Construct, Conspire, Crossfire", 32, 32+12);


  fire1._played = false

  # done request next frame
  requestFrame(draw)


# define directions
[S, N, E, W] = "SNEW"
dir = (d, mag) ->
  if d == S
    new b2Vec2(0, mag)
  else if d == N
    new b2Vec2(0, -mag)
  else if d == E
    new b2Vec2(mag, 0)
  else if d == W
    new b2Vec2(-mag, 0)
  else
    throw "invalid direction #{d}"


class Thing
  constructor: (@x, @y, @grid) ->
    console.log "made thing"

  sim: ->
    # simulate all modules
    for row, py in @grid
      for module, px in row
        if module
          # if there is a module simulate it
          module.sim(@body)


class Projectile
  energy = 10

  sim: ->
    "nothing"

# base moudle, all modules derive from this
class Module
  # tile is the x,y position on the ship tile plate
  tile: [0,0]
  # how much health the module got before total distructions
  health: 100
  # how heavy the module is
  density: 1
  # where is the module facing
  direction: S

  sim: ->

class Rock extends Module
  tile: [16, 25]

class Hull extends Module
  tile: [0, 0]

class Cargo extends Module
  tile: [1, 0]

# applies force to the ship when key is pressed
# can face 4 directions
class Engine extends Module
  tile: [2, 0]
  # engines are controls by keys
  # which key controls this engine
  key: null
  constructor: (@direction, @key) ->
    @off = true
    return

  force: (body, x, y, fx,fy) ->
    body.SetAwake(true)
    console.log body
    # find global tile position
    v = body.GetWorldPoint(new b2Vec2(x,y))
    # rotate force relative to ship
    f = body.GetWorldVector(new b2Vec2(fx*100,fy*100))
    # apply the for to the ship
    console.log "v:", v.x, v.y, "f", f.x, f.y
    body.ApplyImpulse(f, v)

    # draw the debug force vectors
    fire = new b2Vec2(-fx / 100,-fy / 100)
    fire = body.GetWorldVector(new b2Vec2(-fx / 100, -fy / 100))
    ctx.beginPath()
    ctx.arc(v.x, v.y,5,0,Math.PI*2,true)
    ctx.moveTo(v.x, v.y)
    ctx.lineTo(v.x+fire.x, v.y+fire.y)
    ctx.closePath()
    ctx.strokeStyle = "red"
    ctx.stroke()

  sim: (body) ->
    if keys[@key]
      # my key is activated
      vec = dir(@direction, -10000)
      #at_x = shape.m_localCentroid.x
      #at_y = shape.m_localCentroid.y
      @force(body, @x, @y, vec.x, vec.y)

      #if @off
      #  t = thruster1.cloneNode(true)
      #  t.volume = .1
      #  t.play()
      #  @off = false
    else
      @off = true



# Shoot projectiles based on key press
# can face 4 directions
class Gun extends Module
  tile: [3, 0]
  key: null
  constructor: (@direction, @key) ->
    return

  sim: (body) ->
    if keys[@key]
      # my key is activated - fire
      f = body.GetWorldVector(dir(@direction, -10000))
      p = body.GetWorldPoint(new b2Vec2(@x,@y))

      # create the bullet objects
      bullet = createBall(world, p.x, p.y, 8, .2)
      bullet.m_userData = new Projectile()

      # make sure bullet expires after 1 second
      setTimeout((-> world.DestroyBody(bullet)), 1000)

      # apply for to bullet
      bullet.ApplyImpulse(f, p)

# init function
$ ->

  #intro.play()

  $fg = $('#fg')

  world = createWorld()
  ###
  # module shortcuts
  R = -> new Rock()
  H = -> new Hull()
  C = -> new Cargo()
  E = (d,k) -> new Engine(d, k)
  G = (d,k) -> new Gun(d, k)


  # ship definition
  ship = new Thing 0, 0, [
    [E(W, 39), 0,       E(N,38), 0,       E(E,37)]
    [H(),      H(),     C(),     H(),     H()]
    [0,        H(),     C(),     H(),     0]
    [0,        0,       C(),     0,       0]
    [0,        G(S,32), E(S,40), G(S,32), 0]
  ]

  box = createGrid(world, ship)

  for i in [0...1]
    z = 1000
    x = r(-z,z)
    y = r(-z,z)
    xs = r(10,100)
    ys = r(10,100)
    # rock definition
    rock = new Thing x, y, [
      [0,   R(), R(), R(), 0]
      [R(), R(), R(), R(), R()]
      [R(), R(), R(),   R(), R()]
      [R(), R(), R(), R(), R()]
      [0,   R(), R(),   R(), 0]
    ]
    createGrid world, rock
  ###


  fixDef = new b2FixtureDef();
  fixDef.density = 1.0;
  fixDef.friction = 0.5;
  fixDef.restitution = 0.2;

  bodyDef = new b2BodyDef();

  #create some objects
  bodyDef.type = b2Body.b2_dynamicBody;
  for i in [0...10]
    if Math.random() > 0.5
      fixDef.shape = new b2PolygonShape();
      fixDef.shape.SetAsBox(
        Math.random() + 0.1 #half width
        Math.random() + 0.1 #half height
      )
    else
      fixDef.shape = new b2CircleShape(Math.random() + 0.1) #radius

    bodyDef.position.x = Math.random() * 10;
    bodyDef.position.y = Math.random() * 10;
    body = world.CreateBody(bodyDef)
    body.CreateFixture(fixDef);
    box = body

  console.log "world", world, "box", box

  draw()

