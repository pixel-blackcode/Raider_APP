"""Dessine le logo Rider Group (variante B : épingle orange, motard sur la route)
et produit les icônes Android / iOS et l'image utilisée dans l'application.

Usage : python3 -I tool/make_logo.py  (depuis la racine du dépôt)
"""
import math
import os
from PIL import Image, ImageDraw

S = 4096            # dessin en très haute résolution, puis réduction
K = S / 1024
DARK = (22, 22, 22, 255)
ORANGE = (255, 122, 0, 255)
WHITE = (242, 239, 234, 255)


def sc(*v):
    return [x * K for x in v]


def pin(d, cx, cy, r, tip_y, fill):
    """Épingle de carte : cercle + pointe reliée par les tangentes."""
    d.ellipse(sc(cx - r, cy - r, cx + r, cy + r), fill=fill)
    dist = tip_y - cy
    a = math.acos(r / dist)
    left = (cx - r * math.sin(a), cy + r * math.cos(a))
    right = (cx + r * math.sin(a), cy + r * math.cos(a))
    d.polygon([tuple(sc(*left)), tuple(sc(*right)), tuple(sc(cx, tip_y))], fill=fill)


def wheel(d, cx, cy, r, w):
    d.ellipse(sc(cx - r, cy - r, cx + r, cy + r), outline=WHITE, width=int(w * K))
    h = r * 0.32
    d.ellipse(sc(cx - h, cy - h, cx + h, cy + h), fill=ORANGE)


def rider(d, ox, oy, s):
    """Motard casqué sur sa moto ; (ox, oy) = centre, s = échelle."""
    P = lambda x, y: (ox + x * s, oy + y * s)
    poly = lambda pts, c: d.polygon([tuple(sc(*P(*p))) for p in pts], fill=c)
    # Roues
    wheel(d, *P(-64, 40), 31 * s, 12 * s)
    wheel(d, *P(66, 40), 31 * s, 12 * s)
    # Moto : bloc moteur, réservoir, selle, carénage arrière, fourche, guidon
    poly([(-40, 40), (-24, 8), (34, 8), (50, 40), (30, 40), (18, 26), (-10, 26), (-20, 40)], WHITE)
    poly([(-70, 2), (-30, -10), (40, -12), (56, 6), (34, 14), (-26, 14), (-66, 14)], WHITE)
    poly([(-80, -2), (-62, -10), (-60, 4), (-78, 6)], WHITE)
    poly([(44, 0), (56, -30), (64, -30), (74, 38), (62, 40), (54, 6)], WHITE)
    poly([(48, -34), (76, -40), (78, -32), (52, -26)], WHITE)
    # Motard : jambe pliée, buste penché, bras vers le guidon
    poly([(-24, -10), (2, -10), (16, 20), (2, 24), (-10, 2)], WHITE)
    poly([(-34, -12), (-10, -62), (12, -56), (4, -10)], WHITE)
    poly([(0, -54), (56, -34), (50, -24), (-6, -40)], WHITE)
    # Casque orange + visière sombre
    hx, hy = P(6, -80)
    hr = 23 * s
    d.ellipse(sc(hx - hr, hy - hr, hx + hr, hy + hr), fill=ORANGE)
    d.rounded_rectangle(sc(hx - hr * 0.05, hy - hr * 0.38, hx + hr * 1.05, hy + hr * 0.12),
                        radius=6 * K * s, fill=DARK)


def road(d, cx, y, half, w):
    pts = []
    for i in range(0, 101):
        t = i / 100
        x = cx - half + 2 * half * t
        yy = y + math.sin(t * math.pi * 2) * 9
        pts.append(tuple(sc(x, yy)))
    d.line(pts, fill=WHITE, width=int(w * K), joint='curve')
    for p in (pts[0], pts[-1]):
        r = w * K / 2
        d.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=WHITE)


def draw_mark(d, cx=512, cy=420, r=270):
    pin(d, cx, cy, r, cy + r * 1.75, ORANGE)
    ir = r * 0.70
    d.ellipse(sc(cx - ir, cy - ir, cx + ir, cy + ir), fill=DARK)
    k = r / 270 * 1.25
    rider(d, cx - 4 * k, cy - 4 * k, k)
    road(d, cx, cy - 4 * k + 71 * k + 8 * k, ir * 0.80, 12 * r / 270)


def icon(background=True, mark_scale=1.0):
    img = Image.new('RGBA', (S, S), DARK if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 245 * mark_scale
    draw_mark(d, 512, 512 - r * 0.38, r)
    return img.resize((1024, 1024), Image.LANCZOS)


def save(img, path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if path.endswith('.png') and 'ios' in path:
        out = out.convert('RGB')  # l'App Store refuse la transparence
    out.save(path)


full = icon(True)
save(full, 'assets/brand/logo_icon.png', 1024)
# Repère seul, fond transparent (écran de connexion).
save(icon(False), 'assets/brand/logo_mark.png', 512)

# Android : icône classique (les lanceurs l'arrondissent eux-mêmes).
for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save(full, f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png', px)

# iOS : toutes les tailles déclarées dans Contents.json.
import json
base = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for im in json.load(open(f'{base}/Contents.json'))['images']:
    pts = float(im['size'].split('x')[0])
    scale = int(im['scale'].rstrip('x'))
    save(full, f"{base}/{im['filename']}", int(round(pts * scale)))
print('ok')
