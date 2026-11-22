"""Extract transparent avatar sprites from assets/images/characters_turnaround.png.

The turnaround sheet has two rows (boy on top, girl below) and four views per row
(front, 3/4, side, back). This script keeps the front and 3/4 views, removes the
flat studio background plus the dashed reference guides, and writes tidy PNGs to
assets/avatars/.

Run from the project root:  python tool/extract_avatar_assets.py
"""

from __future__ import annotations

import os
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

SRC = os.path.join("assets", "images", "characters_turnaround.png")
OUT_DIR = os.path.join("assets", "avatars")

# (output name, search band y0, y1, expected x-range of that view)
TARGETS = [
    ("boy_front", 120, 780, (280, 660)),
    ("boy_3d_angle", 120, 780, (880, 1250)),
    ("girl_front", 900, 1500, (280, 660)),
    ("girl_3d_angle", 900, 1500, (880, 1250)),
]

TARGET_HEIGHT = 900   # exported sprite height in px
PAD = 6               # transparent padding around the silhouette


def foreground_mask(rgb: np.ndarray) -> np.ndarray:
    """Pixels that differ enough from the neutral studio backdrop."""
    as_f = rgb.astype(np.int16)
    mx = as_f.max(axis=2)
    mn = as_f.min(axis=2)
    sat = mx - mn
    mean = as_f.mean(axis=2)
    # backdrop is a smooth gray/beige ramp: low saturation, mid brightness
    backdrop = (sat < 28) & (mean > 95) & (mean < 215)
    # the dashed guide lines are near-pure white / near-pure gray strokes
    guides = (sat < 18) & (mean >= 215)
    return ~(backdrop | guides)


def _label_components(mask: np.ndarray) -> np.ndarray:
    """4-neighbour connected component labels (0 = background)."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    current = 0
    for y0 in range(h):
        row = mask[y0]
        for x0 in range(w):
            if not row[x0] or labels[y0, x0]:
                continue
            current += 1
            q = deque([(y0, x0)])
            labels[y0, x0] = current
            while q:
                y, x = q.popleft()
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
                        labels[ny, nx] = current
                        q.append((ny, nx))
    return labels


def keep_main_figure(mask: np.ndarray) -> np.ndarray:
    """Keep the character only, dropping the caption text and stray sheet marks."""
    h, w = mask.shape
    small = mask[::3, ::3]
    labels = _label_components(small)
    if labels.max() == 0:
        return mask
    counts = np.bincount(labels.ravel())
    counts[0] = 0
    biggest = int(counts.argmax())

    keep = np.array(
        Image.fromarray(((labels == biggest) * 255).astype(np.uint8)).resize(
            (w, h), Image.NEAREST
        )
    ) > 127

    # fill interior holes so shading gaps inside the silhouette stay opaque
    holes = ~keep
    seed = np.zeros_like(holes)
    seed[0, :] = holes[0, :]
    seed[-1, :] = holes[-1, :]
    seed[:, 0] = holes[:, 0]
    seed[:, -1] = holes[:, -1]
    reach = seed.copy()
    while True:
        nxt = reach.copy()
        nxt[1:, :] |= reach[:-1, :]
        nxt[:-1, :] |= reach[1:, :]
        nxt[:, 1:] |= reach[:, :-1]
        nxt[:, :-1] |= reach[:, 1:]
        nxt &= holes
        if np.array_equal(nxt, reach):
            break
        reach = nxt
    return keep | (holes & ~reach)


def tighten(mask: np.ndarray) -> np.ndarray:
    """Remove horizontal dashed-guide remnants: thin, wide, isolated runs."""
    cleaned = mask.copy()
    h, w = cleaned.shape
    for y in range(h):
        x = 0
        row = cleaned[y]
        while x < w:
            if not row[x]:
                x += 1
                continue
            x2 = x
            while x2 + 1 < w and row[x2 + 1]:
                x2 += 1
            run = x2 - x + 1
            if 4 <= run <= 60:
                # is it a thin band (few rows tall)?
                top = max(0, y - 2)
                bot = min(h, y + 3)
                band = cleaned[top:bot, x : x2 + 1]
                if band.mean() < 0.55 and band.shape[0] <= 5:
                    cleaned[top:bot, x : x2 + 1] = False
            x = x2 + 1
    return cleaned


def extract(name: str, y0: int, y1: int, xband: tuple[int, int]) -> None:
    src = Image.open(SRC).convert("RGB")
    rgb = np.array(src)
    mask = foreground_mask(rgb)

    band = np.zeros_like(mask)
    band[y0:y1, xband[0] : xband[1]] = True
    mask &= band

    # work on the (much smaller) view region so component labelling stays cheap
    ys, xs = np.nonzero(mask)
    if ys.size == 0:
        raise SystemExit(f"no foreground found for {name}")
    oy0, oy1 = ys.min(), ys.max() + 1
    ox0, ox1 = xs.min(), xs.max() + 1
    mask = mask[oy0:oy1, ox0:ox1]

    mask = keep_main_figure(mask)
    mask = tighten(mask)

    src = src.crop((ox0, oy0, ox1, oy1))

    # erase remaining isolated specks (dust, sheet artefacts)
    for _ in range(2):
        nb = (
            np.roll(mask, 1, 0)
            & np.roll(mask, -1, 0)
            & np.roll(mask, 1, 1)
            & np.roll(mask, -1, 1)
        )
        mask = mask & nb

    ys, xs = np.nonzero(mask)
    cy0, cy1 = ys.min(), ys.max() + 1
    cx0, cx1 = xs.min(), xs.max() + 1

    crop = src.crop((cx0, cy0, cx1, cy1)).convert("RGBA")
    alpha = Image.fromarray((mask[cy0:cy1, cx0:cx1] * 255).astype(np.uint8))

    # shave one pixel to kill the backdrop halo, then feather the edge
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    crop.putalpha(alpha)

    # pad the canvas so every sprite shares a consistent transparent margin
    w, h = crop.size
    scale = TARGET_HEIGHT / h
    new_w = max(1, int(round(w * scale)))
    out = Image.new("RGBA", (new_w + PAD * 2, TARGET_HEIGHT + PAD * 2), (0, 0, 0, 0))
    mini = crop.resize((new_w, TARGET_HEIGHT), Image.LANCZOS)
    out.paste(mini, (PAD, PAD), mini)

    os.makedirs(OUT_DIR, exist_ok=True)
    dest = os.path.join(OUT_DIR, f"{name}.png")
    out.save(dest, optimize=True)
    print(f"{dest}: {out.size[0]}x{out.size[1]}")


def main() -> None:
    for name, y0, y1, xband in TARGETS:
        extract(name, y0, y1, xband)


if __name__ == "__main__":
    main()