# The Ito integral -- the check behind the card.  Only math is imported.
# Price S_t = 100 + 20 W_t dollars, t in years, W a Brownian motion.  A strategy
# holds H_t shares; its gain is 20 times the Ito integral of H against W.
# Three roads: the formulas; exact enumeration of every path of a coin-toss
# walk, in whole numbers; a seeded simulation of Brownian motion (SplitMix64
# and Box-Muller, written out), each average printed with its standard error.
from math import log, cos, pi, sqrt
MASK = (1 << 64) - 1
SIGMA, T = 20.0, 1.0

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def uniform(self): return ((self.next() >> 11) + 0.5) * 2.0 ** -53
    def normal(self):                                   # Box-Muller, cosine branch only
        u, v = self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u)) * cos(2.0 * pi * v)

def walk(code, n):                                      # coin-toss walk X_0..X_n; bit k is step k
    x = [0]
    for k in range(n): x.append(x[-1] + (1 if code >> k & 1 else -1))
    return x

def mean_se(s, s2, m):                                  # sample mean and its standard error
    a = s / m
    return a, sqrt((s2 / m - a * a) * m / (m - 1) / m)

print(f"share S_t = 100 + {SIGMA:.0f} W_t dollars, t in years, horizon T = {T:.0f} year")
# Road 1: the formulas, from the isometry E[I^2] = E[int H^2 dt]
var_half = SIGMA * SIGMA * (2 * 2 * T / 2 + 0.5 * T / 2)   # 2 shares, then 1 share half the time
var_wdw = SIGMA * SIGMA * T * T / 2                      # int_0^T E[W_t^2] dt = T^2 / 2
peek = SIGMA * sqrt(T / 2) / sqrt(2 * pi)                # 20 E[max(dW, 0)] over half a year
print(f"formula, half-year rule: E[int H^2 dt] = 4 x {T / 2:.1f} + 0.5 x {T / 2:.1f} = {var_half / (SIGMA * SIGMA):.6f}; mean gain 0, variance {var_half:.6f}, sd ${sqrt(var_half):.6f}")
print(f"formula, hold W_t shares: E[int W_t^2 dt] = T^2/2 = {T * T / 2:.6f}; mean gain 0, variance {var_wdw:.6f}, sd ${sqrt(var_wdw):.6f}")
print(f"formula, ordinary chain rule mean ${SIGMA * T / 2:.6f}, right endpoint mean ${SIGMA * T:.6f}, peeking rule mean ${peek:.6f}")
# Road 2: every path of a coin-toss walk with steps of size sqrt(dt), dt = T / n
for n in (2, 6, 10, 14):                                # half-year rule; n/2 odd, never at 0 then
    h, s1, s2, up, cond = n // 2, 0, 0, 0, {}
    for code in range(2 ** n):
        x = walk(code, n)
        later = (x[h] > 0) * (x[n] - x[h])              # second-half gain / (20 sqrt(dt))
        b = 2 * x[h] + later
        s1 += b; s2 += b * b; up += x[h] > 0
        key = code & ((1 << h) - 1)                     # the first-half history
        cond[key] = cond.get(key, 0) + later
    assert s1 == 0
    assert 4 * s2 == 9 * n * 2 ** n                     # isometry: E[I^2] = 2 + 1/4
    assert all(v == 0 for v in cond.values())           # martingale: future gain averages 0
    print(f"enumerated, half-year rule, {n} steps, {2 ** n} paths: P(S >= 100 at half-year) {up / 2 ** n:.6f}, "
          f"mean gain {s1 / 2 ** n:.6f}, variance {SIGMA * SIGMA * s2 / (n * 2 ** n):.6f}, {len(cond)} histories with future mean 0")
for n in (4, 8, 16):                                    # hold W_t shares
    s2, cond = 0, {}
    for code in range(2 ** n):
        x = walk(code, n)
        g = [x[k] * (x[k + 1] - x[k]) for k in range(n)]   # each trade's gain / dt
        fut = 0
        for m in range(n - 1, -1, -1):                  # gain after each history of length m
            fut += g[m]
            key = (m, code & ((1 << m) - 1))
            cond[key] = cond.get(key, 0) + fut
        a = fut
        assert 2 * a == x[n] * x[n] - n                 # pathwise: left sum = (W_T^2 - T) / 2
        s2 += a * a
    assert 2 * s2 == 2 ** n * n * (n - 1)               # isometry: sum of E[X_k^2] = n(n-1)/2
    assert all(v == 0 for v in cond.values())
    print(f"enumerated, hold W_t, {n} steps: left sum = (W_T^2 - T)/2 on all {2 ** n} paths, "
          f"E[I^2] {s2 / (n * n * 2 ** n):.6f}, formula (1 - 1/n)/2 = {(1 - 1 / n) / 2:.6f}, {len(cond)} histories with future mean 0")
# Road 3: seeded simulation of Brownian motion on a grid
rng = SplitMix64(20260930)
M, N = 40000, 100
sd = sqrt(T / N)
acc = [[0.0, 0.0, 0.0] for _ in range(5)]
for _ in range(M):
    w = left = right = wh = 0.0
    for k in range(N):
        dw = sd * rng.normal()
        left += w * dw; right += (w + dw) * dw; w += dw
        if k == N // 2 - 1: wh = w
    gains = (2 * wh + (w - wh if wh >= 0 else 0.0), left, right, max(w - wh, 0.0), w * w / 2)
    for a, g in zip(acc, gains):
        g *= SIGMA; a[0] += g; a[1] += g * g; a[2] += (g * g) * (g * g)
names = ("half-year rule", "hold W_t, left endpoint (Ito)", "hold W_t, right endpoint",
         "peeking rule", "ordinary chain rule 10 W_T^2")
exact_mean = (0.0, 0.0, SIGMA * T, peek, SIGMA * T / 2)
print(f"simulated, {M} paths, {N} steps of {T / N:.2f} year, seed 20260930")
for i in range(5):
    m, se = mean_se(acc[i][0], acc[i][1], M)
    assert abs(m - exact_mean[i]) < 4 * se
    print(f"simulated, {names[i]}: mean gain ${m:.4f} +/- {se:.4f} (exact {exact_mean[i]:.4f})")
for i, exact in ((0, var_half), (1, var_wdw * (1 - 1 / N))):
    m, se = mean_se(acc[i][1], acc[i][2], M)
    assert abs(m - exact) < 4 * se
    print(f"simulated, {names[i]}: mean square gain {m:.2f} +/- {se:.2f} (exact on this grid {exact:.2f})")
print("left sum minus (W_T^2 - T)/2, in dollars, 2000 paths per step size")
for n in (10, 100, 1000):
    s = s2 = 0.0
    sdn = sqrt(T / n)
    for _ in range(2000):
        w = left = 0.0
        for k in range(n):
            dw = sdn * rng.normal(); left += w * dw; w += dw
        e = SIGMA * (left - (w * w - T) / 2); s += e * e; s2 += (e * e) * (e * e)
    m, se = mean_se(s, s2, 2000)
    exact = SIGMA * SIGMA * T * T / (2 * n)
    assert abs(m - exact) < 4 * se
    print(f"steps, {n}, rms error ${sqrt(m):.2f}, formula 20 T / sqrt(2n) = ${sqrt(exact):.2f}, mean square {m:.4f} +/- {se:.4f}")
n = 10000                                               # one path, 10000 steps, for variation and the chart
sdn = sqrt(T / n)
path = [0.0]
for _ in range(n): path.append(path[-1] + sdn * rng.normal())
for m in (10, 100, 1000, 10000):
    qv = tv = 0.0
    j = n // m
    for k in range(m):
        d = path[(k + 1) * j] - path[k * j]; qv += d * d; tv += abs(d)
    assert abs(qv - T) < 4 * sqrt(2 / m) * T
    assert abs(tv - sqrt(2 * m * T / pi)) < 4 * sqrt(T * (1 - 2 / pi))
    print(f"one path, {m} steps: quadratic variation {qv:.4f} (limit {T:.4f}), total variation {tv:.4f} (mean sqrt(2n/pi) = {sqrt(2 * m * T / pi):.4f})")
ito, form, naive, left = [0.0], [0.0], [0.0], 0.0
for k in range(n):
    left += path[k] * (path[k + 1] - path[k])
    if (k + 1) % 500 == 0:
        t = (k + 1) * T / n
        ito.append(SIGMA * left); form.append(SIGMA * (path[k + 1] * path[k + 1] - t) / 2)
        naive.append(SIGMA * path[k + 1] * path[k + 1] / 2)
assert abs(ito[-1] - form[-1]) < 4 * SIGMA * T / sqrt(2 * n)
print("chart, t = 0, 0.05, ..., 1 year; W_T = " + f"{path[n]:.4f}, price at year end ${100 + SIGMA * path[n]:.2f}")
print("chart, Ito sum ($): " + ", ".join(f"{v:.2f}" for v in ito))
print("chart, 10 (W_t^2 - t) ($): " + ", ".join(f"{v:.2f}" for v in form))
print("chart, ordinary 10 W_t^2 ($): " + ", ".join(f"{v:.2f}" for v in naive))
print("ALL CHECKS PASS")
