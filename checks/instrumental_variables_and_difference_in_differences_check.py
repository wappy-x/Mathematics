# Instrumental variables and difference-in-differences -- the check behind the card.
# Standard library only.  Every number is made up for hand work.  Roads: Wald ratio
# against the compliers' own effect, two-stage least squares and the covariance ratio;
# DiD from four means against a regression with an interaction and per-shop changes.
from math import sqrt

def solve(a, b):                                 # Gaussian elimination, partial pivoting
    n, m = len(b), [row[:] + [b[i]] for i, row in enumerate(a)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(m[r][c])); m[c], m[p] = m[p], m[c]
        for r in range(n):
            if r != c:
                m[r] = [x - m[r][c] / m[c][c] * y for x, y in zip(m[r], m[c])]
    return [m[i][n] / m[i][i] for i in range(n)]

def gram(X):                                     # X^T X
    return [[sum(r[i] * r[j] for r in X) for j in range(len(X[0]))] for i in range(len(X[0]))]

def ols(X, y):                                   # least squares by the normal equations
    return solve(gram(X), [sum(r[i] * v for r, v in zip(X, y)) for i in range(len(X[0]))])

def se(X, resid, j):                             # s * sqrt of entry j of (X^T X)^-1
    e = [0.0] * len(X[0]); e[j] = 1.0
    return sqrt(sum(r * r for r in resid) / (len(X) - len(X[0])) * solve(gram(X), e)[j])

M64, state = (1 << 64) - 1, 20261123              # SplitMix64, seed stated
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def bell():                                      # mean 0, spread 1: four uniforms summed
    return (uniform() + uniform() + uniform() + uniform() - 2.0) * sqrt(3.0)

# ---- the gym voucher, exact: type -> (share, kg lost without the gym, gym's effect in kg)
TYPES = {"always": (0.20, 1.0, 3.0), "complier": (0.30, 0.5, 3.0), "never": (0.50, 0.1, 1.0)}
joins = lambda t, z: t == "always" or (t == "complier" and z == 1)
def arm(z, letter=0.0):                          # sign-up share and mean kg lost in one arm
    d = sum(s for t, (s, _, _) in TYPES.items() if joins(t, z))
    y = sum(s * (y0 + (eff if joins(t, z) else 0.0)) for t, (s, y0, eff) in TYPES.items())
    return d, y + letter * z
print("types: share, kg lost without -> with the gym: " + "; ".join(f"{t} {s:.2f}, {a:.1f} -> {a + e:.1f}"
                                                                   for t, (s, a, e) in TYPES.items()))
(d0, y0), (d1, y1) = arm(0), arm(1)
wald = (y1 - y0) / (d1 - d0)
late, ate = TYPES["complier"][2], sum(s * eff for s, _, eff in TYPES.values())  # off the table
print(f"no voucher: sign-up {d0:.2f}, mean loss {y0:.2f} kg; voucher: sign-up {d1:.2f}, mean loss {y1:.2f} kg")
print(f"Wald = {y1 - y0:.2f} / {d1 - d0:.2f} = {wald:.2f} kg per sign-up; compliers' own effect {late:.2f}; "
      f"average effect over everyone {ate:.2f}")
assert abs(wald - late) < 1e-12                  # the Wald ratio is the compliers' effect
assert abs(ate - late) > 0.5                     # which here is not the average effect over everyone
mem = [(0.5 * s, y0_ + eff) for t, (s, y0_, eff) in TYPES.items() for z in (0, 1) if joins(t, z)]
non = [(0.5 * s, y0_) for t, (s, y0_, eff) in TYPES.items() for z in (0, 1) if not joins(t, z)]
mean = lambda g: sum(w * v for w, v in g) / sum(w for w, _ in g)
(_, yl0), (_, yl1) = arm(0, 0.15), arm(1, 0.15)
print(f"members {mean(mem):.4f} kg, non-members {mean(non):.4f} kg; what breaks: voucher effect read as the gym's "
      f"{y1 - y0:.2f}; naive gap {mean(mem) - mean(non):.2f}; letter itself worth 0.15 kg -> Wald {(yl1 - yl0) / (d1 - d0):.2f} "
      f"(bias 0.15 / {d1 - d0:.2f} = {0.15 / (d1 - d0):.2f}; with a 3-point lift 0.15 / 0.03 = {0.15 / 0.03:.2f})")

# ---- a seeded sample of 4,000 people, with starting weight W as a measured covariate
rows = []
for _ in range(4000):
    u, z = uniform(), 1 if uniform() < 0.5 else 0
    t = "always" if u < 0.2 else ("complier" if u < 0.5 else "never")
    w = 90.0 + 12.0 * bell()
    d = 1 if joins(t, z) else 0
    rows.append((z, d, w, TYPES[t][1] + TYPES[t][2] * d + 0.1 * (w - 90.0) + 1.5 * bell()))
(Z, D, _, Y), n = (list(c) for c in zip(*rows)), len(rows)
avg = lambda v, zz: sum(a for a, b in zip(v, Z) if b == zz) / Z.count(zz)
s_wald = (avg(Y, 1) - avg(Y, 0)) / (avg(D, 1) - avg(D, 0))
mz, md, my = sum(Z) / n, sum(D) / n, sum(Y) / n
cov_ratio = sum((a - mz) * (c - my) for a, c in zip(Z, Y)) / sum((a - mz) * (b - md) for a, b in zip(Z, D))
print(f"sample n={n}: sign-up {avg(D, 0):.4f} -> {avg(D, 1):.4f}, loss {avg(Y, 0):.4f} -> {avg(Y, 1):.4f} kg")
for label, extra in (("no covariate", lambda r: []), ("with W", lambda r: [r[2] - 90.0])):
    X1 = [[1.0, float(r[0])] + extra(r) for r in rows]
    g1 = ols(X1, D)
    fit = [sum(a * b for a, b in zip(x, g1)) for x in X1]
    f_stat = (g1[1] / se(X1, [d - f for d, f in zip(D, fit)], 1)) ** 2
    X2 = [[1.0, f] + extra(r) for f, r in zip(fit, rows)]
    b = ols(X2, Y)
    right = [y - b[0] - b[1] * d - sum(a * c for a, c in zip(extra(r), b[2:])) for y, d, r in zip(Y, D, rows)]
    wrong = [y - sum(a * c for a, c in zip(x, b)) for y, x in zip(Y, X2)]
    print(f"2SLS {label}: {b[1]:.4f} kg (SE {se(X2, right, 1):.4f}; second-stage SE taken as is "
          f"{se(X2, wrong, 1):.4f}); first-stage F {f_stat:.1f}")
    assert abs(b[1] - 3.0) < 4 * se(X2, right, 1)
    if label == "no covariate":
        assert abs(b[1] - s_wald) < 1e-9 and abs(cov_ratio - s_wald) < 1e-9
        print(f"  Wald from the four sample means {s_wald:.4f}; covariance ratio {cov_ratio:.4f}")
print(f"least squares of loss on sign-up, sample: {ols([[1.0, float(d)] for d in D], Y)[1]:.4f} kg")

# ---- weak instrument: 150 samples of 2,000, voucher lifting sign-up by 30 points or by 3
def wald_once(c_share):
    s = [[0, 0.0, 0.0], [0, 0.0, 0.0]]              # per arm: count, sign-ups, kg lost
    for _ in range(2000):
        u, z = uniform(), 1 if uniform() < 0.5 else 0
        t = "always" if u < 0.2 else ("complier" if u < 0.2 + c_share else "never")
        d = 1 if joins(t, z) else 0
        s[z][0] += 1; s[z][1] += d; s[z][2] += TYPES[t][1] + TYPES[t][2] * d + 1.5 * bell()
    p0, p1 = s[0][1] / s[0][0], s[1][1] / s[1][0]
    f = (p1 - p0) ** 2 / (p0 * (1 - p0) / s[0][0] + p1 * (1 - p1) / s[1][0])
    return (s[1][2] / s[1][0] - s[0][2] / s[0][0]) / (p1 - p0), f
spread = {}
for label, c_share in (("strong, 30 points", 0.30), ("weak, 3 points", 0.03)):
    runs = [wald_once(c_share) for _ in range(150)]
    est = sorted(r[0] for r in runs)
    q = lambda p: est[int(p * 149 + 0.5)]
    spread[label] = q(0.95) - q(0.05)
    print(f"{label}: median {q(0.5):.2f}, middle 90% {q(0.05):.2f} to {q(0.95):.2f} kg; "
          f"samples with F over 10: {sum(1 for r in runs if r[1] > 10)} of 150")
assert spread["weak, 3 points"] > 5 * spread["strong, 30 points"]

# ---- difference-in-differences: jobs per shop, town A gets the rule after year 2
A, B = [21.0, 20.0, 21.0], [24.0, 23.0, 22.0]    # years 1, 2, 3
did, counterfactual = (A[2] - A[1]) - (B[2] - B[1]), A[1] + (B[2] - B[1])
print(f"by hand: A {A[1]:.1f} -> {A[2]:.1f}, B {B[1]:.1f} -> {B[2]:.1f}; DiD {did:+.1f}; "
      f"A without the rule {counterfactual:.1f}, effect {A[2] - counterfactual:+.1f}; "
      f"placebo years 1-2 {(A[1] - A[0]) - (B[1] - B[0]):+.1f}")
assert abs(did - ols([[1.0, tr, af, tr * af] for tr in (1.0, 0.0) for af in (0.0, 1.0)], [A[1], A[2], B[1], B[2]])[3]) < 1e-9
print(f"what breaks: before-after in A only {A[2] - A[1]:+.1f}; after-only gap {A[2] - B[2]:+.1f}; "
      f"if A would have stayed flat, true effect {A[2] - A[1]:+.1f} but DiD still says {did:+.1f}")
print(f"chart, town A: {', '.join(f'{v:.1f}' for v in A)}; town B: {', '.join(f'{v:.1f}' for v in B)}; "
      f"town A without the rule: {A[0]:.1f}, {A[1]:.1f}, {counterfactual:.1f}")
shops = []                                       # (treated, jobs in years 1, 2, 3)
for town, mu in ((1, A), (0, B)):                # each shop: its own level, then yearly noise
    shops += [(town, (lambda lv: [m + lv + bell() for m in mu])(3.0 * bell())) for _ in range(60)]
cell = lambda tr, yr: sum(s[1][yr] for s in shops if s[0] == tr) / 60
four = (cell(1, 2) - cell(1, 1)) - (cell(0, 2) - cell(0, 1))
X = [[1.0, float(tr), float(yr == 2), float(tr and yr == 2)] for tr, _ in shops for yr in (1, 2)]
reg = ols(X, [v[yr] for _, v in shops for yr in (1, 2)])[3]
ch, pl = ({tr: [v[b] - v[a] for t, v in shops if t == tr] for tr in (0, 1)} for a, b in ((1, 2), (0, 1)))
def gap(c):                                      # difference in mean changes, and its SE
    m = {k: sum(v) / 60 for k, v in c.items()}
    return m[1] - m[0], sqrt(sum(sum((x - m[k]) ** 2 for x in c[k]) / 59 / 60 for k in (0, 1)))
(est, s_e), (plc, s_p) = gap(ch), gap(pl)
print(f"sample, 60 shops a town: four means {four:+.4f}; regression interaction {reg:+.4f}; "
      f"per-shop changes {est:+.4f} (SE {s_e:.4f}); placebo {plc:+.4f} (SE {s_p:.4f})")
assert abs(four - reg) < 1e-9 and abs(four - est) < 1e-9
assert abs(est - 2.0) < 4 * s_e and abs(plc) < 4 * s_p
print("ALL CHECKS PASS")
