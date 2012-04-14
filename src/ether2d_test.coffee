
test1 = ->

  world = new World(new Vec2(0, 100))

  for i in [0...5]
    r = new RigidBody()
    r.pos.set(130,100-i*50)
    r.shapes.push new CircleShape(20, 1)
    #r.bounce = .2
    world.add(r)

  floor = new RigidBody()
  floor.fixed = true
  floor.pos.set(100, 200)
  floor.shapes.push new CircleShape(50, 1)
  world.add(floor)

  floor = new RigidBody()
  floor.fixed = true
  floor.pos.set(0, 400)
  floor.shapes.push new FloorShape()

  world.add(floor)



  sim = ->

    fg = $("#fg")[0]
    fg.width = $(window).width()
    fg.height = $(window).height()
    ctx = fg.getContext('2d')
    world.sim(16, ctx)
    world.draw(ctx)
    if not world.pause
      setTimeout(sim, 16)
  sim()

timeout = null
$ ->
  timeout = test1()