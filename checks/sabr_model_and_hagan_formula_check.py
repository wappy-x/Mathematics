# SABR and Hagan's formula -- the check behind the card.  Standard library only: the normal CDF, root
# finders, integrator and random numbers are written here.  Hagan's formula meets two simulations of SABR.
from math import log, exp, sqrt, cos, sin, pi, acosh

F, R, T, RHO, NU, ATM = 100.0 * exp(0.05 - 0.02), 0.05, 1.0, -0.3, 0.4, 0.20
KS, M64 = [60.0, 70.0, 80.0, 92.15, 100.0, F, 110.0, 119.93, 130.0, 140.0], (1 << 64) - 1

def ncdf(x):                     # Marsaglia: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        t, i = s, i + 2.0
        b *= x * x / i
        s = t + b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def black(f, k, vol, t):         # Black-76 call on forward f, not yet discounted
    v = vol * sqrt(t)
    d1 = (log(f / k) + 0.5 * v * v) / v
    return f * ncdf(d1) - k * ncdf(d1 - v)
def bisect(fn, lo, hi):          # root of an increasing function, 100 halvings
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if fn(mid) < 0.0 else (lo, mid)
    return 0.5 * (lo + hi)
def chi(z, rho): return log((sqrt(1.0 - 2.0 * rho * z + z * z) + z - rho) / (1.0 - rho))
def hagan(k, a, t, beta=1.0, rho=RHO, nu=NU):      # Hagan et al. (2002), any beta
    fk, lf, e = (F * k) ** ((1.0 - beta) / 2.0), log(F / k), 1.0 - beta
    z = nu / a * fk * lf
    zx = 1.0 if abs(z) < 1e-12 else z / chi(z, rho)
    back = fk * (1.0 + e * e / 24.0 * lf * lf + e * e * e * e / 1920.0 * lf * lf * lf * lf)
    corr = e * e / 24.0 * a * a / (fk * fk) + rho * beta * nu * a / (4.0 * fk) \
        + (2.0 - 3.0 * rho * rho) / 24.0 * nu * nu
    return a / back * zx * (1.0 + corr * t)
def alpha_quadratic(t, rho=RHO):  # beta = 1: b a^2 + (1 + c t) a = ATM, the small root
    c, b = (2.0 - 3.0 * rho * rho) / 24.0 * NU * NU, rho * NU * t / 4.0
    return 2.0 * ATM / ((1.0 + c * t) + sqrt((1.0 + c * t) * (1.0 + c * t) + 4.0 * b * ATM))
def normals(seed):               # splitmix64 integers, then Box-Muller: two normals per two uniforms
    s, u = seed, [0.0, 0.0]
    while True:
        for j in range(2):
            s = (s + 0x9E3779B97F4A7C15) & M64
            z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
            z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
            u[j] = ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
        r, th = sqrt(-2.0 * log(u[0])), 2.0 * pi * u[1]
        yield from (r * cos(th), r * sin(th))
def simulate(t, a, pairs, steps, seed, mixing):  # (price, se, implied vol, its se) per strike
    rng, dt, xs, ps = normals(seed), t / steps, [], []
    for _ in range(pairs):
        zs, x, p = [(next(rng), 0.0 if mixing else next(rng)) for _ in range(steps)], 0.0, [0.0] * len(KS)
        for sign in (1.0, -1.0):                   # antithetic: each path and its mirror image
            al, var, lf = a, 0.0, log(F)
            for z2, z1 in zs:
                nxt = al * exp(sign * NU * sqrt(dt) * z2 - 0.5 * NU * NU * dt)  # vol: exact step
                var += 0.5 * (al * al + nxt * nxt) * dt                         # road 2: its variance
                lf += al * sqrt(dt) * sign * (RHO * z2 + sqrt(1.0 - RHO * RHO) * z1) - 0.5 * al * al * dt
                al = nxt                                                        # road 3: Euler on log F
            fe = F * exp(RHO / NU * (al - a) - 0.5 * RHO * RHO * var) if mixing else exp(lf)
            vol = sqrt((1.0 - RHO * RHO) * var / t)  # road 2: given the vol path, F_T is lognormal
            x += 0.5 * (fe - F)
            p = [pj + 0.5 * (black(fe, k, vol, t) if mixing else max(fe - k, 0.0)) for pj, k in zip(p, KS)]
        xs.append(x); ps.append(p)
    n, out, mx = float(pairs), [], sum(xs) / pairs  # control variate: the forward averages to F
    vx = sum((x - mx) * (x - mx) for x in xs) / n
    for j, k in enumerate(KS):
        mp = sum(p[j] for p in ps) / n
        bj = sum((x - mx) * (p[j] - mp) for x, p in zip(xs, ps)) / n / vx
        se = sqrt(sum((p[j] - mp - bj * (x - mx)) ** 2 for x, p in zip(xs, ps)) / n / n)
        iv = bisect(lambda s: black(F, k, s, t) - (mp - bj * mx), 1e-4, 2.0)
        vega = (black(F, k, iv + 1e-4, t) - black(F, k, iv - 1e-4, t)) / 2e-4
        out.append((mp - bj * mx, se, iv, se / vega))
    return out
def geodesic(k, a):              # shortest distance to the strike's line, by golden-section search
    s, l, g, lo, hi = sqrt(1.0 - RHO * RHO), log(k / F), (sqrt(5.0) - 1.0) / 2.0, 1e-4, 5.0
    def d(v):                    # hyperbolic distance from today's point to the point of the line at vol v
        du = -RHO * a / s - (NU * l - RHO * v) / s
        return acosh(1.0 + (du * du + (a - v) * (a - v)) / (2.0 * a * v)) / NU
    for _ in range(200):
        m1, m2 = hi - g * (hi - lo), lo + g * (hi - lo)
        lo, hi = (lo, m2) if d(m1) < d(m2) else (m1, hi)
    return d(0.5 * (lo + hi)), 0.5 * (lo + hi)
def show(rows):
    for label, v in rows: print(f"{label:<44}{v:>12.6f}")

a, c, b = alpha_quadratic(T), (2.0 - 3.0 * RHO * RHO) / 24.0 * NU * NU, RHO * NU * T / 4.0
a2, z, q = bisect(lambda x: hagan(F, x, T) - ATM, 1e-4, 3.0), NU / a * log(F / 92.15), RHO * NU * a / 4.0
(dist, v_dn), h = geodesic(92.15, a), z / 2000  # Simpson's rule on the slope of chi, 2000 slices
slope = [1.0 / sqrt(1.0 - 2.0 * RHO * w * h + w * h * w * h) for w in range(2001)]
chi_int = h / 3.0 * sum(y * (1 if i in (0, 2000) else 4 if i % 2 else 2) for i, y in enumerate(slope))
show((("forward F = 100 e^(0.05 - 0.02)", F), ("c = (2 - 3 rho^2) nu^2 / 24", c), ("b = rho nu T / 4", b),
      ("alpha, quadratic formula (beta = 1)", a), ("alpha, bisection on Hagan's ATM vol", a2),
      ("alpha, the quadratic's other root", -(1.0 + c * T) / b - a),
      ("ATM vol at the parabola's peak", (1.0 + c * T) ** 2 / (-4.0 * b)), ("Hagan's vol at K = F", hagan(F, a, T)),
      ("skew rho nu / 2", RHO * NU / 2.0), ("curvature (2 - 3 rho^2) nu^2 / (12 alpha)", 2.0 * c / a),
      ("K = 92.15: ln(F / K)", log(F / 92.15)), ("K = 92.15: z", z),
      ("K = 92.15: sqrt(1 - 2 rho z + z^2)", sqrt(1.0 - 2.0 * RHO * z + z * z)),
      ("K = 92.15: chi(z), closed form", chi(z, RHO)), ("K = 92.15: chi(z), Simpson integral", chi_int),
      ("K = 92.15: nu times shortest distance", NU * dist), ("K = 92.15: z / chi(z)", z / chi(z, RHO)),
      ("rho nu alpha / 4", q), ("time factor 1 + (rho nu alpha / 4 + c) T", 1.0 + (q + c) * T),
      ("K = 92.15: Hagan's vol", hagan(92.15, a, T)), ("K = 92.15: arrival vol, by search", v_dn),
      ("K = 119.93: arrival vol, by search", geodesic(119.93, a)[1])))

hag = [hagan(k, a, T) for k in KS]                  # road 1: the formula
mix = simulate(T, a, 200000, 20, 1, True)           # road 2: vol paths, exact lognormal given each
eul = simulate(T, a, 40000, 50, 2, False)           # road 3: both equations stepped by Euler
print("strike  Hagan %  mixing %   se vp  Euler %    se vp   gap vp")
for k, hk, m, e in zip(KS, hag, mix, eul):
    print(f"{k:6.2f}" + "".join(f"{100 * v:9.3f}" for v in (hk, m[2], m[3], e[2], e[3])) + f"{100 * (hk - m[2]):+9.3f}")
D, a10, ap = exp(-R * T), alpha_quadratic(10.0), alpha_quadratic(T, 0.0)
print("dollars, discounted      Hagan   simulated")
for k, kind in ((92.15, "put"), (100.0, "call"), (119.93, "call")):
    j, cut = KS.index(k), (F - k if kind == "put" else 0.0)
    print(f"{kind + f' K = {k:.2f}':<21}{D * (black(F, k, hag[j], T) - cut):9.4f}{D * (mix[j][0] - cut):12.4f}")
mix10, ab = simulate(10.0, a10, 10000, 100, 3, True), bisect(lambda x: hagan(F, x, T, 0.5) - ATM, 1e-4, 3.0 * sqrt(F))
show((("house call K = 100 at a flat 20%, dollars", D * black(F, 100.0, ATM, T)),
      ("wrong: alpha read as the ATM vol", hagan(F, ATM, T)),
      ("wrong: flat 20%, put K = 92.15, dollars", D * (black(F, 92.15, ATM, T) - F + 92.15)),
      ("wrong: rho = +0.3, vol at 92.15", hagan(92.15, a, T, 1.0, 0.3)),
      ("wrong: rho = +0.3, vol at 119.93", hagan(119.93, a, T, 1.0, 0.3)),
      ("try: rho = 0, vol at 92.15", hagan(92.15, ap, T, 1.0, 0.0)),
      ("try: rho = 0, vol at F^2 / 92.15 = 115.23", hagan(F * F / 92.15, ap, T, 1.0, 0.0)),
      ("try: beta = 0.5, alpha", ab), ("try: beta = 0.5, vol at 92.15", hagan(92.15, ab, T, 0.5)),
      ("try: beta = 0.5, vol at 119.93", hagan(119.93, ab, T, 0.5))))
print(f"{'chart, strike':<23}" + "".join(f"{k:7.2f}" for k in KS))
for label, vals in (("chart, Hagan 1y %", hag), ("chart, simulated 1y %", [m[2] for m in mix]),
                    ("chart, Hagan 10y %", [hagan(k, a10, 10.0) for k in KS]),
                    ("chart, simulated 10y %", [m[2] for m in mix10])):
    print(f"{label:<23}" + "".join(f"{100 * v:7.2f}" for v in vals))
gap = [hk - m[2] for hk, m in zip(hag, mix)]
assert abs(a - a2) < 1e-12, "closed-form alpha vs bisection on the whole formula"
assert abs(chi(z, RHO) - chi_int) < 1e-10, "chi in closed form vs Simpson's rule on its slope"
assert abs(chi(z, RHO) - NU * dist) < 1e-9 and abs(v_dn - a * sqrt(1.0 - 2.0 * RHO * z + z * z)) < 1e-7, \
    "chi and the arrival vol, closed form vs the search"
for m, e in zip(mix, eul):
    assert abs(m[0] - e[0]) < 4.0 * sqrt(m[1] * m[1] + e[1] * e[1]), "the two simulations agree within noise"
for k in (92.15, 100.0, 119.93):
    assert abs(gap[KS.index(k)]) < 0.0005, "Hagan within 0.05 vol points of the model at one year"
assert gap[0] > gap[2] > gap[3] > gap[7], "the gap widens toward low strikes"
assert hagan(F, a10, 10.0) - mix10[5][2] > 0.01, "at ten years Hagan overstates the ATM vol by over a point"
print("ALL CHECKS PASS")
