# CMS spread option -- the check behind the card.  Standard library only.  Call on CMS10 - CMS2,
# strike 0, fixing in 1 year.  Roads: (1) Bachelier, (2) 2-D integral, (3) Monte Carlo; a Gaussian
# copula of two smiled margins (integral, Monte Carlo); implied rho by bisection and by Newton.
from math import exp, sqrt, pi, log, cos, sin

F1, F2, S1, S2, RHO, T, K = 0.0420, 0.0380, 0.0090, 0.0100, 0.8, 1.0, 0.0
MIX, D, NOTIONAL, bp, NZ, ZL = 0.3, 1.04 ** -2, 10_000_000, 1e4, 400, 8.0

def N(x):                                   # normal CDF from its Taylor series
    if abs(x) > 9: return 1.0 if x > 0 else 0.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + exp(-x * x / 2) / sqrt(2 * pi) * total

def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)
def bach(m, s): return m * N(m / s) + s * phi(m / s)   # call: head start m, spread s
def spread_sd(rho): return sqrt((S1 * S1 + S2 * S2 - 2 * rho * S1 * S2) * T)
def price(rho): return bach(F1 - F2 - K, spread_sd(rho))

def mix_cdf(x, f, s, k):                    # 50/50 blend of two bell curves, same centre
    a, b = s * (1 - k) * sqrt(T), s * (1 + k) * sqrt(T)
    return 0.5 * N((x - f) / a) + 0.5 * N((x - f) / b)
def mix_call(f, s, k, strike):
    return 0.5 * bach(f - strike, s * (1 - k) * sqrt(T)) + 0.5 * bach(f - strike, s * (1 + k) * sqrt(T))

def normal_vol(f, strike, target):          # Newton: Bachelier vol that matches a price
    s = 0.01
    for _ in range(50): s -= (bach(f - strike, s) - target) / phi((f - strike) / s)
    return s / sqrt(T)
Z = [-ZL + 2 * ZL * i / NZ for i in range(NZ + 1)]
W = [(1 if i in (0, NZ) else 4 if i % 2 else 2) * 2 * ZL / NZ / 3 for i in range(NZ + 1)]

def quantile_table(f, s, k):                # x with the same rank as the bell-curve score z
    half = []
    for z in Z[: NZ // 2 + 1]:
        u, lo, hi = N(z), f - 30 * s, f
        for _ in range(80):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if mix_cdf(mid, f, s, k) < u else (lo, mid)
        half.append((lo + hi) / 2)
    return half + [2 * f - x for x in reversed(half[:-1])]   # symmetric margin

def copula_price(rho, q1, q2):              # Gaussian copula, Simpson in both scores
    c, tot = 1 / (2 * pi * sqrt(1 - rho * rho)), 0.0
    for i, z1 in enumerate(Z):
        for j, z2 in enumerate(Z):
            pay = q1[i] - q2[j] - K
            if pay > 0:
                tot += W[i] * W[j] * pay * c * exp(-(z1 * z1 - 2 * rho * z1 * z2 + z2 * z2) / (2 * (1 - rho * rho)))
    return tot
def interp(q, z):
    t = (min(max(z, -ZL), ZL - 1e-12) + ZL) / (2 * ZL) * NZ
    i = int(t)
    return q[i] + (t - i) * (q[i + 1] - q[i])

def monte_carlo(q1, q2, paths=200_000, seed=20261123):
    x, M = seed, (1 << 64) - 1
    def unif():
        nonlocal x
        x ^= (x << 13) & M; x ^= x >> 7; x ^= (x << 17) & M
        return ((x >> 11) + 0.5) / 2.0 ** 53
    sn = sn2 = sc = sc2 = 0.0
    for _ in range(paths):
        r, a = sqrt(-2 * log(unif())), 2 * pi * unif()
        z1 = r * cos(a); z2 = RHO * z1 + sqrt(1 - RHO * RHO) * r * sin(a)
        pn = max(F1 + S1 * sqrt(T) * z1 - F2 - S2 * sqrt(T) * z2 - K, 0.0)
        pc = max(interp(q1, z1) - interp(q2, z2) - K, 0.0)
        sn += pn; sn2 += pn * pn; sc += pc; sc2 += pc * pc
    mn, mc = sn / paths, sc / paths
    return mn, sqrt((sn2 / paths - mn * mn) / paths), mc, sqrt((sc2 / paths - mc * mc) / paths)

def implied_by_bisection(quote):
    lo, hi = -1.0, 1.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if price(mid) > quote else (lo, mid)
    return (lo + hi) / 2
def implied_by_newton(quote):
    s = normal_vol(F1 - F2, K, quote) * sqrt(T)
    return (S1 * S1 + S2 * S2 - s * s / T) / (2 * S1 * S2)
def cms_adjustment(f, s, n):                # quick formula, normal variance s^2 T, paid 1y later
    def w(r): return (1 + r) ** -1 / sum((1 + r) ** -i for i in range(1, n + 1))
    return s * s * T * (w(f + 1e-6) - w(f - 1e-6)) / 2e-6 / w(f)

m, sd, p1 = F1 - F2 - K, spread_sd(RHO), price(RHO)
flat1, flat2 = quantile_table(F1, S1, 0.0), quantile_table(F2, S2, 0.0)
p2 = copula_price(RHO, flat1, flat2)
q1, q2 = quantile_table(F1, S1, MIX), quantile_table(F2, S2, MIX)
pc = copula_price(RHO, q1, q2)
mn, sen, mc, sec = monte_carlo(q1, q2)
rho_b, rho_n = implied_by_bisection(p1), implied_by_newton(p1)
cop_b, cop_n = implied_by_bisection(pc), implied_by_newton(pc)
vega = -T * phi(m / sd) * S1 * S2 / sd
a10, a2 = cms_adjustment(F1, S1, 10), cms_adjustment(F2, S2, 2)
print(f"spread forward, bp                     {m * bp:.2f}")
print(f"spread sd sqrt(81 + 100 - 144) bp      {sd * bp:.2f}")
print(f"d = head start / sd; N(d); phi(d)      {m / sd:.4f}  {N(m / sd):.4f}  {phi(m / sd):.4f}")
print(f"terms: m N(d) + s phi(d), bp           {m * N(m / sd) * bp:.2f}  {sd * phi(m / sd) * bp:.2f}")
print(f"1 Bachelier on the spread, bp          {p1 * bp:.4f}")
print(f"2 joint bell curve, 2-D integral, bp   {p2 * bp:.4f}")
print(f"3 Monte Carlo 200k, bp                 {mn * bp:.4f}  (se {sen * bp:.4f})")
print(f"discount D(2); today's value, bp       {D:.6f}  {p1 * D * bp:.2f}")
print(f"on $10m notional, dollars today        {p1 * D * NOTIONAL:.2f}")
print(f"correlation sensitivity, bp per 0.01   {vega * bp / 100:.4f}  {(price(RHO + 1e-4) - price(RHO - 1e-4)) / 2e-4 * bp / 100:.4f}")
vols = [normal_vol(F1, F1 + dk / bp, mix_call(F1, S1, MIX, F1 + dk / bp)) * bp for dk in (-150, -75, 0, 75, 150)]
print("10y smile, vol bp at F-150 -75 0 +75 +150  " + "  ".join(f"{v:.2f}" for v in vols))
print(f"blend sds for 10y, 2y, bp              {S1 * 0.7 * bp:.0f} {S1 * 1.3 * bp:.0f}  {S2 * 0.7 * bp:.0f} {S2 * 1.3 * bp:.0f}")
print(f"4 copula of smiled margins, bp         {pc * bp:.3f}")
print(f"5 copula Monte Carlo 200k, bp          {mc * bp:.4f}  (se {sec * bp:.4f})")
print(f"copula minus Bachelier, bp             {(pc - p1) * bp:.2f}")
print(f"implied rho from 49.33-model quote     {rho_b:.6f}  {rho_n:.6f}")
print(f"implied rho from the copula quote      {cop_b:.5f}  {cop_n:.5f}")
print(f"spread sd at that rho, bp              {spread_sd(cop_b) * bp:.2f}")
print(f"price bounds rho = +1, -1, bp          {price(1.0) * bp:.2f}  {price(-1.0) * bp:.2f}")
print("price against correlation, bp (Bachelier, copula):")
for r in (0.0, 0.4, 0.6, 0.8, 0.9, 0.95):
    print(f"  rho = {r:.2f}                            {price(r) * bp:.2f}  {copula_price(r, q1, q2) * bp:.2f}")
print(f"CMS adjustments 10y, 2y, bp            {a10 * bp:.2f}  {a2 * bp:.2f}")
print(f"wrong: rho = 0, sd; price, bp          {spread_sd(0) * bp:.2f}  {price(0) * bp:.2f}")
print(f"wrong: vols subtracted (rho = 1), bp   {price(1.0) * bp:.2f}")
print(f"wrong: unadjusted forwards, bp         {bach(m - a10 + a2, sd) * bp:.2f}")
print(f"try: strike 40 bp, bp                  {bach(0.0, sd) * bp:.2f}")
print(f"try: strike 40 bp, copula, bp          {copula_price(RHO, q1, [x + 0.0040 for x in q2]) * bp:.2f}")

assert abs(p2 - p1) < 1e-7                  # 2-D integral against the closed form
assert abs(mn - p1) < 4 * sen               # simulation against the closed form
assert abs(mc - pc) < 4 * sec               # copula simulation against copula integral
assert abs(rho_b - RHO) < 1e-9             # round trip by bisection
assert abs(rho_n - RHO) < 1e-9             # round trip by Newton on the spread sd
assert abs(cop_b - cop_n) < 1e-9            # two solvers agree on the copula quote
assert abs(vols[2] - S1 * bp) < 1e-9       # the smile keeps the quoted ATM vol
assert abs(sum(W[i] * phi(Z[i]) * max(q1[i] - F1, 0) for i in range(NZ + 1)) - mix_call(F1, S1, MIX, F1)) < 1e-8
assert abs(vega - (price(RHO + 1e-4) - price(RHO - 1e-4)) / 2e-4) < 1e-8
for f, s, n, a in ((F1, S1, 10, a10), (F2, S2, 2, a2)):   # both CMS adjustments against the exact slope of log w
    assert abs(a - s * s * T * (sum(i * (1 + f) ** -(i + 1) for i in range(1, n + 1)) / sum((1 + f) ** -i for i in range(1, n + 1)) - 1 / (1 + f))) < 1e-9
assert all(price(r) > price(r + 0.1) for r in (-0.9, 0.0, 0.5, 0.8))   # falls as rho rises
print("ALL CHECKS PASS")
