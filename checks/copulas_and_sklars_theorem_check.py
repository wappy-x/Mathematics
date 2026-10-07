# Copulas and Sklar's theorem: the check behind the card. Standard library only.
# Two markets' daily returns: A is normal with spread 1.0 percent, B normal with 1.5.
# Ranks agree with Kendall's tau = 0.5, joined by a Gaussian copula (rho = sin(pi/4)) or a
# Clayton copula (theta = 2). Roads: exact formulas, two unrelated integrals, seeded simulations.
import math

M64 = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.s = seed
    def u(self):                                  # SplitMix64 -> uniform in (0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
    def normal(self):                             # Box-Muller, one of the pair
        r = math.sqrt(-2.0 * math.log(self.u()))
        return r * math.cos(2.0 * math.pi * self.u())

def phi(z): return math.exp(-z * z / 2.0) / math.sqrt(2.0 * math.pi)
def Phi(z):                                       # series near 0, continued fraction in the tails
    if z < -3.0:
        x, f = -z, -z
        for k in range(200, 0, -1): f = x + k / f
        return phi(x) / f
    if z > 3.0: return 1.0 - Phi(-z)
    a, total = z, z
    for n in range(1, 100):
        a *= -z * z / (2 * n); total += a / (2 * n + 1)
    return 0.5 + total / math.sqrt(2.0 * math.pi)
def Phi_inv(p):                                   # Newton's method on Phi
    z = 0.0
    for _ in range(100):
        step = (Phi(z) - p) / phi(z); z -= step
        if abs(step) < 1e-14: break
    return z
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n)))

TAU = 0.5
SA, SB = 1.0, 1.5                                 # daily spreads of markets A and B, percent
RHO = math.sin(math.pi * TAU / 2.0)               # Gaussian parameter with this tau
TH = 2.0 * TAU / (1.0 - TAU)                      # Clayton parameter with this tau
def clayton(u, v): return (u ** -TH + v ** -TH - 1.0) ** (-1.0 / TH)
assert abs(clayton(0.3, 1.0) - 0.3) < 1e-12       # a copula's margin is uniform: C(u, 1) = u
def gauss(a, b, rho):                             # road 1: condition on market A's score
    s = math.sqrt(1.0 - rho * rho)
    return simpson(lambda x: phi(x) * Phi((b - rho * x) / s), -12.0, a, 4000)
def gauss_angle(a, rho):                          # road 2: polar angle, Rayleigh radius
    al = math.acos(rho)
    def g(t):
        m = min(-math.cos(t), -math.cos(t - al))
        return math.exp(-a * a / (2.0 * m * m)) if m > 0 else 0.0
    return simpson(g, math.pi / 2 + al, 1.5 * math.pi, 20000) / (2.0 * math.pi)

print(f"tau {TAU:.3f}  gaussian rho {RHO:.6f}  clayton theta {TH:.3f}")
a01 = Phi_inv(0.01)
assert abs(a01 - -2.3263478740408408) < 1e-12   # published 1st percentile of the bell
print(f"worst 1-in-100 day: A below {SA * a01:.3f}%, B below {SB * a01:.3f}%")
g1, g2, c01 = gauss(a01, a01, RHO), gauss_angle(a01, RHO), clayton(0.01, 0.01)
assert abs(g1 - g2) < 1e-9 * g1                  # two unrelated integrals agree
d = 2 * 0.01 ** -2 - 1                            # the Clayton value by hand
print(f"by hand: 0.01^-2 = {0.01 ** -2:.0f}, doubled minus 1 = {d:.0f}, root {math.sqrt(d):.3f}, C = {1 / math.sqrt(d):.6f}")
print(f"both crash, p=0.01: independent {0.01 * 0.01:.6f}  gaussian {g1:.6f} (angle road {g2:.6f})  clayton {c01:.6f}")

N = 400000                                        # three seeded simulations
rng = Rng(20260928)
S = math.sqrt(1.0 - RHO * RHO)
kg = kc = kd = kc2 = kd2 = 0                      # kc2, kd2: both ranks below 0.5
for _ in range(N):
    z1, z2 = rng.normal(), rng.normal()           # Gaussian copula: correlated scores
    if z1 <= a01 and RHO * z1 + S * z2 <= a01: kg += 1
    z = rng.normal(); w = z * z / 2.0             # Clayton by a shared calm level W ~ Gamma(1/2)
    e1, e2 = -math.log(rng.u()), -math.log(rng.u())
    uc, vc = (1 + e1 / w) ** (-1 / TH), (1 + e2 / w) ** (-1 / TH)
    kc += uc <= 0.01 and vc <= 0.01; kc2 += uc <= 0.5 and vc <= 0.5
    u, t = rng.u(), rng.u()                       # Clayton by conditional inversion
    v = (u ** -TH * (t ** (-TH / (1 + TH)) - 1.0) + 1.0) ** (-1 / TH)
    kd += u <= 0.01 and v <= 0.01; kd2 += u <= 0.5 and v <= 0.5
for lab, k, exact in (("gaussian", kg, g1), ("clayton, shared calm", kc, c01), ("clayton, inversion", kd, c01),
                      ("clayton 0.5, shared calm", kc2, clayton(0.5, 0.5)), ("clayton 0.5, inversion", kd2, clayton(0.5, 0.5))):
    est, se = k / N, math.sqrt(k / N * (1 - k / N) / N)
    assert abs(est - exact) < 4 * se
    print(f"simulated {lab:24s} {est:.6f} +/- {se:.6f}  exact {exact:.6f}")

print("given A has its worst 1-in-N day, chance B does too (percent):")
print("  worst day     independent   gaussian    clayton")
for p in (0.1, 0.05, 0.01, 0.001, 0.0001):
    q = Phi_inv(p)
    cg, cc = gauss(q, q, RHO) / p, clayton(p, p) / p
    print(f"  1 in {round(1 / p):<6d} {100 * p:9.2f} {100 * cg:10.2f} {100 * cc:10.2f}")
lam = clayton(1e-6, 1e-6) / 1e-6
assert abs(lam - 2 ** (-1 / TH)) < 1e-6          # formula's limit vs 2^(-1/theta)
q6 = Phi_inv(1e-6)
assert abs(q6 - -4.753424308822899) < 1e-10      # published 1-in-a-million quantile: tests the tail fraction
print(f"at p=1e-6: clayton {lam:.6f} (limit 2^(-1/theta) {2 ** (-1 / TH):.6f}), gaussian {gauss(q6, q6, RHO) / 1e-6:.6f} (limit 0)")
up = (1 - 2 * 0.99 + clayton(0.99, 0.99)) / 0.01
print(f"clayton upper tail, B in its best 1% given A is: {100 * up:.2f} percent")

n = 4000                                          # sixteen years of days from the Clayton world
rng = Rng(7)
xa, xb = [], []
for _ in range(n):
    z = rng.normal(); w = z * z / 2.0
    e1, e2 = -math.log(rng.u()), -math.log(rng.u())
    xa.append(SA * Phi_inv((1 + e1 / w) ** (-1 / TH)))
    xb.append(SB * Phi_inv((1 + e2 / w) ** (-1 / TH)))
ra, rb = [0] * n, [0] * n                         # ranks 1..n, lowest return = 1
for r, i in enumerate(sorted(range(n), key=lambda i: xa[i])): ra[i] = r + 1
for r, i in enumerate(sorted(range(n), key=lambda i: xb[i])): rb[i] = r + 1
conc = sum(1 if (ra[i] - ra[j]) * (rb[i] - rb[j]) > 0 else -1 for i in range(n) for j in range(i))
tau_hat = conc / (n * (n - 1) / 2)
assert abs(tau_hat - TAU) < 0.03                  # Clayton's tau = theta/(theta+2), met by data
sc = [Phi_inv(r / (n + 1)) for r in range(1, n + 1)]   # normal scores of the ranks
sa, sb = [sc[r - 1] for r in ra], [sc[r - 1] for r in rb]
rho_ns = sum(p * q for p, q in zip(sa, sb)) / sum(p * p for p in sa)
rho_tau = math.sin(math.pi * tau_hat / 2)
print(f"from ranks: tau-hat {tau_hat:.4f}, rho by tau {rho_tau:.4f}, rho by normal scores {rho_ns:.4f}")
m = n // 100; k = sum(1 for i in range(n) if ra[i] <= m and rb[i] <= m)
pred = gauss(a01, a01, rho_tau) / 0.01
print(f"worst {m} days of each: both on the same day {k} times ({100 * k / m:.1f}% +/- {100 * math.sqrt(k / m * (1 - k / m) / m):.1f});"
      f" fitted gaussian copula expects {m * pred:.1f} ({100 * pred:.1f}%)")
fa, fb = Phi(-2.0 / SA), Phi(-2.4 / SB)        # Sklar: H(x, y) = C(F(x), G(y))
h = clayton(fa, fb)
print(f"sklar by hand: F^-2 = {fa ** -TH:.1f}, G^-2 = {fb ** -TH:.1f}, sum minus 1 = {fa ** -TH + fb ** -TH - 1:.1f}")
k2 = sum(1 for i in range(n) if xa[i] <= -2.0 and xb[i] <= -2.4); se2 = math.sqrt(h * (1 - h) / n)
assert abs(k2 / n - h) < 4 * se2
print(f"sklar: F(-2%) {fa:.6f}, G(-2.4%) {fb:.6f}, C(F, G) {h:.6f}; days with both {k2}/{n} = {k2 / n:.6f}"
      f" +/- {se2:.6f}; gaussian copula {gauss(-2.0 / SA, -2.4 / SB, RHO):.6f}")
def patch(u, v): return sum(max(0.0, min(1.0, 2 * u - i, 2 * v - j)) for i in (0, 1) for j in (0, 1)) / 4
assert max(max(abs(patch(i / 20, 1.0) - i / 20), abs(patch(1.0, i / 20) - i / 20)) for i in range(21)) < 1e-12
assert min(patch((i + 1) / 20, (j + 1) / 20) - patch((i + 1) / 20, j / 20) - patch(i / 20, (j + 1) / 20) + patch(i / 20, j / 20)
           for i in range(20) for j in range(20)) > -1e-12   # patchwork: uniform margins, no negative rectangle, a copula
def H(x, y): return sum(0.25 for a in (0, 1) for b in (0, 1) if a <= x and b <= y)   # two fair coins, F(0) = 0.5, F(1) = 1
assert all(abs(cop((x + 1) / 2, (y + 1) / 2) - H(x, y)) < 1e-12 for cop in (lambda u, v: u * v, patch) for x in (0, 1) for y in (0, 1))
coin = sum(0.5 for x in (0, 1) if (x + 1) / 2 <= 0.25)
print(f"coin tosses: P(F(X) <= 0.25) = {coin:.2f}, not 0.25; copulas uv and patchwork (min(u,v)/2 near 0) give"
      f" C(0.5,0.5) = {0.5 * 0.5:.4f} = {patch(0.5, 0.5):.4f}, but at (0.25,0.25) {0.25 * 0.25:.4f} vs {patch(0.25, 0.25):.4f}")
print("ALL CHECKS PASS")
