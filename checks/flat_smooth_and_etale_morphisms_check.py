# Flat, smooth and etale -- the check behind the card.  Standard library only.
# A polynomial is a dict {exponent tuple: integer}.  Ranks are exact: integer
# row reduction, each new row divided by its gcd.  Roads: the Hilbert function by
# rank, by standard monomials and by formula; Tor_1 by rank; etale points by the
# Jacobian against brute-force root counts; Hensel lifting against enumeration.
from math import gcd

def rank(rows):
    m, rk = [list(r) for r in rows], 0
    for col in range(len(m[0]) if m else 0):
        piv = next((i for i in range(rk, len(m)) if m[i][col]), None)
        if piv is None: continue
        m[rk], m[piv] = m[piv], m[rk]
        for i in range(rk + 1, len(m)):
            row = [m[rk][col] * m[i][j] - m[i][col] * m[rk][j] for j in range(len(m[i]))]
            g = 0
            for v in row: g = gcd(g, v)
            m[i] = [v // g for v in row] if g else row
        rk += 1
    return rk

def monos(k, n, upto=False):                  # exponent tuples in k variables
    if k == 1: return [(d,) for d in range(n + 1)] if upto else [(n,)]
    return [(a,) + r for a in range(n + 1) for r in monos(k - 1, n - a, upto)]

def times(g, m):                              # the polynomial g times the monomial m
    return {tuple(a + b for a, b in zip(e, m)): c for e, c in g.items()}

def mult_rows(gs, src, dst):                  # one row per source monomial: its images
    pos = {e: i for i, e in enumerate(dst)}
    out = []
    for m in src:
        row = [0] * (len(dst) * len(gs))
        for block, g in enumerate(gs):
            for e, c in times(g, m).items(): row[block * len(dst) + pos[e]] += c
        out.append(row)
    return out

def hf(g, k, n, deg):                         # Hilbert function of k[vars]/(g) in degree n
    if n < deg: return len(monos(k, n))
    return len(monos(k, n)) - rank(mult_rows([g], monos(k, n - deg), monos(k, n)))

print("1. the family xy = t z^2 in P^2 over the t-line; field Q; HF for n = 0..6")
fam = {}
for t in (1, -1, 5, 0):
    fam[t] = [hf({(1, 1, 0): 1, (0, 0, 2): -t}, 3, n, 2) for n in range(7)]
    print(f"   t = {t:2d}: by rank {fam[t]}")
std = [sum(1 for e in monos(3, n) if not (e[0] and e[1])) for n in range(7)]
print(f"   standard monomials, not divisible by xy: {std}; formula 2n + 1: {[2 * n + 1 for n in range(7)]}")
N = 4
V, V2 = monos(2, N, True), monos(2, N + 2, True)
for c in (0, 1, -1):
    r = rank(mult_rows([{(1, 1): 1, (0, 0): -c}], V, V2))
    print(f"   Tor_1 over Q[t] at t = {c:2d}: times (xy - c) on {len(V)} monomials, rank {r}, kernel {len(V) - r}")
    assert r == len(V)                        # no function killed by xy - c
print("2. blowing up the plane at the origin, chart y = x t: B = Q[x, t], y -> x t")
d2 = rank(mult_rows([{(1, 0): 1}], V, monos(2, N + 3, True)) + mult_rows([{(1, 1): 1}], V, monos(2, N + 3, True)))
d1 = rank(mult_rows([{(1, 1): -1}, {(1, 0): 1}], monos(2, N - 2, True), V))
ker = 2 * len(V) - d2
print(f"   Koszul on (x, x t), degree <= {N}: kernel {ker}, boundaries {d1}, Tor_1 piece {ker - d1}")
wit = {e: -c for e, c in times({(1, 0): 1}, (0, 1)).items()}           # x times b1 = -t
for e, c in times({(1, 1): 1}, (0, 0)).items(): wit[e] = wit.get(e, 0) + c  # plus (x t) times b2 = 1
print(f"   witness (-t, 1): x(-t) + (x t)(1) = {'0' if not any(wit.values()) else 'not 0'}; second entry 1 is not a multiple of x")
fib = {(a, b): [hf({(1, 0): -b, (0, 1): a}, 2, n, 1) for n in range(5)] for a, b in ((1, 0), (2, 3), (0, 0))}
for ab, h in fib.items(): print(f"   fibre over {ab}: HF {h}")
p = 7
P1 = [(1, v) for v in range(p)] + [(0, 1)]
sizes = [sum(1 for u, v in P1 if (a * v - b * u) % p == 0) for a in range(p) for b in range(p)]
print(f"   over F_7: fibres of size 1: {sizes.count(1)}, of size 8: {sizes.count(8)}, total {sum(sizes)}")
print("3. relative Jacobian of xy - t over the t-line, over F_7")
bad = [(x, y) for x in range(p) for y in range(p) if rank([[y % p, x % p]]) == 0]
om = sorted({2 - rank([[y % p, x % p]]) for x in range(p) for y in range(p)})
print(f"   points with (y, x) = (0, 0): {len(bad)} of {p * p}, at {bad[0]} in the fibre t = 0; Omega ranks met {om}")
tot = sum(1 for x in range(p) for y in range(p) if rank([[y, x, -1 % p]]) == 0)
print(f"   total space, Jacobian (y, x, -1): singular points {tot}")
print("4. x -> u = x^2: B = A[x]/(x^2 - u), basis 1, x; Omega = B/(2x)")
roots7 = [sum(1 for x in range(p) if (x * x - c) % p == 0) for c in range(p)]
f49 = [(a, b) for a in range(p) for b in range(p)]                     # a + b i with i^2 = -1
sq = lambda z: ((z[0] * z[0] - z[1] * z[1]) % p, 2 * z[0] * z[1] % p)
roots49 = [sum(1 for z in f49 if sq(z) == (c, 0)) for c in range(p)]
mult49 = [sum(1 + (2 * z[0] % p == 2 * z[1] % p == 0) for z in f49 if sq(z) == (c, 0)) for c in range(p)]  # 2x = 0: double
print(f"   roots of x^2 = c, c = 0..6: in F_7 {roots7}; in F_49 {roots49}; with multiplicity {mult49}")
et7 = sum(1 for x in range(p) if 2 * x % p)
print(f"   etale points of X(F_7), where 2x != 0: {et7} of {p}; only x = 0 fails")
r2 = [[x for x in range(2) if (x * x - c) % 2 == 0] for c in range(2)]
et2 = sum(1 for x in range(2) if 2 * x % 2)
print(f"   over F_2: roots per c {r2}, one each, but 2x = 0: etale points {et2} of 2")
print("5. Spec Z[i] -> Spec Z: Z[i] = Z[x]/(x^2 + 1), Jacobian 2x, discriminant -4")
for q in (2, 3, 5, 13, 29):
    rs = [x for x in range(q) if (x * x + 1) % q == 0]
    print(f"   p = {q:2d}: roots of x^2 + 1 {rs}; 2x = 0 at a root: {'yes' if any(2 * x % q == 0 for x in rs) else 'no'}")
primes = [q for q in range(2, 1000) if all(q % d for d in range(2, int(q ** 0.5) + 1))]
ram = [q for q in primes if any((x * x + 1) % q == 0 and 2 * x % q == 0 for x in range(q))]
print(f"   of {len(primes)} primes below 1000, not etale above: {ram}; dividing -4: {[q for q in primes if 4 % q == 0]}")
m2i = [((a * 0 - b * 2), (a * 2 + b * 0)) for a, b in ((1, 0), (0, 1))]   # 2i times 1 and times i
print(f"   Omega = Z[i]/(2i): 2i sends 1, i to {m2i}; Omega has {m2i[0][0] * m2i[1][1] - m2i[0][1] * m2i[1][0]} elements, the determinant")
x, lifts = 2, [2]
for k in range(2, 7):
    m = 5 ** k
    x = (x - (x * x + 1) * pow(2 * x, -1, m)) % m
    lifts.append(x)
brute5 = [sum(1 for y in range(5 ** k) if (y * y + 1) % 5 ** k == 0) for k in range(1, 5)]
brute2 = [sum(1 for y in range(2 ** k) if (y * y + 1) % 2 ** k == 0) for k in range(1, 5)]
print(f"   Hensel, x^2 = -1 mod 5^k, k = 1..6: {lifts}; solutions k = 1..4 by search {brute5}")
print(f"   mod 2^k, k = 1..4: solutions {brute2}; 2x is never a unit mod 2")
print("6. y^2 = x^3 - x -> x-line: not etale where 2y = 0")
hinf = lambda w, Y: Y * Y - (w - w ** 3)          # chart w = 1/x, Y = y w^2: Y^2 = w - w^3
nes = []
for q in (7, 11, 13):
    pts = [(a, b) for a in range(q) for b in range(q) if (b * b - a ** 3 + a) % q == 0]
    inf = [Y for Y in range(q) if hinf(0, Y) % q == 0]     # the fibre over w = 0: x at infinity
    ne, ni = sum(1 for a, b in pts if 2 * b % q == 0), sum(1 for Y in inf if 2 * Y % q == 0)
    print(f"   over F_{q}: {len(pts)} affine points, {ne} not etale; chart w = 1/x, over w = 0: {len(inf)} point, {ni} not etale")
    nes.append((ne, ni))
br = sum(nes[0])                              # x = -1, 0, 1 and the point at infinity
g = (2 * (0 - 1) * 2 + br + 2) // 2
print(f"   Riemann-Hurwitz: 2g - 2 = 2(-2) + {br}, g = {g}; plane formula (3 - 1)(3 - 2)/2 = {(3 - 1) * (3 - 2) // 2}")
print(f"   forgetting infinity: 2g - 2 = 2(-2) + {br - 1} = {2 * -2 + br - 1}, odd, so no whole g")
v1, v4 = 1 ** 0.5, 0.25 ** 0.5                  # vertex of xy = t at (sqrt t, sqrt t)
print(f"figure, xy = t for t = 1, 1/4, 0, -1/4: vertices ({v1:.1f}, {v1:.1f}), ({v4:.1f}, {v4:.1f}), the axes, ({v4:.1f}, {-v4:.1f}); box -2.5..2.5")
assert all(fam[t] == std == [2 * n + 1 for n in range(7)] for t in fam)      # rank vs count vs formula
assert ker - d1 == N and fib[(0, 0)] == [n + 1 for n in range(5)] and fib[(1, 0)] == [1] * 5
assert sizes.count(8) == 1 and sum(sizes) == p * p - 1 + p + 1             # one fibre is a line
assert mult49 == [2] * p and roots7 == [1, 2, 2, 0, 2, 0, 0] and et2 == 0   # constant length 2
assert ram == [2] and brute5 == [2] * 4 and all((y * y + 1) % 5 ** (k + 1) == 0 for k, y in enumerate(lifts))
assert brute2 == [1, 0, 0, 0] and bad == [(0, 0)] and om == [1, 2] and tot == 0
assert nes == [(3, 1)] * 3 and g == (3 - 1) * (3 - 2) // 2       # 3 + 1 branch points; genus 1 both ways
print("ALL CHECKS PASS")
