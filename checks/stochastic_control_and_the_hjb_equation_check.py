# Stochastic control and the HJB equation -- the check behind the card.  Standard library only.
# How much of a $200,000 fortune to keep in shares over 5 years.  Four roads to the best fraction:
# the HJB formula, the HJB equation tested by finite differences, discrete Bellman steps that
# shrink, and a seeded Monte Carlo.  The generator, normals and searches are written out here.
from math import exp, log, sqrt, cos, pi as PI

X0, T, R, MU, SIG, GAM = 200000.0, 5.0, 0.03, 0.08, 0.25, 2.0

def g(p, gam=GAM):                       # certainty-equivalent growth per year of a fixed fraction p
    return R + p * (MU - R) - 0.5 * gam * SIG * SIG * p * p
def U(x):                                # power utility, risk aversion GAM
    return x ** (1.0 - GAM) / (1.0 - GAM)

# Road 1: the formula the HJB equation gives
p_star = (MU - R) / (GAM * SIG * SIG)
g_star = g(p_star)
ce_star = X0 * exp(g_star * T)
def V(t, x):                             # the value function found by solving HJB
    return U(x) * exp((1.0 - GAM) * g_star * (T - t))
print(f"setting: fortune {X0:.0f}, {T:.0f} years, bank {R}, shares drift {MU}, volatility {SIG}, risk aversion {GAM:.0f}")
print(f"road 1 formula: excess {MU - R:.6f}, variance {SIG * SIG:.6f}, risk aversion x variance {GAM * SIG * SIG:.6f}")
print(f"road 1 formula: best fraction            {p_star:.6f}")
print(f"road 1 formula: dollars in shares now    {p_star * X0:.2f}")
print(f"road 1 formula: CE growth per year       {g_star:.6f}")
print(f"road 1 formula: CE fortune at 5 years    {ce_star:.2f}")

# Road 2: put V into the HJB equation by finite differences; scan the fraction, no calculus
def bracket(t, x, p, ito=True):
    e, k = 1e-4, x * 1e-4
    vt = (V(t + e, x) - V(t - e, x)) / (2 * e)
    vx = (V(t, x + k) - V(t, x - k)) / (2 * k)
    vxx = (V(t, x + k) - 2 * V(t, x) + V(t, x - k)) / (k * k)
    b = x * (R + p * (MU - R)) * vx + (0.5 * x * x * p * p * SIG * SIG * vxx if ito else 0.0)
    return (vt + b) / abs(vt)            # HJB says: at most 0, and exactly 0 at the best p
for t, x in ((0.0, X0), (2.5, 100000.0)):
    best = max(range(0, 2001), key=lambda i: bracket(t, x, i / 1000))
    print(f"road 2 HJB test at t={t:.1f}, x={x:.0f}: best fraction {best / 1000:.4f}, residual {bracket(t, x, best / 1000):.6f}")
    if t == 0.0: scan_best, scan_res = best / 1000, bracket(t, x, best / 1000)

# Road 3: Bellman's rule on steps of h years, exact two-point shares, bisection on the slope
def bellman(h):
    up = exp((MU - 0.5 * SIG * SIG) * h + SIG * sqrt(h))
    dn = exp((MU - 0.5 * SIG * SIG) * h - SIG * sqrt(h))
    b = exp(R * h)
    def score(p):                        # expected utility of one step's growth factor
        return 0.5 * (U(b + p * (up - b)) + U(b + p * (dn - b)))
    def slope(p):                        # its derivative in p, falling through zero at the best p
        return 0.5 * ((up - b) * (b + p * (up - b)) ** -GAM + (dn - b) * (b + p * (dn - b)) ** -GAM)
    lo, hi = 0.0, 1.0
    for _ in range(100):
        m = 0.5 * (lo + hi)
        if slope(m) > 0: lo = m
        else: hi = m
    p = 0.5 * (lo + hi)
    m = score(p) * (1.0 - GAM)           # E[G^(1-GAM)] for the best step
    return p, log(m) / ((1.0 - GAM) * h)
print("road 3 Bellman steps: step in years, best fraction, its error, CE growth per year")
steps = []
for name, h in (("1", 1.0), ("1/2", 0.5), ("1/4", 0.25), ("1/12", 1 / 12), ("1/52", 1 / 52), ("1/252", 1 / 252)):
    p, gh = bellman(h)
    steps.append((p, gh))
    print(f"  {name:>6} {p:.6f} {p - p_star:+.6f} {gh:.6f}")

# Road 4: Monte Carlo with SplitMix64 and Box-Muller, written out
M64 = (1 << 64) - 1
state = 2026
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0
def normal():
    u1, u2 = unif(), unif()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
def ce_and_se(ys):                       # ys are X_T^(1-GAM); CE and its standard error
    n = len(ys); m = sum(ys) / n
    sd = sqrt(sum((y - m) ** 2 for y in ys) / (n - 1))
    ce = m ** (1.0 / (1.0 - GAM))
    return ce, ce * sd / sqrt(n) / (abs(1.0 - GAM) * m)
N = 100000
zs = [normal() for _ in range(N)]
print(f"road 4 Monte Carlo, fixed fractions, {N} paths, seed 2026: fraction, CE fortune, SE, exact")
mc = {}
for p in (0.2, 0.4, 0.8):
    drift = (R + p * (MU - R) - 0.5 * p * p * SIG * SIG) * T
    ys = [(X0 * exp(drift + p * SIG * sqrt(T) * z)) ** (1.0 - GAM) for z in zs]
    mc[p] = ce_and_se(ys)
    print(f"  {p:.1f} {mc[p][0]:10.2f} {mc[p][1]:7.2f} {X0 * exp(g(p) * T):10.2f}")
def run_rule(rule, n, months, rec=False):
    hm, out, path = 1.0 / 12, [], []
    for _ in range(n):
        x = X0
        for k in range(months):
            if rec and k % 6 == 0: path.append(x)
            p = rule(x)
            x *= exp((R + p * (MU - R) - 0.5 * p * p * SIG * SIG) * hm + p * SIG * sqrt(hm) * normal())
        out.append(x ** (1.0 - GAM))
        if rec: path.append(x)
    return out, path
print(f"road 4 fraction 0.4: simulated minus exact, in standard errors {(mc[0.4][0] - ce_star) / mc[0.4][1]:.2f}")
ce_fb, se_fb = ce_and_se(run_rule(lambda x: 0.6 if x < X0 else 0.2, 20000, 60)[0])
print(f"road 4 feedback rule, 0.6 below 200000 and 0.2 above, monthly, 20000 paths: CE {ce_fb:.2f}, SE {se_fb:.2f}")
print(f"road 4 feedback rule: shortfall from the best, in standard errors {(ce_star - ce_fb) / se_fb:.1f}")

# The hill, the mistakes, the other taste, one sample path
fr = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2]
print("hill, fraction in shares:     " + " ".join(f"{p:5.1f}" for p in fr))
print("hill, CE growth, % per year:  " + " ".join(f"{100 * g(p):5.2f}" for p in fr))
print("wrong: ordinary chain rule, residual at fraction 0.4, 1, 10, 100: "
      + " ".join(f"{bracket(0.0, X0, p, ito=False):.4f}" for p in (0.4, 1.0, 10.0, 100.0)))
print("right: Ito chain rule,     residual at fraction 0.4, 1, 10, 100: "
      + " ".join(f"{bracket(0.0, X0, p):.4f}" for p in (0.4, 1.0, 10.0, 100.0)))
p_s = (MU - R) / (GAM * SIG)
print(f"wrong: sigma for sigma^2: fraction {p_s:.4f}, CE fortune {X0 * exp(g(p_s) * T):.2f}")
p_1 = (MU - R) / (1.0 * SIG * SIG)
print(f"wrong: risk aversion 1 for 2: fraction {p_1:.4f}, CE fortune {X0 * exp(g(p_1) * T):.2f}")
print(f"all in the bank: CE fortune {X0 * exp(R * T):.2f}")
print(f"exponential taste, A = 0.00001 per dollar: dollars in shares now {(MU - R) * exp(-R * T) / (0.00001 * SIG * SIG):.2f}, at any fortune")
state = 7
path = run_rule(lambda x: p_star, 1, 60, rec=True)[1]
print("path, years:              " + " ".join(f"{k / 2:6.1f}" for k in range(11)))
print("path, fortune ($000):     " + " ".join(f"{x / 1000:6.2f}" for x in path))
print("path, in shares ($000):   " + " ".join(f"{p_star * x / 1000:6.2f}" for x in path))

assert abs(steps[-1][0] - p_star) < 1e-3          # shrinking Bellman steps reach the HJB fraction
assert abs(steps[-1][1] - g_star) < 1e-4          # and the HJB growth rate
assert abs(scan_best - p_star) < 1e-3              # the scan finds the HJB maximiser at p_star
assert abs(scan_res) < 1e-5                         # and V makes the HJB equation balance there
assert abs(mc[0.4][0] - ce_star) < 4 * mc[0.4][1] # simulation agrees with the formula
assert ce_fb + 3 * se_fb < ce_star                # a rule that reacts differently does worse
print("all checks passed")
