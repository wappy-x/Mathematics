# Euler-Maruyama scheme -- the check behind the card.  Only math is imported.
# The share: dS = mu S dt + sigma S dW, S0 = $50, mu = 0.08 and sigma = 0.40 a year, T = 1 year.
# Exact solution on the same Brownian path: S_T = S0 exp((mu - sigma^2/2) T + sigma W_T).
# Roads: one step by hand against the exact step; Euler's method on the noise-free share;
# Euler-Maruyama against the exact solution on 5000 shared paths at 9 step sizes, measured,
# predicted from the term the scheme drops, and fitted for its slope; then the mistakes.
import math

S0, MU, SIG, T = 50.0, 0.08, 0.40, 1.0
SEED, PATHS, FINE = 80430, 5000, 256
LEVELS = [2 ** j for j in range(9)]       # 1, 2, 4, ..., 256 steps in the year
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

def mean_se(xs):
    m = sum(xs) / len(xs)
    v = sum((x - m) * (x - m) for x in xs) / (len(xs) - 1)
    return m, math.sqrt(v / len(xs)), v

def pred(n):                              # predicted mean |EM - exact|: sigma^2 sqrt(T dt / pi) S0 e^(mu T)
    return SIG * SIG * math.sqrt(T * (T / n) / math.pi) * S0 * math.exp(MU * T)

a = MU - 0.5 * SIG * SIG
mean_f = S0 * math.exp(MU * T)
print(f"share: S0 {S0:.0f}, mu {MU}, sigma {SIG} a year, T {T:.0f} year; log drift mu - sigma^2/2 = {MU:.2f} - {0.5 * SIG * SIG:.2f}; seeds {SEED} to {SEED + 2}")
print(f"exact law at T: mean {mean_f:.4f}  median {S0 * math.exp(a * T):.4f}  sd of ln(S_T/S0) {SIG * math.sqrt(T):.4f}")
for z in (1.0, 2.0):                      # one step of a quarter year, by hand
    dt = 0.25
    dw = z * math.sqrt(dt)
    em1, ex1 = S0 + MU * S0 * dt + SIG * S0 * dw, S0 * math.exp(a * dt + SIG * dw)
    print(f"by hand, dt 0.25, Z = {z:.0f}, dW = {dw:.1f}: drift {MU * S0 * dt:.4f}  noise {SIG * S0 * dw:.4f}  EM {em1:.4f}"
          f"  exact {ex1:.4f}  gap {ex1 - em1:.4f}  dropped term {0.5 * SIG * SIG * S0 * (dw * dw - dt):.4f}")
ode = [S0 * math.exp(MU * T) - S0 * (1.0 + MU * T / n) ** n for n in LEVELS]   # Euler's method, sigma = 0
print("ODE Euler, sigma = 0, error at T, n = 1 to 256: " + ", ".join(f"{e:.4f}" for e in ode))
lead = mean_f * MU * MU * T * T / 2.0
print(f"ODE Euler: n x error at n = 256 {256 * ode[-1]:.4f}; leading term S0 e^(mu T) mu^2 T^2 / 2 = {lead:.4f};"
      f" halving the step divides the error by {ode[-2] / ode[-1]:.4f}")
assert abs(256 * ode[-1] - lead) < 0.01 * lead
assert abs(ode[-2] / ode[-1] - 2.0) < 0.01
g = SplitMix64(SEED)                      # the pictured year: 208 fine Brownian steps, 4 a week
fw = [0.0]
for _ in range(208):
    fw.append(fw[-1] + math.sqrt(T / 208) * g.normal())
def em_path(n):                           # Euler-Maruyama on the pictured path with n steps
    b, x, xs = 208 // n, S0, [S0]
    for k in range(n):
        x += MU * x * (T / n) + SIG * x * (fw[(k + 1) * b] - fw[k * b])
        xs.append(x)
    return xs
e13, e52 = em_path(13), em_path(52)
print("figure, week: " + ", ".join(str(4 * k) for k in range(14)))
print("figure, exact: " + ", ".join(f"{S0 * math.exp(a * 4 * k / 52 + SIG * fw[16 * k]):.2f}" for k in range(14)))
print("figure, EM 4-week steps: " + ", ".join(f"{v:.2f}" for v in e13))
print("figure, EM weekly steps: " + ", ".join(f"{e52[4 * k]:.2f}" for k in range(14)))
g = SplitMix64(SEED + 1)                  # 5000 years; every step size runs on the same Brownian path
err = {n: [] for n in LEVELS}
rest, logs, ems, wrong, cross, prev = [], [], [], [], [], None
for _ in range(PATHS):
    W = [0.0]
    for _ in range(FINE):
        W.append(W[-1] + math.sqrt(T / FINE) * g.normal())
    exact = S0 * math.exp(a * T + SIG * W[-1])
    for n in LEVELS:
        b, dt, x = FINE // n, T / n, S0
        for k in range(n):
            x += MU * x * dt + SIG * x * (W[(k + 1) * b] - W[k * b])
        err[n].append(abs(x - exact))
    dt, y, q = T / FINE, S0, 0.0          # x is now the n = 256 run
    for k in range(FINE):
        d = W[k + 1] - W[k]
        q += d * d - dt
        y += MU * y * dt + SIG * y * d * math.sqrt(dt)          # mistake: noise scaled by dt
    rest.append(abs(x - exact + 0.5 * SIG * SIG * exact * q))   # the dropped term put back
    logs.append(math.log(exact / S0)); ems.append(x); wrong.append(math.log(y / S0))
    if prev is not None:
        cross.append(abs(x - prev))       # mistake: Euler on one path, exact on another
    prev = exact
ms = [mean_se(err[n]) for n in LEVELS]
for i, n in enumerate(LEVELS):
    r = "" if i == 0 else f"  ratio to previous {ms[i - 1][0] / ms[i][0]:.3f}"
    print(f"strong error n = {n:3d}: mean |EM - exact| {ms[i][0]:.4f} +- {ms[i][1]:.4f}  predicted {pred(n):.4f}{r}")
print("figure, measured: " + ", ".join(f"{m:.2f}" for m, _, _ in ms))
print("figure, predicted: " + ", ".join(f"{pred(n):.2f}" for n in LEVELS))
xs, ys = [math.log(T / n) for n in LEVELS[4:]], [math.log(m) for m, _, _ in ms[4:]]
xb, yb = sum(xs) / len(xs), sum(ys) / len(ys)
slope = sum((u - xb) * (v - yb) for u, v in zip(xs, ys)) / sum((u - xb) * (u - xb) for u in xs)
print(f"fitted order, n = 16 to 256: log error against log dt has slope {slope:.4f}; theory 0.5")
assert abs(slope - 0.5) < 0.08
assert abs(ms[-1][0] - pred(256)) < 4 * ms[-1][1]
r_m, r_se, _ = mean_se(rest)
print(f"n = 256, dropped term put back: mean |EM - exact + sigma^2 S_T R / 2| {r_m:.4f} +- {r_se:.4f}, R = sum of (dW^2 - dt)")
assert r_m < 0.15 * ms[-1][0]
m_m, m_se, _ = mean_se(ems)
print(f"weak: mean of EM at n = 256 {m_m:.4f} +- {m_se:.4f}; its exact mean S0 (1 + mu dt)^n {S0 * (1 + MU * T / 256) ** 256:.4f};"
      f" true mean {mean_f:.4f}")
assert abs(m_m - S0 * (1 + MU * T / 256) ** 256) < 4 * m_se
_, _, l_v = mean_se(logs)
_, _, w_v = mean_se(wrong)
l_se, w_se = math.sqrt(l_v / (2 * (PATHS - 1))), math.sqrt(w_v / (2 * (PATHS - 1)))   # se of a sample sd
print(f"sd of ln(S_T/S0): exact solution {math.sqrt(l_v):.4f} +- {l_se:.4f} (formula {SIG * math.sqrt(T):.4f});"
      f" mistake, noise scaled by dt: {math.sqrt(w_v):.4f} +- {w_se:.4f} (formula sigma sqrt(T dt) {SIG * math.sqrt(T * T / FINE):.4f})")
assert abs(math.sqrt(l_v) - SIG * math.sqrt(T)) < 4 * l_se
assert abs(math.sqrt(w_v) - SIG * math.sqrt(T * T / FINE)) < 4 * w_se
c_m, c_se, _ = mean_se(cross)
print(f"mistake, EM and exact on different paths, n = 256: mean gap {c_m:.4f} +- {c_se:.4f}")
g = SplitMix64(SEED + 2)                  # Euler-Maruyama with one step for the whole year
neg = [1.0 if 1.0 + MU * T + SIG * math.sqrt(T) * g.normal() < 0 else 0.0 for _ in range(100000)]
p, p_se, _ = mean_se(neg)
print(f"mistake, one step for the year: P(price < 0) {p:.4f} +- {p_se:.4f}; Phi({-(1 + MU * T) / SIG:.2f}) = {Phi(-(1 + MU * T) / SIG):.4f}")
assert abs(p - Phi(-(1 + MU * T) / SIG)) < 4 * p_se
print("ALL CHECKS PASS")
