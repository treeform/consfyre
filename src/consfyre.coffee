# window and document holders
$win = $(window)
$doc = $(document)

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
ships.src = "/data/ships2.png"

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
  worldAABB = new b2AABB()
  s = 2000
  worldAABB.minVertex.Set -s, -s
  worldAABB.maxVertex.Set s, s
  # no gravity this is space!
  gravity = new b2Vec2(0, 0)
  doSleep = true
  world = new b2World(worldAABB, gravity, doSleep)
  return world

# creates a frictionless ball
createBall = (world, x, y, s) ->
  ballSd = new b2CircleDef()
  #console.log "body def", ballSd
  # does not seem to have bullet property
  #ballSd.bullet = true
  ballSd.density = 1.0
  ballSd.radius = s
  ballSd.restitution = 0.6
  ballSd.friction = 0.4
  ballBd = new b2BodyDef()
  ballBd.AddShape ballSd
  ballBd.position.Set x, y
  world.CreateBody ballBd

# creates a physical object from tile grid
# TODO: optimize the number of sub rectangles created
createGrid = (world, x, y, grid) ->
  # cube defintion, 0,0 to 1,1
  cube = [[0,0],[1,0],[1,1],[0,1]]
  # create compisle poly body
  polyBd = new b2BodyDef()
  # for each row tile grid
  for xrow, py in grid
    for e, px in xrow
      if e
        # if tile is defined
        # make a square at that location
        polySd1 = new b2PolyDef()
        polySd1.vertexCount = 4
        # user data is the tile we used
        polySd1.userData = e
        for p,i in cube
          polySd1.vertices[i].Set((p[0]+px)*16, (p[1]+py)*16)
        # set dencity of the tile
        polySd1.density = 1.0
        # add the tile to the composite shape
        polyBd.AddShape(polySd1)
  # set body position
  polyBd.position.Set(x,y)
  body = world.CreateBody(polyBd)
  # add a little friction to space
  body.m_linearDamping = 0.99
  body.m_angularDamping = 0.99
  return body

box = undefined


draw = ->
  # get canvas
  fg_canvas = $fg[0]
  # fast clear
  resize()
  # get context
  ctx = fg_canvas.getContext('2d')

  ctx.save()
  camera_x = -box.m_position.x+width/2
  camera_y = -box.m_position.y+height/2
  ctx.translate(camera_x, camera_y)

  # follow linked list of bodies
  body = world.m_bodyList
  while body != null

    # save and tranlsate body into local cordiates
    ctx.save()
    ctx.translate(body.m_position0.x, body.m_position0.y)
    ctx.rotate(body.m_rotation)

    # follow each shape in a linked list
    sh = body.m_shapeList
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
        # get module at this tile
        module = sh.m_userData
        ctx.save()
        # tiles have location position
        ctx.translate(sh.m_localCentroid.x, sh.m_localCentroid.y)
        # compute plate cordiantes
        tx = module.tile[0]*16
        ty = module.tile[1]*16
        # draw image
        ctx.drawImage(ships, tx,ty, 16,16,  -8,-8, 16,16)
        # restore the ctx
        ctx.restore()

        # follow onto next sub object
        sh = sh.m_next

    ctx.restore()

    # simulate all modules
    sh = body.m_shapeList
    while sh
      # get module at this tile
      module = sh.m_userData
      if module
        # if there is a module simulate it
        module.sim(body,sh)
      # next shape to look at
      sh = sh.m_next

    # follow onto next object
    body = body.m_next

  world.Step(1/60, 1);
  ctx.restore()
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
  else if d == S
    new b2Vec2(-mag, 0)
  else
    throw "invalid direction #{d}"

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
    return

  force: (body, x, y, fx,fy) ->
    body.WakeUp()
    # find global tile position
    v = new b2Vec2(x,y)
    v.MulM(box.sMat0)
    v.Add(box.m_position)
    # rotate force relative to ship
    f = new b2Vec2(fx,fy)
    f.MulM(box.sMat0)
    # apply the for to the ship
    body.ApplyImpulse(f, v)

    # draw the debug force vectors
    fire = new b2Vec2(-fx,-fy/100)
    fire.MulM(box.sMat0)
    ctx.beginPath()
    ctx.arc(v.x, v.y,5,0,Math.PI*2,true)
    ctx.moveTo(v.x, v.y)
    ctx.lineTo(v.x+fire.x, v.y+fire.y)
    ctx.closePath()
    ctx.strokeStyle = "red"
    ctx.stroke()

  sim: (body, shape) ->
    if keys[@key]
      # my key is activated
      vec = dir(@direction, -10000)
      at_x = shape.m_localCentroid.x
      at_y = shape.m_localCentroid.y
      @force(body, at_x, at_y, vec.x, vec.y)

# Shoot projectiles based on key press
# can face 4 directions
class Gun extends Module
  tile: [3, 0]
  key: null
  constructor: (@direction, @key) ->
    return

  sim: (body, shape) ->
    if keys[@key]
      # my key is activated - fire
      vec = dir(@direction, -10000)
      # find current tile location
      at_x = shape.m_localCentroid.x
      at_y = shape.m_localCentroid.y
      p = new b2Vec2(at_x, at_y)
      # mow up the bullets a little bit
      p.Add(dir(@direction, 32))
      # rotate it based on ship matrix
      p.MulM(box.sMat0)
      # translate it relative to ship
      p.Add(box.m_position)
      # create the bullet objects
      bullet = createBall(world, p.x, p.y, 8)
      # make sure bullet expires after 1 second
      setTimeout((-> world.DestroyBody(bullet)), 1000)
      # find the direciton of the tile
      f = dir(@direction, 600000)
      # rotate it relative to ship
      f.MulM(box.sMat0)
      # apply for to bullet
      bullet.ApplyImpulse(f, p)


# init function
$ ->
  $fg = $('#fg')

  world = createWorld()

  # module shortcuts
  R = -> new Rock()
  H = -> new Hull()
  C = -> new Cargo()
  E = (d,k) -> new Engine(d, k)
  G = (d,k) -> new Gun(d, k)

  # ship definition
  ship = [
    [E(N, 39), 0,       E(N,38), 0,       E(N,37)]
    [H(),      H(),     C(),     H(),     H()]
    [0,        H(),     C(),     H(),     0]
    [0,        0,       C(),     0,       0]
    [0,        G(S,32), E(S,40), G(S,32), 0]
  ]

  box = createGrid(world, 0,0, ship)

  for i in [0...20]
    z = 400
    x = r(-z,z)
    y = r(-z,z)
    xs = r(10,100)
    ys = r(10,100)
    # rock definition
    rock = [
      [0,   R(), R(), R(), 0]
      [R(), R(), R(), R(), R()]
      [R(), R(), 0,   R(), R()]
      [R(), R(), R(), R(), R()]
      [0,   R(), 0,   R(), 0]
    ]
    createGrid world, x, y, rock

  console.log "world", world, "box", box

  draw()  