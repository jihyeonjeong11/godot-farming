from PIL import Image
R='assets/temp/rpgm_character_px/'
FEET=48; CX=32
LAYERS=['body_naked.png','outfits/pants.png','outfits/shoes.png','outfits/shirt.png','bag.png','outfits/hair.png','fx.png']
B=[(52,6,10),(96,14,18),(138,24,26),(176,52,48)]

def cell(p,col,row):
    return Image.open(R+p).convert('RGBA').crop((col*64,row*64,col*64+64,row*64+64))

def figure(col=0,row=1):
    im=Image.new('RGBA',(64,64))
    for p in LAYERS:
        im.alpha_composite(cell(p,col,row))
    return im

src=figure()
shadow=cell('shadow.png',0,1)

def squash(im,k):
    out=Image.new('RGBA',(64,64)); S=im.load(); P=out.load()
    for y in range(64):
        for x in range(64):
            sy=round(FEET-(FEET-y)/k)
            if 0<=sy<64 and S[x,sy][3]:
                P[x,y]=S[x,sy]
    return out

def fallen(angle,dx,dy):
    return src.rotate(-angle,resample=Image.NEAREST,center=(CX,FEET),translate=(dx,dy))

def pool(im,r,cx,cy):
    P=im.load()
    if r<=0:
        return
    rw=r; rh=max(1,r*0.5)
    for y in range(64):
        for x in range(64):
            d=((x-cx+0.5)/rw)**2+((y-cy+0.5)/rh)**2
            if d>1:
                continue
            c=B[0] if d>0.7 else B[1] if d>0.3 else B[2]
            if d<0.12 and (x+y)%3==0:
                c=B[3]
            P[x,y]=c+(255,)

def frame(fig,shadow_a,r,cx=CX,cy=FEET-1):
    im=Image.new('RGBA',(64,64))
    if shadow_a>0:
        sh=shadow.copy(); sh.putalpha(sh.split()[3].point(lambda v:int(v*shadow_a))); im.alpha_composite(sh)
    pool(im,r,cx,cy)
    im.alpha_composite(fig)
    return im

lying=fallen(90,-17,-4)
lb=lying.getbbox()
LX=(lb[0]+lb[2])//2+2
LY=lb[3]-1
steps=[
    (src,1,0),
    (squash(src,0.9),1,0),
    (fallen(28,-4,0),0.8,0),
    (fallen(62,-11,-1),0.4,0),
    (fallen(90,-17,-4),0,0),
    (lying,0,7,LX,LY),
    (lying,0,10,LX,LY),
    (lying,0,13,LX,LY),
    (lying,0,16,LX,LY),
]
out=Image.new('RGBA',(64*len(steps),64))
for i,s in enumerate(steps):
    out.paste(frame(*s),(64*i,0))
out.save(R+'death.png')
