"""Pad the launcher icon for Android adaptive foreground.

Android adaptive icons composite a foreground PNG over a background colour,
then apply a launcher-specific mask shape. The visible area is the inner
~66dp safe zone of a 108dp canvas (~61% linear). If the foreground PNG is
full-bleed, aggressive launcher masks crop the content.

This script wraps the existing 1024x1024 icon (which has its own bg + IK
monogram baked in) inside a transparent 1024x1024 canvas, scaled down to
62% so the entire monogram is preserved no matter the mask shape.
"""
from PIL import Image

SRC = 'assets/icons/app_icon.png'
DEST = 'assets/icons/app_icon_foreground.png'
SCALE = 0.62

src = Image.open(SRC).convert('RGBA')
W, H = src.size
print(f'Source: {W}x{H}')

new_size = int(round(W * SCALE))
resized = src.resize((new_size, new_size), Image.LANCZOS)

canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
offset_x = (W - new_size) // 2
offset_y = (H - new_size) // 2
canvas.paste(resized, (offset_x, offset_y), resized)
canvas.save(DEST, 'PNG', optimize=True)

print(f'Wrote {DEST}: {new_size}x{new_size} centred in {W}x{H} canvas '
      f'(offset {offset_x},{offset_y})')
