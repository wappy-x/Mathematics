# Hahn-Banach check: extend a bond price rule to every portfolio, keeping its norm.
# Standard library only.  Three states (down, flat, up), payoffs and prices in pounds,
# all prices illustrative.  Nothing imported knows the answer: the searches are written out.
from itertools import product

G, B, Z = (100, 100, 100), (40, 100, 100), (60, 100, 140)  # government bond, corporate bond, share
PG, PB, BOUND = 95.0, 89.0, 0.95                           # bond prices; the bound s(x) = 0.95|x|
SIGNS = list(product((-1, 1), repeat=3))

def size(x): return max(abs(v) for v in x)                 # sup norm: the largest payoff in size
def value(w, x): return sum(w[i] * x[i] for i in range(3))  # price of payoff x under state prices w
def dnorm(w): return max(abs(value(w, s)) for s in SIGNS)  # norm of a rule: worst case on |x| = 1
def phi(a, b): return a * PG + b * PB                      # the price rule on M = all a*G + b*B
def port(a, b, k): return [a * G[i] + b * B[i] + k * Z[i] for i in range(3)]

def tmin(f, lo=-4.0, hi=4.0):                              # minimum of a convex f, by thirds
    for _ in range(200):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if f(m1) <= f(m2): hi = m2
        else: lo = m1
    return f((lo + hi) / 2)

def min2(f): return tmin(lambda a: tmin(lambda b: f(a, b)))

def det(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2]
            - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def solve(c):                                              # state prices that price G, B and Z at c
    a, r = [G, B, Z], [PG, PB, c]
    return [det([[r[i] if j == k else a[i][j] for j in range(3)] for i in range(3)]) / det(a)
            for k in range(3)]

print("three states (down, flat, up); G = (100,100,100) at 95, B = (40,100,100) at 89")
onM = max(abs(phi(1, t / 1e5)) / size(port(1, t / 1e5, 0)) for t in range(-200000, 200001))
print(f"norm of the bond rule on M, scan of 400001 portfolios: {onM:.6f}")
assert abs(onM - PG / size(G)) < 1e-9, "the rule's norm on M is the government bond's ratio"

# road 1: the one-step band, lo = sup[phi(m) - s(m - z)], hi = inf[s(m + z) - phi(m)]
hi1 = min2(lambda a, b: BOUND * size(port(a, b, 1)) - phi(a, b))
lo1 = -min2(lambda a, b: BOUND * size(port(a, b, -1)) - phi(a, b))
# road 2: state prices; the bonds fix w_d and w_f + w_u, the share's price runs with w_u = t
wd = (PG - PB) / (G[0] - B[0]); rest = PG / 100 - wd
lo2, hi2 = value((wd, rest, 0), Z), value((wd, 0, rest), Z)
# road 3: solve for the rule at each share price c and keep the c whose norm stays 0.95
ok = [c / 4 for c in range(280, 585) if dnorm(solve(c / 4)) <= BOUND + 1e-9]
lo3, hi3 = min(ok), max(ok)
print(f"forced: w_d = {wd:.4f}, w_f + w_u = {rest:.4f}")
for name, lo, hi in [("road 1, one-step formula", lo1, hi1),
                     ("road 2, state prices >= 0", lo2, hi2), ("road 3, scan of c", lo3, hi3)]:
    print(f"{name:<27} share price band: {lo:.2f} to {hi:.2f}")
assert abs(lo1 - lo2) < 1e-6 and abs(hi1 - hi2) < 1e-6, "one-step formula against state prices"
assert abs(lo3 - lo2) < 1e-9 and abs(hi3 - hi2) < 1e-9, "norm scan against state prices"
for name, a, b, k in [("lo witness: m = (8/15)G + (2/3)B, m - z", 8 / 15, 2 / 3, -1),
                      ("hi witness: m = (2/15)G - (4/3)B, m + z", 2 / 15, -4 / 3, 1)]:
    y, s = port(a, b, k), BOUND * size(port(a, b, k))
    print(f"{name} = ({y[0]:.2f}, {y[1]:.2f}, {y[2]:.2f}), phi(m) = {phi(a, b):.2f}, s = {s:.2f}")
    assert abs(k * (s - phi(a, b)) - (lo2 if k < 0 else hi2)) < 1e-9, "a hand witness hits the band's end"

mid = solve((lo2 + hi2) / 2)
grid = list(product(range(-3, 4), repeat=3))
excess = max(value(mid, x) - BOUND * size(x) for x in grid)
print(f"midpoint c = {(lo2 + hi2) / 2:.2f}: w = ({mid[0]:.4f}, {mid[1]:.4f}, {mid[2]:.4f}), "
      f"norm {dnorm(mid):.4f}, sum of |w| {sum(abs(v) for v in mid):.4f}")
print(f"  largest Phi(x) - 0.95|x| over {len(grid)} payoffs: {abs(excess):.4f}")
assert excess < 1e-9 and abs(value(mid, G) - PG) < 1e-9 and abs(value(mid, B) - PB) < 1e-9
norming = (0, 0, 1)
print(f"norming rule for z: w = (0, 0, 1), value {value(norming, Z):.2f}, |z| = {size(Z):.2f}, "
      f"norm {dnorm(norming):.2f}")

print("chart, share price c:  " + " ".join(f"{c / 2:.1f}" for c in range(148, 285, 17)))
print("chart, norm of rule:   " + " ".join(f"{dnorm(solve(c / 2)):.2f}" for c in range(148, 285, 17)))
for c in (131.0, 0.0):
    w = solve(c)
    bad = max(value(w, x) - BOUND * size(x) for x in grid)
    print(f"breaks, share at {c:6.2f}: w = ({w[0]:.4f}, {w[1]:.4f}, {w[2]:.4f}), norm {dnorm(w):.4f},"
          f" worst excess {bad:.4f}")
    assert dnorm(w) > BOUND + 0.1 and abs(dnorm(w) - sum(abs(v) for v in w)) < 1e-9

def qsize(x): return sum(abs(v) ** 0.5 for v in x) ** 2   # the square-root size rule, not convex
print(f"square-root rule: size(e1) + size(e2) = 2.00, size(e1 + e2) = {qsize([1, 1]):.2f}")
for n in (3, 10, 100):
    line = PG / qsize([100] * n)
    w = [PG / 100 / n] * n                                 # spread the price evenly: the best case
    tests = [[1.0 if i == j else 0.0 for i in range(n)] for j in range(n)] + [[1.0] * n]
    best = max(abs(sum(w[i] * x[i] for i in range(n))) / qsize(x) for x in tests)
    print(f"  N = {n:3d}: bound on the bond line {line:.6f}, best extension {best:.6f},"
          f" ratio {best / line:.2f}")
    assert abs(best / line - n) < 1e-9, "the forced bound grows N-fold"

total, high, p, n, rows = 0.0, 0, 1, 0, []                 # hourly prices 120 on [4^k, 2*4^k)
for k in range(1, 7):
    for stop in (2 * 4 ** k - 1, 4 ** (k + 1) - 1):
        while n < stop:
            n += 1
            if p * 4 <= n: p *= 4
            price = 120.0 if n < 2 * p else 40.0
            total += price; high += price > 100
        assert high == (4 ** (k + 1) - 1) // 3, "count of peak hours against the closed form"
        rows.append(f"{stop}: {total / stop:.2f}")
print("peak blocks at GBP 120/MWh, else 40: hours 1, " + ", ".join(f"{4 ** j}-{2 * 4 ** j - 1}" for j in range(1, 4)))
print("running average, GBP/MWh, at hour " + ", ".join(rows[:6]))
print("                                  " + ", ".join(rows[6:]))
print(f"band for the long-run average: {40 + 80 / 3:.2f} to {40 + 160 / 3:.2f}")
for pb, z in [(92.0, Z), (PB, (60, 100, 100))]:
    d = (PG - pb) / (G[0] - B[0]); r = PG / 100 - d
    print(f"try: B at {pb:.2f}, share ({z[0]}, {z[1]}, {z[2]}): band {value((d, r, 0), z):.2f}"
          f" to {value((d, 0, r), z):.2f}")
print("ALL CHECKS PASS")
