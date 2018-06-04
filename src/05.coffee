cvs = document.getElementById "cvs"
ctx = cvs.getContext "2d"

w = cvs.width
h = cvs.height
cx = w/2
cy = h/2



nrm = undefined
N = 10000
points = ([Math.random()*w, Math.random()*h] for i in [0...N])

randomize = (p)->
    p[0] = Math.random()*w
    p[1] = Math.random()*h

cfg =
    N:1000
    u:5.0
    v:1.0
    c:1.0

g = new dat.GUI();

g.add cfg, "N",     0,    N,   1
g.add cfg, "u", -10.0, 10.0, 0.1
g.add cfg, "v", -10.0, 10.0, 0.1
g.add cfg, "c",   0.0, 10.0, 0.1


draw = ->
    ctx.fillStyle = "rgba(0,0,0,0.4)"    
    for i in [0...cfg.N]
        p = points[i]
        [x,y] = p
        xr = Math.round(x)
        yr = Math.round(y)
        if w<xr<0 or h<yr<0
            randomize p
            continue
        vx = (128-nrm[(xr+yr*w)*4+0])/128.0 # r
        vy = (128-nrm[(xr+yr*w)*4+1])/128.0 # g
        sp = Math.sqrt(vx*vx+vy*vy)
        if sp <0.04
            randomize p
            continue

        p[0]-=vx*cfg.v + vy*cfg.u
        p[1]-=vy*cfg.v - vx*cfg.u
        ctx.fillRect(p[0],p[1],1,1)

    for j in [0...50]
        i = Math.random()*cfg.N|0
        randomize points[i]
    
    ctx.fillStyle = "rgba(255,255,255,#{cfg.c/50.0})"
    ctx.fillRect(0,0,w,h);
    
init = ->
    img = new Image
    img.onload = ->
        console.log "loaded"
        nrm_cvs = document.createElement "canvas"
        nrm_ctx = nrm_cvs.getContext "2d"
        nrm_cvs.width  = nrm_ctx.width  = w
        nrm_cvs.height = nrm_ctx.height = h
        get_data = ->
            nrm_ctx.drawImage img, 0, 0
            nrm = nrm_ctx.getImageData(0,0,w,h).data
            console.log nrm[0..10]
            if nrm[0] is 0
                setTimeout get_data, 100
                return
            setInterval draw, 100
        get_data()
    img.src = "img/bf_03_nrm.png"

window.onload = init
