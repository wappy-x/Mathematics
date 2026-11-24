# The Stratonovich integral -- the check behind the card.  Only math is imported.
# W is Brownian motion, t in years.  The Stratonovich sum reads the integrand at
# the middle of each step; the Ito sum reads it at the start.  Roads: a 4-step
# path in whole tenths, exactly; one seeded path pinned to end at W_1 = 1.4;
# an ordinary differential equation along a smoothed path (Wong-Zakai); and
# 20000 seeded paths for averages.  Floats are added in plain loops, not sum().
from math import log, cos, pi, sqrt, exp
MASK = (1 << 64) - 1
MU, SIG, S0 = 0.05, 0.20, 100.0                          # the share, read the Stratonovich way

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def uniform(self): return ((self.next() >> 11) + 0.5) * 2.0 ** -53
    def normal(self):                                    # Box-Muller, cosine branch only
        u, v = self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u)) * cos(2.0 * pi * v)

def mean_se(s, s2, m):                                   # sample mean and its standard error
    a = s / m
    return a, sqrt((s2 / m - a * a) * m / (m - 1) / m)

# Road 1: four quarter-year steps, W in whole tenths, so every sum is an exact integer
w = [0, 8, 6, 10, 14]
left = right = mid2 = qv = 0
for k in range(4):
    d = w[k + 1] - w[k]
    left += w[k] * d; right += w[k + 1] * d; mid2 += (w[k] + w[k + 1]) * d; qv += d * d
    print(f"hand, step {k + 1}: W {w[k] / 10:.1f} to {w[k + 1] / 10:.1f}, move {d / 10:.1f}, half-move {d / 20:.1f}, "
          f"middle {(w[k] + w[k + 1]) / 20:.1f}, start x move {w[k] * d / 100:.2f}, "
          f"middle x move {(w[k] + w[k + 1]) * d / 200:.2f}, move squared {d * d / 100:.2f}")
assert mid2 == w[4] * w[4]                               # midpoint sum telescopes to W^2/2
assert 2 * left == w[4] * w[4] - qv                      # left sum = W^2/2 - (sum of squares)/2
assert right - left == qv
print(f"hand, totals: Ito (start) {left / 100:.2f}, Stratonovich (middle) {mid2 / 200:.2f}, "
      f"end-point {right / 100:.2f}, sum of squares {qv / 100:.2f}, gap {(mid2 - 2 * left) / 200:.2f}")

# Road 2: one seeded path of 20000 half-steps, pinned to end at 1.4 (a Brownian bridge)
rng = SplitMix64(20261123)
N, END = 10000, 1.4
f = [0.0]
for j in range(2 * N): f.append(f[-1] + sqrt(1.0 / (2 * N)) * rng.normal())
last = f[2 * N]
f = [f[j] - j / (2 * N) * (last - END) for j in range(2 * N + 1)]
lsum = tsum = msum = q = sd = sl = sint = 0.0
chart = [[0.0], [0.0], [0.0]]
for k in range(N):
    a, m, b = f[2 * k], f[2 * k + 1], f[2 * k + 2]
    d, dt = b - a, 1.0 / N
    lsum += a * d; tsum += 0.5 * (a + b) * d; msum += m * d; q += d * d
    sa, sb = S0 * exp(MU * k * dt + SIG * a), S0 * exp(MU * (k + 1) * dt + SIG * b)
    sd += 0.5 * (sa + sb) * (MU * dt + SIG * d)          # Stratonovich sum for dS
    sl += sa * (MU * dt + SIG * d); sint += sa * dt      # Ito-reading sum, and int S dt
    if (k + 1) % 500 == 0:
        chart[0].append(tsum); chart[1].append(lsum); chart[2].append(0.5 * q)
assert abs(tsum - END * END / 2) < 1e-9
assert abs(msum - END * END / 2) < 4 * sqrt(1.0 / (4 * N))
assert abs(lsum - (END * END - 1) / 2) < 4 * sqrt(2.0 / N) / 2
assert abs(q - 1.0) < 4 * sqrt(2.0 / N)
print(f"path, {N} steps, W_1 = {f[2 * N]:.4f}: sum of squares {q:.4f} (limit 1)")
print(f"path, Stratonovich, average of ends: {tsum:.4f}; at the middle time: {msum:.4f}; W^2/2 = {END * END / 2:.4f}")
print(f"path, Ito (start): {lsum:.4f}; (W^2 - 1)/2 = {(END * END - 1) / 2:.4f}; end-point sum {tsum + 0.5 * q:.4f}")
print(f"path, gap Stratonovich - Ito {tsum - lsum:.4f}, half the sum of squares {0.5 * q:.4f}")
for i, name in enumerate(("Stratonovich sum", "Ito sum", "half the squares")):
    print(f"chart, {name}: " + ", ".join(f"{v:.2f}" for v in chart[i]))
s1 = S0 * exp(MU + SIG * END)
assert abs(sd - (s1 - S0)) < 0.01                        # ordinary chain rule, path by path
assert abs((s1 - S0) - sl - 0.5 * SIG * SIG * sint) < 0.1  # Ito reading needs the half sigma^2 term
print(f"share, S_1 = 100 exp(0.05 + 0.2 W_1) = {s1:.4f}; Stratonovich sum of dS {sd:.4f}; Ito-reading sum {sl:.4f}")
print(f"share, half sigma^2 x int S dt = {0.5 * SIG * SIG * sint:.4f}; Ito-reading sum plus it {sl + 0.5 * SIG * SIG * sint:.4f}")

# Road 3: Wong-Zakai. Join the path's values every 0.01 year by straight lines and
# solve the ordinary equation dS/dt = S (0.05 + 0.2 x slope) by Runge-Kutta.
x = S0
for k in range(100):
    slope = (f[200 * (k + 1)] - f[200 * k]) / 0.01
    h = 0.01 / 20
    for _ in range(20):
        g = lambda s: s * (MU + SIG * slope)
        k1 = g(x); k2 = g(x + h / 2 * k1); k3 = g(x + h / 2 * k2); k4 = g(x + h * k3)
        x += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
ito_sol = S0 * exp(MU - SIG * SIG / 2 + SIG * END)
assert abs(x - s1) < 1e-6 * s1 and abs(x - ito_sol) > 2.0
print(f"smoothed path, ordinary equation: S_1 = {x:.4f}; Stratonovich solution {s1:.4f}; Ito solution {ito_sol:.4f}")

# Road 4: 20000 seeded paths of 100 steps: averages
M, n = 20000, 100
dt = 1.0 / n
acc = [[0.0, 0.0] for _ in range(6)]
worst = 0.0
for _ in range(M):
    wv = lf = 0.0
    heun = eul7 = eul5 = S0
    cx, cy, r2 = 1.0, 0.0, 1.0
    for k in range(n):
        d = sqrt(dt) * rng.normal()
        lf += wv * d; wv += d
        p = heun + heun * (MU * dt + SIG * d)            # Heun: predict, then average the ends
        heun += 0.5 * (heun + p) * (MU * dt + SIG * d)
        eul7 += eul7 * ((MU + SIG * SIG / 2) * dt + SIG * d)   # converted to Ito, Euler step
        eul5 += eul5 * (MU * dt + SIG * d)               # NOT converted: the mistake
        r2 *= 1.0 + d * d                                # Ito rotation dX = -Y dW, dY = X dW, Euler
        c = d / 2
        cx, cy = (cx * (1 - c * c) - 2 * c * cy) / (1 + c * c), (cy * (1 - c * c) + 2 * c * cx) / (1 + c * c)
    worst = max(worst, abs(cx * cx + cy * cy - 1.0))
    for a, v in zip(acc, (wv * wv / 2, lf, heun, eul7, eul5, r2)):
        a[0] += v; a[1] += v * v
names = ("Stratonovich int W dW", "Ito int W dW", "share, Heun (Stratonovich)",
         "share, Euler with drift 0.07", "share, Euler with drift 0.05", "Ito rotation, radius squared")
exact = (0.5, 0.0, S0 * (1 + MU * dt + 0.5 * (MU * MU * dt * dt + SIG * SIG * dt)) ** n, S0 * (1 + (MU + SIG * SIG / 2) * dt) ** n,
         S0 * (1 + MU * dt) ** n, (1 + dt) ** n)
print(f"averages, {M} paths, {n} steps, seed 20261123")
for i in range(6):
    m, se = mean_se(acc[i][0], acc[i][1], M)
    assert abs(m - exact[i]) < 4 * se
    print(f"averages, {names[i]}: {m:.4f} +/- {se:.4f} (exact {exact[i]:.4f})")
assert worst < 1e-12
print(f"averages, Stratonovich rotation: radius squared within 1e-12 of 1 on every path; Ito limit e = {exp(1.0):.4f}")
print(f"share, no grid: Stratonovich mean 100 e^0.07 = {S0 * exp(MU + SIG * SIG / 2):.2f}, median 100 e^0.05 = {S0 * exp(MU):.2f}; "
      f"Ito median 100 e^0.03 = {S0 * exp(MU - SIG * SIG / 2):.2f}")
print("ALL CHECKS PASS")
