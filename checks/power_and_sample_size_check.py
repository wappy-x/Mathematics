# Power and sample size -- the check behind the card.  Standard library only.
# A drug trial: placebo recovery 35 percent, hoped-for drug recovery 45 percent.
# How many patients per arm give an 80 percent chance of a significant result?
# Road 1: the normal-approximation formula, solved for n in closed form.
# Road 2: exact enumeration over every pair of recovery counts (binomial sums).
# Road 3: seeded simulated trials, patient by patient (SplitMix64).
from math import sqrt, pi, exp, ceil

P0, P1, ALPHA, TARGET, SEED, R = 0.35, 0.45, 0.05, 0.80, 20260928, 10000

def Phi(z):                                   # bell area left of z, by its Taylor series
    term, total = z, z
    for k in range(1, 300):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)

def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)

def Phi_inv(p):                               # normal quantile by Newton's method from 0
    z = 0.0
    for _ in range(50):
        z -= (Phi(z) - p) / phi(z)
    return z

def spreads(p0, p1):                          # per-patient spreads: under the null, under the gain
    pbar = (p0 + p1) / 2
    return sqrt(2 * pbar * (1 - pbar)), sqrt(p0 * (1 - p0) + p1 * (1 - p1))

def power_formula(n, p0=P0, p1=P1, za=None):  # road 1: both tails of the observed gap
    za = Phi_inv(1 - ALPHA / 2) if za is None else za
    s0, s1 = spreads(p0, p1)
    c, d = za * s0 / sqrt(n), p1 - p0          # cutoff for the gap, true gap
    return Phi((d - c) * sqrt(n) / s1), Phi((-d - c) * sqrt(n) / s1)

def n_formula(p0=P0, p1=P1, za=None, zb=None):
    za = Phi_inv(1 - ALPHA / 2) if za is None else za
    zb = Phi_inv(TARGET) if zb is None else zb
    s0, s1 = spreads(p0, p1)
    return ((za * s0 + zb * s1) / (p1 - p0)) ** 2

def pmf(n, p):                                # binomial chances of 0..n recoveries, by recurrence
    out, q = [(1 - p) ** n], p / (1 - p)
    for k in range(n):
        out.append(out[-1] * (n - k) / (k + 1) * q)
    return out

def rejects(x0, x1, n, za):                   # the pooled two-proportion z test, two-sided
    pool = (x0 + x1) / (2 * n)
    if pool == 0 or pool == 1: return False
    return abs(x1 - x0) / n > za * sqrt(pool * (1 - pool) * 2 / n)

def power_exact(n):                           # road 2: add up every rejecting outcome
    za = Phi_inv(1 - ALPHA / 2)
    f0, f1, tot = pmf(n, P0), pmf(n, P1), 0.0
    for x1 in range(n + 1):
        row = 0.0
        for x0 in range(n + 1):
            if rejects(x0, x1, n, za): row += f0[x0]
        tot += f1[x1] * row
    return tot

class Rng:                                    # SplitMix64, seed 20260928
    def __init__(self, s): self.s = s
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def power_sim(n, rng):                        # road 3: run R whole trials, patient by patient
    za, hits = Phi_inv(1 - ALPHA / 2), 0
    for _ in range(R):
        x0 = sum(1 for _ in range(n) if rng.next() < P0)
        x1 = sum(1 for _ in range(n) if rng.next() < P1)
        hits += rejects(x0, x1, n, za)
    est = hits / R
    return est, sqrt(est * (1 - est) / R)

za, zb = Phi_inv(1 - ALPHA / 2), Phi_inv(TARGET)
s0, s1 = spreads(P0, P1)
n_raw = n_formula(); n_need = ceil(n_raw)
print(f"quantiles, z(0.975) {za:.6f}  z(0.80) {zb:.6f}")
print(f"spreads, null sqrt(2 pbar qbar) {s0:.6f}  gain sqrt(p0q0+p1q1) {s1:.6f}")
print(f"n pieces: z*s0 {za * s0:.6f} + z*s1 {zb * s1:.6f} = {za * s0 + zb * s1:.6f}")
print(f"at n 400: SE null {s0 / 20:.6f}, SE gain {s1 / 20:.6f}, (0.10 - cutoff)/SE gain {(0.10 - za * s0 / 20) / (s1 / 20):.4f}")
f0, f1 = pmf(400, P0), pmf(400, P1)                  # Step 1 by enumeration: Var of the gap at n 400
var_ex = sum(f * (k / 400 - P0) ** 2 for k, f in enumerate(f0)) + sum(f * (k / 400 - P1) ** 2 for k, f in enumerate(f1))
print(f"at n 400: Var of gap by enumeration {var_ex:.8f}, sigma1^2/n {s1 * s1 / 400:.8f}")
print(f"formula n per arm {n_raw:.2f}, round up to {n_need}; with 1 in 20 dropping out {n_need / 0.95:.1f}")
rows = {}
for n in (100, n_need, 400):
    up, down = power_formula(n)
    rows[n] = (up + down, power_exact(n))
    print(f"n {n}: power formula {up + down:.4f} (far tail {down:.6f})  exact {rows[n][1]:.4f}")
n_ex = n_need - 20
while power_exact(n_ex) < TARGET: n_ex += 1
print(f"exact: smallest n per arm from {n_need - 20} with power >= 0.80 is {n_ex}, power {power_exact(n_ex):.4f}")
rng = Rng(SEED)
sims = {n: power_sim(n, rng) for n in (100, 400)}
for n, (est, se) in sims.items():
    print(f"simulated n {n}: {R} trials, power {est:.4f} +- {se:.4f}")
pool = 0.40; zh = 0.10 / sqrt(pool * (1 - pool) * 2 / 100)          # the house trial: 45 of 100 against 35 of 100
print(f"house trial z {zh:.4f}, two-sided p-value {2 * (1 - Phi(zh)):.4f}, cutoff at n 100 {za * s0 / 10:.4f}")
print(f"house 95% interval for the gain: {0.10 - za * s1 / 10:.4f} to {0.10 + za * s1 / 10:.4f}; n per arm for +-0.05 {ceil((za * s1 / 0.05) ** 2)}")
print(f"after the trial, observed 40 vs 35 of 100: plug-in 'observed power' {sum(power_formula(100, p1=0.40)):.4f}")
# what breaks
n_one = ceil(n_formula(za=Phi_inv(1 - ALPHA)))
print(f"breaks, one-sided z(0.95) {Phi_inv(1 - ALPHA):.6f} in a two-sided test: n {n_one}, true power {sum(power_formula(n_one)):.4f}")
print(f"breaks, 376 total read as per arm: n 188, power {sum(power_formula(188)):.4f}")
n_half = ceil(n_formula(p1=0.40))
print(f"breaks, 5-point gain with doubled n 752: power {sum(power_formula(752, p1=0.40)):.4f}; needs {n_half}")
print(f"breaks, gain guessed 15 points, truly 10: n {ceil(n_formula(p1=0.50))}, power {sum(power_formula(ceil(n_formula(p1=0.50)))):.4f}")
# try changing
print(f"try, 90% power: n {ceil(n_formula(zb=Phi_inv(0.90)))}")
print(f"try, alpha 0.01: n {ceil(n_formula(za=Phi_inv(0.995)))}")
print(f"try, placebo 0.50 drug 0.60: n {ceil(n_formula(p0=0.50, p1=0.60))}")
print(f"elsewhere, clicks 0.050 vs 0.055: n {ceil(n_formula(p0=0.050, p1=0.055))}; poll 0.50 vs 0.53: n {ceil(n_formula(p0=0.50, p1=0.53))}")
# figures
xs = [round(-0.10 + 0.02 * i, 2) for i in range(16)]
se0, se1 = s0 / sqrt(400), s1 / sqrt(400)
print("figure, gap", " ".join(f"{x:.2f}" for x in xs))
print("figure, null bell n 400", " ".join(f"{phi(x / se0) / se0:.2f}" for x in xs))
print("figure, gain bell n 400", " ".join(f"{phi((x - 0.10) / se1) / se1:.2f}" for x in xs))
print(f"figure, cutoff {za * se0:.4f}")
ns = list(range(50, 650, 50))
curve_f = [sum(power_formula(n)) for n in ns]
curve_e = [power_exact(n) for n in ns]
print("figure, n", " ".join(str(n) for n in ns))
print("figure, power formula", " ".join(f"{v:.2f}" for v in curve_f))
print("figure, power exact", " ".join(f"{v:.2f}" for v in curve_e))
assert abs(za - 1.959963984540054) < 1e-9                                # published 97.5% point
assert abs(var_ex - s1 * s1 / 400) < 1e-12                                # enumeration vs sigma1
assert all(abs(f - e) < 0.02 for f, e in zip(curve_f, curve_e))           # formula vs enumeration
assert sum(power_formula(n_need)) >= TARGET > sum(power_formula(n_need - 1))  # closed form vs power
assert abs(n_ex - n_need) <= 5                                            # enumeration vs closed form
for n, (est, se) in sims.items():
    assert abs(est - rows[n][1]) < 4 * se                                  # simulation vs enumeration
print("all checks passed")
