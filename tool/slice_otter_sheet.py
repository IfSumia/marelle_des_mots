"""Slice the labelled otter sprite sheet into clean, transparent strips.

This is only a stop-gap so the app has real art on day one. Once you draw
your own strips, drop them into assets/sprites/ (name_framecount.png) and
delete the ones this script made.

Usage: python3 tool/slice_otter_sheet.py path/to/sheet.png
"""
import sys
from collections import deque
from PIL import Image

SRC = sys.argv[1]
OUT = "assets/sprites"
im = Image.open(SRC).convert("RGBA")

# Grid measured from the sheet: 10 columns, 3 rows. Each row has slightly
# different cell borders (x positions), measured by scanning for border lines.
N = 10
BORDERS = {
    "front":     [16, 118, 216, 315, 412, 513, 611, 709, 807, 905, 1007],
    "jump":      [16, 116, 217, 321, 409, 512, 614, 716, 806, 907, 1007],
    "celebrate": [16, 102, 204, 307, 409, 512, 614, 716, 819, 921, 1007],
}
# the jump row is cut taller than its drawn box (the mid-air otter overflows
# the top) but stops above its bottom border line
ROWS = {"front": (35, 161), "jump": (186, 359), "celebrate": (426, 543)}
INSET = 4  # drop the cell border lines


def is_bg(c):
    r, g, b, _ = c
    lo, hi = min(r, g, b), max(r, g, b)
    light_grid = lo > 165 and (hi - lo) < 34                     # paper + faint grid
    cool_line = lo > 95 and b >= r - 4 and (hi - lo) < 45        # grey-blue cell borders
    return light_grid or cool_line


def cut_cell(key, col, y0, y1):
    x0 = BORDERS[key][col] + INSET
    x1 = BORDERS[key][col + 1] - INSET
    cell = im.crop((x0, y0 + INSET, x1, y1 - INSET))
    w, h = cell.size
    px = cell.load()
    # flood-fill the background from the edges so inner highlights survive
    bg = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    while q:
        x, y = q.popleft()
        if not (0 <= x < w and 0 <= y < h) or bg[y][x] or not is_bg(px[x, y]):
            continue
        bg[y][x] = True
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    # connected components of what is left; keep the biggest (the otter)
    seen = [[False] * w for _ in range(h)]
    comps = []
    for sy in range(h):
        for sx in range(w):
            if bg[sy][sx] or seen[sy][sx]:
                continue
            comp, dq = [], deque([(sx, sy)])
            seen[sy][sx] = True
            while dq:
                x, y = dq.popleft()
                comp.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not bg[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            dq.append((nx, ny))
            comps.append(comp)
    comps.sort(key=len, reverse=True)
    main = comps[0]
    xs = [p[0] for p in main]
    ys = [p[1] for p in main]
    bbox = (min(xs), min(ys), max(xs), max(ys))
    keep = set(main)
    # also keep pieces that touch the otter's bbox and are not tiny text
    # specks (eyes highlights, detached paws), but never the big banner text
    for comp in comps[1:]:
        cx = [p[0] for p in comp]; cy = [p[1] for p in comp]
        inside = bbox[0] - 2 <= min(cx) and max(cx) <= bbox[2] + 2 and bbox[1] - 2 <= min(cy) and max(cy) <= bbox[3] + 2
        if inside and len(comp) >= 6:
            keep.update(comp)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    po = out.load()
    for x, y in keep:
        po[x, y] = px[x, y]
    return out, bbox


def build_row(name, y0, y1):
    cells = [cut_cell(name, c, y0, y1) for c in range(N)]
    # common ground line = lowest otter pixel of the row
    ground = max(b[3] for _, b in cells)
    return cells, ground


rows = {k: build_row(k, *v) for k, v in ROWS.items()}

# size normalisation: celebrating otter is drawn larger than the front one
def body_h(cells, i):
    b = cells[i][1]
    return b[3] - b[1] + 1

ref = body_h(rows["front"][0], 0)
scale = {"front": 1.0, "jump": 1.0, "celebrate": ref / body_h(rows["celebrate"][0], 9)}
print("ref height", ref, "celebrate scale", round(scale["celebrate"], 3))

def save_strip(key, fname, picks):
    cells, ground = rows[key]
    s = scale[key]
    frames = []
    for i in picks:
        img = cells[i][0]
        w, h = img.size
        img = img.crop((0, 0, w, ground + 3))  # crop the label zone off the bottom
        if abs(s - 1) > 0.01:
            img = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
        frames.append(img)
    fw = max(f.width for f in frames)
    fh = max(f.height for f in frames)
    strip = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
    for n, f in enumerate(frames):
        # bottom-aligned, horizontally centred in its slot
        strip.paste(f, (n * fw + (fw - f.width) // 2, fh - f.height), f)
    strip.save(f"{OUT}/{fname}_{len(frames)}.png")
    print(fname, len(frames), "frames", (fw, fh))

# front row: Idle1, Idle2, Breathing, Blink, Shift, Pose1, Pose1, Pose2, Ready, (unlabelled)
save_strip("front", "idle", [0, 1, 2, 1])
save_strip("front", "idle_blink", [0, 3, 3, 0])
save_strip("front", "poke_1_wiggle", [4, 5, 6, 7, 6, 5, 4])
save_strip("jump", "know_1_jump", list(range(10)))
save_strip("celebrate", "know_2_woohoo", list(range(10)))
save_strip("celebrate", "again_1_cheer", [9, 8, 6, 8, 9])
