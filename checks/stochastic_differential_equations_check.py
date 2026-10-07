# Stochastic differential equations -- the check behind the card.  Only math is imported.
# The share: dS = mu S dt + sigma S dW, S0 = $100, mu = 0.05 and sigma = 0.20 a year, T = 1 year.
# Claimed solution: S_t = S0 exp((mu - sigma^2/2) t + sigma W_t).  Roads: the formula and its
# moments; Ito's lemma by finite differences; the claim plugged into the integral equation on
# one fine path; Euler-Maruyama on the same Brownian steps at shrinking step sizes; and 4000
# simulated years, each estimate with its standard error.
import math

S0, MU, SIG, T = 100.0, 0.05, 0.20, 1.0
SEED, PATHS, FINE = 20260930, 4000, 256
MASK = (1 << 64) - 1

class SplitMix64:                         # the wing's generator, with Box-Muller normals
    def __init__(self, seed):
        self.s, self.spare = seed & MASK, None
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return z
        u1, u2 = self.uniform(), self.uniform()
        r = math.sqrt(-2.0 * math.log(1.0 - u1))
        self.spare = r * math.sin(2.0 * math.pi * u2)
        return r * math.cos(2.0 * math.pi * u2)

def Phi(x, n=4000):                       # normal CDF: Simpson's rule on the bell curve from -10 to x
    h, s = (x + 10.0) / n, math.exp(-50.0) + math.exp(-0.5 * x * x)
    for k in range(1, n):
        s += (4.0 if k % 2 == 1 else 2.0) * math.exp(-0.5 * (-10.0 + k * h) * (-10.0 + k * h))
    return s * h / 3.0 / math.sqrt(2.0 * math.pi)

def claim(t, w):                          # the claimed solution, as a function of time and W
    return S0 * math.exp((MU - 0.5 * SIG * SIG) * t + SIG * w)

def naive(t, w):                          # the ordinary-calculus guess
    return S0 * math.exp(MU * t + SIG * w)

def mean_se(xs):
    m = sum(xs) / len(xs)
    v = sum((x - m) * (x - m) for x in xs) / (len(xs) - 1)
    return m, math.sqrt(v / len(xs)), v

a = MU - 0.5 * SIG * SIG
mean_f = S0 * math.exp(MU * T)
var_f = S0 * S0 * math.exp(2.0 * MU * T) * (math.exp(SIG * SIG * T) - 1.0)
below_f = Phi(-a * math.sqrt(T) / SIG)
print(f"share: S0 {S0:.0f}, mu {MU}, sigma {SIG} a year; log drift mu - sigma^2/2 = {a:.4f}; seeds {SEED} to {SEED + 3}")
print(f"formula, one year: mean {mean_f:.4f}  sd {math.sqrt(var_f):.4f}  median {S0 * math.exp(a * T):.4f}"
      f"  P(S_1 < 100) {below_f:.4f}")
day = 1.0 / 252.0
print(f"one trading day at $100: Brownian step sd {math.sqrt(day):.4f}  drift {MU * S0 * day:.4f}  noise sd {SIG * S0 * math.sqrt(day):.4f}"
      f"  ratio {SIG * math.sqrt(day) / (MU * day):.1f}; drift equals noise sd after {SIG * SIG / (MU * MU):.0f} years")
print(f"by hand, one day, Z = 1: Euler {S0 + MU * S0 * day + SIG * S0 * math.sqrt(day):.4f}  exact"
      f" {claim(day, math.sqrt(day)):.4f};  W_1 = 0.5: claim {claim(1.0, 0.5):.4f}  naive guess {naive(1.0, 0.5):.4f}")
h = 1e-4                                  # Ito's lemma by finite differences at t = 0.5, w = 0.3
for name, f in (("claim", claim), ("naive", naive)):
    ft = (f(0.5 + h, 0.3) - f(0.5 - h, 0.3)) / (2 * h)
    fw = (f(0.5, 0.3 + h) - f(0.5, 0.3 - h)) / (2 * h)
    fww = (f(0.5, 0.3 + h) - 2 * f(0.5, 0.3) + f(0.5, 0.3 - h)) / (h * h)
    drift, noise = (ft + 0.5 * fww) / f(0.5, 0.3), fw / f(0.5, 0.3)
    print(f"Ito's lemma, {name}: drift per dollar {drift:.6f}  noise per dollar {noise:.6f}")
    assert abs(drift - (MU if name == "claim" else MU + 0.5 * SIG * SIG)) < 1e-5 and abs(noise - SIG) < 1e-5
g = SplitMix64(SEED)                      # one fine path: plug each guess into the integral equation
N = 65536
dw_fine = [math.sqrt(T / N) * g.normal() for _ in range(N)]
for n in (16, 256, 4096, 65536):
    b, dt = N // n, T / n
    w = [0.0]
    for k in range(n):
        w.append(w[-1] + sum(dw_fine[k * b:(k + 1) * b]))
    out = []
    for f in (claim, naive):
        x = [f(k * dt, w[k]) for k in range(n + 1)]
        drift = sum(MU * x[k] * dt for k in range(n))
        left = sum(SIG * x[k] * (w[k + 1] - w[k]) for k in range(n))
        mid = sum(SIG * 0.5 * (x[k] + x[k + 1]) * (w[k + 1] - w[k]) for k in range(n))
        out += [x[n] - x[0] - drift - left, x[n] - x[0] - drift - mid]
    print(f"residual n = {n:5d}: claim left {out[0]:+.4f} mid {out[1]:+.4f}   naive left {out[2]:+.4f} mid {out[3]:+.4f}")
gap = 0.5 * SIG * SIG * sum(naive(k * dt, w[k]) * dt for k in range(n))   # naive's missing dt term
print(f"naive guess, missing term sigma^2/2 * integral of S dt on this path: {gap:.4f}; W_1 {w[-1]:.4f}")
assert abs(out[0]) < 0.05 and abs(out[3]) < 0.05 and abs(out[2] - gap) < 0.05
assert abs(out[1] + 0.5 * SIG * SIG * sum(claim(k * dt, w[k]) * dt for k in range(n))) < 0.05
g = SplitMix64(SEED + 1)                  # the pictured year: weekly Brownian steps
wk = [math.sqrt(T / 52) * g.normal() for _ in range(52)]
W, eul = [0.0], [S0]
for d in wk:
    W.append(W[-1] + d)
for k in range(13):                       # Euler with 13 steps of 4 weeks, on the same path
    eul.append(eul[-1] * (1.0 + MU * 4 / 52 + SIG * (W[4 * k + 4] - W[4 * k])))
print("figure, week: " + ", ".join(str(4 * k) for k in range(14)))
print("figure, exact solution: " + ", ".join(f"{claim(4 * k / 52, W[4 * k]):.2f}" for k in range(14)))
print("figure, Euler, 4-week steps: " + ", ".join(f"{v:.2f}" for v in eul))
print("figure, median 100 e^(0.03 t): " + ", ".join(f"{S0 * math.exp(a * 4 * k / 52):.2f}" for k in range(14)))
g = SplitMix64(SEED + 2)                  # 4000 simulated years, Euler at 4 step sizes on each
NS = (4, 16, 64, 256)
err = {n: [] for n in NS}
ends, logs, below, eul256 = [], [], [], []
for _ in range(PATHS):
    dw = [math.sqrt(T / FINE) * g.normal() for _ in range(FINE)]
    exact = claim(T, sum(dw))
    for n in NS:
        b, x = FINE // n, S0
        for k in range(n):
            x += MU * x * (T / n) + SIG * x * sum(dw[k * b:(k + 1) * b])
        err[n].append(abs(x - exact))
    ends.append(exact); logs.append(math.log(exact / S0))
    below.append(1.0 if exact < S0 else 0.0); eul256.append(x)
for n in NS:
    m, se, _ = mean_se(err[n])
    print(f"strong error, Euler n = {n:3d} steps: mean |Euler - exact| {m:.4f} +- {se:.4f}")
print("figure, strong error at n = 4, 16, 64, 256: " + ", ".join(f"{mean_se(err[n])[0]:.2f}" for n in NS))
ratio = mean_se(err[4])[0] / mean_se(err[256])[0]
print(f"error ratio n = 4 to n = 256: {ratio:.2f}; square root of 64 = {math.sqrt(64):.0f}")
assert 5.0 < ratio < 12.0
m, se, v = mean_se(ends)
m4 = sum(((x - m) * (x - m)) * ((x - m) * (x - m)) for x in ends) / PATHS
print(f"simulated {PATHS} years: mean {m:.4f} +- {se:.4f}  var {v:.2f} +- {math.sqrt((m4 - v * v) / PATHS):.2f}"
      f" (formula {var_f:.2f})")
assert abs(m - mean_f) < 4 * se and abs(v - var_f) < 4 * math.sqrt((m4 - v * v) / PATHS)
(ml, sel, _), (mb, seb, _), (me, see, _) = mean_se(logs), mean_se(below), mean_se(eul256)
print(f"simulated: mean ln(S_1/S0) {ml:.4f} +- {sel:.4f}  P(S_1 < 100) {mb:.4f} +- {seb:.4f}"
      f"  Euler n = 256 mean {me:.4f} +- {see:.4f}")
assert abs(ml - a) < 4 * sel and abs(mb - below_f) < 4 * seb and abs(me - mean_f) < 4 * see
print(f"mistake, ordinary chain rule: mean {S0 * math.exp((MU + 0.5 * SIG * SIG) * T):.4f}"
      f"  median {S0 * math.exp(MU * T):.4f}  (right: {mean_f:.4f} and {S0 * math.exp(a * T):.4f})")
print(f"mistake, daily noise as sigma/252: {100 * SIG / 252:.4f} percent; right sigma/sqrt(252): {100 * SIG * math.sqrt(day):.4f} percent")
g = SplitMix64(SEED + 3)                  # 20000 one-step years: Euler at sigma 0.8, and the exact solution's P(S_1 < 100)
zs = [g.normal() for _ in range(20000)]
(mn, sen, _), (lo, slo, _) = mean_se([1.0 if 1.0 + MU + 0.8 * z < 0 else 0.0 for z in zs]), mean_se([1.0 if claim(T, math.sqrt(T) * z) < S0 else 0.0 for z in zs])
print(f"mistake, one Euler step of a year at sigma 0.8: P(price < 0) {mn:.4f} +- {sen:.4f},"
      f" exact Phi(-1.3125) {Phi(-(1.0 + MU) / 0.8):.4f}; the true solution is never negative")
assert abs(mn - Phi(-(1.0 + MU) / 0.8)) < 4 * sen
print(f"exact solution, 20000 one-step years: P(S_1 < 100) {lo:.4f} +- {slo:.4f}; ordinary-calculus guess gives {Phi(-MU * math.sqrt(T) / SIG):.4f}")
assert abs(lo - below_f) < 4 * slo and abs(lo - Phi(-MU * math.sqrt(T) / SIG)) > 4 * slo
print("ALL CHECKS PASS")
