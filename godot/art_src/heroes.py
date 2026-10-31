# FF5-style hero sprites: 16x24 chibi bodies with poses. Composed from head + top + bottom + weapon, auto-outlined.
from PIL import Image
OUT_DIR='out'
import os; os.makedirs(OUT_DIR,exist_ok=True)
PADL,PADR,PADT,PADB=6,6,6,1          # room for weapons
W,H=16+PADL+PADR,24+PADT+PADB
OUTLINE=(26,18,32,255)

HEADS={
'kael':[".......H.H......",
        ".....HHAHHH.H...",
        "....HAAHHHHHH...",
        "...HAHHHHHHHHI..",
        "...RQRRRRRRRRrr.",
        "..HHSSSHHHHHHI.r",
        "..HSSSSSHHHHI.r.",
        "..SESSSSHHHHI...",
        "..SESSSSSHHI....",
        "..SSSSSSsHI.....",
        "...SSSsss.......",
        "....sss........."],
'mira':[".....RRRRR......",
        "....RQQRRRRr....",
        "...RQRRRRRRRr...",
        "..RQRRRRRRRRRr..",
        "..RKKKKKRRRRRr..",
        "..RAAHASRRRRRr..",
        "..RSSSSSSRRRRr..",
        "..SESSSSSRRRr...",
        "..SESSSSSRRRr...",
        "..SSSSSSsRRr....",
        "...SSSsssRr.....",
        "....sss.rr......"],
'doran':["..........RR....",
        ".........RRr....",
        "........RQRr....",
        ".......RQRRr....",
        "......RQRRRRr...",
        "..KKKKKKKKKKKKk.",
        "...HHSSSHHHHHI..",
        "..HSSSSSSHHHI...",
        "..SESSSSSHHHI...",
        "..SESSSSSsHI....",
        "...SSSSsss......",
        "....sss........."],
'pip':["................",
        "......RRRRR.....",
        "....RQQRRRRRr...",
        "...RQRRRRRRRRr..",
        "..RQRRRRRRRRRRr.",
        "..RHHAHRRRRRRrrr",
        "..HSSSSSRRRRr..r",
        "..SESSSSSRRr....",
        "..SESSSSSRRr....",
        "..SSSSSSsRr.....",
        "...SSSsss.......",
        "....sss........."],
}
TOPS={
'stand':[".....CCCCC......",
         "....LCCCCCCc....",
         "...LLCCCCCCc....",
         "...LLCCKCCcc....",
         "...@CKKKKKKc....",
         "....CCCCCCc....."],
'atk1': ["..........@.....",
         ".....CCCCCL.....",
         "....LCCCCCLc....",
         "....LCCCCCCc....",
         "....CCCKKKKc....",
         "....CCCCCCc....."],
'atk2': [".....CCCCC......",
         "....LCCCCCCc....",
         "@LLLLCCCCCCc....",
         "....CCCKCCcc....",
         "....CKKKKKKc....",
         "....CCCCCCc....."],
'cast': [".....CCCCC......",
         "@...LCCCCCCc....",
         ".LLLLCCCCCCc....",
         "....CCCKCCcc....",
         "....CKKKKKKc....",
         "....CCCCCCc....."],
'hurt': [".....CCCCC......",
         "....LCCCCCCcLL@.",
         "....LCCCCCCc....",
         "....CCCKCCcc....",
         "....CKKKKKKc....",
         "....CCCCCCc....."],
'victory':[".....CCCCC......",
         "...LLCCCCCCc....",
         "...L.CCCCCCc....",
         "....CCCKCCcc....",
         "....CKKKKKKc....",
         "....CCCCCCc....."],
}
BOTTOMS={
'tunic':{
 'stand':["....PPPPPPp.....","....PPp.PPp.....","....PPp.PPp.....","....BBb.BBb.....","...BBBb.BBBb....","...bbb..bbb....."],
 'walk': ["...PPPPPPPp.....","..PPp...PPp.....","..PPp....PPp....",".BBb.....BBb....","BBBb.....BBBb...","bbb......bbb...."],
 'lunge':["...PPPPPPPp.....","..PPp....PPp....",".PPp......PPp...",".BBb.......BBb..","BBBb.......BBBb.","bbb........bbb.."]},
'robe':{
 'stand':["...LCCCKCCcc....","...LCCCKCCCcc...","..LLCCCKCCCcc...","..LCCCCKCCCCcc..","..KKKKKKKKKKKk..","...bbb...bbb...."],
 'walk': ["...LCCCKCCcc....","..LLCCCKCCCcc...","..LCCCCKCCCCcc..",".LCCCCCKCCCCCcc.",".KKKKKKKKKKKKKk.",".bbb.......bbb.."],
 'lunge':["...LCCCKCCcc....","..LLCCCKCCCcc...","..LCCCCKCCCCcc..",".LCCCCCKCCCCCcc.",".KKKKKKKKKKKKKk.",".bbb.......bbb.."]},
}
KNEEL={
'tunic':[".....CCCCC......","...LLCCCCCCc....","...@CKKKKKKc....","...PPPPPPPPp....","..PPPPPPPPPPp...","..BBBbb.PPPp....","..bbbb..BBBb....",".........bbb...."],
'robe': [".....CCCCC......","...LLCCCCCCc....","...@CCCKCCcc....","..LCCCCKCCCCc...",".LCCCCCKCCCCCc..",".LCCCCCKCCCCCCc.",".KKKKKKKKKKKKKk.","................"],
}
# weapons: '@' = grip in hand
WEAP={
'sword':{'down':[".K.","K@K",".M.",".M.",".M.",".m."],
         'up':  [".m.",".M.",".M.",".M.",".M.","K@K",".N."],
         'back':[".....m","....Mm","...Mm.","..Mm..",".KK...","K@...."],
         'fwd': ["......K.","mMMMMM@N","......K."]},
'staff':{'down':[".o.","oOO",".O.",".N.",".N.","N@N",".N.",".N.",".n."],
         'up':  [".o.","oOO",".O.",".N.",".N.",".N.",".@.",".N.",".n."],
         'back':["....oO","....OO","...N..","..N...",".N....","@....."],
         'fwd': ["oO.......","OONNNNN@n"]},
'rod':  {'down':[".o.","oOo",".N.","N@N",".n."],
         'up':  [".o.","oOo",".N.",".N.",".@.",".n."],
         'back':["...oO","...OO","..N..",".N...","@...."],
         'fwd': ["oO.....","OONNN@n"]},
'dagger':{'down':["K@K",".M.",".m."],
         'up':  [".m.",".M.","K@K"],
         'back':["..m",".M.","@.."],
         'fwd': ["mMM@N"]},
}
HERO={'kael':('tunic','sword'),'mira':('robe','staff'),'doran':('robe','rod'),'pip':('tunic','dagger')}
PAL={
'kael':dict(H='#8a4a24',A='#c47c3c',I='#552812',S='#f8c898',s='#cc8c66',E='#201820',R='#d83838',Q='#ff8070',r='#8c2020',
            C='#3a68c8',L='#6c9cf0',c='#223f88',K='#a87838',k='#6a4a20',P='#5a4632',p='#3a2c20',B='#6a4428',b='#3e2616',M='#eef2fa',m='#8890a8',N='#6a4428',n='#3e2616'),
'mira':dict(H='#f0c858',A='#fff0a8',I='#b88a2a',S='#f8cca0',s='#d09670',E='#2a2040',R='#f2eee6',Q='#ffffff',r='#b4aac4',
            C='#f2eee6',L='#ffffff',c='#b4aac4',K='#e0b040',k='#a07820',B='#8a6a4a',b='#5a4030',N='#b07a3a',n='#6a4420',O='#5ac8f8',o='#d0f4ff'),
'doran':dict(H='#2a2a3a',A='#505068',I='#121218',S='#eab68a',s='#c08060',E='#181018',R='#6a48b8',Q='#9c7ce4',r='#3a2676',
            C='#5a3ea8',L='#7c5cd4',c='#34226a',K='#e0b040',k='#a07820',B='#3a2a5a',b='#22183a',N='#4a3a5a',n='#2a1e38',O='#ff6a3a',o='#ffc878'),
'pip': dict(H='#d8742a',A='#ffa850',I='#944414',S='#f8c898',s='#cc8c66',E='#201820',R='#3c9a4a',Q='#70cc70',r='#22602c',
            C='#3c8a4a',L='#5cb86a',c='#22562e',K='#8a5a2a',k='#5a3a1a',P='#6a5a3a',p='#463c24',B='#5a3a1a',b='#382410',M='#eef2fa',m='#8890a8',N='#6a4428'),
}
POSES={ # top, bottom, head offset, weapon orientation
 'stand':('stand','stand',(0,0),'down'), 'walk':('stand','walk',(0,0),'down'),
 'atk1':('atk1','stand',(1,0),'back'), 'atk2':('atk2','lunge',(-1,1),'fwd'),
 'cast':('cast','stand',(0,0),'up'), 'hurt':('hurt','walk',(2,1),'back'),
 'victory':('victory','stand',(0,0),'up'), 'kneel':(None,None,(0,4),'down')}

def hexc(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))+(255,)

def compose(hero,pose):
    body,weap=HERO[hero]; pal=PAL[hero]; top,bot,(hx,hy),wo=POSES[pose]
    grid=[[None]*W for _ in range(H)]; hand=None
    def put(rows,ox,oy):
        nonlocal hand
        for y,row in enumerate(rows):
            for x,ch in enumerate(row):
                if ch=='.': continue
                X,Y=ox+x+PADL,oy+y+PADT
                if ch=='@': hand=(X,Y); ch='S'
                if 0<=X<W and 0<=Y<H: grid[Y][X]=ch
    if pose=='kneel': put(KNEEL[body],0,16)
    else: put(TOPS[top],0,12); put(BOTTOMS[body][bot],0,18)
    if pose=='victory':
        for y in range(6,12): grid[y+PADT][1+PADL]='L'
        hand=(1+PADL,5+PADT); grid[hand[1]][hand[0]]='S'
    put(HEADS[hero],hx,hy)
    if pose=='victory': grid[hand[1]][hand[0]]='S'; grid[hand[1]+1][hand[0]]='L'
    w=WEAP[weap][wo]
    gx=gy=0
    for y,row in enumerate(w):
        if '@' in row: gy,gx=y,row.index('@')
    for y,row in enumerate(w):
        for x,ch in enumerate(row):
            if ch=='.' : continue
            X,Y=hand[0]+x-gx,hand[1]+y-gy
            if ch=='@': ch='S'
            if 0<=X<W and 0<=Y<H: grid[Y][X]=ch
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    for y in range(H):
        for x in range(W):
            ch=grid[y][x]
            if ch: px[x,y]=hexc(pal.get(ch,'#ff00ff'))
    # outline
    for y in range(H):
        for x in range(W):
            if grid[y][x]: continue
            if any(0<=x+a<W and 0<=y+b<H and grid[y+b][x+a] for a,b in ((1,0),(-1,0),(0,1),(0,-1))):
                px[x,y]=OUTLINE
    return img

if __name__=='__main__':
    sheet=Image.new('RGBA',(8*(W*5+10),4*(H*5+10)),(60,60,80,255))
    for r,hero in enumerate(HERO):
        for c,pose in enumerate(POSES):
            im=compose(hero,pose); im.save(f'{OUT_DIR}/hero_{hero}_{pose}.png')
            sheet.alpha_composite(im.resize((W*5,H*5),Image.NEAREST),(c*(W*5+10)+5,r*(H*5+10)+5))
    sheet.save('hero_sheet.png'); print(W,H)
