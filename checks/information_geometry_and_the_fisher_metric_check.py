# Fisher metric: a family of models as a curved space.  Standard library only.
# Coin family: distance three ways, then exact error rates.  Normal family:
# Fisher matrix four ways, curvature, Fisher-Rao distance, natural-gradient steps.
from math import sqrt, log, exp, asin, acosh, atan2, cos, sin, pi

def simpson(f, a, b, n=2000):                         # n even; a plain loop, so Rust adds in the same order
    h, tot = (b - a) / n, 0.0
    for i in range(n + 1): tot += (1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h)
    return h / 3 * tot

# ---- coins: ds^2 = dp^2 / (p(1-p)) per flip ----
def d_arc(p0, p1): return 2 * abs(asin(sqrt(p1)) - asin(sqrt(p0)))      # chart phi = asin(sqrt p)
def d_p(p0, p1): return simpson(lambda p: 1 / sqrt(p * (1 - p)), p0, p1)  # chart p
def d_logodds(p0, p1):                                                  # chart eta = ln(p/(1-p))
    e = lambda p: log(p / (1 - p))
    return simpson(lambda t: sqrt(exp(t)) / (1 + exp(t)), e(p0), e(p1))
def exact_error(p0, p1, n):                    # best rule: pick the model with higher likelihood
    lf = [0.0] * (n + 1)
    for k in range(1, n + 1): lf[k] = lf[k - 1] + log(k)
    e = 0.0
    for k in range(n + 1):
        c = lf[n] - lf[k] - lf[n - k]
        l0, l1 = c + k * log(p0) + (n - k) * log(1 - p0), c + k * log(p1) + (n - k) * log(1 - p1)
        e += exp(l0) if l1 > l0 else exp(l1)
    return e / 2
Phi = lambda x: simpson(lambda z: exp(-z * z / 2) / sqrt(2 * pi), -12, x)   # bell-curve area left of x
flips = {}
for p0, p1 in ((0.50, 0.51), (0.98, 0.99)):
    a, b, c = d_arc(p0, p1), d_p(p0, p1), d_logodds(p0, p1)
    n = round((3 / a) ** 2); flips[p0] = n
    kl = p0 * log(p0 / p1) + (1 - p0) * log((1 - p0) / (1 - p1))
    print(f"coin {p0:.2f} vs {p1:.2f}: distance arcsin {a:.6f} | p-chart {b:.6f} | log-odds chart {c:.6f}")
    print(f"  flips for 3 standard errors {n} | exact error {exact_error(p0, p1, n):.6f} | KL {kl:.6f} | d^2/2 {a * a / 2:.6f}")
    assert abs(a - b) < 1e-6 and abs(a - c) < 1e-6
print(f"normal approximation of that error Phi(-1.5) = {Phi(-1.5):.6f} | whole coin family length {d_arc(0, 1):.6f}")
assert all(abs(exact_error(p0, p1, flips[p0]) - Phi(-1.5)) < 0.002 for p0, p1 in ((0.50, 0.51), (0.98, 0.99)))
print(f"ratios, 0.98 pair over 0.50 pair: distance {d_arc(0.98, 0.99) / d_arc(0.50, 0.51):.2f} | flips {flips[0.50] / flips[0.98]:.1f}")
print("chart flips: " + ", ".join(f"{p:.2f}:{(3 / d_arc(p, p + 0.01)) ** 2:.0f}" for p in (0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.98)))

# ---- normal family N(mu, sigma^2): coin weights in grams ----
m, s = 5.670, 0.020                                   # batch mean and standard deviation (divide by n)
mu0, sg0 = 5.600, 0.050                               # starting guess
def L(mu, sg): return -log(sg) - (s * s + (m - mu) ** 2) / (2 * sg * sg) - 0.5 * log(2 * pi)
def grad(mu, sg, u=1.0):                              # u = 1000 when every length is in milligrams
    v = (s * u) ** 2 + (m * u - mu) ** 2
    return (m * u - mu) / sg ** 2, -1 / sg + v / sg ** 3
def g(mu, sg): return 1 / sg ** 2, 2 / sg ** 2       # Fisher matrix diag(g_11, g_22), g_12 = 0
def score(x, mu, sg): z = (x - mu) / sg; return z / sg, (z * z - 1) / sg
dens = lambda z: exp(-z * z / 2) / sqrt(2 * pi)
quad = [simpson(lambda z: f(score(mu0 + sg0 * z, mu0, sg0)) * dens(z), -12, 12)
        for f in (lambda t: t[0] ** 2, lambda t: t[1] ** 2, lambda t: t[0] * t[1])]
state = 20261119                                      # SplitMix64 for the simulation road
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
N, mc = 200000, [0.0, 0.0, 0.0]
for _ in range(N // 2):
    r, t = sqrt(-2 * log(1 - u01())), 2 * pi * u01()
    for z in (r * cos(t), r * sin(t)):
        a, b = score(mu0 + sg0 * z, mu0, sg0); mc[0] += a * a / N; mc[1] += b * b / N; mc[2] += a * b / N
def kl(m1, s1, m2, s2): return log(s2 / s1) + (s1 * s1 + (m1 - m2) ** 2) / (2 * s2 * s2) - 0.5
h = 1e-4
klg = ((kl(mu0, sg0, mu0 + h, sg0) + kl(mu0, sg0, mu0 - h, sg0)) / h ** 2,
       (kl(mu0, sg0, mu0, sg0 + h) + kl(mu0, sg0, mu0, sg0 - h)) / h ** 2)
G = g(mu0, sg0)
print(f"Fisher at (5.600, 0.050): formula {G[0]:.4f} {G[1]:.4f} 0 | quadrature {quad[0]:.4f} {quad[1]:.4f} {abs(quad[2]):.4f}")
print(f"  simulated {mc[0]:.1f} {mc[1]:.1f} {mc[2]:.1f} | KL both sides / h^2 {klg[0]:.2f} {klg[1]:.2f}")
assert abs(quad[0] - G[0]) < 1e-6 and abs(quad[1] - G[1]) < 1e-6 and abs(quad[2]) < 1e-9
assert abs(mc[0] - G[0]) < 5 * G[0] * sqrt(2 / N) and abs(mc[1] - G[1]) < 5 * G[1] * sqrt(8 / N)
assert abs(klg[0] - G[0]) < 0.1 and abs(klg[1] - G[1]) < 0.5
def K(mu, sg, r):                                        # Brioschi with F = 0, every slope numerical
    E, Gf = (lambda y: g(mu, y)[0]), (lambda y: g(mu, y)[1]); e = sg * r
    f = lambda y: (E(y + e) - E(y - e)) / (2 * e) / sqrt(E(y) * Gf(y))   # E_sigma / sqrt(EG); G_mu = 0
    return -(f(sg + e) - f(sg - e)) / (2 * e) / (2 * sqrt(E(sg) * Gf(sg)))
print(f"curvature K, slope steps 1% and 0.1% of sigma: start {K(mu0, sg0, 1e-2):.6f} {K(mu0, sg0, 1e-3):.6f} | fit {K(m, s, 1e-2):.6f} {K(m, s, 1e-3):.6f}")
assert abs(K(mu0, sg0, 1e-3) + 0.5) < 1e-5 and abs(K(m, s, 1e-3) + 0.5) < 1e-5

def d_closed(m1, s1, m2, s2): return sqrt(2) * acosh(1 + ((m1 - m2) ** 2 / 2 + (s1 - s2) ** 2) / (2 * s1 * s2))
def length(path, n):                                  # Fisher length of a path t -> (mu, sigma), t in [0, 1]
    def ds(t):
        e = 1e-6; (a1, b1), (a2, b2) = path(t - e), path(t + e)
        return sqrt((a2 - a1) ** 2 + 2 * (b2 - b1) ** 2) / (2 * e) / path(t)[1]
    return simpson(ds, 0.0, 1.0, n)                   # Simpson's rule with n steps
x1, x2 = mu0 / sqrt(2), m / sqrt(2)                   # geodesic: half circle in (mu/sqrt2, sigma)
c = (x2 ** 2 + s ** 2 - x1 ** 2 - sg0 ** 2) / (2 * (x2 - x1)); R = sqrt((x1 - c) ** 2 + sg0 ** 2)
t1, t2 = atan2(sg0, x1 - c), atan2(s, x2 - c)
arc = lambda t: (sqrt(2) * (c + R * cos(t1 + (t2 - t1) * t)), R * sin(t1 + (t2 - t1) * t))
line = lambda t: (mu0 + (m - mu0) * t, sg0 + (s - sg0) * t)
dc, da, db, dl, dm = d_closed(mu0, sg0, m, s), length(arc, 20), length(arc, 40), length(line, 20), length(line, 40)
lc = sqrt((m - mu0) ** 2 + 2 * (s - sg0) ** 2) / (sg0 - s) * log(sg0 / s)   # straight line, closed form
print(f"Fisher-Rao distance start to fit: closed form {dc:.6f} | along geodesic, 20 and 40 steps {da:.6f} {db:.6f}")
print(f"  straight line: 20 and 40 steps {dl:.6f} {dm:.6f} | closed form {lc:.6f}")
assert abs(dc - db) < 1e-5 and abs(dc - db) < abs(dc - da) / 8 and abs(dm - lc) < 1e-6 and lc > dc  # halving the step

gm, gs = grad(mu0, sg0)
nat = (gm / G[0], gs / G[1])                           # natural gradient g^ij dL/dtheta^j
best = max(range(36000), key=lambda k: gm * cos(k * pi / 18000) / sqrt(G[0]) + gs * sin(k * pi / 18000) / sqrt(G[1]))
th = best * pi / 18000; dirn = (cos(th) / sqrt(G[0]), sin(th) / sqrt(G[1]))  # best unit-Fisher-length step
print(f"gradient {gm:.4f} {gs:.4f} | natural step {nat[0]:.6f} {nat[1]:.6f} | slope ratio formula {nat[1] / nat[0]:.4f}, search {dirn[1] / dirn[0]:.4f}")
assert abs(nat[1] / nat[0] - dirn[1] / dirn[0]) < 1e-3
def natural(mu, sg, eta=1.0, u=1.0):
    a, b = grad(mu, sg, u); A, B = g(mu, sg); return mu + eta * a / A, sg + eta * b / B
def plain(mu, sg, eta, u=1.0):
    a, b = grad(mu, sg, u); return mu + eta * a, sg + eta * b
pn, pp = [(mu0, sg0)], [(mu0, sg0)]
for k in range(30): pn.append(natural(*pn[-1])); pp.append(plain(*pp[-1], 0.0002))
for k in range(7): print(f"natural step {k}: mu {pn[k][0]:.6f} sigma {pn[k][1]:.6f} avg log-lik {L(*pn[k]):.6f}")
print("chart natural: " + ", ".join(f"{L(*q):.3f}" for q in pn[:11]))
print("chart plain:   " + ", ".join(f"{L(*q):.3f}" for q in pp[:11]))
close = lambda q: abs(q[0] - m) < 1e-4 and abs(q[1] - s) < 1e-4
first = lambda qs: next(k for k, q in enumerate(qs) if close(q))
q4 = [(mu0, sg0)]
for k in range(31): q4.append(plain(*q4[-1], 0.0004))
print(f"steps to within 0.0001 g: natural {first(pn)} | plain eta 0.0002 {first(pp)} | plain eta 0.0004 sigma at 30, 31: {q4[30][1]:.6f} {q4[31][1]:.6f}")
assert first(pn) == 5 and first(pp) > 20 and abs(pn[1][0] - m) < 1e-12

# ---- what breaks ----
mg = plain(mu0 * 1000, sg0 * 1000, 0.0002, 1000)            # same eta, coordinates in milligrams
nmg = natural(mu0 * 1000, sg0 * 1000, 1.0, 1000)
one = sg0 + gs * sg0 ** 2                             # Fisher entry for sigma taken as 1/sigma^2
tau = log(sg0) + sg0 * gs / 2                          # natural step in chart (mu, ln sigma): g = diag(1/sigma^2, 2)
small = (sg0 + 0.01 * gs / G[1], exp(log(sg0) + 0.01 * sg0 * gs / 2))
print(f"plain step in g {pp[1][0] - mu0:.6f} | same eta in mg, back in g {(mg[0] - mu0 * 1000) / 1000:.10f} | natural in mg, back in g {(nmg[0] - mu0 * 1000) / 1000:.6f}")
print(f"sigma after one step: right {pn[1][1]:.6f} | missing the 2 {one:.6f} | chart ln sigma {exp(tau):.6f} | eta 0.01 both charts {small[0]:.7f} {small[1]:.7f}")
assert abs((nmg[0] - mu0 * 1000) / 1000 - nat[0]) < 1e-9 and abs(small[0] - small[1]) < 1e-6 < abs(exp(tau) - pn[1][1])

# ---- try changing ----
nh = [(mu0, sg0)]
for k in range(30): nh.append(natural(*nh[-1], 0.5))
nw = [(mu0, 0.010)]
for k in range(30): nw.append(natural(*nw[-1]))
print(f"try: 0.50 vs 0.51 at 4 standard errors {(4 / d_arc(0.50, 0.51)) ** 2:.0f} flips | natural eta 0.5 steps {first(nh)} | start sigma 0.010: step 1 sigma {nw[1][1]:.6f}, steps {first(nw)}")
print("ALL CHECKS PASS")
