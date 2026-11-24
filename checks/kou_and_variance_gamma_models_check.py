# Kou and variance gamma -- the check behind the card.  Standard library only.  Written out here: complex
# exp and log, Marsaglia's bell-curve series, COS, the inversion integral, Simpson, the house recurrence, Box-Muller.
from math import atan2, cos, exp, hypot, log, pi, sin, sqrt
S, K, R, Q, T = 100.0, 100.0, 0.05, 0.02, 1.0               # the house market
SIG, LAM, P, E1, E2 = 0.20, 1.0, 0.4, 10.0, 5.0              # Kou
VS, NU, TH = 0.20, 0.20, -0.14                               # variance gamma
SEED, PATHS, MOD, STRIKES = 20261123, 1000000, 1 << 32, (70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0)
def cexp(z): return exp(z.real) * complex(cos(z.imag), sin(z.imag))
def clog(z): return complex(log(hypot(z.real, z.imag)), atan2(z.imag, z.real))
def cdiv(a, b): return complex(a * b.real / (b.real * b.real + b.imag * b.imag), -a * b.imag / (b.real * b.real + b.imag * b.imag))
def n_cdf(x):                               # area left of x, Marsaglia's series
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t: t, i = s, i + 2.0; b *= x * x / i; s = t + b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def bs(k, sig, t=T):                        # Black-Scholes call, spot S, yield Q
    v = sig * sqrt(t); d1 = (log(S / k) + (R - Q + 0.5 * sig * sig) * t) / v
    return S * exp(-Q * t) * n_cdf(d1) - k * exp(-R * t) * n_cdf(d1 - v)
def zeta(p=P): return p * E1 / (E1 - 1.0) + (1.0 - p) * E2 / (E2 + 1.0) - 1.0   # E[e^J] - 1
def omega(th=TH, nu=NU): return log(1.0 - th * nu - 0.5 * VS * VS * nu) / nu
def kou(z, t=T, lam=LAM, p=P, comp=None):   # ln E[e^(zY)], Y = ln(S_T / S), z complex
    mu = R - Q - 0.5 * SIG * SIG - lam * (zeta(p) if comp is None else comp)
    return t * (z * mu + 0.5 * SIG * SIG * z * z + lam * (cdiv(p * E1, E1 - z) + cdiv((1.0 - p) * E2, E2 + z) - 1.0))
def vg(z, t=T, th=TH, nu=NU, w=None):       # ln E[e^(zY)] for variance gamma
    return z * ((R - Q + (omega(th, nu) if w is None else w)) * t) - t / nu * clog(1.0 - th * nu * z - 0.5 * VS * VS * nu * z * z)
def cos_call(f, k=K, t=T, a=-6.0, b=6.0, modes=512):   # road 1: COS put, then parity
    L, d, tot = b - a, min(b, log(k / S)), 0.0
    for n in range(modes if d > a else 0):
        w = n * pi / L
        fn = 2.0 / L * cexp(f(complex(0.0, w), t) - complex(0.0, w * a)).real
        psi = d - a if n == 0 else sin(w * (d - a)) / w
        chi = (exp(d) * (cos(w * (d - a)) + w * sin(w * (d - a))) - exp(a)) / (1.0 + w * w)
        tot += (0.5 if n == 0 else 1.0) * fn * 2.0 / L * (k * psi - S * chi)
    return exp(-R * t) * L / 2.0 * tot + S * exp(-Q * t) - k * exp(-R * t)
def gp_call(f, k=K, t=T, h=0.02, top=5000):  # road 2: invert for the two chances
    x, g1, p1, p2 = log(k / S), f(complex(1.0, 0.0), t).real, 0.0, 0.0
    for j in range(top):                    # Re[w / (iu)] = Im(w) / u
        u = (j + 0.5) * h
        p2 += cexp(complex(0.0, -u * x) + f(complex(0.0, u), t)).imag / u
        p1 += cexp(complex(0.0, -u * x) + f(complex(1.0, u), t) - g1).imag / u
    return S * exp(g1 - R * t) * (0.5 + p1 * h / pi) - k * exp(-R * t) * (0.5 + p2 * h / pi)
def simpson(f, lo, hi, n=4000):
    h = (hi - lo) / n
    return h / 3.0 * sum((1.0 if i in (0, n) else 4.0 if i % 2 else 2.0) * f(lo + i * h) for i in range(n + 1))
def vg_mix(k=K):                            # road 3: Black-Scholes on each gamma clock
    shape, w = T / NU, omega()
    dens = lambda g: g ** (shape - 1.0) * exp(-g / NU) / (24.0 * NU ** shape) if g > 0 else 0.0  # 24 = 4! = Gamma(T/NU): T/NU = 5 only
    fwd = lambda g: S * exp((R - Q + w) * T + TH * g + 0.5 * VS * VS * g)
    def call(g):
        v = VS * sqrt(g)
        d1 = (log(fwd(g) / k) + 0.5 * v * v) / v
        return exp(-R * T) * (fwd(g) * n_cdf(d1) - k * n_cdf(d1 - v))
    return simpson(lambda g: dens(g) * call(g) if g > 0 else 0.0, 0.0, 8.0), simpson(lambda g: dens(g) * fwd(g), 0.0, 8.0)
def cumulants(model, t=T):                  # closed form: variance, skew, excess kurtosis
    if model == "kou":
        m = lambda n, f: LAM * f * (P / E1 ** n + (1 - P) * (-1) ** n / E2 ** n)   # f = n!
        c2, c3, c4 = (SIG * SIG + m(2, 2)) * t, m(3, 6) * t, m(4, 24) * t
    else:
        c2, c3 = (VS ** 2 + TH ** 2 * NU) * t, (2 * TH ** 3 * NU ** 2 + 3 * VS ** 2 * TH * NU) * t
        c4 = (3 * VS ** 4 * NU + 12 * VS ** 2 * TH ** 2 * NU ** 2 + 6 * TH ** 4 * NU ** 3) * t
    return c2, c3 / c2 ** 1.5, c4 / c2 ** 2
def fd_cumulants(f, h=0.01):                # differences of ln E[e^(zY)] at real z
    g = [f(complex(j * h, 0.0)).real for j in (-2, -1, 0, 1, 2)]
    c2, c3 = (g[3] - 2 * g[2] + g[1]) / h ** 2, (g[4] - 2 * g[3] + 2 * g[1] - g[0]) / (2 * h ** 3)
    return c2, c3 / c2 ** 1.5, (g[4] - 4 * g[3] + 6 * g[2] - 4 * g[1] + g[0]) / h ** 4 / c2 ** 2
def implied(price, k, t=T):                 # bisection: Black-Scholes rises with vol
    lo, hi = 1e-4, 3.0
    for _ in range(100): mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if bs(k, mid, t) < price else (lo, mid)
    return 0.5 * (lo + hi)
def uniform(state):                         # the house recurrence
    state = (1664525 * state + 1013904223) % MOD
    return state, (state + 0.5) / MOD
def simulate(model):                        # road 4: real jumps, or a real gamma clock
    state, disc, e0, sums = SEED, exp(-R * T), exp(-LAM * T), [0.0] * 8
    for _ in range(PATHS):
        state, u = uniform(state)
        state, v = uniform(state)
        z = sqrt(-2.0 * log(u)) * cos(2.0 * pi * v)        # Box-Muller, cosine half
        if model == "kou":
            x, prod = (R - Q - 0.5 * SIG * SIG - LAM * zeta()) * T + SIG * sqrt(T) * z, 1.0
            while True:                     # Knuth's Poisson count, one jump per pass
                state, u = uniform(state); prod *= u
                if prod <= e0: break
                state, u = uniform(state); x += -log(u / P) / E1 if u < P else log((u - P) / (1.0 - P)) / E2
        else:
            g = 0.0
            for _ in range(5): state, u = uniform(state); g -= NU * log(u)   # gamma clock: T/NU = 5 waits, mean nu
            x = (R - Q + omega()) * T + TH * g + VS * sqrt(g) * z
        pay, st = disc * max(S * exp(x) - K, 0.0), disc * S * exp(x)
        for i, v in enumerate((pay, pay * pay, st, st * st, x, x * x, x * x * x, x * x * x * x)): sums[i] += v
    m = [v / PATHS for v in sums]
    var, c3 = m[5] - m[4] ** 2, m[6] - 3 * m[4] * m[5] + 2 * m[4] ** 3
    c4 = m[7] - 4 * m[4] * m[6] + 6 * m[4] ** 2 * m[5] - 3 * m[4] ** 4
    return m[0], sqrt((m[1] - m[0] ** 2) / PATHS), m[2], sqrt((m[3] - m[2] ** 2) / PATHS), var, c3 / var ** 1.5, c4 / var ** 2 - 3.0
row = lambda name, v: print(f"{name:<46}{v:>12.6f}")
print("house: S 100, K 100, r 5%, q 2%, T 1; Kou: sigma 0.20, lambda 1, p 0.4, eta1 10, eta2 5; VG: sigma 0.20, nu 0.20, theta -0.14")
for name, v in (("Kou up part, p eta1/(eta1 - 1)", P * E1 / (E1 - 1)), ("Kou down part, (1 - p) eta2/(eta2 + 1)", (1 - P) * E2 / (E2 + 1)),
                ("Kou compensator zeta", zeta()), ("Kou drift r - q - sigma^2/2 - lambda zeta", R - Q - 0.5 * SIG * SIG - LAM * zeta()),
                ("VG inside the log, 1 - theta nu - sigma^2 nu/2", 1 - TH * NU - 0.5 * VS * VS * NU),
                ("VG martingale correction omega", omega()), ("VG drift r - q + omega", R - Q + omega())): row(name, v)
print(f"E[S_T]/S from the exponent at z = 1: Kou {cexp(kou(complex(1.0, 0.0))).real:.6f}, "
      f"VG {cexp(vg(complex(1.0, 0.0))).real:.6f}; forward factor e^(r - q)T {exp((R - Q) * T):.6f}")
sims = {m: simulate(m) for m in ("kou", "vg")}
print("model  how        variance      skew  ex. kurt")
for m, f in (("kou", kou), ("vg", vg)):
    for how, c in (("closed", cumulants(m)), ("differ", fd_cumulants(f)), ("simul", sims[m][4:]), ("3 months", cumulants(m, 0.25))):
        print(f"{m:<5}  {how:<8} {c[0]:>9.6f}  {c[1]:>8.4f}  {c[2]:>8.4f}")
print("COS modes      Kou call     VG call")
for M in (32, 64, 128, 256, 512): print(f"{M:>9}  {cos_call(kou, modes=M):>10.6f}  {cos_call(vg, modes=M):>10.6f}")
ck, cv, (cm, fm), gk, gv = cos_call(kou), cos_call(vg), vg_mix(), gp_call(kou), gp_call(vg)
kw, vw = lambda **a: lambda z, t: kou(z, t, **a), lambda **a: lambda z, t: vg(z, t, **a)   # one input changed
vk, vv = sqrt(cumulants("kou")[0]), sqrt(cumulants("vg")[0])
for name, v in (("Kou road 1  COS, 512 modes", ck), ("Kou road 2  inversion integral", gk),
                ("Kou road 4  simulation", sims["kou"][0]), ("            standard error", sims["kou"][1]),
                (f"Kou simulated e^-rT S_T (S e^-qT {S * exp(-Q * T):.6f})", sims["kou"][2]), ("            standard error", sims["kou"][3]),
                ("VG  road 1  COS, 512 modes", cv), ("VG  road 2  inversion integral", gv), ("VG  road 3  gamma-clock Black-Scholes", cm),
                ("VG  road 4  simulation", sims["vg"][0]), ("            standard error", sims["vg"][1]),
                ("VG simulated e^-rT S_T", sims["vg"][2]), ("            standard error", sims["vg"][3]), ("VG gamma clock: forward averaged", fm),
                ("Kou with lambda = 0 (house Black-Scholes)", cos_call(kw(lam=0.0))), ("wrong: Kou, no compensator", gp_call(kw(comp=0.0))),
                ("wrong: Kou, compensator from mean log jump", gp_call(kw(comp=P / E1 - (1 - P) / E2))),
                ("wrong: VG, no omega", gp_call(vw(w=0.0))), ("wrong: VG, omega with the sign flipped", gp_call(vw(w=-omega()))),
                ("wrong: VG no omega, call by parity", cos_call(vw(w=0.0))), (f"wrong: one vol for Kou, {vk * 100:.2f}%", bs(K, vk)),
                (f"wrong: one vol for VG, {vv * 100:.2f}%", bs(K, vv))): row(name, v)
ivk, ivv = [implied(cos_call(kou, k), k) for k in STRIKES], [implied(cos_call(vg, k), k) for k in STRIKES]
print("strike         " + "".join(f"{k:>8.0f}" for k in STRIKES))
print("Kou implied %  " + "".join(f"{v * 100:>8.2f}" for v in ivk))
print("VG implied %   " + "".join(f"{v * 100:>8.2f}" for v in ivv))
ks = [S * exp((R - Q) * T + x) for x in (-0.2, 0.0, 0.2)]   # strikes evenly spaced in log terms around the forward
print(f"try: Kou p = 0.6 call {cos_call(kw(p=0.6)):.6f}; VG theta = 0 implied % at " + ", ".join(f"{k:.2f}" for k in ks) + ": "
      + ", ".join(f"{implied(cos_call(vw(th=0.0), k), k) * 100:.2f}" for k in ks))
assert abs(cos_call(kw(lam=0.0)) - 9.227005508154) < 1e-8, "no jumps: the house call"
assert abs(gk - ck) < 1e-7 and abs(gv - cv) < 1e-7, "inversion integral lands on COS"
assert abs(cm - cv) < 1e-7 and abs(fm - S * exp((R - Q) * T)) < 1e-7, "gamma clock lands on COS and on the forward"
for m, c, f in (("kou", ck, kou), ("vg", cv, vg)):
    mc, se, fw, fse = sims[m][:4]
    assert abs(mc - c) < 3.0 * se and abs(fw - S * exp(-Q * T)) < 3.0 * fse, "simulation backs the transform"
    assert max(abs(a - b) for a, b in zip(cumulants(m), fd_cumulants(f))) < 1e-3, "cumulants from the exponent"
    assert abs(sims[m][5] - cumulants(m)[1]) < 0.05 and abs(sims[m][6] - cumulants(m)[2]) < 0.3, "simulated shape"
assert ivk[0] > ivk[3] > ivk[6] and ivv[0] > ivv[3] > ivv[6], "both lean to the left"
print("ALL CHECKS PASS")
