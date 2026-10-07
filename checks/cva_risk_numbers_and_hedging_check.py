# CVA risk numbers and hedging -- the check behind the card.  Standard library only.
# The Acme call (S = K = 100, r 5%, q 2%, vol 20%, 1 year) bought from Northwind
# (hazard 2%, recovery 40%).  Road 1: closed forms and their derivatives.
# Road 2: CVA as a double integral (over Acme's price, then over the default date),
# every risk number by bump and revalue.  The normal CDF is a power series written out.
from math import exp, log, sqrt, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def ncdf(x):                                   # 1/2 + phi(x) (x + x^3/3 + x^5/(3*5) + ...)
    if x > 10.0: return 1.0
    if x < -10.0: return 0.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1; term *= x * x / (2 * n + 1); total += term
    return 0.5 + phi(x) * total

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

K, r, q, T, R = 100.0, 0.05, 0.02, 1.0, 0.40
def call(S, vol, t):                           # Black-Scholes call with t years left
    if t <= 0.0: return max(S - K, 0.0)
    d1 = (log(S / K) + (r - q + 0.5 * vol * vol) * t) / (vol * sqrt(t))
    return S * exp(-q * t) * ncdf(d1) - K * exp(-r * t) * ncdf(d1 - vol * sqrt(t))

# ---- road 1: closed forms ----
def cva1(S, vol, s): return (1 - R) * call(S, vol, T) * (1 - exp(-s / (1 - R) * T))
def cds1(s_now, s0, M, tenor):                 # value of M of protection bought at s0, continuous premium
    h = s_now / (1 - R); k = r + h
    return M * (1 - exp(-k * tenor)) / k * (s_now - s0)

# ---- road 2: integrals, no closed form for CVA or the CDS legs ----
def dee(S, vol, t):                            # discounted expected exposure at date t
    if t == 0.0: return call(S, vol, T)
    g = lambda z: phi(z) * call(S * exp((r - q - 0.5 * vol * vol) * t + vol * sqrt(t) * z), vol, T - t)
    a = -8.0 if t < T else (log(K / S) - (r - q - 0.5 * vol * vol) * t) / (vol * sqrt(t))   # kink at expiry
    return exp(-r * t) * simpson(g, a, 8.0, 2000)
def cva2(S, vol, s):
    h = s / (1 - R)
    return (1 - R) * simpson(lambda t: dee(S, vol, t) * h * exp(-h * t), 0.0, T, 10)
def cds2(s_now, s0, M, tenor):
    h = s_now / (1 - R)
    ann = simpson(lambda t: exp(-(r + h) * t), 0.0, tenor, 200)
    prot = (1 - R) * simpson(lambda t: exp(-r * t) * h * exp(-h * t), 0.0, tenor, 200)
    return M * (prot - s0 * ann)

S0, vol0, lam = 100.0, 0.20, 0.02
s0, bp = lam * (1 - R), 1e-4
C = call(S0, vol0, T)
pd = 1 - exp(-lam * T)
d1 = (log(S0 / K) + (r - q + 0.5 * vol0 ** 2) * T) / (vol0 * sqrt(T))
c_delta, c_vega = exp(-q * T) * ncdf(d1), S0 * exp(-q * T) * phi(d1) * sqrt(T) / 100
CVA, CVA2 = cva1(S0, vol0, s0), cva2(S0, vol0, s0)
cs01_an = C * T * exp(-lam * T) * bp           # dCVA/ds = C T e^{-hT}: the (1-R) cancels
cs01_bp = (cva2(S0, vol0, s0 + bp) - cva2(S0, vol0, s0 - bp)) / 2
ann1 = (1 - exp(-(r + lam) * T)) / (r + lam)
cds_cs01 = (cds2(s0 + bp, s0, 1.0, T) - cds2(s0 - bp, s0, 1.0, T)) / 2
M_cs01 = cs01_bp / cds_cs01
jtd = (1 - R) * C - CVA                         # the risky price falls to recovery times C
M_jtd = jtd / (1 - R)
dl_an, vg_an = (1 - R) * pd * c_delta, (1 - R) * pd * c_vega
dl_bp = (cva2(S0 + 0.5, vol0, s0) - cva2(S0 - 0.5, vol0, s0)) / 1.0
vg_bp = (cva2(S0, vol0 + 0.01, s0) - cva2(S0, vol0 - 0.01, s0)) / 2

rows = [("call C", C), ("Northwind spread s = h(1-R), bp", s0 / bp), ("default chance by T, 1-e^-hT", pd), ("survival to T, e^-hT", 1 - pd),
    ("1 CVA formula (1-R) C (1-e^-hT)", CVA), ("2 CVA by double integral", CVA2),
    ("  DEE at t = 0.5, integral", dee(S0, vol0, 0.5)), ("  DEE at t = 1, integral", dee(S0, vol0, 1.0)),
    ("rule of thumb s C T", s0 * C * T), ("risky price C - CVA", C - CVA),
    ("CS01 analytic C T e^-hT x 1bp", cs01_an), ("CS01 by bump, road 2", cs01_bp),
    ("CDS annuity A = (1-e^-(r+h)T)/(r+h)", ann1), ("CDS CS01 per $1 by bump, x 1e4", cds_cs01 * 1e4),
    ("hedge notional by CS01", M_cs01), ("jump-to-default loss (1-R)C - CVA", jtd),
    ("hedge notional by jump-to-default", M_jtd),
    ("CVA delta analytic", dl_an), ("CVA delta by bump, road 2", dl_bp), ("  call's own delta", c_delta),
    ("CVA vega per vol point, analytic", vg_an), ("CVA vega by bump, road 2", vg_bp), ("  call's own vega", c_vega),
    ("greek ratio (1-R)(1-e^-hT)", (1 - R) * pd),
    ("wrong: CS01 per bp of hazard", (cva1(S0, vol0, s0 + (1 - R) * bp) - CVA)),
    ("wrong: CVA on undiscounted exposure", (1 - R) * lam * C * (exp((r - lam) * T) - 1) / (r - lam)),
    ("wrong: 5y CDS notional by CS01", cs01_bp / ((1 - exp(-(r + lam) * 5)) / (r + lam) * bp)),
    ("try: notional if spread 300bp", C * T * exp(-0.05 * T) / ((1 - exp(-0.10)) / 0.10)),
    ("try: notional if Acme 110", call(110, vol0, T) * T * exp(-lam * T) / ann1),
    ("try: CVA if recovery 0, same spread", C * (1 - exp(-s0 * T)))]
for name, v in rows: print(f"{name:<38}{v:>14.6f}")

def pnl(dS, ds, M, shares):                     # desk is short CVA, long M of CDS and some shares
    return -(cva1(S0 + dS, vol0, s0 + ds) - CVA) + cds1(s0 + ds, s0, M, T) + shares * dS
print(f"{'scenario, $ per option':<28}{'unhedged':>10}{'CS01 hedge':>12}{'JTD hedge':>11}{'call delta':>11}")
for lab, dS, ds in (("spread +10bp", 0, 10 * bp), ("spread +100bp", 0, 100 * bp), ("Acme +5", 5, 0),
                    ("Acme +5 and spread +100bp", 5, 100 * bp)):
    print(f"{lab:<28}{pnl(dS, ds, 0, 0):>10.4f}{pnl(dS, ds, M_cs01, dl_an):>12.4f}"
          f"{pnl(dS, ds, M_jtd, dl_an):>11.4f}{pnl(dS, ds, M_cs01, c_delta):>11.4f}")
dflt = lambda M: -jtd + M * (1 - R)             # default now: pay (1-R)C, release CVA, CDS pays M(1-R)
print(f"{'Northwind defaults now':<28}{dflt(0):>10.4f}{dflt(M_cs01):>12.4f}{dflt(M_jtd):>11.4f}{dflt(M_cs01):>11.4f}")
print(f"{'  5y CDS sized by CS01':<28}{'':>10}{dflt(cs01_bp / ((1 - exp(-(r + lam) * 5)) / (r + lam) * bp)):>12.4f}")

grid = [0, 100, 200, 300, 400, 500, 600]
print("chart, spread bp       " + " ".join(f"{x:>7d}" for x in grid))
print("chart, CVA cents       " + " ".join(f"{100 * cva1(S0, vol0, x * bp):>7.2f}" for x in grid))
print("chart, CS01 line cents " + " ".join(f"{100 * (CVA + cs01_an * (x - 120)):>7.2f}" for x in grid))
moves = [0, 60, 120, 180, 240, 300, 360]
print("chart, spread after bp " + " ".join(f"{x:>7d}" for x in moves))
print("chart, unhedged cents  " + " ".join(f"{100 * pnl(0, (x - 120) * bp, 0, 0):>7.2f}" for x in moves))
print("chart, CS01 hedge cents" + " ".join(f"{100 * pnl(0, (x - 120) * bp, M_cs01, 0):>7.2f}" for x in moves))
print("chart, JTD hedge cents " + " ".join(f"{100 * pnl(0, (x - 120) * bp, M_jtd, 0):>7.2f}" for x in moves))

assert abs(CVA2 - CVA) < 1e-9, "double integral must land on the closed form"
assert max(abs(dee(S0, vol0, t) - C) for t in (0.5, 1.0)) < 1e-9, "discounted exposure is flat at C"
assert abs(cs01_bp - cs01_an) < 1e-10, "bumped CS01 vs C T e^-hT"
assert abs(cds_cs01 / bp - ann1) < 1e-8, "CDS CS01 per bp vs the annuity"
assert abs(dl_bp - dl_an) < 1e-6, "delta by bump vs (1-R) pd x call delta"
assert abs(vg_bp - vg_an) < 1e-6, "vega by bump vs (1-R) pd x call vega"
assert abs(pnl(0, 10 * bp, M_cs01, dl_an)) < 0.01 * abs(pnl(0, 10 * bp, 0, 0)), "CS01 hedge kills 99% of a 10bp move"
print("ALL CHECKS PASS")
