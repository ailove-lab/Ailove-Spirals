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
g2a = (g)->g*PI/180.0

point = (p)->
    r = 5
    ctx.save()
    ctx.beginPath()
    ctx.strokeStyle = "red"
    ctx.moveTo(p[0]-r,p[1]); ctx.lineTo(p[0]+r,p[1]);
    ctx.moveTo(p[0],p[1]-r); ctx.lineTo(p[0],p[1]+r);
    ctx.stroke()
    ctx.restore()

line = (p, q, c)->
    c?="rgba(0,0,0,0.1)"
    ctx.save()
    ctx.beginPath()
    ctx.strokeStyle = c
    ctx.moveTo(p[0],p[1]);
    ctx.lineTo(q[0],q[1]);
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
        @main_contour = for g in [90..450]
            a = g2a g
            r = @wings_formula a
            add [cx, cy], p2c [a, 40*r]

    draw: =>
        contour @main_contour, "rgba(0,0,0,0.25)"
    
class Spiral
    
    constructor: (@steps, @radius, @flex, @br_step=100)->
       @dots = false
       @branches = false
    draw: (p, v, t, s=1)=>
        point p if @dots
        point t if @dots
        p = p
        r = @radius
        k = @flex
        for i in [0...@steps]
            n = p2n dif t, p
            m = [s*n[1],-s*n[0]]
            d = add(t, mul(m,r))
            vv = p2n dif d, p
            v = [v[0]+(vv[0]-v[0])/k, v[1]+(vv[1]-v[1])/k]
            pv = add p, mul v, 10
            line p, pv, "rgba(0,0,0,0.5)"
            if @branches and (i+1)%@br_step is 0
                nn = p2n dif pv, p
                mm = [s*nn[1],-s*nn[0]]
                tt = add p, mul mm, r/2.0
                @draw2 p, nn, tt, s
            p = pv
            r-=1
            break if dst(p, t) < 3
        
    draw2: (p, v, t, s=1)=>
        point t if @dots
        p = p
        r = @radius/5.0
        k = @flex
        for i in [0...@steps]
            n = p2n dif t, p
            m = [-s*n[1],s*n[0]]
            d = add(t, mul(m, r))
            vv = p2n dif d, p
            v = [v[0]+(vv[0]-v[0])/k, v[1]+(vv[1]-v[1])/k]
            pv = add p, mul v, 5
            line p, pv, "rgba(0,0,0,0.3)"
            p = pv
            r-=0.5
            break if dst(p, t) < 3
init = ->

    b = new Butterfly
    s = new Spiral 200, 200, 5.0
    s.spiral_step = 30
    redraw= ->
         
        ctx.clearRect 0, 0, w, h

        b.build()
        b.draw()
        
        mc = b.main_contour
        for i in [30..330] by s.spiral_step
            continue if i%180 is 0
            switch true
                when 0<i<90
                    spin = -1
                    v = [0, -1]
                when 90<=i<180
                    spin = 1
                    v = [0,1]
                when 180<i<270
                    spin = -1
                    v = [0,1]
                when 270<i<360
                    spin = 1
                    v = [0, -1]
            p1 = [mc[i  ][0], mc[i  ][1]]
            p2 = [mc[i+1][0], mc[i+1][1]]
            n = p2n dif p2, p1
            n = [n[1],-n[0]]
            t = add p1, mul n, 100
            line t, p1
            s.draw [cx, cy], v, t, spin
    
    redraw()

    g = new dat.GUI();
    
    f = g.addFolder "Curls"
    f.add(s, "spiral_step",10,   90, 10).onChange redraw
    f.add(s, "radius"   ,   0, 1000).onChange redraw
    f.add(s, "steps"    ,   0, 1000).onChange redraw
    f.add(s, "flex"     , 1.0,  100).onChange redraw
    f.add(s, "branches").onChange redraw
    f.add(s, "br_step" ,  10,  200, 1).onChange redraw
    f.add(s, "dots").onChange redraw
    f.open()

    f = g.addFolder "Wings"
    for i in [0...b.w_n]
        f.add(b, "w_r_#{i}", -10, 10).onChange redraw
    for i in [0...b.w_n]
        f.add(b, "w_p_#{i}", 0, 20, 1).onChange redraw
        
window.onload = init
