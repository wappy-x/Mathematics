# Milstein and the two kinds of error -- the check behind the card.  Standard library only.
# An ounce of silver at $30, drift 5% a year, volatility 30% a year, one year, on geometric Brownian motion.
# Road 1: exact error formulas from moments (no paths).  Road 2: seeded coupled simulation with
# standard errors.  Road 3: one step, and the stochastic integral behind the correction, by fine sums.
from math import exp, sqrt, log, log1p, expm1, cos, sin, pi

X0, MU, SIG, T = 30.0, 0.05, 0.30, 1.0
RATE2 = 2 * MU + SIG * SIG                       # exponent of the exact second moment

class SplitMix64:                            # the wing's generator, seed stated, normals by Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def normals(self, n):
        out = []
        while len(out) < n:
            r, th = sqrt(-2.0 * log(self.u())), 2.0 * pi * self.u()
            out += [r * cos(th), r * sin(th)]
        return out[:n]

def factor(dw, h, scheme):                   # one step's multiplier: 'E' Euler, 'M' Milstein, 'X' exact
    if scheme == "X": return exp((MU - 0.5 * SIG * SIG) * h + SIG * dw)
    f = 1.0 + MU * h + SIG * dw
    return f + 0.5 * SIG * SIG * (dw * dw - h) if scheme == "M" else f

def exact_errors(n, milstein, x0=X0, t=T):   # Road 1: E(Y-X)^2 = x0^2 (M^n - 2 K^n + e^{RATE2 t})
    h = t / n                                # bracket over e^{RATE2 t} by log1p and expm1: no cancellation
    extra = SIG ** 4 * h * h / 2 if milstein else 0.0
    lm = n * log1p(2 * MU * h + MU * MU * h * h + SIG * SIG * h + extra) - RATE2 * t   # log M^n - RATE2 t, M = E[A^2]
    lk = n * MU * h + n * log1p((MU + SIG * SIG) * h + extra) - RATE2 * t   # log K^n - RATE2 t, K = E[A G], G exact
    strong = x0 * sqrt(exp(RATE2 * t) * (expm1(lm) - 2 * expm1(lk)))
    weak = x0 * x0 * exp(RATE2 * t) * expm1(lm)                    # E f(Y_N) - E f(X_T), f(x) = x^2
    return strong, weak

LEVELS = [1, 2, 4, 8, 16, 32, 64]
ex = {n: (exact_errors(n, False), exact_errors(n, True)) for n in LEVELS + [1024]}
print("road 1, exact: steps, Euler path RMS, Milstein path RMS, Euler avg error, Milstein avg error")
for n in LEVELS:
    (se, we), (sm, wm) = ex[n]
    print(f"exact N={n:<3} {se:9.4f} {sm:9.4f} {we:10.3f} {wm:10.3f}")
slope = lambda a, b: log(a / b) / log(2.0)
print(f"order, N=32 to 64: Euler path {slope(ex[32][0][0], ex[64][0][0]):.3f}, Milstein path "
      f"{slope(ex[32][1][0], ex[64][1][0]):.3f}, Euler avg {slope(ex[32][0][1], ex[64][0][1]):.3f}, "
      f"Milstein avg {slope(ex[32][1][1], ex[64][1][1]):.3f}")
c_euler = X0 * exp(RATE2 * T / 2) * SIG * SIG * sqrt(T / 2)     # leading constant from Why it works
print(f"Euler RMS/sqrt(h) at N=1024 {ex[1024][0][0] * sqrt(1024):.4f}; predicted constant {c_euler:.4f}")
print(f"Milstein RMS/h: N=16 {ex[16][1][0] * 16:.4f}, N=64 {ex[64][1][0] * 64:.4f}, N=1024 {ex[1024][1][0] * 1024:.4f}")
print(f"shared average, N=4: Euler and Milstein {X0 * (1 + MU / 4) ** 4:.4f}; exact {X0 * exp(MU * T):.4f}")

# ---- worked numbers: one month, two big kicks ----
for dw in (-0.60, 0.60):
    e, m, x = (X0 * factor(dw, 1 / 12, s) for s in "EMX")
    print(f"one month, kick {dw:+.2f}: mu dt {MU / 12:.6f}, log drift {(MU - SIG * SIG / 2) / 12:.6f}; factors {e / X0:.6f} + {(m - e) / X0:.6f} = {m / X0:.6f}, exact {x / X0:.6f}; "
          f"Euler {e:.4f}  Milstein {m:.4f}  exact {x:.4f}  errors {e - x:+.4f} {m - x:+.4f}")
# ---- road 3: one step's own error, exact, from the same formula with n = 1 ----
for n in (16, 64):
    print(f"one step h=1/{n}: Euler local RMS {exact_errors(1, False, 1.0, 1 / n)[0]:.6f}  "
          f"Milstein local RMS {exact_errors(1, True, 1.0, 1 / n)[0]:.6f}")
gen = SplitMix64(20260930)
m_sub, h1 = 100000, 1 / 12                   # one month cut into 100,000 pieces
w = left = qv = 0.0
for di in (sqrt(h1 / m_sub) * z for z in gen.normals(m_sub)): left += w * di; w += di; qv += di * di
ito, ordinary = (w * w - h1) / 2, w * w / 2
print(f"integral of (W-W_0) dW over a month: left sum {left:.6f}; Ito (dW^2 - h)/2 {ito:.6f}; "
      f"ordinary dW^2/2 {ordinary:.6f}; sum of squared pieces {qv:.6f} vs h {h1:.6f}")

# ---- the picture: one sample path, 12 monthly steps, one shared set of kicks ----
kicks = [sqrt(1 / 12) * z for z in gen.normals(12)]
paths = {s: [X0] for s in "XEM"}
for dw in kicks:
    for s in "XEM": paths[s].append(paths[s][-1] * factor(dw, 1 / 12, s))
for s, name in (("X", "exact"), ("E", "Euler"), ("M", "Milstein")):
    print(f"figure, {name:<9}" + " ".join(f"{v:.2f}" for v in paths[s]))

# ---- road 2: coupled simulation.  64 fine kicks per path; coarser grids add them up ----
PATHS, NF = 20000, 64
acc = {(n, s): [0.0, 0.0, 0.0, 0.0] for n in LEVELS for s in "EMC"}   # C: coin-flip kicks
for _ in range(PATHS):
    cum = [0.0]                              # the Brownian path on the fine grid
    for z in gen.normals(NF): cum.append(cum[-1] + sqrt(T / NF) * z)
    xt = X0 * exp((MU - 0.5 * SIG * SIG) * T + SIG * cum[NF])
    for n in LEVELS:
        h, k, y = T / n, NF // n, {"E": X0, "M": X0, "C": X0}
        for j in range(n):
            dw = cum[(j + 1) * k] - cum[j * k]
            y["E"] *= factor(dw, h, "E"); y["M"] *= factor(dw, h, "M")
            y["C"] *= 1.0 + MU * h + SIG * (sqrt(h) if dw >= 0 else -sqrt(h))
        for s in "EMC":
            e2, dv = (y[s] - xt) ** 2, y[s] ** 2 - xt ** 2
            a = acc[(n, s)]; a[0] += e2; a[1] += e2 * e2; a[2] += dv; a[3] += dv * dv
def summary(n, s):
    a = acc[(n, s)]
    mse, wk = a[0] / PATHS, a[2] / PATHS
    se_mse, se_wk = sqrt((a[1] / PATHS - mse * mse) / (PATHS - 1)), sqrt((a[3] / PATHS - wk * wk) / (PATHS - 1))
    return sqrt(mse), se_mse / (2 * sqrt(mse)), wk, se_wk
print(f"road 2, simulated, {PATHS} coupled paths, seed 20260930: steps, path RMS +- se, avg error +- se")
for n in LEVELS:
    (re_, sre, we_, swe), (rm, srm, wm, swm) = summary(n, "E"), summary(n, "M")
    print(f"sim N={n:<3} Euler {re_:7.4f} +- {sre:.4f} {we_:9.3f} +- {swe:.3f} | "
          f"Milstein {rm:7.4f} +- {srm:.4f} {wm:9.3f} +- {swm:.3f}")
for n in (4, 64):
    rc, src = summary(n, "C")[:2]
    print(f"coin-flip kicks N={n}: path RMS {rc:.4f} +- {src:.4f}")
def coin_avg_error(n):                       # all 2^n coin paths, grouped by the number of up kicks
    h, tot, c = T / n, 0.0, 1.0
    for j in range(n + 1):
        y = X0 * (1 + MU * h + SIG * sqrt(h)) ** j * (1 + MU * h - SIG * sqrt(h)) ** (n - j)
        tot += c / 2 ** n * y * y; c = c * (n - j) / (j + 1)
    return tot - X0 * X0 * exp(RATE2 * T)
print(f"coin-flip kicks, every path enumerated: avg error N=4 {coin_avg_error(4):.3f}, N=16 {coin_avg_error(16):.3f}")
for label, i, j, c in (("Euler path RMS, cents", 0, 0, 100), ("Milstein path RMS, cents", 1, 0, 100),
                       ("Euler avg error", 0, 1, 1), ("Milstein avg error", 1, 1, 1)):
    print(f"chart, {label:<25}" + " ".join(f"{c * ex[n][i][j]:.2f}" for n in LEVELS))

# ---- what breaks ----
print(f"wrong: correction without -h, average at N=64 {X0 * (1 + (MU + SIG * SIG / 2) / 64) ** 64:.4f}; "
      f"limit {X0 * exp((MU + SIG * SIG / 2) * T):.4f}; right {X0 * exp(MU * T):.4f}")
for n in (4, 64):                            # scheme against an exact path driven by other noise
    h = T / n
    ey2 = X0 * X0 * ((1 + MU * h) ** 2 + SIG * SIG * h + SIG ** 4 * h * h / 2) ** n
    uncoupled = sqrt(ey2 + X0 * X0 * exp(RATE2 * T) - 2 * X0 * (1 + MU * h) ** n * X0 * exp(MU * T))
    print(f"wrong: uncoupled noise, Milstein N={n}: path RMS {uncoupled:.4f}")

for s, n in (("E", 16), ("M", 16), ("E", 4)):
    r, sr, wv, sw = summary(n, s)
    exact_s, exact_w = ex[n][0 if s == "E" else 1]
    assert abs(r - exact_s) < 4 * sr, "simulated path error must sit within 4 se of the exact formula"
    assert abs(wv - exact_w) < 4 * sw, "simulated average error must sit within 4 se of the exact formula"
assert abs(ex[1024][0][0] * sqrt(1024) / c_euler - 1) < 0.005, "Euler constant vs the piling-up argument"
assert 0.45 < slope(ex[32][0][0], ex[64][0][0]) < 0.55, "Euler path order one half"
assert 0.95 < slope(ex[32][1][0], ex[64][1][0]) < 1.05, "Milstein path order one"
assert abs(left - ito) < 5 * h1 / sqrt(2 * m_sub), "left sums land on the Ito value (dW^2 - h)/2"
assert abs(left - ordinary) > 0.4 * h1, "ordinary calculus misses by about h/2"
assert summary(64, "C")[0] > 0.8 * summary(4, "C")[0], "coin-flip kicks must not converge in the path sense"
assert abs(coin_avg_error(16) - ex[16][0][1]) < 1e-6, "enumerated coin flips keep Euler's average error"
print("ALL CHECKS PASS")
