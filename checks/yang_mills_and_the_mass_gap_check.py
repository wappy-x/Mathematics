# Yang-Mills existence and mass gap -- the check behind the card.  Standard library only.
# Part 1 reads a published SU(3) lattice gap and extrapolates it to zero spacing.
# Part 2 builds a lattice transfer matrix (Z2 gauge theory, 2 by 2 box) and finds its gap.
from math import exp, log, tanh, sqrt

# ---- Part 1: Athenodorou and Teper 2020, Table 1: beta, box in sites, a*sqrt(sigma), a*m(0++)
DATA = [(5.6924, 10, 0.3999, 0.987), (5.80, 12, 0.31666, 0.908), (5.8941, 14, 0.26118, 0.7991),
        (5.99, 18, 0.21982, 0.7045), (6.0625, 20, 0.19472, 0.6365), (6.235, 26, 0.15003, 0.4969),
        (6.338, 30, 0.12928, 0.4276), (6.50, 38, 0.10383, 0.3474)]
HBARC, R0, R0SIG, PAPER, PAPER_ERR = 197.326980, 0.472, 1.160, 3.405, 0.021   # MeV fm, fm, -, -, -
SIG = R0SIG * HBARC / R0                                          # sqrt(string tension) in MeV
print("part 1: SU(3) glueball gap on the lattice (Athenodorou and Teper 2020)")
print("beta    box  a*sqrt(sig)  a*m     m/sqrt(sig)  a (fm)   box (fm)  m (MeV)")
for b, L, s, m in DATA:
    a = s * HBARC / SIG
    print(f"{b:<7.4f} {L:>3}  {s:.5f}      {m:.4f}  {m / s:.6f}     {a:.5f}  {L * a:.3f}     {m / s * SIG:.1f}")
print(f"scale: sqrt(sigma) = {R0SIG:.3f} x {HBARC:.6f} / {R0:.3f} = {SIG:.3f} MeV; paper: 485(6) MeV")
assert abs(SIG - 485) < 6                              # our conversion matches the paper's quoted scale

def fit(points):                     # least squares: m/sqrt(sig) = c0 + c1 (a sqrt(sig))^2
    xs = [s * s for _, _, s, _ in points]; ys = [m / s for _, _, s, m in points]
    n = len(xs); mx = sum(xs) / n; my = sum(ys) / n
    c1 = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
    return my - c1 * mx, c1
c0, c1 = fit(DATA[2:])
c0all, _ = fit(DATA)
mean = sum(m / s for _, _, s, m in DATA) / len(DATA)
print(f"continuum fit, 6 finest: m/sqrt(sig) = {c0:.6f} + ({c1:.6f}) (a sqrt(sig))^2")
print(f"paper's fit {PAPER:.3f}({PAPER_ERR * 1000:.0f}): difference {c0 - PAPER:.6f}")
print(f"continuum gap: {c0:.6f} x {SIG:.3f} = {c0 * SIG:.1f} MeV;  paper's: {PAPER * SIG:.1f} MeV")
assert abs(c0 - PAPER) < PAPER_ERR                     # our fit agrees with the paper's own fit
assert abs(DATA[-1][3] / DATA[-1][2] / c0 - 1) < 0.02     # the finest lattice sits within 2% of the limit

# ---- Part 2: Z2 lattice gauge theory in 2+1 dimensions on a 2 by 2 spatial box
def lid(x, y, d): return 2 * ((x % 2) + 2 * (y % 2)) + d      # link number: site (x,y), direction d
PLAQ = [(1 << lid(x, y, 0)) | (1 << lid(x + 1, y, 1)) | (1 << lid(x, y + 1, 0)) | (1 << lid(x, y, 1))
        for y in (0, 1) for x in (0, 1)]
def P(s): return sum(1 - 2 * ((s & m).bit_count() & 1) for m in PLAQ)   # sum of 4 plaquettes, +-1 each
FLIP = [(1 << lid(0, y, 0)) | (1 << lid(1, y, 0)) | (1 << lid(x, 0, 1)) | (1 << lid(x, 1, 1))
        for y in (0, 1) for x in (0, 1)]                        # gauge change at one site
GAUGE = sorted({(i & 1) * FLIP[0] ^ (i >> 1 & 1) * FLIP[1] ^ (i >> 2 & 1) * FLIP[2] ^ (i >> 3 & 1) * FLIP[3]
                for i in range(16)})
ORB, seen = [], set()
for s in range(256):                                            # gauge orbits = gauge-invariant states
    if s not in seen:
        ORB.append([s ^ g for g in GAUGE]); seen.update(ORB[-1])
def tmat(b):                                                    # transfer matrix on invariant states
    def T(s, t): return exp(b / 2 * (P(s) + P(t)) + b * (8 - 2 * (s ^ t).bit_count()))
    return [[sum(T(A[0], c) for c in B) for B in ORB] for A in ORB]

def jacobi(M):                                                  # all eigenvalues and eigenvectors
    n = len(M); A = [r[:] for r in M]; V = [[float(i == j) for j in range(n)] for i in range(n)]
    for _ in range(60):
        off = sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j)
        if off < 1e-26 * sum(A[i][i] ** 2 for i in range(n)): break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1)); c = 1 / sqrt(t * t + 1); s = t * c
                for R in (A, V):
                    for k in range(n):
                        x, y = R[k][p], R[k][q]; R[k][p] = c * x - s * y; R[k][q] = s * x + c * y
                for k in range(n):
                    x, y = A[p][k], A[q][k]; A[p][k] = c * x - s * y; A[q][k] = s * x + c * y
    idx = sorted(range(n), key=lambda i: -A[i][i])
    return [A[i][i] for i in idx], [[V[k][i] for k in range(n)] for i in idx]

def spectrum(b):        # lowest level, level the plaquette sum creates, weights, eigenvalues
    lam, vec = jacobi(tmat(b))
    w = [sum(vec[n][i] * P(A[0]) * vec[0][i] for i, A in enumerate(ORB)) ** 2 for n in range(len(ORB))]
    first = next(n for n in range(1, len(ORB)) if w[n] > 1e-9 * max(w[1:]))
    return lam, w, log(lam[0] / lam[1]), log(lam[0] / lam[first])

print(f"part 2: Z2 gauge theory, 2+1 dimensions, 2x2 box: {len(GAUGE)} gauge changes, {len(ORB)} invariant states")
print("beta  lowest level  2(-ln tanh)  plaquette level  4(-ln tanh)  ratio  smallest eigenvalue")
ratios, store = [], {}
for b in (0.1, 0.2, 0.3, 0.4, 0.5):
    lam, w, low, gap = spectrum(b); u = -log(tanh(b)); store[b] = (lam, w, low, gap)
    ratios.append(gap / (4 * u))
    print(f"{b:.1f}   {low:.6f}      {2 * u:.6f}     {gap:.6f}         {4 * u:.6f}     {gap / (4 * u):.4f} {min(lam):.6f}")
    assert min(lam) > 0                                  # reflection positivity: T has no negative eigenvalue
assert ratios[0] > ratios[1] > ratios[2] and ratios[0] > 0.95   # strong coupling is right as beta -> 0

lam, w, low, gap = store[0.3]                            # effective mass from the exact correlator
C = [sum(w[n] * (lam[n] / lam[0]) ** t for n in range(1, len(lam))) for t in range(7)]
meff = [log(C[t] / C[t + 1]) for t in range(6)]
print("beta 0.3, effective mass ln(C(t)/C(t+1)), t = 0..5:", " ".join(f"{m:.6f}" for m in meff))
assert meff[0] > meff[2] > meff[5] > gap and meff[5] - gap < 1e-3      # falls onto the gap from above

def brute(nt, b):       # ln Z by summing every link configuration of a 2x2xnt periodic lattice
    masks = []
    for t in range(nt):
        tl = lambda x, y: 1 << (8 * nt + 4 * t + (x % 2) + 2 * (y % 2))   # timelike link, layer t
        for m in PLAQ: masks.append(m << 8 * t)
        for x, y, d in [(x, y, d) for y in (0, 1) for x in (0, 1) for d in (0, 1)]:
            l = lid(x, y, d)
            masks.append((1 << (l + 8 * t)) ^ (1 << (l + 8 * ((t + 1) % nt))) ^ tl(x, y) ^ tl(x + 1 - d, y + d))
    vec = lambda c: sum((((c & m).bit_count() & 1) << j) for j, m in enumerate(masks))
    lo = [vec(c) for c in range(256)]; hi = [vec(c << 8) for c in range(1 << (12 * nt - 8))]
    hist = [0] * (len(masks) + 1)
    for h in hi:
        for v in lo: hist[(h ^ v).bit_count()] += 1
    return log(sum(n * exp(b * (len(masks) - 2 * k)) for k, n in enumerate(hist)))
for nt in (1, 2):
    for b in (0.3, 0.5):
        lam = store[b][0]; zt = log(16 ** nt * sum(l ** nt for l in lam)); zb = brute(nt, b)
        print(f"ln Z, {nt} time step(s), beta {b:.1f}: every configuration {zb:.9f}  transfer matrix {zt:.9f}")
        assert abs(zb - zt) < 1e-9

print("what breaks:")
print(f"  lowest level in the box at beta 0.3: {store[0.3][2]:.6f}, not the plaquette's {store[0.3][3]:.6f}")
print(f"  plain average of m/sqrt(sig), no extrapolation: {mean:.6f}, not {c0:.6f}; all 8 points: {c0all:.6f}")
print(f"  effective mass at t = 0: {meff[0]:.6f}, not {gap:.6f} ({100 * (meff[0] / gap - 1):.1f}% high)")
print(f"  strong coupling at beta 0.5: {4 * -log(tanh(0.5)):.6f}, not {store[0.5][3]:.6f}")
sig5 = R0SIG * HBARC / 0.5; g05 = spectrum(0.05)[3]
print(f"try: r0 = 0.500 fm: sqrt(sigma) {sig5:.3f} MeV, gap {c0 * sig5:.1f} MeV;"
      f" beta 0.05: plaquette level {g05:.6f}, ratio to 4(-ln tanh) {g05 / (-4 * log(tanh(0.05))):.4f}")
print("ALL CHECKS PASS")
