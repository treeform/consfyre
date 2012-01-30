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

createBox = (world, x, y, width, height, fixed) ->
  fixed = true  if typeof (fixed) is "undefined"
  boxSd = new b2BoxDef()
  boxSd.restitution = 0.6
  boxSd.friction = .3
  boxSd.density = 1.0  unless fixed

  boxSd.extents.Set width, height
  boxBd = new b2BodyDef()
  boxBd.AddShape boxSd
  boxBd.position.Set x, y
  body = world.CreateBody boxBd

  # add a little friction to space
  body.m_linearDamping = 0.99
  body.m_angularDamping = 0.99

  return body

createPoly = (world, x, y) ->
  polySd1 = new b2PolyDef()

  size = Math.floor(r(30, 100)) #add some randomness to it
  points = Math.floor(r(3,9))
  polySd1.vertexCount = points

  for i in [0...points]
    degree = (360/points)*i
    distance = r(size*.5, size*1.5)
    px = distance*Math.cos(Math.PI/180*degree)
    py = distance*Math.sin(Math.PI/180*degree)
    polySd1.vertices[i].Set(px, py)

  polySd1.localRotation = 0.3524 * Math.PI
  R1 = new b2Mat22(polySd1.localRotation)
  polySd1.localPosition = b2Math.b2MulMV(R1, new b2Vec2(30, 0))
  polySd1.density = 1.0

  polyBd = new b2BodyDef()
  polyBd.AddShape(polySd1)
  polyBd.position.Set(x,y)
  return world.CreateBody(polyBd)

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
    if body.m_shapeList
      sh = body.m_shapeList
      verts = sh.m_coreVertices

      ctx.lineWidth=3
      ctx.fillStyle = "#777777"

      if body.IsSleeping()
        ctx.fillStyle = "#377777"
      if body.IsFrozen()
        ctx.fillStyle = "#373777"
      if body.IsFrozen()
        ctx.fillStyle = "#373737"
      ctx.beginPath()

      if verts
        ctx.moveTo(verts[0].x, verts[0].y)
        for v in verts[1..]
          if v
            ctx.lineTo(v.x, v.y)
      else if sh.m_radius
        ctx.arc(0,0,sh.m_radius,0,Math.PI*2,true)
        ctx.lineTo(0,0)

      ctx.closePath()

      ctx.fill()
      ctx.strokeStyle = "#BBBBBB"
      ctx.stroke()

    ctx.fillStyle = "black"
    ctx.fillRect(-5, -5, 10, 10)

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
    force(0,-20, 0, 100000)
  if keys[37]
    force(-20,-20, 0, 10000)
  if keys[39]
    force(20,-20, 0, 10000)
  if keys[40]
    force(0,20, 0, -5000)

  world.Step(1/60, 1);
  #console.log "step"



  ctx.restore()
  # request frame
  requestFrame(draw)


$doc.keydown (e) ->
  #console.log e.which, keys
  keys[e.which] = true

$doc.keyup (e) ->
  keys[e.which] = false


# init function
$ ->
  $fg = $('#fg')

  world = createWorld()

  box = createBox(world, 50, 20, 23, 23, false)

  for i in [0...500]
    z = 3000
    x = r(-z,z)
    y = r(-z,z)
    xs = r(10,100)
    ys = r(10,100)
    #createBox world, x, y, xs, ys, false

    createPoly world, x, y

  console.log "world", world, "box", box



  draw()  