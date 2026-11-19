# Solvable by radicals -- the check behind the card.  Standard library only.
# It computes the Galois group of x^5 - x - 1 instead of quoting it: factor
# patterns mod 5 and mod 2 (Dedekind), the group those shuffles generate, and
# a count of patterns over every prime below 10,000 (Chebotarev: evidence).
import math
from collections import Counter
F, G = [-1, -1, 0, 0, 0, 1], [-2, 0, 0, 0, 0, 1]   # x^5 - x - 1 and x^5 - 2, low to high

def trim(a):
    while a and a[-1] == 0: a.pop()
    return a
def divmod_p(a, b, p):                    # long division of polynomials mod p
    a, q, inv = a[:], [0] * max(len(a) - len(b) + 1, 1), pow(b[-1], p - 2, p)
    while len(trim(a)) >= len(b):
        c, s = a[-1] * inv % p, len(a) - len(b)
        q[s] = c
        for i, bi in enumerate(b):
            a[s + i] = (a[s + i] - c * bi) % p
    return trim(q), a

def mul_p(a, b, p):
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] = (out[i + j] + x * y) % p
    return trim(out)

def gcd_p(a, b, p):
    while b: a, b = b, divmod_p(a, b, p)[1]
    return a

def pattern(f, p):                        # degrees of the factors of f mod p (no repeats)
    g, h, degs, k = trim([c % p for c in f]), [0, 1], [], 0
    while len(g) > 1:
        k += 1
        if len(g) - 1 < 2 * k:
            return tuple(sorted(degs + [len(g) - 1], reverse=True))
        e, base, h = p, divmod_p(h, g, p)[1], [1]
        while e:                          # h <- h^p mod g, square and multiply
            if e & 1:
                h = divmod_p(mul_p(h, base, p), g, p)[1]
            base, e = divmod_p(mul_p(base, base, p), g, p)[1], e >> 1
        d = gcd_p(g, trim([(c - (i == 1)) % p for i, c in enumerate(h + [0, 0])]), p)
        degs += [k] * ((len(d) - 1) // k)
        g = divmod_p(g, d, p)[0]
    return tuple(sorted(degs, reverse=True))

def compose(s, t):                        # do t, then s
    return tuple(s[i] for i in t)
def closure(gens):                        # every shuffle the generators make
    e = tuple(range(len(gens[0])))
    group, frontier = {e}, [e]
    while frontier:
        frontier = [y for y in {compose(g, x) for x in frontier for g in gens} if y not in group]
        group |= set(frontier)
    return group

def inverse(s):
    return tuple(sorted(range(len(s)), key=lambda i: s[i]))
def peel_sizes(group):                    # commutator subgroup, again and again
    sizes = [len(group)]
    while sizes[-1] > 1:
        group = closure(sorted({compose(compose(g, h), compose(inverse(g), inverse(h)))
                                for g in group for h in group}))
        sizes.append(len(group))
        if sizes[-1] == sizes[-2]:
            break
    return sizes

def cycle_type(s):
    seen, out = set(), []
    for i in range(len(s)):
        n, j = 0, i
        while j not in seen: seen.add(j); j = s[j]; n += 1
        if n: out.append(n)
    return tuple(sorted(out, reverse=True))

def roots(f):                             # Durand-Kerner: every complex root at once
    z = [(0.4 + 0.9j) ** k for k in range(len(f) - 1)]
    for _ in range(200):
        for i in range(len(z)):
            z[i] -= ev(f, z[i]) / math.prod(z[i] - z[j] for j in range(len(z)) if j != i)
    return z

ev = lambda f, x: sum(c * x ** i for i, c in enumerate(f))
ps = [p for p in range(2, 10000) if all(p % d for d in range(2, int(p ** 0.5) + 1))]
print(f"1. factor patterns of x^5 - x - 1\nmod 5: {pattern(F, 5)}; values at 0..4 mod 5: {[ev(F, a) % 5 for a in range(5)]}")
quad5 = [(b, c) for b in range(5) for c in range(5) if not divmod_p([c % 5 for c in F], [c, b, 1], 5)[1]]
print(f"monic quadratics mod 5 dividing it, by trying all 25: {len(quad5)}")
prod2 = mul_p([1, 1, 1], [1, 0, 1, 1], 2)
print(f"mod 2: {pattern(F, 2)}; (x^2+x+1)(x^3+x^2+1) mod 2 = {prod2}, f mod 2 = {[c % 2 for c in F]}")
disc = 5 ** 5 * F[0] ** 4 + 4 ** 4 * F[1] ** 5       # x^5 + a x + b: 5^5 b^4 + 4^4 a^5
z = roots(F)
disc_num = math.prod((z[i] - z[j]) ** 2 for i in range(5) for j in range(i + 1, 5))
facs = [p for p in ps if disc % p == 0]
print(f"discriminant: formula {disc}; from the five roots {disc_num.real:.3f}; prime factors {facs}")
print(f"square? {int(disc ** 0.5) ** 2 == disc}; real root {max(r.real for r in z if abs(r.imag) < 1e-9):.10f}")
c5, t23 = (1, 2, 3, 4, 0), (1, 0, 3, 4, 2)
swaps = [tuple(j if k == i else i if k == j else k for k in range(5)) for i in range(5) for j in range(i + 1, 5)]
sizes = [len(closure([c5, t])) for t in swaps]
print(f"2. the group the shuffles generate\na (3, 2) shuffle cubed has cycle type {cycle_type(compose(t23, compose(t23, t23)))}")
print(f"5-cycle with each of the 10 swaps generates: {sizes}")
groups = {"S3, cubic": [(1, 2, 0), (1, 0, 2)], "D4, x^4 - 2": [(1, 2, 3, 0), (0, 3, 2, 1)],
          "F20, x^5 - 2": [c5, (0, 2, 4, 1, 3)], "S5, x^5 - x - 1": [c5, swaps[0]]}
peels = {name: peel_sizes(closure(gens)) for name, gens in groups.items()}
for name in groups:
    print(f"peel sizes {name}: {peels[name]}")
print(f"sizes of D4, its turns, its half turn, the identity: {[len(closure(g)) for g in (groups['D4, x^4 - 2'], [(1, 2, 3, 0)], [(2, 3, 0, 1)], [(0, 1, 2, 3)])]}")
good = [p for p in ps if disc % p]
counts = Counter(pattern(F, p) for p in good)
shape = Counter(cycle_type(s) for s in closure(groups["S5, x^5 - x - 1"]))
n = len(good)
print(f"3. patterns at every prime below 10,000 (evidence, not proof)\nprimes used {n} ({' and '.join(map(str, facs))} skipped)")
for t in sorted(shape, key=lambda t: (-shape[t], t)):
    print(f"pattern {str(t):16} {counts[t]:4}  share {counts[t] / n:.3f}  S5 predicts {shape[t]:3}/120 = {shape[t] / 120:.3f}  {'#' * ((counts[t] + 6) // 12)}")
r19 = [a for a in range(19) if ev(F, a) % 19 == 0 and (5 * a ** 4 - 1) % 19 == 0]
q19, rem19 = divmod_p([c % 19 for c in F], mul_p([19 - r19[0], 1], [19 - r19[0], 1], 19), 19)
print(f"4. what breaks\nmod 19: (x - {r19[0]})^2 divides f, remainder {rem19}; cofactor pattern {pattern(q19, 19)}: two roots merge")
f20 = closure(groups["F20, x^5 - 2"])
odd20 = sum(1 for s in f20 if (5 - len(cycle_type(s))) % 2)
print(f"F20 also has odd shuffles: {odd20} of {len(f20)}, yet peels {peels['F20, x^5 - 2']}")
seen2, types20 = sorted({pattern(G, p) for p in ps if p not in (2, 5)}), sorted({cycle_type(s) for s in f20})
print(f"x^5 - 2 patterns seen: {seen2}; F20 cycle types: {types20}")
real4 = [r for r in roots([-2, 0, 0, 0, 1]) if abs(r.imag) < 1e-9]
print(f"Q(2^(1/4)): degree 4, roots of x^4 - 2 inside it {len(real4)}, so {len(real4)} automorphisms")
D = 1 / 4 - 1 / 27
cbrt = lambda x: abs(x) ** (1 / 3) * (1 if x >= 0 else -1)
u, v = cbrt(0.5 + D ** 0.5), cbrt(0.5 - D ** 0.5)
dk3 = max(r.real for r in roots([-1, -1, 0, 1]) if abs(r.imag) < 1e-9)
print(f"5. the cubic x^3 - x - 1 by Cardano\nq^2/4 + p^3/27 = 23/108 = {D:.10f}; u = {u:.10f}, v = {v:.10f}, u*v = {u * v:.10f}")
print(f"Cardano root {u + v:.10f}; Durand-Kerner root {dk3:.10f}; discriminant {-4 * (-1) ** 3 - 27 * (-1) ** 2}")
assert pattern(F, 5) == (5,) and quad5 == [] and all(ev(F, a) % 5 for a in range(5))
assert pattern(F, 2) == (3, 2) and prod2 == [c % 2 for c in F]
assert disc == 2869 == round(disc_num.real) and facs == [19, 151]
assert sizes == [120] * 10 and peels["S5, x^5 - x - 1"] == [120, 60, 60]
assert [peels[k][-1] for k in groups][:3] == [1, 1, 1] and rem19 == [] and len(real4) == 2
assert set(counts) == set(shape) and all(abs(counts[t] / n - shape[t] / 120)
                                         < 3 * (shape[t] / 120 * (1 - shape[t] / 120) / n) ** 0.5 for t in shape)
assert set(seen2) <= set(types20) and abs(u + v - dk3) < 1e-12 and abs(u * v - 1 / 3) < 1e-12
print("ALL CHECKS PASS")
