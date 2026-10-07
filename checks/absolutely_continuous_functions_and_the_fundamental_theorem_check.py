# Absolutely continuous functions and the fundamental theorem -- the check behind the card.
# Standard library only.  A one-hour trip: the odometer F against the speedometer v,
# three roads to the distance, the epsilon-delta test by random collections of intervals,
# then the Cantor staircase stage by stage in exact fractions.
from fractions import Fraction as Fr
from math import sqrt

def v(t):                        # speed, km/h; each gear change switches it at an instant
    return 300 * t if t < 0.2 else 90.0 if t < 0.5 else 0.0 if t < 0.6 else 45.0

def F(t):                        # odometer, km, written from the legs, not from v
    if t <= 0.2: return 150 * t * t
    if t <= 0.5: return 6 + 90 * (t - 0.2)
    if t <= 0.6: return 33.0
    return 33 + 45 * (t - 0.6)

def integral(g, a, b, n):        # midpoint rule, n pieces
    w = (b - a) / n
    return sum(g(a + (i + 0.5) * w) for i in range(n)) * w

def above(y):                    # length of {t : v(t) > y}, read off the legs
    return max(0.0, 0.2 - y / 300) + (0.3 if y < 90 else 0.0) + (0.4 if y < 45 else 0.0)

S = [20260929]                   # SplitMix64, seed 20260929
def rnd():
    S[0] = (S[0] + 0x9E3779B97F4A7C15) % 2**64
    z = S[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2**53

def worst_move(G, delta, trials):  # largest sum |G(b) - G(a)| over random disjoint collections
    worst = 0.0
    for _ in range(trials):
        k = 1 + int(rnd() * 8)
        pts = sorted(rnd() for _ in range(k))
        ws = [rnd() for _ in range(k)]
        tot = sum(ws)
        iv = [(p, min(p + 0.999 * delta * w / tot, 1.0)) for p, w in zip(pts, ws)]
        if any(iv[i][1] > iv[i + 1][0] for i in range(k - 1)): continue
        worst = max(worst, sum(abs(G(b) - G(a)) for a, b in iv))
    return worst

legs = [(0.0, 0.2), (0.2, 0.5), (0.5, 0.6), (0.6, 1.0)]
print("legs, h: speed at start and end km/h, distance km:", "; ".join(
    f"{a:.1f}-{b:.1f}: {v(a):.0f} to {v(b - 1e-12):.0f}, {F(b) - F(a):.2f}" for a, b in legs))
print("odometer km at t = 0.0, 0.1, ..., 1.0 h:", " ".join(f"{F(i / 10):.2f}" for i in range(11)))
odo, mid, lay = F(1.0) - F(0.0), integral(v, 0, 1, 100000), integral(above, 0, 90, 90000)
print(f"distance: odometer {odo:.4f} | integral of speed, midpoint {mid:.4f} | layer cake {lay:.4f}")
assert abs(mid - odo) < 1e-6
assert abs(lay - odo) < 1e-6
A = [(0.1, 0.3), (0.45, 0.55), (0.7, 0.95)]
dA = sum(F(b) - F(a) for a, b in A)
iA = integral(lambda t: v(t) if any(a <= t < b for a, b in A) else 0.0, 0, 1, 100000)
print(f"distance during A: odometer differences {dA:.4f} | integral of speed over A {iA:.4f}")
assert abs(dA - iA) < 1e-6
for c in (0.2, 0.5, 0.6):
    L, R = (F(c) - F(c - 0.001)) / 0.001, (F(c + 0.001) - F(c)) / 0.001
    print(f"gear change t = {c}: left quotient {L:.2f}, right quotient {R:.2f} (h = 0.001)")
    assert abs(L - v(c - 1e-9)) < 0.2
    assert abs(R - v(c + 1e-9)) < 0.2
    assert abs(R - L) > 20
ok = near = 0
for _ in range(1000):
    t = 0.001 + 0.998 * rnd()
    if min(abs(t - c) for c in (0.2, 0.5, 0.6)) < 1e-6: near += 1; continue
    ok += abs((F(t + 1e-6) - F(t - 1e-6)) / 2e-6 - v(t)) < 1e-4
print(f"1000 random times: quotient within 0.0001 of speed at {ok}, within 1e-6 of a gear change {near}")
assert ok + near == 1000
w_trip = worst_move(F, 0.1 / 90, 2000)
hand = F(0.2 + 0.999 * 0.1 / 90) - F(0.2)
print(f"trip, eps 0.1 km, delta 0.1/90 = {0.1 / 90:.6f} h ({3600 * 0.1 / 90:.1f} s): random worst {w_trip:.4f}, all in the 90 km/h leg {hand:.4f}")
assert w_trip < 0.1
assert hand < 0.1
var = sum(abs(F((i + 1) / 1000) - F(i / 1000)) for i in range(1000))
print(f"AC gives BV: eps 1, delta 1/90, 91 pieces, variation at most 91; measured variation {var:.4f}")
assert var <= 91
assert abs(var - lay) < 1e-6
w_sq = worst_move(sqrt, 0.01, 2000)
print(f"sqrt: quotient at 0 is {sqrt(0.01) / 0.01:.2f} (h = 0.01), {sqrt(0.0001) / 0.0001:.2f} (h = 0.0001)")
print(f"sqrt, eps 0.1, delta 0.01: random worst {w_sq:.4f}, one interval at 0 {sqrt(0.00999):.4f}")
assert w_sq <= sqrt(0.01)
m1, m2 = (integral(lambda s: 1 / (2 * sqrt(s)), 0, 1, n) for n in (100, 10000))
print(f"sqrt: integral of 1/(2 sqrt s) on [0,1], midpoint n=100 {m1:.4f}, n=10000 {m2:.4f}; sqrt 1 - sqrt 0 = 1")
assert abs(m1 - 1) < 0.1
assert abs(m2 - 1) < abs(m1 - 1)

def cantor(x):                   # the staircase, read off the ternary digits of x
    if x == 1: return Fr(1)
    val, half = Fr(0), Fr(1, 2)
    while x != 0:
        x *= 3; d = int(x); x -= d
        if d == 1: return val + half
        val += half * (d // 2); half /= 2
    return val

print("stage n: kept intervals, their length, counter rise on them, rise on the gaps, gap length")
kept, gaps = [(Fr(0), Fr(1))], []
for n in range(1, 13):
    new = []
    for a, b in kept:
        t = (b - a) / 3
        new += [(a, a + t), (b - t, b)]; gaps.append((a + t, b - t))
    kept = new
    if n in (1, 2, 3, 5, 10, 12):
        ln = sum(b - a for a, b in kept); rise = sum(cantor(b) - cantor(a) for a, b in kept)
        grise = sum(cantor(b) - cantor(a) for a, b in gaps); gl = sum(b - a for a, b in gaps)
        print(f"stage {n:2d}: {len(kept):4d} | {float(ln):.6f} | {float(rise):.4f} | {float(grise):.4f} | {float(gl):.6f}")
        assert ln == Fr(2, 3) ** n
        assert rise == cantor(Fr(1)) - cantor(Fr(0))
        assert grise == 0
        assert all(cantor(b) - cantor(a) == Fr(1, 2**n) for a, b in kept)
        if n == 3:
            pts = []
            for a, b in kept: pts += [(a, cantor(a)), (b, cantor(b))]
        if n == 10:
            a, b = kept[0]
            print(f"stage 10, one interval: length {float(b - a):.7f}, rise {float(cantor(b) - cantor(a)):.7f}")
n12 = next(n for n in range(1, 40) if Fr(2, 3) ** n < Fr(1, 100))
print(f"cantor, eps 0.5, delta 0.01: first stage below delta {n12}, length {float(ln):.6f}, rise {float(rise):.4f}")
print("figure, stage-3 staircase at 200 units per unit, origin (60, 220):",
      " ".join(f"{60 + 200 * float(x):.2f},{220 - 200 * float(y):.2f}" for x, y in pts))
