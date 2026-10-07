# Liouville and the fundamental theorem of algebra -- the check behind the card.
# Standard library only.  Roots are found twice: by formula, and by Newton's
# method with peeling, which never uses a formula; the brackets are multiplied
# back.  Then Cauchy's estimate and the growth of |p| are measured directly.
import math
FOOT, QUART = [25, -20, 5], [1, 0, 0, 0, 1]        # coefficients, constant first
def ev(c, z):                                       # Horner: the polynomial at z
    out = 0
    for a in reversed(c): out = out * z + a
    return out
def peel(c):                                        # road two: Newton, then divide out
    c, roots = [complex(a) for a in c], []
    while len(c) > 1:
        dc, z = [k * c[k] for k in range(1, len(c))], complex(0.4, 0.9)
        for _ in range(100): z -= ev(c, z) / ev(dc, z)
        q = [c[-1]]                                 # synthetic division by (z - root)
        for a in reversed(c[1:-1]): q.append(a + z * q[-1])
        c, roots = list(reversed(q)), roots + [z]
    return roots
def expand(lead, roots):                            # road three: lead*(z - r1)(z - r2)...
    c = [complex(lead)]
    for r in roots: c = [(c[k - 1] if k else 0) - r * (c[k] if k < len(c) else 0) for k in range(len(c) + 1)]
    return c
def show(z): return f"{z.real:.6f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.6f}i"
def circle(r, n): return [complex(r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n)) for k in range(n)]
def cauchy_d(f, a, r, n):                           # f'(a) = (1/2 pi i) loop f(z)/(z - a)^2 dz
    return sum(f(a + w) / (w * w) * (1j * w) for w in circle(r, n)) * (2 * math.pi / n) / (2j * math.pi)
d = math.sqrt(4 * 5 * 25 - 20 ** 2)                 # the football, by the quadratic formula
formula = {"football": [complex(2, d / 10), complex(2, -d / 10)],
           "z^4 + 1": [complex(math.cos((2 * k + 1) * math.pi / 4), math.sin((2 * k + 1) * math.pi / 4)) for k in range(4)]}
gap, z1 = 0, formula["z^4 + 1"][0]
for (name, c), lead in zip([("football", FOOT), ("z^4 + 1", QUART)], [5, 1]):
    a, b = (sorted(s, key=lambda z: (-round(z.imag, 6), round(z.real, 6))) for s in (formula[name], peel(c)))
    back = max(abs(x - y) for x, y in zip(expand(lead, b), c))
    gap = max([gap, back] + [abs(x - y) for x, y in zip(a, b)])
    print(f"{name}, roots by formula: " + ", ".join(show(z) for z in a))
    print(f"{name}, roots by Newton and peeling: " + ", ".join(show(z) for z in b))
print(f"z^4 + 1 = (z^2 - {2 * z1.real:.6f}z + {abs(z1) ** 2:.6f})(z^2 + {2 * z1.real:.6f}z + {abs(z1) ** 2:.6f}); every gap between roads below 1e-12: {'yes' if gap < 1e-12 else 'no'}")
xs = [k / 100 for k in range(-300, 301)]
print(f"real line, x from -3 to 3: lowest x^4 + 1 = {min(x ** 4 + 1 for x in xs):.6f}, lowest 5x^2 - 20x + 25 = {min(ev(FOOT, x) for x in xs):.6f}")
ring = [min(abs(ev(QUART, z)) for z in circle(r / 4, 360)) for r in range(9)]
print(f"chart, lowest |z^4 + 1| on |z| = r, r = 0 to 2 by 0.25: " + ", ".join(f"{v:.2f}" for v in ring))
print(f"on |z| = 2: lowest |z^4 + 1| sampled {ring[8]:.6f}, bound |z|^4 - 1 = {2 ** 4 - 1:.6f}")
f = lambda z: 1 / ev(QUART, z)
exact = -4 / ev(QUART, 1) ** 2                      # (1/p)' = -p'/p^2, with p'(1) = 4
print(f"p(1) = {ev(QUART, 1)}, p'(1) = 4, so (1/p)'(1) = -p'(1)/p(1)^2 = {exact:.6f}")
est = [cauchy_d(f, 1, 0.25, n).real for n in (8, 16, 32)]
print(f"(1/p)'(1) by Cauchy's integral on radius 0.25, 8, 16, 32 points: " + ", ".join(f"{v:.9f}" for v in est))
bound = [max(abs(f(1 + w)) for w in circle(r, 3600)) / r for r in (0.25, 0.5, 0.75)]
print(f"Cauchy bound M(r)/r at a = 1, r = 0.25, 0.5, 0.75: " + ", ".join(f"{v:.6f}" for v in bound) + f"; nearest root {abs(1 - z1):.6f} away")
pts = [(130 + 50 * z.real, 120 - 50 * z.imag) for z in formula["z^4 + 1"] + formula["football"]]
print("figure, 50 units per 1, origin (130, 120): roots at " + " ".join(f"({x:.2f}, {y:.2f})" for x, y in pts))
print(f"mistake 1, real inputs only: 1/(x^4 + 1) is at most {1 / min(x ** 4 + 1 for x in xs):.6f}, but at 0.7 + 0.7i its size is {abs(f(complex(0.7, 0.7))):.6f}")
print(f"mistake 2, unbounded f(z) = z: M(r)/r at r = 1, 10, 100 is " + ", ".join(f"{max(abs(w) for w in circle(r, 360)) / r:.6f}" for r in (1, 10, 100)))
print(f"mistake 3, Cauchy's integral on radius 1 round a = 1, two roots inside: {cauchy_d(f, 1, 1, 4096).real:.6f}, not {exact:.6f}")
assert gap < 1e-12                                                    # formula = Newton = brackets
assert abs(est[2] - exact) < 1e-12 and abs(est[0] - exact) > 1e-6     # the loop recovers the slope
assert all(abs(v - abs((r / 4) ** 4 - 1)) < 1e-9 for r, v in enumerate(ring))
assert all(b >= abs(exact) for b in bound)                            # Cauchy's estimate holds
print("ALL CHECKS PASS")
