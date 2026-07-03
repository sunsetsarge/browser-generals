"""Generate Browser Generals PWA launcher icons programmatically (no AI gen).
A bold gold 5-point general's star on a dark military-green field.
Outputs icon-192.png, icon-512.png, icon-512-maskable.png in the repo root.
Run with:  C:/ComfyUI/.venv/Scripts/python.exe make_icons.py
"""
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))

BG      = (26, 29, 22, 255)     # #1a1d16 dark military
FIELD   = (46, 52, 36, 255)     # #2e3424 lighter olive disc
RING     = (74, 82, 56, 255)    # #4a5238 border tone
GOLD    = (232, 192, 96, 255)   # #e8c060
GOLD_HI = (255, 226, 150, 255)  # highlight
GOLD_LO = (168, 128, 48, 255)   # shadow edge

def star_points(cx, cy, r_out, r_in, rot=-math.pi/2):
    pts = []
    for i in range(10):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts

def render(size, safe=1.0, disc=True):
    """safe<1.0 shrinks all content into the maskable safe zone."""
    SS = 4  # supersample for crisp edges
    S = size * SS
    img = Image.new("RGBA", (S, S), BG)
    d = ImageDraw.Draw(img)
    cx = cy = S / 2
    content = (S / 2) * safe

    if disc:
        # olive disc backdrop with a subtle ring
        rr = content * 0.98
        d.ellipse([cx-rr, cy-rr, cx+rr, cy+rr], fill=FIELD, outline=RING, width=int(6*SS))

    # star
    r_out = content * 0.82
    r_in  = r_out * 0.40
    # drop shadow
    sh = star_points(cx, cy+content*0.03, r_out, r_in)
    d.polygon(sh, fill=(0, 0, 0, 90))
    # main star
    pts = star_points(cx, cy, r_out, r_in)
    d.polygon(pts, fill=GOLD, outline=GOLD_LO)
    # inner facet highlight (smaller star, offset up-left)
    hp = star_points(cx - content*0.02, cy - content*0.03, r_out*0.62, r_in*0.62)
    d.polygon(hp, fill=GOLD_HI)
    hp2 = star_points(cx, cy, r_out*0.42, r_in*0.42)
    d.polygon(hp2, fill=GOLD)

    return img.resize((size, size), Image.LANCZOS)

def main():
    render(192).save(os.path.join(HERE, "icon-192.png"))
    render(512).save(os.path.join(HERE, "icon-512.png"))
    # maskable: fill entire canvas with BG (no transparent corners) + safe-zone padding
    m = render(512, safe=0.78)
    m.save(os.path.join(HERE, "icon-512-maskable.png"))
    print("wrote icon-192.png, icon-512.png, icon-512-maskable.png")

if __name__ == "__main__":
    main()
