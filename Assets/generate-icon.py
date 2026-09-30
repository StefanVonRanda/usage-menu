#!/usr/bin/env python3
"""Generate AppIcon.icns for UsageMenu (Claude Code + Codex usage bars)."""
from PIL import Image, ImageDraw
import os, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "Sources", "UsageMenuApp", "Resources")
ICONSET = "/tmp/UsageMenu.iconset"
SIZE = 1024

CLAUDE_TOP = (232, 149, 107)   # #E8956B
CLAUDE_BOT = (217, 119, 87)    # #D97757 (Claude terracotta)
CODEX_TOP = (52, 211, 153)     # #34D399
CODEX_BOT = (16, 163, 127)     # #10A37F (OpenAI green)
BG_TOP = (43, 45, 66)
BG_BOT = (22, 22, 30)

def lerp(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))

def rounded_rect_gradient(base, box, radius, top, bot):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    grad = Image.new("RGB", (1, h))
    for y in range(h):
        grad.putpixel((0, y), lerp(top, bot, y / max(h - 1, 1)))
    grad = grad.resize((w, h))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w, h], radius=radius, fill=255)
    base.paste(grad, (x0, y0), mask)
    return mask

def bar(base, x, bar_w, bottom, height, fill_frac, radius, top_c, bot_c, track_color=(63, 65, 84)):
    track_top = bottom - height
    # track (solid muted slate so it reads as a track on the dark bg)
    tmask = Image.new("L", (bar_w, height), 0)
    ImageDraw.Draw(tmask).rounded_rectangle([0, 0, bar_w, height], radius=radius, fill=255)
    track = Image.new("RGB", (bar_w, height), track_color)
    base.paste(track, (x, track_top), tmask)
    # fill (bottom-up)
    fh = int(height * fill_frac)
    if fh > 4:
        grad = Image.new("RGB", (1, fh))
        for y in range(fh):
            grad.putpixel((0, y), lerp(top_c, bot_c, y / max(fh - 1, 1)))
        grad = grad.resize((bar_w, fh))
        fmask = Image.new("L", (bar_w, fh), 0)
        ImageDraw.Draw(fmask).rounded_rectangle([0, 0, bar_w, fh], radius=min(radius, fh // 2), fill=255)
        base.paste(grad, (x, bottom - fh), fmask)

def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # background squircle
    mask = rounded_rect_gradient(img, (0, 0, SIZE, SIZE), 232, BG_TOP, BG_BOT)
    d = ImageDraw.Draw(img)
    # subtle top highlight
    d.rounded_rectangle([0, 0, SIZE, SIZE], radius=232, outline=(255, 255, 255, 22), width=6)
    # bars
    bar_w, gap, height, bottom = 150, 90, 560, 780
    total = bar_w * 2 + gap
    x0 = (SIZE - total) // 2
    bar(img, x0, bar_w, bottom, height, 0.86, 75, CLAUDE_TOP, CLAUDE_BOT)
    bar(img, x0 + bar_w + gap, bar_w, bottom, height, 0.42, 75, CODEX_TOP, CODEX_BOT)
    # baseline
    d.rounded_rectangle([x0 - 30, bottom + 34, x0 + total + 30, bottom + 52], radius=9, fill=(255, 255, 255, 60))

    os.makedirs(RES, exist_ok=True)
    os.makedirs(ICONSET, exist_ok=True)
    # master preview
    img.save(os.path.join(RES, "AppIcon-1024.png"))
    sizes = [(16, ""), (32, "@2x", 16), (32, ""), (64, "@2x", 32),
             (128, ""), (256, "@2x", 128), (256, ""), (512, "@2x", 256),
             (512, ""), (1024, "@2x", 512)]
    # normalize: (pixels, suffix, base)
    spec = [(16, 16, ""), (32, 16, "@2x"), (32, 32, ""), (64, 32, "@2x"),
            (128, 128, ""), (256, 128, "@2x"), (256, 256, ""),
            (512, 256, "@2x"), (512, 512, ""), (1024, 512, "@2x")]
    for px, base, suffix in spec:
        small = img.resize((px, px), Image.LANCZOS)
        small.save(f"{ICONSET}/icon_{base}x{base}{suffix}.png")
    subprocess.run(["iconutil", "-c", "icns", ICONSET, "-o",
                    os.path.join(RES, "AppIcon.icns")], check=True)
    print("Wrote", os.path.join(RES, "AppIcon.icns"))

if __name__ == "__main__":
    main()
