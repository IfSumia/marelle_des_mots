"""Generate the sound effects as small WAV files (same chimes as the HTML V1).

Usage: python3 tool/make_sounds.py
Replace any file in assets/audio/ with a recorded sound of the same name
whenever you like; the app does not care how the file was made.
"""
import math, struct, wave

RATE = 44100

def chime(freqs, dur, gain=0.35, stagger=0.05):
    total = dur + stagger * len(freqs) + 0.1
    n = int(RATE * total)
    buf = [0.0] * n
    for i, f in enumerate(freqs):
        start = stagger * i
        for k in range(int(RATE * (dur + 0.05))):
            t = k / RATE
            # fast attack, exponential-ish decay, like the V1 gain ramps
            env = min(1.0, t / 0.02) * math.exp(-5.0 * t / dur)
            idx = int((start + t) * RATE)
            if idx < n:
                buf[idx] += math.sin(2 * math.pi * f * t) * env * gain
    return buf

def sweep(f0, f1, dur, gain=0.4):
    n = int(RATE * dur)
    buf, phase = [], 0.0
    for k in range(n):
        t = k / n
        f = f0 + (f1 - f0) * t
        phase += 2 * math.pi * f / RATE
        buf.append(math.sin(phase) * math.sin(math.pi * t) ** 0.6 * gain)
    return buf

def save(name, buf):
    peak = max(1e-9, max(abs(x) for x in buf))
    scale = min(1.0, 0.9 / peak)
    with wave.open(f"assets/audio/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * scale)) * 32767)) for x in buf))

save("pop",     chime([660, 880], 0.18))                          # word known
save("again",   chime([392, 523.25], 0.22, gain=0.3))             # see it again (gentle, rising)
save("fanfare", chime([523.25, 659.25, 783.99, 1046.5], 0.35))    # round complete
save("boing",   sweep(260, 760, 0.28))                            # poke the mascot
save("cheer",   chime([659.25, 783.99, 987.77, 1318.5], 0.3))     # streak
print("ok")
