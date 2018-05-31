cvs = document.getElementById "cvs"
ctx = cvs.getContext "2d"

w = cvs.width
h = cvs.height
cx = w/2
cy = h/2

sin = Math.sin
cos = Math.cos
rnd = Math.random
PI  = Math.PI

p2c = (p)->[p[1]*cos(p[0]), -p[1]*sin(p[0])]
p2l = (p)->Math.sqrt(p[0]*p[0]+p[1]*p[1])
p2n = (p)->l=p2l(p); [p[0]/l, p[1]/l]
dst = (p,q)->p2l dif(q,p)
dif = (p,q)->[p[0]-q[0], p[1]-q[1]]
add = (p,q)->[p[0]+q[0], p[1]+q[1]]
mul = (p,k)->[p[0]*k, p[1]* k]
rot = (p,s=-1)->[p[1]*s,-p[0]*s]
g2a = (g)->g*PI/180.0
clm = (p,q,k)->[p[0]+(q[0]-p[0])/k, p[1]+(q[1]-p[1])/k]

point = (p, c)->
    r = 5
    c?= "red"
    ctx.save()
    ctx.beginPath()
    ctx.moveTo(p[0]-r,p[1]); ctx.lineTo(p[0]+r,p[1]);
    ctx.moveTo(p[0],p[1]-r); ctx.lineTo(p[0],p[1]+r);
    ctx.strokeStyle = c
    ctx.stroke()
    ctx.restore()

line = (p, q, c)->
    c?="rgba(0,0,0,0.2)"
    ctx.save()
    ctx.beginPath()
    ctx.strokeStyle = c
    ctx.moveTo(p[0],p[1]);
    ctx.lineTo(q[0],q[1]);
    ctx.stroke()
    ctx.restore()
    
circle = (p, r, c)->
    c?="red"
    ctx.save()
    ctx.beginPath()
    ctx.strokeStyle = c
    ctx.arc(p[0],p[1], r,0, 2.0*PI);
    ctx.stroke()
    ctx.restore()

contour = (cnt, c)->
    ctx.save()
    c?="rgba(0,0,0,0.1)"
    ctx.beginPath()
    ctx.moveTo cnt[0][0], cnt[0][1]
    for i in [1...cnt.length]
        ctx.lineTo cnt[i][0], cnt[i][1]
    ctx.strokeStyle = c
    ctx.stroke()
    ctx.restore()

class Butterfly

    constructor:->
        s = sin; c=cos
        @wings_details = 1
        @w_n = 6
        @w_c = 8
        @["w_r_#{i}"] = r for r, i in [-1,+2,+2,-1,+3,-2]
        @["w_p_#{i}"] = p for p, i in [ 1, 3, 5, 7, 2, 4]
        @["w_f_#{i}"] = f for f, i in [ s, s, s, s, c, c]

        @build()

    wings_formula: (a)=>
        f = @w_c
        for i in [0...@w_n]
            f+= @["w_r_#{i}"] * @["w_f_#{i}"] ( @["w_p_#{i}"]*a )
        f

    build: =>
        @main_contour = for g in [90..450] by @wings_details
            a = g2a g
            r = @wings_formula a
            add [cx, cy], p2c [a, 40*r]

    draw: =>
        contour @main_contour, "rgba(0,0,0,0.25)"
    
class Spiral
    
    constructor: (@steps, @flex, @br_step=100)->
       @dots = false
       @branches = false
       @radiuses = false
       @speed = 20
       
    draw: (p, v, t, r, s=1)=>
        points = []
        rs = r
        
        point p if @dots
        point t if @dots
        circle t, r if @radiuses
        
        p = p
        k = @flex
        for i in [0...@steps]
            m = rot(p2n(dif(t,p)),s)
            tt = add(t,mul(m,r))
            
            vv = p2n(dif(tt,p))
            v = clm(v, vv, k)
            
            pv = add(p,mul(v, @speed))

            line p, pv, "rgba(0,0,0,0.5)"
            p = pv
            points.push p
            d = dst(p,t)
            r-=0.5
            break if r<0 or d < 2

        points
        
init = ->

    b = new Butterfly
    s = new Spiral 200, 5.0
    s.spiral_step = 30
    s.Spirals = true
    s.Voronoi = false
    s.Delaunay = false

    wings = (i, s1, s2, s3)->
        
        c = [cx, cy]
        mc = b.main_contour

        t = mc[i]
        point t
        v = [0, s3]
        r = 100
        p = s.draw c, v, t, r, s2
        for _ in [1..5]
            d = 0
            while d<r*1.618
                d+=dst(mc[i], mc[i+s1])
                i+=s1
            r*=0.75
            t = mc[i]
            line mc[i],t
            s.draw c, v, t, r, s2

    redraw= ->
         
        ctx.clearRect 0, 0, w, h

        b.build()
        b.draw()
        
        wings  60, -1,  1, -1
        wings  80,  1, -1,  1
        wings 280, -1,  1,  1
        wings 300,  1, -1, -1
        
        mc = b.main_contour
        
        # Voronoi
        if s.Voronoi
            vr = new Voronoi
            bb = xl: 0, yt: 0, xr: w, yb:h
            ps = mc.map (p)->x:p[0], y:p[1]
            dr = vr.compute ps, bb
            for e in dr.edges
                line [e.va.x, e.va.y], [e.vb.x, e.vb.y], "rgba(0,0,0,0.25)"

        # Delaunay
        if s.Delaunay
            dl = new Delaunator.from mc
            for e in [0...dl.triangles.length] by 3
                i1 = dl.triangles[e+0]
                i2 = dl.triangles[e+1]
                i3 = dl.triangles[e+2]
                p1 = [mc[i1][0], mc[i1][1]]
                p2 = [mc[i2][0], mc[i2][1]]
                p3 = [mc[i3][0], mc[i3][1]]
                line p1, p2, "rgba(0,0,0,0.25)"
                line p2, p3, "rgba(0,0,0,0.25)"
                line p3, p1, "rgba(0,0,0,0.25)"

    redraw()

    g = new dat.GUI();
    
    f = g.addFolder "Curls"
    f.add(s, "Voronoi").onChange redraw
    f.add(s, "Delaunay").onChange redraw
    f.add(s, "Spirals").onChange redraw
    f.add(s, "spiral_step",10,   90, 10).onChange redraw
    #f.add(s, "radius"   ,   0, 1000).onChange redraw
    f.add(s, "steps"    ,   0, 1000).onChange redraw
    f.add(s, "flex"     , 1.0,  100).onChange redraw
    f.add(s, "speed"     , 1.0,  30).onChange redraw
    f.add(s, "branches").onChange redraw
    f.add(s, "br_step" ,  10,  200, 1).onChange redraw
    f.add(s, "dots").onChange redraw
    f.add(s, "radiuses").onChange redraw
    f.open()

    f = g.addFolder "Wings"
    f.add(b, "wings_details", 1, 10, 1).onChange redraw
    for i in [0...b.w_n]
        f.add(b, "w_r_#{i}", -10, 10).onChange redraw
    for i in [0...b.w_n]
        f.add(b, "w_p_#{i}", 0, 20, 1).onChange redraw
        
window.onload = init
