# Forward market model: two compounded overnight forwards, terminal and spot measures -- the check.
# Standard library only.  The normal CDF, the random numbers and every integral are written here.
from math import exp, log, sqrt, cos, sin, pi

tau, T = 1.0, [0.0, 1.0, 2.0]            # two annual accrual periods: [0, 1] and [1, 2] years
R0, s, rho = [0.04, 0.045], [0.010, 0.009], 0.9   # forwards, normal vols, correlation
P = [1.0, 1 / 1.04, 1 / (1.04 * 1.045)]  # 1 + tau R_j(0) = P(0,T_j) / P(0,T_(j+1))
K, USD = R0[:], 1e6                      # at-the-money strikes; $1,000,000 notional
corr = lambda j, k: 1.0 if j == k else rho

inside = {"lin": lambda u: 1 - u, "flat": lambda u: 1.0, "fixed": lambda u: 0.0}   # u: share of period gone
def g(j, t, decay="lin"):                # decay of R_j's volatility; rate j accrues over T[j]..T[j+1]
    return 1.0 if t <= T[j] else 0.0 if t >= T[j + 1] else inside[decay]((t - T[j]) / tau)

def simpson(f, a, b, m=200):
    hh = (b - a) / m
    return hh / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * hh) for i in range(1, m)))

def vtime(j, decay="lin"):               # variance time: integral of g_j^2 up to the payment date
    return T[j] + tau * simpson(lambda u: inside[decay](u) ** 2, 0.0, 1.0)

def N(x, m=2000):                        # bell-curve area left of x, by Simpson's rule from 0
    return 0.5 + simpson(lambda u: exp(-0.5 * u * u) / sqrt(2 * pi), 0.0, x, m) if x else 0.5

def bachelier(j, v, k):                  # caplet on R_j paid at T_(j+1), normal variance s_j^2 v
    sd = s[j] * sqrt(v)
    if sd == 0: return tau * P[j + 1] * max(R0[j] - k, 0.0)
    d = (R0[j] - k) / sd
    return tau * P[j + 1] * ((R0[j] - k) * N(d) + sd * exp(-0.5 * d * d) / sqrt(2 * pi))

def cov(t):                              # instantaneous covariance of R_j and R_k per year at time t
    return [[corr(j, k) * s[j] * s[k] * g(j, t) * g(k, t) for k in (0, 1)] for j in (0, 1)]

def drift(j, t, R, rule, c=None):        # drift of R_j at time t (per year, or over a step if c is a step's covariance)
    a, c = [tau / (1 + tau * R[k]) for k in (0, 1)], c or cov(t)
    if rule == "T": return -sum(c[j][k] * a[k] for k in range(j + 1, 2))
    if rule == "S": return sum(c[j][k] * a[k] for k in range(0, j + 1))
    if rule == "X": return sum(c[j][k] * a[k] for k in range(0, j + 1) if not T[k] <= t < T[k + 1])
    return 0.0

def logbond(i, R):                       # ln P(t,T_i)/P(t,T_2): every bond rebuilt from the rates (extended after T_i)
    return sum(log(1 + tau * R[k]) for k in range(i, 2))
def bump(j, t, R, rule, e=1e-7):         # road 2: bump each rate, read ln(new unit / R_j's payment bond)
    num = 2 if rule == "T" else max(i for i in (0, 1, 2) if T[i] <= t)   # bank account B(t) = B(T_n) P(t,T_n)
    lr = lambda Rb: logbond(num, Rb) - logbond(j + 1, Rb)
    up = lambda k, d: [R[m] + d * (m == k) for m in (0, 1)]
    return sum(cov(t)[j][k] * (lr(up(k, e)) - lr(up(k, -e))) / (2 * e) for k in (0, 1))

h, steps = 0.1, 20                       # exact noise and covariance per step; curve frozen at its start
C = []
for n in range(steps):
    t0, t1 = n * h, (n + 1) * h
    c = [[corr(j, k) * s[j] * s[k] * simpson(lambda t: g(j, t) * g(k, t), t0, t1, 2) for k in (0, 1)] for j in (0, 1)]
    l0 = sqrt(c[0][0]); l1 = c[1][0] / l0 if l0 else 0.0
    C.append((t0, c, l0, l1, sqrt(max(c[1][1] - l1 * l1, 0.0))))

state = 20261123                         # xorshift64* random numbers, Box-Muller normals
def unif():
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) * 2.0 ** -53 + 2.0 ** -54
def normals():
    r, t = sqrt(-2 * log(unif())), 2 * pi * unif()
    return (r * cos(t), r * sin(t))

def path(rule, zs, sg):
    R = R0[:]
    for (t0, c, l0, l1, l2), (z1, z2) in zip(C, zs):
        mu = [drift(0, t0, R, rule, c), drift(1, t0, R, rule, c)]
        R = [R[0] + mu[0] + l0 * sg * z1, R[1] + mu[1] + l1 * sg * z1 + l2 * sg * z2]
    G = [(1 + tau * R[0]), (1 + tau * R[1])]       # realised growth of $1 rolled overnight, per period
    c1, c2 = tau * max(R[0] - K[0], 0.0), tau * max(R[1] - K[1], 0.0)
    if rule in "TN": return [P[2] * c1 * G[1], P[2] * c2, G[0] * G[1], (R[1] - R0[1]) ** 2]
    return [c1 / G[0], c2 / (G[0] * G[1]), 1 / (G[0] * G[1]), 0.0]

rules, M = "TSNX", 30000                 # antithetic pairs, the same draws for every rule
tot = {r: [[0.0, 0.0] for _ in range(4)] for r in rules}
dif = {r: [[0.0, 0.0] for _ in range(2)] for r in rules}
for _ in range(M):
    zs, val = [normals() for _ in range(steps)], {}
    for r in rules:
        a, b = path(r, zs, 1), path(r, zs, -1)
        val[r] = [0.5 * (x + y) for x, y in zip(a, b)]
        for k in range(4): tot[r][k][0] += val[r][k]; tot[r][k][1] += val[r][k] ** 2
        base = val["T" if r in "TN" else "S"]
        for k in range(2): d = val[r][k] - base[k]; dif[r][k][0] += d; dif[r][k][1] += d * d
ms = lambda q: (q[0] / M, sqrt(max(q[1] / M - (q[0] / M) ** 2, 0.0) / M))

print("forward market model: compounded forwards on [0,1] and [1,2], annual accrual")
print(f"P(0,1) {P[1]:.6f}  P(0,2) {P[2]:.6f}  R_1(0) 4.0%  R_2(0) 4.5%  normal vols 1.0% 0.9%  rho 0.9")
vt = [vtime(j) for j in (0, 1)]
print(f"variance time, Simpson on g^2: R_1 {vt[0]:.6f}  R_2 {vt[1]:.6f}   rule T_s + tau/3: {T[0] + tau / 3:.6f} {T[1] + tau / 3:.6f}")
cf = [bachelier(j, vt[j], K[j]) for j in (0, 1)]
print(f"caplet sd: R_1 {s[0] * sqrt(vt[0]) * 100:.6f}%  R_2 {s[1] * sqrt(vt[1]) * 100:.6f}%  bell height at 0 {1 / sqrt(2 * pi):.6f}")
print(f"closed form, ATM, per $1m: caplet 1 {cf[0] * USD:.2f}  caplet 2 {cf[1] * USD:.2f}")
for name, dec in (("fixed at period start", "fixed"), ("flat to payment date", "flat")):
    v = [vtime(j, dec) for j in (0, 1)]
    print(f"  vol {name:<22} variance times {v[0]:.4f} {v[1]:.4f}  caplets {bachelier(0, v[0], K[0]) * USD:8.2f}"
          f" {bachelier(1, v[1], K[1]) * USD:8.2f}")
print(f"try: caplet 2 per $1m at K = 4% {bachelier(1, vt[1], 0.04) * USD:.2f}, at K = 5% {bachelier(1, vt[1], 0.05) * USD:.2f}")
print("drift at t = 0, today's curve, bp/yr        formula     bump road")
for lab, j, r in (("R_1 under terminal Q^T2", 0, "T"), ("R_2 under spot (bank account)", 1, "S"), ("R_1 under spot", 0, "S")):
    print(f"  {lab:<34} {drift(j, 0.0, R0, r) * 1e4:10.4f}  {bump(j, 0.0, R0, r) * 1e4:10.4f}")
print(f"  R_2 spot, accruing rate's term dropped {drift(1, 0.0, R0, 'X') * 1e4:.4f}")
a0, a1 = tau / (1 + tau * R0[0]), tau / (1 + tau * R0[1])
print(f"  R_2 spot terms: rho s_2 s_1 a_1 {rho * s[1] * s[0] * a0 * 1e4:.4f}  s_2^2 a_2 {s[1] ** 2 * a1 * 1e4:.4f}")
grid = [0.25 * i for i in range(9)]
print("chart, t        " + " ".join(f"{t:6.2f}" for t in grid))
print("chart, vol R_2  " + " ".join(f"{s[1] * g(1, t) * 1e4:6.1f}" for t in grid))
print("chart, LIBOR    " + " ".join(f"{s[1] * (t < T[1]) * 1e4:6.1f}" for t in grid))
print("chart, mu2 spot " + " ".join(f"{drift(1, t, R0, 'S') * 1e4 + 0.0:6.3f}" for t in grid))
print("chart, mu1 term " + " ".join(f"{drift(0, t, R0, 'T') * 1e4 + 0.0:6.3f}" for t in grid))
print(f"Monte Carlo, {2 * M} paths, {steps} steps of {h} years, per $1m      caplet 1        caplet 2")
names = {"T": "terminal Q^T2, drift", "S": "spot, drift", "N": "terminal, no drift", "X": "spot, accruing dropped"}
for r in rules:
    (m1, e1), (m2, e2) = ms(tot[r][0]), ms(tot[r][1])
    print(f"  {names[r]:<24} {m1 * USD:8.2f} se {e1 * USD:4.2f}  {m2 * USD:8.2f} se {e2 * USD:4.2f}")
for r in "NX":
    (d1, f1), (d2, f2) = ms(dif[r][0]), ms(dif[r][1])
    print(f"  {names[r]:<24} minus correct: {d1 * USD:+7.2f} se {f1 * USD:.2f}  {d2 * USD:+7.2f} se {f2 * USD:.2f}")
vm, ve = ms(tot["T"][3])
print(f"simulated variance time of R_2: {vm / s[1] ** 2:.4f}  se {ve / s[1] ** 2:.4f}  (one-third rule {T[1] + tau / 3:.4f})")
tg = {"T": 1 / P[2], "N": 1 / P[2], "S": P[2], "X": P[2]}
print("no-arbitrage test: terminal must average 1/P(0,2), spot must average P(0,2)")
for r in rules:
    m, e = ms(tot[r][2])
    print(f"  {names[r]:<24} {m:.7f} se {e:.7f}  target {tg[r]:.7f}  off by {(m - tg[r]) / e:+7.2f} se")

assert all(abs(vt[j] - (T[j] + tau / 3)) < 1e-12 for j in (0, 1)), "one-third rule vs Simpson"
assert all(abs(bump(j, t, R0, r) - drift(j, t, R0, r)) < 1e-12 for j in (0, 1) for t in grid for r in "TS"), "drift"
for r in "TS":
    for k in (0, 1): assert abs(ms(tot[r][k])[0] - cf[k]) < 3 * ms(tot[r][k])[1], "MC caplet vs closed form"
    assert abs(ms(tot[r][2])[0] - tg[r]) < 3 * ms(tot[r][2])[1], "numeraire ratio is a fair bet"
for r in "NX": assert abs(ms(tot[r][2])[0] - tg[r]) > 3 * ms(tot[r][2])[1], "wrong drift must fail the test"
assert abs(ms(dif["N"][0])[0]) > 3 * ms(dif["N"][0])[1], "dropping the drift must move caplet 1"
assert abs(vm / s[1] ** 2 - 4 / 3) < 3 * ve / s[1] ** 2, "simulated variance time"
print("ALL CHECKS PASS")
