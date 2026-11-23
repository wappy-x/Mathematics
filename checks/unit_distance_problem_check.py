# The unit-distance problem -- the check behind the card.  Standard library
# only.  Grid counts are made pair by pair and again by the two-squares formula;
# r2(m) is counted on the circle and again by divisors; a 4-D set shows what the
# plane forbids; a sieve follows the grid's extra exponent as n grows.
import math

def grid(k):
    return [(x, y) for x in range(k) for y in range(k)]

def histogram(pts):                      # road one: every unordered pair, by squared distance
    h = {}
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            d = sum((p - q) ** 2 for p, q in zip(pts[i], pts[j]))
            h[d] = h.get(d, 0) + 1
    return h

def reps(m):                             # road one: whole (a, b) on the circle a^2 + b^2 = m
    out = []
    for a in range(-math.isqrt(m), math.isqrt(m) + 1):
        b = math.isqrt(m - a * a)
        if b * b == m - a * a:
            out += [(a, b), (a, -b)] if b else [(a, 0)]
    return out

def r2_divisors(m):                      # road two: 4 x (divisors 1 mod 4 - divisors 3 mod 4)
    d1 = sum(1 for d in range(1, m + 1) if m % d == 0 and d % 4 == 1)
    d3 = sum(1 for d in range(1, m + 1) if m % d == 0 and d % 4 == 3)
    return 4 * (d1 - d3)

def by_formula(k, m):                    # road two for grids: each step (a, b) fits (k-|a|)(k-|b|) times
    return sum((k - abs(a)) * (k - abs(b)) for a, b in reps(m) if abs(a) < k and abs(b) < k) // 2

def most_shared(pts, m):                 # most points at squared distance m from two given points
    nb = [{j for j, q in enumerate(pts) if sum((x - y) ** 2 for x, y in zip(p, q)) == m} for p in pts]
    return max(len(nb[i] & nb[j]) for i in range(len(pts)) for j in range(i + 1, len(pts)))

def sci(v):                              # mantissa and exponent, written out alike in Rust
    ex = math.floor(math.log10(v))
    return f"{v / 10 ** ex:.3f}e{ex}"

def plane_cap(n):                        # largest u with n * C(d, 2) <= n(n - 1), d = 2u/n
    u = 0
    while (2 * (u + 1) / n) * (2 * (u + 1) / n - 1) <= 2 * (n - 1):
        u += 1
    return u

g3 = histogram(grid(3))
print(f"3x3 grid: n = 9, pairs at distance 1: {g3[1]} by brute force ({g3[1] // 2} across, {g3[1] // 2} up), {2 * 3 * 2} by 2k(k-1)")
g5 = histogram(grid(5))
print(f"5x5 grid, pairs by squared distance: 1 -> {g5[1]}, 2 -> {g5[2]}, 5 -> {g5[5]}, 25 -> {g5[25]}")
d1, d3 = (sum(1 for d in range(1, 6) if 5 % d == 0 and d % 4 == r) for r in (1, 3))
print(f"5x5 knight steps: {len(reps(5))} steps x (5-1)(5-2) = {len(reps(5)) * 12} ordered, {by_formula(5, 5)} pairs;"
      f" divisors of 5: d1 = {d1}, d3 = {d3}")
print("best squared distance m in a k x k grid (brute force, then formula):")
best = {}
for k in (5, 10, 20, 30):
    h = histogram(grid(k))
    m = min(d for d in h if h[d] == max(h.values()))
    best[k] = (m, h[m])
    print(f"  k={k:2d} n={k * k:3d} best m={m:2d} pairs {h[m]:5d} formula {by_formula(k, m):5d}"
          f" distance-1 pairs {h[1]:5d} pairs/n {h[m] / (k * k):.2f}")
    assert by_formula(k, m) == h[m] and h[1] == 2 * k * (k - 1)    # two roads per grid
r2s = [(m, len(reps(m)), r2_divisors(m)) for m in (5, 15, 25, 45, 65, 325, 1105)]
print("r2(m) on the circle and by divisors:", "; ".join(f"{m}: {a} {b}" for m, a, b in r2s))
assert all(a == b for _, a, b in r2s)                             # two roads to r2
m10 = best[10][0]
deg = [sum(1 for q in grid(10) if (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 == m10) for p in grid(10)]
sc2 = sum(d * (d - 1) // 2 for d in deg)
print(f"plane rule, 10x10 grid at m={m10}: most shared neighbours {most_shared(grid(10), m10)};"
      f" sum C(d,2) = {sc2} <= n(n-1) = {100 * 99}")
circ = [(a, b) for a, b in reps(25)]
four = [(a, b, 0, 0) for a, b in circ] + [(0, 0, a, b) for a, b in circ]
h4 = histogram(four)
print(f"4-D, two circles of radius 5: n = {len(four)}, pairs at squared distance 50: {h4[50]};"
      f" most shared neighbours {most_shared(four, 50)}")
print(f"plane cap for n = 24 when no two points share 3 neighbours: {plane_cap(24)}")
assert most_shared(grid(10), m10) <= 2 and sc2 <= 100 * 99 and h4[50] > plane_cap(24)
print(f"mistake, 10x10 grid with distance 1 only: {2 * 10 * 9} not {best[10][1]}")
print(f"mistake, ordered pairs in the 5x5 grid: {2 * g5[5]} not {g5[5]}")
print(f"mistake, 3x3 grid read as an exponent: log 12 / log 9 = {math.log(12) / math.log(9):.4f}")
primes1 = [p for p in range(5, 200) if p % 4 == 1 and all(p % q for q in range(2, math.isqrt(p) + 1))]
print(f"Erdos grid: m = first t primes 1 mod 4 ({', '.join(map(str, primes1[:6]))}) multiplied, side k = 2s, s = isqrt(m) + 1:")
m = 1
for t in range(1, 7):
    m *= primes1[t - 1]
    k = 2 * (math.isqrt(m) + 1)
    u = by_formula(k, m)
    print(f"  t={t} m={m} r2={len(reps(m))} s={k // 2} k={k} pairs {u} >= 2^(t-1) n = {2 ** (t - 1) * k * k};"
          f" log u / log n - 1 = {math.log(u) / math.log(k * k) - 1:.4f}")
    assert len(reps(m)) == 4 * 2 ** t and u >= 2 ** (t - 1) * k * k   # circle count, then the bound
limit = 10 ** 6
sieve = bytearray([1]) * (limit + 1)
sieve[0] = sieve[1] = 0
for p in range(2, math.isqrt(limit) + 1):
    if sieve[p]:
        sieve[p * p::p] = bytearray(len(range(p * p, limit + 1, p)))
print("the grid bound further out (extra exponent = (t-1) log 2 / log n, log n = log 4 + log m):")
t, logm, mark = 0, 0.0, 100
for p in range(5, limit + 1, 4):
    if sieve[p]:
        t += 1
        logm += math.log(p)
    if p + 4 > mark:
        logn = math.log(4) + logm
        e, est = (t - 1) * math.log(2) / logn, math.log(2) / math.log(logn)
        print(f"  primes below {mark:>7}: t = {t:5d}, log10 n = {logn / math.log(10):9.1f},"
              f" extra exponent {e:.4f}, estimate log 2 / log log n {est:.4f}")
        assert e > 0.014 and abs(e / est - 1) < 0.1             # above n^1.014; sieve near the estimate
        mark *= 10
print(f"estimate: c near log 2 = {math.log(2):.4f}; the grid's extra exponent falls to 0.014"
      f" near log10 n = {sci(math.exp(math.log(2) / 0.014) / math.log(10))}")
print("quoted: Erdos 1946 grid and 3/2 ceiling; Golod-Shafarevich 1964; 4/3 ceiling 1984, Szekely 1997;"
      " disproof announced 2026-05-20; explicit eps 6.24e-38; Sawin exponent 1.014; u(9) = 18, u(21) = 57")
print(f"log10 n where n^eps reaches 2: eps 6.24e-38 -> {sci(math.log10(2) / 6.24e-38)},"
      f" eps 0.014 -> {math.log10(2) / 0.014:.2f}")
segs = [((x, y), (x + a, y + b)) for x, y in grid(5) for a, b in reps(5)
        if (a, b) > (0, 0) and 0 <= x + a < 5 and 0 <= y + b < 5]
(x0, y0), (x1, y1) = segs[0]
print(f"figure, 5x5 grid, step 60, origin (40, 40); {len(segs)} segments of squared length 5;"
      f" first ({40 + 60 * x0}, {40 + 60 * y0})-({40 + 60 * x1}, {40 + 60 * y1}); unit {60 * math.sqrt(5):.2f}")
print("ALL CHECKS PASS")
