# Novikov's condition -- the check behind the card.  Standard library only.
# Three tilts theta_t for Girsanov, time in years, W_t a Brownian motion under P:
#   A  constant 0.15: the share drifting 8% a year, priced at 5%, volatility 20%
#   B  theta_t = c W_t, c = 1 per year: the tilt grows with the wander
#   C  theta_t = -Z_t: the tilt grows with the weight itself, so dZ = Z^2 dW
# Roads: closed forms; exact Gaussian determinants and an exact lattice walk on
# shrinking grids; seeded simulation (SplitMix64 + Box-Muller) with standard errors.
from math import sqrt, exp, log, cos, sin, cosh, sinh, pi

def erf(x):                                   # Taylor series, accurate for |x| <= 3
    term, total, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -x * x / n
        total += term / (2 * n + 1)
    return 2.0 / sqrt(pi) * total

class Rng:                                    # SplitMix64 uniforms, Box-Muller normals
    def __init__(self, seed): self.s, self.spare = seed, None
    def u(self):
        M = (1 << 64) - 1
        self.s = (self.s + 0x9E3779B97F4A7C15) & M
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def normal(self):
        if self.spare is not None:
            g, self.spare = self.spare, None
            return g
        r, a = sqrt(-2.0 * log(1.0 - self.u())), 2.0 * pi * self.u()
        self.spare = r * sin(a)
        return r * cos(a)

def mean_se(xs):                              # plain running sums (sum() compensates, Rust does not)
    s1 = s2 = 0.0
    for x in xs: s1, s2 = s1 + x, s2 + x * x
    m = s1 / len(xs)
    return m, sqrt((s2 / len(xs) - m * m) / len(xs))

def gauss(n, T, a, b):
    # E[exp(-a W_T^2 - b dt sum_{k=1..n} W_{k dt}^2)], dt = T/n, exactly: det(Tn + 2b dt^2 I + 2a dt e_n e_n)^(-1/2),
    # Tn = inverse covariance of the grid path times dt (diagonal 2,..,2,1, off-diagonal -1).  None = infinite.
    dt, d0, d1 = T / n, 1.0, 1.0
    for k in range(1, n + 1):
        dk = (2.0 if k < n else 1.0 + 2.0 * a * dt) + 2.0 * b * dt * dt
        d0, d1 = d1, dk * d1 - (d0 if k > 1 else 0.0)
        if d1 <= 0.0: return None
    return 1.0 / sqrt(d1)

def fmt(v): return "infinite" if v is None else f"{v:.6f}"

# ---- A: constant tilt, the shelf's share ----
mu, r, sig, T = 0.08, 0.05, 0.20, 1.0
th = (mu - r) / sig
rng = Rng(20260930)
zs = [exp(-th * sqrt(T) * g - 0.5 * th * th * T) for g in (rng.normal() for _ in range(100000))]
mA, sA = mean_se(zs)
print(f"A theta {th:.2f}   theta^2 {th * th:.4f}   half theta^2 T {0.5 * th * th * T:.5f}")
print(f"A Novikov E[exp(half int theta^2)] {exp(0.5 * th * th * T):.6f}   Q drift {mu - sig * th:.2f}")
print(f"A simulated E[Z_1], 100000 draws  {mA:.4f}  se {sA:.4f}")

# ---- B: theta_t = c W_t ----
c = 1.0
def novB(T): return 1.0 / sqrt(cos(c * T)) if c * T < pi / 2 else None
def ezB(T): return exp(0.5 * c * T) / sqrt(cosh(c * T) + sinh(c * T))   # Cameron-Martin, a = c/2, b = c^2/2
print(f"B Novikov horizon pi/(2c) {pi / (2 * c):.6f} years   cos(1) {cos(1.0):.6f}")
print("B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2")
for n in (25, 100, 400, 1600):
    nv, ez = gauss(n, 1.0, 0.0, -0.5 * c * c), exp(c) * gauss(n, 2.0, 0.5 * c, 0.5 * c * c)
    print(f"B {n:6d} {nv:12.6f} {nv - novB(1.0):+11.7f} {ez:12.6f} {ez - 1.0:+11.7f}   {fmt(gauss(n, 2.0, 0.0, -0.5 * c * c))}")
print(f"B formula Novikov T=1 {novB(1.0):.6f}   T=1.5 {fmt(novB(1.5))}   T=1.6 {fmt(novB(1.6))}   T=2 {fmt(novB(2.0))}")
tstar = next(k / 100 for k in range(1, 401) if gauss(1600, k / 100, 0.0, -0.5 * c * c) is None)
print(f"B grid n 1600, T in steps of 0.01: Novikov first infinite at T = {tstar:.2f}   formula pi/(2c) {pi / (2 * c):.6f}")
steps, T2 = 200, 2.0
dt, zs = T2 / steps, []
for _ in range(20000):
    w, s = 0.0, 0.0
    for _ in range(steps):
        w += sqrt(dt) * rng.normal()
        s += dt * w * w
    zs.append(exp(0.5 * c * T2 - 0.5 * c * w * w - 0.5 * c * c * s))
mB, sB = mean_se(zs)
print(f"B simulated E[Z_2], 200 steps, 20000 paths {mB:.4f}  se {sB:.4f}   same grid exact {exp(c) * gauss(steps, T2, 0.5 * c, 0.5 * c * c):.6f}")
print("chart, B T          " + " ".join(f"{t:6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))
print("chart, B Novikov    " + " ".join(f"{novB(t):6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))
print("chart, B E[Z_T]     " + " ".join(f"{ezB(t):6.2f}" for t in (0.25, 0.5, 0.75, 1.0, 1.25, 1.5)))

# ---- C: dZ = Z^2 dW, the weight that feeds its own tilt ----
R0 = 1.0                                       # start of R = 1/Z, so Z_0 = 1/R0; weights are Z/Z_0
def survC(T): return erf(R0 / sqrt(2.0 * T))    # chance a Brownian motion from R0 stays above 0 to T
def lattice(h, T):                             # walk of +-h every h^2 years from R0, absorbed at 0
    k0, n = round(R0 / h), round(T / (h * h))
    p = [0.0] * (k0 + n + 2)
    p[k0] = 1.0
    for _ in range(n):
        p = [0.0] + [0.5 * (p[j - 1] + p[j + 1]) for j in range(1, len(p) - 1)] + [0.0]
        p[0] = 0.0
    tot = 0.0
    for v in p[1:]: tot += v
    return tot
print(f"C deterministic part dy = y^3 dt from 1 blows up at t = {0.5:.2f} years")
print(f"C formula E[Z_1] = 2 Phi(R0) - 1 = {survC(1.0):.6f}   Phi(1) {0.5 * (1 + erf(1 / sqrt(2))):.6f}   leak {1 - survC(1.0):.6f}")
lat = []
for h in (0.1, 0.05, 0.025):
    lat.append(lattice(h, 1.0))
    print(f"C lattice h {h:5.3f}  survival {lat[-1]:.6f}  error {lat[-1] - survC(1.0):+.6f}")
zs = []
for _ in range(200000):                        # Z_1/Z_0 = R0/|(R0,0,0) + 3-d Brownian motion at time 1|
    g1, g2, g3 = rng.normal(), rng.normal(), rng.normal()
    zs.append(R0 / sqrt((R0 + g1) * (R0 + g1) + g2 * g2 + g3 * g3))
mC, sC = mean_se(zs)
print(f"C simulated E[Z_1] under P, 200000 paths {mC:.4f}  se {sC:.4f}")
for cap in (10, 100, 1000):
    lost = 1.0 - erf((R0 - 1.0 / cap) / sqrt(2.0))
    print(f"C cap {cap:5d}: mass on capped paths {lost:.6f}, their chance {lost / (cap * R0):.6f}")
tc = (0.25, 0.5, 1.0, 2.0, 4.0, 8.0)
print("chart, C T          " + " ".join(f"{t:6.2f}" for t in tc))
print("chart, C E[Z_T]     " + " ".join(f"{survC(t):6.2f}" for t in tc))
print("chart, A E[Z_T]     " + " ".join(f"{exp(-0.5 * th * th * t) * exp(0.5 * th * th * t):6.2f}" for t in tc))

assert abs(mA - 1.0) < 4 * sA, "A: constant tilt, weights average 1"
assert abs(gauss(1600, 1.0, 0.0, -0.5 * c * c) - novB(1.0)) < 1e-3, "B: grid determinant vs 1/sqrt(cos cT)"
assert (gauss(1600, 2.0, 0.0, -0.5 * c * c) is None) == (novB(2.0) is None), "B: both roads agree on Novikov at T = 2"
assert abs(tstar - pi / (2 * c)) < 0.01, "B: the grid road blows up within a step of pi/(2c)"
assert abs(exp(c) * gauss(1600, 2.0, 0.5 * c, 0.5 * c * c) - 1.0) < 1e-3, "B: E[Z_2] = 1 though Novikov fails"
assert abs(mB - exp(c) * gauss(steps, T2, 0.5 * c, 0.5 * c * c)) < 4 * sB, "B: simulation vs same-grid exact"
assert abs(lat[-1] - survC(1.0)) < 0.01 and abs(lat[-1] - survC(1.0)) < abs(lat[0] - survC(1.0)), "C: lattice -> formula"
assert abs(mC - survC(1.0)) < 4 * sC, "C: P-side simulation vs Q-side reflection formula"
assert 1.0 - mC > 20 * sC, "C: the leak is real"
print("ALL CHECKS PASS")
