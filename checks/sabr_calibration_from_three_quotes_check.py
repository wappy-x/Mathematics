# SABR from three quotes -- the check behind the card.  Standard library only.  Nothing
# imported knows the answer: the normal CDF is Marsaglia's series, the roots come from the
# quadratic formula, Newton and bisection, the integrals from Simpson.  Every card number prints.
from math import log, sqrt, exp, pi

S, R, Q, T1 = 100.0, 0.05, 0.02, 1.0                   # the house market
QUOTES = ((92.15, 0.24), 0.20, (119.93, 0.18))        # low wing, ATM (at the forward), high wing
HOUSE = (-0.3, 0.4)                                   # the shelf's house SABR: rho, nu (beta = 1)
def fwd(T): return S * exp((R - Q) * T)
def ncdf(x):                                          # bell-curve area left of x, Marsaglia's series
    if x < 0 or x > 12: return 1.0 - ncdf(-x) if x < 0 else 1.0
    term, total, n = x, x, 1
    while term > 1e-17 * total: term *= x * x / (2 * n + 1); total += term; n += 1
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2 * pi)
def simpson(f, a, b, n=400):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def chi(z, rho): return log((sqrt(1 - 2 * rho * z + z * z) + z - rho) / (1 - rho))
def hagan(K, F, a, rho, nu, T):                       # Hagan's implied volatility, beta = 1
    z = nu / a * log(F / K)
    zx = 1 - rho * z / 2 if abs(z) < 1e-7 else z / chi(z, rho)
    return a * zx * (1 + (rho * nu * a / 4 + (2 - 3 * rho * rho) * nu * nu / 24) * T)
def coeffs(rho, nu, T): return rho * nu * T / 4, 1 + (2 - 3 * rho * rho) * nu * nu * T / 24
def alpha_quad(atm, rho, nu, T):                      # road 1 to alpha: quadratic formula, small root
    c2, c1 = coeffs(rho, nu, T); disc = c1 * c1 + 4 * c2 * atm
    return None if disc < 0 else 2 * atm / (c1 + sqrt(disc))
def alpha_newton(atm, F, rho, nu, T, a):              # road 2 to alpha: Newton on Hagan's ATM vol
    for _ in range(100):
        g = hagan(F, F, a, rho, nu, T) - atm
        a -= g / ((hagan(F, F, a + 1e-6, rho, nu, T) - hagan(F, F, a - 1e-6, rho, nu, T)) / 2e-6)
        if abs(g) < 1e-15: break
    return a
def fit_newton(quotes, F, T, rho=0.0, nu=0.5):        # road 1: 2-D Newton on the two wing gaps
    (k1, s1), s0, (k2, s2) = quotes
    def gaps(r, n):
        a = alpha_quad(s0, r, n, T)
        return hagan(k1, F, a, r, n, T) - s1, hagan(k2, F, a, r, n, T) - s2
    for it in range(1, 100):
        (g1, g2), (a1, a2), (b1, b2) = gaps(rho, nu), gaps(rho + 1e-7, nu), gaps(rho, nu + 1e-7)
        j11, j21, j12, j22 = (a1 - g1) / 1e-7, (a2 - g2) / 1e-7, (b1 - g1) / 1e-7, (b2 - g2) / 1e-7
        det = j11 * j22 - j12 * j21; dr, dn = (j22 * g1 - j12 * g2) / det, (j11 * g2 - j21 * g1) / det
        while abs(rho - dr) >= 0.999 or nu - dn <= 0.01: dr, dn = dr / 2, dn / 2   # stay legal
        rho, nu = rho - dr, nu - dn
        if abs(dr) + abs(dn) < 1e-14: break
    return alpha_quad(s0, rho, nu, T), rho, nu, it, det
def fit_bisect(quotes, F, T, lo=0.6, hi=2.5):         # road 2: rho for the tilt inside nu for the curve
    (k1, s1), s0, (k2, s2) = quotes
    def vols(r, n):
        a = alpha_newton(s0, F, r, n, T, s0)
        return a, hagan(k1, F, a, r, n, T), hagan(k2, F, a, r, n, T)
    def rho_for(n):                                   # the tilt steepens as rho falls
        rl, rh = -0.999, 0.999
        for _ in range(60):
            m = (rl + rh) / 2; _, v1, v2 = vols(m, n)
            rl, rh = (m, rh) if v1 - v2 > s1 - s2 else (rl, m)
        return (rl + rh) / 2
    for _ in range(60):                               # the curvature grows with nu
        n = (lo + hi) / 2; _, v1, v2 = vols(rho_for(n), n)
        lo, hi = (lo, n) if v1 + v2 > s1 + s2 else (n, hi)
    n = (lo + hi) / 2; r = rho_for(n); return vols(r, n)[0], r, n
def black(F, K, vol, T):                              # undiscounted Black-76 call
    v = vol * sqrt(T); d1 = log(F / K) / v + v / 2
    return F * ncdf(d1) - K * ncdf(d1 - v)
def call(K, F, p, T): return black(F, K, hagan(K, F, *p, T), T)   # ... at the SABR smile's vol
def density_prices(K, F, p, T, h=0.05):               # density road 1: butterfly on prices / h^2
    return (call(K - h, F, p, T) - 2 * call(K, F, p, T) + call(K + h, F, p, T)) / (h * h)
def density_g(K, F, p, T, e=1e-3):                    # density road 2: Durrleman's g, no prices
    k = log(K / F); w = lambda x: hagan(F * exp(x), F, *p, T) ** 2 * T
    w0, wp, wm = w(k), w(k + e), w(k - e)
    w1, w2 = (wp - wm) / (2 * e), (wp - 2 * w0 + wm) / (e * e)
    g = (1 - k * w1 / (2 * w0)) ** 2 - w1 * w1 / 4 * (1 / w0 + 0.25) + w2 / 2
    d2 = -k / sqrt(w0) - sqrt(w0) / 2; return exp(-d2 * d2 / 2) / sqrt(2 * pi) / (K * sqrt(w0)) * g
def bisect(f, lo, hi):                                # where f changes sign between lo and hi
    for _ in range(80): m = (lo + hi) / 2; lo, hi = (m, hi) if (f(m) > 0) == (f(lo) > 0) else (lo, m)
    return (lo + hi) / 2
def row(label, *vals, d=6): print(f"{label:<46}" + "".join(f"{v:>12.{d}f}" for v in vals))
F, F10 = fwd(T1), fwd(10.0); (K1, S1), S0, (K2, S2) = QUOTES
(a1, r1, n1, its, det), (a2, r2, n2) = fit_newton(QUOTES, F, T1), fit_bisect(QUOTES, F, T1)
P = (a1, r1, n1); c2, c1 = coeffs(r1, n1, T1); root = sqrt(c1 * c1 + 4 * c2 * S0)
big = (-c1 - root) / (2 * c2); z = n1 / a1 * log(F / K1)
chi_s = simpson(lambda s: 1 / sqrt(1 - 2 * r1 * s + s * s), 0.0, z)       # chi' = 1/sqrt(1 - 2 rho s + s^2)
print(f"quotes: {K1} at {100*S1:.0f}%, forward {F:.6f} at {100*S0:.0f}%, {K2} at {100*S2:.0f}%; T = 1")
row("risk reversal, butterfly (vol points)", 100 * (S2 - S1), 100 * ((S1 + S2) / 2 - S0), d=4)
row(f"road 1, 2-D Newton, {its} steps: a, rho, nu, det", a1, r1, n1, det)
row("road 2, nested bisection: a, rho, nu", a2, r2, n2)
row("road 1 from 35 starts: fits found elsewhere", strays := sum(abs(g[1] - r1) + abs(g[2] - n1) > 1e-9 for r in
    (-0.9, -0.6, -0.3, 0.0, 0.3, 0.6, 0.9) for n in (0.2, 0.5, 1.0, 2.0, 3.0) for g in [fit_newton(QUOTES, F, T1, r, n)]), d=0)
row("ATM equation: c2, c1, root of c1^2 + 4 c2 s", c2, c1, root)
row("alpha: quadratic, Newton from 0.20, large root", alpha_quad(S0, r1, n1, T1), alpha_newton(S0, F, r1, n1, T1, S0), big)
row("vertex alpha, peak ATM vol it allows", -c1 / (2 * c2), c1 * c1 / (-4 * c2))
row("edges: alpha at nu = 0, alpha at rho = 0", alpha_quad(S0, r1, 0.0, T1), alpha_quad(S0, 0.0, n1, T1))
aw = alpha_quad(S0, -0.999, 0.4, T1); tilt = hagan(K2, F, aw, -0.999, 0.4, T1) - hagan(K1, F, aw, -0.999, 0.4, T1)
row("widest tilt, nu 0.40, rho -0.999 (vol points)", 100 * tilt, d=4)
row("by hand at 92.15: ln(F/K), nu/alpha, z", log(F / K1), n1 / a1, z)
row("by hand at 92.15: chi, by Simpson, z/chi", chi(z, r1), chi_s, z / chi(z, r1))
row("by hand at 92.15: time factor, fitted vol", c1 + c2 * a1, hagan(K1, F, *P, T1))
for kind, K, q in (("put ", K1, S1), ("call", F, S0), ("call", K2, S2)):
    par = F - K if kind == "put " else 0.0                                   # put = call - (F - K)
    row(f"{kind} {K:6.2f}: fitted vol %, $ at fit, at quote", 100 * hagan(K, F, *P, T1),
        exp(-R * T1) * (call(K, F, P, T1) - par), exp(-R * T1) * (black(F, K, q, T1) - par))
ah = alpha_quad(S0, *HOUSE, T1); PH = (ah, *HOUSE); hv = [hagan(k, F, *PH, T1) for k in (K1, K2)]
hA, hR, hN, *_ = fit_newton(((K1, hv[0]), S0, (K2, hv[1])), F, T1)
row("house SABR: a, rho, nu, vols at the wings", ah, *HOUSE, 100 * hv[0], 100 * hv[1], d=4)
row("house round trip: a, rho, nu recovered", hA, hR, hN)
row("wrong: large root, vols at 92.15, 119.93 (%)", *[100 * hagan(k, F, big, r1, n1, T1) for k in (K1, K2)], d=4)
row("wrong: alpha = 0.20, ATM vol comes out (%)", 100 * hagan(F, F, S0, r1, n1, T1), d=4)
row("wrong: ATM read as $100, fitted vol there (%)", 100 * hagan(100.0, F, *P, T1), d=4)
(d1p, d1g), (d10p, d10g) = [(density_prices(40.0, Fw, P, T), density_g(40.0, Fw, P, T)) for Fw, T in ((F, T1), (F10, 10.0))]
row("nu^2 T at 1 year and at 10 years", n1 * n1, 10 * n1 * n1, d=4)
row("density at $40 x100, 1 year: prices, g", 100 * d1p, 100 * d1g)
row("density at $40 x100, 10 years: prices, g", 100 * d10p, 100 * d10g)
row("density at $40 x100, T = 1, 2, 3, 5, 10", *[100 * density_prices(40.0, fwd(t), P, t) for t in (1, 2, 3, 5, 10)], d=4)
row("10-year forward, fitted vol at $40 (%)", F10, 100 * hagan(40.0, F10, *P, 10.0), d=4)
row("10 years: D, calls at 30, 40, 50 (undiscounted)", exp(-R * 10), *[call(k, F10, P, 10.0) for k in (30, 40, 50)])
fly = lambda T, Fw: exp(-R * T) * (call(30, Fw, P, T) - 2 * call(40, Fw, P, T) + call(50, Fw, P, T))
simp = exp(-R * 10) * simpson(lambda x: (10 - abs(x - 40)) * density_g(x, F10, P, 10.0), 30.0, 50.0)
row("butterfly 30/40/50 today ($): 1 year, 10 years", fly(T1, F), fly(10.0, F10))
row("  10 years again, Simpson on tent x density", simp)
row("10 years: density changes sign at strikes", *[bisect(lambda k: density_prices(k, F10, P, 10.0), *ab) for ab in ((60, 130), (150, 300))], d=4)
row("at $40 density turns negative past T (years)", bisect(lambda t: density_prices(40, fwd(t), P, t), 1, 10), d=4)
row("try: Newton on the ATM vol from alpha = 10", alpha_newton(S0, F, r1, n1, T1, 10.0))
row("try: house, 10 years: x100 at $40, < 0 below", 100 * density_prices(40, F10, PH, 10), bisect(lambda k: density_prices(k, F10, PH, 10), 1, 40))
row("try: wings swapped (18% low, 24% high)", *fit_newton(((K1, S2), S0, (K2, S1)), F, T1)[:3])
print("chart strikes " + " ".join(f"{k:6d}" for k in range(80, 131, 5)))
print("chart fitted  " + " ".join(f"{100 * hagan(k, F, *P, T1):6.2f}" for k in range(80, 131, 5)))
print("chart house   " + " ".join(f"{100 * hagan(k, F, ah, *HOUSE, T1):6.2f}" for k in range(80, 131, 5)))
print("chart K       " + " ".join(f"{k:6d}" for k in range(20, 201, 20)))
print("chart 1y x100 " + " ".join(f"{100 * density_prices(k, F, P, T1):6.2f}" for k in range(20, 201, 20)))
print("chart 10y x100" + " ".join(f"{100 * density_prices(k, F10, P, 10.0):6.2f}" for k in range(20, 201, 20)))
assert max(abs(a1 - a2), abs(r1 - r2), abs(n1 - n2)) < 1e-9, "two roads to alpha, rho, nu"
assert max(abs(hagan(k, F, *P, T1) - s) for k, s in ((K1, S1), (F, S0), (K2, S2))) < 1e-12, "fit reprices the quotes"
assert abs(chi_s - chi(z, r1)) < 1e-10, "chi in closed form = its integral"
assert max(abs(hA - ah), abs(hR - HOUSE[0]), abs(hN - HOUSE[1])) < 1e-9, "house parameters recovered"
assert abs(d10p - d10g) < 1e-6 and abs(d1p - d1g) < 1e-6, "two density roads agree"
assert d10p < 0 < d1p, "negative at ten years, positive at one"
assert abs(simp - fly(10.0, F10)) < 1e-6, "butterfly price = discounted tent x density"
assert abs(det) > 1e-3 and strays == 0, "the fit is locally unique and every start finds it"
assert abs(alpha_newton(S0, F, r1, n1, T1, 10.0) - big) < 1e-9 and abs(hagan(F, F, big, r1, n1, T1) - S0) < 1e-12, "large root fits ATM too"
assert S2 - S1 < tilt < 0, "at nu = 0.4 even rho = -0.999 falls short of the quoted tilt"
print("ALL CHECKS PASS")
