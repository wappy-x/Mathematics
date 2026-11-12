# Many dimensions: a product grid against random points.  Standard library only.
# Five assets; over a year each grows by a factor 0.8 + 0.4u, u uniform on 0 to 1
# (illustrative).  Wanted: the expected payoff of a $100 basket call,
# 100 * max(average factor - 1, 0), which is an integral over the 5-dimensional cube.
from fractions import Fraction
from math import comb, factorial, sqrt, exp, log
from itertools import product

MASK = (1 << 64) - 1
def splitmix64(seed):                      # the generator, written out, as in wing 09
    state = seed
    def next_u():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        z ^= z >> 31
        return (z >> 11) * 2.0 ** -53       # uniform on [0, 1)
    return next_u

def basket(us):                             # average growth factor, 0.8 to 1.2
    s = 0.0
    for u in us:
        s += u
    return 0.8 + 0.4 * s / len(us)

def payoff(us):                             # dollars, on a $100 basket
    return 100.0 * max(basket(us) - 1.0, 0.0)

def exact(d):                               # road 1: exact rationals
    # payoff = (40/d)(S - d/2)+ with S = u1 + ... + ud.  S is symmetric about d/2, so
    # E(S - d/2)+ = E(d/2 - S)+ = sum_k (-1)^k C(d,k) (d/2 - k)+^(d+1) / (d+1)!.
    c = Fraction(d, 2)
    low = sum((-1) ** k * comb(d, k) * (c - k) ** (d + 1) for k in range(d + 1) if c > k)
    mean = Fraction(40, d) * low / factorial(d + 1)
    var = Fraction(40, d) ** 2 * Fraction(d, 24) - mean ** 2   # E(S - d/2)+^2 = Var S / 2 = d/24
    return float(mean), sqrt(float(var))

def grid(d, m, f, left=False):              # road 2: the product midpoint rule, m per axis
    xs = [(j + (0.0 if left else 0.5)) / m for j in range(m)]
    t = 0.0
    for p in product(xs, repeat=d):
        t += f(p)
    return t / m ** d

def monte_carlo(d, n, nxt, same=False):     # road 3: n random points, mean and s
    t = t2 = 0.0
    for _ in range(n):
        if same:
            u = nxt(); x = payoff([u] * d)  # wrong: one draw reused for every asset
        else:
            x = payoff([nxt() for _ in range(d)])
        t += x; t2 += x * x
    mean = t / n
    return mean, sqrt((t2 - n * mean * mean) / (n - 1))

I5, sig5 = exact(5)
print(f"exact, d=5      I = {I5:.6f}   sigma = {sig5:.6f}")
assert abs(I5 - 2.081597) < 1e-6 and abs(sig5 - 3.000048) < 1e-6
t = [comb(5, k) * (2.5 - k) ** 6 for k in range(3)]; low = t[0] - t[1] + t[2]
print(f"hand: {t[0]:.6f} - {t[1]:.6f} + {t[2]:.6f} = {low:.6f}; /720 = {low / 720:.6f}; x8 = {8 * low / 720:.6f}")
print(f"hand: E[X^2] = 64 x 5/24 = {64 * 5 / 24:.6f}; minus I^2 {I5 * I5:.6f} = variance {64 * 5 / 24 - I5 * I5:.6f}")

print("grid, d=5:  m   N = m^5   estimate   true error")
err = {}
for m in range(2, 11):
    g = grid(5, m, payoff); err[m] = g - I5
    print(f"           {m:2d} {m ** 5:9d} {g:10.6f} {err[m]:+12.6f}")
print("observed order in h (even m):")
for a, b in ((2, 4), (4, 6), (6, 8), (8, 10)):
    p = log(abs(err[a] / err[b])) / log(b / a)
    print(f"  m {a:2d} -> {b:2d}   order {p:.4f}   per N {p / 5:.4f}")
assert abs(log(abs(err[8] / err[10])) / log(10 / 8) - 2.0) < 0.1   # h^2, as proved
assert abs(err[5]) > abs(err[4])                                     # the kink: more points, worse
assert abs(err[10]) < 0.01                                           # grid closes in on road 1

# the smooth check: f = 100 exp(A - 1) has f_ii <= 100 * 0.08^2 * e^0.2 everywhere
smooth = lambda us: 100.0 * exp(basket(us) - 1.0)
J = 100.0 * exp(-0.2) * ((exp(0.08) - 1.0) / 0.08) ** 5
ej = grid(5, 10, smooth) - J
bound = 5 * 100.0 * 0.0064 * exp(0.2) * 0.1 ** 2 / 24
print(f"smooth, m=10: true error {ej:+.8f}  bound {bound:.8f}  ratio {bound / -ej:.4f}")
assert 0 < -ej <= bound   # convex f: the midpoint grid reads low

nxt = splitmix64(2026)
est, s = monte_carlo(5, 10000, nxt)
e5, s5, se = est, s, s / sqrt(10000)
print(f"MC, d=5, N=10000: estimate {est:.6f}  s {s:.6f}  SE {se:.6f}")
print(f"  true error {est - I5:+.6f} = {(est - I5) / se:+.4f} SE;  sigma/sqrt(N) {sig5 / 100:.6f}")
assert abs(est - I5) < 4 * se and abs(s / sig5 - 1) < 0.05

print("MC root-mean-square error over 40 runs, d=5:")
rms = {}
for n in (100, 1000, 10000):
    sq = 0.0
    for _ in range(40):
        e, _s = monte_carlo(5, n, nxt); sq += (e - I5) ** 2
    rms[n] = sqrt(sq / 40)
    print(f"  N {n:6d}   rms {rms[n]:.6f}   sigma/sqrt(N) {sig5 / sqrt(n):.6f}   ratio {rms[n] * sqrt(n) / sig5:.4f}")
    assert abs(rms[n] * sqrt(n) / sig5 - 1) < 0.35
print(f"  observed order per N, 100 -> 10000: {log(rms[100] / rms[10000]) / log(100):.4f}")

C = abs(err[10]) * 100000 ** 0.4                 # grid error about C N^-0.4 (even m)
print(f"crossover estimate, d=5: C {C:.4f}  MC wins above N = {(sig5 / C) ** 10:.0f}")
print(f"equal budget, d=5, N=100000: grid error {err[10]:+.6f}  MC sigma/sqrt(N) {sig5 / sqrt(100000):.6f}")
assert abs(err[10]) < sig5 / sqrt(100000)                          # below the crossover, the grid wins
print("cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error")
for d in (1, 2, 3, 4, 5, 10, 20):
    print(f"   {d:3d} {10 ** d:22d} {2 / d:9.2f} {2 ** (d / 2):14.2f} {4:12d}")

se_mc = {}
for d in (10, 20):
    Id, sd = exact(d)
    est, s = monte_carlo(d, 10000, nxt)
    print(f"d={d}: I {Id:.6f} sigma {sd:.6f}  MC {est:.6f} SE {s / 100:.6f} err {est - Id:+.6f}")
    assert abs(est - Id) < 4 * s / 100
    se_mc[d] = s / 100
I10 = exact(10)[0]
for m in (2, 3):
    g = grid(10, m, payoff)
    print(f"grid d=10, m={m}: N {m ** 10:6d}  estimate {g:.6f}  true error {g - I10:+.6f}")
print(f"  m=3 grid error / MC SE at d=10: {abs(g - I10) / se_mc[10]:.2f}")

print("what breaks, d=5:")
gl = grid(5, 10, payoff, left=True)
print(f"  left-corner grid, m=10      {gl:.6f}  error {gl - I5:+.6f}")
bad, sb = monte_carlo(5, 10000, splitmix64(2026), same=True)
aim = 100 * 0.2 * 0.5 / 2                  # what that averages: 100 max(0.4u - 0.2, 0) on 0 to 1, a triangle
print(f"  one draw for all 5 assets   {bad:.6f}  error {bad - I5:+.6f}  aims at {aim:.6f}")
print(f"  error bar s/N, not s/sqrt(N) {s5 / 10000:.6f}  true error is {abs(e5 - I5) / (s5 / 10000):.1f} of them")
assert abs(bad - aim) < 4 * sb / 100       # it estimates that 1-D integral, not the basket
print("ALL CHECKS PASS")
