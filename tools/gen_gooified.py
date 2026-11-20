from PIL import Image
R='assets/temp/rpgm_character_px/'
def cell(p,col,row): return Image.open(R+p).convert('RGBA').crop((col*64,row*64,col*64+64,row*64+64))
def comp(col=0,row=1):
    im=Image.new('RGBA',(64,64))
    for p in ['shadow.png','body_naked.png','outfits/pants.png','outfits/shoes.png','outfits/shirt.png','bag.png','outfits/hair.png','fx.png']:
        c=cell(p,col,row); im.alpha_composite(c)
    return im
from PIL import Image
FEET=48; CX=32
src=comp(); S=src.load()
shadow=cell('shadow.png',0,1)
G=[(16,40,22),(30,86,36),(58,146,50),(112,210,74),(200,255,150)]
def mix(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def lum(c): return (c[0]*3+c[1]*6+c[2])/10
def goo_of(c):
    l=lum(c); return G[1] if l<60 else G[2] if l<150 else G[3]
def opaque(x,y): return 0<=x<64 and 0<=y<64 and S[x,y][3]>=200
def frame(sag, tint, puddle):
    im=Image.new('RGBA',(64,64)); P=im.load()
    a=max(0.0,1-puddle*3)
    if a>0:
        sh=shadow.copy(); sh.putalpha(sh.split()[3].point(lambda v:int(v*a))); im.alpha_composite(sh)
    if puddle>0:
        pw=6+26*puddle; ph=2+5*puddle
        for y in range(FEET-6,FEET+5):
            for x in range(64):
                d=((x-CX+0.5)/(pw/2))**2+((y-FEET-0.5)/(ph/2))**2
                if d<=1:
                    c=G[1] if d>0.55 else G[2]
                    if d<0.25 and y<=FEET: c=G[3]
                    P[x,y]=c+(255,)
    body={}
    for y in range(FEET+1):
        h=FEET-y
        for x in range(64):
            spread=1+sag*1.3*max(0,1-h/(34*(1-sag)+1))+sag*0.25
            sx=round(CX-0.5+(x-CX+0.5)/spread); sy=round(FEET-h/max(1-sag,0.05))
            if opaque(sx,sy):
                body[(x,y)]=S[sx,sy]
    if not body: return im
    tops={}
    for (x,y) in body: tops[x]=min(tops.get(x,99),y)
    xs=sorted(tops)
    sm={x:sum(tops.get(x+d,tops[x]) for d in(-1,0,1))/3 for x in xs}
    for x in xs:
        top=round(sm[x]) if sag>0.3 else tops[x]
        for y in range(top,FEET+1):
            c=body.get((x,y))
            depth=(y-top)
            if c is None:
                if sag<=0.3: continue
                g=G[2]
            else:
                g=goo_of(c)
            k=min(1,tint*(1.0+0.6*(y-top)/max(1,FEET-top)))
            base=c[:3] if c is not None else g
            col=mix(base,g,k)
            if sag>0.3 and depth==0: col=mix(col,G[3],min(1,tint))
            if sag>0.3 and y==FEET: col=mix(col,G[1],0.6)
            P[x,y]=col+(255,)
    if 0.2<tint and sag<0.6:
        for i,dx in enumerate((-5,-2,3,6)):
            x=CX+dx
            if x not in tops: continue
            top=round(sm[x]); L=int(2+tint*4)+(i%2)
            for y in range(top+1,min(FEET,top+1+L)): P[x,y]=G[3]+(255,)
            if top+1+L<FEET: P[x,top+1+L]=G[4]+(255,)
    if puddle>0.6:
        for bx,by in ((CX-7,FEET-1),(CX+5,FEET),(CX+10,FEET+1)):
            P[bx,by]=G[4]+(255,)
    return im
steps=[(0,0,0),(0,0.35,0),(0.12,0.6,0.1),(0.3,0.8,0.25),(0.5,0.95,0.4),(0.68,1,0.6),(0.82,1,0.78),(0.92,1,0.92),(0.97,1,1)]
out=Image.new('RGBA',(64*len(steps),64))
for i,s in enumerate(steps): out.paste(frame(*s),(64*i,0))
out.save(R+'gooified.png')
