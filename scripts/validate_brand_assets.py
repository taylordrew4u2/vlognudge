"""Validate generated iOS icon sizes, catalogs and contrast (no Apple SDK needed)."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
count=0
for catalog in [ROOT/'vlognudgee/Assets.xcassets/AppIcon.appiconset',ROOT/'vlog/Assets.xcassets/AppIcon.appiconset',ROOT/'design/vlognudge-logo/Legacy/AppIcon.appiconset',ROOT/'vlognudgee/Assets.xcassets/VlogNudgeMark.imageset']:
    data=json.loads((catalog/'Contents.json').read_text())
    for entry in data['images']:
        path=catalog/entry['filename']
        assert path.is_file(), path
        if path.suffix=='.png':
            image=Image.open(path)
            scale=int(entry.get('scale','1x')[:-1])
            pixels=round(float(entry['size'].split('x')[0])*scale)
            assert image.size==(pixels,pixels),(path,image.size,pixels)
            assert image.mode=='RGB',(path,image.mode)
        else:
            assert path.read_bytes().startswith(b'%PDF'),path
        count+=1
sizes={20,29,40,58,60,76,80,87,120,152,167,180,1024}
for style in ['light','dark','tinted']:
    for size in sizes:
        path=ROOT/f'design/vlognudge-logo/AllSizes/{style}/VlogNudge-{style}-{size}.png'
        assert Image.open(path).size==(size,size),path
        count+=1
assert Image.open(ROOT/'design/vlognudge-logo/logo.png').size[0]==1600
assert Image.open(ROOT/'design/vlognudge-logo/logo-icon.png').size==(1024,1024)

def luminance(hex):
    values=[int(hex[i:i+2],16)/255 for i in (0,2,4)]
    values=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values]
    return sum(a*b for a,b in zip(values,[.2126,.7152,.0722]))
for fg,bg in [('182F2C','F5F2EA'),('536660','F5F2EA'),('5B6B64','F5F2EA'),('FFFFFF','17665B'),('F5F2EA','101F1C'),('B7C9BF','101F1C'),('102D24','94D8BF')]:
    a,b=sorted([luminance(fg),luminance(bg)])
    ratio=(b+.05)/(a+.05)
    assert ratio>=4.5,(fg,bg,ratio)
    print(f'Contrast #{fg} / #{bg}: {ratio:.2f}:1')
print(f'PASS: {count} asset entries/exports verified; icon RGB, dimensions, vector headers and text contrast.')
