# Rouche's theorem -- the check behind the card.  Standard library only.
# Road one: the dog's turns, the argument of f(z) followed step by step round a circle.
# Road two: the roots themselves, by Durand-Kerner or de Moivre, counted by size.
# The inequality |g| < |f| on the circle predicts both; the asserts demand they agree.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def loop(R, n=2000): return [R * complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n + 1)]
def turns(h, R):                              # net turns of h(z) round 0 as z walks |z| = R once
    w = [h(z) for z in loop(R)]
    return sum(math.atan2((b / a).imag, (b / a).real) for a, b in zip(w, w[1:])) / (2 * math.pi)
def durand_kerner(h, n):                      # all n roots of a monic polynomial, found together
    zs = [complex(0.4, 0.9) ** k for k in range(n)]
    for _ in range(500):
        new = []
        for k, z in enumerate(zs):
            d = 1
            for j, w in enumerate(zs):
                if j != k: d *= z - w
            new.append(z - h(z) / d)
        zs = new
    return sorted(zs, key=lambda z: (round(z.real, 9), z.imag))
def cube_roots(c):                            # de Moivre: the three roots of z^3 = c, c > 0
    r = c ** (1 / 3)
    return [r * complex(math.cos(2 * math.pi * k / 3), math.sin(2 * math.pi * k / 3)) for k in range(3)]
def inside(zs, R): return sum(abs(z) < R - 1e-9 for z in zs)   # a root on the circle is not inside
def fx(x): return f"{round(x, 6) + 0.0:.6f}"

p = lambda z: z ** 5 + 3 * z + 1
c3 = cube_roots(1 / 8)
print(f"z^3 - 1/8 on |z| = 1: |f| = 1.000000, |g| = {1 / 8:.6f}; root sizes {', '.join(f'{abs(z):.6f}' for z in c3)}")
print(f"z^3 - 1/8: roots inside {inside(c3, 1)}; dog's turns {turns(lambda z: z ** 3 - 1 / 8, 1):.6f}; owner z^3 turns {turns(lambda z: z ** 3, 1):.6f}")
gap1 = min(abs(3 * z) - abs(z ** 5 + 1) for z in loop(1))
gap2 = min(abs(z ** 5) - abs(3 * z + 1) for z in loop(2))
print(f"quintic, |z| = 1: owner 3z, lead z^5 + 1 at most 2 < 3; least gap on the loop {gap1:.6f}")
print(f"quintic, |z| = 2: owner z^5, lead 3z + 1 at most 7 < 32; least gap on the loop {gap2:.6f}")
t1, t2 = turns(p, 1), turns(p, 2)
print(f"dog's turns: |z| = 1 {t1:.6f}, |z| = 2 {t2:.6f}; owner's turns {turns(lambda z: 3 * z, 1):.6f} and {turns(lambda z: z ** 5, 2):.6f}")
rs = durand_kerner(p, 5)
for k, z in enumerate(rs):
    print(f"root {k + 1}: {show(z)}, size {abs(z):.6f}")
n1, n2 = inside(rs, 1), inside(rs, 2)
print(f"roots in |z| < 1: {n1}; in |z| < 2: {n2}; between the circles: {n2 - n1}; least |p| on |z| = 1: {min(abs(p(z)) for z in loop(1)):.6f}")
print(f"two-line FTA: lower coefficients' sizes sum to 4, so at R = 5 the dog turns {turns(p, 5):.6f}")
e3 = cube_roots(1)
print(f"mistake, equality: z^3 - 1 has root sizes {', '.join(f'{abs(z):.6f}' for z in e3)}; inside {inside(e3, 1)}, not 3")
zero = durand_kerner(lambda z: z + 1 / 4, 1)                   # 1 + 1/(4z) = 0 exactly when z + 1/4 = 0
tp = turns(lambda z: 1 + 1 / (4 * z), 1)
print(f"mistake, a pole: 1 + 1/(4z) turns {fx(tp)}, yet its zero {show(zero[0])} is inside; 1 has none")
print(f"mistake, wrong owner on |z| = 1: |3z + 1| reaches {max(abs(3 * z + 1) for z in loop(1)):.6f} > 1 = |z^5|; true count {n1}, not 5")
print(f"silent test: z^5 + 3z + 3 has a lead reaching 4 > 3 on |z| = 1, yet {inside(durand_kerner(lambda z: z ** 5 + 3 * z + 3, 5), 1)} root inside, as before")
print("figure, 50 units per 1, 0 at (180, 120); roots at " + ", ".join(f"({180 + 50 * z.real:.2f}, {120 - 50 * z.imag:.2f})" for z in rs))
assert round(t1) == n1 == 1 and round(t2) == n2 == 5                  # dog's turns against counted roots
assert all(abs(p(z)) < 1e-12 for z in rs) and abs(t1 - n1) < 1e-9 and abs(t2 - n2) < 1e-9
assert inside(c3, 1) == round(turns(lambda z: z ** 3 - 1 / 8, 1)) == 3 and all(abs(z ** 3 - 1 / 8) < 1e-12 for z in c3)  # de Moivre against the dog
assert inside(e3, 1) == 0 and all(abs(z ** 3 - 1) < 1e-12 for z in e3) and inside(zero, 1) == 1 != round(tp)  # both breaks show
print("ALL CHECKS PASS")
