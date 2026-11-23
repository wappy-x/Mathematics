# Machines in proofs -- the check behind the card.  Nothing is imported.
# The four kinds of computer help, each on a case small enough to run here:
# numerical evidence, exact (symbolic) computation, exhaustive search, and the
# double count that the quoted Lean lemma proves, redone on two small graphs.
def yn(claim): return "yes" if claim else "no"

def is_prime(n):                         # road one: trial division
    if n < 2: return False
    d = 2
    while d * d <= n:
        if n % d == 0: return False
        d += 1
    return True

def sieve(limit):                        # road two: the sieve of Eratosthenes
    mark = [True] * (limit + 1)
    mark[0] = mark[1] = False
    for i in range(2, limit + 1):
        if mark[i]:
            for j in range(i * i, limit + 1, i): mark[j] = False
    return mark

def ten_digits(n):                       # an exact integer, rounded to 10 digits
    s = str(n)
    head = int(s[:10]) + (1 if s[10] >= "5" else 0)
    return f"{str(head)[0]}.{str(head)[1:]} x 10^{len(s) - 1}"

def pmul(p, q):                          # polynomials as coefficient lists, lowest first
    out = [0] * (len(p) + len(q) - 1)
    for i, x in enumerate(p):
        for j, y in enumerate(q): out[i + j] += x * y
    return out

def padd(p, q, sign=1):
    n = max(len(p), len(q))
    p, q = p + [0] * (n - len(p)), q + [0] * (n - len(q))
    return [x + sign * y for x, y in zip(p, q)]

def chromatic(n, edges):                 # deletion-contraction: P(G) = P(G - e) - P(G / e)
    if not edges: return [0] * n + [1]   # no lines: k^n
    (u, v), rest = edges[0], edges[1:]
    merged = set()                       # contract: v becomes u, the last vertex becomes v
    for x, y in rest:
        x, y = (u if x == v else x), (u if y == v else y)
        x, y = (v if x == n - 1 else x), (v if y == n - 1 else y)
        if x != y: merged.add((min(x, y), max(x, y)))
    return padd(chromatic(n, rest), chromatic(n - 1, sorted(merged)), -1)

def colourings(n, edges, k):             # exhaustive search over all k^n assignments
    found = []
    for code in range(k ** n):
        c = [code // k ** i % k for i in range(n)]
        if all(c[x] != c[y] for x, y in edges): found.append(c)
    return found

def darts(n, edges):                     # the lemma's double count, done both ways
    d = [(x, y) for x, y in edges] + [(y, x) for x, y in edges]
    by_start = sum(sum(1 for s, _ in d if s == v) for v in range(n))
    by_edge = sum(sum(1 for s, t in d if {s, t} == {x, y}) for x, y in edges)
    return len(d), by_start, by_edge

print("1. numerical evidence")
K = 41                                   # the constant in n*n + n + K
vals = [n * n + n + K for n in range(41)]
run = 0
while is_prime(vals[run]): run += 1
mark = sieve(vals[-1])
low = next(d for d in range(2, vals[run]) if vals[run] % d == 0)   # its smallest factor
print(f"  n*n + n + {K} is prime for n = 0 to {run - 1}: checked for {run} values by trial division")
print(f"  the sieve agrees on all {run}: {yn(all(mark[v] for v in vals[:run]))}")
print(f"  n = {run}: {vals[run]} = {low} x {vals[run] // low}, composite")
a, b, c, e = 1782, 1841, 1922, 12
fa = fb = fc = 1.0
for _ in range(e): fa, fb, fc = fa * a, fb * b, fc * c
rel = (fa + fb) / fc - 1.0
print(f"  floats: (1782^12 + 1841^12) / 1922^12 - 1 = {rel:.3e}")
print("2. exact computation")
lhs, rhs = a ** e + b ** e, c ** e
print(f"  1782^12 + 1841^12 = {lhs}")
print(f"  1922^12           = {rhs}")
print(f"  to 10 digits both are {ten_digits(lhs)}: {yn(ten_digits(lhs) == ten_digits(rhs))}")
print(f"  exact difference: {lhs - rhs}")
primes = [2, 3, 5, 7, 11, 13]
res = [(pow(a, e, p) + pow(b, e, p) - pow(c, e, p)) % p for p in primes]
print(f"  difference mod 2, 3, 5, 7, 11, 13 by residues: {res}; from the exact number: {[(lhs - rhs) % p for p in primes]}")
print(f"  parity: 1782^12 + 1841^12 is {'odd' if lhs % 2 else 'even'}, 1922^12 is {'odd' if rhs % 2 else 'even'}")
WHEEL = [(0, i) for i in range(1, 6)] + [(i, i % 5 + 1) for i in range(1, 6)]   # hub 0, rim 1 to 5
poly = chromatic(6, WHEEL)
x2 = [-2, 1]                                                     # k - 2
closed = pmul([0, 1], padd(pmul(pmul(x2, x2), pmul(pmul(x2, x2), x2)), x2, -1))
print(f"  wheel (hub + ring of 5), P(k) coefficients k^0..k^6 by deletion-contraction: {poly}")
print(f"  the same from k((k-2)^5 - (k-2)): {closed}; equal: {yn(poly == closed)}")
ev = lambda p, k: sum(cf * k ** i for i, cf in enumerate(p))
print(f"  P(3) = {ev(poly, 3)}, P(4) = {ev(poly, 4)}, P(5) = {ev(poly, 5)}")
print(f"  by hand: P(3) = 3 x (1 - 1) = {3 * (1 - 1)}; P(4) = 4 x (2^5 - 2) = 4 x {2 ** 5 - 2} = {4 * (2 ** 5 - 2)}")
print("3. exhaustive search")
four, three = colourings(6, WHEEL, 4), colourings(6, WHEEL, 3)
print(f"  wheel: {4 ** 6} assignments of 4 colours tried, {len(four)} proper; {3 ** 6} of 3 tried, {len(three)} proper")
cert = four[0]
print(f"  certificate for 'four suffice': {cert}, rechecked in {len(WHEEL)} edge tests: {yn(all(cert[x] != cert[y] for x, y in WHEEL))}")
holed = [ed for ed in WHEEL if ed != (1, 2)]
print(f"  search run on the wrong map (rim line 1-2 left out): {len(colourings(6, holed, 3))} proper 3-colourings")
print("4. the quoted lemma's double count")
ICO = ([(0, i) for i in range(1, 6)] + [(i, i % 5 + 1) for i in range(1, 6)] + [(11, i) for i in range(6, 11)]
       + [(i, (i - 5) % 5 + 6) for i in range(6, 11)] + [(i, i + 5) for i in range(1, 6)]
       + [(i, i % 5 + 6) for i in range(1, 6)])
deg = lambda n, ed, v: sum(v in pair for pair in ed)
for name, n, ed in (("wheel", 6, WHEEL), ("icosahedron", 12, ICO)):
    total, by_start, by_edge = darts(n, ed)
    degs = sorted({deg(n, ed, v) for v in range(n)})
    print(f"  {name}: {n} vertices, {len(ed)} edges, degrees {degs}; darts {total}: "
          f"by start vertex {by_start}, by edge {by_edge}, 2 x edges {2 * len(ed)}")
print(f"  by hand, wheel degree sum: hub 5 + rim 5 x 3 = {5 + 5 * 3}; icosahedron: 12 x 5 = {12 * 5}")
print(f"  mistake, edges counted once: wheel degree sum {sum(deg(6, WHEEL, v) for v in range(6))} against {len(WHEEL)} edges")
print("quoted, not computed: 1852, the question; 1879, Kempe, gap found 1890; 1976, about 1200 hours, 1476 configurations in the final version; 1997, 633 configurations, "
      "32 rules (487 before); 2005, the whole proof in Coq")
assert run == 40 and vals[run] == 41 * 41 and all(mark[v] for v in vals[:run]) and not mark[vals[run]]
assert lhs != rhs and ten_digits(lhs) == ten_digits(rhs) and res == [(lhs - rhs) % p for p in primes]
assert res[0] == 1 and abs(rel - float(lhs - rhs) / fc) < 1e-15 and rel < 0
assert poly == closed and ev(poly, 3) == len(three) == 0 and ev(poly, 4) == len(four) == 120
assert len(colourings(6, holed, 3)) == 6 == ev(chromatic(6, holed), 3)
assert darts(6, WHEEL) == (20, 20, 20) and darts(12, ICO) == (60, 60, 60) and len(set(ICO)) == 30
print("ALL CHECKS PASS")
