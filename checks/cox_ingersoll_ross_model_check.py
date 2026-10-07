# Cox-Ingersoll-Ross: the 5-year zero four ways, and the same bond under Vasicek.
# Standard library only. Random numbers, ODE solver and PDE grid are written here.
from math import exp, log, sqrt, cos, sin, pi

K, TH, SIG, R0, T = 0.3, 0.05, 0.05, 0.04, 5.0    # CIR: pull, target, noise per root-rate
SIG_V = 0.01                                      # Vasicek noise: the shelf's house example

def cir_AB(tau, k=K, th=TH, s=SIG, two=2.0):     # road 1: the closed form
    g = sqrt(k * k + two * s * s)
    e = exp(g * tau); den = (g + k) * (e - 1.0) + 2.0 * g
    B = 2.0 * (e - 1.0) / den
    A = exp(2.0 * k * th / (s * s) * log(2.0 * g * exp((g + k) * tau / 2.0) / den))
    return A, B, g

def cir_P(tau, r=R0, k=K, th=TH, s=SIG):
    A, B, _ = cir_AB(tau, k, th, s)
    return A * exp(-B * r)

def vas_P(tau, r=R0):
    B = (1.0 - exp(-K * tau)) / K
    lnA = (TH - SIG_V ** 2 / (2 * K * K)) * (B - tau) - SIG_V ** 2 * B * B / (4 * K)
    return exp(lnA - B * r), B

def riccati_P(tau, n=500):                        # road 2: B' = 1 - kB - s^2 B^2/2, (lnA)' = -k th B
    f = lambda b: 1.0 - K * b - 0.5 * SIG * SIG * b * b
    h, b, lnA = tau / n, 0.0, 0.0
    for _ in range(n):
        k1 = f(b); k2 = f(b + h * k1 / 2); k3 = f(b + h * k2 / 2); k4 = f(b + h * k3)
        b1, b2, b3 = b + h * k1 / 2, b + h * k2 / 2, b + h * k3
        lnA -= K * TH * h * (b + 2 * b1 + 2 * b2 + b3) / 6
        b += h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return exp(lnA - b * R0)

def pde_P(tau, rmax=0.4, m=200, dt=0.001):       # road 3: P_tau = k(th-r)P_r + s^2 r P_rr/2 - rP
    hr = rmax / m
    u = [1.0] * (m + 1)
    for _ in range(round(tau / dt)):
        v = u[:]
        for i in range(m + 1):
            r = i * hr; mu = K * (TH - r); D = 0.5 * SIG * SIG * r
            if i == 0:   ur, urr = (u[1] - u[0]) / hr, 0.0
            elif i == m: ur, urr = (u[m] - u[m - 1]) / hr, 0.0
            elif abs(mu) * hr <= 2 * D:
                ur, urr = (u[i + 1] - u[i - 1]) / (2 * hr), (u[i + 1] - 2 * u[i] + u[i - 1]) / hr ** 2
            else:
                ur = (u[i + 1] - u[i]) / hr if mu > 0 else (u[i] - u[i - 1]) / hr
                urr = (u[i + 1] - 2 * u[i] + u[i - 1]) / hr ** 2
            v[i] = u[i] + dt * (mu * ur + D * urr - r * u[i])
        u = v
    return u[round(R0 / hr)]

class Rng:                                        # splitmix64 + Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def pair(self):
        a, b = 1.0 - self.u(), self.u()
        rad = sqrt(-2.0 * log(a))
        return rad * cos(2 * pi * b), rad * sin(2 * pi * b)

def simulate(s, pairs=5000, steps=250, seed=20260928):   # road 4: paths straight from the SDE
    rng, dt = Rng(seed), T / steps
    out = {"c": [], "v": [], "rT": [], "c0": 0, "v0": 0}
    for _ in range(pairs):
        zs = []
        for _ in range(steps // 2): zs.extend(rng.pair())
        for sign in (1.0, -1.0):                      # antithetic twin: same draws, flipped
            rc = rv = R0; ic = iv = 0.0; hitc = hitv = False
            for z in zs:
                dw = sign * z * sqrt(dt)
                nc = rc + K * (TH - rc) * dt + s * sqrt(max(rc, 0.0)) * dw
                nv = rv + K * (TH - rv) * dt + SIG_V * dw
                ic += 0.5 * (rc + max(nc, 0.0)) * dt; iv += 0.5 * (rv + nv) * dt
                hitc = hitc or nc <= 0.0; hitv = hitv or nv < 0.0
                rc, rv = max(nc, 0.0), nv
            out["c"].append(exp(-ic)); out["v"].append(exp(-iv)); out["rT"].append(rc)
            out["c0"] += hitc; out["v0"] += hitv
    return out

def tot(xs):                                      # plain left-to-right sum, as in the Rust twin
    s = 0.0
    for x in xs: s += x
    return s

def mean_se(xs):                                  # antithetic pairs averaged first, then the spread
    ps = [(xs[i] + xs[i + 1]) / 2 for i in range(0, len(xs), 2)]
    m = tot(ps) / len(ps)
    return m, sqrt(tot((p - m) ** 2 for p in ps) / (len(ps) - 1) / len(ps))

A5, B5, G = cir_AB(T)
den5 = (G + K) * (exp(G * T) - 1) + 2 * G; base5 = 2 * G * exp((G + K) * T / 2) / den5
P1, P2, P3 = cir_P(T), riccati_P(T), pde_P(T)
sim = simulate(SIG)
P4, se4 = mean_se(sim["c"]); PV4, seV = mean_se(sim["v"])
mT = tot(sim["rT"]) / len(sim["rT"]); sdT = sqrt(tot((x - mT) ** 2 for x in sim["rT"]) / (len(sim["rT"]) - 1))
PV, BV = vas_P(T)
e = exp(-K * T)
mean_f = TH + (R0 - TH) * e
sd_c = sqrt(R0 * SIG ** 2 / K * (e - e * e) + TH * SIG ** 2 / (2 * K) * (1 - e) ** 2)
sd_v = sqrt(SIG_V ** 2 / (2 * K) * (1 - e * e))
yld = lambda p, t: -log(p) / t * 100
fail = simulate(0.2, pairs=1000)
rows = [("Feller 2*kappa*theta", 2 * K * TH), ("Feller sigma^2", SIG * SIG), ("gamma", G), ("e^(gamma T)", exp(G * T)),
        ("D = (g+k)(e^(gT)-1) + 2g", den5), ("power 2*kappa*theta/sigma^2", 2 * K * TH / (SIG * SIG)),
        ("A base 2g e^((g+k)T/2) / D", base5), ("e^(-B(5) r0)", exp(-B5 * R0)), ("B(5)", B5), ("A(5)", A5), ("1 closed form P(5)", P1), ("2 Riccati by RK4 P(5)", P2),
        ("3 PDE grid P(5)", P3), ("4 Monte Carlo P(5)", P4), ("  Monte Carlo std error", se4),
        ("CIR 5y yield %", yld(P1, T)), ("Vasicek B(5)", BV), ("Vasicek P(5) formula", PV),
        ("Vasicek P(5) Monte Carlo", PV4), ("Vasicek 5y yield %", yld(PV, T)), ("CIR minus Vasicek P(5)", P1 - PV), ("e^(-kappa T)", e),
        ("CIR long yield %", 200 * K * TH / (G + K)), ("Vasicek long yield %", 100 * (TH - SIG_V ** 2 / (2 * K * K))),
        ("mean r(5) formula %", 100 * mean_f), ("mean r(5) CIR sim %", 100 * mT),
        ("sd r(5) CIR formula %", 100 * sd_c), ("sd r(5) CIR sim %", 100 * sdT), ("sd r(5) Vasicek %", 100 * sd_v),
        ("paths below zero, CIR", sim["c0"]), ("paths below zero, Vasicek", sim["v0"]),
        ("wrong: Vasicek sigma 0.01 in CIR", cir_P(T, s=0.01)),
        ("wrong: A without its power", exp(log(base5) - B5 * R0)),
        ("wrong: gamma without the 2", cir_AB(T, two=1.0)[0] * exp(-cir_AB(T, two=1.0)[1] * R0)),
        ("wrong: flat e^(-r0 T)", exp(-R0 * T)),
        ("try: sigma 0.2 P(5)", cir_P(T, s=0.2)), ("try: sigma 0.2 paths touching 0 of 2000", fail["c0"]),
        ("try: r0 0.01 P(5)", cir_P(T, r=0.01)), ("try: kappa 1.0 P(5)", cir_P(T, k=1.0))]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}" if isinstance(v, float) else f"{name:<40} {v:>12d}")
mats = (1, 2, 3, 5, 7, 10, 20, 30)
print("chart maturity    " + " ".join(f"{t:5d}" for t in mats))
print("chart CIR %       " + " ".join(f"{yld(cir_P(t), t):5.2f}" for t in mats))
print("chart Vasicek %   " + " ".join(f"{yld(vas_P(t)[0], t):5.2f}" for t in mats))
print("chart rate %      " + " ".join(f"{i:5d}" for i in range(11)))
print("chart CIR noise % " + " ".join(f"{100 * SIG * sqrt(i / 100):5.2f}" for i in range(11)))
assert abs(P2 - P1) < 1e-10, "RK4 on the Riccati pair must land on the closed form"
assert abs(P3 - P1) < 2e-5, "PDE grid, which never guesses the affine shape, must agree"
assert abs(P4 - P1) < 4 * se4, "Monte Carlo from the SDE within four standard errors"
assert abs(PV4 - PV) < 4 * seV, "Vasicek on the same draws within four standard errors"
assert abs(mT - mean_f) < 4 * mean_se(sim["rT"])[1], "simulated mean rate vs the transition law"
assert sim["c0"] == 0, "Feller holds: no CIR path touches zero"
assert fail["c0"] > 0, "Feller broken (sigma 0.2): some paths do touch zero"
print("ALL CHECKS PASS")
