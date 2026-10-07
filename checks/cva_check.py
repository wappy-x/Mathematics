# CVA -- the check behind the card.  Standard library only.
# The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from
# Northwind (hazard 2% a year, recovery 40%).  Nothing imported knows the answer:
# the normal CDF is a series, the integrals are Simpson's rule, the random
# numbers are splitmix64 plus Box-Muller, all written out below.
from math import exp, log, sqrt, pi, cos

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LAM, R = 0.02, 0.40
LGD = 1.0 - R

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)              # bell-curve height
def N(x):                                                           # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def bs(s, left, put=False):                                         # Acme option with `left` years to run
    if left <= 1e-12: return max(K - s, 0.0) if put else max(s - K, 0.0)
    v = sig * sqrt(left)
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * left) / v
    if put: return K * exp(-r * left) * N(v - d1) - s * exp(-q * left) * N(-d1)
    return s * exp(-q * left) * N(d1) - K * exp(-r * left) * N(d1 - v)

def simpson(f, a, b, n):                                            # area under f from a to b, n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def dee(t, sign=1.0):
    # discounted expected exposure D(t) EE(t): average of the bank's positive value at t over
    # Acme's price at t, found by integrating over the bell curve.  No martingale shortcut used.
    drift, vol = (r - q - 0.5 * sig * sig) * t, sig * sqrt(t)
    st = lambda z: S * exp(drift + vol * z)
    lo = -8.0 if t < T else (log(K / S) - drift) / vol              # at expiry, start at the kink
    f = lambda z: max(sign * bs(st(z), T - t), 0.0) * phi(z)
    return exp(-r * t) * simpson(f, lo, 8.0, 2000)

Q = lambda t, lam=LAM: exp(-lam * t)                                # survival to t
C0, P0 = bs(S, T), bs(S, T, put=True)
PD = 1.0 - Q(T)

cva_closed = LGD * C0 * PD                                          # road 1: loss x price x default chance

def bucketed(n):                                                    # road 2: sum over n buckets
    parts = [LGD * dee((i + 0.5) * T / n) * (Q(i * T / n) - Q((i + 1) * T / n)) for i in range(n)]
    return sum(parts), parts
cva_52, weekly = bucketed(52)
cva_1, _ = bucketed(1)

state = 20260928                                                    # road 3: simulate the default date
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
M, acc, acc2 = 400000, 0.0, 0.0
for _ in range(M):
    u1, u2, u3 = uniform(), uniform(), uniform()
    tau = -log(1.0 - u1 * PD) / LAM                                 # a default date, given one before T
    z = sqrt(-2.0 * log(u2)) * cos(2.0 * pi * u3)
    s_tau = S * exp((r - q - 0.5 * sig * sig) * tau + sig * sqrt(tau) * z)
    x = LGD * PD * exp(-r * tau) * bs(s_tau, T - tau)
    acc += x; acc2 += x * x
cva_mc = acc / M
se_mc = sqrt((acc2 / M - cva_mc * cva_mc) / M)

s_run = LGD * LAM                                                   # road 4: a CDS on the exposure
annuity_E = simpson(lambda t: dee(t) * Q(t), 0.0, T, 8)             # exposure-weighted risky annuity
cva_cds = s_run * annuity_E

risky = C0 - cva_closed
risky_disc = C0 * exp(-LGD * LAM * T)                               # approximate road: risky discounting
dee_end = dee(T)

rows = [
    ("clean call C0", C0), ("clean put P0", P0), ("loss given default 1-R", LGD),
    ("default chance to T, 1-e^-lam T", PD),
    ("1 closed form (1-R) C0 PD", cva_closed), ("2 bucketed sum, 52 weeks", cva_52),
    ("  one bucket only", cva_1), ("3 simulated default dates", cva_mc), ("  standard error", se_mc),
    ("4 CDS view: spread x annuity", cva_cds),
    ("  running spread (1-R) lam", s_run), ("  exposure annuity int DEE Q dt", annuity_E),
    ("risky call C0 - CVA", risky), ("risky discounting C0 e^-(1-R)lam T", risky_disc),
    ("DEE at expiry, by integration", dee_end),
    ("wrong: R in place of 1-R", R * C0 * PD),
    ("wrong: exposure not discounted", LGD * C0 * LAM * (exp((r - LAM) * T) - 1.0) / (r - LAM)),
    ("wrong: risky discount and CVA", risky_disc - cva_closed),
    ("wrong: CVA charged on a call sold", cva_closed), ("  right: sold call DEE at 6 months", dee(0.5, -1.0)),
    ("try: hazard 5%", LGD * C0 * (1.0 - Q(T, 0.05))), ("try: recovery 0", C0 * PD),
    ("try: long put", LGD * P0 * PD), ("try: 5-year call", LGD * bs(S, 5.0) * (1.0 - Q(5.0))),
]
for name, v in rows:
    print(f"{name:<36}{v:12.6f}")
print()
ts = [0.0, 0.25, 0.5, 0.75, 1.0]
print("chart, years      " + " ".join(f"{t:6.2f}" for t in ts))
print("chart, EE         " + " ".join(f"{exp(r * t) * dee(t):6.2f}" for t in ts))
print("chart, DEE        " + " ".join(f"{dee(t):6.2f}" for t in ts))
hz = [i / 100 for i in range(11)]
print("chart, hazard %   " + " ".join(f"{100 * h:6.0f}" for h in hz))
print("chart, CVA cents  " + " ".join(f"{100 * LGD * C0 * (1 - Q(T, h)):6.2f}" for h in hz))
print("chart, lam T cents" + " ".join(f"{100 * LGD * C0 * h * T:6.2f}" for h in hz))
print("bars, CVA cents by quarter " + " ".join(f"{100 * sum(weekly[13 * j:13 * j + 13]):.2f}" for j in range(4)))

assert abs(C0 - 9.227005508154) < 1e-9, "own normal CDF reproduces the house call"
assert abs(P0 - 6.330080627550) < 1e-9, "and the house put"
assert abs(dee_end - C0) < 1e-6, "payoff averaged at expiry, discounted, is today's price"
assert abs(cva_52 - cva_closed) < 5e-6, "52-week sum with integrated exposure agrees to four decimals"
assert abs(cva_mc - cva_closed) < 4 * se_mc, "simulation within four standard errors"
assert abs(cva_cds - cva_closed) < 1e-6, "CDS view: spread times exposure annuity"
print("ALL CHECKS PASS")
