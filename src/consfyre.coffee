# window and document holders
$win = $(window)
$doc = $(document)

# our current size
width = 1000
height = 600

# canvas holder
$fg = undefined

world = undefined

keys = {}

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

resize = ->
  # resize the canvas to match window
  width = $win.width()
  height = $win.height()
  $fg.attr "width", width
  $fg.attr "height", height

createWorld = ->

  worldAABB = new b2AABB()
  s = 20000
  worldAABB.minVertex.Set -s, -s
  worldAABB.maxVertex.Set s, s
  # no gravity this is space!
  gravity = new b2Vec2(0, 0)
  doSleep = true
  world = new b2World(worldAABB, gravity, doSleep)
  return world

createBall = (world, x, y, s) ->
  ballSd = new b2CircleDef()
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
#

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
  ctx.translate(-box.m_position.x+width/2, -box.m_position.y+height/2)
  # draw some thing
  ctx.fillStyle = "white"

  #ctx.fillRect(100,100,100,100)


  body = world.m_bodyList
  while body != null

    ctx.save()
    ctx.translate(body.m_position0.x, body.m_position0.y)
    ctx.rotate(body.m_rotation)

    ctx.lineWidth=3
    ctx.fillStyle = "#777777"

    if body.IsSleeping()
      ctx.fillStyle = "#377777"
    if body.IsFrozen()
      ctx.fillStyle = "#373777"
    if body.IsFrozen()
      ctx.fillStyle = "#373737"

    sh = body.m_shapeList

    if sh and sh.m_radius
        ctx.beginPath()
        ctx.arc(0,0,sh.m_radius,0,Math.PI*2,true)
        ctx.lineTo(0,0)
        ctx.closePath()
        ctx.fill()
        ctx.strokeStyle = "#BBBBBB"
        ctx.stroke()
    else
      # draw a grid of tiles
      # keep drawing the tiles till we run out
      while sh
        ctx.save()
        # tiles have location position
        ctx.translate(sh.m_localCentroid.x, sh.m_localCentroid.y)
        verts = sh.m_coreVertices
        ctx.drawImage(ships, (sh.m_userData-1)*16, 0, 16,16,  -8,-8, 16,16)
        ctx.restore()
        sh = sh.m_next

    ctx.restore()
    body = body.m_next


  # apply impulse
  force = (x, y, fx,fy) ->
    box.WakeUp()

    v = new b2Vec2(x,y)
    v.MulM(box.sMat0)
    v.Add(box.m_position)

    f = new b2Vec2(fx,fy)
    f.MulM(box.sMat0)

    box.ApplyImpulse(f, v)

    fire = new b2Vec2(-fx,-fy/100)
    fire.MulM(box.sMat0)

    ctx.beginPath()
    ctx.moveTo(v.x, v.y)
    ctx.lineTo(v.x+fire.x, v.y+fire.y)
    ctx.closePath()
    ctx.strokeStyle = "red"
    ctx.stroke()


  # engine contolr
  if keys[38]
    force(0,-32, 0, 10000)

  if keys[37]
    force(-32,-32, 0, 8000)
  if keys[39]
    force(32,-32, 0, 8000)

  if keys[40]
    force(0,20, 0, -5000)

  if keys[32]
    # fire
    p = new b2Vec2(0, 60)
    p.MulM(box.sMat0)
    p.Add(box.m_position)
    ball = createBall(world, p.x, p.y, 10)
    f = new b2Vec2(0, 1000000)
    f.MulM(box.sMat0)
    ball.ApplyImpulse(f, p)
    console.log ball

  world.Step(1/60, 1);
  #console.log "step"



  ctx.restore()
  # request frame
  requestFrame(draw)


$doc.keydown (e) ->
  console.log e.which, keys
  keys[e.which] = true

$doc.keyup (e) ->
  keys[e.which] = false


# init function
$ ->
  $fg = $('#fg')

  world = createWorld()

  ship = [
    [3,0,0,0,3]
    [1,1,2,1,1]
    [0,1,2,1,0]
    [0,0,2,0,0]
    [0,1,1,1,0]
  ]

  box = createGrid(world, 0,0, ship)

  for i in [0...50]
    z = 1000
    x = r(-z,z)
    y = r(-z,z)
    xs = r(10,100)
    ys = r(10,100)

    rock = [
      [0,1,1,1,0]
      [1,1,1,1,1]
      [1,1,0,1,1]
      [1,1,1,1,1]
      [0,1,0,1,0]
    ]
    createGrid world, x, y, rock

  console.log "world", world, "box", box



  draw()  