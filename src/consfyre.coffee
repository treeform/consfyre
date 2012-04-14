# window and document holders
$win = $(window)
$doc = $(document)

# our current size
width = 1000
height = 600

# canvas holder
$fg = undefined

space = undefined
ctx = undefined
box = undefined

v = cp.v

# keys are nothing more then a hash table
# with up and down state
# this allows modules to look them up during simulation
# instead of sending descrete events
keys = {}
# shift keys are keys pressed with shift
# shift allows keys to stick untill pressed and relased again
shift_keys = {}
$doc.keydown (e) ->
    key = String.fromCharCode(e.which)
    keys[key] = true
    shift_keys[key] = e.shiftKey

$doc.keyup (e) ->
    key = String.fromCharCode(e.which) 
    if not shift_keys[key]
        keys[key] = false

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
    #window.requestAnimationFrame or
    #window.webkitRequestAnimationFrame or
    #window.mozRequestAnimationFrame or
    #window.oRequestAnimationFrame or
    #window.msRequestAnimationFrame or
    (cb) -> window.setTimeout(cb, 1000/60)

# resize the canvas to match window
# called mainly to clear the window
resize = ->
    width = $win.width()
    height = $win.height()
    $fg.attr "width", width
    $fg.attr "height", height

# creates a space
createspace = ->
    space = new cp.Space();
    #space.iterations = 30;
    #space.gravity = v(0, -1);
    space.sleepTimeThreshold = 0.5;
    space.collisionSlop = 0.5;
    space.damping = 0.95
    return space

# creates a frictionless ball
createBall = (space, x, y, radius) ->

    body = space.addBody(new cp.Body(1, cp.momentForCircle(10, 0, radius, v(0,0))))
    body.setPos(v(x, y))
    shape = space.addShape(new cp.CircleShape(body, radius, v(0,0)));
    shape.setElasticity(0);
    shape.setFriction(0.9);

    return body    

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
    space.CreateBody ballBd


createBox = (space, x, y, xsize, ysize) ->
    body = space.addBody(new cp.Body(10, cp.momentForBox(10, xsize, ysize)))
    body.setPos(v(x, y))
    shape = space.addShape(new cp.BoxShape(body, xsize, ysize))
    shape.setElasticity(0)
    shape.setFriction(0.8)
    return body

# creates a physical object from tile grid
# TODO: optimize the number of sub rectangles created
createGrid = (space, x, y, grid) ->

    body = space.addBody(new cp.Body(1, cp.momentForBox(10, 50, 50)))
    body.setPos(v(x, y))

    # cube defintion, 0,0 to 1,1
    cube = [[0,0],[1,0],[1,1],[0,1]].reverse()
    # for each row tile grid
    for xrow, iy in grid
        py = iy - grid.length/2
        for e, ix in xrow
            if e
                px = ix - xrow.length/2
                # if tile is defined
                verts = []
                for p,i in cube
                    verts.push (p[0]+px)*16
                    verts.push (p[1]+py)*16
                shape = space.addShape(new cp.PolyShape(body, verts, new v(0, 0)))
                shape.setElasticity(0)
                shape.setFriction(0.8)
                
    body.grid = grid
    # set body position
    return body

box = undefined


draw = ->
    ###
    s = 1
    if keys["W"]
        box.applyImpulse(new v(0, -s), new v(0,0))
    if keys["S"]
        box.applyImpulse(new v(0,  s), new v(0,0))
    if keys["A"]
        box.applyImpulse(new v(-s, 0), new v(0,0))
    if keys["D"]
        box.applyImpulse(new v( s, 0), new v(0,0))
    ###
    
    # get canvas
    fg_canvas = $fg[0]
    # fast clear
    resize()
    # get context
    ctx = fg_canvas.getContext('2d')


    ctx.save()
    camera_x = -box.p.x+width/2
    camera_y = -box.p.y+height/2
    ctx.translate(camera_x, camera_y)

    space.eachBody (body) ->
        ctx.save()
        ctx.translate(body.p.x, body.p.y)
        #console.log(body.rot.x , body.rot.y, Math.atan2(body.rot.x, body.rot.y))
        ctx.rotate(Math.atan2(body.rot.y, body.rot.x))
        
        if body.grid?
            for row, iy in body.grid
                gy = iy - body.grid.length/2 +.5
                for module, ix in row
                    continue if not module
                    gx = ix - row.length/2 +.5
                    
                    ctx.save()
                    ctx.translate(gx*16, gy*16)
                    tx = module.tile[0]*16
                    ty = module.tile[1]*16
                    # draw image
                    if module.direction == S
                        # nothing
                    else if module.direction == N
                        ctx.rotate(180/180*Math.PI)
                    else if module.direction == E
                        ctx.rotate(-90/180*Math.PI)
                    else if module.direction == W
                        ctx.rotate(90/180*Math.PI)

                    #ctx.drawImage(ships, tx,ty, 16, 16,    -8, -8, 16,16)
                    ctx.restore()
                    
        ctx.restore()
        
        if body.grid?
            for row, iy in body.grid
                gy = iy - body.grid.length/2 +.5
                for module, ix in row
                    continue if not module
                    gx = ix - row.length/2 +.5
                    module.sim(body, gx*16, gy*16)            

    space.eachShape (shape) ->
        #console.log shape
        ctx.save()
        
        #ctx.rotate(shape.body.rot)
        
        #console.log shape
        if shape.type == "circle"
            ctx.translate(shape.body.p.x, shape.body.p.y)
            #ctx.fillStyle = shape.style()
            #shape.draw(ctx, 1, (p) -> p )
            # draw a debug circle
            
            ctx.beginPath()
            ctx.arc(0, 0, shape.r, 0, Math.PI*2, true)
            ctx.lineTo(0,0)
            ctx.closePath()
            ctx.lineWidth= 1
            ctx.fillStyle = "#777777"
            
            ctx.strokeStyle = "#BBBBBB"
            ctx.stroke()
        
        if shape.type == "poly"
            ctx.beginPath()
            verts = shape.tVerts
            ctx.moveTo(verts[0], verts[1])
            for i in [0...verts.length] by 2
                ctx.lineTo(verts[i], verts[i+1])
            ctx.closePath()
            ctx.fillStyle = "#777777"    
            
            ctx.strokeStyle = "#BBBBBB"
            ctx.stroke()
           
        #else            
        #    console.log "shape:", shape
            
        ctx.restore()
        

    space.step(1/60, 1);
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
        new v(0, mag)
    else if d == N
        new v(0, -mag)
    else if d == E
        new v(mag, 0)
    else if d == W
        new v(-mag, 0)
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
        @off = true
        return

    force: (body, x, y, fx,fy) ->
        body.activate()
        # find global tile position
        r = new v(x,y)
        r = cp.v.rotate(body.rot, r)
        #v.MulM(box.sMat0)
        #v.Add(box.m_position)
        # rotate force relative to ship
        f = new v(fx,fy)
        f = cp.v.rotate(body.rot, f)
        #f.MulM(box.sMat0)
        # apply the for to the ship
        body.applyImpulse(f, r)

        # draw the debug force vectors
        fire = new v(-fx/100,-fy/100)
        
        r.add(body.p)
        
        
        #fire.MulM(box.sMat0)
        ctx.beginPath()
        ctx.arc(r.x, r.y, 5,0, Math.PI*2, true)
        ctx.moveTo(r.x, r.y)
        ctx.lineTo(r.x-f.x*100, r.y-f.y*100)
        ctx.closePath()
        ctx.strokeStyle = "red"
        ctx.stroke()

    sim: (body, x, y) ->
        ###
        p = v(x, y)
        p = cp.v.rotate(body.rot, p)
      
        xaxis = new v(body.rot.x, body.rot.y)
        yaxis = new v(-body.rot.y, +body.rot.x)
        
        x = p.x
        y = p.y
        
        
        x += body.p.x  
        y += body.p.y
      
        ctx.beginPath()
        ctx.arc(x, y, 5,0, Math.PI*2, true)
        
        
        ctx.moveTo(x, y)
        ctx.lineTo(x+xaxis.x*10, y+xaxis.y*10)
        ctx.moveTo(x, y)
        ctx.lineTo(x+yaxis.x*10, y+yaxis.y*10)
        
        ctx.closePath()
        ctx.strokeStyle = "red"
        ctx.stroke()
        ###
        if keys[@key]
            console.log "here"
            # my key is activated
            vec = dir(@direction, -1)
            @force(body, x, y, vec.x, vec.y)

# Shoot projectiles based on key press
# can face 4 directions
class Gun extends Module
    tile: [3, 0]
    key: null
    constructor: (@direction, @key) ->
        return

    sim: (body, x, y) ->
        if keys[@key]
        
            make = ->
                console.log x, y
                r = new v(x, y)
                r = cp.v.rotate(body.rot, r)
                r.add(body.p)
               
                # rotate force relative to ship
                f = new v(0, 20)
                f = cp.v.rotate(body.rot, f)
                
                bullet = createBall(space, r.x+f.x, r.y+f.y, 4)
                bullet.applyImpulse(f.mult(50), v(0,0))
                remove = ->
                    space.removeBody(bullet)
                    for s in bullet.shapeList
                        space.removeShape(s)
                setTimeout(remove, 1000)
            
            setTimeout(make, 0)
            

# init function
$ ->

    #intro.play()

    $fg = $('#fg')

    space = createspace()

    # module shortcuts
    R = -> new Rock()
    H = -> new Hull()
    C = -> new Cargo()
    E = (d,k) -> new Engine(d, k)
    G = (d,k) -> new Gun(d, k)
     
    # ship definition
    ship = [
        [E(W, "D"), 0,             E(N,"S"), 0,             E(E,"A")]
        [H(),            H(),         C(),         H(),         H()]
        [0,                H(),         C(),         H(),         0]
        [0,                0,             C(),         0,             0]
        [0,                G(S," "), E(S,"W"), G(S," "), 0]
    ]

    
    box = createGrid(space, 0,0, ship)

    for i in [0...20]
        z = 400
        x = r(-z,z)
        y = r(-z,z)
        xs = r(10,100)
        ys = r(10,100)
        # rock definition
        rock = [
            [0,     R(), R(), R(), 0]
            [R(), R(), R(), R(), R()]
            [R(), R(), 0,     R(), R()]
            [R(), R(), R(), R(), R()]
            [0,     R(), 0,     R(), 0]
        ]
        createGrid space, x, y, rock
        #createBox(space, x, y, xs, ys)
    
    #console.log "space", space, "box", box

    #console.log createBall(space, 0, 0, 8)
    #createBall(space, 0, .1, 8)
    #box = createBox(space, .1, .1, 18, 18)
    
    
    console.log box

    draw()    
