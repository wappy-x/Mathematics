# Distributions -- the check behind the card.  Standard library: math only.
# A hammer tap of impulse J = 0.5 N s (illustrative) is read through a smooth
# probe: a bump centred at c = 1 ms, half-width a = 5 ms, height 1 at its centre.
# Roads: the reading by quadrature against the limit J*phi(0); the derivative
# moved onto the probe against the direct reading; exact integer sums on a grid.
import math
J, C, A = 0.5, 0.001, 0.005                    # N s, s, s

def phi(t, c=C, a=A):                          # the probe: smooth, zero off (c-a, c+a)
    u = (t - c) / a
    return math.exp(1 - 1 / (1 - u * u)) if abs(u) < 1 else 0.0

def dphi(t, c=C, a=A):                         # its slope, by the chain rule
    u = (t - c) / a
    return phi(t, c, a) * (-2 * u / (a * (1 - u * u) ** 2)) if abs(u) < 1 else 0.0

def tap(t, w):                                 # half-cosine force, width w, area J
    return J * math.pi / (2 * w) * math.cos(math.pi * t / w) if abs(t) < w / 2 else 0.0

def mom(t, w):                                 # momentum delivered so far: its slope is tap
    if t <= -w / 2: return 0.0
    if t >= w / 2: return J
    return J * (1 + math.sin(math.pi * t / w)) / 2

def simpson(g, lo, hi, n=2000):                # Simpson's rule, n even, written out
    h, s = (hi - lo) / n, g(lo) + g(hi)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * g(lo + k * h)
    return s * h / 3

limit = J * phi(0.0)
print(f"probe: centre 1 ms, half-width 5 ms, u at the tap = {(0.0 - C) / A:.1f}, phi(0) = {phi(0.0):.6f}")
print(f"ideal tap reads J*phi(0) = {limit:.6f} N s")
gaps = []
for name, w in (("4 ms", 0.004), ("2 ms", 0.002), ("1 ms", 0.001), ("0.5 ms", 0.0005)):
    r = simpson(lambda t: tap(t, w) * phi(t), -w / 2, w / 2)
    gaps.append(limit - r)
    print(f"width {name:>6}: peak force {tap(0.0, w):7.2f} N, reading {r:.6f} N s, "
          f"gap {limit - r:.7f}, log10 gap {math.log10(limit - r):.3f}")
ratios = [gaps[i] / gaps[i + 1] for i in range(3)]
print("gap ratio per halving of the width: " + ", ".join(f"{q:.3f}" for q in ratios))

w = 0.001                                      # the 1 ms tap, read two ways
direct = simpson(lambda t: tap(t, w) * phi(t), -w / 2, w / 2)
moved = -(simpson(lambda t: mom(t, w) * dphi(t), -w / 2, w / 2)
          + simpson(lambda t: J * dphi(t), w / 2, C + A))
step = -simpson(lambda t: J * dphi(t), 0.0, C + A)
print(f"1 ms tap read directly, integral of f*phi: {direct:.9f} N s")
print(f"its momentum p, derivative moved onto the probe, -integral of p*phi': {moved:.9f} N s")
print(f"ideal step of height J, -integral of J*phi' from 0: {step:.9f} N s")
print(f"bound: reading {direct:.6f} <= (integral of |f|) x (largest phi) = {J:.6f}")
far = simpson(lambda t: tap(t, w) * phi(t, 0.010), -w / 2, w / 2)
print(f"probe moved to centre 10 ms, clear of the tap: reading {far:.6f} N s")

grid = []
for n in (10, 100, 1000):                      # grid rehearsal: step h = a/n
    h, fwd, back = A / n, 0.0, 0.0
    for k in range(-n - 2, 2 * n + 2):         # covers the probe's support
        p0, p1 = (J if k >= 0 else 0.0), (J if k + 1 >= 0 else 0.0)
        fwd += (p1 - p0) * phi(k * h)
        back -= p0 * (phi(k * h) - phi((k - 1) * h))
    grid.append((h, fwd, back))
    print(f"grid n = {n:4d}, h = {5000 // n:3d} us: difference reading {fwd:.9f}, "
          f"moved onto probe {back:.9f}, gap {limit - fwd:.7f}")
pv = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8]      # any 12 samples
qv = [0, 1, 3, 6, 8, 9, 8, 6, 3, 1, 0, 0]      # an integer probe, zero at both ends
left = sum((pv[k + 1] - pv[k]) * qv[k] for k in range(11))
right = -sum(pv[k] * (qv[k] - qv[k - 1]) for k in range(1, 12))
print(f"12 integer samples: sum of differences x probe = {left}; "
      f"minus sum of samples x probe differences = {right}")

for name, eps in (("1 ms", 0.001), ("0.1 ms", 0.0001), ("0.01 ms", 0.00001)):
    lo, hi = max(-eps, -w / 2), min(eps, w / 2)     # shrink the probe, keep phi(0) = 1
    r = simpson(lambda t: tap(t, w) * phi(t, 0.0, eps), lo, hi)
    print(f"probe half-width {name:>7}: value at 0 is {phi(0.0, 0.0, eps):.3f}, 1 ms tap reads {r:.6f} N s")

print(f"mistake 1, minus sign dropped: {-step:.6f} N s, not {limit:.6f}")
ramp = lambda t: (t - C + A) / (2 * A)         # smooth, but 1 at the window's end
rd = simpson(lambda t: tap(t, w) * ramp(t), -w / 2, w / 2)
rm = -(simpson(lambda t: mom(t, w) / (2 * A), -w / 2, w / 2) + J * (C + A - w / 2) / (2 * A))
print(f"mistake 2, ramp probe, 1 at the window's end: direct {rd:.6f}, moved {rm:.6f}, gap {rd - rm:.6f} N s")
edge = C + A                                   # a box probe: 1 up to 6 ms, then 0
box = [mom(edge - t0, 0.0001) for t0 in (edge - 0.0001, edge, edge + 0.0001)]
print("mistake 3, box probe, 0.1 ms tap at 5.9, 6.0, 6.1 ms: " + ", ".join(f"{b:.6f}" for b in box))
print(f"mistake 4, force at t = 0 of the 0.5 ms tap: {tap(0.0, 0.0005):.2f} N, doubling as the width halves")
ts = [k * 0.5 for k in range(-10, 15)]
print("figure, t ms: " + " ".join(f"{t:g}" for t in ts))
print("figure, probe: " + " ".join(f"{phi(t / 1000):.2f}" for t in ts))
print("figure, 4 ms tap / peak: " + " ".join(f"{tap(t / 1000, 0.004) / tap(0.0, 0.004):.2f}" for t in ts))

assert all(3.9 < q < 4.2 for q in ratios)                  # gap falls as width squared
assert abs(direct - moved) < 1e-9 and abs(step - limit) < 1e-9   # moved derivative = reading
assert all(abs(f - J * phi(-h)) < 1e-12 and abs(f - b) < 1e-12 for h, f, b in grid)
assert left == right                                       # summation by parts, exact
assert abs(rd - rm - J * ramp(C + A)) < 1e-9               # the boundary term J*psi(end)
assert far == 0.0 and box == [0.5, 0.25, 0.0]
print("ALL CHECKS PASS")
