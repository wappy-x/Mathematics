# Uniform continuity and Lipschitz -- the check behind the card.  Only
# math.sqrt is imported.  Example: a square tile of side x metres, area x*x,
# sides from 0 to 2 m, area tolerance 0.01 m^2.  Each tolerance is found twice:
# by a formula, and by bisection over sample points, which takes no roots.
from math import sqrt
EPS, B = 0.01, 2.0

def bisect(ok, lo=0.0, hi=1.0):           # largest d with ok(d) true
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if ok(mid) else (lo, mid)
    return lo

def uniform_ok(d):                         # every sampled pair d apart in [0, 2]
    xs = [i * (B - d) / 2000 for i in range(2001)]
    return max((x + d) * (x + d) - x * x for x in xs) <= EPS

def point_ok(c):                           # every sample within d of the side c
    return lambda d: max(abs((c + d * k / 100) ** 2 - c * c) for k in range(-100, 101)) <= EPS

K = 2 * B                                  # factoring: x*x - y*y = (x - y)(x + y), x + y <= 4
g = [i / 1000 for i in range(2001)]
steep = max((y * y - x * x) / (y - x) for i, x in enumerate(g) for y in g[i + 1:])
lip = EPS / K
exact, bis = B - sqrt(B * B - EPS), bisect(uniform_ok)
d5 = sqrt(0.25 + EPS) - 0.5
print(f"K by factoring on [0,2]: {K:.6f}; steepest sampled chord: {steep:.6f}")
print(f"Lipschitz tolerance, m: {lip:.8f}")
print(f"worst pair 1.9975 and 2, area gap: {B * B - (B - lip) ** 2:.8f}")
print(f"best uniform tolerance, m: formula {exact:.8f}, bisection {bis:.8f}")
print(f"best at side 0.5 alone, m: {d5:.8f}; used at side 2, area gap {B * B - (B - d5) ** 2:.8f}")
print(f"best at side 100 alone, m: {sqrt(10000 + EPS) - 100:.8f}")
for d in (0.1, 0.01, 0.0025, 0.001):
    x = 1 / d; y = x + d / 2
    assert abs((y * y - x * x) - (1 + d * d / 4)) < 1e-6    # direct gap against the algebra
    print(f"whole line, tolerance {d}: sides {x:.2f} and {y:.5f}, area gap {y * y - x * x:.8f}")
print(f"open end, 1/x at 0.01 and {1 / 101:.8f}: input gap {0.01 - 1 / 101:.8f}, output gap {1 / (1 / 101) - 1 / 0.01:.6f}")
t = 1 / (K + 1)
print(f"square root, K = 4 beaten by 0 and {t * t:.2f}: ratio {sqrt(t * t) / (t * t):.6f}")
print(f"square root, inputs 0.01 apart, largest output gap {max(sqrt(i / 1000 + 0.01) - sqrt(i / 1000) for i in range(991)):.6f}")
step = lambda x: 1 if x >= 1 else 0            # a switch that jumps at side 1
print(f"jump at 1: inputs 0.9999 and 1, output gap {step(1.0) - step(0.9999)}")
cs = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 10]
pts = [bisect(point_ok(c)) for c in cs]
for c, p in zip(cs, pts):
    assert abs(p - (sqrt(c * c + EPS) - c)) < 1e-9          # bisection against the closed form
assert 0 <= K - steep < 0.0011                                # sampled chords against factoring
assert abs(bis - exact) < 1e-9                                # bisection against the formula
print(f"try, sides up to 3 m: K {2 * 3.0:.6f}, tolerance {EPS / (2 * 3.0):.8f}; area tolerance 0.001 on [0,2]: {0.001 / K:.8f}")
print("figure, side m:", " ".join(f"{c:.2f}" for c in cs))
print("figure, best tolerance mm:", " ".join(f"{1000 * p:.2f}" for p in pts))
print("all four checks passed")
