"""Regenerate native iOS assets from the SVG master; requires Inkscape and Pillow."""
from pathlib import Path
import json, subprocess, shutil
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design/vlognudge-logo'
OUT.mkdir(parents=True, exist_ok=True)

def mark(color):
    return f'''<path d="M704 256H328c-80 0-144 64-144 144v224c0 80 64 144 144 144h368c80 0 144-64 144-144V400" fill="none" stroke="{color}" stroke-width="64" stroke-linecap="round"/><path d="M440 388L636 512 440 636Z" fill="{color}" stroke="{color}" stroke-width="24" stroke-linejoin="round"/><circle cx="832" cy="224" r="72" fill="{color}"/>'''

def svg(content, box='0 0 1024 1024'):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{box}"><title>VlogNudge — a moment, a gentle nudge</title>{content}</svg>'

def render(source, dest, width, pdf=False):
    args=['inkscape', str(source), '--export-filename='+str(dest)]
    if not pdf: args += ['--export-width='+str(width)]
    subprocess.run(args,check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

(OUT/'logo-icon.svg').write_text(svg(mark('#17665B')))
(OUT/'logo.svg').write_text(svg('<g transform="translate(0,0) scale(0.25)">'+mark('#17665B')+'</g><text x="288" y="164" font-family="Georgia, Times, serif" font-size="112" font-weight="bold" fill="#17665B">VlogNudge</text>', '0 0 980 256'))
render(OUT/'logo.svg',OUT/'logo.png',1600)
render(OUT/'logo-icon.svg',OUT/'logo-icon.png',1024)

# Modern universal slots: Xcode generates device sizes from each 1024 px master.
variants=[('light','#F5F2EA','#17665B'),('dark','#102D24','#F5F2EA'),('tinted','#171717','#EEEEEE')]
app_images=[]
for style,bg,fg in variants:
    filename='AppIcon.png' if style=='light' else f'AppIcon-{style}.png'
    source=OUT/f'app-icon-{style}.svg'
    source.write_text(svg(f'<path fill="{bg}" d="M0 0H1024V1024H0Z"/>'+mark(fg)))
    render(source,OUT/filename,1024)
    Image.open(OUT/filename).convert('RGB').save(OUT/filename)
    entry={'filename':filename,'idiom':'universal','platform':'ios','size':'1024x1024'}
    if style!='light': entry['appearances']=[{'appearance':'luminosity','value':style}]
    app_images.append(entry)
for target in ['vlognudgee','vlog']:
    catalog=ROOT/target/'Assets.xcassets/AppIcon.appiconset'
    catalog.mkdir(parents=True,exist_ok=True)
    for entry in app_images: shutil.copy2(OUT/entry['filename'],catalog/entry['filename'])
    (catalog/'Contents.json').write_text(json.dumps({'images':app_images,'info':{'author':'xcode','version':1}},indent=2)+'\n')

# Explicit legacy slots supplied separately: never mix duplicate slots into the active catalog.
slots=[('iphone','20',2),('iphone','20',3),('iphone','29',2),('iphone','29',3),('iphone','40',2),('iphone','40',3),('iphone','60',2),('iphone','60',3),('ipad','20',1),('ipad','20',2),('ipad','29',1),('ipad','29',2),('ipad','40',1),('ipad','40',2),('ipad','76',1),('ipad','76',2),('ipad','83.5',2),('ios-marketing','1024',1)]
legacy=OUT/'Legacy/AppIcon.appiconset'
legacy.mkdir(parents=True,exist_ok=True)
entries=[]
for idiom,point,scale in slots:
    px=round(float(point)*scale)
    name=f'Icon-{idiom}-{point}@{scale}x.png'
    Image.open(OUT/'AppIcon.png').resize((px,px),Image.Resampling.LANCZOS).save(legacy/name)
    entries.append({'filename':name,'idiom':idiom,'size':f'{point}x{point}','scale':f'{scale}x'})
(legacy/'Contents.json').write_text(json.dumps({'images':entries,'info':{'author':'xcode','version':1}},indent=2)+'\n')
# Export each appearance in every unique size, too.
for style,_,_ in variants:
    source=OUT/('AppIcon.png' if style=='light' else f'AppIcon-{style}.png')
    dest=OUT/'AllSizes'/style
    dest.mkdir(parents=True,exist_ok=True)
    for px in sorted({round(float(p)*s) for _,p,s in slots}):
        Image.open(source).resize((px,px),Image.Resampling.LANCZOS).save(dest/f'VlogNudge-{style}-{px}.png')

# PDF vectors are supported directly by Xcode; SVG remains the editable master.
imageset=ROOT/'vlognudgee/Assets.xcassets/VlogNudgeMark.imageset'
imageset.mkdir(parents=True,exist_ok=True)
images=[]
for appearance,fg in [('light','#17665B'),('dark','#94D8BF')]:
    src=OUT/f'mark-{appearance}.svg'
    src.write_text(svg(mark(fg)))
    name=f'VlogNudgeMark-{appearance}.pdf'
    render(src,imageset/name,1024,pdf=True)
    item={'filename':name,'idiom':'universal'}
    if appearance=='dark': item['appearances']=[{'appearance':'luminosity','value':'dark'}]
    images.append(item)
(imageset/'Contents.json').write_text(json.dumps({'images':images,'info':{'author':'xcode','version':1},'properties':{'preserves-vector-representation':True}},indent=2)+'\n')
shutil.copytree(imageset,OUT/'VlogNudgeMark.imageset',dirs_exist_ok=True)
shutil.copytree(ROOT/'vlognudgee/Assets.xcassets/AppIcon.appiconset',OUT/'AppIcon.appiconset',dirs_exist_ok=True)
# 1x/2x/3x transparent raster marks for clients that cannot use PDF vectors.
for scale in [1,2,3]:
    Image.open(OUT/'logo-icon.png').resize((64*scale,64*scale),Image.Resampling.LANCZOS).save(OUT/f'VlogNudgeMark@{scale}x.png')
print('Generated universal catalogs, 18 legacy slots, all appearance sizes and PDF vector marks.')
