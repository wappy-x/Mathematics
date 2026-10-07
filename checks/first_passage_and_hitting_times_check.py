# Hitting times of the simple random walk -- the check behind the card.  Standard library only.
# Roads: the formula; every path of 16 rounds enumerated; probability pushed along every path
# round by round; first-step equations solved by elimination; a seeded simulation with its
# standard error.  Nothing imported knows the answer.
from fractions import Fraction
from math import sqrt, pi

M64 = (1 << 64) - 1
class SplitMix64:                                  # the small generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def step(self): return 1 if self.next() >> 63 else -1   # top bit: +1 or -1, each half the time

def u(two_n, x=1.0):                               # formula: P(S_2n = 0) = C(2n, n) / 2^(2n), as a product
    for k in range(1, two_n // 2 + 1): x = x * (2 * k - 1) / (2 * k)
    return x

def first_step(lo, hi, p, start, top, bottom, cost):
    # h_k = cost + p h_(k+1) + (1 - p) h_(k-1) for lo < k < hi, h_lo = bottom, h_hi = top.
    q, n = 1.0 - p, hi - lo - 1
    b, c, d = [1.0] * n, [-p] * n, [cost] * n
    d[0] += q * bottom; d[-1] += p * top
    for i in range(1, n):                          # eliminate downwards
        m = -q / b[i - 1]; b[i] -= m * c[i - 1]; d[i] -= m * d[i - 1]
    h = [0.0] * n; h[-1] = d[-1] / b[-1]
    for i in range(n - 2, -1, -1): h[i] = (d[i] - c[i] * h[i + 1]) / b[i]
    return h[start - lo - 1]

def row(name, *vals): print(f"{name:<40}" + "".join(f"{v:>12.6f}" for v in vals))
def row_eq(name, got, want): row(name, got, want); assert abs(got - want) < 1e-9, name

# ---- road 2: every one of the 2^16 paths of 16 rounds, first return to level recorded ----
L = 16
first, hit1, never = [0] * (L + 1), [0] * (L + 1), 0
for w in range(1 << L):
    s, back, up = 0, 0, 0
    for i in range(L):
        s += 1 if (w >> i) & 1 else -1
        if s == 0 and not back: first[i + 1] += 1; back = 1
        if s == 1 and not up: hit1[i + 1] += 1; up = 1
    never += not back
print(f"{'first return T, all 65536 paths of 16':<40}{'enumerated':>12}{'formula':>12}")
for t in (2, 4, 6, 8):
    e, f = Fraction(first[t], 1 << L), u(t - 2, Fraction(1)) - u(t, Fraction(1))
    print(f"{'  P(T = ' + str(t) + ')':<40}{str(e):>12}{str(f):>12}")
    assert e == f, "enumerated first-return law vs u(2n-2) - u(2n)"
e16 = Fraction(never, 1 << L)
print(f"{'  P(T > 16)':<40}{str(e16):>12}{str(u(16, Fraction(1))):>12}")
assert e16 == u(16, Fraction(1)), "no return in 16 rounds vs P(S_16 = 0)"
for t in (1, 3, 5, 7):                             # first passage to +1 at round t = 2n - 1 has P(T = 2n)
    e, f = Fraction(hit1[t], 1 << L), u(t - 1, Fraction(1)) - u(t + 1, Fraction(1))
    print(f"{'  P(tau_1 = ' + str(t) + ')':<40}{str(e):>12}{str(f):>12}")
    assert e == f, "enumerated first passage to +1 vs P(T = t + 1)"

# ---- road 3: push probability along every path, level absorbs; survival to 1000 rounds ----
N = 1000
dist = {0: 1.0}; surv = [1.0]
for k in range(1, N + 1):
    new = {}
    for x, pr in dist.items():
        for y in (x - 1, x + 1):
            if y != 0: new[y] = new.get(y, 0.0) + pr / 2
    dist = new; surv.append(sum(dist.values()))
print(f"{'still waiting, P(T > n)':<40}{'pushed':>12}{'formula':>12}")
for n in range(N + 1):                             # every n checked; a few printed
    if n in (0, 2, 4, 6, 8, 10, 20, 40, 60, 80, 100, 1000): row(f"  n = {n}", surv[n], u(n))
    assert abs(surv[n] - u(n)) < 1e-12, "pushed survival vs C(n, n/2) / 2^n"
row("  1 / sqrt(pi * 500), estimate at 1000", 1 / sqrt(pi * 500))
print("chart, P(T > n), n = 0 to 100 by 10:", " ".join(f"{surv[n]:.2f}" for n in range(0, 101, 10)))

# ---- the mean: capped averages E[min(T, cap)] grow without limit ----
print(f"{'capped mean E[min(T, cap)]':<40}{'tail sum':>12}{'closed':>12}{'sqrt(cap/2)':>12}")
run, tail, capped = 1.0, 0.0, {}
for n in range(0, 50000):                          # tail sum: E[min(T, 2N)] = 2 * sum of u(2n), n < N
    tail += 2 * run
    if 2 * (n + 1) in (10, 100, 1000, 10000, 100000):
        cap = 2 * (n + 1); capped[cap] = tail
        row(f"  cap = {cap}", tail, 2 * (cap - 1) * u(cap - 2), sqrt(cap / 2))
        assert abs(tail - 2 * (cap - 1) * u(cap - 2)) < 1e-9 * cap, "tail sum vs closed form"
        assert tail >= sqrt(cap / 2), "capped mean at least sqrt(cap/2), from u(2n) >= 1/(2 sqrt n)"
    run *= (2 * n + 1) / (2 * n + 2)
print("chart, capped mean, caps 10 to 100000:", " ".join(f"{capped[c]:.2f}" for c in sorted(capped)))
assert abs(sum(surv[:1000]) - capped[1000]) < 1e-9, "pushed survival summed vs formula tail sum"

# ---- road 4: first-step equations with a floor at -b; the wait for +1 is at least b ----
print(f"{'first-step equations':<40}{'solved':>12}{'formula':>12}")
row_eq("  10 chips, stop at 0 or 11: P(reach 11)", first_step(-10, 1, 0.5, 0, 1.0, 0.0, 0.0), 10 / 11)
for b in (10, 100, 1000):
    m = first_step(-b, 1, 0.5, 0, 0.0, 0.0, 1.0)
    row(f"  fair, mean rounds to +1 or -{b}", m, b * 1.0)
    assert abs(m - b) < 1e-6 * b, "first-step duration vs b * 1 from gambler's ruin"
for b in (10, 100, 1000):
    row_eq(f"  fair, P(level again before +-{b})", first_step(0, b, 0.5, 1, 0.0, 1.0, 0.0), 1 - 1 / b)
for p in (0.4, 0.6):
    q = 1 - p
    up = first_step(-400, 1, p, 0, 1.0, 0.0, 0.0)
    back = p * first_step(0, 400, p, 1, 0.0, 1.0, 0.0) + q * first_step(-400, 0, p, -1, 1.0, 0.0, 0.0)
    row_eq(f"  p = {p}: P(ever reach +1)", up, min(1.0, p / q))
    row_eq(f"  p = {p}: P(ever level again)", back, 1 - abs(p - q))
row_eq("  p = 0.4: P(ever reach +3)", first_step(-400, 3, 0.4, 0, 1.0, 0.0, 0.0), (0.4 / 0.6) ** 3)
row_eq("  p = 0.6: mean rounds to reach +1", first_step(-400, 1, 0.6, 0, 0.0, 0.0, 1.0), 1 / (0.6 - 0.4))

# ---- road 5: seeded simulation, 20000 matches, each capped at 10000 rounds ----
rng, NS, CAP = SplitMix64(20260929), 20000, 10000
t2 = over100 = 0; tot = tot2 = 0.0
for _ in range(NS):
    s, t = rng.step(), 1
    while s != 0 and t < CAP: s += rng.step(); t += 1
    t2 += t == 2; over100 += t > 100; tot += t; tot2 += t * t
mean = tot / NS; se = sqrt((tot2 / NS - mean * mean) / NS)
for name, k, f in (("P(T = 2)", t2, 0.5), ("P(T > 100)", over100, u(100))):
    ph = k / NS; sep = sqrt(ph * (1 - ph) / NS)
    print(f"sim {name:<36}{ph:>12.6f} +- {sep:.6f}  formula {f:.6f}")
    assert abs(ph - f) < 4 * sep, "simulated chance within 4 standard errors"
print(f"sim E[min(T, 10000)]{'':<20}{mean:>12.6f} +- {se:.6f}  formula {capped[10000]:.6f}")
assert abs(mean - capped[10000]) < 4 * se, "simulated capped mean within 4 standard errors"

# ---- the picture: one sample match, seed 7, the first whose return comes in rounds 10 to 24 ----
g = SplitMix64(7)
while True:
    path = [0]
    while len(path) < 25 and (len(path) == 1 or path[-1] != 0): path.append(path[-1] + g.step())
    if path[-1] == 0 and len(path) >= 11: break
print("figure, T =", len(path) - 1, "scores:", " ".join(str(x) for x in path))
print("figure, svg points:", " ".join(f"{30 + 18 * i},{50 - 20 * x}" for i, x in enumerate(path)))
print("ALL CHECKS PASS")
