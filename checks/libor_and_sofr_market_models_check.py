# Market models: ten forwards under the terminal measure -- the check behind the card.
# Standard library only.  The normal CDF, the random numbers and every sum are written here.
from math import exp, log, sqrt, cos, sin, pi

n, dl, T0 = 10, 0.5, 1.0               # ten half-year forwards; the first one resets at T0 = 1 year
L0 = [0.030 + 0.001 * i for i in range(n)]
V = [(0.20 - 0.005 * i, 0.08 + 0.003 * i) for i in range(n)]   # two-factor log volatilities
P = [exp(-0.03 * T0)]                  # P(0,T0); later bonds from 1 + dl L_i = P(T_i) / P(T_(i+1))
for L in L0: P.append(P[-1] / (1 + dl * L))
S0 = (P[0] - P[n]) / (dl * sum(P[1:]))  # today's 1y-into-5y swap rate: the swaption strike
dot = lambda x, y: x[0] * y[0] + x[1] * y[1]

def drift(L, rule):   # T terminal bond; F first bond; N none; S sign flipped; I own term included
    if rule == 'N': return [0.0] * n
    mu, s0, s1 = [0.0] * n, 0.0, 0.0
    for i in (range(n) if rule == 'F' else range(n - 1, -1, -1)):
        ai = dl * L[i] / (1 + dl * L[i])
        if rule in 'FI': s0 += ai * V[i][0]; s1 += ai * V[i][1]
        mu[i] = (1 if rule in 'FS' else -1) * (V[i][0] * s0 + V[i][1] * s1) + 0.0
        if rule in 'TS': s0 += ai * V[i][0]; s1 += ai * V[i][1]
    return mu

def step(L, rule, h, z, pc=True):      # log-Euler predictor, then trapezoid corrector on the drift
    kick = [sqrt(h) * dot(V[i], z) - 0.5 * dot(V[i], V[i]) * h for i in range(n)]
    m0 = drift(L, rule)
    Lp = [L[i] * exp(m0[i] * h + kick[i]) for i in range(n)]
    if not pc: return Lp
    m1 = drift(Lp, rule)
    return [L[i] * exp(0.5 * (m0[i] + m1[i]) * h + kick[i]) for i in range(n)]

def bump_drift(L, i, eps=1e-6):        # road 2: minus the covariance of log L_i with the log bond ratio
    def logD(k, e): return sum(log(1 + dl * L[j] * exp(e * V[j][k])) for j in range(i + 1, n))
    load = [(logD(k, eps) - logD(k, -eps)) / (2 * eps) for k in (0, 1)]
    return -dot(V[i], load) + 0.0

def N(x, m=2000):                      # bell-curve area left of x, by Simpson's rule from 0
    f = lambda u: exp(-0.5 * u * u) / sqrt(2 * pi)
    hh = x / m
    return 0.5 + hh / 3 * (f(0) + f(x) + sum((4 if k % 2 else 2) * f(k * hh) for k in range(1, m)))

state = 20260928                       # xorshift64* random numbers, Box-Muller normals
def unif():
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) * 2.0 ** -53 + 2.0 ** -54
def normals():
    r, t = sqrt(-2 * log(unif())), 2 * pi * unif()
    return (r * cos(t), r * sin(t))

def at_reset(L, rule):                 # caplet on L_0, swaption, bond ratio: in numeraire units at T0
    w, acc = [0.0] * n, 1.0
    for i in (range(n) if rule == 'F' else range(n - 1, -1, -1)):
        if rule == 'F': acc /= 1 + dl * L[i]; w[i] = acc
        else: w[i] = acc; acc *= 1 + dl * L[i]
    cap = dl * max(L[0] - 0.03, 0.0) * w[0]
    swp = max(sum(dl * (L[i] - S0) * w[i] for i in range(n)), 0.0)
    return (cap, swp, acc)

rules, M, steps = "TFNSI", 12000, 4    # antithetic pairs; four quarter-year steps to T0
tot = {r: [[0.0, 0.0] for _ in range(3)] for r in rules}
dif = {r: [0.0, 0.0] for r in rules}
for _ in range(M):
    zs = [normals() for _ in range(steps)]
    val = {}
    for r in rules:
        acc = [0.0, 0.0, 0.0]
        for sg in (1, -1):
            L = L0[:]
            for z in zs: L = step(L, r, T0 / steps, (sg * z[0], sg * z[1]))
            acc = [a + 0.5 * b for a, b in zip(acc, at_reset(L, r))]
        val[r] = [acc[0] * P[0 if r == 'F' else n], acc[1] * P[0 if r == 'F' else n], acc[2]]
        for k in range(3): tot[r][k][0] += val[r][k]; tot[r][k][1] += val[r][k] ** 2
        d = val[r][1] - val['T'][1]; dif[r][0] += d; dif[r][1] += d * d
ms = lambda s: (s[0] / M, sqrt(max(s[1] / M - (s[0] / M) ** 2, 0.0) / M))

print("market model: ten half-year forwards, first reset T0 = 1 year")
print(f"P(0,T0) {P[0]:.6f}  P(0,T10) {P[n]:.6f}  swap rate S0 {S0 * 100:.6f}%  annuity {dl * sum(P[1:]):.6f}")
print("  i  L_i(0) %   drift terminal %/yr   bump road %/yr   drift first bond %/yr")
muT, muF = drift(L0, 'T'), drift(L0, 'F')
bump = [bump_drift(L0, i) for i in range(n)]
for i in range(n):
    print(f"{i:>3} {L0[i] * 100:9.3f} {muT[i] * 100:21.4f} {bump[i] * 100:16.4f} {muF[i] * 100:23.4f}")
for r, mu in (("terminal", muT), ("first bond", muF)):
    print(f"chart, {r + ' drift bp/yr':<25}" + " ".join(f"{m * L * 1e4:5.2f}" for m, L in zip(mu, L0)))
print("drift of L_0, terms a_j sigma_0.sigma_j, %/yr: "
      + " ".join(f"{dl * L0[j] / (1 + dl * L0[j]) * dot(V[0], V[j]) * 100:.4f}" for j in range(1, n)))
hp, hc = step(L0, 'T', 0.25, (0.2, -0.4), False), step(L0, 'T', 0.25, (0.2, -0.4))
print(f"hand step, h = 0.25, z = (0.2, -0.4): sigma_0.dW {dot(V[0], (0.1, -0.2)):.6f}"
      f"  half variance x h {0.5 * dot(V[0], V[0]) * 0.25:.6f}")
print(f"  L_0 drift at start {muT[0] * 100:.6f}%/yr, on the predicted curve {drift(hp, 'T')[0] * 100:.6f}%/yr")
print(f"  log move of L_0: predicted {log(hp[0] / L0[0]):.8f}, corrected {log(hc[0] / L0[0]):.8f}")
print(f"  L_0 predicted {hp[0] * 100:.9f}%  corrected {hc[0] * 100:.9f}%;  L_9 both {hc[9] * 100:.9f}%")
print(f"try: L_0 drift %/yr, rates doubled {drift([2 * x for x in L0], 'T')[0] * 100:.4f}, rates halved "
      f"{drift([x / 2 for x in L0], 'T')[0] * 100:.4f}; no-shock step L_0 {step(L0, 'T', 0.25, (0.0, 0.0))[0] * 100:.6f}%")
vbar = sqrt(dot(V[0], V[0]))
d1 = (log(L0[0] / 0.03) + 0.5 * vbar ** 2 * T0) / (vbar * sqrt(T0))
black = dl * P[1] * (L0[0] * N(d1) - 0.03 * N(d1 - vbar * sqrt(T0)))
print(f"caplet on L_0, K = 3%, per $1m: Black-76 {black * 1e6:.2f}  (vol {vbar * 100:.4f}%, d1 {d1:.6f})")
for r, name in (("T", "terminal bond"), ("F", "first bond")):
    m, se = ms(tot[r][0])
    print(f"  Monte Carlo, {name:<13} {m * 1e6:9.2f}  se {se * 1e6:.2f}")
print(f"payer swaption 1y into 5y, K = S0, per $1m, {2 * M} paths, {steps} predictor-corrector steps:")
names = {"T": "terminal bond, drift", "F": "first bond, drift", "N": "terminal, no drift",
         "S": "terminal, sign flipped", "I": "terminal, own term in"}
for r in rules:
    m, se = ms(tot[r][1]); dm, dse = ms(dif[r])
    print(f"  {names[r]:<23} {m * 1e6:10.2f}  se {se * 1e6:6.2f}   minus terminal {dm * 1e6:8.2f}  se {dse * 1e6:5.2f}")
target = P[0] / P[n]
print(f"bond ratio P(T0,T0)/P(T0,T10), must average today's {target:.6f}:")
for r in "TNSI":
    m, se = ms(tot[r][2])
    print(f"  {names[r]:<23} {m:.6f}  se {se:.6f}  off by {(m - target) / se:+7.2f} se")
m, se = ms(tot["F"][2])
print(f"  first bond: P(T0,T10) {m:.6f}  se {se:.6f}  must average {1 / target:.6f}")

print("same kicks, 2000 paths: error in L_0(1) against 64 steps, hundredths of a basis point")
err, paths = {}, 2000
for _ in range(paths):
    zf, Lr = [normals() for _ in range(64)], L0[:]
    for z in zf: Lr = step(Lr, 'T', T0 / 64, z)
    for k in (1, 2, 4, 8):
        g = 64 // k
        zk = [[sum(z[c] for z in zf[s * g:(s + 1) * g]) / sqrt(g) for c in (0, 1)] for s in range(k)]
        for pc in (False, True):
            Lc = L0[:]
            for z in zk: Lc = step(Lc, 'T', T0 / k, z, pc)
            e = err.setdefault((k, pc), [0.0, 0.0])
            e[0] += (Lc[0] - Lr[0]) * 1e6 / paths; e[1] += abs(Lc[0] - Lr[0]) * 1e6 / paths
for k in (1, 2, 4, 8):
    (eb, ea), (pb, pa) = err[(k, False)], err[(k, True)]
    print(f"  {k} steps  average: Euler {eb:7.4f}  corrector {pb:7.4f}   size: Euler {ea:7.4f}  corrector {pa:7.4f}")

assert max(abs(muT[i] - bump[i]) for i in range(n)) < 1e-10, "drift formula vs bumped bond ratio"
assert abs(hc[0] - 0.029897065778) < 1e-11, "hand step vs the audited value"
for r in "TF": assert abs(ms(tot[r][0])[0] - black) < 3 * ms(tot[r][0])[1], "caplet MC vs Black-76"
assert abs(ms(dif["F"])[0]) < 3 * ms(dif["F"])[1], "two measures, one swaption price"
assert abs(ms(dif["N"])[0]) > 3 * ms(dif["N"])[1], "dropping the drift must move the price"
assert abs(ms(tot["T"][2])[0] - target) < 3 * ms(tot["T"][2])[1], "bond ratio is a fair bet"
assert all(abs(err[(k, True)][0]) < abs(err[(k, False)][0]) / 4 for k in (1, 2, 4, 8)), "corrector bias"
print("ALL CHECKS PASS")
