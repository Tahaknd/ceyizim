#!/usr/bin/env python3
"""Çeyizim app icon generator.

Draws the three App Icon appearances (light / dark / tinted) at 1024×1024 and
writes them into the asset catalog.

    python3 -m pip install pillow
    python3 Tools/make-icon.py [output-dir]

Default output dir: Ceyizim/Assets.xcassets/AppIcon.appiconset

The mark is a çeyiz sandığı (hope chest): an arched lid separated from the body
by a hairline seam, with a gold heart clasp on the front. Deliberately flat and
geometric — no gradients on the mark, no sparkles — so it stays legible down to
40 px in Spotlight and Settings.
"""

import os
import sys
from PIL import Image, ImageDraw

SIZE = 1024
SS = 4                     # supersampling factor; everything is drawn at SIZE*SS
N = SIZE * SS


# ------------------------------------------------------------------ helpers

def hexc(value, alpha=255):
    return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF, alpha)


# The mark is laid out in a 1024-point design space, then scaled and nudged as
# a whole so it sits optically centred inside the iOS squircle.
MARK_SCALE = 1.06
MARK_DY = -74.0
MARK_ORIGIN = (512.0, 597.0)


def px(x):
    """Map a design-space x to the working canvas."""
    return (MARK_ORIGIN[0] + (x - MARK_ORIGIN[0]) * MARK_SCALE) * SS


def py(y):
    """Map a design-space y to the working canvas."""
    return (MARK_ORIGIN[1] + (y - MARK_ORIGIN[1]) * MARK_SCALE + MARK_DY) * SS


def sl(v):
    """Scale a length (radius, stroke) into the working canvas."""
    return v * MARK_SCALE * SS


def mask():
    return Image.new("L", (N, N), 0)


def vertical_gradient(top, bottom):
    small = Image.new("RGB", (4, 64))
    px = small.load()
    for y in range(64):
        t = y / 63.0
        color = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(4):
            px[x, y] = color
    return small.resize((N, N), Image.BICUBIC)


def bezier(p0, p1, p2, p3, steps=80):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return pts


def heart_polygon(cx, cy, width):
    """Symmetric heart; (cx, cy) is the centre of the shape's bounding box."""
    w = width
    h = width * 0.90
    top, bottom = cy - h / 2, cy + h / 2
    left, right = cx - w / 2, cx + w / 2
    lobe = top + h * 0.30
    pts = [(cx, bottom)]
    pts += bezier((cx, bottom), (cx - w * 0.50, bottom - h * 0.36), (left, lobe + h * 0.22), (left, lobe))
    pts += bezier((left, lobe), (left, lobe - h * 0.30), (cx - w * 0.06, lobe - h * 0.30), (cx, lobe + h * 0.10))
    pts += bezier((cx, lobe + h * 0.10), (cx + w * 0.06, lobe - h * 0.30), (right, lobe - h * 0.30), (right, lobe))
    pts += bezier((right, lobe), (right, lobe + h * 0.22), (cx + w * 0.50, bottom - h * 0.36), (cx, bottom))
    return [(px(x), py(y)) for x, y in pts]


def paint(canvas, m, color):
    canvas.paste(Image.new("RGBA", (N, N), color), (0, 0), m)


# ----------------------------------------------------------------- geometry
# One design space, shared by every appearance, so the three icons are
# pixel-identical apart from colour.

CX = 512.0
BODY = (276.0, 572.0, 748.0, 802.0)      # left, top, right, bottom
BODY_RADIUS = 26.0
RIM = (262.0, 562.0, 762.0, 600.0)       # lip that sits on top of the body
RIM_RADIUS = 14.0
LID_LEFT, LID_RIGHT = 262.0, 762.0
LID_BASE, LID_SHOULDER, LID_APEX = 572.0, 512.0, 392.0
SEAM = (554.0, 562.0)                    # hairline gap between lid and rim
HEART = (CX, 682.0, 146.0)               # centre x, centre y, width


def chest_mask():
    m = mask()
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([px(BODY[0]), py(BODY[1]), px(BODY[2]), py(BODY[3])],
                        radius=sl(BODY_RADIUS), fill=255)
    pts = [(LID_LEFT, LID_BASE), (LID_LEFT, LID_SHOULDER)]
    pts += bezier((LID_LEFT, LID_SHOULDER), (LID_LEFT, LID_APEX + 10),
                  (CX - 150, LID_APEX), (CX, LID_APEX))
    pts += bezier((CX, LID_APEX), (CX + 150, LID_APEX),
                  (LID_RIGHT, LID_APEX + 10), (LID_RIGHT, LID_SHOULDER))
    pts += [(LID_RIGHT, LID_BASE)]
    d.polygon([(px(x), py(y)) for x, y in pts], fill=255)
    d.rounded_rectangle([px(RIM[0]), py(RIM[1]), px(RIM[2]), py(RIM[3])],
                        radius=sl(RIM_RADIUS), fill=255)

    # Cut the seam so the lid reads as a separate piece.
    seam = mask()
    ImageDraw.Draw(seam).rectangle(
        [px(LID_LEFT - 4), py(SEAM[0]), px(LID_RIGHT + 4), py(SEAM[1])], fill=255)
    return Image.composite(Image.new("L", (N, N), 0), m, seam)


def render(path, ground_top, ground_bottom, chest, heart):
    canvas = Image.new("RGBA", (N, N), hexc(ground_top))
    canvas.paste(vertical_gradient(hexc(ground_top)[:3], hexc(ground_bottom)[:3]), (0, 0))

    paint(canvas, chest_mask(), hexc(chest))

    hm = mask()
    ImageDraw.Draw(hm).polygon(heart_polygon(*HEART), fill=255)
    paint(canvas, hm, hexc(heart))

    canvas.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS).save(path)
    print("wrote", path)


def main():
    default = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "Ceyizim", "Assets.xcassets", "AppIcon.appiconset")
    out_dir = sys.argv[1] if len(sys.argv) > 1 else default
    os.makedirs(out_dir, exist_ok=True)

    # Light — deep rose ground, ivory chest, gold heart.
    render(os.path.join(out_dir, "AppIcon.png"),
           ground_top=0xBD5069, ground_bottom=0xA13E58,
           chest=0xF8F1E9, heart=0xD7A65C)

    # Dark — plum ground, the same mark slightly warmed down.
    render(os.path.join(out_dir, "AppIcon-Dark.png"),
           ground_top=0x3E222D, ground_bottom=0x180E13,
           chest=0xEFE2D8, heart=0xD7A65C)

    # Tinted — greyscale on black; the system applies the user's tint.
    render(os.path.join(out_dir, "AppIcon-Tinted.png"),
           ground_top=0x000000, ground_bottom=0x000000,
           chest=0xFFFFFF, heart=0x8A8A8A)


if __name__ == "__main__":
    main()
