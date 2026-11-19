# Frechet mean -- the check behind the card.  Standard library only (math).  Six rock cores:
# each gives a compass bearing D and a dip I of its magnetisation.  Part 1 averages the bearings
# alone, on the circle.  Part 2 averages the full directions, on the sphere, and finds the leading geodesic.
import math
D = [340.0, 350.0, 355.0, 5.0, 10.0, 30.0]          # bearing, degrees clockwise from north
I = [50.0, 58.0, 54.0, 63.0, 60.0, 72.0]            # dip, degrees below horizontal
N, R2D = len(D), 180.0 / math.pi
D2 = R2D * R2D                                      # square degrees per square radian

def sq(x): return x * x
def wrap(a): return (a + 180.0) % 360.0 - 180.0     # an angle difference into [-180, 180)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def vec(d, i):                                      # (north, east, down), a unit arrow
    d, i = d / R2D, i / R2D
    return (math.cos(i) * math.cos(d), math.cos(i) * math.sin(d), math.sin(i))
def chart(m): return (math.atan2(m[1], m[0]) * R2D % 360.0, math.asin(m[2]) * R2D)
def dist(a, b): return math.acos(max(-1.0, min(1.0, dot(a, b))))   # radians
def log(m, x):                                      # the arrow at m that aims at x
    c = max(-1.0, min(1.0, dot(m, x)))
    w = [x[k] - c * m[k] for k in range(3)]
    s = math.sqrt(dot(w, w))
    return [0.0, 0.0, 0.0] if s == 0.0 else [math.acos(c) * w[k] / s for k in range(3)]
def exp(m, v):                                      # shoot from m along v
    t = math.sqrt(dot(v, v))
    if t == 0.0: return m
    y = [math.cos(t) * m[k] + math.sin(t) * v[k] / t for k in range(3)]
    s = math.sqrt(dot(y, y))                        # rescale away rounding drift off the sphere
    return tuple(y[k] / s for k in range(3))
def sci(x):                                         # x as d.dd e-n, the same in Rust
    n = math.floor(math.log10(x))
    return f"{x / 10.0 ** n:.2f}e{n}"
def frechet(m, pts): return sum(sq(dist(m, x)) for x in pts) / len(pts)

print("part 1: the six bearings on the circle")
print("bearings: " + ", ".join(f"{d:.0f}" for d in D))
naive = sum(D) / N
m1 = (D[0] + sum(wrap(d - D[0]) for d in D) / N) % 360.0  # road 1: one log-average-exp step
again = sum(wrap(d - m1) for d in D) / N                  # a second step moves it by this much
F1 = lambda b: sum(sq(wrap(d - b)) for d in D) / N
scan1 = min((F1(k / 100.0), k / 100.0) for k in range(36000))[1]    # road 2: scan every 0.01 deg
ext1 = math.atan2(sum(math.sin(d / R2D) for d in D), sum(math.cos(d / R2D) for d in D)) * R2D % 360.0
print(f"average of the numbers: {naive:.2f} deg")
print(f"Frechet mean, one step from {D[0]:.0f}: {m1:.2f} deg; a second step moves it {abs(again):.2f} deg")
print("turns from 340: " + ", ".join(f"{wrap(d - D[0]):.0f}" for d in D) + f", sum {sum(wrap(d - D[0]) for d in D):.0f}")
print("turns from the mean: " + ", ".join(f"{wrap(d - m1):.2f}" for d in D))
print(f"Frechet mean, scanning 36000 bearings: {scan1:.2f} deg")
print(f"spread at the mean: {F1(m1):.2f} deg^2, rms {math.sqrt(F1(m1)):.2f} deg")
print(f"spread at the number average: {F1(naive):.2f} deg^2")
print(f"vector average of the bearings: {ext1:.2f} deg")
pair = lambda b: (sq(wrap(0.0 - b)) + sq(wrap(180.0 - b))) / 2
print(f"bearings 350 and 10: number average {(350 + 10) / 2:.0f}, Frechet mean "
      f"{min((sq(wrap(350 - k / 10)) + sq(wrap(10 - k / 10)), k / 10) for k in range(3600))[1]:.0f}")
print(f"bearings 0 and 180: spread {pair(90):.0f} at 90, {pair(270):.0f} at 270, {pair(0):.0f} at 0")

print("part 2: the six full directions on the sphere")
X = [vec(d, i) for d, i in zip(D, I)]
print("core  bearing  dip   north   east    down")
for k in range(N):
    print(f"{k + 1:>4}{D[k]:>9.0f}{I[k]:>5.0f}{X[k][0]:>8.4f}{X[k][1]:>8.4f}{X[k][2]:>8.4f}")
m, it, moves = X[0], 0, []                          # road 1: average the logs, shoot, repeat
print("step    bearing        dip   move (deg)")
while True:
    g = [sum(log(m, x)[k] for x in X) / N for k in range(3)]
    m, it, mv = exp(m, g), it + 1, math.sqrt(dot(g, g)) * R2D
    moves += [mv]
    print(f"{it:>4}{chart(m)[0]:>11.6f}{chart(m)[1]:>11.6f}   {sci(mv)}")
    if mv < 1e-9: break
Fm = frechet(m, X)
def grid(d0, i0, h, n):                             # road 2: scan a bearing-dip grid
    best = None
    for a in range(-n, n + 1):
        for b in range(-n, n + 1):
            i = max(-90.0, min(90.0, i0 + b * h))
            f = frechet(vec(d0 + a * h, i), X)
            if best is None or f < best[0]: best = (f, (d0 + a * h) % 360.0, i)
    return best
g1 = grid(180.0, 0.0, 1.0, 180)
gd = g1
for h in (0.1, 0.01, 0.001, 0.0001, 0.00001): gd = grid(gd[1], gd[2], h, 20)
gap = max(abs(wrap(gd[1] - chart(m)[0])), abs(gd[2] - chart(m)[1]))
print(f"whole-sphere grid, 1 deg steps: bearing {g1[1]:.0f}, dip {g1[2]:.0f}, "
      f"{dist(m, vec(g1[1], g1[2])) * R2D:.4f} deg from road 1")
print(f"grid refined to 1e-5 deg: bearing {gd[1]:.5f}, dip {gd[2]:.5f}, {sci(gap)} deg from road 1")
print(f"Frechet variance {Fm * D2:.2f} deg^2, rms angle {math.sqrt(Fm) * R2D:.2f} deg")
S = [sum(x[k] for x in X) for k in range(3)]
rbar = math.sqrt(dot(S, S)) / N
e = tuple(s / (N * rbar) for s in S)
print(f"vector (Fisher) mean: bearing {chart(e)[0]:.4f}, dip {chart(e)[1]:.4f}, "
      f"length {rbar:.4f}, {dist(m, e) * R2D:.4f} deg from the Frechet mean")
print(f"dipole latitude from the mean dip: {math.atan(math.tan(chart(m)[1] / R2D) / 2) * R2D:.1f} deg")
d0, i0 = chart(m)[0] / R2D, chart(m)[1] / R2D       # unit arrows at the mean: steeper, clockwise
eI = (-math.sin(i0) * math.cos(d0), -math.sin(i0) * math.sin(d0), math.cos(i0))
eD = (-math.sin(d0), math.cos(d0), 0.0)
P = [(dot(v, eD) * R2D, dot(v, eI) * R2D) for v in (log(m, x) for x in X)]
print("core  clockwise  steeper   (log-map coordinates at the mean, deg)")
for k in range(N): print(f"{k + 1:>4}{P[k][0]:>10.3f}{P[k][1]:>9.3f}")
sx, sy = sum(p[0] for p in P) / N, sum(p[1] for p in P) / N
a, b, c = sum(sq(p[0]) for p in P) / N, sum(p[0] * p[1] for p in P) / N, sum(sq(p[1]) for p in P) / N  # C = [[a, b], [b, c]]
root = math.sqrt(sq((a - c) / 2) + b * b)
l1, l2 = (a + c) / 2 + root, (a + c) / 2 - root
psi = math.atan2(l1 - a, b) * R2D                   # angle of the top eigenvector from clockwise
u = (math.cos(psi / R2D), math.sin(psi / R2D))
cu = (a * u[0] + b * u[1], b * u[0] + c * u[1])     # the matrix times u, against l1 times u
print(f"centre of the log points: {abs(sx):.6f}, {abs(sy):.6f} deg")
print(f"covariance: {a:.3f} {b:.3f} / {b:.3f} {c:.3f} deg^2")
print(f"eigenvalues {l1:.3f} and {l2:.3f}, sum {l1 + l2:.3f}; leading share {100 * l1 / (l1 + l2):.1f}%")
rate = moves[4] / moves[3]                          # the slowest error lies across the leading geodesic
print(f"each move over the one before: {rate:.5f}; leading spread in square radians, over 3: {l1 / D2 / 3:.5f}")
print(f"leading direction {psi:.2f} deg from clockwise toward steeper; check C u = ({cu[0]:.3f}, {cu[1]:.3f}), "
      f"l1 u = ({l1 * u[0]:.3f}, {l1 * u[1]:.3f})")
def along(t):                                       # road 2: project onto the true great circle
    w = tuple(math.cos(t / R2D) * eD[k] + math.sin(t / R2D) * eI[k] for k in range(3))
    s = [math.atan2(dot(x, w), dot(x, m)) for x in X]
    return sum(q * q for q in s) / N * D2
best = max((along(k / 100.0), k / 100.0) for k in range(18000))
print(f"exact great-circle scan: best {best[1]:.2f} deg, variance along it {best[0]:.3f} deg^2")
ends = [chart(exp(m, tuple(sg * 2 * math.sqrt(l1) / R2D * (u[0] * eD[k] + u[1] * eI[k]) for k in range(3)))) for sg in (-1, 1)]
print(f"two standard deviations, 2 x {math.sqrt(l1):.2f} deg, either way: ({ends[0][0]:.1f}, {ends[0][1]:.1f}) and ({ends[1][0]:.1f}, {ends[1][1]:.1f})")
fx = sum(wrap(d) for d in D) / N
fa = [(wrap(d) - fx, i - sum(I) / N) for d, i in zip(D, I)]
fc = [sum(p[j] * p[k] for p in fa) / N for j, k in ((0, 0), (0, 1), (1, 1))]
flat = 0.5 * math.atan2(2 * fc[1], fc[0] - fc[2]) * R2D             # an angle on the raw chart
onsph = math.atan2(math.sin(flat / R2D), math.cos(flat / R2D) * math.cos(i0)) * R2D  # the same line on the sphere
sep = vec(m1, sum(I) / N)
print(f"mistake: PCA on raw bearing and dip: {flat:.2f} deg on the chart, {onsph:.2f} on the sphere, {psi - onsph:.2f} short of {psi:.2f}")
print(f"mistake: bearing and dip averaged apart: ({m1:.2f}, {sum(I) / N:.2f}), "
      f"{dist(m, sep) * R2D:.3f} deg from the mean, spread {frechet(sep, X) * D2:.2f} deg^2")
sc = 4.0                                            # figure: 4 px per degree, centre (330, 110)
print("figure, log-map pixels: " + " ".join(f"({330 + sc * p[0]:.1f},{110 - sc * p[1]:.1f})" for p in P))
L = sc * 2 * math.sqrt(l1)                          # two standard deviations, in pixels
print(f"figure, leading line pixels: ({330 - L * u[0]:.1f},{110 + L * u[1]:.1f}) to ({330 + L * u[0]:.1f},{110 - L * u[1]:.1f})")
print("figure, compass pixels: " + " ".join(
    f"({100 + 70 * math.sin(d / R2D):.1f},{110 - 70 * math.cos(d / R2D):.1f})" for d in D + [m1, naive]))
assert abs(wrap(m1 - scan1)) <= 0.006 and abs(naive - m1) > 170   # two roads; the trap is real
assert gap < 2e-5 and dist(m, vec(g1[1], g1[2])) * R2D < 1.0      # iteration against grid
assert abs((l1 + l2) - Fm * D2) < 1e-9 and abs(cu[0] - l1 * u[0]) + abs(cu[1] - l1 * u[1]) < 1e-9      # trace = variance; eigenvector
assert 0.05 < abs(best[1] - psi) < 0.3 and l1 < best[0] < l1 * 1.01  # exact scan: a small tilt, a longer spread
assert pair(90) == pair(270) and pair(90) < pair(0)               # antipodes: two means
assert abs(rate / (l1 / D2 / 3) - 1) < 0.1                        # convergence factor as linearising predicts
print("ALL CHECKS PASS")
