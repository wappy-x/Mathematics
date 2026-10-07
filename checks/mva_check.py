# MVA -- the check behind the card.  Standard library only.
# The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind
# (hazard 2% a year, recovery 40%), now with two-way initial margin sized as a 99% ten-day
# move and funded at 50 bp over what the margin earns.  Nothing imported knows the answer:
# the normal CDF is a series, the percentile is bisection, the integrals are Simpson's rule,
# the random numbers are splitmix64 plus Box-Muller, all written out below.
from math import exp, log, sqrt, pi, cos

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LAM, R, S_IM, S_F = 0.02, 0.40, 0.005, 0.01           # hazard, recovery, margin spread, funding spread
H = 10.0 / 252.0                                      # ten trading days, in years

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                             # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def d1(s, left): return (log(s / K) + (r - q + 0.5 * sig * sig) * left) / (sig * sqrt(left))
def call(s, left): return s * exp(-q * left) * N(d1(s, left)) - K * exp(-r * left) * N(d1(s, left) - sig * sqrt(left))
def delta(s, left): return exp(-q * left) * N(d1(s, left)) if left > 1e-12 else (1.0 if s >= K else 0.0)

lo, hi = 0.0, 8.0                                     # the 99th percentile z: N(z) = 0.99, by bisection
for _ in range(200):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if N(mid) < 0.99 else (lo, mid)
Z99 = 0.5 * (lo + hi)
def im(s, left): return Z99 * delta(s, left) * s * sig * sqrt(H)   # delta-normal 99% ten-day move

def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def deim(t):                                          # D(t) E[IM(t)], integrated over Acme's price at t
    if t < 1e-12: return im(S, T)
    drift, vol = (r - q - 0.5 * sig * sig) * t, sig * sqrt(t)
    a = -8.0 if t < T else (log(K / S) - drift) / vol # at expiry delta jumps at K: start there
    return exp(-r * t) * simpson(lambda z: im(S * exp(drift + vol * z), T - t) * phi(z), a, 8.0, 2000)

state = 20260928
def uniform():                                        # splitmix64, a number in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())

def annuity(lam, T): return (1.0 - exp(-lam * T)) / lam if lam > 0 else T
def im0(T): return Z99 * delta(S, T) * S * sig * sqrt(H)
def mva(T, lam=LAM, s=S_IM): return s * im0(T) * annuity(lam, T)
def cva(T, lam=LAM): return (1.0 - R) * call(S, T) * (1.0 - exp(-lam * T))
def fva(T, lam=LAM): return S_F * call(S, T) * annuity(lam, T)

C0, D0 = call(S, T), delta(S, T)
ten_day_sd = D0 * S * sig * sqrt(H)                   # one standard deviation of the ten-day P&L
IM0 = im0(T)
im_spec = 2.33 * 0.587 * S * sig * sqrt(H)            # the rounded hand arithmetic
M = 200000                                            # road 2 for IM: simulate ten-day P&L, sort, read 99%
pnl = sorted(ten_day_sd * gauss() for _ in range(M))
im_sim = pnl[int(0.99 * M)]
up = exp(sig * sqrt(H) * Z99)
im_full_up, im_full_dn = call(S * up, T) - C0, C0 - call(S / up, T)

mva1 = mva(T)                                         # road 1: closed form, flat discounted margin
n = 12                                                # road 2: monthly profile, each month integrated
mva2 = sum(S_IM * deim((i + 0.5) / n) * exp(-LAM * (i + 0.5) / n) / n for i in range(n))
acc = acc2 = 0.0                                      # road 3: simulate a date, a price, a default time
for _ in range(M):
    t, tau = T * uniform(), -log(uniform()) / LAM
    st = S * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * gauss())
    x = T * S_IM * exp(-r * t) * im(st, T - t) if t < tau else 0.0
    acc += x; acc2 += x * x
mva3 = acc / M; se3 = sqrt((acc2 / M - mva3 * mva3) / M)

cva1, fva1 = cva(T), fva(T)
lam_star = S_IM * IM0 / ((1.0 - R) * C0)              # hazard where CVA = MVA, by algebra
a, b = 1e-6, 0.5                                      # ... and by bisection on the two costs
for _ in range(200):
    m = 0.5 * (a + b)
    a, b = (m, b) if cva(T, m) < mva(T, m) else (a, m)
lam_bis = 0.5 * (a + b)
sf_star = S_IM * IM0 / C0                             # funding spread where FVA = MVA
tail = ten_day_sd * (phi(Z99) - Z99 * (1.0 - N(Z99))) # E[(move - IM)+]: loss beyond the margin
tail_int = simpson(lambda x: (x - IM0) * phi(x / ten_day_sd) / ten_day_sd, IM0, 10 * ten_day_sd, 4000)
cva_coll = (1.0 - R) * tail * (1.0 - exp(-LAM * T))

rows = [
    ("clean call C0", C0), ("delta e^-qT N(d1)", D0), ("z, 99th percentile", Z99),
    ("ten-day P&L sd, D S sig sqrt(h)", ten_day_sd), ("IM, delta-normal z x sd", IM0),
    ("IM, rounded 2.33 x 0.587", im_spec), ("IM, simulated 99% quantile", im_sim),
    ("IM, full repricing, Acme up", im_full_up), ("IM, full repricing, Acme down", im_full_dn),
    ("survival annuity (1-e^-lam T)/lam", annuity(LAM, T)),
    ("1 MVA closed form", mva1), ("2 MVA monthly integrated profile", mva2),
    ("3 MVA simulated", mva3), ("  standard error", se3),
    ("CVA (1-R) C0 PD", cva1), ("FVA s_F C0 annuity", fva1),
    ("MVA / CVA", mva1 / cva1), ("MVA / FVA", mva1 / fva1),
    ("hazard where CVA = MVA, algebra", lam_star), ("  by bisection", lam_bis),
    ("funding spread where FVA = MVA", sf_star),
    ("tail beyond IM, E[(X-IM)+]", tail), ("  by integration", tail_int),
    ("CVA with VM and IM held", cva_coll),
    ("wrong: no survival weight", S_IM * IM0 * T),
    ("wrong: margin discounted twice", S_IM * IM0 * annuity(LAM + r, T)),
    ("wrong: one-day horizon", mva1 * sqrt(1.0 / 10.0)),
    ("wrong: whole 5.5% funding rate", (r + S_IM) * IM0 * annuity(LAM, T)),
    ("try: spread 100 bp", mva(T, s=0.01)), ("try: hazard 10%", mva(T, lam=0.10)),
]
for name, v in rows:
    print(f"{name:<36}{v:12.6f}")
print()
ts = [0.0, 0.25, 0.5, 0.75, 1.0]
prof = [deim(t) for t in ts]
print("chart, years       " + " ".join(f"{t:6.2f}" for t in ts))
print("chart, E[IM]       " + " ".join(f"{exp(r * t) * p:6.2f}" for t, p in zip(ts, prof)))
print("chart, D E[IM]     " + " ".join(f"{p:6.2f}" for p in prof))
print("maturity   IM0    C0      MVA      FVA      CVA   MVA/CVA")
for Tm in (1.0, 2.0, 3.0, 5.0, 10.0):
    print(f"{Tm:6.0f} {im0(Tm):6.3f} {call(S, Tm):6.3f} {mva(Tm):8.5f} {fva(Tm):8.5f} {cva(Tm):8.5f} {mva(Tm) / cva(Tm):7.3f}")
print("chart, MVA cents by maturity " + " ".join(f"{100 * mva(Tm):.2f}" for Tm in (1.0, 2.0, 3.0, 5.0, 10.0)))
print("bars, cents: CVA MVA uncollateralised, CVA MVA collateralised "
      + " ".join(f"{100 * v:.3f}" for v in (cva1, mva1, cva_coll, mva1)))

assert abs(C0 - 9.227005508154) < 1e-9, "own normal CDF reproduces the house call"
assert abs(mva2 - mva1) < 1e-6, "monthly integrated margin profile lands on the closed form"
assert abs(mva3 - mva1) < 4 * se3, "simulated dates, prices and defaults within four standard errors"
assert abs(im_sim - IM0) < 0.06, "simulated 99% quantile of the ten-day P&L near z x sd"
assert abs(lam_bis - lam_star) < 1e-9, "bisection on the two costs finds the algebraic crossover"
assert abs(tail_int - tail) < 1e-7, "tail beyond the margin: formula vs integral"
print("ALL CHECKS PASS")
