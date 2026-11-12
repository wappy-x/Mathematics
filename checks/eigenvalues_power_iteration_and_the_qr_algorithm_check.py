# Eigenvalues by iteration -- the check behind the card.  Standard library only.
# A five-storey shear frame: floor mass m, storey stiffness s, A = K / s.
# Road one: the closed form 4 sin^2((2j-1) pi / 22).  Road two: power, inverse
# and shifted inverse iteration.  Road three: the QR algorithm, with trace,
# determinant (product of Thomas pivots) and a power-iteration column as checks.
from math import sin, sqrt, pi, log10

n, m, s = 5, 5.0e4, 1.0e8                  # illustrative: 50 t floors, 100 MN/m storeys
b = [2.0] * (n - 1) + [1.0]                # diagonal of A; every off-diagonal is -1
A = [[b[i] if i == j else (-1.0 if abs(i - j) == 1 else 0.0) for j in range(n)] for i in range(n)]
FL = [0]

def dot(u, v):
    t = 0.0
    for p, q in zip(u, v): t += p * q
    return t
def nrm(x): return sqrt(dot(x, x))
def unit(x):
    r = nrm(x); return [t / r for t in x]
def mv(x):                                 # A x on the three diagonals, flops counted
    y = []
    for i in range(n):
        t = b[i] * x[i]; FL[0] += 1
        if i > 0: t -= x[i - 1]; FL[0] += 1
        if i < n - 1: t -= x[i + 1]; FL[0] += 1
        y.append(t)
    return y
def solve(mu, d):                          # (A - mu I) y = d by the Thomas sweep
    p, z = [b[0] - mu], [d[0]]
    for i in range(1, n):
        l = -1.0 / p[i - 1]
        p.append(b[i] - mu + l); z.append(d[i] - l * z[i - 1])
    y = [0.0] * n; y[-1] = z[-1] / p[-1]
    for i in range(n - 2, -1, -1): y[i] = (z[i] + y[i + 1]) / p[i]
    return y, p
def resid(x, lam): return nrm([u - lam * v for u, v in zip(mv(x), x)])   # |A x - lambda x|
def err(x, v): c = dot(x, v); return nrm([p - c * q for p, q in zip(x, v)])   # e: distance off the true line

sj = [sin((2 * j - 1) * pi / (2 * (2 * n + 1))) for j in range(1, n + 1)]
lam = [4 * t * t for t in sj]              # road one: the closed form
V = [unit([sin((2 * j - 1) * i * pi / (2 * n + 1)) for i in range(1, n + 1)]) for j in range(1, n + 1)]
per = lambda L: 2 * pi / sqrt(L * s / m)   # period in seconds from an eigenvalue of A
print("closed form lambda_1..5:", " ".join(f"{t:.6f}" for t in lam))
print(f"periods: mode 1 {per(lam[0]):.4f} s ({sqrt(lam[0] * s / m) / (2 * pi):.3f} Hz), mode 5 {per(lam[4]):.4f} s")
print("mode 1 shape, top floor = 1:", " ".join(f"{t / V[0][-1]:.4f}" for t in V[0]))
print("mode 5 shape, largest = 1:", " ".join(f"{t / V[4][2]:.4f}" for t in V[4]))
mf = [dot(v, [1.0] * n) * dot(v, [1.0] * n) / n for v in V]
print("share of the frame's mass moving in each mode:", " ".join(f"{t:.4f}" for t in mf))

w0 = 2 * pi / 0.5; mu = w0 * w0 * m / s    # rule of thumb: 0.1 s a storey, so 0.5 s
runs = [("power", lambda x: mv(x), 4, lam[3] / lam[4]),
        ("inverse", lambda x: solve(0.0, x)[0], 0, lam[0] / lam[1]),
        ("shifted", lambda x: solve(mu, x)[0], 0, abs((lam[0] - mu) / (lam[1] - mu)))]
print(f"shift mu from a 0.5 s guess = {mu:.6f}")
hist, tb = {}, {}
for name, step, j, g in runs:
    x, H = unit([1.0] * n), []
    for k in range(121):
        L = dot(x, mv(x)); H.append((err(x, V[j]), abs(L - lam[j]), resid(x, L), L))
        x = unit(step(x))
    hist[name] = H
    kk = {"power": 10, "inverse": 3, "shifted": 1}[name]
    ks = next((k for k in range(121) if H[k][2] < 1e-10), 120)
    print(f"{name}: gamma {g:.6f}, seen e ratio {H[kk + 1][0] / H[kk][0]:.6f}, "
          f"lambda-error ratio {H[kk + 1][1] / H[kk][1]:.6f} (gamma^2 {g * g:.6f})")
    bd = H[ks][2] / min(abs(t - H[ks][3]) for i, t in enumerate(lam) if i != j)   # gap from lambda-hat
    tb[name] = H[ks][0] / bd
    print(f"  residual < 1e-10 at step {ks}: lambda-hat {H[ks][3]:.12f}, true e {H[ks][0]:.1e}, "
          f"bound residual/gap {bd:.1e}, true/bound {H[ks][0] / bd:.3f}")
for name in hist:
    print(f"chart {name}: log10 e_k, k = 0..12:", " ".join(f"{log10(max(h[0], 1e-17)):.2f}" for h in hist[name][:13]))
y = solve(0.0, [1.0] * n)[0]; z = solve(0.0, y)[0]   # by hand: A^-1 has entries min(i, j)
print("by hand: A y = ones gives y =", " ".join(f"{t:.4f}" for t in y), "; A z = y gives z =", " ".join(f"{t:.4f}" for t in z))
print(f"  lambda-hat {dot(y, [1.0] * n):.0f}/{dot(y, y):.0f} = {dot(y, [1.0] * n) / dot(y, y):.6f} ({per(dot(y, [1.0] * n) / dot(y, y)):.4f} s), "
      f"{dot(z, y):.0f}/{dot(z, z):.0f} = {dot(z, y) / dot(z, z):.6f} ({per(dot(z, y) / dot(z, z)):.4f} s)")
print("  shape after two steps, top = 1:", " ".join(f"{t / z[-1]:.4f}" for t in z))
print("first steps, inverse: lambda-hat", " ".join(f"{h[3]:.6f}" for h in hist["inverse"][:4]))
FL[0] = 0; mv([1.0] * n); print(f"flops: A x {FL[0]} = 3n - 2 (off-diagonals are -1); a general Thomas solve 8n - 7 = {8 * n - 7}")

def qr_step(M, mu):                        # M - mu I = Q R by Givens rotations; return R Q + mu I
    k = len(M); R = [r[:] for r in M]; rot = []
    for i in range(k): R[i][i] -= mu
    for i in range(k - 1):
        a, c = R[i][i], R[i + 1][i]; r = sqrt(a * a + c * c); cs, sn = a / r, c / r; rot.append((cs, sn))
        for j in range(k): R[i][j], R[i + 1][j] = cs * R[i][j] + sn * R[i + 1][j], -sn * R[i][j] + cs * R[i + 1][j]
    for i, (cs, sn) in enumerate(rot):
        for j in range(k): R[j][i], R[j][i + 1] = cs * R[j][i] + sn * R[j][i + 1], -sn * R[j][i] + cs * R[j][i + 1]
    for i in range(k): R[i][i] += mu
    return R, rot
M, Qb, steps = [r[:] for r in A], [[float(i == j) for j in range(n)] for i in range(n)], 0
xe = [1.0] + [0.0] * (n - 1)
while max(abs(M[i + 1][i]) for i in range(n - 1)) >= 1e-12:
    M, rot = qr_step(M, 0.0); steps += 1
    for i, (cs, sn) in enumerate(rot):
        for j in range(n): Qb[j][i], Qb[j][i + 1] = cs * Qb[j][i] + sn * Qb[j][i + 1], -sn * Qb[j][i] + cs * Qb[j][i + 1]
    xe = unit(mv(xe))
    if steps == 10:
        print("unshifted QR, 10 steps: diagonal", " ".join(f"{M[i][i]:.6f}" for i in range(n)))
        print("  subdiagonal", " ".join(f"{abs(M[i + 1][i]):.1e}" for i in range(n - 1)))
        col = abs(dot([Qb[j][0] for j in range(n)], xe)); print(f"  |first column of Q-bar . power vector from e1| = {col:.15f}")
print(f"unshifted QR: {steps} steps to subdiagonal < 1e-12; diagonal", " ".join(f"{M[i][i]:.6f}" for i in range(n)))
def shifted_qr(wilkinson):                 # QR with deflation; shift by Wilkinson's rule, or the corner entry alone
    M, e, ws = [r[:] for r in A], n - 1, 0
    while e > 0:
        a, c, d = M[e - 1][e - 1], M[e][e - 1], M[e][e]; h = (a - d) / 2
        w = d - (1.0 if h >= 0 else -1.0) * c * c / (abs(h) + sqrt(h * h + c * c)) if wilkinson else d
        B, _ = qr_step([r[:e + 1] for r in M[:e + 1]], w); ws += 1
        for i in range(e + 1): M[i][:e + 1] = B[i]
        while e > 0 and abs(M[e][e - 1]) < 1e-14 * (abs(M[e][e]) + abs(M[e - 1][e - 1])): e -= 1
    return M, ws
(M, ws), wc = shifted_qr(True), shifted_qr(False)[1]
ev = sorted(M[i][i] for i in range(n))
tr, pr = 0.0, 1.0
for t in ev: tr += t; pr *= t
piv = solve(0.0, [1.0] * n)[1]; dt = 1.0
for t in piv: dt *= t
print(f"shifted QR: {ws} steps (corner shift alone: {wc}); eigenvalues", " ".join(f"{t:.12f}" for t in ev))
print(f"  sum {tr:.12f} = trace 9; product {pr:.12f} = det = Thomas pivots' product {dt:.12f}")
# what breaks
x, k = [1.0] * n, 0
while max(map(abs, x)) < float("inf"): x = mv(x); k += 1
print(f"break, no normalising: entries overflow to inf at step {k}")
mid = (lam[0] + lam[1]) / 2; x = unit([1.0] * n)
for k in range(50): x = unit(solve(mid, x)[0])
Lm = dot(x, mv(x)); print(f"break, shift midway {mid:.6f}: lambda-hat after 50 steps {Lm:.6f}, residual {resid(x, Lm):.3f}")
print(f"break, power iteration for the fundamental: period {per(hist['power'][120][3]):.4f} s, not {per(lam[0]):.4f} s")
H = hist["power"]; kc = next(k for k in range(120) if abs(H[k + 1][3] - H[k][3]) < 1e-10)
print(f"break, stop when lambda-hat moves < 1e-10: step {kc + 1}, lambda error {H[kc + 1][1]:.1e}, mode-shape error e {H[kc + 1][0]:.1e}")

assert max(resid(V[j], lam[j]) for j in range(n)) < 1e-14           # closed form solves A v = lambda v
assert max(abs(p - q) for p, q in zip(ev, lam)) < 1e-13                # QR agrees with the closed form
assert abs(tr - 9.0) < 1e-13 and abs(pr - dt) < 1e-13 and abs(dt - 1.0) < 1e-13
for name, _, _, g in runs:                                             # observed rate = eigenvalue gap
    kk = {"power": 10, "inverse": 3, "shifted": 1}[name]
    assert abs(hist[name][kk + 1][0] / hist[name][kk][0] - g) < 0.02 * g
assert abs(col - 1.0) < 1e-12 and ws < wc < steps / 5                 # QR = power on e1; shifts pay; Wilkinson's best
assert all(t < 1.001 for t in tb.values())                             # true e <= residual/gap, up to rounding
assert resid(x, Lm) > 0.1 and min(abs(Lm - t) for t in lam) > 0.05   # equal gaps: no convergence
print("ALL CHECKS PASS")
