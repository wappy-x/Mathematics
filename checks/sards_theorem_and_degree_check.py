# Sard's theorem and degree -- the check behind the card.  Standard library only.
# A spinner: one turn of the knob (angle t) drives the pointer to F(t) = G t + A sin t radians.
# The degree comes three ways: preimages counted with signs, net turns read from pointer
# positions alone, and the integral of the slope F'.  Signs are re-read in a second chart.
import math
TAU, G, A, N = 2 * math.pi, 2, 3.0, 3600       # gear ratio G, wobble A radians, N grid steps

def F(t): return G * t + A * math.sin(t)      # pointer angle, not wrapped, radians
def dF(t): return G + A * math.cos(t)         # slope: pointer turn per knob turn
def deg(x): return math.degrees(x)
def fix(x): return 0.0 if abs(x) < 5e-7 else x   # print -0.00 as 0.00

def preimages(f, y, lo=0.0, hi=TAU, closed=True):   # knob angles where f = y + whole turns
    out, ts = [], [lo + (i + 0.5) * (hi - lo) / N for i in range(N)]
    for i in range(N if closed else N - 1):   # f is a formula on all reals: f(t + TAU) = f(t) + G TAU
        a, b = ts[i], (ts[i + 1] if i < N - 1 else ts[0] + TAU)
        ka, kb = math.floor((f(a) - y) / TAU), math.floor((f(b) - y) / TAU)
        if ka != kb:                          # the cell crosses the level y + max(ka, kb) turns
            lev = y + TAU * max(ka, kb)
            for _ in range(60):               # bisection
                m = (a + b) / 2
                a, b = (a, m) if (f(a) - lev) * (f(m) - lev) <= 0 else (m, b)
            r = ((a + b) / 2) % TAU
            out.append(0.0 if r > TAU - 1e-9 else r)
    return sorted(out)

def sgn(s): return 0 if abs(s) < 1e-9 else (1 if s > 0 else -1)
def signed(f, df, y, **kw): return sum(sgn(df(t)) for t in preimages(f, y, **kw))

def net_turns(f, steps=N):                    # road 2: positions only, small turns by atan2
    total, prev = 0.0, (math.cos(f(0)), math.sin(f(0)))
    for i in range(1, steps + 1):
        p = (math.cos(f(TAU * i / steps)), math.sin(f(TAU * i / steps)))
        total += math.atan2(prev[0] * p[1] - prev[1] * p[0], prev[0] * p[0] + prev[1] * p[1])
        prev = p
    return total / TAU

def simpson(g, a, b, n=N):                    # road 3: integral of the slope
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(a + i * h) for i in range(n + 1))

def chart_slope(t, y):                        # second chart: u = tan((angle - c)/2), c = 0 or pi
    cs, cy = (0.0 if math.cos(t) > 0 else math.pi), (0.0 if math.cos(y) > 0 else math.pi)
    phi = lambda u: math.tan((F(cs + 2 * math.atan(u)) - cy) / 2)
    u, h = math.tan((t - cs) / 2), 1e-6
    return (phi(u + h) - phi(u - h)) / (2 * h)

print(f"spinner: pointer = {G} x knob + {A:.1f} rad x sin(knob); wobble {deg(A):.2f} deg")
knobs = list(range(0, 361, 15))
print("chart,knob," + ",".join(str(k) for k in knobs))
print("chart,pointer," + ",".join(f"{deg(F(math.radians(k))):.1f}" for k in knobs))
print("chart,gear only," + ",".join(f"{G * k:.1f}" for k in knobs))

crit = []                                     # critical points: where the slope changes sign
for i in range(N):
    a, b = (i + 0.5) * TAU / N, (i + 1.5) * TAU / N
    if dF(a) * dF(b) < 0:
        for _ in range(60):
            m = (a + b) / 2
            a, b = (a, m) if dF(a) * dF(m) <= 0 else (m, b)
        crit.append((a + b) / 2 % TAU)
cvals = [deg(F(c)) % 360 for c in crit]
print("critical knob angles (slope 0):", " ".join(f"{deg(c):.2f}" for c in crit))
print("critical values (pointer):", " ".join(f"{v:.2f}" for v in cvals))

for name, yd in (("12 o'clock", 0), ("3 o'clock", 90), ("6 o'clock", 180), ("9 o'clock", 270)):
    ts = preimages(F, math.radians(yd))
    print(f"target {name} ({yd} deg): " + " ".join(f"{fix(deg(t)):.2f}({dF(t):+.3f})" for t in ts)
          + f" -> unsigned {len(ts)}, signed {sum(sgn(dF(t)) for t in ts)}")
ts0 = preimages(F, 0.0)
print("by hand:", "; ".join(f"{G * deg(t):.2f} {fix(deg(A * math.sin(t))):+.2f} = {deg(F(t)):.2f}" for t in ts0))
cs = [chart_slope(t, 0.0) for t in ts0]
print("slopes read in the tan charts:", " ".join(f"{s:+.3f}" for s in cs))
assert [sgn(s) for s in cs] == [sgn(dF(t)) for t in ts0], "a chart change flipped a sign"

tally, signs = {}, set()
for j in range(360):                          # targets at 0.5, 1.5, ..., 359.5 degrees
    ts = preimages(F, math.radians(j + 0.5))
    tally[len(ts)] = tally.get(len(ts), 0) + 1
    signs.add(sum(sgn(dF(t)) for t in ts))
print("unsigned counts over 360 targets:", ", ".join(f"{k} at {tally[k]}" for k in sorted(tally)))
print("signed counts over 360 targets:", sorted(signs))
d1, d2, d3 = signed(F, dF, 0.0), net_turns(F), simpson(dF, 0.0, TAU) / TAU
print(f"road 1 signed count {d1}; road 2 net turns {d2:.6f}; road 3 slope integral {d3:.6f}")
assert signs == {d1} and abs(d2 - d1) < 1e-9 and abs(d3 - d1) < 1e-9, "the three roads disagree"
assert (len(tally) > 1) == bool(crit), "unsigned counts vary exactly when the map folds"

covers = []
for m in (36, 360, 3600):                     # Sard: image of the arcs holding a critical point
    w, tot = TAU / m, 0.0
    for i in range(m):
        if dF(i * w) * dF((i + 1) * w) < 0:   # samples, plus the turning point itself
            vals = [F(i * w + w * k / 200) for k in range(201)] + [F(c) for c in crit if int(c / w) == i]
            tot += deg(max(vals) - min(vals))
    print(f"sard cover, {m} arcs of {360 / m:g} deg: bad values fill {tot:.6f} deg")
    covers.append(tot)
assert all(a > 50 * b for a, b in zip(covers, covers[1:])), "a tenfold finer cover shrinks like the square"

if crit:                                      # what breaks 1: count at a critical value
    yc = F(crit[0])
    near = [t for t in preimages(F, yc) if abs(t - crit[0]) > 1e-3] + [crit[0]]
    print(f"at critical value {cvals[0]:.2f}: knob " + " ".join(f"{deg(t):.2f}({fix(dF(t)):+.3f})"
          for t in sorted(near)) + f" -> {len(near)} points, one has no sign")
    assert sgn(dF(crit[0])) == 0 and (len(near) - 1 - d1) % 2 == 0, "transverse points = degree mod 2"
op = [signed(F, dF, math.radians(j + 0.5), hi=math.radians(240), closed=False) for j in range(360)]
print(f"knob limited to 0-240 deg: signed count {op[359]} at 359.5 deg, {op[179]} at 179.5 deg;"
      f" values seen {sorted(set(op))}")
assert len(set(op)) > 1, "an open source lets the signed count change"

cells = [(0.0, 1.0, 0.0, 1.0)]                # what breaks 2: the devil's staircase
for k in range(1, 13):
    cells = [c for a, b, ca, cb in cells for c in ((a, a + (b - a) / 3, ca, (ca + cb) / 2),
                                                   (b - (b - a) / 3, b, (ca + cb) / 2, cb))]
    if k in (4, 8, 12):
        cov, img = sum(b - a for a, b, _, _ in cells), sum(cb - ca for _, _, ca, cb in cells)
        print(f"staircase stage {k}: rough points covered by length {cov:.6f}, their images {img:.6f} turn")
assert abs(cov - (2 / 3) ** 12) < 1e-12 and abs(img - 1) < 1e-12
print(f"staircase: slope 0 on gaps of length {1 - cov:.6f}, so slope integral -> 0 turns; pointer turns {img:.0f}")

mF, mdF = (lambda t: -F(t)), (lambda t: -dF(t))
mirror = (signed(mF, mdF, 0.0), net_turns(mF))
print(f"mirrored dial: signed count {mirror[0]}, net turns {mirror[1]:.6f}")
assert mirror[0] == -d1 and abs(mirror[1] + d1) < 1e-9
print("ALL CHECKS PASS")
