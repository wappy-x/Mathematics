# Stepping an SDE -- the check behind the card.  Standard library only.  Nothing is imported
# that already knows an answer: the bell-curve area comes from math.erf, every integral is
# Simpson's rule written out below, and the normal draws come from a generator written here.
from math import cos, erf, exp, expm1, log, log1p, pi, sin, sqrt
S0, K, RF, DIV, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
MU = RF - DIV                            # Acme's pretend-world drift, 3% a year
PATHS, FINE, GRIDS, SEED = 40000, 48, (1, 4, 12, 48), 20260919
V0, KAP, THETA, ETA2 = 0.09, log(2.0), 0.04, 0.08 * log(2.0)
def ncdf(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))     # bell-curve area to the left
def dens(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height
def row(name, v): print(f"{name:<45}{v:>13.6f}")

def simpson(f, a, b, n):                 # every integral on this card, written out
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def bs_call():                           # road 1: the Black-Scholes call price
    vt = SIG * sqrt(T)
    d1 = (log(S0 / K) + (MU + 0.5 * SIG * SIG) * T) / vt
    return S0 * exp(-DIV * T) * ncdf(d1) - K * exp(-RF * T) * ncdf(d1 - vt)
def rms_theory(n, mil):                  # road 4: exact terminal moments, no paths
    h, hi = T / n, (2.0 * MU + SIG * SIG) * T
    extra = 0.5 * SIG * SIG * SIG * SIG * h * h if mil else 0.0
    b, c = 2.0 * MU * h + MU * MU * h * h + SIG * SIG * h + extra, MU * h + SIG * SIG * h + extra
    gap = expm1(n * log1p(b) - hi) - 2.0 * expm1(MU * T + n * log1p(c) - hi)
    return S0 * sqrt(max(exp(hi) * gap, 0.0))
def normals(state, count):               # linear congruential bits, then Box-Muller
    out = []
    while len(out) < count:
        state = (1664525 * state + 1013904223) % 4294967296
        rad = sqrt(-2.0 * log((state + 0.5) / 4294967296.0))
        state = (1664525 * state + 1013904223) % 4294967296
        ang = 2.0 * pi * (state + 0.5) / 4294967296.0
        out += [rad * cos(ang), rad * sin(ang)]
    return state, out
def mean_se(a):                          # the sample mean and its standard error
    m = a[0] / PATHS
    return m, sqrt(max((a[1] - PATHS * m * m) / (PATHS - 1), 0.0) / PATHS)
def cond_moments(v, h, eta2):            # the exact variance law's two moments
    rr = exp(-KAP * h)
    return (v * rr + THETA * (1.0 - rr), eta2 * (v * rr * (1.0 - rr) + THETA * (1.0 - rr) * (1.0 - rr) / 2.0) / KAP)
def quad_branch(m, psi):                 # square a shifted normal: its scale and shift
    b2 = 2.0 / psi - 1.0 + sqrt(2.0 / psi) * sqrt(2.0 / psi - 1.0)
    return m / (1.0 + b2), sqrt(b2)
def moments(g, wt, lo, hi, n):           # mean and variance of g under the weight wt
    one = simpson(lambda x: g(x) * wt(x), lo, hi, n)
    return one, simpson(lambda x: g(x) * g(x) * wt(x), lo, hi, n) - one * one

def walk():                              # roads 2 and 3: exact, Euler, Milstein
    disc, root, dr = exp(-RF * T), sqrt(T / FINE), MU - 0.5 * SIG * SIG
    acc = {k: [0.0, 0.0] for k in [("ex", 0)] + [(t, g) for t in ("eb", "mb", "eq", "mq") for g in GRIDS]}
    state, neg, worst = SEED, {g: 0 for g in GRIDS}, 0.0
    for _ in range(PATHS):
        state, zs = normals(state, FINE)
        fine = [z * root for z in zs]    # Brownian increments on the fine grid
        st = S0 * exp(dr * T + SIG * sum(fine))
        led = S0
        for dw in fine:                  # the same terminal, stepped factor by factor
            led *= exp(dr * T / FINE + SIG * dw)
        worst = max(worst, abs(led - st) / st)
        ex = disc * max(st - K, 0.0)
        pairs = [(("ex", 0), ex)]
        for g in GRIDS:
            blk, h, y, m = FINE // g, T / g, S0, S0
            for i in range(0, FINE, blk):
                dw = sum(fine[i:i + blk])      # coarse increments, summed from fine
                y *= 1.0 + MU * h + SIG * dw
                m *= 1.0 + MU * h + SIG * dw + 0.5 * SIG * SIG * (dw * dw - h)
                neg[g] += y < 0.0
            pe, pm = disc * max(y - K, 0.0), disc * max(m - K, 0.0)
            pairs += [(("eb", g), pe - ex), (("mb", g), pm - ex),
                      (("eq", g), (y - st) * (y - st)), (("mq", g), (m - st) * (m - st))]
        for key, x in pairs:
            acc[key] = [acc[key][0] + x, acc[key][1] + x * x]
    return acc, neg, worst

bs, (acc, neg, worst) = bs_call(), walk()
ex_m, ex_se = mean_se(acc[("ex", 0)])
er, mr = [rms_theory(g, False) for g in GRIDS], [rms_theory(g, True) for g in GRIDS]
m1, w1 = cond_moments(V0, 1.0, ETA2); psi1 = w1 / (m1 * m1)
a1, b1 = quad_branch(m1, psi1)
mo, so = V0, V0 * V0                     # road 5: m and w again, by stepping the two equations they obey
for _ in range(50000): mo, so = mo + 2e-5 * KAP * (THETA - mo), so + 2e-5 * (2.0 * KAP * THETA * mo - 2.0 * KAP * so + ETA2 * mo)
qm, qv = moments(lambda z: a1 * (b1 + z) * (b1 + z), dens, -10.0, 10.0, 20000)
eu_m, eu_s = V0 + KAP * (THETA - V0) * T, sqrt(ETA2 * V0 * T)
zstar = -eu_m / eu_s                     # below this the plain Euler reading is negative
pneg, pquad = ncdf(zstar), simpson(lambda v: dens((v - eu_m) / eu_s) / eu_s, -1.0, 0.0, 20000)
ft_m, ft_v = moments(lambda z: eu_m + eu_s * z, dens, zstar, 10.0, 20000)
ft_closed = eu_m * ncdf(-zstar) + eu_s * dens(zstar)
m2, w2 = cond_moments(V0, 1.0, 4.0 * ETA2); psi2 = w2 / (m2 * m2)
p2 = (psi2 - 1.0) / (psi2 + 1.0); be2 = (1.0 - p2) / m2
xm, xv = moments(lambda y: y, lambda y: (1.0 - p2) * be2 * exp(-be2 * y), 0.0, 40.0 / be2, 20000)
print(f"Acme: S={S0:.2f} K={K:.2f} r={RF * 100:.0f}% q={DIV * 100:.0f}% sigma={SIG * 100:.0f}% T={T:.0f} year, drift r-q={MU * 100:.0f}%; {PATHS} paths of {FINE} fine steps")
row("road 1, Black-Scholes call", bs)
row("road 2, exact lognormal stepping", ex_m)
row("  its standard error", ex_se)
print(f"{'48 factors against one exponential agree':<45}{'yes' if worst < 1e-12 else 'no':>13}")
print(f"{'steps':>6}{'h':>10}{'price':>11}{'bias, cents':>13}{'se, cents':>11}{'rms':>10}{'rms theory':>12}  scheme")
for tag, lab, th in (("eb", "Euler", er), ("mb", "Milstein", mr)):
    for j, g in enumerate(GRIDS):
        b, bse = mean_se(acc[(tag, g)])
        print(f"{g:>6}{T / g:>10.6f}{ex_m + b:>11.6f}{100 * b:>13.2f}{100 * bse:>11.2f}"
              f"{sqrt(acc[(tag[0] + 'q', g)][0] / PATHS):>10.6f}{th[j]:>12.6f}  {lab}")
for name, v in [
        ("error ratio, 12 steps against 48, Euler", er[2] / er[3]), ("  the same ratio, Milstein", mr[2] / mr[3]),
        ("Euler terminal mean, 12 steps", S0 * (1.0 + MU * T / 12.0) ** 12), ("  the exact terminal mean", S0 * exp(MU * T)),
        ("supplied input dW = -6, Euler stock reading", S0 * (1.0 + MU * T - 6.0 * SIG)),
        ("  the exact exponential reading there", S0 * exp((MU - 0.5 * SIG * SIG) * T - 6.0 * SIG)),
        ("Euler stock reading turns negative below dW", -(1.0 + MU * T) / SIG),
        ("  its chance per step, parts per ten million", 1e7 * ncdf(-(1.0 + MU * T) / SIG)),
        ("variance now, v", V0), ("pull-back speed kappa", KAP), ("resting variance theta", THETA), ("variance volatility eta", sqrt(ETA2)),
        ("2 kappa theta", 2.0 * KAP * THETA), ("eta squared", ETA2), ("exact conditional mean m", m1), ("exact conditional variance w", w1),
        ("  the same m from the moment equations", mo), ("  the same w from the moment equations", so - mo * mo), ("relative spread psi = w / m squared", psi1),
        ("plain Euler mean", eu_m), ("plain Euler variance", eu_s * eu_s), ("plain Euler chance of a negative reading", pneg),
        ("  the same chance by quadrature", pquad), ("floored Euler mean, by quadrature", ft_m),
        ("  the same mean in closed form", ft_closed), ("floored Euler variance, by quadrature", ft_v),
        ("QE shift b", b1), ("QE scale a", a1), ("QE mean, by quadrature", qm), ("QE variance, by quadrature", qv),
        ("noise doubled: variance w", w2), ("noise doubled: relative spread psi", psi2),
        ("noise doubled: mass p at zero", p2), ("noise doubled: rate beta", be2), ("noise doubled: mean, by quadrature", xm),
        ("noise doubled: variance, by quadrature", xv)]:
    row(name, v)
print("negative Euler stock readings: " + ", ".join(f"{g} steps {neg[g]}" for g in GRIDS))
assert abs(bs - 9.227005508154) < 1e-9           # road 1 against the house number
assert abs(ex_m - bs) < 4.0 * ex_se              # road 2 against road 1
assert worst < 1e-12                             # 48 factors against one exponential
for j, g in enumerate(GRIDS):                    # sampled spread against the moments
    assert abs(sqrt(acc[("eq", g)][0] / PATHS) / er[j] - 1.0) < 0.06
    assert abs(sqrt(acc[("mq", g)][0] / PATHS) / mr[j] - 1.0) < 0.06
    assert mr[j] < 0.30 * er[j]                  # the correction earns its place
assert abs(er[2] / er[3] - 2.0) < 0.05           # Euler: halved by fourfold refinement
assert abs(mr[2] / mr[3] - 4.0) < 0.10           # Milstein: quartered by the same
assert mean_se(acc[("mb", 12)])[0] < -0.015 and abs(mean_se(acc[("eb", 12)])[0]) < 2.0 * mean_se(acc[("eb", 12)])[1]   # Milstein cheap, Euler inside its wobble
assert abs(mo - m1) < 1e-6 and abs(so - mo * mo - w1) < 1e-6   # road 5 against the closed form
assert abs(qm - m1) < 1e-9 and abs(qv - w1) < 1e-9   # quadrature against the QE algebra
assert abs(xm - m2) < 1e-9 and abs(xv - w2) < 1e-9
assert abs(pquad - pneg) < 1e-9                  # Simpson against erf
assert abs(ft_m - ft_closed) < 1e-9              # quadrature against the closed form
assert ft_v > 1.5 * w1                           # the floor does not fix the spread
print("ALL CHECKS PASS")
