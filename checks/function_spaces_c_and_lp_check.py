# Function spaces C and Lp -- the check behind the card.  Standard library only.
# One day of traffic on a 100 km/h road, as the shortfall below 100 km/h.
# Tuesday: a jam, 60 km/h short from 07:00 to 10:00.  Thursday: a crash,
# 90 km/h short from 15:00 to 15:06.  Sizes use the day as a probability
# (each hour weighs 1/24), so every size is in km/h.  Code holds a truncation:
# a grid of 23,040 cells (3.75 s each) and at most 64 daily harmonics.
from math import cos, sin, pi, sqrt

CELLS = 24 * 960                        # cell width 1/960 h
DT = 24 / CELLS
MID = [(i + 0.5) * DT for i in range(CELLS)]    # midpoints: for averages
NODE = [i * DT for i in range(CELLS + 1)]       # nodes: for the worst moment

def jam(t):                             # Tuesday, with sudden onset and clearing
    return 60.0 if 7 <= t < 10 else 0.0

def crash(t):
    return 90.0 if 15 <= t < 15.1 else 0.0

def ramp(w):                            # the jam with onset and clearing over w hours
    return lambda t: 60.0 * max(0.0, min(1.0, (t - 7) / w, (10 - t) / w))

def total(vals):                        # plain left-to-right sum, as in the Rust
    s = 0.0
    for v in vals:
        s += v
    return s

def avg_p(vals, p):                     # the p-norm, day weighted as a probability
    return (total([abs(v) ** p for v in vals]) / len(vals)) ** (1 / p)

def sizes(f):                           # average, RMS (root mean square), worst moment
    m = [f(t) for t in MID]
    return avg_p(m, 1), avg_p(m, 2), max(abs(f(t)) for t in NODE)

print("bars, the two days under three sizes, km/h")
jt, ct = sizes(jam), sizes(crash)
for name, s in (("jam", jt), ("crash", ct)):
    print(f"{name}: average {s[0]:.4f}  RMS {s[1]:.4f}  worst {s[2]:.4f}")
assert abs(jt[0] - 60 * 3 / 24) < 1e-9 and abs(ct[0] - 90 * 0.1 / 24) < 1e-9
assert abs(jt[1] - sqrt(3600 * 3 / 24)) < 1e-9 and abs(ct[1] - sqrt(8100 * 0.1 / 24)) < 1e-9
print(f"average ratio jam/crash {jt[0] / ct[0]:.4f}, worst ratio crash/jam {ct[2] / jt[2]:.4f}")
print(f"totals without the 1/24: jam {24 * jt[0]:.4f} km, crash {24 * ct[0]:.4f} km")

print("rehearsal: N bins, largest ratio worst/average is N (one-bin spike)")
for N in (24, 96, 288, 1440):
    spike = [90.0] + [0.0] * (N - 1)
    print(f"N {N}: worst/average {max(spike) / avg_p(spike, 1):.1f}")
    assert abs(max(spike) / avg_p(spike, 1) - N) < 1e-9
print("crash seen through bin averages")
for N in (24, 96, 288):
    per = CELLS // N
    m = [crash(t) for t in MID]
    bins = [total(m[i * per:(i + 1) * per]) / per for i in range(N)]
    print(f"N {N}: worst bin {max(bins):.4f}  average {avg_p(bins, 1):.4f}")
    assert abs(avg_p(bins, 1) - ct[0]) < 1e-9    # averaging keeps the average
assert abs(max(bins) - 90) < 1e-9

print("ramps f_w: distances, by geometry and by the grid")
for w in (1, 1 / 2, 1 / 4, 1 / 8, 1 / 16):
    f, h = ramp(w), ramp(w / 2)
    to_jam = avg_p([f(t) - jam(t) for t in MID], 1)
    step = avg_p([f(t) - h(t) for t in MID], 1)
    sup_step = max(abs(f(t) - h(t)) for t in NODE)
    sup_jam = max(abs(f(t) - jam(t)) for t in NODE)
    print(f"w {w:.4f} h: avg to jam {to_jam:.6f}  avg to next {step:.6f}"
          f"  worst to next {sup_step:.4f}  worst to jam {sup_jam:.4f}")
    assert abs(to_jam - 2.5 * w) < 1e-9 and abs(step - 1.25 * w) < 1e-9
    assert abs(sup_step - 30) < 1e-9 and abs(sup_jam - 60) < 1e-9

W = 2 * pi / 24                         # one cycle per day
def coeffs(w, K):                       # Fourier coefficients of the ramped jam (w = 0: jam)
    a0 = 60 * (3 - w) / 24
    lo, hi = 7 + w / 2, 10 - w / 2
    out = []
    for k in range(1, K + 1):
        s = 1.0 if w == 0 else sin(k * W * w / 2) / (k * W * w / 2)
        out.append((60 * (sin(k * W * hi) - sin(k * W * lo)) / (pi * k) * s,
                    60 * (cos(k * W * lo) - cos(k * W * hi)) / (pi * k) * s))
    return a0, out

def fourier_errors(f, w, energy, Ks):
    a0, ab = coeffs(w, max(Ks))
    sm, sn = [a0] * CELLS, [a0] * (CELLS + 1)
    rows, done, par = [], 0, energy - a0 * a0
    for K in Ks:
        for k in range(done + 1, K + 1):
            a, b = ab[k - 1]
            par -= (a * a + b * b) / 2  # Parseval: what the first K harmonics carry
            for i, t in enumerate(MID):
                sm[i] += a * cos(k * W * t) + b * sin(k * W * t)
            for i, t in enumerate(NODE):
                sn[i] += a * cos(k * W * t) + b * sin(k * W * t)
        done = K
        e = [f(t) - s for t, s in zip(MID, sm)]
        rows.append((K, avg_p(e, 1), avg_p(e, 2), sqrt(par),
                     max(abs(f(t) - s) for t, s in zip(NODE, sn))))
    return rows

Ks = (4, 8, 16, 32, 64)
print("daily harmonics S_K: average, RMS (grid), RMS (Parseval), worst")
jr = fourier_errors(jam, 0, 450.0, Ks)
rr = fourier_errors(ramp(0.5), 0.5, 3600 * (3 - 4 * 0.5 / 3) / 24, Ks)
for tag, rows in (("jam", jr), ("ramp 0.5", rr)):
    for K, l1, l2, l2p, sup in rows:
        print(f"{tag} K {K}: {l1:.4f}  {l2:.4f}  {l2p:.4f}  {sup:.4f}")
        assert abs(l2 - l2p) < 1e-3     # grid against Parseval
for K, l1, l2, l2p, sup in jr:
    assert sup > 29.5                   # a jump keeps every continuous curve 30 away
for K, l1, l2, l2p, sup in rr:
    assert sup <= 5760 / (pi * pi * K)  # M-test bound for the ramped jam
assert jr[-1][1] < jr[0][1] / 4 and rr[-1][4] < rr[0][4] / 8
print(f"M-test bound at K 64: {5760 / (pi * pi * 64):.4f}")
print("ALL CHECKS PASS")
