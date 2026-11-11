# Local and global minima on a coffee blend's cost curve.  Standard library only.
# x = Ethiopian share of the blend; robusta is held at 0.2 for strength and
# Brazil fills the rest, 0.8 - x.  Cost is in pounds per kilo; we MINIMISE it.
bean = lambda x: 0.2 * 5 + 9 * (0.8 - x) + 14 * x            # beans at £5, £9, £14 a kilo
pen = lambda x: 1250 * (x - 0.2)**2 * (x - 0.6)**2            # taste penalty, £ a kilo
f = lambda x: bean(x) + pen(x)
df = lambda x: 5 + 2500 * (x - 0.2) * (x - 0.6) * (2 * x - 0.8)
d2f = lambda x: 2500 * ((x - 0.6) * (2 * x - 0.8) + (x - 0.2) * (2 * x - 0.8) + 2 * (x - 0.2) * (x - 0.6))
LO, HI = 0.0, 0.8
for x in (0.1, 0.4, 0.7):                                      # slopes against central differences
    h = 1e-5
    assert abs((f(x + h) - f(x - h)) / (2 * h) - df(x)) < 1e-4
    assert abs((df(x + h) - df(x - h)) / (2 * h) - d2f(x)) < 1e-3
print(f"ends: f(0) = {f(LO):.2f}, f(0.8) = {f(HI):.2f}; middle f(0.4) = {f(0.4):.2f}, penalty {pen(0.4):.2f}")
for a in (0.2, 0.6):                                           # by hand: one Newton step from each taste
    print(f"by hand from {a}: cost {f(a):.2f}, slope {df(a):.0f}, curvature {d2f(a):.0f}, step to {a - df(a) / d2f(a):.4f}, cost about {f(a) - df(a)**2 / (2 * d2f(a)):.5f}")
print("chart x = 0.05..0.75:", ", ".join(f"{f(0.05 * i):.2f}" for i in range(1, 16)))

def walk(x, g=f, step=0.01):                                   # road 1: downhill walk, values only
    n = 1
    while step > 1e-9:
        for t in (x - step, x + step):
            n += 1
            if LO <= t <= HI and g(t) < g(x):
                x = t
                break
        else:
            step /= 2
    return x, n
runs = {}
for s in (0.05, 0.75):
    x, n = walk(s)
    runs[s] = x
    print(f"walk from {s:.2f}: x = {x:.6f}, cost {f(x):.6f}, {n} evaluations, slope size {abs(df(x)):.4f}, curvature {d2f(x):.2f}")
    assert abs(df(x)) < 1e-5 and d2f(x) > 0                     # local certificate holds at both
def bisect(a, b):                                              # road 2: every flat spot of f
    assert df(a) * df(b) < 0
    for _ in range(60):
        m = (a + b) / 2
        a, b = (m, b) if df(a) * df(m) > 0 else (a, m)
    return (a + b) / 2
print(f"slope signs at 0, 0.3, 0.5, 0.8: {df(0.0):.0f}, {df(0.3):.0f}, {df(0.5):.0f}, {df(0.8):.0f}")
cands = [LO, HI] + [bisect(a, b) for a, b in ((0.0, 0.3), (0.3, 0.5), (0.5, 0.8))]
for c in cands:
    kind = "end" if c in (LO, HI) else ("local min" if d2f(c) > 0 else "local max")
    print(f"candidate x = {c:.6f}: cost {f(c):.6f} ({kind})")
xstar = min(cands, key=f)
print(f"global: x* = {xstar:.6f}, min cost {f(xstar):.6f}; other dip costs {f(runs[0.75]) - f(xstar):.6f} more, £{1000 * (f(runs[0.75]) - f(xstar)):.0f} a tonne")
assert abs(runs[0.05] - xstar) < 1e-6 and abs(runs[0.75] - cands[4]) < 1e-6
basin = sum(abs(walk(i / 100)[0] - xstar) < 1e-6 for i in range(81))
print(f"starts 0.00, 0.01, ..., 0.80 reaching x*: {basin} of 81; local max at {cands[3]:.6f}")
L = 5 + 2500 * 0.6 * 0.6 * 0.8                                 # road 3: slope bound on [0, 0.8]
steep = max(abs(df(i / 10000)) for i in range(8001))
assert steep <= L
grid = [f(i / 1000) for i in range(801)]
gbest = min(grid)
lower = gbest - L * 0.001 / 2
print(f"slope bound L = {L:.0f} (steepest seen {steep:.2f}); 801-point grid best {gbest:.6f}")
print(f"grid gap h = 0.001, slack L*h/2 = {L * 0.001 / 2:.4f}")
print(f"certificate: no blend costs below {lower:.6f}; best found {f(xstar):.6f}")
assert lower <= f(xstar) <= gbest
c0, w, depth = 0.4005, 0.0004, 4.0                             # a narrow dip between grid points
dip = lambda x: -depth * (1 - ((x - c0) / w)**2)**2 if abs(x - c0) < w else 0.0
g = lambda x: f(x) + dip(x)
assert all(g(i / 1000) == grid[i] for i in range(801))
assert all(walk(i / 100, g)[0] == walk(i / 100)[0] for i in range(81))
gsteep = max(abs(g(c0 + w * (k + 1) / 1000) - g(c0 + w * k / 1000)) / (w / 1000) for k in range(-1000, 1000))
print(f"hidden dip, depth {depth:.0f}, half-width {w}, centre {c0}: same 801 grid values, same walks from all 81 starts")
print(f"hidden dip: lowest cost now g({c0}) = {g(c0):.6f}; steepest slope {gsteep:.0f}")
assert g(c0) < lower
assert abs(gsteep - (depth / w * 8 / 27**0.5 + df(c0))) < 1    # dip's steepest slope, from its formula
print(f"breaks, bean cost only: lowest at x = 0, £{bean(0):.2f} of beans, true cost {f(0):.2f}")
x = 0.42                                                       # Newton on slope = 0, curvature unchecked
for _ in range(6):
    x -= df(x) / d2f(x)
print(f"breaks, Newton on slope = 0 from 0.42: x = {x:.6f}, cost {f(x):.6f}, curvature {d2f(x):.2f}")
assert abs(x - cands[3]) < 1e-9 and d2f(x) < 0
print("ALL CHECKS PASS")
