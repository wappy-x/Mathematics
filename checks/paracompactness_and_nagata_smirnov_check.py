# Paracompactness, partitions of unity, Nagata-Smirnov -- the check behind the card.  Standard library only.
# The line, covered by U_n = (n - 3/2, n + 3/2).  Survey heights in metres at kilometre markers 0 to 5.
from fractions import Fraction as Fr
from math import floor
half = Fr(1, 2)
grid = [Fr(j, 20) for j in range(-400, 401)]                    # x from -20 to 20 in steps of 0.05
ns = range(-25, 26)
near = lambda x: range(floor(x) - 3, floor(x) + 4)               # tents and dials vanish beyond these
inU = lambda x, n: abs(x - n) < Fr(3, 2)
tent = lambda x, n: max(Fr(0), 1 - abs(x - n))                  # zero outside [n - 1, n + 1]
inside = [sum(inU(x, n) for n in ns) for x in grid]
meets = [sum(abs(x - n) < 2 for n in ns) for x in grid]         # U_n meets (x - 1/2, x + 1/2)
print(f"cover U_n=(n-1.5,n+1.5) on {len(grid)} grid points: each point in {min(inside)} to {max(inside)} sets; "
      f"a width-1 window meets at most {max(meets)}")
assert min(inside) == 2 and max(inside) == 3 and max(meets) == 4
assert all(tent(x, n) == 0 for x in grid for n in ns if n not in near(x))
assert all(sum(tent(x, n) for n in near(x)) == 1 for x in grid)  # term-by-term sum, exact
assert all(sum(tent(x, n) * n for n in near(x)) == x for x in grid)  # tents reproduce straight lines
print(f"tents: sum exactly 1 at all {len(grid)} points; support [n-1,n+1] sits inside U_n with {half} to spare")
x = Fr(23, 10)
print(f"x=2.3: in U_n for n = {[n for n in ns if inU(x, n)]}; nonzero tents "
      + ", ".join(f"phi_{n}={tent(x, n)}" for n in ns if tent(x, n)))
assert tent(x, 2) == Fr(7, 10) and tent(x, 3) == Fr(3, 10)
h = {0: 120, 1: 128, 2: 135, 3: 150, 4: 146, 5: 140}           # heights at the markers, metres
print(f"heights at markers {min(h)} to {max(h)} km: {', '.join(str(h[n]) for n in sorted(h))} m")
glue = lambda x, w: sum(w(x, n) * h[n] for n in h)
line = h[2] + (x - 2) * (h[3] - h[2])                            # second road: straight line, markers 2 to 3
print(f"glued height at 2.3 km: tents {float(glue(x, tent)):.1f} m; straight line between markers {float(line):.1f} m")
assert glue(x, tent) == line == Fr(279, 2)
# the proof's construction: shrink to W_n=(n-3/5,n+3/5), Urysohn dial 1 on [n-3/5,n+3/5], 0 outside (n-6/5,n+6/5)
def psi(x, n):
    dA, dB = max(Fr(0), Fr(6, 5) - abs(x - n)), max(Fr(0), abs(x - n) - Fr(3, 5))
    return dA / (dA + dB)
Psi = lambda x: sum(psi(x, n) for n in near(x))
phi = lambda x, n: psi(x, n) / Psi(x)
assert all(any(abs(x - n) < Fr(3, 5) for n in ns) for x in grid)  # the shrunk sets W_n still cover
assert all(1 <= Psi(x) <= 2 and sum(phi(x, n) for n in near(x)) == 1 for x in grid)
assert all(psi(x, n) == 0 for x in grid for n in ns if abs(x - n) >= Fr(6, 5))
print(f"dial partition: Psi between {min(Psi(x) for x in grid)} and {max(Psi(x) for x in grid)}; after dividing, "
      f"sum exactly 1 at all {len(grid)} points; support [n-6/5,n+6/5] inside U_n")
print(f"dial partition at 2.3: psi_2={psi(x, 2)} psi_3={psi(x, 3)} Psi={Psi(x)} phi_2={phi(x, 2)} phi_3={phi(x, 3)}; "
      f"glued height {glue(x, phi)} = {float(glue(x, phi)):.3f} m")
assert phi(x, 2) == Fr(6, 11) and glue(x, phi) == Fr(1560, 11)
# thinning: the cover V_k = (-k, k) by the proof's ring recipe; a set is (lo, hi) meaning lo < |x| < hi
V = [(-1, k) for k in range(1, 41)]
def ring_refine(cover, K):
    out = []
    for k in range(1, K + 1):                                    # compact ring C_k: k-1 <= |x| <= k
        lo, hi = next(c for c in cover if c[0] < k - 1 and c[1] > k)   # first member holding C_k
        out.append((max(lo, k - 2), min(hi, k + 1)))             # cut down to the open ring k-2 < |x| < k+1
    return out
W = ring_refine(V, 30)
has = lambda s, x: s[0] < abs(x) < s[1]
def meets_win(s, a, b):                                         # does s meet the window (a, b)?
    m1, m2 = (Fr(-1), max(-a, b)) if a < 0 < b else (min(abs(a), abs(b)), max(abs(a), abs(b)))
    return s[0] < m2 and m1 < s[1]
inW = [sum(has(s, x) for s in W) for x in grid]
mW = [sum(meets_win(s, x - half, x + half) for s in W) for x in grid]
print(f"V_k=(-k,k): the first K sets all hold 0: " + ", ".join(f"K={K}: {sum(has((-1, k), 0) for k in range(1, K + 1))}"
      for K in (10, 100, 1000)))
print("ring refinement W_k={k-2<|x|<k+1}: " + " ".join(f"W_{k}: {lo}<|x|<{hi}" for k, (lo, hi) in enumerate(W[:3], 1))
      + f"; each point in {min(inW)} to {max(inW)} sets, a width-1 window meets at most {max(mW)}")
assert min(inW) >= 1 and max(inW) == 3 and max(mW) == 4
assert all(any(v[0] <= w[0] and w[1] <= v[1] for v in V) for w in W)   # each W_k sits inside some V
# Nagata-Smirnov layers on the line: layer j holds ((m-1)/2^j, (m+1)/2^j) for every whole m
g2 = [Fr(i, 160) for i in range(-480, 481)]
for j in (0, 3, 6):
    cnt = lambda x, t: sum(abs(2 ** j * x - m) < t for m in range(floor(2 ** j * x) - 3, floor(2 ** j * x) + 4))
    c1, c2 = max(cnt(x, 1) for x in g2), max(cnt(x, Fr(3, 2)) for x in g2)
    print(f"layer {j}: intervals of width {Fr(2, 2 ** j)}; each point in at most {c1}, a window of radius 1/{2 ** (j + 1)} meets at most {c2}")
    assert c1 == 2 and c2 == 3
def basic(x, r):                                                # a layer set holding x inside (x - r, x + r)
    j = next(j for j in range(40) if Fr(2, 2 ** j) <= r)
    m = floor(2 ** j * x) + (1 if 2 ** j * x - floor(2 ** j * x) > half else 0)
    return j, Fr(m - 1, 2 ** j), Fr(m + 1, 2 ** j)
j, a, b = basic(x, Fr(1, 10))
print(f"basis at x=2.3, r=0.1: layer {j}, interval ({a}, {b}) = ({float(a)}, {float(b)})")
assert a < x < b and x - Fr(1, 10) <= a and b <= x + Fr(1, 10)
assert all(a < z < b and z - r <= a and b <= z + r for z in g2 for r in (half, Fr(1, 10), Fr(1, 100)) for _, a, b in [basic(z, r)])
print(f"basis check: a layer set fits inside every ball tested, {len(g2)} points x 3 radii")
# what breaks
print(f"no normalising: psi_2 + psi_3 at 2.3 = {Psi(x)}, so sum psi*h = {float(glue(x, psi)):.1f} m, not {float(glue(x, phi)):.3f} m")
assert glue(x, psi) == 260
sup = [z for z in grid if tent(z, 2) > 0]                       # tent 2 is nonzero on (1, 3); its closure adds 1 and 3
ends = (sup[0] - Fr(1, 20), sup[-1] + Fr(1, 20))
print(f"open cover (n-1,n+1): support of phi_2 is [{ends[0]}, {ends[1]}]; ends inside U_2=(1,3): {[1 < e < 3 for e in ends]}")
assert ends == (1, 3) and not any(1 < e < 3 for e in ends) and all(abs(e - 2) < Fr(3, 2) for e in ends)
print("figure, bars " + " ".join(f"U_{n}=({n - Fr(3, 2)}, {n + Fr(3, 2)})" for n in sorted(h))
      + f"; tents peak at (n, 1) for n = {min(h)}..{max(h)}; at x={float(x)} dots {float(tent(x, 2))} and {float(tent(x, 3))}")
print("ALL CHECKS PASS")
