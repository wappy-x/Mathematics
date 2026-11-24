# Extreme value theory -- the check behind the card.  Nothing imported holds the answer.
# Part 1: largest of n exponential waits minus ln n: exact formula, Gumbel limit, simulation.
# Part 2: max-stability of the three limits; the von Mises shape of three laws.
# Part 3: 30 yearly flood maxima simulated from a known GEV, fitted by maximum likelihood
#   (Nelder-Mead) and by a brute-force grid; the 100-year level by formula and by bisection.
import math

M64 = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.s = seed
    def u(self):  # SplitMix64 mapped into (0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0

def gev_cdf(z, mu, sg, xi):
    t = (z - mu) / sg; w = 1 + xi * t
    if abs(xi) < 1e-12: return math.exp(-math.exp(-t))
    if w <= 0: return 0.0 if xi > 0 else 1.0
    return math.exp(-w ** (-1 / xi))

def gev_level(p, mu, sg, xi):  # the level a year stays under with chance p
    y = -math.log(p)
    return mu - sg * math.log(y) if abs(xi) < 1e-12 else mu + sg * (y ** (-xi) - 1) / xi

def nll(x, mu, sg, xi):  # minus the log-likelihood of the GEV for the data x
    if sg <= 0: return math.inf
    s = len(x) * math.log(sg)
    for v in x:
        t = (v - mu) / sg
        if abs(xi) < 1e-12: s += t + math.exp(-t); continue
        w = 1 + xi * t
        if w <= 0: return math.inf
        s += (1 + 1 / xi) * math.log(w) + w ** (-1 / xi)
    return s

def nelder_mead(f, p0, steps, iters):
    d = len(p0)
    pts = [list(p0)] + [[p0[j] + (steps[j] if i == j else 0.0) for j in range(d)] for i in range(d)]
    val = [f(p) for p in pts]
    for _ in range(iters):
        idx = sorted(range(d + 1), key=lambda i: val[i])
        pts = [pts[i] for i in idx]; val = [val[i] for i in idx]
        c = [sum(pts[i][j] for i in range(d)) / d for j in range(d)]
        r = [c[j] + (c[j] - pts[d][j]) for j in range(d)]; fr = f(r)
        if fr < val[0]:
            e = [c[j] + 2 * (c[j] - pts[d][j]) for j in range(d)]; fe = f(e)
            pts[d], val[d] = (e, fe) if fe < fr else (r, fr)
        elif fr < val[d - 1]: pts[d], val[d] = r, fr
        else:
            k = [c[j] + 0.5 * (pts[d][j] - c[j]) for j in range(d)]; fk = f(k)
            if fk < val[d]: pts[d], val[d] = k, fk
            else:
                for i in range(1, d + 1):
                    pts[i] = [pts[0][j] + 0.5 * (pts[i][j] - pts[0][j]) for j in range(d)]; val[i] = f(pts[i])
    b = min(range(d + 1), key=lambda i: val[i])
    return pts[b], val[b]

# Part 1 -- the largest of n exponential waits
N, X = 365, 2.0
exact, gumbel = (1 - math.exp(-X) / N) ** N, math.exp(-math.exp(-X))
rng, T, hits = Rng(20261123), 20000, 0  # T simulated years of N daily waits
for _ in range(T):
    m = max(-math.log(rng.u()) for _ in range(N))
    hits += m - math.log(N) <= X
sim = hits / T; se = math.sqrt(sim * (1 - sim) / T)
print(f"ln 365 {math.log(N):.6f}  e^-2 {math.exp(-X):.6f}  e^-2/365 {math.exp(-X) / N:.9f}")
print(f"exp max n=365 x=2: exact {exact:.6f}  gumbel {gumbel:.6f}  sim {sim:.4f} (se {se:.4f})")
assert abs(exact - gumbel) < 1e-4 and abs(sim - exact) < 4 * se
for n in (3, 10, 100, 365, 10000): print(f"n={n:5d}: P(max - ln n <= 2) = {(1 - math.exp(-X) / n) ** n:.6f}")
xs = [i / 2 - 2 for i in range(15)]
print("chart x:", " ".join(f"{x:5.1f}" for x in xs))
for n in (3, 365): print(f"chart n={n:3d}:", " ".join(f"{max(0.0, 1 - math.exp(-x) / n) ** n:5.3f}" for x in xs))
print("chart gumbel:", " ".join(f"{math.exp(-math.exp(-x)):5.3f}" for x in xs))
print(f"no shift: P(max <= 2) = {(1 - math.exp(-X)) ** N:.3e}")
# Part 2 -- max-stability: G(x)^k equals G at a shifted or rescaled point
A, worst, h = 1.5, 0.0, 1e-4  # Pareto shape a = 1.5, as on the heavy-tails card
fr = lambda y: math.exp(-y ** -A) if y > 0 else 0.0  # Frechet, shape 1/A
wb = lambda y: math.exp(y) if y < 0 else 1.0  # reversed Weibull, ceiling 0
for k in (2, 10, 365):
    for x in (-1.0, 0.5, 2.0):
        g = gev_cdf(x, 0, 1, 0.0) ** k; worst = max(worst, abs(g - gev_cdf(x - math.log(k), 0, 1, 0.0)))
        worst = max(worst, abs(fr(x + 2) ** k - fr((x + 2) * k ** (-1 / A))))
        worst = max(worst, abs(wb(x - 3) ** k - wb((x - 3) * k)))
print(f"max-stability, largest gap over 27 tests: {worst:.1e}")
assert worst < 1e-12
par, uni = (1 - 2.0 ** -A / N) ** N, (1 - 1 / N) ** N
print(f"pareto a=1.5, P(max <= 2 n^(2/3)): {par:.4f}  frechet {math.exp(-2.0 ** -A):.4f}")
print(f"uniform, P(n(max - 1) <= -1): {uni:.4f}  weibull {math.exp(-1):.4f}")
assert abs(par - math.exp(-2.0 ** -A)) < 2e-3 and abs(uni - math.exp(-1)) < 1e-3
r = lambda sf, pdf, x: sf(x) / pdf(x)  # (1 - F)/f; its slope far out is the shape xi
for name, sf, pdf, x0, xi in (("exponential", lambda x: math.exp(-x), lambda x: math.exp(-x), 20.0, 0.0),
                              ("pareto 1.5", lambda x: x ** -A, lambda x: A * x ** (-A - 1), 50.0, 1 / A),
                              ("uniform", lambda x: 1 - x, lambda x: 1.0, 0.99, -1.0)):
    sl = (r(sf, pdf, x0 + h) - r(sf, pdf, x0 - h)) / (2 * h)
    print(f"von Mises slope, {name}: {sl:+.4f}"); assert abs(sl - xi) < 1e-6
# Part 3 -- 30 yearly flood maxima, cubic metres per second
MU, SG, XI, YEARS, g = 1000.0, 250.0, 0.1, 30, Rng(7)
data = [float(round(gev_level(g.u(), MU, SG, XI))) for _ in range(YEARS)]
print("flows:", " ".join(str(int(v)) for v in data))
mean = sum(data) / YEARS; sd = math.sqrt(sum((v - mean) ** 2 for v in data) / (YEARS - 1))
s0 = sd * math.sqrt(6) / math.pi; m0 = mean - 0.5772156649 * s0
print(f"mean {mean:.1f}  sd {sd:.1f}  largest {max(data):.0f}  start mu {m0:.1f} sigma {s0:.1f}")
f3 = lambda p: nll(data, p[0], p[1], p[2])
(mu, sg, xi), best = nelder_mead(f3, [m0, s0, 0.1], [50.0, 25.0, 0.1], 1500)
z100 = gev_level(0.99, mu, sg, xi)
print(f"ML fit: mu {mu:.1f}  sigma {sg:.1f}  xi {xi:.4f}  loglik {-best:.3f}")
dens = sum(-math.log((gev_cdf(v + 1e-3, mu, sg, xi) - gev_cdf(v - 1e-3, mu, sg, xi)) / 2e-3) for v in data)
print(f"log-likelihood from the slope of G: {-dens:.3f}"); assert abs(dens - best) < 1e-6
gb = (0.0, 0.0, 0.0, math.inf)
for i in range(61):
    for j in range(41):
        for k in range(51):
            v = nll(data, 700 + 10 * i, 100 + 10 * j, -0.4 + 0.02 * k)
            if v < gb[3]: gb = (700 + 10 * i, 100 + 10 * j, -0.4 + 0.02 * k, v)
print(f"grid fit ({61 * 41 * 51} points): mu {gb[0]}  sigma {gb[1]}  xi {gb[2]:.2f}  loglik {-gb[3]:.3f}")
assert best <= gb[3] and abs(gb[0] - mu) <= 10 and abs(gb[1] - sg) <= 10 and abs(gb[2] - xi) <= 0.02
bump = lambda q, e: [mu + e * (q == 0), sg + e * (q == 1), xi + e * (q == 2)]
gmax = max(abs(f3(bump(q, e)) - f3(bump(q, -e))) / (2 * e) for q, e in ((0, 0.01), (1, 0.01), (2, 1e-5)))
print(f"largest slope of the log-likelihood at the fit: {gmax:.4f}"); assert gmax < 0.01
lo, hi = mu, mu + 100 * sg
for _ in range(200):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if gev_cdf(mid, mu, sg, xi) < 0.99 else (lo, mid)
y1 = -math.log(0.99); print(f"by hand: mu {mu:.3f}  sigma {sg:.3f}  xi {xi:.6f}  y {y1:.6f}  y^-xi {y1 ** -xi:.6f}  sigma/xi {sg / xi:.1f}  rise {sg * (y1 ** -xi - 1) / xi:.3f}")
print(f"100-year level: formula {z100:.1f}  bisection {lo:.1f}  true {gev_level(0.99, MU, SG, XI):.1f}")
assert abs(lo - z100) < 1e-6
for T_ in (2, 5, 10, 20, 50, 100, 200, 500):
    print(f"return period {T_:3d} years: fitted {gev_level(1 - 1 / T_, mu, sg, xi):7.1f}  true {gev_level(1 - 1 / T_, MU, SG, XI):7.1f}")
(gm, gs), gbv = nelder_mead(lambda p: nll(data, p[0], p[1], 0.0), [m0, s0], [50.0, 25.0], 800)
print(f"gumbel fit (xi forced to 0): mu {gm:.1f}  sigma {gs:.1f}  100-year {gev_level(0.99, gm, gs, 0.0):.1f}  loglik {-gbv:.3f}")
assert -gbv <= -best
boot = []
for _ in range(200):
    y = [gev_level(g.u(), mu, sg, xi) for _ in range(YEARS)]
    (bm, bs, bx), _v = nelder_mead(lambda p: nll(y, p[0], p[1], p[2]), [mu, sg, xi], [50.0, 25.0, 0.1], 600)
    boot.append(gev_level(0.99, bm, bs, bx))
boot.sort(); print(f"bootstrap 90% range of the 100-year level: {boot[9]:.0f} to {boot[189]:.0f}")
print(f"chance of at least one 100-year flood: in 30 years {1 - 0.99 ** 30:.4f}, in 100 years {1 - 0.99 ** 100:.4f}")
print("ALL CHECKS PASS")
