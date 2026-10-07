# The generator -- the check behind the card.  Only math is imported.
# OU short rate: dr = KAPPA (THETA - r) dt + SIG dW, from R0 = 6 percent, time in years.
# GBM share: dS = MU S dt + VOL S dW from $100.  The generator is L f = drift f' + 1/2 noise^2 f''.
# Roads: the formula; the definition (E f(X_h) - f(x)) / h with E taken under the exact law
# (Simpson against the bell curve) at shrinking h; Dynkin's formula on 4000 simulated paths
# of 1000 Euler steps (SplitMix64, Box-Muller); and, for the band 4 to 8 percent, the exit
# chance and mean exit time by integrals, by finite differences, and by simulation.
import math

KAPPA, THETA, R0, SIG = 0.5, 0.04, 0.06, 0.02          # per year, rate, rate, per sqrt(year)
S0, MU, VOL = 100.0, 0.05, 0.20                        # dollars, per year, per sqrt(year)
LO, HI, SEED, MASK = 0.04, 0.08, 20260930, (1 << 64) - 1

def L_ou(f1, f2, r): return KAPPA * (THETA - r) * f1(r) + 0.5 * SIG * SIG * f2(r)
def L_gbm(f1, f2, s): return MU * s * f1(s) + 0.5 * VOL * VOL * s * s * f2(s)
def ou_law(r, t): return THETA + (r - THETA) * math.exp(-KAPPA * t), math.sqrt(SIG * SIG / (2 * KAPPA) * (1 - math.exp(-2 * KAPPA * t)))
def expect_normal(g, m, sd, n=4000):                   # E g(m + sd Z) by Simpson on [-10, 10]
    h, tot = 20.0 / n, 0.0
    for i in range(n + 1):
        z = -10.0 + i * h
        tot += (1 if i in (0, n) else (4 if i % 2 else 2)) * g(m + sd * z) * math.exp(-0.5 * z * z)
    return tot * h / 3 / math.sqrt(2 * math.pi)
def quotient_ou(f, h):                                 # the definition, at step h
    m, sd = ou_law(R0, h); return (expect_normal(f, m, sd) - f(R0)) / h
def quotient_gbm(f, h):                                # log S_h is normal: exact GBM law
    m, sd = math.log(S0) + (MU - 0.5 * VOL * VOL) * h, VOL * math.sqrt(h)
    return (expect_normal(lambda y: f(math.exp(y)), m, sd) - f(S0)) / h

class SplitMix64:
    def __init__(self, seed): self.s, self.spare = seed & MASK, None
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def normal(self):                                  # Box-Muller, both halves used
        if self.spare is not None:
            z, self.spare = self.spare, None; return z
        rad, ang = math.sqrt(-2.0 * math.log(self.uniform())), 2.0 * math.pi * self.uniform()
        self.spare = rad * math.sin(ang); return rad * math.cos(ang)
def mean_se(xs):
    n = len(xs); m = sum(xs) / n
    return m, math.sqrt(sum((x - m) * (x - m) for x in xs) / (n - 1) / n)

def band_integrals(x, n=20000):                        # scale function and L g = -1, by trapezoids
    c, d = KAPPA / (SIG * SIG), (HI - LO) / n
    sp = [math.exp(c * (LO + i * d - THETA) ** 2) for i in range(n + 1)]
    S, I, J = [0.0], [0.0], [0.0]
    for i in range(n):
        S.append(S[-1] + d * (sp[i] + sp[i + 1]) / 2)
        I.append(I[-1] + d * (2 / (SIG * SIG)) * (1 / sp[i] + 1 / sp[i + 1]) / 2)
        J.append(J[-1] + d * (sp[i] * I[i] + sp[i + 1] * I[i + 1]) / 2)
    k = round((x - LO) / d)
    return S[k] / S[n], J[n] * S[k] / S[n] - J[k]
def band_fd(x, rhs, top, n=2000):                      # 1/2 SIG^2 u'' + drift u' = rhs, Thomas algorithm
    d = (HI - LO) / n; a = 0.5 * SIG * SIG / (d * d)
    cp, dp = [0.0] * n, [0.0] * n
    for i in range(1, n):
        b = KAPPA * (THETA - (LO + i * d)) / (2 * d)
        lo, di, up, r = a - b, -2 * a, (a + b if i < n - 1 else 0.0), rhs - ((a + b) * top if i == n - 1 else 0.0)
        den = di - lo * cp[i - 1]; cp[i], dp[i] = up / den, (r - lo * dp[i - 1]) / den
    u = [0.0] * (n + 1); u[n] = top
    for i in range(n - 1, 0, -1): u[i] = dp[i] - cp[i] * u[i + 1]
    return u[round((x - LO) / d)]
def band_sim(h, paths, rng):
    ups, times = [], []
    for _ in range(paths):
        r, k = R0, 0
        while LO < r < HI:
            r += KAPPA * (THETA - r) * h + SIG * math.sqrt(h) * rng.normal(); k += 1
        ups.append(1.0 if r >= HI else 0.0); times.append(k * h)
    return mean_se(ups), mean_se(times)
sq, one, zero = (lambda r: 2 * r), (lambda r: 1.0), (lambda r: 0.0)
gap2 = lambda r: (r - THETA) ** 2
rows = [("OU  L[r] at 6%", L_ou(one, zero, R0)), ("OU  L[r^2] at 6%", L_ou(sq, lambda r: 2.0, R0)),
        ("OU  L[(r-theta)^2] at 6%", L_ou(lambda r: 2 * (r - THETA), lambda r: 2.0, R0)),
        ("wrong: no 1/2 sigma^2 f'', L[r^2]", L_ou(sq, zero, R0)),
        ("wrong: no 1/2 sigma^2 f'', L[gap^2]", L_ou(lambda r: 2 * (r - THETA), zero, R0)),
        ("wrong: sigma^2 f'' without the 1/2", L_ou(sq, lambda r: 4.0, R0))]
for name, v in rows: print(f"{name:<40}{v:>14.8f}")
quo = {}; print("definition (E f(r_h) - f(0.06)) / h, exact OU law:")
for h in (0.1, 0.01, 0.001, 0.0001):
    quo[h] = (quotient_ou(lambda r: r, h), quotient_ou(lambda r: r * r, h), quotient_ou(gap2, h))
    print(f"  h = {h:<8} r {quo[h][0]:>12.8f}  r^2 {quo[h][1]:>12.8f}  gap^2 {round(quo[h][2], 8) + 0.0:>12.8f}")
g_rows = [("GBM L[s] at $100", L_gbm(one, zero, S0), quotient_gbm(lambda s: s, 1e-4)),
          ("GBM L[log s] at $100", L_gbm(lambda s: 1 / s, lambda s: -1 / (s * s), S0), quotient_gbm(math.log, 1e-4)),
          ("GBM L[s^2] at $100", L_gbm(sq, lambda s: 2.0, S0), quotient_gbm(lambda s: s * s, 1e-4))]
print("GBM: formula, then definition at h = 0.0001:")
for name, a, b in g_rows: print(f"  {name:<22}{a:>14.6f}{b:>14.6f}")
# ---- the house example: 4000 paths, 1000 Euler steps over 2 years; f = r^2 ----
rng, PATHS, STEPS, T = SplitMix64(SEED), 4000, 1000, 2.0; h = T / STEPS
marks = list(range(0, STEPS + 1, 125))
sums = {k: [] for k in marks}; mart, g2 = [], []
for _ in range(PATHS):
    r, comp = R0, 0.0
    sums[0].append(r * r)
    for k in range(1, STEPS + 1):
        comp += L_ou(sq, lambda x: 2.0, r) * h
        r += KAPPA * (THETA - r) * h + SIG * math.sqrt(h) * rng.normal()
        if k in sums: sums[k].append(r * r)
    mart.append(r * r - R0 * R0 - comp); g2.append(gap2(r))
print("house example, 4000 paths x 1000 steps of 0.002 years, E[r_t^2] in percent^2:")
chart = []
for k in marks:
    t = k * h; m, sd = ou_law(R0, t)
    sim, se = mean_se(sums[k]); chart.append((t, (m * m + sd * sd) * 1e4, (R0 * R0 + rows[1][1] * t) * 1e4, sim * 1e4, se * 1e4))
    print(f"  t = {t:4.2f}  exact {chart[-1][1]:7.4f}  tangent {chart[-1][2]:7.4f}  sim {chart[-1][3]:7.4f} +- {chart[-1][4]:.4f}")
print("figure, exact  " + ", ".join(f"{c[1]:.2f}" for c in chart))
print("figure, tangent " + ", ".join(f"{c[2]:.2f}" for c in chart))
print("figure, sim    " + ", ".join(f"{c[3]:.2f}" for c in chart))
mm, mse = mean_se(mart); gm, gse = mean_se(g2)
print(f"{'Dynkin: mean of r_T^2 - r_0^2 - sum L f h':<40}{mm:>14.8f} +- {mse:.8f}")
print(f"{'E[(r_2 - theta)^2], simulated':<40}{gm:>14.8f} +- {gse:.8f}")
p_int, t_int = band_integrals(R0)
p_fd, t_fd = band_fd(R0, 0.0, 1.0), band_fd(R0, -1.0, 0.0)
print("band 4% to 8% from 6%: chance 8% first, mean exit time (years)")
print(f"  integrals          {p_int:.6f}   {t_int:.6f}")
sims = {}; print(f"  finite differences {p_fd:.6f}   {t_fd:.6f}")
for hh in (0.004, 0.001, 0.00025):
    sims[hh] = band_sim(hh, 4000, rng); (p, pse), (tm, tse) = sims[hh]
    print(f"  sim h = {hh:<7}    {p:.6f} +- {pse:.6f}   {tm:.6f} +- {tse:.6f}   off by {tm - t_int:+.4f}")
def ncdf(x, n=2000):                                   # bell-curve area left of x, by Simpson
    hx = x / n
    return 0.5 + sum((1 if i in (0, n) else (4 if i % 2 else 2)) * math.exp(-0.5 * (i * hx) ** 2) for i in range(n + 1)) * hx / 3 / math.sqrt(2 * math.pi)
print("unbounded stopping: W from 0, tau = first hit of 1; E[W_tau] = 1, not 0")
for TT in (1, 100, 10000): print(f"  P(tau <= {TT:>5}) = {2 * (1 - ncdf(1 / math.sqrt(TT))):.4f}")
e = [abs(quo[hh][1] - rows[1][1]) for hh in (0.1, 0.01, 0.001)]
assert abs(quo[0.0001][1] - rows[1][1]) < 1e-7, "definition limit must reach the formula"
assert e[1] < e[0] / 5 and e[2] < e[1] / 5, "quotient error must shrink with h"
assert abs(g_rows[2][2] - g_rows[2][1]) < 0.05, "GBM: definition vs formula for s^2"
assert abs(mm) < 4 * mse, "Dynkin: the compensated r^2 has mean zero"
assert abs(chart[-1][3] - chart[-1][1]) < 4 * chart[-1][4], "simulated E[r_2^2] vs exact OU law"
assert abs(p_int - p_fd) < 1e-5, "exit chance: integrals vs finite differences"
assert abs(t_int - t_fd) < 1e-5, "exit time: integrals vs finite differences"
assert abs(sims[0.00025][0][0] - p_int) < 4 * sims[0.00025][0][1], "simulated exit chance"
assert abs(sims[0.00025][1][0] - t_int) < 4 * sims[0.00025][1][1], "simulated exit time, finest step"
print("ALL CHECKS PASS")
