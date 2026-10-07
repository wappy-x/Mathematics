# Barriers on a smile -- the check behind the card.  Standard library only.
# House EURUSD reverse knock-out: EUR call, strike 1.10, knocked out at 1.20.
# Roads: reflection formula, finite-difference PDE, Monte Carlo on the same draws.
from math import exp, log, sqrt, pi, cos
RD, RF, K, H, ATM, PIP = 0.05, 0.03, 1.10, 1.20, 0.10, 1e-4
SMILE = (0.1075, 0.10, 0.0975)                   # 25-delta put, ATM, 25-delta call vols

def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def N(x):                                         # bell-curve area: series for the integral
    if abs(x) > 9: return 1.0 if x > 0 else 0.0
    s = t = x; n = 1
    while abs(t) > 1e-17 * abs(s): t *= x * x / (2 * n + 1); s += t; n += 1
    return 0.5 + phi(x) * s
def Ninv(p, lo=-9.0, hi=9.0):                     # bisection root finder
    for _ in range(80):
        m = 0.5 * (lo + hi); lo, hi = (m, hi) if N(m) < p else (lo, m)
    return 0.5 * (lo + hi)
def gk(S, k, T, v, w=1):                          # Garman-Kohlhagen call (w=1) or put (w=-1)
    d1 = (log(S / k) + (RD - RF + 0.5 * v * v) * T) / (v * sqrt(T)); d2 = d1 - v * sqrt(T)
    return w * (S * exp(-RF * T) * N(w * d1) - k * exp(-RD * T) * N(w * d2))
def dig(S, k, T, v): return exp(-RD * T) * N((log(S / k) + (RD - RF - 0.5 * v * v) * T) / (v * sqrt(T)))
def uoc(S, T, v, h=H):                            # road 1: reflection formula
    g = lambda s: gk(s, K, T, v) - gk(s, h, T, v) - (h - K) * dig(s, h, T, v)
    return g(S) - (h / S) ** (2 * (RD - RF) / (v * v) - 1) * g(h * h / S)
def surv(S, T, v, h=H):                           # chance the wall is never touched
    mu, a = RD - RF - 0.5 * v * v, log(h / S)
    return N((a - mu * T) / (v * sqrt(T))) - exp(2 * mu * a / (v * v)) * N((-a - mu * T) / (v * sqrt(T)))
def pillars(S, T, vols):                          # strikes of 25-put, ATM, 25-call (spot delta)
    vp, va, vc = vols; d = Ninv(0.25 * exp(RF * T)); m = (RD - RF) * T
    return [(S * exp(d * vp * sqrt(T) + m + 0.5 * vp * vp * T), vp, -1),
            (S * exp(m + 0.5 * va * va * T), va, 1),
            (S * exp(-d * vc * sqrt(T) + m + 0.5 * vc * vc * T), vc, 1)]
def vvv(f, S, v, e=1e-4):                         # vega, vanna, volga by central bumps
    return ((f(S, v + e) - f(S, v - e)) / (2 * e), (f(S + e, v + e) - f(S + e, v - e) - f(S - e, v + e)
            + f(S - e, v - e)) / (4 * e * e), (f(S, v + e) - 2 * f(S, v) + f(S, v - e)) / (e * e))
def solve3(A, b):                                 # Cramer's rule
    det = lambda m: (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2]
                     - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
    return [det([[b[i] if j == c else A[i][j] for j in range(3)] for i in range(3)]) / det(A) for c in range(3)]
def overlay(f, S, T, pil):                        # vanna-volga: hedge weights x, cost of the hedge
    cols = [vvv(lambda s, v, k=k, w=w: gk(s, k, T, v, w), S, ATM) for k, _, w in pil]
    x = solve3([[cols[j][i] for j in range(3)] for i in range(3)], vvv(f, S, ATM))
    return x, sum(x[j] * (gk(S, k, T, v, w) - gk(S, k, T, ATM, w)) for j, (k, v, w) in enumerate(pil))

def pde(S, T, lv, pay, h=None, nx=300, nt=150):   # road 2: implicit-then-Crank-Nicolson, log spot
    L = 0.8 * sqrt(T) + 0.05; x0 = -L; x1 = log(h / S) if h else L; dx = (x1 - x0) / nx; dt = T / nt
    xs = [x0 + i * dx for i in range(nx + 1)]; V = [pay(S * exp(x)) for x in xs]
    if h: V[nx] = 0.0
    s2 = [lv(x) ** 2 for x in xs]
    lo_ = [0.5 * q / dx / dx - 0.5 * (RD - RF - 0.5 * q) / dx for q in s2]
    up_ = [0.5 * q / dx / dx + 0.5 * (RD - RF - 0.5 * q) / dx for q in s2]
    di_ = [-q / dx / dx - RD for q in s2]
    for n in range(nt):
        th = 1.0 if n < 2 else 0.5; e = (1 - th) * dt; bl = V[0] * exp(-RD * dt); bh = 0.0 if h else V[nx] * exp(-RD * dt)
        cp = [0.0] * (nx + 1); dp = [0.0] * (nx + 1); cp[0], dp[0] = 0.0, bl
        for i in range(1, nx):
            r = V[i] + e * (lo_[i] * V[i - 1] + di_[i] * V[i] + up_[i] * V[i + 1])
            a, b, c = -th * dt * lo_[i], 1 - th * dt * di_[i], -th * dt * up_[i]
            m = b - a * cp[i - 1]; cp[i] = c / m; dp[i] = (r - a * dp[i - 1]) / m
        V[nx] = bh
        for i in range(nx - 1, 0, -1): V[i] = dp[i] - cp[i] * V[i + 1]
        V[0] = bl
    i = int(-x0 / dx); w = -xs[i] / dx
    return V[i] * (1 - w) + V[i + 1] * w
def lvf(p): return lambda x: min(max(p[0] + p[1] * x + p[2] * x * x, 0.02), 0.6)
def calib(S, T, pil):                             # fit a + b x + c x^2 so the PDE hits all three quotes
    tgt = [(gk(S, k, T, v, w), vvv(lambda s, u: gk(s, k, T, u, w), S, v)[0]) for k, v, w in pil]
    res = lambda p: [(pde(S, T, lvf(p), lambda s, k=k, w=w: max(w * (s - k), 0.0)) - tgt[j][0]) / tgt[j][1]
                     for j, (k, v, w) in enumerate(pil)]
    p = [ATM, 0.0, 0.0]; r = res(p); J = [[0.0] * 3 for _ in range(3)]
    for j in range(3):
        q = p[:]; q[j] += 1e-3; rq = res(q)
        for i in range(3): J[i][j] = (rq[i] - r[i]) / 1e-3
    for _ in range(5):                            # chord Newton: one Jacobian, reused
        d = solve3(J, [-u for u in r]); p = [p[i] + d[i] for i in range(3)]; r = res(p)
    return p, max(abs(u) for u in r)
M64 = (1 << 64) - 1
def rng(seed):                                    # splitmix64 uniforms in (0, 1]
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & M64; z = seed
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        yield (((z ^ (z >> 31)) >> 11) + 1) / 9007199254740992.0
def mc(S, T, lv, pay, n, steps, h=H):             # road 3: flat and smile paths on the same draws
    g = rng(7); dt = T / steps; b = log(h / S); s1 = s2 = 0.0
    for _ in range(n):
        xa = xb = 0.0; wa = wb = 1.0
        for _ in range(steps):
            z = sqrt(-2 * log(next(g))) * cos(2 * pi * next(g)); out = []
            for x, v in ((xa, ATM), (xb, lv(xb))):         # Euler step, then Brownian-bridge survival
                y = x + (RD - RF - 0.5 * v * v) * dt + v * sqrt(dt) * z
                out.append((y, 0.0 if y >= b else 1 - exp(-2 * (b - x) * (b - y) / (v * v * dt))))
            (xa, ka), (xb, kb) = out; wa *= ka; wb *= kb
        d = wb * pay(S * exp(xb)) - wa * pay(S * exp(xa)); s1 += d; s2 += d * d
    m = s1 / n; return exp(-RD * T) * m, exp(-RD * T) * sqrt((s2 / n - m * m) / n)

call = lambda s: max(s - K, 0.0)
def case(S, T, tag, n, steps):
    pil = pillars(S, T, SMILE); flat = uoc(S, T, ATM); ps = surv(S, T, ATM); f = lambda s, v: uoc(s, T, v)
    x, ov = overlay(f, S, T, pil); p, fit = calib(S, T, pil); lv = lvf(p)
    pf = pde(S, T, lambda y: ATM, call, H); d = pde(S, T, lv, call, H) - pf; dm, se = mc(S, T, lv, call, n, steps)
    rows = [("pillar strikes 25P ATM 25C", [k for k, _, _ in pil]), ("barrier vega vanna volga", vvv(f, S, ATM)),
            ("hedge weights x", x), ("local vol a b c", p), ("flat: formula, PDE, pips", [flat / PIP, pf / PIP]),
            ("pillar cost mkt - flat, pips", [(gk(S, k, T, v, w) - gk(S, k, T, ATM, w)) / PIP for k, v, w in pil]),
            ("survival chance, touch chance", [ps, 1 - ps]), ("overlay: full, x survival, pips", [ov / PIP, ps * ov / PIP]),
            ("VV: unweighted, x survival, pips", [(flat + ov) / PIP, (flat + ps * ov) / PIP]), ("local vol: flat + PDE gap, pips", [(flat + d) / PIP]),
            ("smile gap: PDE, MC, s.e., pips", [d / PIP, dm / PIP, se / PIP]), ("VV minus local vol: full, x surv", [(ov - d) / PIP, (ps * ov - d) / PIP])]
    print(tag)
    for lab, vals in rows: print(f"  {lab:<32}" + "".join(f"{v:>12.6f}" for v in vals))
    return flat, ps, ov, d, pf, pil, lv, fit, dm, se

flat, ps, ov, d, pf, pil, lv, fit, dm, se = case(1.10, 1.0, "house reverse knock-out, 1 year, spot 1.10", 20000, 200)
W = 7 / 365
wf, wps, wov, wd, wpf, *_, wdm, wse = case(1.19, W, "same contract, 1 week left, spot 1.19", 20000, 200)
print("1 week left: spot, flat, VV x survival - flat, local vol - flat (pips)")
for s in [1.15 + 0.005 * i for i in range(10)]:
    ps_ = pillars(s, W, SMILE); _, o = overlay(lambda q, v: uoc(q, W, v), s, W, ps_); p_s, _ = calib(s, W, ps_)
    g = pde(s, W, lvf(p_s), call, H) - pde(s, W, lambda y: ATM, call, H)
    print(f"  {s:.3f} {uoc(s, W, ATM) / PIP:9.2f} {surv(s, W, ATM) * o / PIP:9.2f} {g / PIP:9.2f}")
print("payoff at expiry if 1.20 never traded: " + " ".join(f"{s:.3f}:{call(s) if s < H else 0.0:.3f}" for s in (1.05, 1.10, 1.15, 1.19, 1.20, 1.25)))
nt_pde = pde(1.10, 1.0, lambda y: ATM, lambda s: 1.0, H) * exp(RD)          # survival chance by PDE
k3, v3, _ = pil[2]; _, o3 = overlay(lambda s, v: gk(s, k3, 1.0, v), 1.10, 1.0, pil)
kp, vp, _ = pil[0]; pm, pse = mc(1.10, 1.0, lv, lambda s: max(kp - s, 0.0), 20000, 200, 1e9)
extra = [("wrong: weight by touch chance", (flat + (1 - ps) * ov) / PIP), ("wrong: flat at 25C vol 9.75%", uoc(1.10, 1.0, 0.0975) / PIP),
         ("wrong: flat at 25P vol 10.75%", uoc(1.10, 1.0, 0.1075) / PIP)]
for lab, vv_ in (("try: risk reversal mirrored", (0.0975, 0.10, 0.1075)), ("try: butterfly zero", (0.105, 0.10, 0.095))):
    _, o = overlay(lambda s, v: uoc(s, 1.0, v), 1.10, 1.0, pillars(1.10, 1.0, vv_)); extra.append((lab + ", VVxS", (flat + ps * o) / PIP))
_, o = overlay(lambda s, v: uoc(s, 1.0, v, 1.25), 1.10, 1.0, pil); f25, s25 = uoc(1.10, 1.0, ATM, 1.25), surv(1.10, 1.0, ATM, 1.25)
extra += [("try: wall 1.25, flat", f25 / PIP), ("try: wall 1.25, VV x survival", (f25 + s25 * o) / PIP),
          ("try: wall 1.25, local vol PDE", (f25 + pde(1.10, 1.0, lv, call, 1.25) - pde(1.10, 1.0, lambda y: ATM, call, 1.25)) / PIP)]
extra += [("check: survival by PDE", nt_pde), ("check: 25C via overlay", gk(1.10, k3, 1.0, ATM) + o3), ("  market 25C at 9.75%", gk(1.10, k3, 1.0, v3)),
          ("check: 25P smile-flat MC, s.e., pips", pm / PIP), ("  s.e.", pse / PIP), ("  market - flat, pips", (gk(1.10, kp, 1.0, vp, -1) - gk(1.10, kp, 1.0, ATM, -1)) / PIP)]
for lab, v in extra: print(f"{lab:<38}{v:>12.6f}")
assert abs(pf - flat) < 0.5 * PIP and abs(wpf - wf) < 0.5 * PIP, "PDE road vs reflection formula"
assert abs(dm - d) < 3 * se and abs(wdm - wd) < 3 * wse, "Monte Carlo smile gap vs PDE smile gap"
assert abs(nt_pde - ps) < 1e-3, "survival chance: closed form vs PDE"
assert abs(gk(1.10, k3, 1.0, ATM) + o3 - gk(1.10, k3, 1.0, v3)) < 1e-9, "overlay reprices its own pillar"
assert abs(pm - (gk(1.10, kp, 1.0, vp, -1) - gk(1.10, kp, 1.0, ATM, -1))) < 3 * pse, "local vol MC reprices the 25P quote"
assert fit < 1e-6, "local vol reprices all three quotes on the grid"
assert wd < 0 < wps * wov, "a week out the recipe and the model disagree in sign"
print("ALL CHECKS PASS")
