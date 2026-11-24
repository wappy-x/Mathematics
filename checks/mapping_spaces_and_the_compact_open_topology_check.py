# Mapping spaces and the compact-open topology -- the check behind the card.  Standard library only.
# Two ramp profiles on [0, 1], heights in metres: f(s) = s^2 and g(s) = s.  Ramp heights are exact
# integers on the grid s = j/N; the loops use floats only for turn counts, which are rounded to integers.
from math import gcd, atan2, cos, sin, pi

N = 1680                                    # grid s = j/N; N is divisible by 2k for k = 1..8
GRID = range(N + 1)
def frac(p, q):                             # an exact fraction, printed in lowest terms
    d = gcd(p, q); p, q = p // d, q // d
    return str(p) if q == 1 else f"{p}/{q}"
def H(j, i):                                # frame t = i/10 of the slide, at s = j/N, in units 1/(10 N^2)
    return (10 - i) * j * j + i * j * N
def dec(v, den):                            # an exact 3-place decimal
    m = v * 1000 // den
    return f"{m // 1000}.{m % 1000:03d}"

# ---- the straight-line slide from f to g, as a path of maps ----
gap = max(j * N - j * j for j in GRID)      # worst gap g - f on the grid, units 1/N^2
assert frac(gap, N * N) == "1/4" and (N // 2) * N - (N // 2) ** 2 == gap   # brute force = vertex s = 1/2
print(f"worst gap between the ramps: {frac(gap, N * N)} m, at s = {frac(N // 2, N)}")
pairs = 0
for i in range(11):
    for k in range(i, 11):
        d = max(abs(H(j, i) - H(j, k)) for j in GRID)
        assert d * 4 == (k - i) * N * N     # sup distance = |t - t'| / 4, checked independently
        pairs += 1
d37 = max(abs(H(j, 3) - H(j, 7)) for j in GRID)
print(f"sup distance between frames 0 and 1: {frac(max(abs(H(j, 0) - H(j, 10)) for j in GRID), 10 * N * N)} m; frames 0.3 and 0.7: {frac(d37, 10 * N * N)} m")
print(f"all {pairs} pairs of frames on tenths: distance = |t - t'| x 1/4: yes")
print(f"frame 1/2 at s = 1/2: {frac(H(N // 2, 5), 10 * N * N)} m")
for name, i in (("H_0", 0), ("H_1/2", 5), ("H_1", 10)):
    print(f"chart {name}: [{', '.join(dec(H(j * N // 10, i), 10 * N * N) for j in range(11))}]")

# ---- a sup ball round f against a compact-open neighbourhood built from 40 pieces ----
def cands():                                # candidate maps: f plus a tooth wave of height m/100, or a shift
    for m in range(-20, 21):
        for k in range(1, 9):
            if m:
                yield [100 * j * j + m * N * (N - abs(2 * (k * j % N) - N)) for j in GRID]
    for m in range(-12, 13):
        yield [100 * j * j + m * N * N for j in GRID]
P, W = 40, N // 40                          # 40 compact pieces [i/40, (i+1)/40]; U_i widens f(K_i) by 1/20
def in_nbhd(c):
    return all(100 * (i * W) ** 2 - 5 * N * N < c[j] < 100 * ((i + 1) * W) ** 2 + 5 * N * N
               for i in range(P) for j in range(i * W, (i + 1) * W + 1))
def sup(c):
    return max(abs(c[j] - 100 * j * j) for j in GRID)
C = list(cands())
inside = [c for c in C if in_nbhd(c)]
assert inside and all(sup(c) < 10 * N * N for c in inside)          # every one within 1/10 of f
far = [c for c in C if sup(c) >= 10 * N * N]
assert far and not any(in_nbhd(c) for c in far)
print(f"candidates {len(C)}: {len(inside)} pass all {P} piece tests, worst sup distance among them {frac(max(map(sup, inside)), 100 * N * N)} m < 1/10")
print(f"  {len(far)} candidates at sup distance >= 1/10 m: none passes")
rise = max(100 * ((i + 1) * W) ** 2 - 100 * (i * W) ** 2 for i in range(P))   # f's rise on its worst piece
assert rise <= 200 * W * N                  # s^2 rises by at most 2 x the width on [0, 1]
print(f"grid {len(GRID)} points; teeth up to {frac(20, 100)} m high; largest rise of f on one piece: {frac(rise, 100 * N * N)} m, bound 2 x {frac(W, N)} = {frac(2 * W, N)} m")
# one subbasic set V(K, U), K = [0, 1/2], U = (-1/10, 3/10): f(K) = [0, 1/4], room r = 1/20
r = min(0 + 10 * N * N, 30 * N * N - 100 * (N // 2) ** 2)
near = [c for c in C if sup(c) < r]
assert frac(r, 100 * N * N) == "1/20" and all(-10 * N * N < c[j] < 30 * N * N for c in near for j in range(N // 2 + 1))
print(f"V([0, 1/2], (-1/10, 3/10)) round f: room r = {frac(r, 100 * N * N)} m; {len(near)} candidates within r, all inside V: yes")

# ---- what breaks ----
print("mistake, domain not compact: s/n has max on [0, 1] and on [0, n]: " +
      "; ".join(f"n={n}: {frac(max(j for j in GRID), n * N)}, {frac(max(j * n for j in GRID), n * N)}" for n in (1, 10, 100)))
tent = lambda n, p, q: frac(max(0, q - abs(n * p - q)), q)   # max(0, 1 - |n s - 1|) at s = p/q
print("mistake, pointwise only: tent peaked at 1/n, value at s = 1/10 and at the peak: " +
      "; ".join(f"n={n}: {tent(n, 1, 10)}, {tent(n, 1, n)}" for n in (10, 100, 1000)))
coarse = frac(max(3 * k - k * k for k in range(4)), 9)   # s - s^2 at s = k/3, in ninths
assert coarse == "2/9" and frac(gap, N * N) != coarse
print(f"mistake, worst gap on the grid s = 0, 1/3, 2/3, 1: {coarse} m, not 1/4")

# ---- loops on the circle: winding number by two roads ----
M = 360
def wind_turns(th):                         # road 1: add the small turns between neighbours
    pts = [(cos(2 * pi * th(n / M)), sin(2 * pi * th(n / M))) for n in range(M + 1)]
    tot = 0.0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        tot += atan2(x0 * y1 - y0 * x1, x0 * x1 + y0 * y1)
    return round(tot / (2 * pi)), pts
def wind_ray(pts):                          # road 2: signed crossings of the ray at angle 1 radian
    ux, uy, w = cos(1.0), sin(1.0), 0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        a, b = ux * y0 - uy * x0, ux * y1 - uy * x1
        if (a < 0 <= b or b < 0 <= a) and ux * (x0 + x1) + uy * (y0 + y1) > 0:
            w += 1 if b >= 0 else -1
    return w
phi = lambda s: 1 - abs(2 * s - 1)          # out and back
loops = [("wound once", lambda s: s), ("wound twice", lambda s: 2 * s), ("other way", lambda s: -s),
         ("round then back", phi), ("stay put", lambda s: 0.0),
         ("twice, back once", lambda s: 3 * s if s <= 2 / 3 else 4 - 3 * s)]
print(f"winding numbers from {M} samples per loop, by two roads")
found = set()
for name, th in loops:
    w, pts = wind_turns(th)
    assert w == wind_ray(pts)
    found.add(w)
    print(f"loop {name}: winding {w} (ray count {wind_ray(pts)})")
assert sorted(found) == [-1, 0, 1, 2]
print("mistake, counting laps: twice, back once runs 3 laps, but its winding is 1")
# a loop of loops: frame t of Theta(s, t) = 4 t (1 - t) phi(s); the square's edges sit at the base point
fr = [wind_turns(lambda s, t=t / 10: 4 * t * (1 - t) * phi(s)) for t in range(11)]
assert all(w == 0 == wind_ray(p) for w, p in fr)
edge = [p for w, p in (fr[0], fr[10])] + [[p[0], p[-1]] for w, p in fr]
assert all(x == 1.0 and y == 0.0 for e in edge for x, y in e)
print(f"loop of loops: frame windings {[w for w, p in fr]}; every edge point of the square at (1, 0): yes")
print("ALL CHECKS PASS")
