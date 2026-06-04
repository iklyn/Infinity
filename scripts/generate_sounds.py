#!/usr/bin/env python3
"""
Generate 5 soothing alarm sounds as WAV files.
Then use afconvert to produce AIFF for NSSound.
"""
import wave, math, array, os, sys

SR    = 44100
PEAK  = 28000   # 85% of 32767 — headroom to avoid clipping

# ── Primitives ────────────────────────────────────────────────────────────────

def hz(note, octave=4):
    """Note name (C D E F G A B) + octave → frequency in Hz.  A4 = 440."""
    st = {'C':-9,'D':-7,'E':-5,'F':-4,'G':-2,'A':0,'B':2}
    return 440.0 * 2 ** ((st[note] + (octave - 4) * 12) / 12.0)

def adsr(t, dur, attack=0.04, decay=0.08, sustain=0.75, release=0.35):
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    elif t < dur - release:
        return sustain
    else:
        rem = dur - t
        return sustain * max(0, rem / release)

def tone(freq, dur, vol=0.8, partials=None,
         attack=0.04, decay=0.08, sustain=0.75, release=0.35,
         vibrato_hz=0, vibrato_depth=0):
    """Generate samples for a single tone."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t   = i / SR
        vib = 1.0 + vibrato_depth * math.sin(2 * math.pi * vibrato_hz * t)
        s   = math.sin(2 * math.pi * freq * vib * t)
        if partials:
            for mult, amp in partials:
                s += amp * math.sin(2 * math.pi * freq * vib * mult * t)
            s /= (1 + sum(a for _, a in partials))
        env = adsr(t, dur, attack, decay, sustain, release)
        out.append(int(s * env * vol * PEAK))
    return out

def silence(sec):
    return [0] * int(SR * sec)

def mix(*tracks):
    L = max(len(t) for t in tracks)
    out = []
    for i in range(L):
        v = sum(t[i] if i < len(t) else 0 for t in tracks)
        out.append(max(-32767, min(32767, v)))
    return out

def concat(*segs):
    r = []
    for s in segs: r.extend(s)
    return r

def xfade(a, b, samples=int(SR*0.12)):
    f = min(samples, len(a), len(b))
    result = list(a[:-f]) if f < len(a) else []
    for i in range(f):
        alpha = i / f
        va = a[len(a)-f+i] if len(a) > f else 0
        result.append(int(va*(1-alpha) + b[i]*alpha))
    result.extend(b[f:])
    return result

def write_wav(path, samples):
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        data = array.array('h', [max(-32767, min(32767, s)) for s in samples])
        f.writeframes(data.tobytes())

# ── 1. Sunrise ────────────────────────────────────────────────────────────────
# Ascending C pentatonic — soft marimba warmth

def make_sunrise():
    warm = [(2, 0.30), (3, 0.10), (4, 0.04)]
    notes = [
        (hz('C',4), 0.90), (hz('E',4), 0.90), (hz('G',4), 0.90),
        (hz('A',4), 0.90), (hz('C',5), 1.40),
    ]
    fade = int(SR * 0.14)
    seg = tone(*notes[0], vol=0.75, partials=warm,
               attack=0.05, decay=0.09, sustain=0.72, release=0.40)
    for f, d in notes[1:]:
        nxt = tone(f, d, vol=0.75, partials=warm,
                   attack=0.05, decay=0.09, sustain=0.72, release=0.40)
        seg = xfade(seg, nxt, fade)
    return concat(seg, silence(0.4))

# ── 2. Bowl ───────────────────────────────────────────────────────────────────
# Tibetan singing bowl: 432 Hz, slow bloom, long resonance, gentle vibrato

def make_bowl():
    bowl = tone(432, 8.0, vol=0.88,
                partials=[(2,0.38),(3,0.16),(4,0.07),(5,0.03)],
                attack=0.5, decay=1.0, sustain=0.65, release=5.0,
                vibrato_hz=4.8, vibrato_depth=0.0028)
    # faint strike transient
    strike = tone(432*3.4, 0.20, vol=0.22,
                  partials=[(2,0.25)],
                  attack=0.003, decay=0.04, sustain=0.05, release=0.12)
    pad = silence(8)
    return mix(bowl, concat(strike, pad[:len(bowl)-len(strike)]))

# ── 3. Chimes ─────────────────────────────────────────────────────────────────
# Pentatonic wind chimes — staggered entries, real bell partial ratios

def make_chimes():
    notes = [hz('C',5), hz('E',5), hz('G',5), hz('A',5), hz('C',6)]
    total = int(SR * 6.5)
    tracks = []
    for i, f in enumerate(notes):
        bell = [(2.756, 0.42), (5.404, 0.18), (8.0, 0.07)]
        t = tone(f, 2.4, vol=0.68, partials=bell,
                 attack=0.006, decay=0.06, sustain=0.28, release=1.8)
        offset = int(SR * i * 0.82)
        pad = silence(offset // SR) if offset > 0 else []
        track = [0]*offset + t
        if len(track) < total: track += [0]*(total - len(track))
        tracks.append(track[:total])
    return mix(*tracks)

# ── 4. Pulse ──────────────────────────────────────────────────────────────────
# 7 soft pulses of a warm A3 chord — bell-curve amplitude, hypnotic

def make_pulse():
    f      = hz('A', 3)          # 220 Hz — low and warm
    warm   = [(2,0.55),(3,0.28),(4,0.10)]
    on, off = 0.38, 0.38
    pulses  = 7
    out     = []
    for i in range(pulses):
        prog = i / (pulses - 1)
        v    = 0.38 + 0.50 * math.sin(math.pi * prog)   # bell curve
        out.extend(tone(f, on, vol=v, partials=warm,
                        attack=0.018, decay=0.05, sustain=0.80, release=0.18))
        out.extend(silence(off))
    return out

# ── 5. Crystal ────────────────────────────────────────────────────────────────
# E-major triad of pure sine waves — absolutely no harmonics → crystal glass

def make_crystal():
    chord = [(hz('E',5), 0.90), (hz('B',4), 0.60), (hz('B',5), 0.52)]
    tracks = []
    for f, v in chord:
        tracks.append(
            tone(f, 6.0, vol=v, partials=None,
                 attack=0.10, decay=0.25, sustain=0.55, release=3.8)
        )
    return mix(*tracks)

# ── Main ─────────────────────────────────────────────────────────────────────

out_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
os.makedirs(out_dir, exist_ok=True)

SOUNDS = [
    ('Sunrise', make_sunrise),
    ('Bowl',    make_bowl),
    ('Chimes',  make_chimes),
    ('Pulse',   make_pulse),
    ('Crystal', make_crystal),
]

for name, fn in SOUNDS:
    path = os.path.join(out_dir, f'{name}.wav')
    print(f'  generating {name}…', end=' ', flush=True)
    s = fn()
    write_wav(path, s)
    print(f'{len(s)/SR:.1f}s')

print('done')
