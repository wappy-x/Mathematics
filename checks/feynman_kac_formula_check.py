# Feynman-Kac -- the check behind the card.  Only math is imported.
# A $100 share, sigma 0.20, real drift 0.08, bank rate 0.05; a one-year call at $100.
# Roads to its price: closed form; heat-kernel average (Simpson); the Black-Scholes
# equation solved backwards on four grids; 200000 seeded draws under Q.  Then the
# martingale inside the proof, and an equation's solution that is not the expectation.
import math

S0, K, R, MU, SIG, T = 100.0, 100.0, 0.05, 0.08, 0.20, 1.0
SEED, DRAWS = 20260930, 200000
MASK = (1 << 64) - 1

class SplitMix64:                         # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                     # Box-Muller, cosine half
        u1, u2 = self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)

def phi(z):                               # bell-curve height
    return math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi)

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                              # bell-curve area left of x
    return 0.5 + simpson(phi, 0.0, x, 2000)

def closed_form(s, tau, drift=R):         # e^(-R tau) E[(S_T - K)+], S growing at `drift`
    if tau <= 0.0:
        return max(s - K, 0.0)
    v = SIG * math.sqrt(tau)
    d2 = (math.log(s / K) + (drift - 0.5 * SIG * SIG) * tau) / v
    return math.exp(-R * tau) * (s * math.exp(drift * tau) * ncdf(d2 + v) - K * ncdf(d2))

def heat_kernel(s, tau):                  # the heat equation's bell-curve average, discounted
    y = math.log(s) + (R - 0.5 * SIG * SIG) * tau
    f = lambda z: max(math.exp(y + SIG * math.sqrt(tau) * z) - K, 0.0) * phi(z)
    return math.exp(-R * tau) * simpson(f, -10.0, 10.0, 40000)

def grid(n, lam):                         # explicit scheme in x = log s; returns (V at S0, max |V|, steps, weights)
    dx = 2.4 / n
    m = math.ceil(SIG * SIG * T / (lam * dx * dx))
    dt = T / m
    a = 0.5 * SIG * SIG * dt / (dx * dx)
    b = (R - 0.5 * SIG * SIG) * dt / (2.0 * dx)
    pu, pm, pd = a + b, 1.0 - 2.0 * a, a - b
    xs = [math.log(S0) + (i - n // 2) * dx for i in range(n + 1)]
    v = [max(math.exp(x) - K, 0.0) for x in xs]
    for j in range(1, m + 1):             # each value: a weighted average of three, minus interest
        v = [0.0] + [pu * v[i + 1] + pm * v[i] + pd * v[i - 1] - R * dt * v[i] for i in range(1, n)] \
            + [math.exp(xs[n]) - K * math.exp(-R * j * dt)]
    return v[n // 2], max(abs(x) for x in v), m, (pu, pm, pd)

c = closed_form(S0, T)
v = SIG * math.sqrt(T); d2 = (math.log(S0 / K) + (R - 0.5 * SIG * SIG) * T) / v
print(f"share {S0:.0f}, strike {K:.0f}, r {R:.2f}, real drift {MU:.2f}, sigma {SIG:.2f}, T {T:.0f} year")
print(f"log drift {R - 0.5 * SIG * SIG:.6f}   d2 {d2:.6f}   d1 {d2 + v:.6f}   N(d2) {ncdf(d2):.6f}   N(d1) {ncdf(d2 + v):.6f}")
print(f"share half {S0 * ncdf(d2 + v):.6f}   cash half {K * math.exp(-R * T) * ncdf(d2):.6f}")
print(f"road 1, closed form                       {c:.6f}")
print(f"road 2, heat-kernel average (Simpson)     {(hk := heat_kernel(S0, T)):.6f}")
print("road 3, the equation solved backwards on a grid:")
errs = []
for n in (60, 120, 240, 480):
    val, _, m, (pu, pm, pd) = grid(n, 0.5)
    errs.append(val - c)
    print(f"  dx {2.4 / n:.4f}  steps {m:5d}  price {val:.6f}  error {val - c:+.6f}"
          f"  weights {pu:.4f} {pm:.4f} {pd:.4f}")
print("chart, grid error in cents " + " ".join(f"{-100.0 * e:.2f}" for e in errs))
print("  error ratio at each halving of dx " + " ".join(f"{errs[i] / errs[i + 1]:.2f}" for i in range(3)))
g = SplitMix64(SEED)
q_sum = q_sq = p_sum = p_sq = 0.0
for _ in range(DRAWS):                    # one normal, the payoff under Q and under the real drift
    z = g.normal()
    pq, pp = (max(S0 * math.exp((d - 0.5 * SIG * SIG) * T + v * z) - K, 0.0) * math.exp(-R * T) for d in (R, MU))
    q_sum += pq; q_sq += pq * pq; p_sum += pp; p_sq += pp * pp
mean_se = lambda s1, s2: (s1 / DRAWS, math.sqrt((s2 / DRAWS - (s1 / DRAWS) * (s1 / DRAWS)) / DRAWS))
(mq, se_q), (mp, se_p) = mean_se(q_sum, q_sq), mean_se(p_sum, p_sq)
print(f"road 4, {DRAWS} draws under Q (seed {SEED})  {mq:.4f} (se {se_q:.4f})")

print("the martingale e^(-rt) V(t, S_t), averaged over S_t (Simpson) and by closed form:")
times = (0.0, 0.25, 0.5, 0.75, 1.0)
lines = {}
for name, drift in (("Q", R), ("P", MU)):
    row = []
    for t in times:
        sd = SIG * math.sqrt(t)
        f = lambda z: closed_form(S0 * math.exp((drift - 0.5 * SIG * SIG) * t + sd * z), T - t) * phi(z)
        quad = c if t == 0.0 else math.exp(-R * t) * simpson(f, -10.0, 10.0, 400 if t < T else 40000)
        blend = closed_form(S0, T, (drift * t + R * (T - t)) / T)
        row.append((quad, blend))
        print(f"  {name}  t {t:.2f}   quadrature {quad:.6f}   closed form {blend:.6f}")
    lines[name] = row
print("chart, t " + " ".join(f"{t:6.2f}" for t in times))
for name in ("Q", "P"):
    print(f"chart, {name} " + " ".join(f"{q:6.2f}" for q, _ in lines[name]))

print("what breaks:")
print(f"  average under the real drift 0.08     {closed_form(S0, T, MU):.6f}"
      f"  draws {mp:.4f} (se {se_p:.4f})")
print(f"  real drift, discounted at 0.08 too    {closed_form(S0, T, MU) * math.exp((R - MU) * T):.6f}")
print(f"  curvature term dropped: (S - Ke^-rT)+ {max(S0 - K * math.exp(-R * T), 0.0):.6f}")
_, big, m_bad, (pu, pm, pd) = grid(120, 1.2)
print(f"  grid step too long: dx 0.0200, steps {m_bad}, middle weight {pm:.4f},"
      f" largest |V| 10^{math.log10(big):.1f}")
# dX = X^2 dW from X = 1: X_t = 1/|a + B_t|, B a 3-d Brownian motion, |a| = 1.
u_star = 2.0 * ncdf(1.0) - 1.0
s_sum = s_sq = 0.0
for _ in range(DRAWS):
    b1, b2, b3 = 1.0 + g.normal(), g.normal(), g.normal()
    x = 1.0 / math.sqrt(b1 * b1 + b2 * b2 + b3 * b3)
    s_sum += x; s_sq += x * x
ms, se_s = mean_se(s_sum, s_sq)
us = lambda tau, x: x * (2.0 * ncdf(1.0 / (x * math.sqrt(tau))) - 1.0)
h = 1e-3                                  # residual of u_tau = (1/2) x^4 u_xx at x = 1 and at two x != 1
res = [abs((us(t + h, x) - us(t - h, x)) / (2 * h) - 0.5 * x ** 4 * (us(t, x + h) - 2 * us(t, x) + us(t, x - h)) / (h * h))
       for t, x in ((1.0, 1.0), (0.5, 2.0), (2.0, 0.7))]
print(f"  dX = X^2 dW, payoff x, T 1: the solution u = x gives 1.000000")
print(f"    expectation 2N(1) - 1 {u_star:.6f}   draws {ms:.4f} (se {se_s:.4f})   its equation residual {max(res):.6f}")

assert abs(hk - c) < 1e-6, "heat-kernel road lands on the closed form"
assert abs(errs[-1]) < 2e-3 and abs(errs[0]) > abs(errs[1]) > abs(errs[2]) > abs(errs[3]), "grid closes in"
assert abs(mq - c) < 4 * se_q, "draws under Q within 4 se"
assert all(abs(q - c) < 1e-5 for q, _ in lines["Q"][1:]), "under Q the discounted price is a martingale"
assert all(abs(q - b) < 1e-5 for q, b in lines["P"][1:]), "under P the tower property gives the blend"
assert lines["P"][-1][0] > c + 2.0, "under P the discounted price drifts up"
assert abs(mp - closed_form(S0, T, MU)) < 4 * se_p, "real-drift draws match their own formula"
assert math.log10(big) > 3.0, "too long a step blows up"
assert abs(ms - u_star) < 4 * se_s, "draws land on the expectation 2N(1) - 1"
assert all(r < 1e-5 for r in res), "the expectation also solves dX = X^2 dW's equation, at x != 1 too"
print("ALL CHECKS PASS")
