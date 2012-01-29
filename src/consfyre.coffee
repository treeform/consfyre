# window and document holders
$win = $(window)
$doc = $(document)

# our current size
width = 1000
height = 600

# canvas holder
$fg = undefined

world = undefined

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
  world.CreateBody boxBd


box = undefined
force_x = null
force_y = null

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
    ctx.translate(body.m_position.x, body.m_position.y)
    ctx.rotate(body.m_rotation)
    console.log body
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

  if force_x != null
    #console.log "up", box
    box.ApplyImpulse(force_x, box.m_position)
  if force_y != null
    #console.log "up", box
    box.ApplyImpulse(force_y, box.m_position)

  box.WakeUp()

  world.Step(1/60, 1);
  #console.log "step"



  ctx.restore()
  # request frame
  requestFrame(draw)


$doc.keydown (e) ->
  f = 10000
  #console.log e.which
  if e.which == 38
    force_y = new b2Vec2(0,-f)
  if e.which == 39
    force_x = new b2Vec2(f, 0)
  if e.which == 37
    force_x = new b2Vec2(-f,0)
  if e.which == 40
    force_y = new b2Vec2(0,f)

$doc.keyup (e) ->
   if e.which in [38,40]
     force_y = null
   if e.which in [37,39]
     force_x = null


# init function
$ ->
  $fg = $('#fg')

  world = createWorld()

  box = createBox(world, 50, 20, 23, 23, false)

  for i in [0...100]
    x = r(-1000,1000)
    y = r(-1000,1000)
    xs = r(10,100)
    ys = r(10,100)
    createBox world, x, y, xs, ys

  console.log "world", world



  draw()  