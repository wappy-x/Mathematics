# Paths with a budget -- the check behind the card.  Standard library only.
# A 6 m chain hangs from hooks 4 m apart at height 0; a 100 m fence encloses
# the most area it can.  Each answer is reached by two roads.
import math
D, L, FENCE = 2.0, 6.0, 100.0           # half-span (m), chain length (m), fence (m)

def bisect(f, lo, hi):                  # f(lo) > 0 > f(hi); halve 200 times
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) > 0 else (lo, mid)
    return (lo + hi) / 2

def simpson(f, lo, hi, m=2000):         # Simpson's rule on m panels
    h = (hi - lo) / m
    return h / 3 * sum(f(lo + i * h) * (1 if i in (0, m) else 4 if i % 2 else 2) for i in range(m + 1))

def catenary(length):                   # road 1: y = a cosh(x/a) + c from the multiplier rule
    a = bisect(lambda a: 2 * a * math.sinh(D / a) - length, 0.1, 1e4)
    return a, -a * math.cosh(D / a)     # c = lambda puts the hooks at height 0

def beads(n):                           # road 2: n massless strings, n - 1 equal beads
    s = L / n                           # force balance: slope of string k is (k - (n-1)/2) s / a
    slopes = lambda a: [(k - (n - 1) / 2) * s / a for k in range(n)]
    a = bisect(lambda a: 2 * D - sum(s / math.sqrt(1 + t * t) for t in slopes(a)), 0.01, 100.0)
    return a, sum(s * abs(t) / math.sqrt(1 + t * t) for t in slopes(a)[: n // 2])

def energy(length):                     # height summed along the chain, J[y]
    a, c = catenary(length)
    return simpson(lambda x: (a * math.cosh(x / a) + c) * math.cosh(x / a), -D, D)

def polygon(n, perim):                  # regular n-gon by the shoelace formula, rescaled to perim
    p = [(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n)]
    q = p[1:] + p[:1]
    side = sum(math.hypot(x2 - x1, y2 - y1) for (x1, y1), (x2, y2) in zip(p, q))
    return sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(p, q)) / 2 * (perim / side) ** 2

a, c = catenary(L)
sag = a * (math.cosh(D / a) - 1)
print(f"chain 6 m, hooks 4 m apart; road 1, multiplier rule: a = {a:.4f} m, c = lambda = {c:.4f} m, sag = {sag:.4f} m")
for n in (10, 100, 1000):
    an, sn = beads(n)
    print(f"road 2, {n:4d} beads: a = {an:.4f} m, sag = {sn:.4f} m, sag error {abs(sn - sag):.1e} m")
print(f"cosh(2/a) = {math.cosh(D / a):.4f}; tension as a length of chain: bottom {a:.4f} m, hooks {-c:.4f} m, hook vertical {a * math.sinh(D / a):.4f} m")
dE = (energy(L + 1e-3) - energy(L - 1e-3)) / 2e-3
print(f"price of chain: dE/dL = {dE:.4f} m against lambda = {c:.4f} m")
print("figure, " + " ".join(f"{180 + 60 * x:.0f},{40 - 60 * (a * math.cosh(x / a) + c):.1f}" for x in (-2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2)))
r = FENCE / (2 * math.pi)
print(f"fence: circle radius {r:.4f} m, area L^2/(4 pi) = {FENCE ** 2 / (4 * math.pi):.4f} m^2")
print("regular n-gons, n = 3 4 6 12 24 96: " + " ".join(f"{polygon(n, FENCE):.2f}" for n in (3, 4, 6, 12, 24, 96)))
big, dA = polygon(4096, FENCE), (polygon(4096, FENCE + 0.01) - polygon(4096, FENCE - 0.01)) / 0.02
print(f"4096-gon area {big:.4f} m^2; price of fence dA/dL = {dA:.4f} m against radius {r:.4f} m")
k = bisect(lambda k: L - simpson(lambda x: math.sqrt(1 + 4 * k * k * x * x), -D, D), 0.0, 5.0)
print(f"mistake 1, a parabola 6 m long: sag {4 * k:.4f} m; mistake 2, sag read as a cosh(2/a): {-c:.4f} m")
print("hypothesis dropped, no slack: " + ", ".join(f"chain {x} m gives a = {catenary(x)[0]:.1f} m" for x in (4.01, 4.001)))
print(f"mistake 3, a square fence: {polygon(4, FENCE):.2f} m^2, short by {FENCE ** 2 / (4 * math.pi) - polygon(4, FENCE):.2f} m^2")
assert abs(beads(1000)[1] - sag) < 1e-4                  # force balance agrees with the multiplier rule
assert abs(dE - c) < 1e-4                                # the multiplier is the price of chain
assert abs(big - FENCE ** 2 / (4 * math.pi)) < 0.01      # polygons close on the circle
assert abs(dA - r) < 1e-3                                # the fence's multiplier is the radius
print("ALL CHECKS PASS")
