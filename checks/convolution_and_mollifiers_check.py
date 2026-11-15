# Convolution and mollifiers: smooth a jagged GPS track with a shrinking bump.
from math import exp, cos, sin

Y = [0.0, 2.0, -1.0, 3.0, 1.0, 4.0, 0.0, 2.0, -2.0, 1.0, 0.0]  # offsets (m), one fix per second

def bump(u):                       # exp(-1/(1-u^2)) inside (-1, 1), zero outside
    return exp(-1.0 / (1.0 - u * u)) if abs(u) < 1.0 else 0.0

R = 0.6 ** 0.5
def gauss(g, a, b, n):             # n panels of 3-point Gauss-Legendre; never touches a or b
    h, s = (b - a) / n, 0.0
    for i in range(n):
        c = a + (i + 0.5) * h
        s += 5.0 * g(c - 0.5 * h * R) + 8.0 * g(c) + 5.0 * g(c + 0.5 * h * R)
    return s * h / 18.0

Z = gauss(bump, -1.0, 1.0, 2000)                    # the bump's area
def eta(u): return bump(u) / Z                         # unit-area bump
def deta(u): return eta(u) * (-2.0 * u / (1.0 - u * u) ** 2) if abs(u) < 1.0 else 0.0
m1 = gauss(lambda u: abs(u) * eta(u), -1.0, 1.0, 2000)  # mean distance |u| under the bump

def joined(t):                     # fixes joined by straight lines, zero outside 0..10 s
    if t <= 0.0 or t >= 10.0: return 0.0
    k = int(t); return Y[k] + (Y[k + 1] - Y[k]) * (t - k)
def held(t):                       # each fix held for one second, zero outside 0..10 s
    return Y[int(t)] if 0.0 <= t < 10.0 else 0.0

def smooth(f, x, eps, kern=eta, n=100, lo=-1.0, hi=1.0):  # (kern_eps * f)(x), split where f breaks
    cuts = [lo * eps] + sorted(x - k for k in range(-1, 13) if lo * eps < x - k < hi * eps) + [hi * eps]
    g = lambda s: kern(s / eps) / eps * f(x - s)
    return sum(gauss(g, a, b, n) for a, b in zip(cuts, cuts[1:]) if b > a)

def integrate(h, lo, hi, eps, n=100):     # integral of h over [lo, hi], split at k and k +- eps
    pts = sorted(set([lo, hi] + [p for k in range(-1, 12) for p in (k - eps, k, k + eps) if lo < p < hi]))
    return sum(gauss(h, a, b, n) for a, b in zip(pts, pts[1:]))

print(f"bump area Z                     {Z:.12f}")
print(f"m1, mean |u| under the bump     {m1:.12f}")
print(f"eta(0), the bump's peak         {eta(0.0):.12f}")

# Rehearsal on the list of 11 fixes: weights eta(k/eps) on whole seconds, rescaled to add to 1.
print(f"list, raw hill at 0 and 1 s, eps 2: {bump(0.0):.6f} {bump(0.5):.6f}; sum {bump(0.0) + 2 * bump(0.5):.6f}")
for eps in (2.0, 0.5):
    w = [eta(k / eps) for k in (-1, 0, 1)]; tot = sum(w); w = [v / tot for v in w]
    pad = [0.0] + Y + [0.0]
    sm = [w[0] * pad[i] + w[1] * pad[i + 1] + w[2] * pad[i + 2] for i in range(11)]
    print(f"list, eps {eps:.1f} s: weights {w[0]:.6f} {w[1]:.6f}; fix at 5 s {sm[5]:.6f}; total {sum(sm):.6f}")

# Road 1 against road 2: worst gap on the joined track, scanned against eps*m1*7/2.
print("eps (s)   sup gap joined  formula   L1 gap held  formula   sup gap held")
for eps in (0.5, 0.25, 0.125, 0.0625):
    grid = [(j - 100) / 100.0 for j in range(1201)]
    sup_j = max(abs(smooth(joined, x, eps) - joined(x)) for x in grid)
    l1_h = integrate(lambda x: abs(smooth(held, x, eps) - held(x)), -1.0, 11.0, eps)
    sup_h = max(abs(smooth(held, x, eps) - held(x)) for x in grid)
    f_sup, f_l1 = 3.5 * eps * m1, 28.0 * eps * m1
    print(f"{eps:<9.4f} {sup_j:.6f}        {f_sup:.6f}  {l1_h:.6f}     {f_l1:.6f}  {sup_h:.6f}")
    assert abs(sup_j - f_sup) < 1e-6          # scanned worst gap = eps * m1 * 7/2
    assert abs(l1_h - f_l1) < 1e-6            # integrated gap = eps * m1 * 28
    assert abs(sup_h - 2.0) < 1e-9          # half the 4 m jump survives in the sup norm

# Smoothness: slope of the smoothed track at the 5 s corner (3 m/s in, -4 m/s out).
eps = 0.25
slope_q = smooth(joined, 5.0, eps, kern=lambda u: deta(u) / eps)
slope_fd = (smooth(joined, 5.0 + 1e-4, eps) - smooth(joined, 5.0 - 1e-4, eps)) / 2e-4
print(f"slope at 5 s, eps 0.25: eta' * f {slope_q:.6f}; finite difference {slope_fd:.6f}")
assert abs(slope_q - (-0.5)) < 1e-6 and abs(slope_fd - (-0.5)) < 1e-6

# No shift: area and centre of the track are kept; a trailing bump moves the centre by eps.
for eps in (0.5, 1.0):
    a0 = integrate(joined, -2.0, 12.0, eps)
    c0 = integrate(lambda t: t * joined(t), -2.0, 12.0, eps) / a0
    a1 = integrate(lambda t: smooth(joined, t, eps), -2.0, 12.0, eps)
    c1 = integrate(lambda t: t * smooth(joined, t, eps), -2.0, 12.0, eps) / a1
    c2 = integrate(lambda t: t * smooth(joined, t, eps, kern=lambda u: eta(u - 1.0), lo=0.0, hi=2.0), -2.0, 12.0, eps) / a1
    print(f"eps {eps:.1f}: area {a0:.6f} -> {a1:.6f}; centre {c0:.6f} s -> {c1:.6f} s; trailing bump {c2:.6f} s")
    assert abs(a0 - sum(Y)) < 1e-9          # area of the joined track = sum of the fixes
    assert abs(a1 - a0) < 1e-7 and abs(c1 - c0) < 1e-7
    assert abs(c2 - c0 - eps) < 1e-6

# Never larger: the L2 size of the smoothed track against the track's own (Young, p = 2).
n2 = sum((Y[k] ** 2 + Y[k] * Y[k + 1] + Y[k + 1] ** 2) / 3.0 for k in range(10)) ** 0.5
for eps in (0.5, 1.0):
    s2 = integrate(lambda t: smooth(joined, t, eps) ** 2, -2.0, 12.0, eps) ** 0.5
    print(f"L2 size: track {n2:.6f}, smoothed eps {eps:.1f}: {s2:.6f}")
    assert s2 <= n2

# Wrong mass: the raw bump (area Z) shrinks the track and never recovers it.
raw = smooth(joined, 5.0, 0.0625, kern=bump)
print(f"raw bump at 5 s, eps 0.0625: {raw:.6f} (track 4.000000); gap {4.0 - raw:.6f}")
assert abs(raw - Z * (4.0 - 3.5 * 0.0625 * m1)) < 1e-6

# The infinite-dimensional catch: a wiggle sin(xi t), xi = 20/eps, is all but erased at every eps.
hat20 = gauss(lambda u: eta(u) * cos(20.0 * u), -1.0, 1.0, 4000)
for eps in (0.5, 0.0625):
    xi, x = 20.0 / eps, 0.3
    ratio = smooth(lambda t: sin(xi * t), x, eps, n=4000) / sin(xi * x)
    print(f"wiggle, eps {eps:.4f}: kept fraction {ratio:.6f}; eta-hat(20) {hat20:.6f}; gap {1.0 - hat20:.6f}")
    assert abs(ratio - hat20) < 1e-7

# The switch and the tap: H * eta_eps rises over 2 eps; its slope at 0 is eta_eps(0).
ramp_half = gauss(eta, -1.0, 0.5, 2000)
print(f"switch smoothed, at t = eps/2: {ramp_half:.6f}; at t = 0: {gauss(eta, -1.0, 0.0, 2000):.6f}")

# Chart points: the joined track and two smoothings, every half second.
ts = [0.5 * j for j in range(21)]
def tidy(v): return v if abs(v) >= 0.005 else 0.0   # print 0.00, never -0.00
print("chart, track    " + " ".join(f"{tidy(joined(t)):.2f}" for t in ts))
for eps in (1.0, 0.25):
    print(f"chart, eps {eps:.2f} " + " ".join(f"{tidy(smooth(joined, t, eps)):.2f}" for t in ts))
print("ALL CHECKS PASS")
