# FF5-style monsters: larger than heroes, hand-shaded ramps (a dark .. e highlight), auto dark outline.
from PIL import Image
OUT='out'
def norm(rows,w): return [r.ljust(w,'.')[:w] for r in rows]
ART={}
ART['gel']=norm([""]*9+[
"...........ccccccccc",
".........ccdddddddcccc",
".......ccdddeeedddddccc",
"......cdddeeeeddddddcccb",
".....cdddeeedddddddddccbb",
"....cddddeedddddddddddcccbb",
"....cdddddddddddddddddccccbb",
"...cddddddddddddxxddddxxccbbb",
"...cdddddddddddxxyddddxyxcbbb",
"..ccddddddddddddxxddddxxccbbbb",
"..cccdddddddddddddddddddcccbbb",
"..ccccddddddddddddddddcccccbbb",
".bccccdddddddddbbbbddcccccbbbbb",
".bcccccdddddddbaaaabdccccccbbbb",
".bbccccccdddddbaaaabcccccccbbbb",
".bbbcccccccccccbbbbccccccbbbbbb",
".bbbbccccccccccccccccccbbbbbbbb",
"..bbbbbccccccccccccccbbbbbbbbb",
"..abbbbbbbbbbbbbbbbbbbbbbbbbaa",
"...aaabbbbbbbbbbbbbbbbbbbbaaa",
".....aaaaaaaaaaaaaaaaaaaaaa",""],32)
ART['bat']=norm([""]*6+[
"..a.........................a",
"..ba.......................ab",
"..bba..........a..a.......abb",
"..bcba........ab..ba.....abcb",
"..bccba.......abccba....abccb",
"..bcccbba....abccccba.abbcccb",
"..bccccccbba.bcxccxcbabbccccb",
"..bccdccccccbbcyxccyxcbbcdcccb",
".bccdddccccccccccccccccccdddccb",
".bcdd.dcccccccccwccwcccccd.ddcb",
".bcd...dccccccccdddcccccd....db",
".bd.....ddcccccbcdcbccdd......d",
".b........d.dccbbbbbbcd.d",
"...............bbbbbb",
"................bbbb",""],32)
ART['imp']=norm(["","",
"..........a..........a",
"..........ba........ab",
"...........ba......ab",
"...........bbcccccccb",
"..........bccdddddcccb",
".........bcddddddddccb",
"...a....bcdddddddxxdccb..a",
"...bbb.bcddddddddxyddccbbb",
"....bcbcddddddddddddccbcb",
".....bbcdddddwvwvwvdcccbb",
".......bcdddddaaaaaacccb",
"........bccdddddddccccb",
".........bbccccccccbbb",
"......bbccbbbcccccbbccbb.....gh",
".....bcddcccccccccccccdcb...ggh",
"....bcdd.bccddddddcccb.dcb.ggh",
"....bcd..bcdddddddcccb..dcbggh",
"....bcb..bccddddddccb...bccgh",
"....bcb..bbcccccccccb....bcbf",
"....bdb...fffffffffff....ff",
"....bb....fggggggggf",
"..........fghhggghhf",
"...........fgg.fggf",
"...........bcc..bcc",
"...........bcc..bcc",
"...........bcc..bcc",
"..........bccc..bccc",
".........bbccc..bcccb",
".........bbbb...bbbbb",""],32)
ART['skel']=norm(["",
"...........vwwwwwv",
"..........vwwwwwwwwv",
".........vwwwwwwwwwwv",
".........vwwaawwwaawv",
".........vwaxawwaxawv",
".........vwwaawwwaawv",
"..........vwwwwawwwwv",
"...........vwwaaawwv",
"...........vawawawav",
"............vwwwwwv",
"..............vwv",
"..........vvwwwwwwwvv.......h",
".........vw.vwwwwwv.wv......hg",
"........vw.vwavwavw..wv.....hg",
"........vw..vwwwwwv...wv...hg",
"........vw.vwavwavwv..vw..hg",
"........vw..vwwwwwv....wvhg",
"........vv...vwawv......wvg",
"...............wvw......ff",
"............vwwwwwwv",
"...........vw.vwv.wv",
"...........vw.....wv",
"...........vw.....wv",
"...........vw.....wv",
"...........vv.....vv",
"...........vw.....wv",
"...........vw.....wv",
"...........vw.....wv",
"..........vww.....wwv",
"..........vvv.....vvv",""],32)
ART['wolf']=norm([""]*7+[
"........................bb.b",
".......................bcbbcb",
".......................bcccccb",
"......................bccdxcccb",
"a.....................bcdyxccccb",
"ba...................bcdddccccccb",
"bba.................bcddddcccwwwb",
".bbbbbbbbbbbbbbbbbbbcddddcccbbbb",
"..bcccdddddddddddddddddddcccb",
"..bcddddddeeeeeeddddddddccccb",
"..bcddddddddddddddddddddcccb",
"...bcdddddddddddddddddccccb",
"...bccdddddccccccdddddcccb",
"....bccccccbbbbbbccccccccb",
"....bccb.bcb....bccb..bccb",
"....bcb..bcb.....bcb..bcb",
"....bcb..bcb.....bcb..bcb",
"...bcb...bcb.....bcb...bcb",
"...bcb....bcb....bcb...bcb",
"..bcb.....bcb...bcb.....bcb",
".bbbb....bbbb..bbbb....bbbb",""],32)
ART['golem']=norm(["",
"................bbbbbbbbbbbbbb",
"..............bbccccccccccccccbb",
".............bcccddddddddddcccccb",
"............bcccdddeedddddddcccccb",
"............bccdddddddddddddddcccb",
"............bccdxxxdddddddxxxdcccb",
"............bccdxyxdddddddxyxdcccb",
"............bcccddddddddddddddcccb",
"............bccccccaaaaaaaacccccbb",
".............bbccccccccccccccbbbb",
"......bbbbbb...bbbbbbbbbbbbbb...bbbbbb",
"....bbccccccbbbbccccccccccccbbbbccccccbb",
"...bcccddddccbcccddddddddddcccbccddddcccb",
"..bccddddddcccbccdddeeeeddddccbcccdddddccb",
"..bcdddeedddccbcdddddddddddddcbccddeedddcb",
"..bcddddddddcbccddddxxxxddddddcbcddddddddcb",
"..bccdddddddcbcdddddxyyxdddddddbcddddddccb",
"..bbccdddddcbbcddddddxxddddddddbbcddddccbb",
"...bbcccccccbcccdddddddddddddcccbcccccccbb",
"....bbccccbb.bcccdddddddddddcccb.bbccccbb",
".....bcddcb..bbcccccddddcccccccb..bcddcb",
".....bcddcb...bbccccccccccccccbb..bcddcb",
"....bcdddcb....bbbbbbbbbbbbbbbb...bcdddcb",
"....bcddddcb...bccccbbbbbbccccb..bcddddcb",
"...bcddeddcb...bcdddcb..bcdddcb..bcddedddcb",
"...bcdddddcb...bcdddcb..bcdddcb..bcdddddcb",
"...bccdddccb...bcdddcb..bcdddcb..bccdddccb",
"....bbcccbb....bcdddcb..bcdddcb...bbcccbb",
"......bbb......bcdddcb..bcdddcb.....bbb",
"..............bccdddcb..bcdddccb",
".............bcccdddcb..bcdddcccb",
".............bccddddcb..bcddddccb",
"............bcccddddcb..bcddddcccb",
"............bbbbbbbbbb..bbbbbbbbbb",""],48)
ART['wyrm']=norm(["",
"....................................bb.b",
"...................................bccbcb",
"..................................bcdddccb",
".................................bcddxxdcb",
"..f..............................bcdyxddccbbb",
".fgf............................bcddddddcccccb",
".fggf...........................bcddddddddddccwb",
"fgghgf..........................bccdddccccbbwwb",
"fghhggf.........................bbccccbbb..bb",
"fghhhggf.........................bcccb",
"fgghhhggf.......................bcddcb",
".fgghhhggff....................bcdddcb",
".fggghhhgggff.................bcdddcb",
"..fgggghhhgggff..............bcdddcb",
"..fggggghhhggggff...........bcdddcb",
"...fggggghhhgggggff........bcdddcb",
"...fgggggghhhgggggfff.....bcdddcb",
"....fggggggghhgggggggf...bcddddcb",
"....fgggggggghhgggggggfbbcdddddcb",
".....fggggggggghggggggbccdddddcb",
".....ffgggggggggggggbccddddddccb",
"......ffggggggggggbcccdddeeddddcb",
"........fffgggggbccdddddeeeddddcb",
"...........fffbbcccddddddeeddddccb",
"..............bcccddddddddddddddcb",
".............bcccddddhhhhhdddddccb",
"............bccddddhhhhhhhhddddcb",
"...........bccdddhhhhhhhhhhhdddcb",
"..........bccdddhhhhhhhhhhhhhddcb",
".........bccdddddhhhhhhhhhhhhddcb",
"........bccddddddddhhhhhhhhhdddcb",
"bb.....bccddddddddddddddddddddccb",
"bcbb..bccdddddddddddddddddddddcb",
"bccdbbccdddddcccbbbbcccdddddcccb",
".bccdddddddccbb.....bbbccdddccb",
"..bbccddddcbb..........bcdddcb",
"....bbbbbb.............bcdddcb",
".......................bcdddcbb",
"......................bcdddcccb",
"......................bcdddcddcb",
".....................bbwbwbbwbwb",""],48)
PALS={
 'gel':dict(a='#1e5a24',b='#2f8a3a',c='#4cba52',d='#7ee07a',e='#d8ffd0',x='#102018',y='#ffffff'),
 'fgel':dict(a='#1a3a7a',b='#2a5ab0',c='#4a8ae0',d='#86c0ff',e='#e8f6ff',x='#0c1830',y='#ffffff'),
 'bat':dict(a='#2a1838',b='#4a2a62',c='#6a4a8a',d='#9070b0',x='#ff3030',y='#ffd0d0',w='#ffffff'),
 'vbat':dict(a='#3a0814',b='#6a1424',c='#9a2236',d='#c84a5a',x='#ffe050',y='#ffffff',w='#ffffff'),
 'imp':dict(a='#2a1410',b='#3e6a22',c='#5a9a30',d='#80c84a',x='#ffd83a',y='#ffffff',w='#f4f0e0',v='#b0a890',f='#4a2a14',g='#7a4a24',h='#a87040'),
 'shade':dict(a='#100818',b='#2a1a40',c='#3e2a60',d='#5a4488',x='#d050ff',y='#ffe0ff',w='#c0a0e0',v='#806aa0',f='#1a1028',g='#2e2048',h='#4a3a70'),
 'wraith':dict(a='#081020',b='#14284a',c='#22406e',d='#3a6a9a',x='#7af0ff',y='#ffffff',w='#a0e0f0',v='#5aa0c0',f='#0a1424',g='#1a2e4a',h='#2e4a70'),
 'skel':dict(a='#3a2e24',v='#a89a80',w='#eae4d0',x='#ff3a3a',f='#5a3a1a',g='#8890a8',h='#e8eef8'),
 'bknight':dict(a='#141c2a',v='#6a7a96',w='#c4ccdc',x='#4af0ff',f='#2a2a3a',g='#6a70a0',h='#d0d8f8'),
 'monarch':dict(a='#401010',v='#c0a050',w='#f4e8b8',x='#ff2a6a',f='#601a1a',g='#c09030',h='#ffe890'),
 'wolf':dict(a='#1a1a20',b='#3a3a44',c='#62626e',d='#9090a0',e='#c8c8d4',x='#ffcc33',y='#ffffff',w='#ffffff'),
 'hound':dict(a='#1a0604',b='#4a1008',c='#7a2010',d='#b04020',e='#e87040',x='#ffe040',y='#ffffff',w='#ffffff'),
 'golem':dict(a='#2a2a24',b='#4a4a40',c='#6e6e60',d='#9a9a88',e='#c8c8b4',x='#ff5a2a',y='#ffe0a0'),
 'wyrm':dict(a='#140c24',b='#22163e',c='#3a2a5e',d='#54448a',e='#7a6ab8',x='#ff2a5a',y='#ffd0e0',w='#f0e8f8',f='#2a1440',g='#5a2a8a',h='#8a5ac0'),
}
BASE={'gel':'gel','fgel':'gel','bat':'bat','vbat':'bat','imp':'imp','shade':'imp','wraith':'imp','skel':'skel','bknight':'skel','monarch':'skel',
      'wolf':'wolf','hound':'wolf','golem':'golem','wyrm':'wyrm'}
NAMEMAP={'golem':'warden'}  # game key for the golem
def hexc(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))+(255,)
def render(key):
    rows=ART[BASE[key]]; pal=PALS[key]; w=len(rows[0]); h=len(rows)
    W,H=w+2,h+2
    grid=[[None]*W for _ in range(H)]
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch!='.' and ch in pal: grid[y+1][x+1]=pal[ch]
    if key=='monarch':  # gold crown + cape over the skeleton
        for x,y in [(11,1),(13,0),(15,1),(17,0),(19,1)]: grid[y][x]=pal['h']
        for x in range(11,21): grid[2][x]=pal['g']
        for y in range(13,22):
            for x in range(9,12):
                if grid[y][x] is None: grid[y][x]='#7a1428' if x>9 else '#4a0a18'
    img=Image.new('RGBA',(W,H),(0,0,0,0)); px=img.load()
    for y in range(H):
        for x in range(W):
            if grid[y][x]: px[x,y]=hexc(grid[y][x])
    for y in range(H):
        for x in range(W):
            if grid[y][x]: continue
            if any(0<=x+a<W and 0<=y+b<H and grid[y+b][x+a] for a,b in ((1,0),(-1,0),(0,1),(0,-1))):
                px[x,y]=(20,14,26,255)
    if key=='monarch': img=img.resize((int(W*1.5),int(H*1.5)),Image.NEAREST)
    return img
if __name__=='__main__':
    keys=list(PALS)
    sheet=Image.new('RGBA',(7*260,2*270),(60,60,80,255))
    for i,k in enumerate(keys):
        im=render(k); im.save(f'{OUT}/enemy_{NAMEMAP.get(k,k)}.png')
        s=4 if im.width<=36 else (3 if im.width<=52 else 2)
        sheet.alpha_composite(im.resize((im.width*s,im.height*s),Image.NEAREST),((i%7)*260+5,(i//7)*270+5))
    sheet.save('monster_sheet.png')
