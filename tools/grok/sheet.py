"""컨택트시트: python sheet.py <out.jpg> <편id>... — 편마다 한 줄(컷 4장, 각 390x262)"""
import sys,glob
from PIL import Image, ImageDraw
out=sys.argv[1]; ids=sys.argv[2:]; W,H=390,262
rows=[]
for id_ in ids:
    fs=sorted(glob.glob(f'data/review/art/{id_}/cut*.jpg'), key=lambda f:int(f.split('cut')[-1].split('.')[0]))
    rows.append((id_,fs))
sheet=Image.new('RGB',(W*4,(H+18)*len(rows)),'white'); d=ImageDraw.Draw(sheet)
for r,(id_,fs) in enumerate(rows):
    y=r*(H+18); d.text((4,y+2),id_,fill='black')
    for i,f in enumerate(fs[:4]):
        sheet.paste(Image.open(f).resize((W,H)),(i*W,y+18))
sheet.save(out,quality=80); print(out)
