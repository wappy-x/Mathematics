# Implied hazard from a bond price, and the CDS-bond basis -- the check behind the card.
# Standard library only; nothing imported knows the answer.  Northwind: five-year bond,
# coupon 6 a year on 100 face, 40% of face recovered at the moment of default, coupons
# stop at default, riskless rate 5% flat and continuous.  CDS: quarterly premiums, no accrual.
from math import exp, sqrt, log

F, C, R, r, T = 100.0, 6.0, 0.40, 0.05, 5
YEARS = range(1, T + 1)

def simpson(f, a, b, n=40):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def bond_sum(lam):                           # road 1: legs term by term, recovery leg by Simpson
    alive = sum(C * exp(-(r + lam) * t) for t in YEARS) + F * exp(-(r + lam) * T)
    return alive + sum(simpson(lambda s: R * F * lam * exp(-(r + lam) * s), t - 1, t) for t in YEARS)
def bond(lam, c=C, rec=R, rr=r):             # road 2: the closed form on the card
    u = rr + lam
    return sum(c * exp(-u * t) for t in YEARS) + F * exp(-u * T) + rec * F * lam / u * (1 - exp(-u * T))

def bond_slope(lam):                         # its derivative, worked out by hand
    u = r + lam
    return (-sum(C * t * exp(-u * t) for t in YEARS) - F * T * exp(-u * T)
            + R * F * (r / u ** 2 * (1 - exp(-u * T)) + lam / u * T * exp(-u * T)))

def bisect(f, lo, hi, n=60):                 # needs f(lo) > 0 > f(hi)
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)
def newton(price, lam=0.0, steps=6):         # from zero: the price curve is convex, so no overshoot
    path = [lam]
    for _ in range(steps):
        lam -= (bond(lam) - price) / bond_slope(lam)
        path.append(lam)
    return path
def cash_price(z, c=C):                      # promised cash flows discounted at the curve plus z
    return sum(c * exp(-(r + z) * t) for t in YEARS) + F * exp(-(r + z) * T)
def zspread(price, c=C): return bisect(lambda z: cash_price(z, c) - price, -0.05, 1.0)

def z_newton(price, y=0.05):                 # road B for z: Newton on the continuous yield, then y - r
    for _ in range(30):
        p = sum(C * exp(-y * t) for t in YEARS) + F * exp(-y * T)
        y -= (p - price) / (-sum(C * t * exp(-y * t) for t in YEARS) - F * T * exp(-y * T))
    return y - r
def cds_par(lam):                            # CDS legs term by term (not the closed form)
    ann = sum(0.25 * exp(-(r + lam) * 0.25 * j) for j in range(1, 21))
    return simpson(lambda s: (1 - R) * lam * exp(-(r + lam) * s), 0.0, 5.0, 400) / ann, ann

def cds_closed(lam):                         # the credit-triangle card's form, with its timing factor
    x = (r + lam) * 0.25
    return (1 - R) * lam * (exp(x) - 1) / x

HOUSE, QUOTE = 98.28, 97.00
S_CDS = cds_closed(0.02)                     # the CDS quote: exactly what a 2% hazard gives
lam_house = bisect(lambda l: bond_sum(l) - HOUSE, 0.0, 1.85)
lam_bond = bisect(lambda l: bond_sum(l) - QUOTE, 0.0, 1.85)
path = newton(QUOTE)
lam_cds = bisect(lambda l: S_CDS - cds_par(l)[0], 0.0, 1.0)
z_house, z_bond = zspread(HOUSE), zspread(QUOTE)

def row(label, v, d=4): print(f"{label:<42} {v:.{d}f}")
row("risk-free price, hazard 0", bond(0.0))
row("house price at 2%, closed form", bond(0.02))
row("house price at 2%, legs by Simpson", bond_sum(0.02))
row("slope of price at 2%, per unit hazard", bond_slope(0.02))
print(f"house legs at 2%: coupons {sum(C * exp(-0.07 * t) for t in YEARS):.4f}  face {F * exp(-0.35):.4f}  recovery {R * F * 0.02 / 0.07 * (1 - exp(-0.35)):.4f}")
row("hand estimate from 2% with the slope (%)", 100 * (0.02 - (bond(0.02) - QUOTE) / bond_slope(0.02)))
row("hazard from 98.28, bisection (%)", 100 * lam_house)
row("hazard from 97, road 1 bisection (%)", 100 * lam_bond)
row("hazard from 97, road 2 Newton (%)", 100 * path[-1])
print("Newton path from 0 (%)  " + " ".join(f"{100 * x:.4f}" for x in path[:5]))
row("CDS quote at 2%, closed form (bp)", 1e4 * S_CDS)
row("CDS par at 2%, legs term by term (bp)", 1e4 * cds_par(0.02)[0])
row("CDS risky annuity at 2%", cds_par(0.02)[1])
row("hazard from the CDS quote (%)", 100 * lam_cds)
row("z-spread at 98.28 (bp)", 1e4 * z_house)
row("z-spread at 97, bisection (bp)", 1e4 * z_bond)
row("z-spread at 97, yield Newton (bp)", 1e4 * z_newton(QUOTE))
row("basis at 98.28, CDS - z (bp)", 1e4 * (S_CDS - z_house))
row("basis at 97, CDS - z (bp)", 1e4 * (S_CDS - z_bond))
row("hazard gap x (1-R) at 97 (bp)", 1e4 * (1 - R) * (lam_cds - lam_bond))
row("funding spread that prices 97 at 2% (bp)", 1e4 * bisect(lambda f: bond(0.02, rr=r + f) - QUOTE, 0, 0.05))

def package(tau):                            # basis trade worth today if default comes at tau (99: never)
    cpn = sum(C * exp(-r * t) for t in YEARS if t < tau)
    prem = sum(S_CDS * F * 0.25 * exp(-r * 0.25 * j) for j in range(1, 21) if 0.25 * j < tau)
    return cpn - prem + F * exp(-r * min(tau, T)) - QUOTE   # 40 bond + 60 CDS at default, or the face
exp_pkg = sum(simpson(lambda s: 0.02 * exp(-0.02 * s) * package(s), (k - 1) / 8 + 1e-12, k / 8 - 1e-12, 8)
              for k in range(1, 41)) + exp(-0.02 * T) * package(99.0)
for label, tau in (("immediately", 1e-9), ("at 0.999 years", 0.999), ("at 1.001 years", 1.001),
                   ("at 4.999 years", 4.999), ("never", 99.0)):
    row("package value, default " + label, package(tau))
row("package, expected at 2%, by default time", exp_pkg)
row("package, expected at 2%, B(2%) - 97", bond(0.02) - QUOTE)

seed = 20260928                              # road 3: simulate default times, reprice the bond
def uniform():
    global seed
    seed = (6364136223846793005 * seed + 1442695040888963407) % 2 ** 64
    return ((seed >> 11) + 0.5) / 2 ** 53
n, tot, tot2 = 200000, 0.0, 0.0
for _ in range(n):
    tau = -log(uniform()) / lam_bond
    v = sum(C * exp(-r * t) for t in YEARS if t < tau) + (R * F * exp(-r * tau) if tau < T else F * exp(-r * T))
    tot, tot2 = tot + v, tot2 + v * v
mc = tot / n
se = sqrt((tot2 / n - mc * mc) / n)
row("road 3 simulated price at that hazard", mc, 3)
row("  its standard error", se, 3)

lam_g = bisect(lambda l: 3.0 - (exp(r + l) - 1) / (r + l), 0.0, 5.0)   # where R F r g(u) reaches the coupon
falls = all(bond(lam_g * (k + 1) / 4000) < bond(lam_g * k / 4000) for k in range(4000))
tail = max(bond(lam_g + 0.01 * k) for k in range(1, 10001))
low = min((bond(0.01 * k), k) for k in range(1, 2001))
row("proof reaches hazard (%)", 100 * lam_g, 2)
row("price there", bond(lam_g))
row("highest price beyond it, to 10,000%", tail)
print(f"{'lowest price anywhere, and its hazard (%)':<42} {low[0]:.4f} at {low[1]}")
print("chart, hazard (%)      " + " ".join(f"{k:7d}" for k in range(11)))
print("chart, bond price      " + " ".join(f"{bond(k / 100):7.2f}" for k in range(11)))
print("chart, quoted price    " + " ".join(f"{p:7d}" for p in range(94, 101)))
print("chart, basis (bp)      " + " ".join(f"{1e4 * (S_CDS - zspread(p)):7.2f}" for p in range(94, 101)))
for cc in (2.0, 4.0, 6.0, 8.0, 10.0):        # same 2% hazard, different coupons
    zc = zspread(bond(0.02, cc), cc)
    print(f"coupon {cc:4.1f}: price {bond(0.02, cc):7.2f}  z {1e4 * zc:7.2f} bp  basis {1e4 * (S_CDS - zc):6.2f} bp")
row("wrong: recovery 0, hazard from 97 (%)", 100 * bisect(lambda l: bond(l, rec=0.0) - QUOTE, 0, 1))
row("wrong: hazard gap without (1-R) (bp)", 1e4 * (lam_cds - lam_bond))
row("try: recovery 25%, hazard from 97 (%)", 100 * bisect(lambda l: bond(l, rec=0.25) - QUOTE, 0, 1))
row("try: price 96, hazard (%)", 100 * bisect(lambda l: bond(l) - 96.0, 0, 1))
row("try: price 96, basis (bp)", 1e4 * (S_CDS - zspread(96.0)))

assert abs(lam_house - 0.02) < 1e-4, "98.28 must solve back to 2%"
assert abs(lam_bond - path[-1]) < 1e-10, "bisection on Simpson legs vs Newton on the closed form"
assert abs(z_bond - z_newton(QUOTE)) < 1e-12, "z-spread two ways"
assert abs(cds_par(0.02)[0] - S_CDS) < 1e-9, "CDS legs term by term vs closed form"
assert abs(mc - QUOTE) < 4 * se, "simulated price at the implied hazard must be 97"
assert abs(exp_pkg - (bond(0.02) - QUOTE)) < 1e-6, "basis trade value two ways"
assert falls, "price must fall strictly up to the proof's reach"
assert tail < bond(lam_g), "beyond it the price never climbs back"
print("ALL CHECKS PASS")
