# Options on a CDS: Black on the forward spread, risky annuity as the unit. Standard library only.
# Nothing imported knows the answer: normal CDF, integrator, root finder and random numbers are written out.
from math import exp, log, sqrt, cos, pi

RATE, LOSS, KNOTS = 0.05, 0.60, [0.0, 1.0, 3.0, 5.0]     # riskless rate; loss = 1 - recovery 40%
QUOTES = [0.0120, 0.0200, 0.0250]                         # Northwind CDS at 1, 3, 5 years
TE, K, VOL = 1.0, 0.0250, 0.50                            # expiry, strike spread, spread volatility

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def N(x): return 0.0 if x < -12 else 1.0 if x > 12 else 0.5 + simpson(phi, 0.0, x, 2000)
def bisect(f, lo, hi, n=100):                             # f rises through zero between lo and hi
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return 0.5 * (lo + hi)

def surv(t, lam):                                         # survival to t under the step hazard
    area = 0.0
    for i, h in enumerate(lam):
        right = KNOTS[i + 1] if i + 1 < len(lam) else float("inf")
        area += h * max(0.0, min(t, right) - KNOTS[i])
    return exp(-area)
def annuity(a, b, lam):                                   # risky annuity: quarters in (a, b], paid if alive
    return sum(0.25 * exp(-RATE * j / 4) * surv(j / 4, lam) for j in range(round(4 * a) + 1, round(4 * b) + 1))
def prot(a, b, lam):                                      # protection on (a, b], exact on each flat piece
    total, edges = 0.0, sorted(set([a, b] + [k for k in KNOTS[1:len(lam)] if a < k < b]))
    for lo, hi in zip(edges, edges[1:]):
        h = lam[min([i for i in range(len(lam)) if KNOTS[i] <= lo][-1], len(lam) - 1)]
        total += LOSS * exp(-RATE * lo) * surv(lo, lam) * h / (RATE + h) * (1 - exp(-(RATE + h) * (hi - lo)))
    return total
def bootstrap(quotes):
    lam = []
    for i, s in enumerate(quotes):
        lam.append(bisect(lambda h: prot(0, KNOTS[i + 1], lam + [h]) - s * annuity(0, KNOTS[i + 1], lam + [h]), 0.0, 1.0))
    return lam
def black(F, K, v, A):                                    # knock-out payer and receiver, per unit notional
    d1 = (log(F / K) + 0.5 * v * v * TE) / (v * sqrt(TE)); d2 = d1 - v * sqrt(TE)
    return A * (F * N(d1) - K * N(d2)), A * (K * N(-d2) - F * N(-d1)), d1, d2
def option_on(quotes):                                    # re-bootstrap, then the knock-out payer
    lam = bootstrap(quotes); A = annuity(TE, 5, lam)
    return black(prot(TE, 5, lam) / A, K, VOL, A)[0]

lam = bootstrap(QUOTES)                                   # ---- road A: closed-form legs ----
A, P = annuity(TE, 5, lam), prot(TE, 5, lam)
F = P / A
FEP = LOSS * exp(-RATE * TE) * (1 - surv(TE, lam))       # loss on default before expiry, settled at expiry
dens = lambda t, h: LOSS * exp(-RATE * t) * surv(t, lam) * h                     # road B: protection by Simpson
P_simp = simpson(lambda t: dens(t, lam[1]), 1, 3, 200) + simpson(lambda t: dens(t, lam[2]), 3, 5, 200)
state = 20260928                                          # road C: simulated default dates, own generator
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
n_def, sA = 400000, [0.0, 0.0, 0.0]
for _ in range(n_def):
    e, tau = -log(unif()), 99.0
    for i, h in enumerate(lam):
        width = KNOTS[i + 1] - KNOTS[i] if i < 2 else 99.0
        if e <= h * width: tau = KNOTS[i] + e / h; break
        e -= h * width
    sA[0] += sum(0.25 * exp(-RATE * j / 4) for j in range(5, 21) if tau > j / 4)
    sA[1] += LOSS * exp(-RATE * tau) if 1 < tau <= 5 else 0.0
    sA[2] += LOSS * exp(-RATE * TE) if tau <= 1 else 0.0
A_mc, P_mc, FEP_mc = (x / n_def for x in sA)
p1 = 1 - surv(TE, lam); se_fep = LOSS * exp(-RATE) * sqrt(p1 * (1 - p1) / n_def)

pay, rec, d1, d2 = black(F, K, VOL, A)                    # ---- the option, three roads ----
sd = VOL * sqrt(TE)
payoff = lambda z, c: max(c * (F * exp(-0.5 * sd * sd + sd * z) - K), 0.0) * phi(z)
pay_int = A * simpson(lambda z: payoff(z, 1), -10, 10, 4000)
rec_int = A * simpson(lambda z: payoff(z, -1), -10, 10, 4000)
mc = 0.0
for _ in range(200000):
    u1, u2 = unif(), unif(); z = sqrt(-2 * log(u1)) * cos(2 * pi * u2)
    mc += 0.5 * sum(max(F * exp(-0.5 * sd * sd + sd * y) - K, 0.0) for y in (z, -z))
pay_mc = A * mc / 200000
delta, vega = A * N(d1), A * F * phi(d1) * sqrt(TE)       # Greeks, annuity held fixed
delta_b = (black(F + 1e-6, K, VOL, A)[0] - black(F - 1e-6, K, VOL, A)[0]) / 2e-6
vega_b = (black(F, K, VOL + 1e-5, A)[0] - black(F, K, VOL - 1e-5, A)[0]) / 2e-5
curve_d = (option_on([q + 1e-4 for q in QUOTES]) - option_on([q - 1e-4 for q in QUOTES])) / 2
lo_b, hi_b = A * max(F - K, 0), A * F                     # Black's price range for this F, K, A
iv_bis = bisect(lambda v: black(F, K, v, A)[0] - pay, 1e-4, 5.0)
v = 0.30                                                  # Newton from 30%
for _ in range(8): v -= (black(F, K, v, A)[0] - pay) / (A * F * phi(black(F, K, v, A)[2]) * sqrt(TE))
iv_bad = bisect(lambda v: black(F, K, v, A)[0] - (pay + FEP), 1e-4, 5.0)
iv_low = bisect(lambda v: black(F, K, v, A)[0] - 0.0120, 1e-4, 5.0)

def spot_cds(S):                                          # at expiry: flat hazard for a 4y spread S, its annuity
    h = bisect(lambda x: prot(0, 4, [x]) - S * annuity(0, 4, [x]), 0.0, 1.0, 60)
    return annuity(0, 4, [h])
Ars = sum(0.25 * exp(-RATE * j / 4) for j in range(5, 21))
pc = lambda x: f"{100 * x:.6f}"
rows = [("hazard pieces 0-1, 1-3, 3-5y", " ".join(f"{h:.6f}" for h in lam)), ("Q(1) survival to expiry, D(1)", f"{surv(1, lam):.6f} {exp(-RATE * TE):.6f}"),
        ("forward risky annuity A, closed", f"{A:.6f}"), ("  by simulated defaults", f"{A_mc:.6f}"),
        ("forward protection leg %, closed", pc(P)), ("  by Simpson", pc(P_simp)), ("  by simulated defaults", pc(P_mc)),
        ("forward spread F bp", f"{1e4 * F:.4f}"), ("  by simulated defaults", f"{1e4 * P_mc / A_mc:.4f}"),
        ("ln(F/K), half variance", f"{log(F / K):.6f} {0.5 * sd * sd:.6f}"), ("Black bracket F N(d1) - K N(d2) bp", f"{1e4 * pay / A:.4f}"),
        ("d1, d2", f"{d1:.6f} {d2:.6f}"), ("N(d1), N(d2)", f"{N(d1):.6f} {N(d2):.6f}"),
        ("payer % (knock-out), Black", pc(pay)), ("  by Simpson integral", pc(pay_int)), ("  by Monte Carlo", pc(pay_mc)),
        ("receiver %, Black", pc(rec)), ("  by Simpson integral", pc(rec_int)),
        ("payer - receiver %, integrals", pc(pay_int - rec_int)), ("A (F - K) %", pc(A * (F - K))),
        ("front-end protection %, closed", pc(FEP)), ("  by simulated defaults", pc(FEP_mc)),
        ("payer that keeps FEP %", pc(pay + FEP)),
        ("delta, % per bp of F: A N(d1)", f"{delta * 1e-2:.6f}"), ("  by bump", f"{delta_b * 1e-2:.6f}"),
        ("  whole curve +-1bp, re-bootstrap", f"{100 * curve_d:.6f}"),
        ("vega, % per vol point: A F phi(d1)", f"{vega:.6f}"), ("  by bump", f"{vega_b:.6f}"),
        ("price range %: A(F-K)+ to A F", f"{pc(lo_b)} {pc(hi_b)}"),
        ("implied vol from payer, bisection", f"{iv_bis:.6f}"), ("  by Newton from 0.30", f"{v:.6f}"),
        ("wrong: invert payer + FEP", f"{iv_bad:.6f}"), ("premium 1.20% < floor: bisection", f"{iv_low:.6f}"),
        ("wrong: D(1) as the unit %", pc(black(F, K, VOL, exp(-RATE))[0])),
        ("wrong: riskless annuity as unit %", pc(black(F, K, VOL, Ars)[0])),
        ("wrong: spot 5y spread as forward %", pc(black(0.0250, K, VOL, A)[0])),
        ("wrong: spot 5y annuity as unit %", pc(black(F, K, VOL, annuity(0, 5, lam))[0])),
        ("try: vol 25% payer %", pc(black(F, K, 0.25, A)[0])), ("try: strike 350bp payer %", pc(black(F, 0.035, VOL, A)[0]))]
for name, val in rows: print(f"{name:<36} {val}")
xs = [0.0150, 0.0200, 0.0250, 0.0300, 0.0350, 0.0400, 0.0450]
print("chart, spread at expiry (bp)  " + " ".join(f"{1e4 * s:6.0f}" for s in xs))
print("chart, payer exercise (%)     " + " ".join(f"{100 * spot_cds(s) * max(s - K, 0):6.2f}" for s in xs))
print("chart, receiver exercise (%)  " + " ".join(f"{100 * spot_cds(s) * max(K - s, 0):6.2f}" for s in xs))
print("chart, vol (%)                " + " ".join(f"{10 * i:6d}" for i in range(1, 11)))
print("chart, payer premium (%)      " + " ".join(f"{100 * black(F, K, i / 10, A)[0]:6.2f}" for i in range(1, 11)))

assert abs(P_simp - P) < 1e-10 and abs(1e4 * (P_mc / A_mc - F)) < 3.0, "forward spread: three roads agree"
assert abs(FEP_mc - FEP) < 4 * se_fep, "front-end protection: closed form vs simulated defaults"
assert abs(pay_int - pay) < 1e-7 and abs(pay_mc - pay) < 0.01 * pay, "payer: formula, integral, simulation"
assert abs((pay_int - rec_int) - A * (F - K)) < 1e-7 and abs(rec_int - rec) < 1e-7, "parity by the two integrals"
assert abs(delta_b - delta) < 1e-6 and abs(vega_b - vega) < 1e-6, "Greeks: bumps vs closed forms"
assert abs(iv_bis - VOL) < 1e-9 and abs(v - VOL) < 1e-9, "implied volatility recovers 50% by two roads"
assert lo_b < pay < hi_b and iv_low < 1e-3 and 0.0120 < lo_b, "below the floor there is no volatility"
print("ALL CHECKS PASS")
