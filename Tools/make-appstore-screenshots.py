#!/usr/bin/env python3
"""Turns raw simulator captures into App Store product page screenshots.

    python3 -m pip install pillow
    python3 Tools/make-appstore-screenshots.py            # all five
    python3 Tools/make-appstore-screenshots.py 02-listem.png

Input :  AppStore/screenshots/raw/*.png   (6.9" captures, 1320×2868)
Output:  AppStore/screenshots/*.png       (same names, ready to upload)

The five frames are cut out of ONE 6600×2868 panorama, so the ground, the light
and the ribbons run straight through the gallery: swiping reads as a single
composition rather than five separate cards. Devices alternate a small tilt and
a vertical offset for rhythm, while the headlines stay on a fixed baseline so
they do not jump around during the swipe.

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

# 6.9" App Store size. Captures are expected at exactly this size.
W, H = 1320, 2868

# Brand — same values as Theme.swift and the app icon.
HEADLINE = (0xFF, 0xF6, 0xEF)
SUBLINE = (0xF4, 0xCD, 0xD7)
IVORY = (0xF8, 0xF1, 0xE9)
GOLD = (0xD7, 0xA6, 0x5C)
BEZEL = (0x24, 0x15, 0x1B)
BEZEL_EDGE = (0x5A, 0x3B, 0x47)
STATUS_FG = (0x33, 0x22, 0x2B)

# Ground colour along the panorama: (position 0…1, colour). The gallery opens
# and closes light and dips into plum in the middle, so consecutive frames are
# always visibly different without any hard edge between them.
GROUND_STOPS = [
    (0.00, 0xC2566E),
    (0.30, 0xA8405C),
    (0.58, 0x8B3250),
    (0.82, 0xA33E5B),
    (1.00, 0xBE5169),
]
GROUND_SHADE = 0.22        # how much darker the bottom edge is

# (file, headline, subline, tilt°, device dy)
SHOTS = [
    ("01-ozet.png",
     "Çeyizin tek bakışta",
     "İlerleme, harcama ve düğüne kalan gün",
     -2.5, 0),
    ("02-listem.png",
     "Hazır listeyle hemen başla",
     "10 kategori, 111 eşya — tek dokunuşla işaretle",
     2.5, 54),
    ("03-kategori-detay.png",
     "Kategori kategori ilerle",
     "Mutfaktan yatak odasına, eksik kalan hiçbir şey yok",
     -2.5, 0),
    ("04-harcamalar.png",
     "Hesabı uygulama tutsun",
     "Toplam, kategori grafiği ve en büyük harcamalar",
     2.5, 54),
    ("05-esya-detay.png",
     "Her eşyanın kendi kartı",
     "Fotoğraf, mağaza, fiyat, hediye eden ve not",
     -2.5, 0),
]

PANO_W = W * len(SHOTS)

# Ribbons sweeping across the whole panorama, behind the devices.
# (vertical centre, amplitude, wavelength, phase, thickness, opacity)
# Most of the middle band is hidden behind the phones, so the ribbons are
# placed where they actually show: across the caption area and in the margins
# beside the devices, where each one disappears behind a phone and comes back
# out on the other side.
RIBBONS = [
    (1120, 300, 5400, 0.0, 360, 0.165),
    (2020, 340, 6900, 2.1, 240, 0.110),
    (560, 210, 4300, 4.0, 110, 0.070),
]

# A soft light sits behind every device so the frames have depth and the swipe
# has a visible beat. (radius, opacity)
GLOW = (760, 0.085)

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


# ---------------------------------------------------------------- panorama

def _ground_at(t):
    """Colour of the panorama ground at horizontal position t (0…1)."""
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
    gw, gh = 160, 40
    small = Image.new("RGB", (gw, gh))
    px = small.load()
    for x in range(gw):
        base = _ground_at(x / (gw - 1))
        for y in range(gh):
            shade = 1 - GROUND_SHADE * (y / (gh - 1)) ** 1.4
            px[x, y] = tuple(round(base[i] * shade) for i in range(3))
    return small.resize((PANO_W, H), Image.BICUBIC)


def _ribbon_mask(centre, amplitude, wavelength, phase, thickness, scale=4):
    """One sine band across the panorama, drawn small and scaled up."""
    w, h = PANO_W // scale, H // scale
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    top, bottom = [], []
    steps = 240
    for i in range(steps + 1):
        x = w * i / steps
        angle = 2 * math.pi * (x * scale) / wavelength + phase
        y = (centre + amplitude * math.sin(angle)) / scale
        half = (thickness / 2) * (0.75 + 0.25 * math.cos(angle * 0.7)) / scale
        top.append((x, y - half))
        bottom.append((x, y + half))
    d.polygon(top + bottom[::-1], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(9))
    return m.resize((PANO_W, H), Image.BICUBIC)


def _glow_mask(scale=4):
    """One soft pool of light per frame, following the device offsets."""
    radius, opacity = GLOW
    w, h = PANO_W // scale, H // scale
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    for index, shot in enumerate(SHOTS):
        cx = (index * W + W / 2) / scale
        cy = (SCREEN_TOP + shot[4] + 620) / scale
        r = radius / scale
        for step in range(6, 0, -1):
            rr = r * step / 6
            d.ellipse([cx - rr, cy - rr * 1.25, cx + rr, cy + rr * 1.25],
                      fill=round(255 * opacity * (1 - step / 7)))
    m = m.filter(ImageFilter.GaussianBlur(26))
    return m.resize((PANO_W, H), Image.BICUBIC)


def panorama():
    canvas = _ground().convert("RGBA")
    for centre, amp, wave, phase, thick, opacity in RIBBONS:
        m = _ribbon_mask(centre, amp, wave, phase, thick)
        m = m.point(lambda v: round(v * opacity))
        canvas.paste(Image.new("RGBA", (PANO_W, H), IVORY + (255,)), (0, 0), m)
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

def rounded(img, radius):
    m = Image.new("L", (img.width * 2, img.height * 2), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.width * 2 - 1, img.height * 2 - 1],
                                        radius=radius * 2, fill=255)
    m = m.resize(img.size, Image.LANCZOS)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img.convert("RGBA"), (0, 0), m)
    return out


def device_layer(shot, dy):
    """Device body + screen on a transparent frame-sized layer."""
    scale = SCREEN_W / W
    screen = shot.resize((SCREEN_W, round(H * scale)), Image.LANCZOS)
    sx = (W - SCREEN_W) // 2
    sy = SCREEN_TOP + dy
    bez = [sx - BEZEL_PAD, sy - BEZEL_PAD,
           sx + screen.width + BEZEL_PAD, sy + screen.height + BEZEL_PAD]
    radius = SCREEN_RADIUS + BEZEL_PAD

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(bez, radius=radius, fill=BEZEL + (255,))
    d.rounded_rectangle(bez, radius=radius, outline=BEZEL_EDGE + (255,), width=3)
    layer.alpha_composite(rounded(screen, SCREEN_RADIUS), (sx, sy))
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
    canvas.paste(Image.new("RGBA", (W, H), (0x38, 0x0E, 0x1D, 255)), (0, 0), shadow)

    if tilt:
        layer = layer.rotate(tilt, resample=Image.BICUBIC, center=centre)
    canvas.alpha_composite(layer)


# --------------------------------------------------------------------- text

def wrap(draw, text, f, max_width):
    lines, line = [], ""
    for word in text.split():
        trial = (line + " " + word).strip()
        if draw.textlength(trial, font=f) <= max_width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def draw_text(canvas, headline, subline):
    d = ImageDraw.Draw(canvas)
    hf = font("Nunito-ExtraBold.ttf", HEADLINE_SIZE)
    sf = font("Nunito-SemiBold.ttf", SUBLINE_SIZE)
    max_w = W - 2 * MARGIN

    head_lines = wrap(d, headline, hf, max_w)
    sub_lines = wrap(d, subline, sf, max_w)
    block = (len(head_lines) * HEADLINE_LEADING + SUBLINE_GAP
             + len(sub_lines) * (SUBLINE_SIZE + 12) + RULE_GAP)
    y = TEXT_TOP + max(0, (TEXT_BOTTOM - TEXT_TOP - block) // 2)

    for line in head_lines:
        d.text((W / 2, y), line, font=hf, fill=HEADLINE, anchor="ma")
        y += HEADLINE_LEADING
    y += SUBLINE_GAP
    for line in sub_lines:
        d.text((W / 2, y), line, font=sf, fill=SUBLINE, anchor="ma")
        y += SUBLINE_SIZE + 12

    # gold hairline — the one element every frame shares, at the same baseline
    y += RULE_GAP - 12
    d.rounded_rectangle([W / 2 - 54, y, W / 2 + 54, y + 5], radius=3, fill=GOLD + (210,))


# --------------------------------------------------------------------- main

def build(index, name, headline, subline, tilt, dy, pano):
    shot = Image.open(os.path.join(RAW_DIR, name)).convert("RGB")
    if shot.size != (W, H):
        raise SystemExit(f"{name}: expected {W}×{H} (6.9\" capture), got {shot.size[0]}×{shot.size[1]}")
    shot = normalise_status_bar(shot)

    canvas = pano.crop((index * W, 0, (index + 1) * W, H))
    place_device(canvas, shot, tilt, dy)
    draw_text(canvas, headline, subline)

    out = os.path.join(OUT_DIR, name)
    canvas.convert("RGB").save(out)
    print("wrote", out)


def main():
    if not os.path.isdir(RAW_DIR):
        raise SystemExit(f"missing {RAW_DIR} — put the simulator captures there")
    os.makedirs(OUT_DIR, exist_ok=True)
    only = sys.argv[1:]
    pano = panorama()
    for index, (name, headline, subline, tilt, dy) in enumerate(SHOTS):
        if only and name not in only:
            continue
        build(index, name, headline, subline, tilt, dy, pano)


if __name__ == "__main__":
    main()
