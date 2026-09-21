#!/usr/bin/env python3
"""Turns raw simulator captures into App Store product page screenshots.

    python3 -m pip install pillow
    python3 Tools/make-appstore-screenshots.py

Input :  AppStore/screenshots/raw/*.png   (6.9" captures, 1320×2868)
Output:  AppStore/screenshots/*.png       (same names, ready to upload)

Each output frame gets the brand ground, a Turkish headline + supporting line,
a device body around the capture, and a normalised status bar (9:41, full
signal) so the gallery looks deliberate instead of like five raw captures.

Re-run it after every recapture; nothing here is hand-edited.
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(ROOT, "AppStore", "screenshots", "raw")
OUT_DIR = os.path.join(ROOT, "AppStore", "screenshots")
FONT_DIR = os.path.join(ROOT, "Ceyizim", "Fonts")

# 6.9" App Store size. Captures are expected at exactly this size.
W, H = 1320, 2868

# Brand — same values as Theme.swift / the app icon.
GROUND_TOP = (0xBD, 0x50, 0x69)
GROUND_BOTTOM = (0x8E, 0x33, 0x4F)
HEADLINE = (0xFF, 0xF6, 0xEF)
SUBLINE = (0xF2, 0xC8, 0xD3)
BEZEL = (0x24, 0x15, 0x1B)
BEZEL_EDGE = (0x5A, 0x3B, 0x47)
STATUS_FG = (0x33, 0x22, 0x2B)

# Screenshot order is the App Store order. Headlines stay short enough to fit
# two lines at 1320 px wide; the second line is the supporting detail.
SHOTS = [
    ("01-ozet.png",
     "Çeyizin tek bakışta",
     "İlerleme, harcama ve düğüne kalan gün"),
    ("02-listem.png",
     "Hazır listeyle hemen başla",
     "10 kategori, 111 eşya — tek dokunuşla işaretle"),
    ("03-kategori-detay.png",
     "Kategori kategori ilerle",
     "Mutfaktan yatak odasına, eksik kalan hiçbir şey yok"),
    ("04-harcamalar.png",
     "Hesabı uygulama tutsun",
     "Toplam, kategori grafiği ve en büyük harcamalar"),
    ("05-esya-detay.png",
     "Her eşyanın kendi kartı",
     "Fotoğraf, mağaza, fiyat, hediye eden ve not"),
]

# Layout
MARGIN = 110
TEXT_TOP, TEXT_BOTTOM = 150, 660      # headline + subline live between these
HEADLINE_SIZE, HEADLINE_LEADING = 84, 104
SUBLINE_SIZE, SUBLINE_GAP = 46, 36
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


def ground():
    small = Image.new("RGB", (4, 64))
    px = small.load()
    for y in range(64):
        t = y / 63.0
        c = tuple(round(GROUND_TOP[i] + (GROUND_BOTTOM[i] - GROUND_TOP[i]) * t) for i in range(3))
        for x in range(4):
            px[x, y] = c
    return small.resize((W, H), Image.BICUBIC)


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

    # cellular
    x = 937
    for i, h in enumerate((13, 21, 29, 37)):
        d.rounded_rectangle([x, 117 - h, x + 12, 117], radius=4, fill=STATUS_FG)
        x += 20

    # wifi — three arcs and a dot
    cx, cy = 1062, 112
    for r, wdt in ((46, 12), (30, 12), (14, 12)):
        d.arc([cx - r, cy - r, cx + r, cy + r], start=215, end=325, fill=STATUS_FG, width=wdt)
    d.ellipse([cx - 6, cy - 12, cx + 6, cy], fill=STATUS_FG)

    # battery
    d.rounded_rectangle([1108, 76, 1197, 118], radius=14, outline=STATUS_FG + (0,), width=5)
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


def place_device(canvas, shot):
    scale = SCREEN_W / W
    screen = shot.resize((SCREEN_W, round(H * scale)), Image.LANCZOS)
    sx = (W - SCREEN_W) // 2
    sy = SCREEN_TOP
    bez = [sx - BEZEL_PAD, sy - BEZEL_PAD, sx + screen.width + BEZEL_PAD, sy + screen.height + BEZEL_PAD]
    radius = SCREEN_RADIUS + BEZEL_PAD

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([bez[0], bez[1] + 26, bez[2], bez[3] + 26],
                                             radius=radius, fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    canvas.paste(Image.new("RGBA", (W, H), (0x3A, 0x10, 0x1F, 255)), (0, 0), shadow)

    body = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle(bez, radius=radius, fill=BEZEL + (255,))
    bd.rounded_rectangle(bez, radius=radius, outline=BEZEL_EDGE + (255,), width=3)
    canvas.alpha_composite(body)
    canvas.alpha_composite(rounded(screen, SCREEN_RADIUS), (sx, sy))


# --------------------------------------------------------------------- text

def wrap(draw, text, f, max_width):
    words = text.split()
    lines, line = [], ""
    for word in words:
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
    block = len(head_lines) * HEADLINE_LEADING + SUBLINE_GAP + len(sub_lines) * (SUBLINE_SIZE + 12)
    y = TEXT_TOP + max(0, (TEXT_BOTTOM - TEXT_TOP - block) // 2)

    for line in head_lines:
        d.text((W / 2, y), line, font=hf, fill=HEADLINE, anchor="ma")
        y += HEADLINE_LEADING
    y += SUBLINE_GAP
    for line in sub_lines:
        d.text((W / 2, y), line, font=sf, fill=SUBLINE, anchor="ma")
        y += SUBLINE_SIZE + 12


# --------------------------------------------------------------------- main

def build(name, headline, subline):
    src = os.path.join(RAW_DIR, name)
    shot = Image.open(src).convert("RGB")
    if shot.size != (W, H):
        raise SystemExit(f"{name}: expected {W}×{H} (6.9\" capture), got {shot.size[0]}×{shot.size[1]}")
    shot = normalise_status_bar(shot)

    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    canvas.paste(ground(), (0, 0))
    place_device(canvas, shot)
    draw_text(canvas, headline, subline)

    out = os.path.join(OUT_DIR, name)
    canvas.convert("RGB").save(out)
    print("wrote", out)


def main():
    if not os.path.isdir(RAW_DIR):
        raise SystemExit(f"missing {RAW_DIR} — put the simulator captures there")
    os.makedirs(OUT_DIR, exist_ok=True)
    only = sys.argv[1:]
    for name, headline, subline in SHOTS:
        if only and name not in only:
            continue
        build(name, headline, subline)


if __name__ == "__main__":
    main()
