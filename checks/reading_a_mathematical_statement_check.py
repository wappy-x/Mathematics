# Reading a statement -- the check behind the card.  Standard library only.
# Three statements, each tested on small cases: the four-colour theorem on six
# small maps, Goldbach on the even numbers to 10,000, and the data clauses of
# Clay's Navier-Stokes statement (A) on two starting flows.
from math import exp, sin, cos, pi, sqrt

def brute(n, edges, k):          # road 1: try every colouring, count the proper ones
    count = 0
    for code in range(k ** n):
        c = [(code // k ** i) % k for i in range(n)]
        count += all(c[a] != c[b] for a, b in edges)
    return count
def poly(n, edges, k):           # road 2: deletion-contraction, P(G) = P(G-e) - P(G/e)
    if not edges: return k ** n
    (a, b), rest = edges[0], edges[1:]
    merged = {tuple(sorted((a if x == b else x, a if y == b else y))) for x, y in rest}
    return poly(n, rest, k) - poly(n - 1, sorted(e for e in merged if e[0] != e[1]), k)
def relabel(edges):              # vertices 0..n-1, as the contraction above expects
    names = sorted({v for e in edges for v in e})
    return len(names), [tuple(sorted((names.index(a), names.index(b)))) for a, b in edges]
def ring(m): return [(i, (i + 1) % m) for i in range(m)]
def complete(m): return [(i, j) for i in range(m) for j in range(i + 1, m)]
MAPS = [("Benelux, France, Germany", [("BE", "NL"), ("BE", "LU"), ("BE", "FR"), ("BE", "DE"),
          ("NL", "DE"), ("LU", "FR"), ("LU", "DE"), ("FR", "DE")]),
        ("Four Corners, borders only", ring(4)), ("Four Corners, points count", complete(4)),
        ("6-slice cake, borders only", ring(6)), ("6-slice cake, points count", complete(6)),
        ("5 regions all touching", complete(5))]
print("map                           regions pairs  most  colours  ways at k-1, k (brute / poly)")
needed, pairs = {}, {}
for name, raw in MAPS:
    n, edges = relabel(raw)
    k = next(k for k in range(1, n + 1) if brute(n, edges, k) > 0)
    lo, hi = brute(n, edges, k - 1), brute(n, edges, k)
    assert (lo, hi) == (poly(n, edges, k - 1), poly(n, edges, k))   # the two roads agree
    needed[name], pairs[name] = k, (len(edges), 3 * n - 6)
    print(f"{name:<30}{n:>7}{len(edges):>6}{3 * n - 6:>6}{k:>9}   {lo}, {hi} / {lo}, {hi}")
assert needed["Benelux, France, Germany"] == 4 and needed["6-slice cake, points count"] == 6
assert needed["5 regions all touching"] == 5 and pairs["5 regions all touching"] == (10, 9)

N = 10000                        # Goldbach: primes two ways, then every even number to N
sieve = [False, False] + [True] * (N - 1)
for i in range(2, int(N ** 0.5) + 1):
    if sieve[i]: sieve[i * i::i] = [False] * len(sieve[i * i::i])
trial = [m > 1 and all(m % d for d in range(2, int(m ** 0.5) + 1)) for m in range(N + 1)]
assert sieve == trial
def ways(m, distinct=False):
    return sum(1 for p in range(2, m // 2 + 1) if sieve[p] and sieve[m - p] and not (distinct and 2 * p == m))
print(f"primes below {N:,}: {sum(sieve)} (sieve and trial division agree)")
print("ways as a sum of two primes:  " + "  ".join(f"{m}: {ways(m)}" for m in (2, 4, 6, 8, 100)))
print("the same, two different primes: " + "  ".join(f"{m}: {ways(m, True)}" for m in (4, 6, 8)))
evens = range(4, N + 1, 2)
fail = [m for m in evens if ways(m) == 0]
fail_distinct = [m for m in evens if ways(m, True) == 0]
odd_fail = [m for m in range(3, 31, 2) if ways(m) == 0]
print(f"even numbers 4 to {N:,} checked: {len(evens):,}; with no split: {len(fail)}")
print(f"with no split into two different primes: {fail_distinct}")
print(f"odd numbers 3 to 29 with no split: {odd_fail}")
print("quoted, not computed: even numbers checked to 4e18 (published 2014)")
assert fail == [] and fail_distinct == [4, 6] and ways(2) == 0 and ways(100) == 6
assert odd_fail[:3] == [3, 11, 17]

def swirl(x, y, z):              # start A: a smooth swirl round the z-axis
    g = exp(-(x * x + y * y + z * z))
    return (-2 * y * g, 2 * x * g, 0.0)
h, worst = 1e-4, 0.0
for x, y, z in [(0.3, -0.7, 0.2), (1.1, 0.4, -0.5), (-0.6, 0.9, 1.3)]:
    d = ((swirl(x + h, y, z)[0] - swirl(x - h, y, z)[0]) + (swirl(x, y + h, z)[1] - swirl(x, y - h, z)[1])) / (2 * h)
    worst = max(worst, abs(d))
peak = max(sqrt(sum(c * c for c in swirl(i / 1000, 0, 0))) for i in range(0, 3001))
decay = [(r, (1 + r) ** 10 * sqrt(sum(c * c for c in swirl(r, 0, 0)))) for r in (5, 7, 9)]
s, m = 0.125, 80                  # road 1: energy by a grid sum over the cube [-5, 5]^3
grid = sum(sum(c * c for c in swirl(-5 + (i + 0.5) * s, -5 + (j + 0.5) * s, -5 + (l + 0.5) * s))
           for i in range(m) for j in range(m) for l in range(m)) * s ** 3
exact = 2 * (pi / 2) ** 1.5       # road 2: the Gaussian integral done by hand
print(f"start A: divergence at 3 points below 1e-6: {worst < 1e-6}; peak speed {peak:.6f} "
      f"(formula {sqrt(2) * exp(-0.5):.6f})")
print("start A: (1+|x|)^10 x speed at |x| = 5, 7, 9: " + ", ".join(f"{v:.3e}" for _, v in decay))
print(f"start A: energy integral, grid {grid:.6f}, formula {exact:.6f}")
assert worst < 1e-6 and abs(peak - sqrt(2) * exp(-0.5)) < 1e-6 and abs(grid - exact) < 1e-6
assert decay[0][1] > decay[1][1] > decay[2][1]

k, nu = 2 * pi, 0.01             # start B: a flow repeating in the unit cube, exact solution
def abc(x, y, z, t):
    a = exp(-nu * k * k * t)
    return [a * (sin(k * z) + cos(k * y)), a * (sin(k * x) + cos(k * z)), a * (sin(k * y) + cos(k * x))]
def pres(x, y, z, t): return -0.5 * sum(c * c for c in abc(x, y, z, t))
def d(f, p, axis, h):            # centred difference along one axis (axis 3 is time)
    a, b = list(p), list(p); a[axis] += h; b[axis] -= h
    return (f(*a) - f(*b)) / (2 * h)
left, biggest = 0.0, 0.0
for p in [(0.1, 0.2, 0.3, 0.5), (0.7, 0.4, 0.9, 0.5), (0.25, 0.6, 0.05, 1.0)]:
    u = abc(*p)
    for i in range(3):
        comp = lambda *q: abc(*q)[i]
        ut = d(comp, p, 3, 1e-5)
        conv = sum(u[j] * d(comp, p, j, 1e-5) for j in range(3))
        lap = sum((comp(*[p[q] + (1e-3 if q == j else 0) for q in range(4)]) - 2 * u[i]
                   + comp(*[p[q] - (1e-3 if q == j else 0) for q in range(4)])) / 1e-6 for j in range(3))
        left = max(left, abs(ut + conv + d(pres, p, i, 1e-5) - nu * lap))
        biggest = max(biggest, abs(conv))
print(f"start B: Navier-Stokes leftover at 3 points below 1e-4: {left < 1e-4} (largest term {biggest:.2f})")
cells = []
for side in (1, 2, 3):           # energy in a box of side 1, 2, 3 cells, grid exact for these waves
    q = 16 * side
    cells.append(sum(sum(c * c for c in abc(i / 16, j / 16, l / 16, 0)) for i in range(q)
                     for j in range(q) for l in range(q)) / 16 ** 3)
print("start B: energy integral in a box of side 1, 2, 3: " + ", ".join(f"{e:.4f}" for e in cells)
      + f" (formula 3, 24, 81); one cell at t = 1: {3 * exp(-2 * nu * k * k):.4f}")
assert left < 1e-4 and all(abs(e - 3 * s ** 3) < 1e-9 for e, s in zip(cells, (1, 2, 3)))
print("ALL CHECKS PASS")
