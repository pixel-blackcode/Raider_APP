"""Images des fiches Google Play / App Store à partir du logo officiel.

Usage : python3 -I tool/make_store_graphics.py  (depuis la racine du dépôt)
Produit store/icon-512.png (Google Play), store/icon-1024.png (App Store,
sans transparence) et store/feature-graphic.png (bannière Play 1024 × 500).
"""
from PIL import Image, ImageDraw, ImageFont

LOGO = 'assets/brand/logo_icon.png'
FONT = 'assets/fonts/BarlowCondensed-800.ttf'
MARINE = (20, 33, 61)
ORANGE = (232, 89, 12)

icon = Image.open(LOGO).convert('RGBA')
for size, name in ((512, 'icon-512.png'), (1024, 'icon-1024.png')):
    bg = Image.new('RGB', (size, size), (22, 22, 22))
    im = icon.resize((size, size), Image.LANCZOS)
    bg.paste(im, (0, 0), im)
    bg.save(f'store/{name}', optimize=True)

W, H = 1024, 500
fg = Image.new('RGB', (W, H), MARINE)
d = ImageDraw.Draw(fg)
d.rectangle([0, H - 14, W, H], fill=ORANGE)
mark = icon.resize((300, 300), Image.LANCZOS)
mask = Image.new('L', (300, 300), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, 299, 299], radius=64, fill=255)
alpha = Image.composite(mark.getchannel('A'), mask, mask)
fg.paste(mark, (70, 100), alpha)
title = ImageFont.truetype(FONT, 112)
sub = ImageFont.truetype(FONT, 46)
d.text((410, 120), 'Rider Group', font=title, fill=(255, 255, 255))
d.text((414, 262), 'Balades, clubs et sécurité', font=sub, fill=(252, 163, 17))
d.text((414, 316), 'pour les motards', font=sub, fill=(252, 163, 17))
fg.save('store/feature-graphic.png', optimize=True)
print('ok')
