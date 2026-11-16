# Stable laws and heavy tails -- the check behind the card.
# Lighthouse: d = 1 km off a straight shore, flashes at a uniform random angle;
# a hit lands at x0 + d tan(angle): Cauchy errors, fingerprint exp(-d|t|).
# Roads: closed forms against defining integrals, series, inversion and simulation.
import math, cmath
D, N_HITS = 1.0, 100
def add(xs):                             # plain left-to-right sum, as in Rust
    total = 0.0
    for x in xs: total += x
    return total
def simpson(f, a, b, m):                 # m even; works for real or complex f
    h = (b - a) / m
    s = f(a) + f(b)
    for k in range(1, m):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3
def big_phi(x):                          # normal law, one series written out
    term, total, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= -x * x / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / math.sqrt(2 * math.pi)
state = 20261115                         # SplitMix64, seed 20261115
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def hit():                               # one lighthouse hit, error from x0 in km
    return D * math.tan(math.pi * (unif() - 0.5))
def gauss():                             # Box-Muller, one standard normal
    r = math.sqrt(-2 * math.log(1 - unif()))
    return r * math.cos(2 * math.pi * unif())
def semi_iqr(v):                         # half the width of the middle half
    v = sorted(v)
    return (v[3 * len(v) // 4] - v[len(v) // 4]) / 2
def median(v):
    v, m = sorted(v), len(v) // 2
    return v[m] if len(v) % 2 else (v[m - 1] + v[m]) / 2
lo, hi = 0.0, 3.0
for _ in range(100):                     # upper quartile of the bell by bisection
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if big_phi(mid) < 0.75 else (lo, mid)
MED_K = lo * math.pi / 2                 # median of n hits: half-width about MED_K d / sqrt(n)
# 1. Cauchy: fingerprint, stability, chances
cut = 1000.0                             # tail beyond cut: at most 2 g(cut) / t
by_int = 2 * simpson(lambda x: math.cos(x) / (math.pi * (1 + x * x)), 0.0, cut, 400000)
print(f"Cauchy, d = {D:.0f} km: fingerprint at t = 1 per km: closed form exp(-1) = {math.exp(-1):.6f}")
print(f"  defining integral to |x| = 1000: {by_int:.6f} (tail at most {4 / (math.pi * (1 + cut * cut)):.7f})")
lap = 2 * simpson(lambda x: math.cos(x) * 0.5 * math.exp(-x), 0.0, 40.0, 40000)
print(f"  duality: Laplace law's fingerprint at t = 1 is {lap:.6f} = 1/(1 + 1) = 0.5")
one = math.exp(-D / N_HITS)
print(f"mean of {N_HITS} hits at t = 1: exp(-1/{N_HITS}) = {one:.6f}; to the {N_HITS}th = {one ** N_HITS:.6f}")
print(f"  sum of {N_HITS} over sqrt({N_HITS}) at t = 1: exp(-sqrt({N_HITS})) = {math.exp(-math.sqrt(N_HITS)):.6f}")
for a in [1, 3]:
    print(f"  P(|mean error| > {a} km) = 1 - (2/pi) atan({a}) = {1 - 2 * math.atan(a / D) / math.pi:.6f}")
print(f"n, middle-half half-width (km) of 1000 means, of 1000 medians, large-n median {lo:.6f} pi/2/sqrt(n) = {MED_K:.6f}/sqrt(n)")
widths = {}
for n in [1, 10, 100, 1000]:
    means, meds, far = [], [], 0
    for r in range(1000):
        xs = [hit() for _ in range(n)]
        means.append(add(xs) / n)
        meds.append(median(xs))
        far += abs(means[-1]) > 1
    widths[n] = (semi_iqr(means), semi_iqr(meds))
    print(f"  {n:4d}  {widths[n][0]:.6f}  {widths[n][1]:.6f}  {MED_K * D / math.sqrt(n):.6f}  beyond 1 km: {far / 1000:.3f}")
# 2. Index above 2 is no law: invert exp(-|t|^3)
neg = simpson(lambda t: math.cos(4.5 * t) * math.exp(-t ** 3), 0.0, 6.0, 6000) / math.pi
pos = [simpson(lambda t: math.cos(4.5 * t) * math.exp(-t ** a), 0.0, 60.0, 60000) / math.pi for a in [2, 1]]
print(f"inverse of exp(-|t|^a) at x = 4.5: a = 3 {neg:.6f}; a = 2 {pos[0]:.6f}; a = 1 {pos[1]:.6f}")
print(f"die: variance 35/12 = {35 / 12:.6f} (finite), so dice totals over sqrt(n) go to the bell, index 2")
# 3. Levy waits: first time a 20 %-a-year Brownian log price climbs 0.1; c = (0.1/0.2)^2 years
C_L = (0.1 / 0.2) ** 2
med1 = C_L / lo ** 2
waits = [C_L / gauss() ** 2 for _ in range(40000)]
avgs = [add(waits[10 * k: 10 * k + 10]) / 10 for k in range(4000)]
fp = complex(add(math.cos(w) for w in waits), add(math.sin(w) for w in waits)) / 40000
fp_cf = cmath.exp(-math.sqrt(C_L) * (1 - 1j))
print(f"Levy, c = {C_L:.2f} years: median wait c/0.674490^2 = {med1:.4f} (simulated {median(waits):.4f})")
print(f"  average of 10 waits: median 10 x {med1:.4f} = {10 * med1:.4f} (simulated {median(avgs):.4f})")
print(f"  fingerprint at t = 1 per year: closed form {fp_cf.real:.4f} + {fp_cf.imag:.4f}i; simulated {fp.real:.4f} + {fp.imag:.4f}i")
# 4. The generalised limit theorem: Pareto fortunes, shape 1.5, cutoff $1 million, mean 3
A, MU, NF = 1.5, 3.0, 1000
CA = -math.sqrt(2 * math.pi) * (1 + 1j)  # integral of (e^(iu) - 1 - iu) 1.5 u^(-2.5), closed form
V = 30.0                                 # u = v^2; past v = 30 the rest is -1/V^3 - 3i/V, error <= 1/V^3
f_v = lambda v: 3 * (cmath.exp(1j * v * v) - 1 - 1j * v * v) / v ** 4 if v > 0 else -1.5   # the integrand in v
num = simpson(f_v, 0.0, V, 60000) + complex(-1 / V ** 3, -3 / V)
print(f"limit constant: closed form {CA.real:.6f} {CA.imag:+.6f}i; by integral {num.real:.6f} {num.imag:+.6f}i")
def phi_pareto(s):                       # exact series, s > 0
    total, k, term = 1 + 1j * s * MU + CA * s ** A, 2, -s * s / 2
    while abs(term) > 1e-18:
        total -= A * term / (k - A)
        k += 1
        term *= 1j * s / k
    return total
s0 = 0.1
direct = simpson(lambda x: cmath.exp(1j * s0 * x) * A * x ** (-A - 1), 1.0, 1000.0, 200000)
print(f"Pareto fingerprint at s = 0.1: series {phi_pareto(s0).real:.6f} {phi_pareto(s0).imag:+.6f}i; "
      f"integral to 1000 {direct.real:.6f} {direct.imag:+.6f}i")
limit = lambda t: cmath.exp(CA * t ** A)
def exact(t):                            # [e^(-i 3 s) phi(s)]^n, s = t / n^(2/3), via the log
    w = cmath.exp(-1j * MU * t / NF ** (1 / A)) * phi_pareto(t / NF ** (1 / A))
    return cmath.exp(NF * complex(math.log(abs(w)), math.atan2(w.imag, w.real)))
def exact2(t):                           # road 2: quadrature from 0 to s in place of the series; own centre A/(A-1)
    s, m = t / NF ** (2 / 3), A / (A - 1)
    return cmath.exp(NF * cmath.log(cmath.exp(-1j * m * s) * (1 + 1j * m * s + s ** A * (CA - simpson(f_v, 0.0, math.sqrt(s), 40)))))
def cdf(phi, z):                         # Gil-Pelaez, t = s^2, cut at s = 4
    return 0.5 - simpson(lambda s: 0.0 if s == 0 else 2 * (cmath.exp(-1j * s * s * z) * phi(s * s)).imag / s,
                         0.0, 4.0, 4000) / math.pi
zs_sim = []
for r in range(4000):
    zs_sim.append((add((1 - unif()) ** (-1 / A) for _ in range(NF)) - MU * NF) / NF ** (1 / A))
print(f"average of {NF} fortunes = 3 + Z/{NF ** (1 - 1 / A):.0f}; gamma = (2 pi)^(1/3) = {(2 * math.pi) ** (1 / 3):.6f}")
print(f"Z at most, average at most, P limit, P exact n = {NF}, P simulated (4000 runs)")
rows = {}
for z in [-1, 0, 2, 5]:
    rows[z] = (cdf(limit, z), cdf(exact, z), sum(x <= z for x in zs_sim) / 4000, cdf(exact2, z))
    print(f"  {z:2d}  {MU + z / 10:.1f}  {rows[z][0]:.4f}  {rows[z][1]:.4f}  {rows[z][2]:.4f}")
print(f"exact column again, by quadrature in place of the series: every gap below 1e-6: {'yes' if all(abs(r[3] - r[1]) < 1e-6 for r in rows.values()) else 'no'}")
print("chart n, means, medians")
print("  " + ", ".join(f"{widths[n][0]:.3f}" for n in widths) + " | " + ", ".join(f"{widths[n][1]:.3f}" for n in widths))
assert abs(by_int - math.exp(-1)) < 1e-5                       # closed form = defining integral
assert abs(lap - 0.5) < 1e-9                                   # duality road
assert all(abs(widths[n][0] - D) < 0.2 for n in widths)        # means never settle
assert abs(widths[1000][1] - MED_K * D / math.sqrt(1000)) < 0.01  # medians do
assert neg < -0.01                                             # index 3 is no law
assert min(pos) > 0                                            # indices 2 and 1 are laws
assert abs(pos[1] - 1 / (math.pi * (1 + 4.5 * 4.5))) < 1e-6     # index 1 inverts to Cauchy
assert abs(median(avgs) - 10 * med1) < 0.6                     # Levy: average n times wider
assert abs(fp - fp_cf) < 0.02
assert abs(num - CA) < 1e-4                                    # limit constant
assert abs(direct - phi_pareto(s0)) < 1e-5                     # series = defining integral
assert abs(rows[0][0] - 2 / 3) < 1e-6                          # P(Z <= 0) = 2/3 exactly
assert all(abs(rows[z][3] - rows[z][1]) < 1e-6 for z in rows)  # exact column: series road = quadrature road
assert all(abs(rows[z][1] - rows[z][2]) < 4 * math.sqrt(rows[z][1] * (1 - rows[z][1]) / 4000) for z in rows)
print("ALL CHECKS PASS")
