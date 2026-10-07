# The credit triangle -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Roads to the par spread:
# the triangle, the closed form for dated premiums, the two legs added up
# (Simpson's rule and a premium-date sum), and a Monte Carlo of default dates.
from math import exp, log

R, r, dl, T, M = 0.40, 0.05, 0.25, 5.0, 20          # recovery, rate, quarter, years, premium dates
L = 1.0 - R                                           # loss given default

def F(x):                                             # (e^x - 1)/x: the quarter-end delay factor
    return 1.0 if x == 0.0 else (exp(x) - 1.0) / x

def closed(lam, d=dl):                                # road 2: exact par spread, flat hazard
    return L * lam * F((r + lam) * d)

def legs(haz, knots, d=dl, n=2000):                   # road 3: add up both legs
    def w(t):                                         # discount times survival at date t
        a, prev = 0.0, 0.0
        for h, k in zip(haz, knots):
            a += h * (min(t, k) - prev); prev = k
            if t <= k: break
        return exp(-r * t - a)
    prot = cont = 0.0
    prev = 0.0
    for h, k in zip(haz, knots):                      # Simpson's rule on each flat piece
        step = (k - prev) / n
        for i in range(n + 1):
            c = (1 if i in (0, n) else (4 if i % 2 else 2)) * step / 3
            prot += c * L * h * w(prev + i * step)
            cont += c * w(prev + i * step)
        prev = k
    ann = sum(d * w(j * d) for j in range(1, round(T / d) + 1))
    return prot, ann, cont

def monte_carlo(lam, paths=4_000_000, seed=20260928):  # road 4: simulate default dates
    s = seed
    disc = [0.0]
    for j in range(1, M + 1): disc.append(disc[-1] + dl * exp(-r * j * dl))
    prot = ann = 0.0
    for _ in range(paths):
        s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF          # splitmix64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        u = ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0
        tau = -log(u) / lam
        if tau < T: prot += L * exp(-r * tau)
        ann += disc[min(M, int(tau / dl))]
    return prot / ann

def solve(s, lo=0.0, hi=1.0):                         # bisection on the closed form
    while hi - lo > 1e-14:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if closed(mid) < s else (lo, mid)
    return 0.5 * (lo + hi)

def fixed_point(s, lam):                              # seed, then correct for timing
    for it in range(1, 50):
        new = s / (L * F((r + lam) * dl))
        if abs(new - lam) < 1e-14: return new, it
        lam = new
    return lam, it

bp = 1e4
lam = 0.02
tri = L * lam
p, a, c = legs([lam], [T])
mc = monte_carlo(lam)
x = (r + lam) * dl
print("Northwind, flat 2% hazard, 40% recovery, r = 5%, 5 years")
print(f"{'triangle (1-R) lambda, bp':<38}{tri * bp:>12.4f}")
print(f"{'protection leg per $1 (Simpson)':<38}{p:>12.6f}")
print(f"{'risky annuity, quarterly (sum)':<38}{a:>12.4f}")
print(f"{'par spread, legs, bp':<38}{p / a * bp:>12.4f}")
print(f"{'par spread, closed form, bp':<38}{closed(lam) * bp:>12.4f}")
print(f"{'par spread, Monte Carlo 4e6, bp':<38}{mc * bp:>12.2f}")
print(f"{'continuous premiums, legs, bp':<38}{p / c * bp:>12.4f}")
print(f"{'timing term x = (r+lambda) delta':<38}{x:>12.4f}")
print(f"{'rule of thumb x/2, %':<38}{x / 2 * 100:>12.4f}")
print(f"{'rule of thumb 120 (1 + x/2), bp':<38}{tri * (1 + x / 2) * bp:>12.4f}")
print(f"{'premium on $10m, triangle, $':<38}{tri * 1e7:>12.2f}")
print(f"{'premium on $10m, exact, $':<38}{closed(lam) * 1e7:>12.2f}")
print(f"{'recovery, 2% with 120 / 121.06 bp, %':<38}{(1 - tri / lam) * 100:>6.4f}  {(1 - closed(lam) / lam) * 100:.4f}")
print(f"{'5-year default chance at 2%, %':<38}{(1 - exp(-5 * lam)) * 100:>12.4f}")
print()
print("300 bp quote, 40% recovery")
s3 = 0.03
seed = s3 / L
root = solve(s3)
fp, its = fixed_point(s3, seed)
corr = seed / (1 + (r + seed) * dl / 2)
print(f"{'seed s/(1-R), %':<38}{seed * 100:>12.4f}")
print(f"{'timing term x/2 at the seed, %':<38}{(r + seed) * dl / 2 * 100:>12.4f}")
print(f"{'seed with timing, %':<38}{corr * 100:>12.4f}")
print(f"{'bisection on the closed form, %':<38}{root * 100:>12.4f}")
print(f"{'fixed point from the seed, %':<38}{fp * 100:>12.4f}")
print(f"{'fixed-point steps from the seed':<38}{its:>12d}")
pr, an, _ = legs([root], [T])
print(f"{'legs re-priced at the root, bp':<38}{pr / an * bp:>12.4f}")
print(f"{'spread the seed prices at, bp':<38}{closed(seed) * bp:>12.4f}")
print(f"{'5-year default chance at root, %':<38}{(1 - exp(-5 * root)) * 100:>12.4f}")
print()
print("shelf quotes, flat hazard to each tenor: seed %, solved %")
seeds = []
for ten, q in ((1, 0.012), (3, 0.020), (5, 0.025)):
    seeds.append((q / L, solve(q)))
    print(f"{f'{ten}y {q * bp:.0f} bp':<38}{q / L * 100:>6.4f}  {solve(q) * 100:.4f}")
print()
print("error of the triangle, bp: hazard, quarterly gap, annual gap")
for h in range(1, 11):
    g1, g2 = (closed(h / 100) - L * h / 100) * bp, (closed(h / 100, 1.0) - L * h / 100) * bp
    print(f"gap {h:>2}%{'':<31}{g1:>6.2f}  {g2:.2f}")
print()
print("hazard curves, 5 years: calendar triangle, continuous, quarterly (bp)")
up = legs([0.01, 0.03], [2.0, 5.0])
dn = legs([0.03, 0.01], [2.0, 5.0])
cal_up, cal_dn = L * (0.01 * 2 + 0.03 * 3) / T, L * (0.03 * 2 + 0.01 * 3) / T
print(f"{'calendar average, rising curve, %':<38}{(0.01 * 2 + 0.03 * 3) / T * 100:>8.4f}")
print(f"{'rising 1% then 3%':<38}{cal_up * bp:>8.4f}  {up[0] / up[2] * bp:.4f}  {up[0] / up[1] * bp:.4f}")
print(f"{'falling 3% then 1%':<38}{cal_dn * bp:>8.4f}  {dn[0] / dn[2] * bp:.4f}  {dn[0] / dn[1] * bp:.4f}")
print()
print("what breaks")
print(f"{'R in place of 1-R, bp':<38}{R * lam * bp:>12.4f}")
print(f"{'300 bp divided by R, %':<38}{s3 / R * 100:>12.4f}")
print(f"{'spread read as hazard, %':<38}{s3 * 100:>12.4f}")
print(f"{'5 x 2% as 5-year default chance, %':<38}{5 * lam * 100:>12.4f}")

# asserts: each side computed a different way
assert abs(p / a - closed(lam)) < 1e-12                       # legs summed vs closed form
assert abs(mc - closed(lam)) < 0.6e-4                         # simulation vs closed form, ~3 s.e.
assert abs(p / c - tri) < 1e-12                               # continuous premiums: triangle exact
assert abs(root - fp) < 1e-12                                 # two solvers agree
assert its <= 8                                               # the seed is close
assert abs(pr / an - s3) < 1e-12                              # the root re-priced by the legs
assert 0 < closed(lam) - tri * (1 + x / 2) < tri * x * x * exp(x) / 6
assert up[0] / up[2] < cal_up                                 # a rising curve pulls the spread down
assert dn[0] / dn[2] > cal_dn                                 # a falling curve pushes it up
assert all(s0 > s1 for s0, s1 in seeds)                       # triangle seed always above the root
print("All checks passed.")
