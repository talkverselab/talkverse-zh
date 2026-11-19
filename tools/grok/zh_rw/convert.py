"""out/<id>.md(Grok 답) 검사 → data/review/final/<id>.txt + data/review/<id>_grok_rewrite.md. 문제 있으면 이유를 찍고 건너뜀.
  python3 convert.py <id>...   (없으면 out/ 전부)"""
import json,glob,re,sys,os,shutil
R='/Users/talkverse/talkverse/zh'; H=os.path.dirname(os.path.abspath(__file__))
EMO=set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
BAD=re.compile(r'새로 ?씀|callback|콜백|hook|턴 ?\d|#\d|ep\d|초안|작성용',re.I)
EM=re.compile(r'[\U0001F300-\U0001FAFF☀-➿]')
def norm(s): return re.sub(r'[\s，。！？、,.!?…~～]','',EM.sub('',s))
ids=sys.argv[1:] or sorted(os.path.basename(p)[:-3] for p in glob.glob(f'{H}/out/*.md'))
ok=[]
for id_ in ids:
    e=json.load(open(glob.glob(f'{R}/assets/data/dialogues/R*/*/{id_}.json')[0]))
    txt=open(f'{H}/out/{id_}.md').read()
    rows=[l for l in txt.splitlines() if re.match(r'^\d+ [AB] \|',l.strip())]
    errs=[]; same=[]; out=[]
    if len(rows)!=len(e['turns']): errs.append(f'턴 {len(rows)}/{len(e["turns"])}')
    for l,t in zip(rows,e['turns']):
        c=[x.strip() for x in l.strip().split('|')]
        m=re.match(r'(\d+) ([AB])',c[0]); n,s=int(m[1]),m[2]
        if n!=t['num'] or s!=t['speaker']: errs.append(f'#{n} 번호/화자')
        zh,py,ko=c[1],c[2],c[3]
        rest=c[4:]; emo_i=[i for i,x in enumerate(rest) if x.startswith('emotion=')]
        if not emo_i: errs.append(f'#{n} emotion 없음'); continue
        k=emo_i[0]; note=' | '.join(rest[:k]).strip(); emo=('|'.join(rest[k:]))[8:].strip()
        if '|' in emo or ':' in emo:
            segs=[x.split(':',1) for x in emo.split('|')]
            if any(len(x)!=2 or x[0].strip() not in EMO for x in segs): errs.append(f'#{n} 감정 {emo}')
            elif norm(''.join(x[1] for x in segs))!=norm(zh): errs.append(f'#{n} segs≠zh')
        elif emo not in EMO: errs.append(f'#{n} 감정 {emo}')
        if BAD.search(note): errs.append(f'#{n} note 표시: {note}')
        if EM.search(zh): zh=EM.sub('',zh).strip()
        zh=zh.replace('马克','{name}').replace('Mark','{name}'); ko=ko.replace('마크','{name}')
        if norm(zh)==norm(t['zh']): same.append(n)
        zh,py,ko,note=[x.replace(' / ','/') for x in (zh,py,ko,note)]
        out.append(f'{n} {s}: {zh} / {py} / {ko} / {note} / {emo}')
    if errs: print(id_,'✗',errs); continue
    if same: open(f'{H}/same.txt','a').write(f'{id_} {same}\n')
    open(f'{R}/data/review/final/{id_}.txt','w').write('\n'.join(out)+'\n')
    shutil.copy(f'{H}/out/{id_}.md',f'{R}/data/review/{id_}_grok_rewrite.md'); ok.append(id_)
print('통과',len(ok)); open(f'{H}/ok.txt','a').write(''.join(i+'\n' for i in ok))
