# Mean reversion -- the check behind the card.  Only math is imported.
# A short rate r_t (a decimal, per year) is pulled toward THETA = 4 percent at speed
# KAPPA = 0.5 a year, starting at R0 = 6 percent.  OU: dr = KAPPA (THETA - r) dt + SIG dW.
# CIR: the noise is SIG_C sqrt(r) dW instead.  Roads: the closed forms; the moment
# equations from Ito's lemma, solved by RK4; the Euler recursion's own exact moments at
# shrinking steps; 10000 simulated paths from a SplitMix64 generator and Box-Muller.
import math

KAPPA, THETA, R0, SIG = 0.5, 0.04, 0.06, 0.02          # per year, rate, rate, per sqrt(year)
SIG_OK, SIG_BAD = 0.10, 0.30                           # CIR noise: Feller holds, Feller fails
PATHS, H, STEPS, SEED, MASK = 10000, 0.02, 500, 20260930, (1 << 64) - 1     # step 0.02 years, 10 years

def ou_mean(t): return THETA + (R0 - THETA) * math.exp(-KAPPA * t)
def ou_var(t): return SIG * SIG / (2 * KAPPA) * (1 - math.exp(-2 * KAPPA * t))
def cir_var(t, s):                                     # the CIR variance, from the moment equations
    a, b = math.exp(-KAPPA * t), s * s / KAPPA
    return R0 * b * (a - a * a) + THETA * b / 2 * (1 - a) * (1 - a)

def moments_rk4(t, s, cir, n=2000):     # dm/dt = K(TH - m);  dE[r^2]/dt = 2K TH m - 2K E[r^2] + E[noise^2]
    f = lambda m, m2: (KAPPA * (THETA - m), 2 * KAPPA * THETA * m - 2 * KAPPA * m2 + (s * s * m if cir else s * s))
    m, m2, h = R0, R0 * R0, t / n
    for _ in range(n):
        k1 = f(m, m2); k2 = f(m + h / 2 * k1[0], m2 + h / 2 * k1[1])
        k3 = f(m + h / 2 * k2[0], m2 + h / 2 * k2[1]); k4 = f(m + h * k3[0], m2 + h * k3[1])
        m += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        m2 += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return m, m2 - m * m

def ncdf(x, n=2000):                    # bell-curve area left of x: one half plus Simpson from 0 to x
    h, s = x / n, 0.0
    for i in range(n + 1):
        z = i * h
        s += (1 if i in (0, n) else (4 if i % 2 else 2)) * math.exp(-0.5 * z * z)
    return 0.5 + s * h / 3 / math.sqrt(2 * math.pi)

def euler_moments(h, t):                # exact mean and variance of the Euler recursion itself
    m, v, a = R0, 0.0, 1 - KAPPA * h
    for _ in range(round(t / h)):
        m, v = THETA + a * (m - THETA), a * a * v + SIG * SIG * h
    return m, v

class SplitMix64:                       # the wing's generator, written out
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                   # Box-Muller, cosine half only
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def stats(xs):                          # mean, its SE, variance, its SE
    n = len(xs); m = sum(xs) / n
    c2 = sum((x - m) * (x - m) for x in xs) / n
    c4 = sum(((x - m) * (x - m)) * ((x - m) * (x - m)) for x in xs) / n
    return m, math.sqrt(c2 / (n - 1)), c2 * n / (n - 1), math.sqrt((c4 - c2 * c2) / n)

half, v_inf = math.log(2) / KAPPA, SIG * SIG / (2 * KAPPA); p_neg = ncdf(-THETA / math.sqrt(v_inf))
print(f"OU: kappa {KAPPA}, theta {THETA}, r0 {R0}, sigma {SIG}; CIR sigma {SIG_OK} and {SIG_BAD}")
print(f"half-life ln2/kappa {half:.6f} years; time constant 1/kappa {1 / KAPPA:.6f} years")
print(f"stationary: var {v_inf:.6f}, sd {100 * math.sqrt(v_inf):.4f} percent, P(r < 0) {p_neg:.6f}, 1 in {1 / p_neg:.1f}")
a1, b1 = math.exp(-KAPPA), SIG_OK * SIG_OK / KAPPA
print(f"hand: ln 2 {math.log(2):.6f}, e^-0.5 {a1:.6f}, 1 - e^-0.5 {1 - a1:.6f}, e^-1 {a1 * a1:.6f}; CIR t = 1: a - a^2 {a1 - a1 * a1:.6f}, (1 - a)^2 {(1 - a1) * (1 - a1):.6f},"
      f" pieces {R0 * b1 * (a1 - a1 * a1):.7f} + {THETA * b1 / 2 * (1 - a1) * (1 - a1):.7f}")
for t in (1, 2, 5, 10):
    rm, rv = moments_rk4(t, SIG, False)
    print(f"OU t = {t:2d}: formula mean {100 * ou_mean(t):.4f} sd {100 * math.sqrt(ou_var(t)):.4f} percent;"
          f" RK4 mean {100 * rm:.4f} sd {100 * math.sqrt(rv):.4f}")
    assert abs(rm - ou_mean(t)) < 1e-12 and abs(rv - ou_var(t)) < 1e-12
lo, hi = 0.0, 5.0                       # half-life by bisection on the RK4 mean: when is the gap 1 point?
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if moments_rk4(mid, SIG, False, 400)[0] > (R0 + THETA) / 2 else (lo, mid)
print(f"half-life by bisection on the RK4 mean: {lo:.6f} years; rate then {100 * ou_mean(lo):.4f} percent")
assert abs(lo - half) < 1e-9
errs = []
for h in (0.5, 0.1, 0.01, 0.001):
    em, ev = euler_moments(h, 1.0)
    errs.append(abs(ev - ou_var(1)))
    print(f"Euler recursion h = {h:5}: mean {100 * em:.4f} percent, var {ev:.8f}; var off by"
          f" {100 * abs(ev / ou_var(1) - 1):.4f} percent")
assert errs[3] < errs[2] / 5 < errs[1] / 25 and errs[3] < 1e-3 * ou_var(1)
for h in (0.02, 1.0, 2.5):
    a = 1 - KAPPA * h
    print(f"Euler step h = {h:.2f}: factor 1 - kappa h = {a:.2f}, long-run var {SIG * SIG * h / (1 - a * a):.6f}"
          f" against {v_inf:.6f}")
print(f"Euler step h = 4.50: factor {1 - KAPPA * 4.5:.2f}, var after 10 steps {euler_moments(4.5, 45)[1]:.6f},"
      f" after 20 steps {euler_moments(4.5, 90)[1]:.6f}")

g = SplitMix64(SEED)
ou1, ou10, ok1, ok10, ou_dip, ok_hit, bad_hit, fig = [], [], [], [], 0, 0, 0, []
for p in range(PATHS):
    x = y = w = R0
    dipped = hit_y = hit_w = False
    row = [(x, y, w)]
    for k in range(1, STEPS + 1):
        z = g.normal() * math.sqrt(H)
        x += KAPPA * (THETA - x) * H + SIG * z
        y += KAPPA * (THETA - max(y, 0.0)) * H + SIG_OK * math.sqrt(max(y, 0.0)) * z
        w += KAPPA * (THETA - max(w, 0.0)) * H + SIG_BAD * math.sqrt(max(w, 0.0)) * z
        dipped, hit_y, hit_w = dipped or x < 0, hit_y or y <= 0, hit_w or w <= 0
        if k == 50: ou1.append(x); ok1.append(y)
        if p == 0 and k % 25 == 0: row.append((x, y, w))
    ou10.append(x); ok10.append(y)
    ou_dip += dipped; ok_hit += hit_y; bad_hit += hit_w
    if p == 0: fig = row
for lab, xs, mt, vt in (("OU t = 1", ou1, ou_mean(1), ou_var(1)), ("OU t = 10", ou10, ou_mean(10), ou_var(10)),
                        ("CIR t = 1", ok1, ou_mean(1), cir_var(1, SIG_OK)), ("CIR t = 10", ok10, ou_mean(10), cir_var(10, SIG_OK))):
    m, sm, v, sv = stats(xs)
    print(f"simulated {lab:10s}: mean {100 * m:.4f} +- {100 * sm:.4f} percent (formula {100 * mt:.4f}),"
          f" var {v:.7f} +- {sv:.7f} (formula {vt:.7f})")
    assert abs(m - mt) < 4 * sm and abs(v - vt) < 4 * sv
neg = sum(1 for x in ou10 if x < 0) / PATHS
print(f"OU at t = 10: P(r < 0) simulated {neg:.4f} +- {math.sqrt(neg * (1 - neg) / PATHS):.4f},"
      f" formula {ncdf(-ou_mean(10) / math.sqrt(ou_var(10))):.4f}; CIR below 0: {sum(1 for y in ok10 if y < 0)}")
assert abs(neg - ncdf(-ou_mean(10) / math.sqrt(ou_var(10)))) < 4 * math.sqrt(neg * (1 - neg) / PATHS)
for t in (1, 10):
    rm, rv = moments_rk4(t, SIG_OK, True)
    print(f"CIR t = {t:2d}: formula var {cir_var(t, SIG_OK):.7f}, RK4 mean {100 * rm:.4f} percent, RK4 var {rv:.7f}")
    assert abs(rm - ou_mean(t)) < 1e-12 and abs(rv - cir_var(t, SIG_OK)) < 1e-12
for s, hits in ((SIG_OK, ok_hit), (SIG_BAD, bad_hit)):
    fr = hits / PATHS
    print(f"CIR sigma {s}: 2 kappa theta {2 * KAPPA * THETA:.2f} vs sigma^2 {s * s:.2f}, shape {2 * KAPPA * THETA / (s * s):.4f};"
          f" paths touching 0 in 10 years {fr:.4f} +- {math.sqrt(fr * (1 - fr) / PATHS):.4f}")
assert ok_hit <= PATHS // 1000 and bad_hit > PATHS // 2      # Feller holds: grid artefacts only
print(f"OU paths dipping below 0 within 10 years: {ou_dip / PATHS:.4f} +- {math.sqrt(ou_dip / PATHS * (1 - ou_dip / PATHS) / PATHS):.4f}")
print(f"mistake: Brownian variance sigma^2 t at t = 10: {SIG * SIG * 10:.6f}, sd {100 * SIG * math.sqrt(10):.4f} percent")
print(f"mistake: stationary var without the 2, sigma^2/kappa: {SIG * SIG / KAPPA:.6f}, sd {100 * SIG / math.sqrt(KAPPA):.4f} percent")
print(f"mistake: 1/kappa as the half-life: mean at t = 2 is {100 * ou_mean(2):.4f} percent, not 5.0000")
print(f"try: kappa 1.0: half-life {math.log(2) / 1.0:.6f}, stationary sd {100 * SIG / math.sqrt(2.0):.4f};"
      f" sigma 0.04: stationary sd {100 * 0.04 / math.sqrt(2 * KAPPA):.4f}, P(r < 0) {ncdf(-1.0):.6f}")
print("figure, years: " + ", ".join(f"{k / 2:.1f}" for k in range(21)))
print("figure, OU sample path, percent: " + ", ".join(f"{100 * r[0]:.2f}" for r in fig))
print("figure, OU mean, percent: " + ", ".join(f"{100 * ou_mean(k / 2):.2f}" for k in range(21)))
print("figure, OU mean - 2 sd, percent: " + ", ".join(f"{100 * (ou_mean(k / 2) - 2 * math.sqrt(ou_var(k / 2))):.2f}" for k in range(21)))
print(f"figure, CIR sigma {SIG_OK} path, percent: " + ", ".join(f"{100 * r[1]:.2f}" for r in fig))
print(f"figure, CIR sigma {SIG_BAD} path, percent: " + ", ".join(f"{100 * r[2]:.2f}" for r in fig))
print("ALL CHECKS PASS")
