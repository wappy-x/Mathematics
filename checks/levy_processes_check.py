# Levy processes -- the check behind the card.  Only math is imported.
# A share's log price X_t (t in years) drifts, diffuses and jumps:
#   X_t = GAM t + SIG W_t + (jumps: 2 a year, -0.20 with chance 0.75, +0.20 with 0.25),
# and the price is S_t = 100 e^(X_t).  Roads to E[e^(iuX_t)]: the Levy-Khintchine
# exponent; an exact sum over the jump counts; the year cut into slots of length h;
# and 40000 simulated years from a SplitMix64 generator written out.
import math

GAM, SIG, LAM = 0.25, 0.20, 2.0
JUMPS = [(-0.20, 0.75), (0.20, 0.25)]           # (size, chance); nu puts LAM x chance on each size
U, SEED, YEARS, MASK = 3.0, 20260930, 40000, (1 << 64) - 1
NU = [(x, LAM * p) for x, p in JUMPS]
B = GAM + sum(x * m for x, m in NU if abs(x) < 1)  # the triplet's drift b
def psi(u):                                      # Levy-Khintchine exponent, (real, imaginary)
    return (-0.5 * SIG * SIG * u * u + sum(m * (math.cos(u * x) - 1) for x, m in NU),
            B * u + sum(m * (math.sin(u * x) - u * x) for x, m in NU))
def pois(k, mean): return math.exp(-mean + k * math.log(mean) - sum(math.log(j) for j in range(2, k + 1)))
def mixture(t, lam=LAM, top=40):                # (chance, mean of X_t) given each pair of jump counts
    (a, pa), (c, pc) = JUMPS
    return [(pois(n, lam * pa * t) * pois(k, lam * pc * t), GAM * t + a * n + c * k)
            for n in range(top) for k in range(top)]
def cf_exact(u, t, lam=LAM):                    # sum over counts of chance x normal cf
    re = im = 0.0
    for pr, m in mixture(t, lam):
        r = pr * math.exp(-0.5 * SIG * SIG * u * u * t)
        re, im = re + r * math.cos(u * m), im + r * math.sin(u * m)
    return re, im
def ncdf(x):                                    # normal CDF from its power series, no erf
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term, s, n = x, x, 0
    while abs(term) > 1e-17 * abs(s):
        n += 1
        term *= x * x / (2 * n + 1)
        s += term
    return 0.5 + s * math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)
def p_below(a, t=1.0): return sum(pr * ncdf((a - m) / (SIG * math.sqrt(t))) for pr, m in mixture(t))
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def uniform(self):                          # in (0, 1]
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (((z ^ (z >> 31)) >> 11) + 1) / 9007199254740992.0
    def normal(self):                           # Box-Muller, cosine half
        u, v = self.uniform(), self.uniform()
        return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v)
    def jumps(self, length):                    # jump sizes in a window, from exponential gaps
        out, clock = [], -math.log(self.uniform()) / LAM
        while clock < length:
            out.append(JUMPS[0][0] if self.uniform() <= JUMPS[0][1] else JUMPS[1][0])
            clock += -math.log(self.uniform()) / LAM
        return out
def simpson(f, a, b, n=4000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

pr_, pi_ = psi(U)
print(f"triplet: b {B:.4f} = gamma {GAM:.4f} + int x nu {B - GAM:.4f}; sigma^2 {SIG * SIG:.4f}, int x^2 nu {sum(x * x * m for x, m in NU):.4f}; nu = {NU[0][1]:.1f} at {NU[0][0]:.2f} and {NU[1][1]:.1f} at {NU[1][0]:.2f}")
print(f"psi({U:.0f}) = {pr_:.6f} + {pi_:.6f} i;  pieces: drift i {B * U:.6f}, Brownian {-0.5 * SIG**2 * U * U:.6f},"
      f" jumps {pr_ + 0.5 * SIG**2 * U * U:.6f} + {pi_ - B * U:.6f} i")
print(f"extremes at u = {U:.0f}: Brownian alone psi = {-0.5 * SIG**2 * U * U:.6f};"
      f" Poisson rate 2, size 1: psi = {LAM * (math.cos(U) - 1):.6f} + {LAM * math.sin(U):.6f} i")
for t in (0.5, 1.0, 2.0):
    fr, fi = math.exp(t * pr_) * math.cos(t * pi_), math.exp(t * pr_) * math.sin(t * pi_)
    er, ei = cf_exact(U, t)
    print(f"t = {t:.1f}: Levy-Khintchine cf {fr:.9f} + {fi:.9f} i; exact sum over counts {er:.9f} + {ei:.9f} i")
    assert math.hypot(fr - er, fi - ei) < 1e-12, "exponent and count sum must agree"
mean_x = sum(pr * m for pr, m in mixture(1.0))
var_x = sum(pr * ((m - mean_x) ** 2 + SIG * SIG) for pr, m in mixture(1.0))
print(f"X_1 from the exact law: mean {mean_x:.6f}, variance {var_x:.6f};"
      f" formula b = {B:.6f}, sigma^2 + int x^2 nu = {SIG**2 + sum(x * x * m for x, m in NU):.6f}")
assert abs(mean_x - B) < 1e-12, "mean of the exact law is b"
assert abs(var_x - SIG**2 - sum(x * x * m for x, m in NU)) < 1e-12, "variance is sigma^2 + int x^2 nu"
es_formula = 100 * math.exp(B + 0.5 * SIG**2 + sum(m * (math.exp(x) - 1 - x) for x, m in NU))
es_exact = sum(pr * 100 * math.exp(m + 0.5 * SIG**2) for pr, m in mixture(1.0))
print(f"E[S_1] = 100 e^(psi(-i)) = {es_formula:.6f}; exact law gives {es_exact:.6f}; 100 e^(E X_1) would say {100 * math.exp(mean_x):.6f}")
assert abs(es_formula - es_exact) < 1e-9
errs, (er, ei) = [], cf_exact(U, 1.0)
for n in (10, 100, 1000, 10000):                # slots of length h = 1/n, at most one jump each
    h = 1.0 / n
    jr = 1 - LAM * h + LAM * h * sum(p * math.cos(U * x) for x, p in JUMPS)
    ji = LAM * h * sum(p * math.sin(U * x) for x, p in JUMPS)
    mod = (math.exp(-0.5 * SIG**2 * U * U * h) * math.hypot(jr, ji)) ** n
    ang = n * (GAM * U * h + math.atan2(ji, jr))
    errs.append(math.hypot(mod * math.cos(ang) - er, mod * math.sin(ang) - ei))
    print(f"slots h = 1/{n:<5d}: cf {mod * math.cos(ang):.6f} + {mod * math.sin(ang):.6f} i, error {errs[-1]:.2e}")
assert errs[-1] < 1e-4 and 8 < errs[-2] / errs[-1] < 12, "slot error should fall tenfold"
g = SplitMix64(SEED)
xa, xb = [], []
for _ in range(YEARS):                          # each year as two independent half-years
    xa.append(GAM / 2 + SIG * math.sqrt(0.5) * g.normal() + sum(g.jumps(0.5)))
    xb.append(GAM / 2 + SIG * math.sqrt(0.5) * g.normal() + sum(g.jumps(0.5)))
x1 = [a + b for a, b in zip(xa, xb)]
def mse(v):                                      # sample mean and its standard error
    m = sum(v) / len(v); return m, math.sqrt(sum((y - m) ** 2 for y in v) / (len(v) - 1) / len(v))
(m1, se1), ma, mb = mse(x1), sum(xa) / YEARS, sum(xb) / YEARS
(v1, sev), (cr, sec), (ci, ses) = mse([(y - m1) ** 2 for y in x1]), mse([math.cos(U * y) for y in x1]), mse([math.sin(U * y) for y in x1])
(cov, secov), (va, seva) = mse([(a - ma) * (b - mb) for a, b in zip(xa, xb)]), mse([(a - ma) ** 2 for a in xa])
(pb, sepb), (es, sees) = mse([1.0 if y <= -0.5 else 0.0 for y in x1]), mse([100 * math.exp(y) for y in x1])
print(f"simulated {YEARS} years, seed {SEED}: mean {m1:.4f} se {se1:.4f}; variance {v1:.4f} se {sev:.4f}")
print(f"  cf at u = {U:.0f}: {cr:.4f} se {sec:.4f} + {ci:.4f} se {ses:.4f} i; E[S_1] {es:.2f} se {sees:.2f}")
print(f"  half-years: cov {cov:.5f} se {secov:.5f}; variance of first half {va:.4f} se {seva:.4f}, Levy says {var_x / 2:.4f}")
print(f"  P(X_1 <= -0.5): simulated {pb:.4f} se {sepb:.4f}; exact {p_below(-0.5):.4f}")
fr, fi = cf_exact(U, 1.0)
for est, true, se in ((m1, mean_x, se1), (v1, var_x, sev), (cr, fr, sec), (ci, fi, ses), (cov, 0.0, secov),
                      (va, var_x / 2, seva), (pb, p_below(-0.5), sepb), (es, es_exact, sees)):
    assert abs(est - true) < 4 * se, "simulation within 4 standard errors"
cuts = [-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6]; print("figure, bands of X_1 (below -0.6, then 0.2 wide, then above 0.6), percent:")
for lab, cdf in (("exact    ", p_below), ("simulated", lambda c: sum(1 for y in x1 if y <= c) / YEARS),
                 ("normal   ", lambda c: ncdf((c - mean_x) / math.sqrt(var_x)))):
    q = [cdf(c) for c in cuts]; bands = [q[0]] + [q[i + 1] - q[i] for i in range(6)] + [1 - q[6]]
    print(f"  {lab} " + ", ".join(f"{100 * v:.2f}" for v in bands))
    if lab == "simulated": print("  sim. se   " + ", ".join(f"{100 * math.sqrt(v * (1 - v) / (YEARS - 1)):.2f}" for v in bands))
gp, x, path, jl = SplitMix64(SEED + 6), 0.0, [100.0], []
for day in range(1, 251):                       # one sample year on a grid of 250 trading days
    js = gp.jumps(1 / 250)
    x += GAM / 250 + SIG * math.sqrt(1 / 250) * gp.normal() + sum(js)
    jl += [(day, j) for j in js]
    path.append(100 * math.exp(x))
print("figure, one sample year, price every 10 trading days: " + ", ".join(f"{path[d]:.2f}" for d in range(0, 251, 10)))
print("figure, its jumps (trading day, size): " + ", ".join(f"({d}, {j:+.2f})" for d, j in jl))
half = cf_exact(U, 0.5, lam=3.0)                # seasonal: 3 jumps a year for six months, then 1
print(f"breaks, seasonal rate: half-year mean {GAM / 2 + 1.5 * sum(x * p for x, p in JUMPS):.4f} against Levy {B / 2:.4f};"
      f" |cf(3)| at t = 0.5 {math.hypot(*half):.6f} against |cf at 1|^0.5 {math.hypot(fr, fi) ** 0.5:.6f}")
print(f"breaks, random slope X_t = {B:.2f} t + {math.sqrt(var_x):.4f} t Z: Var X_2 {4 * var_x:.4f} against Levy {2 * var_x:.4f};"
      f" jump variance from lam Var(J) {LAM * (sum(x * x * p for x, p in JUMPS) - sum(x * p for x, p in JUMPS) ** 2):.4f}, not {sum(x * x * m for x, m in NU):.4f}")
def tail(eps, comp):                            # int_eps^1 (e^(iux) - 1 [- iux]) x^-2.5 dx, with x = e^y
    re = simpson(lambda y: -2 * math.sin(U * math.exp(y) / 2) ** 2 * math.exp(-1.5 * y), math.log(eps), 0.0)
    f = lambda z: (-(z ** 3) / 6 + z ** 5 / 120 if z < 1e-2 else math.sin(z) - z) if comp else math.sin(z)
    return re, simpson(lambda y: f(U * math.exp(y)) * math.exp(-1.5 * y), math.log(eps), 0.0)
sre = sum((-1) ** k * U ** (2 * k) / (math.factorial(2 * k) * (2 * k - 1.5)) for k in range(1, 30))
sim_ = sum((-1) ** k * U ** (2 * k + 1) / (math.factorial(2 * k + 1) * (2 * k - 0.5)) for k in range(1, 30))
for eps in (1e-2, 1e-4, 1e-6, 1e-8):
    (r0, i0), (_, i1) = tail(eps, False), tail(eps, True)
    print(f"breaks, nu = x^-2.5 dx on (0,1), cut at {eps:.0e}: real {r0:.6f}; imaginary, raw {i0:.3f}, compensated {i1:.6f}")
    assert abs((i0 - i1) - 2 * U * (eps ** -0.5 - 1)) < 1e-6 * i0, "raw minus compensated is u int x^-1.5"
print(f"  series limit, no cut: real {sre:.6f}, compensated imaginary {sim_:.6f}")
assert abs(r0 - (sre + U * U * 1e-4)) < 1e-6, "real part: the cut at 1e-8 leaves out -u^2 eps^0.5 to leading order"
assert abs(i1 - sim_) < 1e-6, "compensated imaginary part converges to the series"
print("ALL CHECKS PASS")
