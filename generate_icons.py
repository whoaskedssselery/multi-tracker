"""
Generates all app icons from the bar-chart design.
Run: python generate_icons.py
Requires: Pillow  (pip install Pillow)
"""

import io
import os
import struct
from PIL import Image, ImageDraw

# ── Design constants (at 1024 px) ──────────────────────────────────────
BG      = (19, 18, 16, 255)       # #131210
BAR     = (244, 241, 232, 255)    # #F4F1E8  warm white
BASE    = 1024
RADIUS  = int(BASE * 0.22)        # rounded corner ratio


def draw_icon(size: int) -> Image.Image:
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded-rectangle background
    r = max(1, round(size * 0.22))
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=BG)

    # Three bars — same proportions as the SVG (viewBox 512)
    #   x: 82, 208, 334   width: 96 each   heights: 188, 262, 330
    #   y-bottom: 430   (82+188=270, but y=242 so bottom=430)
    s      = size / 512
    bottom = round(430 * s)
    br     = max(2, round(10 * s))   # bar corner radius

    bars = [
        (round(82  * s), round(242 * s), round(178 * s), bottom),  # left
        (round(208 * s), round(168 * s), round(304 * s), bottom),  # mid
        (round(334 * s), round(100 * s), round(430 * s), bottom),  # right
    ]
    for x1, y1, x2, y2 in bars:
        draw.rounded_rectangle([x1, y1, x2, y2], radius=br, fill=BAR)

    return img


# ── iOS AppIcon sizes (size × scale → pixel size) ──────────────────────
IOS_DIR  = r"flutter\ios\Runner\Assets.xcassets\AppIcon.appiconset"
IOS_SIZES = [
    ("Icon-App-20x20@1x.png",      20),
    ("Icon-App-20x20@2x.png",      40),
    ("Icon-App-20x20@3x.png",      60),
    ("Icon-App-29x29@1x.png",      29),
    ("Icon-App-29x29@2x.png",      58),
    ("Icon-App-29x29@3x.png",      87),
    ("Icon-App-40x40@1x.png",      40),
    ("Icon-App-40x40@2x.png",      80),
    ("Icon-App-40x40@3x.png",     120),
    ("Icon-App-60x60@2x.png",     120),
    ("Icon-App-60x60@3x.png",     180),
    ("Icon-App-76x76@1x.png",      76),
    ("Icon-App-76x76@2x.png",     152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png",1024),
]

# ── Android mipmap sizes ───────────────────────────────────────────────
ANDROID_DIR   = r"flutter\assets\icon\android"
ANDROID_SIZES = [
    ("mipmap-mdpi",    48),
    ("mipmap-hdpi",    72),
    ("mipmap-xhdpi",   96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi",192),
]

# ── Windows ICO ────────────────────────────────────────────────────────
WIN_PATH  = r"flutter\windows\runner\resources\app_icon.ico"
ICO_SIZES = [16, 32, 48, 64, 128, 256]


def _save_ico(frames: list, path: str):
    """Write a proper multi-size .ico using PNG compression (Vista+).
    Pillow's built-in ICO saver silently drops all but the first frame
    in some versions, so we hand-craft the binary structure."""
    pngs = []
    for img in frames:
        buf = io.BytesIO()
        img.save(buf, "PNG")
        pngs.append(buf.getvalue())

    count = len(frames)
    header = struct.pack("<HHH", 0, 1, count)   # ICONDIR
    dir_offset = 6 + count * 16
    entries = b""
    for img, png in zip(frames, pngs):
        w = img.width  if img.width  < 256 else 0   # 0 encodes 256
        h = img.height if img.height < 256 else 0
        entries += struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, len(png), dir_offset)
        dir_offset += len(png)

    with open(path, "wb") as f:
        f.write(header + entries)
        for png in pngs:
            f.write(png)


def save_png(img: Image.Image, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.convert("RGB").save(path, "PNG")
    print(f"  {path}  ({img.size[0]}px)")


def main():
    print("=== iOS icons ===")
    for name, px in IOS_SIZES:
        save_png(draw_icon(px), os.path.join(IOS_DIR, name))

    print("\n=== Android icons ===")
    os.makedirs(ANDROID_DIR, exist_ok=True)
    for folder, px in ANDROID_SIZES:
        path = os.path.join(ANDROID_DIR, folder, "ic_launcher.png")
        save_png(draw_icon(px), path)

    print("\n=== Windows ICO ===")
    frames = [draw_icon(s).convert("RGBA") for s in ICO_SIZES]
    os.makedirs(os.path.dirname(WIN_PATH), exist_ok=True)
    _save_ico(frames, WIN_PATH)
    print(f"  {WIN_PATH}  ({len(ICO_SIZES)} sizes: {ICO_SIZES})")

    print("\nDone.")


if __name__ == "__main__":
    main()
