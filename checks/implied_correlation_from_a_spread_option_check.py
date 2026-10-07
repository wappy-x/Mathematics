# Implied correlation from a spread option -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series, the root finders, the integrator
# and the random numbers are written out here.
from math import log, sqrt, exp, pi, cos, sin, atanh, tanh
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)       # bell-curve height at x
def N(x):                                # bell-curve area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total
def black(F, K, w):                      # undiscounted Black call, total swing w = vol * sqrt(T)
    if w < 1e-12: return max(F - K, 0.0)
    a = (log(F / K) + 0.5 * w * w) / w
    return F * N(a) - K * N(a - w)
F1, F2, s1, s2, T, r = 100.0, 90.0, 0.30, 0.25, 0.5, 0.05   # gasoline, crude, their vols, six months, 5%
D = exp(-r * T)
def spread_vol(rho, a=s1, b=s2): return sqrt(max(a * a + b * b - 2 * rho * a * b, 0.0))
def margrabe(rho, a=s1, b=s2): return D * black(F1, F2, spread_vol(rho, a, b) * sqrt(T))
def kirk(rho, K):                        # Kirk: crude plus strike treated as one lognormal leg
    b = F2 / (F2 + K); v = sqrt(max(s1 * s1 - 2 * rho * s1 * s2 * b + s2 * s2 * b * b, 0.0))
    return D * black(F1, F2 + K, v * sqrt(T))
def by_integral(rho, K=0.0, n=2000):     # road 4: fix crude's shock z; gasoline is then lognormal
    a, bb = -8.0, 8.0; h = (bb - a) / n; st = sqrt(T)
    def f(z):
        crude = F2 * exp(-0.5 * s2 * s2 * T + s2 * st * z)
        gas = F1 * exp(-0.5 * rho * rho * s1 * s1 * T + rho * s1 * st * z)
        return black(gas, crude + K, s1 * sqrt(max(1 - rho * rho, 0.0)) * st) * phi(z)
    tot = f(a) + f(bb) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return D * tot * h / 3.0
def bisect(price, quote, lo=-1.0, hi=1.0, steps=50):   # price falls as rho rises
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if price(mid) > quote: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def implied_rho(quote, price=margrabe):  # refuse quotes outside [price at +1, price at -1]
    if not price(1.0) <= quote <= price(-1.0): return None
    return bisect(price, quote)
def corr_vega(rho):                      # dC/drho = vega times dsigma/drho = -vega s1 s2 / sigma
    v = spread_vol(rho); a = (log(F1 / F2) + 0.5 * v * v * T) / (v * sqrt(T))
    return -D * F1 * phi(a) * sqrt(T) * s1 * s2 / v
Q = round(margrabe(0.5), 6)              # the screen quote, to six decimals
print("house crack: gasoline 100, crude 90, vols 30% and 25%, six months, 5%")
rows = [("discount D", D), ("floor D (F1 - F2)", D * (F1 - F2)),
        ("spread vol at rho 0.5", spread_vol(0.5)), ("quote = Margrabe at rho 0.5", Q),
        ("price at rho +1 (lowest)", margrabe(1.0)), ("  same by integral", by_integral(1.0, n=20000)),
        ("price at rho -1 (highest)", margrabe(-1.0)), ("  same by integral", by_integral(-1.0, n=20000))]
r1 = implied_rho(Q)
vimp = bisect(lambda v: D * black(F1, F2, v * sqrt(T)), Q, 1.0, 1e-9, 60)   # price rises with vol
r2 = (s1 * s1 + s2 * s2 - vimp * vimp) / (2 * s1 * s2)
x, its = 0.0, 0
while its < 50:
    its += 1; step = (margrabe(x) - Q) / corr_vega(x); x -= step
    if abs(step) < 1e-13: break
r4 = implied_rho(Q, by_integral)
cv, bump = corr_vega(0.5), (margrabe(0.501) - margrabe(0.499)) / 0.002
rows += [("1 implied rho, bisection", r1), ("  implied spread vol", vimp), ("2 rho from the spread vol", r2),
         ("3 implied rho, Newton from 0", x), ("  Newton steps", its), ("4 implied rho, integral price", r4),
         ("corr vega dC/drho at 0.5", cv), ("  same by bump", bump), ("rho moved by a 0.01 price error", 0.01 / abs(cv))]
w5 = spread_vol(0.5) * sqrt(T); a5 = (log(F1 / F2) + 0.5 * w5 * w5) / w5
rows += [("d1 at rho 0.5", a5), ("d2 = d1 - sigma sqrt T", a5 - w5), ("N(d1)", N(a5)), ("N(d2)", N(a5 - w5))]
for name, v in rows: print(f"  {name:<32} {v:>11.6f}")
print(f"  by hand: s1^2 + s2^2 {s1*s1 + s2*s2:.6f}   2 s1 s2 {2*s1*s2:.6f}   vimp^2 {vimp*vimp:.6f}")
print(f"  spread vol can run from |s1 - s2| {abs(s1 - s2):.6f} to s1 + s2 {s1 + s2:.6f}")
txt = lambda v: "none" if v is None else f"{v:.6f}"
print(f"  quote 20.00: rho {txt(implied_rho(20.0))}    quote 9.70: rho {txt(implied_rho(9.70))}")
print("\nchart: price against correlation, quote lines 13.15 and 20.00")
grid = [-1.0 + 0.25 * i for i in range(9)]
print("  rho    " + " ".join(f"{g:6.2f}" for g in grid))
print("  price  " + " ".join(f"{margrabe(g):6.2f}" for g in grid))
state = [20260927]
def unif():                              # 64-bit linear congruential generator
    state[0] = (6364136223846793005 * state[0] + 1442695040888963407) % 2**64
    return ((state[0] >> 11) + 0.5) / 2**53
def pair():                              # Box-Muller: two independent normals
    u1, u2 = unif(), unif(); rad = sqrt(-2 * log(u1))
    return rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)
def pay(z1, z2):                         # the spread's payoff for one pair of shocks, at rho 0.5
    w2 = 0.5 * z1 + sqrt(0.75) * z2
    return max(F1 * exp(-0.5 * s1 * s1 * T + s1 * sqrt(T) * z1) - F2 * exp(-0.5 * s2 * s2 * T + s2 * sqrt(T) * w2), 0.0)
paths, tot, tot2 = 500000, 0.0, 0.0     # road 5: simulate both futures, each draw used twice (z and -z)
for _ in range(paths):
    z1, z2 = pair(); p = 0.5 * (pay(z1, z2) + pay(-z1, -z2)); tot += p; tot2 += p * p
mc = D * tot / paths; se = D * sqrt(tot2 / paths - (tot / paths) ** 2) / sqrt(paths)
print(f"\nsimulation, {paths} mirrored pairs: price {mc:.6f}  std error {se:.6f}  implied rho {implied_rho(mc):.6f}")
days, true_rho, dt = 126, 0.70, 1.0 / 252          # a six-month history of daily moves
state[0] = 777; xs, ys = [], []
for _ in range(days):
    z1, z2 = pair()
    xs.append(s1 * sqrt(dt) * z1); ys.append(s2 * sqrt(dt) * (true_rho * z1 + sqrt(1 - true_rho ** 2) * z2))
mx, my = sum(xs) / days, sum(ys) / days
sxy = sum((a - mx) * (b - my) for a, b in zip(xs, ys))
sxx = sum((a - mx) ** 2 for a in xs); syy = sum((b - my) ** 2 for b in ys)
rr = sxy / sqrt(sxx * syy); half = 1.96 / sqrt(days - 3)
lo, hi = tanh(atanh(rr) - half), tanh(atanh(rr) + half)
print(f"realised, {days} days drawn at rho {true_rho:.2f}: vols {sqrt(sxx/(days-1)/dt):.4f} {sqrt(syy/(days-1)/dt):.4f}  rho {rr:.4f}  95% band {lo:.4f} to {hi:.4f}")
print(f"  price at realised rho {margrabe(rr):.6f}   quote minus that {Q - margrabe(rr):.6f}")
print("\nimplied rho from the same quote, by the vols assumed (gasoline down, crude across)")
print("  gas \\ crude    0.23      0.25      0.27")
for a in (0.26, 0.28, 0.30, 0.32, 0.34):
    print(f"  {a:.2f}      " + "  ".join(f"{(a*a + b*b - vimp*vimp) / (2*a*b):8.4f}" for b in (0.23, 0.25, 0.27)))
need = (0.55 ** 2 + s2 * s2 - vimp * vimp) / (2 * 0.55 * s2)
print(f"  gasoline vol 0.55: rho needed {need:.4f}, solver says {txt(implied_rho(Q, lambda p: margrabe(p, 0.55)))}")
KQ = round(kirk(0.5, 10.0), 6)
rk, rx = implied_rho(KQ, lambda p: kirk(p, 10.0)), implied_rho(KQ, lambda p: by_integral(p, 10.0))
print(f"\nstrike 10: Kirk quote {KQ:.6f}  rho by Kirk {rk:.6f}  rho by exact integral {rx:.6f}")
print("\nwhat breaks")
und = bisect(lambda p: black(F1, F2, spread_vol(p) * sqrt(T)), Q)
wrong = [("no 2 on the cross term", (s1 * s1 + s2 * s2 - vimp * vimp) / (s1 * s2)),
         ("plus sign on the cross term", (vimp * vimp - s1 * s1 - s2 * s2) / (2 * s1 * s2)),
         ("forgot the discount D", und), ("quote 20.00, bare solver", bisect(margrabe, 20.0))]
for name, v in wrong: print(f"  {name:<32} {v:>11.6f}")
assert abs(r1 - 0.5) < 1e-6 and abs(r2 - r1) < 1e-6 and abs(x - r1) < 1e-9, "three roads on Margrabe"
assert abs(r4 - r1) < 1e-6, "a price built without Margrabe gives the same correlation"
assert abs(by_integral(-1.0, n=20000) - margrabe(-1.0)) < 1e-4 and abs(by_integral(1.0, n=20000) - margrabe(1.0)) < 1e-4, "bounds by two roads"
assert abs(mc - Q) < 3 * se, "simulated spread payoff matches the quote within noise"
assert abs(cv - bump) < 1e-4 and cv < 0, "correlation vega by formula and by bump, and negative"
assert implied_rho(20.0) is None and implied_rho(9.70) is None and need > 1, "no correlation outside the range"
assert lo < true_rho < hi, "realised band covers the correlation the history was drawn with"
print("ALL CHECKS PASS")
