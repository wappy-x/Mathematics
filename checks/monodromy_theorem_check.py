# Monodromy theorem -- the check behind the card.  Standard library only.
# Continue sqrt z from sqrt 1 = 1 along paths in the plane without 0.  Road one
# walks a chain of discs: each disc's series is w (1 + u)^(1/2), u = z/c - 1.
# Road two is Newton's method started from the last value.  Road three is the
# closed form e^(i theta / 2).  The log is walked the same way.
import math

def series(u, a):                      # a = 0.5: (1 + u)^(1/2); a = 0: log(1 + u)
    total, term = 0j, (1 + 0j if a else u)
    for k in range(1, 400):
        total += term
        term *= (a - k + 1) / k * u if a else -u * k / (k + 1)
    return total

def ellipse(b, theta_end, n):          # cos t + i b sin t, t from 0 to theta_end
    return [complex(math.cos(theta_end * k / n), b * math.sin(theta_end * k / n)) for k in range(n + 1)]

def walk(path):                        # sqrt by discs, sqrt by Newton, log by discs
    w, v, L, ratio = 1 + 0j, 1 + 0j, 0j, 0.0
    for c, z in zip(path, path[1:]):   # the disc at c has radius |c|, the distance to 0
        ratio = max(ratio, abs(z - c) / abs(c))
        w, L = w * series(z / c - 1, 0.5), L + series(z / c - 1, 0)
        for _ in range(30):
            v = (v + z / v) / 2
    return w, v, L, ratio

def show(w):                           # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

hand = walk(ellipse(1, math.pi, 4))
print(f"4 discs, upper half: step ratio {hand[3]:.6f}, ends at {show(hand[0])}")
print("  values at the centres: " + ", ".join(show(walk(ellipse(1, math.pi, 4)[:k + 2])[0]) for k in range(3)))
runs = {}
for name, theta in [("upper half", math.pi), ("lower half", -math.pi), ("once round", 2 * math.pi), ("twice round", 4 * math.pi)]:
    w, v, L, ratio = runs[name] = walk(ellipse(1, theta, 64 * round(abs(theta) / math.pi)))
    closed = complex(math.cos(theta / 2), math.sin(theta / 2))
    print(f"{name}: discs {show(w)}, Newton {show(v)}, e^(i theta/2) {show(closed)}, log {show(L)}")
    assert abs(w - closed) < 1e-9 and abs(v - closed) < 1e-9 and abs(L - 1j * theta) < 1e-9
for b in (1, 0.5, 0.1, -0.1, -0.5, -1):
    path = ellipse(b, math.pi, 256)
    w, v, L, ratio = walk(path)
    print(f"slide t = {(1 - b) / 2:.2f}, height b = {b:+.1f}: ends at {show(w)}, "
          f"closest to 0 {min(abs(z) for z in path):.6f}, worst step ratio {ratio:.6f}")
    assert abs(w - (1j if b > 0 else -1j)) < 1e-9 and ratio < 0.5
print(f"slide t = 0.50, height b = +0.0: passes through 0, closest {min(abs(z) for z in ellipse(0, math.pi, 256)):.6f}, no disc")
cut = [1 + 0j, -3 + 0.5j, -3 + 3j, 4j]          # a wandering path that never crosses the cut
path = [p + (q - p) * k / 64 for p, q in zip(cut, cut[1:]) for k in range(64)] + [4j]
principal = math.sqrt(4) * complex(math.cos(math.atan2(4, 0) / 2), math.sin(math.atan2(4, 0) / 2))
print(f"cut plane, 1 to 4i via -3 + 0.5i and -3 + 3i: {show(walk(path)[0])}; principal sqrt(4i) {show(principal)}")
assert abs(walk(path)[0] - principal) < 1e-9
lower_end = runs["lower half"][0]
print(f"mistake, principal sqrt(-1) at the end of the lower path: {show(1j)}, not {show(lower_end)}")
print(f"mistake, a loop taken to return 1: once round gives {show(runs['once round'][0])}; log gains 2 pi i = {show(2j * math.pi)}")
print("figure, unit circle centre (180,130) r 100; start (280,130); end (80,130); tops "
      + " ".join(f"(180,{130 - 100 * b:.0f})" for b in (1, 0.5, 0.1, -0.1, -0.5, -1)))
print("ALL CHECKS PASS")
