# Rho and dividend rho -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the
# answer: the normal CDF is a series written out, the root finder is bisection,
# the integral is Simpson's rule, and no road below borrows from another.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                                   # bell-curve area left of x
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s, t, n = x, x, 1
    while s + t * x * x / (2 * n + 1) != s:                 # x + x^3/3 + x^5/(3*5) + ...
        t *= x * x / (2 * n + 1); s += t; n += 1
    return 0.5 + s * phi(x)

def d1d2(S, K, r, q, sig, T):
    v = sig * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / v
    return d1, d1 - v

def call(S, K, r, q, sig, T):
    d1, d2 = d1d2(S, K, r, q, sig, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)

def rho_c(S, K, r, q, sig, T): return K * T * exp(-r * T) * N(d1d2(S, K, r, q, sig, T)[1])
def rho_p(S, K, r, q, sig, T): return -K * T * exp(-r * T) * N(-d1d2(S, K, r, q, sig, T)[1])
def qrho_c(S, K, r, q, sig, T): return -T * S * exp(-q * T) * N(d1d2(S, K, r, q, sig, T)[0])
def qrho_p(S, K, r, q, sig, T): return T * S * exp(-q * T) * N(-d1d2(S, K, r, q, sig, T)[0])

def simpson(f, a, b, n=20000):
    h = (b - a) / n
    tot = f(a) + f(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3.0

def by_integral(S, K, r, q, sig, T, kind):
    # Road 3: the risk-neutral average done by brute force.  No d1, no d2, no N.
    ST = lambda z: S * exp((r - q - 0.5 * sig * sig) * T + sig * sqrt(T) * z)
    lo, hi = -10.0, 10.0                        # bisection: where does S_T cross K?
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if ST(mid) > K: hi = mid
        else: lo = mid
    zc = 0.5 * (lo + hi)
    if kind == "call": v = simpson(lambda z: (ST(z) - K) * phi(z), zc, 10.0)
    elif kind == "put": v = simpson(lambda z: (K - ST(z)) * phi(z), -10.0, zc)
    else:                                       # Road 4: differentiate inside the average
        v = simpson(lambda z: (T * ST(z) - T * (ST(z) - K)) * phi(z), zc, 10.0)
    return exp(-r * T) * v                      # pathwise: d/dr of e^-rT (S_T - K), S_T fixed in z

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = d1d2(S, K, r, q, sig, T)
C, h = call(S, K, r, q, sig, T), 1e-4
Ci, Pi = by_integral(S, K, r, q, sig, T, "call"), by_integral(S, K, r, q, sig, T, "put")
rho, rhoP, qrho, qrhoP = rho_c(S, K, r, q, sig, T), rho_p(S, K, r, q, sig, T), qrho_c(S, K, r, q, sig, T), qrho_p(S, K, r, q, sig, T)
bump = lambda f, dr, dq: (f(S, K, r + dr, q + dq, sig, T) - f(S, K, r - dr, q - dq, sig, T)) / (2 * h)
ci = lambda kind: (lambda S, K, r, q, sig, T: by_integral(S, K, r, q, sig, T, kind))
rho_bump, rho_int = bump(call, h, 0), bump(ci("call"), h, 0)
rho_path = by_integral(S, K, r, q, sig, T, "path")
rhoP_int, qrho_int, qrhoP_int = bump(ci("put"), h, 0), bump(ci("call"), 0, h), bump(ci("put"), 0, h)
dens = S * exp(-q * T) * phi(d1) * sqrt(T) / sig            # the two terms that cancel, one each side
dens2 = K * exp(-r * T) * phi(d2) * sqrt(T) / sig
up1pc = call(S, K, r + 0.01, q, sig, T) - C

rows = [("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("N(-d1)", N(-d1)), ("N(-d2)", N(-d2)), ("e^-rT", exp(-r * T)), ("e^-qT", exp(-q * T)),
    ("share half  S e^-qT N(d1)", S * exp(-q * T) * N(d1)), ("cash half   K e^-rT N(d2)", K * exp(-r * T) * N(d2)),
    ("call, formula", C), ("call, Simpson integral", Ci), ("put, Simpson integral", Pi),
    ("d1 and d2 move per unit r", sqrt(T) / sig), ("density term, share side", dens), ("density term, cash side", -dens2),
    ("rho 1 formula K T e^-rT N(d2)", rho), ("rho 2 bump the formula", rho_bump),
    ("rho 3 bump the integral", rho_int), ("rho 4 pathwise integral", rho_path),
    ("rho per basis point", rho / 1e4),
    ("rho per 1 percent", rho / 100), ("reprice, r up 1 percent", up1pc),
    ("put rho, formula", rhoP), ("put rho, bump the integral", rhoP_int),
    ("rho call - rho put", rho - rhoP_int), ("K T e^-rT", K * T * exp(-r * T)),
    ("dividend rho call, formula", qrho), ("dividend rho call, bump", qrho_int),
    ("dividend rho put, formula", qrhoP), ("dividend rho put, bump", qrhoP_int),
    ("div rho call - div rho put", qrho - qrhoP_int), ("-T S e^-qT", -T * S * exp(-q * T)),
    ("call: rho + dividend rho", rho + qrho), ("put: rho + dividend rho", rhoP + qrhoP),
    ("wrong: N(d1) for N(d2)", K * T * exp(-r * T) * N(d1)), ("wrong: no e^-rT", K * T * N(d2)),
    ("wrong: put rho = -call rho", -rho),
    ("wrong: no T, 5-year option", K * exp(-r * 5) * N(d1d2(S, K, r, q, sig, 5.0)[1])),
    ("  right, 5-year option", rho_c(S, K, r, q, sig, 5.0)),
    ("try: K = 130", rho_c(S, 130.0, r, q, sig, T)),
    ("try: T = 20", rho_c(S, K, r, q, sig, 20.0))]
for name, v in rows:
    print(f"{name:<31} {v:>13.6f}")

print("maturity  call   rho  put rho  per 1%  % of call")
for t in (1 / 12, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0):
    c, rc, rp = call(S, K, r, q, sig, t), rho_c(S, K, r, q, sig, t), rho_p(S, K, r, q, sig, t)
    print(f"{t:8.2f} {c:6.2f} {rc:6.2f} {rp:8.2f} {rc / 100:7.2f} {rc / c:9.2f}")
rates = [0.01 * i for i in range(11)]
print("chart, rate %  " + " ".join(f"{100 * x:5.0f}" for x in rates))
print("chart, call    " + " ".join(f"{call(S, K, x, q, sig, T):5.2f}" for x in rates))
print("chart, tangent " + " ".join(f"{C + rho * (x - r):5.2f}" for x in rates))

assert abs(rho - 49.458109105322) < 1e-9, "formula vs the house number"
assert abs(rho_bump - rho) < 1e-5, "bumped formula price"
assert abs(rho_int - rho) < 1e-5, "bumped integral price: no d1, d2 or N used"
assert abs(rho_path - rho) < 1e-8, "pathwise integral"
assert abs((rho - rhoP_int) - K * T * exp(-r * T)) < 1e-5, "parity in r, put from the integral"
assert abs(qrho_int - qrho) < 1e-5, "dividend rho, call, by bump"
assert abs(qrhoP_int - qrhoP) < 1e-5, "dividend rho, put, by bump"
assert abs((rho + qrho) + T * Ci) < 1e-8, "parallel move: rho + dividend rho = -T C"
assert abs(dens - dens2) < 1e-9, "the two density terms cancel"
assert abs((rhoP + qrhoP) + T * Pi) < 1e-8, "parallel move for the put"
print("ALL CHECKS PASS")
