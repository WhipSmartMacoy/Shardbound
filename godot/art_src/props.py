# Rebuild props that contained old-style characters: stall (no merchant baked in), cage with new Doran, merchant sprite.
from PIL import Image, ImageDraw
import heroes as Hm
OUT='out'
# merchant: robe body + brown hood head (reuse Pip head shape), arms on table
Hm.HERO['merchant']=('robe','rod')
Hm.HEADS['merchant']=Hm.HEADS['pip']
Hm.PAL['merchant']=dict(H='#3a2a1a',A='#5a4030',I='#20160c',S='#d8a878',s='#a87850',E='#181010',R='#7a5a3a',Q='#9a7a54',r='#4a3420',
    C='#6a4a30',L='#8a6a48',c='#3e2a18',K='#c8a050',k='#8a6a2a',B='#3a2a1a',b='#20160c',N='#6a4428',n='#3e2616',O='#ffd84a',o='#fff0a0')
Hm.compose('merchant','stand').save(f'{OUT}/npc_merchant.png')
# stall: drawn at prop density (2 px per logical px)
W,H=150,110; im=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(im)
OL=(26,18,32,255)
def rect(x0,y0,x1,y1,fill,hi=None,lo=None):
    d.rectangle([x0-1,y0-1,x1+1,y1+1],fill=OL); d.rectangle([x0,y0,x1,y1],fill=fill)
    if hi: d.line([x0,y0,x1,y0],fill=hi); d.line([x0,y0,x0,y1],fill=hi)
    if lo: d.line([x0,y1,x1,y1],fill=lo); d.line([x1,y0,x1,y1],fill=lo)
rect(8,22,13,104,(90,56,26,255),(130,86,44,255),(56,34,14,255)); rect(136,22,141,104,(90,56,26,255),(130,86,44,255),(56,34,14,255))
for i in range(7):  # awning
    col=(200,50,50,255) if i%2==0 else (238,232,224,255); sh=(150,30,30,255) if i%2==0 else (190,180,176,255)
    x0=4+i*20; d.rectangle([x0,6,x0+19,24],fill=col); d.rectangle([x0,20,x0+19,24],fill=sh)
    d.pieslice([x0,16,x0+19,32],0,180,fill=col)
d.rectangle([3,5,144,6],fill=OL)
rect(6,70,143,98,(107,61,26,255),(150,96,48,255),(60,32,12,255))   # counter
for y in (78,86,94): d.line([8,y,141,y],fill=(80,44,18,255))
rect(4,64,145,70,(138,82,38,255),(180,120,60,255),(90,50,20,255))  # counter top
# goods on the counter
for x,c in [(22,(224,180,58,255)),(40,(216,64,64,255)),(56,(64,128,255,255)),(96,(90,200,120,255)),(116,(224,180,58,255))]:
    d.rectangle([x-1,54,x+9,64],fill=OL); d.rectangle([x,55,x+8,63],fill=c); d.rectangle([x+1,56,x+3,58],fill=(255,255,255,200))
im.save(f'{OUT}/prop_stall.png')
# cage with new Doran inside (hero sprite at 2x = prop density)
cage=Image.open('../assets/sprites/prop_cage_open.png').convert('RGBA')
dor=Hm.compose('doran','kneel'); dor=dor.resize((dor.width*2,dor.height*2),Image.NEAREST)
out=Image.new('RGBA',cage.size,(0,0,0,0))
out.alpha_composite(dor,((cage.width-dor.width)//2+2,cage.height-dor.height-6))
# redraw bars over him
bars=Image.open('../assets/sprites/prop_cage_open.png').convert('RGBA')
full=Image.new('RGBA',cage.size,(0,0,0,0)); full.alpha_composite(out)
dd=ImageDraw.Draw(full)
for i in range(7):
    x=2+i*12
    dd.rectangle([x,4,x+3,cage.height-5],fill=(136,136,144,255)); dd.line([x,4,x,cage.height-5],fill=(190,190,200,255))
full.alpha_composite(bars)
full.save(f'{OUT}/prop_cage.png')
print('props ok', cage.size)
