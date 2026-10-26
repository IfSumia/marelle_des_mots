"""Generate the sound effects as WAV files (marimba notes + bubbles).

Usage: python3 tool/make_sounds.py
Replace any file in assets/audio/ with a recording of the same name when you like.
"""
import math, random, struct, wave

RATE = 44100
random.seed(3)

def marimba(f, dur=0.9, gain=0.5):
    # wooden bar: fundamental + a 4x overtone that dies fast + a short mallet tick
    partials = [(1.0, 1.0, 0.45), (4.0, 0.35, 0.09), (9.2, 0.10, 0.03)]
    n = int(RATE * dur)
    buf = []
    for k in range(n):
        t = k / RATE
        s = sum(a * math.sin(2 * math.pi * f * r * t) * math.exp(-t / d) for r, a, d in partials)
        s += random.uniform(-1, 1) * math.exp(-t / 0.002) * 0.12
        buf.append(s * min(1.0, t / 0.002) * gain)
    return buf

def bubble(f0, f1, dur=0.16, gain=0.5):
    # rising chirp with a fast decay: a bubble "bloop"
    n = int(RATE * dur)
    buf, phase = [], 0.0
    for k in range(n):
        t = k / n
        f = f0 * (f1 / f0) ** t
        phase += 2 * math.pi * f / RATE
        env = math.sin(min(1.0, t * 10) * math.pi / 2) * math.exp(-3.5 * t)
        buf.append(math.sin(phase) * env * gain)
    return buf

def mix(parts):
    total = max(int(off * RATE) + len(b) for off, b in parts)
    out = [0.0] * total
    for off, b in parts:
        o = int(off * RATE)
        for i, x in enumerate(b):
            out[o + i] += x
    return out

def save(name, buf):
    peak = max(1e-9, max(abs(x) for x in buf))
    scale = min(1.0, 0.85 / peak)
    with wave.open(f"assets/audio/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * scale)) * 32767)) for x in buf))

# C major pentatonic, two octaves: one note per hopscotch square, so the trail
# plays a rising scale as she reads.
SCALE = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00]
for i, f in enumerate(SCALE):
    save(f"note{i}", marimba(f))

save("again", bubble(380, 820, 0.22, gain=0.45))                       # gentle, still positive
save("boing", mix([(0, bubble(500, 1500, 0.13)), (0.07, bubble(700, 1900, 0.12))]))  # poke
save("fanfare", mix([(0.00, marimba(523.25)), (0.09, marimba(659.25)), (0.18, marimba(783.99)),
                     (0.27, marimba(1046.5)), (0.50, marimba(523.25, 1.2)), (0.50, marimba(659.25, 1.2)),
                     (0.50, marimba(783.99, 1.2)), (0.50, marimba(1046.5, 1.2))]))
save("cheer", mix([(0.07 * i, marimba(f)) for i, f in enumerate([659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51])]))
print("ok")
