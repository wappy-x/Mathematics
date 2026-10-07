# SABR for rates -- the check behind the card.  Standard library only: the normal CDF, root finders,
# integrator and the solvers are written here.  A 1-into-5 swaption smile, shifted SABR, and a small cube.
from math import log, exp, sqrt, pi

NOTIONAL, ANN, T, SHIFT = 1e6, 4.40, 1.0, 0.02          # $1m, annuity 4.40 years, 1-year expiry, 2% shift
S, QL, QA, QH = 0.025, 0.22625, 0.22, 0.22375           # forward swap rate F; quotes at F - 50bp, F, F + 50bp

def ncdf(x):                     # Marsaglia: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        t, i = s, i + 2.0
        b *= x * x / i
        s = t + b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def payer(s, k, vol, t, ann=ANN):  # shifted Black: N A [f N(d1) - k N(d2)], f and k both shifted
    f, kk, v = s + SHIFT, k + SHIFT, vol * sqrt(t)
    d1 = (log(f / kk) + 0.5 * v * v) / v
    return NOTIONAL * ann * (f * ncdf(d1) - kk * ncdf(d1 - v))
def bisect(fn, lo, hi, n=100):   # root of an increasing function
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if fn(mid) < 0.0 else (lo, mid)
    return 0.5 * (lo + hi)
def chi(z, rho): return log((sqrt(1.0 - 2.0 * rho * z + z * z) + z - rho) / (1.0 - rho))
def hagan(f, k, a, beta, rho, nu, t):   # Hagan et al. (2002), eq. 2.17, on shifted f and k
    e, lf = 1.0 - beta, log(f / k)
    fk = (f * k) ** (e / 2.0)
    z = nu / a * fk * lf
    zx = 1.0 if abs(z) < 1e-12 else z / chi(z, rho)
    back = fk * (1.0 + e * e / 24.0 * lf * lf + e * e * e * e / 1920.0 * (lf * lf * lf * lf))
    corr = e * e * a * a / (24.0 * fk * fk) + rho * beta * nu * a / (4.0 * fk) + (2.0 - 3.0 * rho * rho) * nu * nu / 24.0
    return a / back * zx * (1.0 + corr * t)
def smile(s, beta, rho, nu, atm, t):     # alpha retuned so the ATM quote is met; returns (alpha, vol at k)
    f = s + SHIFT
    a = bisect(lambda x: hagan(f, f, x, beta, rho, nu, t) - atm, 1e-6, 1.0)
    return a, (lambda k: hagan(f, k + SHIFT, a, beta, rho, nu, t))
def wings(s, beta, rho, nu, q, t):       # (vol at S - 50bp, vol at S + 50bp) with the ATM quote met
    v = smile(s, beta, rho, nu, q[1], t)[1]
    return v(s - 0.005), v(s + 0.005)
def read(s, beta, q):            # road 3: dials read off the near-money expansion, no solving
    f, yl, yh = s + SHIFT, log((s - 0.005 + SHIFT) / (s + SHIFT)), log((s + 0.005 + SHIFT) / (s + SHIFT))
    rl, rh = q[0] / q[1] - 1.0, q[2] / q[1] - 1.0            # ratio - 1 = slope y + curve y^2
    curve = (rl / yl - rh / yh) / (yl - yh)
    slope = rl / yl - curve * yl
    m = 2.0 * slope + (1.0 - beta)                            # rho * lambda
    lam = sqrt((12.0 * curve - (1.0 - beta) ** 2 + 3.0 * m * m) / 2.0)
    return slope, curve, m / lam, lam * q[1]                  # nu = lambda alpha / f^(1-beta) ~ lambda * ATM
def newton(s, beta, q, t, rho, nu):      # road 1: Newton on both wing equations at once
    for _ in range(40):
        lo, hi = wings(s, beta, rho, nu, q, t)
        r1, r2, h = lo - q[0], hi - q[2], 1e-6
        a1, a2 = wings(s, beta, rho + h, nu, q, t); b1, b2 = wings(s, beta, rho, nu + h, q, t)
        j11, j21, j12, j22 = (a1 - lo) / h, (a2 - hi) / h, (b1 - lo) / h, (b2 - hi) / h
        det = j11 * j22 - j12 * j21
        rho, nu = rho - (j22 * r1 - j12 * r2) / det, nu - (j11 * r2 - j21 * r1) / det
    return rho, nu
def nested(s, beta, q, t):       # road 2: outer bisection on nu for the butterfly, inner on rho for the RR
    rr, bf = q[2] - q[0], 0.5 * (q[0] + q[2]) - q[1]
    def rho_for(nu): return bisect(lambda r: (lambda w: w[1] - w[0])(wings(s, beta, r, nu, q, t)) - rr, -0.99, 0.99, 60)
    def fly(nu):
        w = wings(s, beta, rho_for(nu), nu, q, t)
        return 0.5 * (w[0] + w[1]) - q[1] - bf
    nu = bisect(fly, 0.05, 2.0, 60)
    return rho_for(nu), nu
def show(rows):
    for label, v in rows: print(f"{label:<44}{v:>14.6f}")

q = (QL, QA, QH)
f, rrbp, bfbp = S + SHIFT, 1e4 * (QH - QL), 1e4 * (0.5 * (QL + QH) - QA)
slope, curve, rho3, nu3 = read(S, 0.5, q)
rho1, nu1 = newton(S, 0.5, q, T, rho3, nu3)
rho2, nu2 = nested(S, 0.5, q, T)
al, vol = smile(S, 0.5, rho1, nu1, QA, T)
lf, akk = log(f / (S - 0.005 + SHIFT)), al / (f * (S - 0.005 + SHIFT)) ** 0.25
z = nu1 / akk * lf
corr = akk * akk / 96.0 + rho1 * nu1 * akk / 8.0 + (2.0 - 3.0 * rho1 * rho1) * nu1 * nu1 / 24.0
show((("shifted forward f = F + shift", f), ("risk reversal, vol bp (high - low)", rrbp),
      ("butterfly, vol bp (mean wing - ATM)", bfbp), ("road 3: slope of vol ratio in log-strike", slope),
      ("road 3: curvature of vol ratio", curve), ("road 3: rho, read", rho3), ("road 3: nu, read", nu3),
      ("road 1: rho, Newton", rho1), ("road 1: nu, Newton", nu1), ("road 2: rho, nested bisection", rho2),
      ("road 2: nu, nested bisection", nu2), ("alpha from the ATM quote", al), ("alpha / f^(1-beta)", al / sqrt(f)),
      ("lambda = nu f^(1-beta) / alpha", nu1 * sqrt(f) / al),
      ("K = 2.00%: ln(f / k)", lf), ("K = 2.00%: level alpha / (f k)^(1/4)", akk), ("K = 2.00%: z", z),
      ("K = 2.00%: chi(z)", chi(z, rho1)), ("K = 2.00%: z / chi(z)", z / chi(z, rho1)),
      ("K = 2.00%: divisor 1 + l^2/96 + l^4/30720", 1.0 + lf * lf / 96.0 + (lf * lf * lf * lf) / 30720.0),
      ("K = 2.00%: time factor", 1.0 + corr * T), ("K = 2.00%: fitted vol", vol(S - 0.005)),
      ("K = 3.00%: fitted vol", vol(S + 0.005))))
ks = [S + 0.0025 * i for i in range(-4, 5)]
fits = {b: newton(S, b, q, T, *read(S, b, q)[2:]) for b in (0.0, 0.5, 1.0)}
print("beta     rho       nu      alpha  " + "".join(f"{100 * k:7.2f}" for k in ks))
for b, (r, n) in fits.items():
    a, v = smile(S, b, r, n, QA, T)
    print(f"{b:4.1f}{r:9.4f}{n:9.4f}{a:11.6f}  " + "".join(f"{100 * v(k):7.2f}" for k in ks))
print("backbone: ATM vol % as F moves, dials held " + "".join(f"{1e4 * d:+7.0f}" for d in (-0.005, -0.0025, 0.0, 0.0025, 0.005)))
for b, (r, n) in fits.items():
    a = smile(S, b, r, n, QA, T)[0]
    print(f"  beta {b:3.1f}{'':34}" + "".join(f"{100 * hagan(S + d + SHIFT, S + d + SHIFT, a, b, r, n, T):7.2f}" for d in (-0.005, -0.0025, 0.0, 0.0025, 0.005)))
prem = [payer(S, k, vol(k), T) for k in ks]
v0, n_int = QA * sqrt(T), 4000
x0 = 0.5 * v0                             # at the money the payoff starts where x = v0 / 2
hh = (10.0 - x0) / n_int                  # second road for the premium: Simpson on E[(F_T - k)^+], x normal
g = [(f * exp(v0 * (x0 + i * hh) - 0.5 * v0 * v0) - f) * exp(-0.5 * (x0 + i * hh) ** 2) / sqrt(2 * pi) for i in range(n_int + 1)]
atm_int = NOTIONAL * ANN * hh / 3.0 * sum(y * (1 if i in (0, n_int) else 4 if i % 2 else 2) for i, y in enumerate(g))
flies = [prem[i - 1] - 2.0 * prem[i] + prem[i + 1] for i in range(1, 8)]
bb = {b: smile(S, b, *fits[b], QA, T)[0] for b in (0.0, 0.5, 1.0)}
up = [hagan(S + 0.0025 + SHIFT, S + 0.0025 + SHIFT, bb[b], b, *fits[b], T) for b in (0.0, 0.5, 1.0)]
show((("payer K = 2.00%, dollars", prem[2]), ("payer K = 2.50% (ATM), Black, dollars", prem[4]),
      ("payer K = 2.50% (ATM), Simpson integral", atm_int), ("payer K = 3.00%, dollars", prem[6]),
      ("ATM normal vol, bp, from the premium", 1e4 * prem[4] / (NOTIONAL * ANN) * sqrt(2 * pi / T)),
      ("smallest 25bp butterfly on the grid, dollars", min(flies)),
      ("wrong: shift dropped, ATM payer at 22%", NOTIONAL * ANN * S * (2.0 * ncdf(0.5 * QA * sqrt(T)) - 1.0)),
      ("wrong: alpha set to 0.22, ATM vol", hagan(f, f, 0.22, 0.5, rho1, nu1, T)),
      ("beta 0 fit: ATM vol after +25bp", up[0]), ("beta 1 fit: ATM vol after +25bp", up[2]),
      ("ATM payer after +25bp, beta 0, dollars", payer(S + 0.0025, S + 0.0025, up[0], T)),
      ("ATM payer after +25bp, beta 0.5, dollars", payer(S + 0.0025, S + 0.0025, up[1], T)),
      ("ATM payer after +25bp, beta 1, dollars", payer(S + 0.0025, S + 0.0025, up[2], T))))
cube = (("1y into 2y", 1.0, 0.015, (0.225, 0.200, 0.190)), ("1y into 5y", 1.0, 0.025, q),
        ("2y into 2y", 2.0, -0.005, (0.275, 0.240, 0.225)), ("2y into 5y", 2.0, 0.010, (0.245, 0.210, 0.190)))
print("cube node     F %   ATM %  RR bp  BF bp    alpha      rho       nu   miss bp")
miss = []
for name, t, s, qq in cube:
    r, n = newton(s, 0.5, qq, t, *read(s, 0.5, qq)[2:])
    w, a = wings(s, 0.5, r, n, qq, t), smile(s, 0.5, r, n, qq[1], t)[0]
    miss.append(1e4 * max(abs(w[0] - qq[0]), abs(w[1] - qq[2])))
    print(f"{name}{100 * s:7.2f}{100 * qq[1]:8.2f}{1e4 * (qq[2] - qq[0]):7.1f}{1e4 * (0.5 * (qq[0] + qq[2]) - qq[1]):7.1f}"
          f"{a:9.5f}{r:9.4f}{n:9.4f}{miss[-1]:10.6f}")
assert abs(rho1 - rho2) < 1e-8 and abs(nu1 - nu2) < 1e-8, "Newton and nested bisection land on the same dials"
assert abs(vol(S - 0.005) - QL) < 1e-10 and abs(vol(S + 0.005) - QH) < 1e-10, "fitted smile meets both wing quotes"
assert abs(akk * z / chi(z, rho1) * (1.0 + corr * T) / (1.0 + lf * lf / 96.0 + lf ** 4 / 30720.0) - vol(S - 0.005)) < 1e-12, "beta-1/2 hand formula = general Hagan"
assert abs(rho3 - rho1) < 0.05 and abs(nu3 / nu1 - 1.0) < 0.05, "the read-off dials sit near the exact fit"
assert abs(atm_int - prem[4]) < 1e-6 * prem[4], "Black formula vs Simpson integral at the money"
assert min(flies) > 0.0, "no negative butterfly on the grid"
assert up[0] < up[1] < up[2], "the lower the beta, the more the ATM vol falls as rates rise"
assert max(miss) < 1e-6, "every cube node fits its three quotes"
print("ALL CHECKS PASS")
