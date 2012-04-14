###
MIT - license
by Andre von Houck

Ether2d - simple physics engine for HTML5 games written in coffee script
###

e = window

class e.Vec2
  constructor: (@x, @y) ->
  set: (@x, @y) ->
  add: (v) ->
    @x += v.x
    @y += v.y
    return this
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    return this
  mul: (n) ->
    @x *= n
    @y *= n
    return this
  div: (n) ->
    @x /= n
    @y /= n
    return this

  # add with time delta
  add_dt: (v, dt) ->
    @x += v.x * dt
    @y += v.y * dt
    return this
  # distance
  dist: (v) ->
    x = @x - v.x
    y = @y - v.y
    Math.sqrt(x * x + y * y)

  copy: ->
    new Vec2(@x, @y)

  # dot product
  dot: (v) ->
    @x * v.x + @y * v.y

  # magnitude or length of the vector
  mag: ->
    Math.sqrt(@x * @x + @y * @y)

  # normalize vector to have length of 1
  norm: ->
    m = @mag()
    if m > Number.MIN_VALUE
        @div(m)
    return this

class e.Mat2

  # new rotation matrix
  constructor: ->
    @m = [1,0,
          0,1]
  # sets matrix to 4 values
  set: (a,b,c,d) ->
    @m[0] = a; @m[2] = c
    @m[1] = b; @m[3] = d
  # make a copy
  copy: ->
    mx = new Mat2()
    mx.m[0] = @m[0]
    mx.m[1] = @m[1]
    mx.m[2] = @m[2]
    mx.m[3] = @m[3]
    return mx
  # creates a matrix with this angle
  angle: (a) ->
    c = Math.cos(a)
    s = Math.sin(a)
    @m[0] = c; @m[2] = -s
    @m[1] = s; @m[3] = c
  add: (mx) ->
    @m[0] += mx.m[0]
    @m[1] += mx.m[1]
    @m[2] += mx.m[2]
    @m[3] += mx.m[3]
  sub: (mx) ->
    @m[0] -= mx.m[0]
    @m[1] -= mx.m[1]
    @m[2] -= mx.m[2]
    @m[3] -= mx.m[3]
  mul: (mx) ->
    @m[0] = @m[0]*mx.m[0] + @m[1]*mx.m[2]
    @m[1] = @m[0]*mx.m[1] + @m[1]*mx.m[3]
    @m[2] = @m[2]*mx.m[0] + @m[3]*mx.m[2]
    @m[3] = @m[2]*mx.m[1] + @m[3]*mx.m[3]
  # invert the matrix
  inv: ->
    a = @m[0]
    b = @m[1]
    c = @m[2]
    d = @m[3]
    det = a * d - b * c;
    det = 1.0 / det
    @m[0] =  det * d; @m[2] = -det * b
    @m[1] = -det * c; @m[3] =  det * a

class e.World

  constructor: (@gravity) ->
    @id = 0
    @things = {}

  add: (thing) ->
    thing.id = @id
    @id += 1
    @things[thing.id] = thing

  del: (thing) ->
    delete @things[thing.id]

  sim: (dt, ctx) ->

    dt = dt or 16
    dt /= 1000

    for id, thing of @things
      continue if thing.fixed
      thing.vel.add_dt(@gravity, dt)
      thing.pos.add_dt(thing.vel, dt)
      #thing.rot.mul(thing.w)
      #thing.angle = Math.atan2(thing.rot.m[2],thing.rot.m[3])

      thing.angle += thing.av * dt
      console.log "angle", thing.angle, thing.av

    for id1, thing1 of @things
      for sh1 in thing1.shapes
        for id2, thing2 of @things
          continue if thing1 == thing2 or thing2.fixed

          for sh2 in thing2.shapes
             @collide(thing1, sh1, thing2, sh2, dt, ctx)

  collide: (thing1, sh1, thing2, sh2, dt, ctx) ->

    p1 = sh1.pos.copy().add(thing1.pos)
    p2 = sh2.pos.copy().add(thing2.pos)

    if sh1 instanceof CircleShape and
       sh2 instanceof CircleShape
        p1 = sh1.pos.copy().add(thing1.pos)
        p2 = sh2.pos.copy().add(thing2.pos)
        dir = p1.copy().sub(p2)
        #dir = p2.sub(p1)

        d = dir.mag()
        if d < sh1.radius + sh2.radius
          console.log "-------- collide",d, sh1.radius, sh2.radius
          #thing1.vel.set(0,0)
          #thing2.vel.set(0,0)
          dir.div(d)
          console.log "dir", dir.x, dir.y, p1, p2

          disp_v = dir.copy().mul(sh2.radius)

          point = disp_v.copy().add(p2)
          console.log "point", point.x, point.y


          dot = thing2.vel.dot(dir)
          console.log "dot", dot

          dot = 0 if dot < 0

          force = dir.copy().mul(-dot)
          ctx.beginPath()
          ctx.moveTo(point.x, point.y)
          ctx.lineTo(force.x+point.x, force.y+point.y)
          ctx.closePath()
          ctx.strokeStyle = "green"
          ctx.stroke()

          ctx.beginPath()
          ctx.moveTo(p2.x, p2.y)
          ctx.lineTo(thing2.vel.x+p2.x, thing2.vel.y+p2.y)
          ctx.closePath()
          ctx.strokeStyle = "gray"
          ctx.stroke()



          thing2.vel.add(force)

          ctx.beginPath()
          ctx.moveTo(p2.x, p2.y)
          ctx.lineTo(thing2.vel.x+p2.x, thing2.vel.y+p2.y)
          ctx.closePath()
          ctx.strokeStyle = "yellow"
          ctx.stroke()



          dir.mul(dot)
          thing1.vel.set(dir.x, dir.y)

          console.log "force", force.x, force.y

          #thing2.w = new Mat2()
          #thing2.w.angle(-.1)
          th = Math.atan(dir.x, dir.y)
          arm = sh2.radius
          torque = arm * force.mag() * Math.sin(th)
          I = 1000
          aa = torque / I
          thing2.av -= aa
          console.log "aa", aa, th, thing1.angle
          #@pause = true

          if force.y > 0
            @pause = true

    if sh1 instanceof FloorShape and
       sh2 instanceof CircleShape
        #console.log "floor", p1.y, p2.y
        if p1.y < p2.y + sh2.radius
          #@pause = true
          if thing2.vel.y > 0
            thing2.vel.y = -thing2.vel.y * thing2.bounce
            thing2.pos.y = p1.y - sh2.radius

  # debug draw
  draw: (ctx) ->
    for id, thing of @things
      ctx.save()
      ctx.translate(thing.pos.x, thing.pos.y)
      ctx.rotate(thing.angle)

      for sh in thing.shapes
        sh.draw(ctx)

      ctx.restore()

class e.RigidBody

  constructor: ->
    @pos = new Vec2(0, 0)
    @vel = new Vec2(0, 0)
    @w = new Mat2()
    @angle = 0
    @av = 0
    @rot = new Mat2()
    @rot.angle(@angle)
    @shapes = []
    @fixed = false
    @bounce = 0.5

class e.Shape

  constructor: ->
    @mass = 0


class e.FloorShape extends Shape
  # an axis aligned rectangle
  constructor: () ->
    @pos = new Vec2(0, 0)

  draw: (ctx) ->
    ctx.strokeStyle = "red"
    ctx.strokeRect(-10000, 0, 20000, 2)

class e.CircleShape extends Shape

  constructor: (@radius, @dencity) ->
    @pos = new Vec2(0,0)
    @angle = 0
    @area = Math.PI * @radius*@radius
    @mass = @area * @dencity
    @center = new Vec2(0, 0)

  draw: (ctx) ->
    ctx.save()
    ctx.translate(@pos.x, @pos.y)
    ctx.rotate(@angle)
    # draw a debug circle
    ctx.beginPath()
    ctx.arc(0, 0, @radius, 0, Math.PI*2, true)
    ctx.lineTo(0, 0)
    ctx.closePath()
    ctx.lineWidth = 1
    ctx.strokeStyle = "red"
    ctx.stroke()

    ctx.restore()