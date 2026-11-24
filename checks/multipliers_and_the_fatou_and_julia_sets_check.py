# Multipliers and the Fatou and Julia sets -- the check behind the card.  Standard library only.
# f(z) = z^2 + c, mostly c = -1.  Multipliers by the chain rule against Cauchy's formula on a small
# circle; gaps followed step by step; every cycle up to period 4 found by Durand-Kerner root-finding.
import cmath, math

def f(z, c=-1): return z * z + c
def cl(x): return round(x, 12) + 0.0             # clears float dust and the sign of -0.0
def it(z, n, c=-1):                               # f applied n times
    for _ in range(n): z = f(z, c)
    return z
def chain(z, k, c=-1):                            # multiplier of f^k at z: product of f' = 2z along the orbit
    m = 1
    for _ in range(k): m, z = m * 2 * z, f(z, c)
    return m + 0.0
def cauchy(p, k, r=1e-3, m=64):                   # road two: average of (f^k(p + w) - p)/w round |w| = r
    ws = [r * cmath.exp(2j * math.pi * j / m) for j in range(m)]
    return cl(sum((it(p + w, k) - p) / w for w in ws).real / m)
def escape(z, c=-1):                              # steps until |z| > 2, or -1 if 500 steps never leave
    for n in range(500):
        if abs(z) > 2: return n
        z = f(z, c)
    return -1
def periodic(n, c=-1):                            # all 2^n roots of f^n(z) - z, by Durand-Kerner
    r = [(0.4 + 0.9j) ** k for k in range(2 ** n)]
    for _ in range(500):
        r = [a - (it(a, n, c) - a) / math.prod(a - b for j, b in enumerate(r) if j != i) for i, a in enumerate(r)]
    return r
s = lambda v, d=6: ", ".join(f"{x:.{d}f}" for x in v)
p, q = (1 + math.sqrt(5)) / 2, (1 - math.sqrt(5)) / 2
print(f"orbit of 0: {s([it(0, n) for n in range(5)], 0)}; orbit of 2: {s([it(2, n) for n in range(5)], 0)}")
print(f"fixed points (1 +/- sqrt 5)/2: {s([p, q])}; multipliers 2p: {s([chain(p, 1), chain(q, 1)])}")
print(f"the same by Cauchy's formula on |w| = 0.001: {s([cauchy(p, 1), cauchy(q, 1)])}")
print(f"2-cycle 0, -1: multiplier f'(0) f'(-1) = 0 x -2 = {chain(0, 2):.6f}; by Cauchy's formula: {cauchy(0, 2):.6f}")
print(f"gap from 1.618034 + 0.001, steps 1 to 5: {s([it(p + 1e-3, n) - p for n in range(1, 6)])}")
print(f"gap from -0.618034 + 0.001, steps 1 to 5: {s([it(q + 1e-3, n) - q for n in range(1, 6)])}")
print(f"from 0.1, two steps at a time: {s([it(0.1, n) for n in (2, 4, 6)], 7)}")
near = abs(it(p - 1e-3, 100)) < 1e-12 or abs(it(p - 1e-3, 101)) < 1e-12
print(f"1.618034 + 0.001 leaves |z| <= 2 after {escape(p + 1e-3)} steps; 1.618034 - 0.001 ends on the cycle: {'yes' if near else 'no'}")
print(f"slope of f^n at 1.618034, n = 5, 10, 20: {s([chain(p, n) for n in (5, 10, 20)], 1)}")
roots = [periodic(n) for n in (1, 2, 3, 4)]
att = [[z for z in r if abs(chain(z, n + 1)) < 1] for n, r in enumerate(roots)]
print(f"roots of f^n(z) - z, n = 1 to 4: {[len(r) for r in roots]}; with |multiplier| < 1: {[len(a) for a in att]}")
print(f"those points, n = 2 and 4: {s(sorted(cl(z.real) for z in att[1] + att[3]))}")
pc = (1 - math.sqrt(1 - 4 * 0.2)) / 2
print(f"c = 0.2: fixed point {pc:.6f}, multiplier {chain(pc, 1, 0.2):.6f}; orbit of 0 at step 100: {it(0, 100, 0.2):.6f}")
print(f"c = 0.2: Cauchy cap 2/0.1 = {2 / 0.1:.1f}; 1/|multiplier|^n, n = 5, 6: {s([1 / chain(pc, n, 0.2) for n in (5, 6)], 1)}")
print(f"mistake 1: one point's slope f'(-1) = {chain(-1, 1):.1f} reads repelling; the product is {chain(-1, 2):.1f}")
print(f"mistake 2: iterating the 6-digit value 1.618034 leaves |z| <= 2 after {escape(1.618034)} steps")
print(f"mistake 3: c = -0.75, fixed point -0.5, multiplier {chain(-0.5, 1, -0.75):.1f}: gap 0.1 after 1000 steps "
      f"{abs(it(-0.4, 1000, -0.75) + 0.5):.6f}")
assert all(abs(chain(z, 1) - cauchy(z, 1)) < 1e-9 for z in (p, q)) and abs(cauchy(0, 2)) < 1e-9
assert [len(a) for a in att] == [0, 2, 0, 2] and all(abs(it(z, 4) - z) < 1e-9 for z in roots[3])
assert escape(p + 1e-3) == 6 and near and escape(1.618034) == 15 and escape(2) == 1
assert abs(it(0, 100, 0.2) - pc) < 1e-12 and abs(chain(pc, 1, 0.2) - (1 - math.sqrt(0.2))) < 1e-12
print("ALL CHECKS PASS")
