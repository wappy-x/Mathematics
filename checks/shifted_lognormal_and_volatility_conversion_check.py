# Shifted lognormal and volatility conversion -- the check behind the card.  Standard
# library only.  Nothing imported already knows the answer: the bell-curve area is built
# from math.erf, the payoff average is Simpson's rule, the tree is a loop, inverses are
# bisection.  Rates in basis points, one bp = 0.01 percent; premiums also in dollars.
from math import log, sqrt, exp, erf, pi

BP = 1e4                                   # rates are quoted in basis points
NOTIONAL, ACCRUAL = 10_000_000.0, 0.5      # $10m of rate for half a year

def N(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))     # bell-curve area left of x
def phi(x):  return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def simpson(f, lo, hi, n):                 # Simpson's rule, written out here
    h = (hi - lo) / n
    tot = f(lo) + f(hi)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(lo + i * h)
    return tot * h / 3.0

def solve(f, target, lo, hi, iters=200):   # bisection on an increasing function
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if f(mid) < target: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def shifted(F, K, a, sigma, T, D, cp=1):
    # Road 1: slide rate and strike up by a, price with Black-76, discount.
    G, L = F + a, K + a
    if G <= 0.0: raise ValueError("the shift must lift the rate above the floor")
    if L <= 0.0: return D * (F - K) if cp > 0 else 0.0   # strike at or below the floor
    w = sigma * sqrt(T)
    d1 = (log(G / L) + 0.5 * w * w) / w
    d2 = d1 - w
    if cp > 0: return D * (G * N(d1) - L * N(d2))
    return D * (L * N(-d2) - G * N(-d1))

def bachelier(F, K, sn, T, D, cp=1):
    # The normal model: the fixing itself is bell-curved, so it may go negative.
    v = sn * sqrt(T)
    d = cp * (F - K) / v
    return D * (cp * (F - K) * N(d) + v * phi(d))

def by_integral(F, K, a, sigma, T, D, cp=1, n=20000):
    # Road 2: average the payoff over the bell curve, the kink found by bisection and used
    # as an endpoint.  No d1, no d2, nothing borrowed from road 1.
    G, w = F + a, sigma * sqrt(T)
    def fixing(z): return G * exp(-0.5 * w * w + w * z) - a
    def f(z): return max(cp * (fixing(z) - K), 0.0) * phi(z)
    z0 = solve(fixing, K, -12.0, 12.0)                   # where the fixing equals K
    lo, hi = (z0, 10.0) if cp > 0 else (-10.0, z0)
    return D * simpson(f, lo, hi, n)

def by_tree(F, K, a, sigma, T, D, steps=2000):
    # Road 3: a coin-flip tree on the distance above the floor.
    G, dt = F + a, T / steps
    u = exp(sigma * sqrt(dt)); d = 1.0 / u
    p = (1.0 - d) / (u - d)                # the slid rate is a fair bet on itself
    v = [max(G * u ** j * d ** (steps - j) - a - K, 0.0) for j in range(steps + 1)]
    for step in range(steps, 0, -1):
        v = [p * v[j + 1] + (1.0 - p) * v[j] for j in range(step)]
    return D * v[0]

# ---- the trade: a one-year rate quoted at 50 bp, floor at -200 bp, 30 pct vol ----
F, K, K0, a, sigma, T, r = 0.005, 0.005, 0.0, 0.02, 0.30, 1.0, 0.005
D, G, L, w = exp(-r * T), F + a, K + a, sigma * sqrt(T)
d1 = (log(G / L) + 0.5 * w * w) / w; d2 = d1 - w
C, C_int, C_tree = shifted(F, K, a, sigma, T, D), by_integral(F, K, a, sigma, T, D), by_tree(F, K, a, sigma, T, D)
# ---- the floor struck at zero: the contract Black-76 prices at nothing ----
P0, P0_int = shifted(F, K0, a, sigma, T, D, -1), by_integral(F, K0, a, sigma, T, D, -1)
C0, P0_black = shifted(F, K0, a, sigma, T, D), shifted(F, K0, 0.0, sigma, T, D, -1)
# ---- the conversion at the money, its series, and the reverse direction ----
sn = G * sqrt(2.0 * pi / T) * (2.0 * N(w / 2.0) - 1.0)
sn_solved = solve(lambda x: bachelier(F, K, x, T, D), C, 1e-9, 1.0)
napkin, corrected, bound = G * sigma, G * sigma * (1.0 - w * w / 24.0), G * sigma * w ** 4 / 640.0
R_int, R_exact = simpson(lambda u: exp(-w * w * u * u / 8.0), 0.0, 1.0, 2000), sn / (G * sigma)
sn_quote = 0.0060
eta = sn_quote * sqrt(T) / (G * sqrt(2.0 * pi))
sig_inv = 2.0 / sqrt(T) * solve(N, 0.5 * (1.0 + eta), -10.0, 10.0)
prem_norm = bachelier(F, K, sn_quote, T, D)
sig_solved = solve(lambda x: shifted(F, K, a, x, T, D), prem_norm, 1e-9, 5.0)
prem_at_sig, ceiling = shifted(F, K, a, sig_inv, T, D), G * sqrt(2.0 * pi / T)
gaps = [shifted(F, K, big, sn / (F + big), T, D) - bachelier(F, K, sn, T, D) for big in (1.0, 10.0)]
# ---- what breaks, two things to try, and the shelf's house market at a = 0 ----
w_noslide, w_shift100 = D * (F + a - K), shifted(F, K, 0.01, sigma, T, D)
w_noshift, mean_nodrag = shifted(F, K, 0.0, sigma, T, D), G * exp(0.5 * w * w) - a
w_nodrag, t_vol40 = shifted(mean_nodrag, K, a, sigma, T, D), shifted(F, K, a, 0.40, T, D)
t_shift500 = shifted(F, K, 0.05, sigma, T, D)
C_house = shifted(100.0 * exp(0.03), 100.0, 0.0, 0.20, 1.0, exp(-0.05))
print(f"the rate F {F * BP:.6f} bp, the strike K {K * BP:.6f} bp, the shift a {a * BP:.6f} bp")
print(f"slid rate G {G * BP:.6f} bp, slid strike L {L * BP:.6f} bp, w {w:.6f}, D {D:.6f}")
print(f"d1 {d1:.6f}, d2 {d2:.6f}, N(d1) {N(d1):.6f}, N(d2) {N(d2):.6f}")
rows = [
    ("1 formula, at-the-money premium, bp", C * BP), ("2 payoff averaged over the bell curve, bp", C_int * BP),
    ("3 tree on the slid rate, 2000 steps, bp", C_tree * BP), ("  the premium in dollars", C * NOTIONAL * ACCRUAL),
    ("4 floor struck at 0 bp, shifted put, bp", P0 * BP), ("  the same put by the payoff average, bp", P0_int * BP),
    ("  in dollars", P0 * NOTIONAL * ACCRUAL), ("  call minus put at 0 bp, bp", (C0 - P0_int) * BP),
    ("  D times (F - K) at K = 0, bp", D * (F - K0) * BP), ("5 Black-76, no shift, floor at 0 bp, bp", P0_black * BP),
    ("6 normal vol matching 30 pct at 200 bp, bp", sn * BP), ("  the same by bisection on the normal price", sn_solved * BP),
    ("  napkin rule, G times sigma, bp", napkin * BP), ("  corrected, G sigma (1 - w^2/24), bp", corrected * BP),
    ("  error bound, G sigma w^4/640, bp", bound * BP), ("  R(w) by integrating exp(-w^2u^2/8)", R_int),
    ("  R(w) from the exact conversion", R_exact), ("7 lognormal vol matching 60 bp, pct", sig_inv * 100.0),
    ("  the same by bisection on the price, pct", sig_solved * 100.0), ("  shifted premium at that vol, bp", prem_at_sig * BP),
    ("  normal premium at 60 bp, bp", prem_norm * BP), ("  highest normal vol a 200 bp shift meets, bp", ceiling * BP),
    ("8 the 30 pct quote, as normal vol, bp", sn * BP), ("  the gap between the two quotes, dollars", (C - prem_norm) * NOTIONAL * ACCRUAL),
    ("9 Bachelier limit, shift 10000 bp, gap in bp", gaps[0] * BP), ("  Bachelier limit, shift 100000 bp, gap in bp", gaps[1] * BP),
    ("wrong: the strike not slid with the rate, bp", w_noslide * BP), ("wrong: the 30 pct vol at a 100 bp shift, bp", w_shift100 * BP),
    ("wrong: the 30 pct vol at no shift at all, bp", w_noshift * BP), ("wrong: no drag, mean fixing, bp", mean_nodrag * BP),
    ("wrong: no drag, premium, bp", w_nodrag * BP), ("try: sigma = 40 pct, bp", t_vol40 * BP),
    ("try: shift 500 bp, vol left at 30 pct, bp", t_shift500 * BP), ("house market at a = 0, the Acme call", C_house)]
for name, v in rows: print(f"{name:<46}{v:>14.6f}")
pairs = []
for sh in (0.01, 0.02, 0.03, 0.05, 0.10):
    v = solve(lambda x: shifted(F, K, sh, x, T, D), C, 1e-9, 5.0)
    pairs.append((sh, v, (F + sh) * v, shifted(F, K, sh, v, T, D), shifted(F, K0, sh, v, T, D, -1)))
print(f"\none premium of {C * BP:.6f} bp, five shifts, each vol re-solved:")
for sh, v, wob, atm, fl in pairs:
    print(f"  shift {sh * BP:>5.0f} bp  vol {v * 100:>5.2f} pct  wobble {wob * BP:>5.2f} bp  at the money {atm * BP:.6f} bp  floor at 0 bp {fl * BP:>5.2f} bp")
strikes = [-0.015, -0.010, -0.005, 0.0, 0.005, 0.010, 0.015]
print("\nfloor premiums by strike, in bp of notional")
print(f"{'strike, bp':<36}" + "".join(f"{k * BP:>8.0f}" for k in strikes))
for label, fn in (("shifted, 30 pct at a 200 bp shift", lambda k: shifted(F, k, a, sigma, T, D, -1)),
                  ("Bachelier, at the matched normal vol", lambda k: bachelier(F, k, sn, T, D, -1)),
                  ("Black-76, no shift", lambda k: shifted(F, k, 0.0, sigma, T, D, -1))):
    print(f"{label:<36}" + "".join(f"{fn(k) * BP:>8.2f}" for k in strikes))
assert abs(C_int - C) < 1e-13,                    "the payoff average must land on the formula"
assert abs(C_tree - C) < 1e-6,                    "the tree must land within a bp's hundredth"
assert abs(C0 - P0_int - D * (F - K0)) < 1e-15,   "parity, with the put priced on its own"
assert P0_black == 0.0 and P0 > 8e-4,             "Black-76 gives a floor at zero nothing"
assert abs(sn - sn_solved) < 1e-12,               "exact conversion against bisection"
assert corrected <= sn <= corrected + bound,      "the series bound, on both sides"
assert abs(R_int - R_exact) < 1e-12,              "the integral form of R(w)"
assert abs(prem_at_sig - prem_norm) < 1e-12,      "the inverted vol reprices the quote"
assert abs(sig_inv - sig_solved) < 1e-9,          "two roads to the inverse vol"
assert abs(C_house - 9.227005508154) < 1e-9,      "the shelf's house call, at a = 0"
assert abs(gaps[1]) < 0.15 * abs(gaps[0]),        "the shift dial reaches Bachelier"
assert all(abs(p[3] - C) < 1e-12 for p in pairs), "every pair reproduces the one quote"
assert all(pairs[i][1] > pairs[i + 1][1] for i in range(4)), "a smaller shift needs a bigger vol"
assert max(p[4] for p in pairs) > 1.4 * min(p[4] for p in pairs), "a second strike separates them"
print("ALL CHECKS PASS")
