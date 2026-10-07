# Compound options -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is a series, the
# two-dimensional bell curve is Simpson's rule, the critical share price is
# Newton's method checked by bisection, and the tree is a loop.
from math import exp, log, sqrt, pi, asin

S, K2, T2, K1, T1, r, q, SIG = 100.0, 100.0, 1.0, 8.0, 0.5, 0.05, 0.02, 0.20

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x

def N(x):                                                  # bell-curve area left of x, by series
    if x < -10.0: return 0.0
    if x > 10.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def M(a, b, rho):                    # chance X <= a and Y <= b, standard normals, correlation rho
    if a < -10.0: return 0.0
    w = sqrt(1.0 - rho * rho)
    return simpson(lambda z: phi(z) * N((b - rho * z) / w), -10.0, a, 2000)

def bs(s, t, eta, sg=SIG):           # Black-Scholes call (eta = 1) or put (eta = -1), strike K2
    v = sg * sqrt(t); d1 = (log(s / K2) + (r - q + 0.5 * sg * sg) * t) / v
    return eta * (s * exp(-q * t) * N(eta * d1) - K2 * exp(-r * t) * N(eta * (d1 - v)))

def newton(eta, k1, tau, sg=SIG, trail=None):   # share price at T1 where the underlying is worth k1
    x = K2
    for i in range(50):
        d1 = (log(x / K2) + (r - q + 0.5 * sg * sg) * tau) / (sg * sqrt(tau))
        f = bs(x, tau, eta, sg) - k1; slope = eta * exp(-q * tau) * N(eta * d1)
        if trail is not None: trail.append((i, x, f))
        step = f / slope; x -= step
        if abs(step) < 1e-10: return x
    raise RuntimeError("Newton did not settle")

def bisect(eta, k1, tau, lo=1.0, hi=300.0):     # the same root with no derivative
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if eta * (bs(mid, tau, eta) - k1) > 0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def geske(eps, eta, s=S, k1=K1, t1=T1, t2=T2, sg=SIG, x=None, rho=None, k1_disc=None):
    # eps: 1 compound call, -1 compound put; eta: 1 on a call, -1 on a put.
    if k1 == 0.0: return bs(s, t2, eta, sg) if eps == 1 else 0.0
    x = newton(eta, k1, t2 - t1, sg) if x is None else x
    rho = sqrt(t1 / t2) if rho is None else rho
    a2 = (log(s / x) + (r - q - 0.5 * sg * sg) * t1) / (sg * sqrt(t1)); a1 = a2 + sg * sqrt(t1)
    b2 = (log(s / K2) + (r - q - 0.5 * sg * sg) * t2) / (sg * sqrt(t2)); b1 = b2 + sg * sqrt(t2)
    j = eps * eta
    A, B, F = s * exp(-q * t2), K2 * exp(-r * t2), k1 * exp(-r * (t1 if k1_disc is None else k1_disc))
    return eps * (eta * (A * M(j * a1, eta * b1, j * eta * rho) - B * M(j * a2, eta * b2, j * eta * rho))
                  - F * N(j * a2))

def by_integral(eps, eta, x):        # road 2: average the first-date payoff over the bell curve
    v = SIG * sqrt(T1); cut = (log(x / S) - (r - q - 0.5 * SIG * SIG) * T1) / v
    lo, hi = (cut, 10.0) if eps * eta == 1 else (-10.0, cut)
    f = lambda z: max(eps * (bs(S * exp((r - q - 0.5 * SIG * SIG) * T1 + v * z), T2 - T1, eta) - K1), 0.0) * phi(z)
    return exp(-r * T1) * simpson(f, lo, hi, 4000)

def by_tree(eta, n=2000):            # road 3: one coin-flip tree, both dates on it, no critical price
    dt = T2 / n; up = SIG * sqrt(dt); p = (exp((r - q) * dt) - exp(-up)) / (exp(up) - exp(-up))
    disc = exp(-r * dt); m = int(round(n * T1 / T2))
    back = lambda a, i: [disc * (p * a[j + 1] + (1.0 - p) * a[j]) for j in range(i + 1)]
    u = [max(eta * (S * exp((2 * j - n) * up) - K2), 0.0) for j in range(n + 1)]
    for i in range(n - 1, m - 1, -1): u = back(u, i)
    c, pt = [max(x - K1, 0.0) for x in u], [max(K1 - x, 0.0) for x in u]
    for i in range(m - 1, -1, -1): c, pt = back(c, i), back(pt, i)
    return c[0], pt[0]

trail = []; xc = newton(1, K1, T2 - T1, trail=trail); xb = bisect(1, K1, T2 - T1)
xp = newton(-1, K1, T2 - T1); xpb = bisect(-1, K1, T2 - T1)
v1, rho = SIG * sqrt(T1), sqrt(T1 / T2)
a2 = (log(S / xc) + (r - q - 0.5 * SIG * SIG) * T1) / v1; a1 = a2 + v1
b2 = (log(S / K2) + (r - q - 0.5 * SIG * SIG) * T2) / (SIG * sqrt(T2)); b1 = b2 + SIG * sqrt(T2)
cc, pc, cp, pp = geske(1, 1), geske(-1, 1), geske(1, -1), geske(-1, -1)
cc_i, pc_i, cp_i, pp_i = by_integral(1, 1, xc), by_integral(-1, 1, xc), by_integral(1, -1, xp), by_integral(-1, -1, xp)
cc_t, pc_t = by_tree(1); cp_t, pp_t = by_tree(-1)
C0, h = bs(S, T2, 1), 0.01
delta_bump = (geske(1, 1, s=S + h) - geske(1, 1, s=S - h)) / (2 * h)
gamma = (geske(1, 1, s=S + 1.0) - 2 * cc + geske(1, 1, s=S - 1.0)) / 1.0
vega = (geske(1, 1, sg=SIG + 0.01) - geske(1, 1, sg=SIG - 0.01)) / 2.0
c_delta = (bs(S + h, T2, 1) - bs(S - h, T2, 1)) / (2 * h)
c_gamma = bs(S + 1.0, T2, 1) - 2 * C0 + bs(S - 1.0, T2, 1)
c_vega = (bs(S, T2, 1, SIG + 0.01) - bs(S, T2, 1, SIG - 0.01)) / 2.0

rows = [
    ("underlying call today, 1 year", C0),
    ("critical price x*, Newton", xc), ("critical price x*, bisection", xb),
    ("call at 6 months when Acme = x*", bs(xc, T2 - T1, 1)),
    ("a1", a1), ("a2", a2), ("b1", b1), ("b2", b2),
    ("N(a2)  chance the $8 is paid", N(a2)), ("M(a2, b2; rho)  both exercised", M(a2, b2, rho)),
    ("M(a1, b1; rho)  share-counted", M(a1, b1, rho)),
    ("share leg  S e^-qT2 M(a1,b1)", S * exp(-q * T2) * M(a1, b1, rho)),
    ("strike leg K2 e^-rT2 M(a2,b2)", K2 * exp(-r * T2) * M(a2, b2, rho)),
    ("fee leg    K1 e^-rT1 N(a2)", K1 * exp(-r * T1) * N(a2)),
    ("1 call on call, Geske formula", cc), ("2 call on call, Simpson integral", cc_i),
    ("3 call on call, tree 2000 steps", cc_t),
    ("put on call, formula", pc), ("put on call, integral", pc_i), ("put on call, tree", pc_t),
    ("  CoC - PoC", cc - pc), ("  C0 - K1 e^-rT1", C0 - K1 * exp(-r * T1)),
    ("critical price on the put, Newton", xp),
    ("call on put, formula", cp), ("call on put, integral", cp_i), ("call on put, tree", cp_t),
    ("put on put, formula", pp), ("put on put, integral", pp_i), ("put on put, tree", pp_t),
    ("check M(0,0;rho)", M(0.0, 0.0, rho)), ("  1/4 + asin(rho)/(2 pi)", 0.25 + asin(rho) / (2 * pi)),
    ("delta CoC, e^-qT2 M(a1,b1)", exp(-q * T2) * M(a1, b1, rho)), ("delta CoC, bump", delta_bump),
    ("gamma CoC, bump", gamma), ("vega CoC per vol point", vega), ("gearing CoC  S delta / V", S * delta_bump / cc),
    ("delta call, bump", c_delta), ("gamma call, bump", c_gamma), ("vega call per vol point", c_vega),
    ("gearing call  S delta / C", S * c_delta / C0),
    ("wrong: always pay the $8", C0 - K1 * exp(-r * T1)), ("wrong: rho = T1/T2", geske(1, 1, rho=T1 / T2)),
    ("wrong: $8 discounted from T2", geske(1, 1, k1_disc=T2)), ("wrong: exercise when Acme > 100", geske(1, 1, x=K2)),
    ("try: sigma = 0.30", geske(1, 1, sg=0.30)), ("try: T1 = 0.25", geske(1, 1, t1=0.25)),
]
for name, val in rows: print(f"{name:<40} {val:>12.6f}")
print(f"hand: sigma sqrt(T1) {v1:.6f}; drift T1 {(r - q - 0.5 * SIG * SIG) * T1:.6f}; ln(S/x*) {log(S / xc):.6f}; rho {rho:.6f}\n"
      f"hand: e^-qT2 {exp(-q * T2):.6f}; e^-rT2 {exp(-r * T2):.6f}; e^-rT1 {exp(-r * T1):.6f}; K1 e^-rT1 {K1 * exp(-r * T1):.6f}")
print("newton steps: " + "; ".join(f"{x:.4f} ({f:+.4f})" for i, x, f in trail))
xs = [80.0 + 5.0 * i for i in range(10)]
print("chart, Acme at 6 months " + " ".join(f"{x:6.0f}" for x in xs))
print("chart, call at 6 months " + " ".join(f"{bs(x, T2 - T1, 1):6.2f}" for x in xs))
print("chart, CoC payoff       " + " ".join(f"{max(bs(x, T2 - T1, 1) - K1, 0.0):6.2f}" for x in xs))
ks = [2.0 * i for i in range(9)]
print("chart, fee K1           " + " ".join(f"{k:6.0f}" for k in ks))
print("chart, CoC price        " + " ".join(f"{geske(1, 1, k1=k):6.2f}" for k in ks))

assert abs(xc - xb) < 1e-6, "Newton and bisection find one critical price, call underlying"
assert abs(xp - xpb) < 1e-6, "Newton and bisection find one critical price, put underlying"
assert abs(M(0.0, 0.0, rho) - (0.25 + asin(rho) / (2 * pi))) < 1e-10, "bivariate routine vs closed form"
for f_, i_ in ((cc, cc_i), (pc, pc_i), (cp, cp_i), (pp, pp_i)): assert abs(f_ - i_) < 1e-6, "formula vs integral"
for f_, t_ in ((cc, cc_t), (pc, pc_t), (cp, cp_t), (pp, pp_t)): assert abs(f_ - t_) < 0.01, "formula vs tree"
assert abs((cc - pc) - (C0 - K1 * exp(-r * T1))) < 1e-9, "compound parity with the tree-free call"
assert abs(exp(-q * T2) * M(a1, b1, rho) - delta_bump) < 1e-6, "delta formula vs bump"
assert abs(C0 - 9.227005508154) < 1e-9, "the house call"
print("ALL CHECKS PASS")
