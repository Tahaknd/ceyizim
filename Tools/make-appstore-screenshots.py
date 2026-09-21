#!/usr/bin/env python3
"""Turns raw simulator captures into App Store product page screenshots.

    python3 -m pip install pillow
    python3 Tools/make-appstore-screenshots.py            # all frames
    python3 Tools/make-appstore-screenshots.py 02-listem.png

Input :  AppStore/screenshots/raw/*.png   (6.9" captures, 1320×2868)
Output:  AppStore/screenshots/*.png       (same names, ready to upload)

Every frame is cut out of ONE panorama, so the ground, the light, the ribbons
and the lace medallions run straight through the gallery: swiping reads as a
single composition rather than a stack of separate cards. Devices alternate a
small tilt and a vertical offset for rhythm, while the headlines stay on a
fixed baseline so they do not jump during the swipe. The last frame carries no
capture — it closes the gallery with the icon and the privacy promise.

Re-run it after every recapture; nothing here is hand-edited.
"""

import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(ROOT, "AppStore", "screenshots", "raw")
OUT_DIR = os.path.join(ROOT, "AppStore", "screenshots")
FONT_DIR = os.path.join(ROOT, "Ceyizim", "Fonts")
ICON = os.path.join(ROOT, "Ceyizim", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

# 6.9" App Store size. Captures are expected at exactly this size.
W, H = 1320, 2868

# Brand — same values as Theme.swift and the app icon.
HEADLINE = (0xFF, 0xF6, 0xEF)
SUBLINE = (0xF4, 0xCD, 0xD7)
IVORY = (0xF8, 0xF1, 0xE9)
GOLD = (0xE7, 0xBE, 0x79)
SHADOW = (0x3A, 0x0C, 0x1D)
BEZEL = (0x24, 0x15, 0x1B)
BEZEL_EDGE = (0x60, 0x40, 0x4C)
STATUS_FG = (0x33, 0x22, 0x2B)

# Ground colour along the panorama: (position 0…1, colour). The gallery opens
# and closes light and dips into plum in the middle, so consecutive frames are
# always visibly different without any hard edge between them.
GROUND_STOPS = [
    (0.00, 0xC2566E),
    (0.26, 0xA8405C),
    (0.50, 0x8B3250),
    (0.72, 0xA33E5B),
    (0.88, 0xBA4D66),
    (1.00, 0x9C3A57),
]
GROUND_SHADE = 0.22        # how much darker the bottom edge is

# A word or two per headline is set in gold. Wrap it in *asterisks*.
# (file, headline, subline, tilt°, device dy)
SHOTS = [
    {"file": "01-ozet.png",
     "headline": "Çeyizin *tek bakışta*",
     "subline": "İlerleme, harcama ve düğüne kalan gün",
     "tilt": -2.5, "dy": 0},
    {"file": "02-listem.png",
     "headline": "*Hazır listeyle* hemen başla",
     "subline": "10 kategori, 111 eşya — tek dokunuşla işaretle",
     "tilt": 2.5, "dy": 54},
    {"file": "03-kategori-detay.png",
     "headline": "*Kategori kategori* ilerle",
     "subline": "Mutfaktan yatak odasına, eksik kalan hiçbir şey yok",
     "tilt": -2.5, "dy": 0},
    {"file": "04-harcamalar.png",
     "headline": "Hesabı *uygulama tutsun*",
     "subline": "Toplam, kategori grafiği ve en büyük harcamalar",
     "tilt": 2.5, "dy": 54},
    {"file": "05-esya-detay.png",
     "headline": "Her eşyanın *kendi kartı*",
     "subline": "Fotoğraf, mağaza, fiyat, hediye eden ve not",
     "tilt": -2.5, "dy": 0},
    {"file": "06-gizlilik.png",
     "closing": True,
     "headline": "Her şey *telefonunda* kalır",
     "subline": "Hesap yok, sunucu yok, reklam yok",
     "chips": ["Çevrimdışı çalışır", "CSV dışa aktarım", "Ücretsiz"],
     "capture": "01-ozet.png", "tilt": 2.5, "dy": 994},
]

PANO_W = W * len(SHOTS)

# Ribbons sweeping across the whole panorama. Most of the middle band is hidden
# behind the phones, so they are placed where they actually show: across the
# caption area and in the margins beside the devices, where each one disappears
# behind a phone and comes back out on the other side.
# (vertical centre, amplitude, wavelength, phase, thickness, opacity)
RIBBONS = [
    (1120, 300, 5400, 0.0, 360, 0.150),
    (2020, 340, 6900, 2.1, 240, 0.100),
    (560, 210, 4300, 4.0, 110, 0.065),
]

# Oya/dantel medallions embossed into the ground — the çeyiz motif, drawn as
# line work rather than a decal. They straddle frame edges on purpose.
# (centre x in frame units, centre y, radius, opacity)
MEDALLIONS = [
    (1.02, 1180, 820, 0.070),
    (3.06, 760, 640, 0.060),
    (4.92, 1760, 900, 0.055),
    (5.50, 1500, 700, 0.085),
]

# A soft light sits behind every device so the frames have depth and the swipe
# has a visible beat. (radius, opacity)
GLOW = (760, 0.085)
SCRIM = 0.13               # plum wash over the caption area, for even contrast

# Layout
MARGIN = 110
TEXT_TOP, TEXT_BOTTOM = 150, 660       # headline + subline live between these
HEADLINE_SIZE, HEADLINE_LEADING = 84, 104
SUBLINE_SIZE, SUBLINE_GAP = 46, 36
RULE_GAP = 40                          # gold hairline under the subline
SCREEN_W = 990                         # width of the capture inside the frame
SCREEN_TOP = 706
BEZEL_PAD = 20
SCREEN_RADIUS = 124

# Status bar geometry, measured on the 1320×2868 captures.
STATUS_H = 172
ISLAND = (472, 42, 847, 151)
SAMPLE_POINT = (20, 200)               # a pixel of plain app background


def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def rgb(value):
    return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)


def bezier(p0, p1, p2, p3, steps=24):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return pts


# ---------------------------------------------------------------- panorama

def _ground_at(t):
    for i in range(len(GROUND_STOPS) - 1):
        t0, c0 = GROUND_STOPS[i]
        t1, c1 = GROUND_STOPS[i + 1]
        if t0 <= t <= t1:
            k = 0 if t1 == t0 else (t - t0) / (t1 - t0)
            k = k * k * (3 - 2 * k)                     # smoothstep
            a, b = rgb(c0), rgb(c1)
            return tuple(a[j] + (b[j] - a[j]) * k for j in range(3))
    return rgb(GROUND_STOPS[-1][1])


def _ground():
    """Horizontal brand gradient with a soft vertical falloff."""
    gw, gh = 200, 40
    small = Image.new("RGB", (gw, gh))
    px = small.load()
    for x in range(gw):
        base = _ground_at(x / (gw - 1))
        for y in range(gh):
            shade = 1 - GROUND_SHADE * (y / (gh - 1)) ** 1.4
            px[x, y] = tuple(round(base[i] * shade) for i in range(3))
    return small.resize((PANO_W, H), Image.BICUBIC)


def _ribbon_mask(centre, amplitude, wavelength, phase, thickness, scale=4):
    w, h = PANO_W // scale, H // scale
    m = Image.new("L", (w, h), 0)
    top, bottom = [], []
    steps = 260
    for i in range(steps + 1):
        x = w * i / steps
        angle = 2 * math.pi * (x * scale) / wavelength + phase
        y = (centre + amplitude * math.sin(angle)) / scale
        half = (thickness / 2) * (0.75 + 0.25 * math.cos(angle * 0.7)) / scale
        top.append((x, y - half))
        bottom.append((x, y + half))
    ImageDraw.Draw(m).polygon(top + bottom[::-1], fill=255)
    return m.filter(ImageFilter.GaussianBlur(9)).resize((PANO_W, H), Image.BICUBIC)


def _petal(cx, cy, angle, r0, r1, width):
    """One lace petal, pointing along `angle`."""
    local = bezier((r0, 0), (r0 + (r1 - r0) * 0.25, -width), (r1 - (r1 - r0) * 0.25, -width), (r1, 0))
    local += bezier((r1, 0), (r1 - (r1 - r0) * 0.25, width), (r0 + (r1 - r0) * 0.25, width), (r0, 0))
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    return [(cx + x * cos_a - y * sin_a, cy + x * sin_a + y * cos_a) for x, y in local]


def _medallion(d, cx, cy, r, stroke):
    """An oya rosette in line work: dotted rim, rings, petals, inner star."""
    for i in range(28):
        a = 2 * math.pi * i / 28
        px, py = cx + math.cos(a) * r, cy + math.sin(a) * r
        d.ellipse([px - stroke * 1.7, py - stroke * 1.7, px + stroke * 1.7, py + stroke * 1.7], fill=255)
    for k in (0.90, 0.60, 0.26):
        d.ellipse([cx - r * k, cy - r * k, cx + r * k, cy + r * k], outline=255, width=stroke)
    for i in range(14):
        a = 2 * math.pi * i / 14
        d.line(_petal(cx, cy, a, r * 0.62, r * 0.88, r * 0.075) + [(cx + math.cos(a) * r * 0.62,
                                                                    cy + math.sin(a) * r * 0.62)],
               fill=255, width=stroke, joint="curve")
    for i in range(7):
        a = 2 * math.pi * i / 7 + math.pi / 7
        d.line(_petal(cx, cy, a, r * 0.10, r * 0.24, r * 0.05) + [(cx + math.cos(a) * r * 0.10,
                                                                   cy + math.sin(a) * r * 0.10)],
               fill=255, width=stroke, joint="curve")


def _glow_mask(scale=4):
    radius, opacity = GLOW
    w, h = PANO_W // scale, H // scale
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    for index, shot in enumerate(SHOTS):
        cx = (index * W + W / 2) / scale
        cy = (SCREEN_TOP + shot["dy"] + 620) / scale
        r = radius / scale
        for step in range(6, 0, -1):
            rr = r * step / 6
            d.ellipse([cx - rr, cy - rr * 1.25, cx + rr, cy + rr * 1.25],
                      fill=round(255 * opacity * (1 - step / 7)))
    return m.filter(ImageFilter.GaussianBlur(26)).resize((PANO_W, H), Image.BICUBIC)


def _scrim_mask():
    """Plum wash that fades out below the captions, so text contrast is even."""
    small = Image.new("L", (1, 48))
    px = small.load()
    for y in range(48):
        t = y / 47
        px[0, y] = round(255 * SCRIM * max(0.0, 1 - (t / 0.30) ** 1.6))
    return small.resize((PANO_W, H), Image.BICUBIC)


def panorama():
    canvas = _ground().convert("RGBA")
    canvas.paste(Image.new("RGBA", (PANO_W, H), SHADOW + (255,)), (0, 0), _scrim_mask())

    for centre, amp, wave, phase, thick, opacity in RIBBONS:
        m = _ribbon_mask(centre, amp, wave, phase, thick)
        canvas.paste(Image.new("RGBA", (PANO_W, H), IVORY + (255,)), (0, 0),
                     m.point(lambda v: round(v * opacity)))

    for fx, cy, r, opacity in MEDALLIONS:
        m = Image.new("L", (PANO_W, H), 0)
        _medallion(ImageDraw.Draw(m), fx * W, cy, r, max(5, round(r * 0.009)))
        m = m.filter(ImageFilter.GaussianBlur(2))
        canvas.paste(Image.new("RGBA", (PANO_W, H), IVORY + (255,)), (0, 0),
                     m.point(lambda v: round(v * opacity)))

    canvas.paste(Image.new("RGBA", (PANO_W, H), IVORY + (255,)), (0, 0), _glow_mask())
    return canvas


# --------------------------------------------------------------- status bar

def normalise_status_bar(shot):
    """Repaint the captured status bar as 9:41 with full signal."""
    d = ImageDraw.Draw(shot)
    bg = shot.getpixel(SAMPLE_POINT)
    d.rectangle([0, 0, W, STATUS_H], fill=bg)
    d.rounded_rectangle(list(ISLAND), radius=(ISLAND[3] - ISLAND[1]) // 2, fill=(0, 0, 0))

    f = font("Nunito-Bold.ttf", 58)
    bb = d.textbbox((0, 0), "9:41", font=f)
    d.text((270 - (bb[2] - bb[0]) / 2 - bb[0], 96 - (bb[3] - bb[1]) / 2 - bb[1]),
           "9:41", font=f, fill=STATUS_FG)

    x = 937
    for h in (13, 21, 29, 37):
        d.rounded_rectangle([x, 117 - h, x + 12, 117], radius=4, fill=STATUS_FG)
        x += 20

    cx, cy = 1062, 112
    for r in (46, 30, 14):
        d.arc([cx - r, cy - r, cx + r, cy + r], start=215, end=325, fill=STATUS_FG, width=12)
    d.ellipse([cx - 6, cy - 12, cx + 6, cy], fill=STATUS_FG)

    faded = tuple(round(STATUS_FG[i] + (bg[i] - STATUS_FG[i]) * 0.6) for i in range(3))
    d.rounded_rectangle([1108, 76, 1197, 118], radius=14, outline=faded, width=5)
    d.rounded_rectangle([1116, 84, 1189, 110], radius=8, fill=STATUS_FG)
    d.rounded_rectangle([1202, 90, 1209, 104], radius=3, fill=faded)
    return shot


# ------------------------------------------------------------------- device

def rounded_mask(size, radius):
    m = Image.new("L", (size[0] * 2, size[1] * 2), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] * 2 - 1, size[1] * 2 - 1],
                                        radius=radius * 2, fill=255)
    return m.resize(size, Image.LANCZOS)


def rounded(img, radius):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img.convert("RGBA"), (0, 0), rounded_mask(img.size, radius))
    return out


def _screen_sheen(size, radius):
    """A single soft diagonal highlight, clipped to the screen."""
    sheen = Image.new("L", (size[0] // 4, size[1] // 4), 0)
    d = ImageDraw.Draw(sheen)
    w, h = sheen.size
    d.polygon([(-w * 0.1, 0), (w * 0.52, 0), (w * 0.12, h), (-w * 0.5, h)], fill=26)
    sheen = sheen.filter(ImageFilter.GaussianBlur(22)).resize(size, Image.BICUBIC)
    clip = rounded_mask(size, radius)
    return Image.composite(sheen, Image.new("L", size, 0), clip)


def device_layer(shot, dy):
    """Device body, buttons, screen and sheen on a transparent frame-sized layer."""
    scale = SCREEN_W / W
    screen = shot.resize((SCREEN_W, round(H * scale)), Image.LANCZOS)
    sx = (W - SCREEN_W) // 2
    sy = SCREEN_TOP + dy
    bez = [sx - BEZEL_PAD, sy - BEZEL_PAD,
           sx + screen.width + BEZEL_PAD, sy + screen.height + BEZEL_PAD]
    radius = SCREEN_RADIUS + BEZEL_PAD

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # side buttons, tucked under the body so only their edge shows
    for top, height in ((sy + 300, 96), (sy + 430, 170), (sy + 630, 170)):
        d.rounded_rectangle([bez[0] - 9, top, bez[0] + 8, top + height], radius=8,
                            fill=(0x3A, 0x26, 0x2E, 255))
    d.rounded_rectangle([bez[2] - 8, sy + 520, bez[2] + 9, sy + 780], radius=8,
                        fill=(0x3A, 0x26, 0x2E, 255))

    d.rounded_rectangle(bez, radius=radius, fill=BEZEL + (255,))
    d.rounded_rectangle(bez, radius=radius, outline=BEZEL_EDGE + (255,), width=3)
    # polished inner edge, just inside the bezel
    d.rounded_rectangle([bez[0] + 13, bez[1] + 13, bez[2] - 13, bez[3] - 13],
                        radius=radius - 13, outline=(0x8A, 0x6A, 0x76, 120), width=2)

    layer.alpha_composite(rounded(screen, SCREEN_RADIUS), (sx, sy))
    layer.paste(Image.new("RGBA", screen.size, (255, 255, 255, 255)), (sx, sy),
                _screen_sheen(screen.size, SCREEN_RADIUS))
    return layer, bez, radius


def place_device(canvas, shot, tilt, dy):
    layer, bez, radius = device_layer(shot, dy)
    centre = ((bez[0] + bez[2]) / 2, (bez[1] + bez[3]) / 2)

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([bez[0], bez[1] + 30, bez[2], bez[3] + 30],
                                             radius=radius, fill=120)
    if tilt:
        shadow = shadow.rotate(tilt, resample=Image.BICUBIC, center=centre)
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas.paste(Image.new("RGBA", (W, H), SHADOW + (255,)), (0, 0), shadow)

    if tilt:
        layer = layer.rotate(tilt, resample=Image.BICUBIC, center=centre)
    canvas.alpha_composite(layer)


# --------------------------------------------------------------------- text

def parse(text):
    """'a *b* c' → [('a ', False), ('b', True), (' c', False)] — True means gold."""
    parts, gold = [], False
    for chunk in text.split("*"):
        if chunk:
            parts.append((chunk, gold))
        gold = not gold
    return parts


def measure(d, parts, f):
    return sum(d.textlength(t, font=f) for t, _ in parts)


def wrap_rich(d, text, f, max_width):
    """Word wrap that keeps the gold marks attached to their words.

    The marks go around whole words — '*tek bakışta*', not 'bakış*ta*'.
    """
    words, line, lines = [], [], []
    for token, gold in parse(text):
        for word in token.split(" "):
            if word:
                words.append((word, gold))
    for word in words:
        trial = line + [word]
        if measure(d, [(" ".join(w for w, _ in trial), False)], f) <= max_width or not line:
            line = trial
        else:
            lines.append(line)
            line = [word]
    if line:
        lines.append(line)
    return lines


def draw_rich_line(d, cx, y, line, f, plain):
    width = sum(d.textlength(w, font=f) for w, _ in line) + d.textlength(" ", font=f) * (len(line) - 1)
    x = cx - width / 2
    for i, (word, gold) in enumerate(line):
        d.text((x, y), word, font=f, fill=GOLD if gold else plain)
        x += d.textlength(word, font=f)
        if i < len(line) - 1:
            x += d.textlength(" ", font=f)


def text_block(headline, subline, top=TEXT_TOP, bottom=TEXT_BOTTOM):
    """Captions on their own layer, so they can carry a soft shadow."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    hf = font("Nunito-ExtraBold.ttf", HEADLINE_SIZE)
    sf = font("Nunito-SemiBold.ttf", SUBLINE_SIZE)
    max_w = W - 2 * MARGIN

    head_lines = wrap_rich(d, headline, hf, max_w)
    sub_lines = wrap_rich(d, subline, sf, max_w)
    block = (len(head_lines) * HEADLINE_LEADING + SUBLINE_GAP
             + len(sub_lines) * (SUBLINE_SIZE + 12) + RULE_GAP)
    y = top + max(0, (bottom - top - block) // 2)

    for line in head_lines:
        draw_rich_line(d, W / 2, y, line, hf, HEADLINE)
        y += HEADLINE_LEADING
    y += SUBLINE_GAP
    for line in sub_lines:
        draw_rich_line(d, W / 2, y, line, sf, SUBLINE)
        y += SUBLINE_SIZE + 12

    y += RULE_GAP - 12
    d.rounded_rectangle([W / 2 - 54, y, W / 2 + 54, y + 5], radius=3, fill=GOLD + (225,))
    return layer


def stamp(canvas, layer):
    """Composite a text layer with a soft shadow underneath it."""
    shade = layer.getchannel("A").filter(ImageFilter.GaussianBlur(10)).point(lambda v: round(v * 0.38))
    canvas.paste(Image.new("RGBA", (W, H), SHADOW + (255,)), (0, 4), shade)
    canvas.alpha_composite(layer)


# ------------------------------------------------------------- closing card

def closing_frame(canvas, shot):
    """Icon lockup, promises, and the app itself rising from the bottom edge."""
    capture = Image.open(os.path.join(RAW_DIR, shot["capture"])).convert("RGB")
    place_device(canvas, normalise_status_bar(capture), shot["tilt"], shot["dy"])

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    size = 340
    icon = rounded(Image.open(ICON).convert("RGB").resize((size, size), Image.LANCZOS),
                   round(size * 0.2237))
    ix, iy = (W - size) // 2, 800

    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).rounded_rectangle([ix + 14, iy + 30, ix + size - 14, iy + size + 10],
                                           radius=70, fill=165)
    canvas.paste(Image.new("RGBA", (W, H), SHADOW + (255,)), (0, 0),
                 glow.filter(ImageFilter.GaussianBlur(34)))
    layer.alpha_composite(icon, (ix, iy))

    d.text((W / 2, iy + size + 46), "Çeyizim",
           font=font("Nunito-ExtraBold.ttf", 104), fill=HEADLINE, anchor="ma")

    cf = font("Nunito-SemiBold.ttf", 42)
    chips = shot["chips"]
    widths = [d.textlength(c, font=cf) + 70 for c in chips]
    total = sum(widths) + 24 * (len(chips) - 1)
    x, y = (W - total) / 2, iy + size + 230
    for chip, width in zip(chips, widths):
        d.rounded_rectangle([x, y, x + width, y + 86], radius=43,
                            fill=IVORY + (30,), outline=IVORY + (95,), width=2)
        bb = d.textbbox((0, 0), chip, font=cf)
        d.text((x + width / 2, y + 43 - (bb[3] + bb[1]) / 2), chip,
               font=cf, fill=IVORY + (238,), anchor="ma")
        x += width + 24

    stamp(canvas, text_block(shot["headline"], shot["subline"]))
    stamp(canvas, layer)


# --------------------------------------------------------------------- main

def build(index, shot, pano):
    canvas = pano.crop((index * W, 0, (index + 1) * W, H))

    if shot.get("closing"):
        closing_frame(canvas, shot)
    else:
        capture = Image.open(os.path.join(RAW_DIR, shot["file"])).convert("RGB")
        if capture.size != (W, H):
            raise SystemExit(f"{shot['file']}: expected {W}×{H} (6.9\" capture), "
                             f"got {capture.size[0]}×{capture.size[1]}")
        place_device(canvas, normalise_status_bar(capture), shot["tilt"], shot["dy"])
        stamp(canvas, text_block(shot["headline"], shot["subline"]))

    out = os.path.join(OUT_DIR, shot["file"])
    canvas.convert("RGB").save(out)
    print("wrote", out)


def main():
    if not os.path.isdir(RAW_DIR):
        raise SystemExit(f"missing {RAW_DIR} — put the simulator captures there")
    os.makedirs(OUT_DIR, exist_ok=True)
    only = sys.argv[1:]
    pano = panorama()
    for index, shot in enumerate(SHOTS):
        if only and shot["file"] not in only:
            continue
        build(index, shot, pano)


if __name__ == "__main__":
    main()
