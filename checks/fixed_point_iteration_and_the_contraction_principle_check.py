# Fixed points and the contraction rule -- the check behind the card.  Standard
# library only; math.cos, sin and acos are primitives.  The answer to cos x = x
# is reached twice: by pressing cos again and again, and by halving a bracket.
from math import cos, sin, acos, pi

xs = [0.0]                                   # road one: press cos 100 times from 0
for _ in range(100):
    xs.append(cos(xs[-1]))
lo, hi = 0.0, 1.0                            # road two: x - cos x changes sign on [0, 1]
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if mid - cos(mid) < 0 else (lo, mid)
p = (lo + hi) / 2
q = sin(1.0)                                 # the mean value theorem's bound for |cos'| on [0, 1]
grid = [k / 200 for k in range(201)]
chord = max(abs(cos(a) - cos(b)) / (b - a) for a in grid for b in grid if b > a)
k = q / (1 - q)
prior = lambda n: q ** n / (1 - q) * abs(xs[1] - xs[0])
post = lambda n: k * abs(xs[n] - xs[n - 1])
print(f"pressing cos 100 times: {xs[100]:.10f}; halving 60 times: {p:.10f}")
print(f"q = sin 1 = {q:.6f}; widest sampled chord slope {chord:.6f}; q/(1-q) = {k:.6f}")
deg = 0.0                                    # the same key in degree mode
for _ in range(50):
    deg = cos(deg * pi / 180)
print(f"cos sends [0, 1] into [{min(cos(t) for t in grid):.6f}, {max(cos(t) for t in grid):.6f}]; degree mode settles at {deg:.10f}")
print("n, x_n, true error, last-step bound, first-step bound")
for n in (1, 2, 3, 4, 5, 10, 20):
    print(f"{n}, {xs[n]:.6f}, {abs(xs[n] - p):.6f}, {post(n):.6f}, {prior(n):.6f}")
first = lambda ok: next(n for n in range(1, 61) if ok(n))
print(f"within 0.001 promised by first-step bound at n = {first(lambda n: prior(n) <= 1e-3)}, "
      f"by last-step bound at n = {first(lambda n: post(n) <= 1e-3)}, true at n = {first(lambda n: abs(xs[n] - p) <= 1e-3)}")
h = 1e-5                                     # the card's own difference quotient for cos' at p
slope = (cos(p + h) - cos(p - h)) / (2 * h)
ratio = abs(xs[31] - p) / abs(xs[30] - p)
print(f"error ratio at n = 30: {ratio:.6f}; |slope of cos at p| by difference quotient: {abs(slope):.6f}")
y = [0.75]                                   # break 1: the same equation as x = arccos x
for _ in range(8):
    y.append(acos(y[-1]))
print("arccos from 0.75, errors: " + ", ".join(f"{abs(t - p):.4f}" for t in y))
z = 1.0                                      # break 2: halving on (0, 1], which lacks 0
for _ in range(20):
    z /= 2
print(f"halving on (0, 1], x_20 = {z:.8f}, heading for 0, outside the set")
w = 1.0                                      # break 3: x + 1/x on [1, infinity)
for _ in range(1000):
    w += 1 / w
s = lambda t: t + 1 / t
print(f"x + 1/x: chord slope on [100, 101] = {s(101) - s(100):.6f}; x_1000 from 1 = {w:.4f}")
pts = [(0.0, 0.0)] + [c for j in range(4) for c in ((xs[j], xs[j + 1]), (xs[j + 1], xs[j + 1]))]
print("figure, cobweb px: " + " ".join(f"{60 + 200 * a:.1f},{220 - 200 * b:.1f}" for a, b in pts))
print("figure, cos curve px: " + " ".join(f"{60 + 20 * i:.0f},{220 - 200 * cos(i / 10):.1f}" for i in range(11)))
print(f"figure, fixed point px: {60 + 200 * p:.1f},{220 - 200 * p:.1f}")
assert abs(xs[100] - p) < 1e-12                                  # two roads, one answer
assert all(abs(xs[n] - p) <= post(n) <= prior(n) for n in range(1, 41))
assert chord <= q                                               # q really bounds every sampled chord
assert abs(ratio - abs(slope)) < 1e-4                           # errors shrink at the slope at p
print("ALL CHECKS PASS")
