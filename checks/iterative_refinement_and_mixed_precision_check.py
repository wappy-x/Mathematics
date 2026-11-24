# Iterative refinement: factor once in low precision, form each residual in double, win back double accuracy.
import math, struct

R = C = 16; N = R * C  # a 16 by 16 grid of junctions: 256 unknown drawdowns, 480 grid pipes + 20 feed pipes

def rnd(x, p):  # round a double to p significant bits, ties to even (p = 24 single, 11 half, 53 double)
    if p == 53 or x == 0.0: return x
    b = struct.unpack('<Q', struct.pack('<d', x))[0]
    sh = 53 - p; rem = b & ((1 << sh) - 1); t = b - rem; half = 1 << (sh - 1)
    if rem > half or (rem == half and (t >> sh) & 1): t += 1 << sh
    return struct.unpack('<d', struct.pack('<Q', t))[0]

def network(feeds, g_feed):  # nodal matrix: row i says water into junction i = the demand drawn there
    A = [[0.0] * N for _ in range(N)]
    def pipe(i, j, g):
        A[i][i] += g; A[j][j] += g; A[i][j] -= g; A[j][i] -= g
    for r in range(R):
        for c in range(C):
            k = r * C + c
            if c + 1 < C: pipe(k, k + 1, 1 + (7 * r + 3 * c) % 3)   # conductance 1, 2 or 3 L/s per m
            if r + 1 < R: pipe(k, k + C, 1 + (7 * r + 3 * c + 1) % 3)
    for k in feeds: A[k][k] += g_feed  # a feed pipe from the reservoir
    return A

def lu(A, p):  # LU with partial pivoting, every operation rounded to p bits
    a = [[rnd(v, p) for v in row] for row in A]; perm = list(range(N)); swaps = 0
    for k in range(N):
        m = max(range(k, N), key=lambda i: abs(a[i][k]))
        if m != k: a[k], a[m] = a[m], a[k]; perm[k], perm[m] = perm[m], perm[k]; swaps += 1
        cols = [j for j in range(k + 1, N) if a[k][j] != 0.0]
        for i in range(k + 1, N):
            if a[i][k] == 0.0: continue  # a zero multiplier changes nothing: skipped for speed only
            l = rnd(a[i][k] / a[k][k], p); a[i][k] = l
            for j in cols: a[i][j] = rnd(a[i][j] - rnd(l * a[k][j], p), p)
    nzL = [[j for j in range(i) if a[i][j] != 0.0] for i in range(N)]
    nzU = [[j for j in range(i + 1, N) if a[i][j] != 0.0] for i in range(N)]
    return a, perm, nzL, nzU, swaps

def solve(F, b, p):  # sweep down L, then up U, rounding to p bits
    a, perm, nzL, nzU, _ = F; y = [0.0] * N; x = [0.0] * N
    for i in range(N):
        s = rnd(b[perm[i]], p)
        for j in nzL[i]: s = rnd(s - rnd(a[i][j] * y[j], p), p)
        y[i] = s
    for i in range(N - 1, -1, -1):
        s = y[i]
        for j in nzU[i]: s = rnd(s - rnd(a[i][j] * x[j], p), p)
        x[i] = rnd(s / a[i][i], p)
    return x

def matvec(A, x, p=53):
    out = []
    for row in A:
        s = 0.0
        for j, v in enumerate(row):
            if v != 0.0: s = rnd(s + rnd(v * x[j], p), p)
        out.append(s)
    return out

norm = lambda v: max(abs(t) for t in v)
def setup(feeds, g_feed):  # matrix, kappa two ways, and a true answer known to the last bit
    A = network(feeds, g_feed); F64 = lu(A, 53); nA = max(sum(abs(v) for v in row) for row in A)
    inv = [solve(F64, [1.0 if i == j else 0.0 for i in range(N)], 53) for j in range(N)]  # columns
    n_inv = max(sum(abs(inv[j][i]) for j in range(N)) for i in range(N))
    w = solve(F64, [1.0] * N, 53)  # A^-1 has no negative entry, so its norm is the largest entry of A^-1 * ones
    xs = [round(v * 2**20) / 2**20 for v in w]  # true drawdowns: rounded to a 2^-20 m grid
    b = matvec(A, xs)  # demands those drawdowns imply; checked exact in whole-number arithmetic
    exact = all(sum(int(v * 2**10) * int(xs[j] * 2**20) for j, v in enumerate(row)) == int(b[i] * 2**30)
                and (b[i] * 2**30).is_integer() for i, row in enumerate(A))
    return A, F64, nA, n_inv, norm(w), xs, b, exact

def refine(A, F, b, xs, pf, pr, px, steps):  # factor precision pf, residual pr, stored answer px
    x = [rnd(v, px) for v in solve(F, b, pf)]; err = [norm([x[i] - xs[i] for i in range(N)]) / norm(xs)]; dn = []
    for _ in range(steps):
        r = [rnd(b[i] - v, pr) for i, v in enumerate(matvec(A, x, pr))]
        d = solve(F, r, pf); dn.append(norm(d) / norm(x))
        x = [rnd(x[i] + d[i], px) for i in range(N)]; err.append(norm([x[i] - xs[i] for i in range(N)]) / norm(xs))
    return err, dn

U = {11: 2.0**-11, 24: 2.0**-24, 53: 2.0**-53}
feeds = list(range(C)) + [C * r for r in range(1, 5)]  # top row and four junctions down the left side
A, F64, nA, n_inv, n_w, xs, b, exact = setup(feeds, 2.0)
kap = nA * n_inv; f32 = lambda v: struct.unpack('<f', struct.pack('<f', v))[0]
print(f"network: {N} junctions, {2 * R * (C - 1)} grid pipes + {len(feeds)} feed pipes; A is {N} by {N}")
print(f"norm A {nA:.2f}  norm A^-1 {n_inv:.4f} (full inverse) {n_w:.4f} (A^-1 x ones)  kappa {kap:.2f}")
print(f"unit roundoff: half {U[11]:.2e}  single {U[24]:.2e}  double {U[53]:.2e}")
print(f"kappa x u: half {kap * U[11]:.2f}  single {kap * U[24]:.2e}  double {kap * U[53]:.2e}")
print(f"true drawdowns: largest {max(xs):.6f} m; demands {min(b):.7f} to {max(b):.7f} L/s; exact: {exact}")
assert exact and abs(n_inv - n_w) < 1e-12 * n_w and 1e3 < kap < 2e3
def eta_G(F):  # eta = |PA - LU|/|A| and |G| = |I - F^-1 A| for the factors F
    a = F[0]; rows = [[a[i][j] if j >= i else 0.0 for j in range(N)] for i in range(N)]
    for i in range(N):  # rows of L times U, in double: products of singles or halves are exact
        for k in F[2][i]:
            for j in range(k, N): rows[i][j] += a[i][k] * a[k][j]
    M = [solve(F, [A[i][j] for i in range(N)], 53) for j in range(N)]  # columns of F^-1 A
    return (max(sum(abs(A[F[1][i]][j] - rows[i][j]) for j in range(N)) for i in range(N)) / nA,
            max(sum(abs((1.0 if i == j else 0.0) - M[j][i]) for j in range(N)) for i in range(N)))
F32 = lu(A, 24); a32 = F32[0]; eta, nG = eta_G(F32)
lib = sum(f32(v) == v for row in a32 for v in row)
print(f"single LU: swaps {F32[4]}, eta = |PA - LU|/|A| {eta:.2e} = {eta / U[24]:.2f} u_single, library f32 agrees on {lib} of {N * N}")
print(f"|G| = |I - F^-1 A| {nG:.2e} <= kappa eta/(1 - kappa eta) {kap * eta / (1 - kap * eta):.2e}")
assert lib == N * N and nG <= kap * eta / (1 - kap * eta) and nG < 1
mix, dmix = refine(A, F32, b, xs, 24, 53, 53, 8); fix, _ = refine(A, F32, b, xs, 24, 24, 24, 8)
F16 = lu(A, 11); hal, _ = refine(A, F16, b, xs, 11, 53, 53, 8); eh, gh = eta_G(F16)
print("step  mixed: single LU,  |d|/|x|   fixed: all     half LU,")
print("      double residual               single         double residual")
for k in range(9):
    print(f"{k:3d}   {mix[k]:.2e}  {dmix[k - 1] if k else 0.0:10.2e}    {fix[k]:.2e}       {hal[k]:.2e}")
x0 = solve(F32, b, 24); e0 = [x0[i] - xs[i] for i in range(N)]
ge = [e0[i] - v for i, v in enumerate(solve(F32, matvec(A, e0), 53))]  # G e0, the proof's prediction of e1
r1 = norm(ge) / norm(xs)
rat = mix[1] / mix[0]; bnd = kap * eta / (1 - kap * eta)
print(f"step ratios {rat:.2e} {mix[2] / mix[1]:.2e}; |G| is {nG / rat:.1f} times the first, the bound {bnd / rat:.1f} times")
print(f"proof's G e0 predicts e1 {r1:.2e}; observed e1 / predicted {mix[1] / r1:.3f}")
stop = next(k for k in range(1, 8) if dmix[k] <= U[53] or dmix[k] > dmix[k - 1] / 2)
xd = solve(F64, b, 53); ed = norm([xd[i] - xs[i] for i in range(N)]) / norm(xs)
print(f"stop test passes at step {stop + 1}: error {mix[stop + 1]:.2e}; floor kappa x u_double {kap * U[53]:.2e}; double LU {ed:.2e}")
assert mix[1] < kap * U[24] * mix[0] and mix[2] < 1e-14 and max(mix[3:]) < kap * U[53] and abs(mix[1] / r1 - 1) < 0.1
assert min(fix) > 10 * U[24] and hal[8] < 1e-5 and hal[8] < hal[4] < hal[0] and kap * eh > 0.5 and all(hal[k + 1] < gh * hal[k] for k in range(8))
f_cost = (4 * N**3 - 3 * N**2 - N) // 6; s_cost = 2 * N * N + (2 * N * N - N) + N
print(f"flops n = {N}: factor {f_cost:,} (single), each step {s_cost:,} = 4n^2, {stop + 1} steps {(stop + 1) * s_cost / f_cost:.2%} of the factor")
tiny = sum(1 for row in F16[0] for v in row if 0.0 < abs(v) < 2.0**-14)
print(f"half LU: {tiny} factor entries below 6.10e-5, half precision's smallest normal number (range ignored here)")
print(f"half LU: swaps {F16[4]}, eta {eh:.2e} = {eh / U[11]:.2f} u_half, kappa eta {kap * eh:.2f} > 1/2, yet |G| {gh:.3f} < 1; step ratio {hal[1] / hal[0]:.2f}")
Aw, Fw64, nAw, niw, _, xw, bw, ex2 = setup([0], 2.0**-4); kw = nAw * niw
hw, _ = refine(Aw, lu(Aw, 11), bw, xw, 11, 53, 53, 12); sw, _ = refine(Aw, lu(Aw, 24), bw, xw, 24, 53, 53, 3)
xsg, _ = refine(A, F32, b, xs, 24, 53, 24, 8)
print(f"weak feed (one pipe, 0.0625 L/s per m): kappa {kw:.2f}, kappa x u_half {kw * U[11]:.1f}, exact: {ex2}")
print(f"  half LU after 12 steps: error {hw[12]:.3e} (start {hw[0]:.3e}); single LU after 3 steps: {sw[3]:.2e}")
print(f"wrong: no refinement {mix[0]:.2e}; answer kept in single {min(xsg[1:]):.2e} to {max(xsg[1:]):.2e}")
print(f"wrong: residual and answer in single {min(fix[1:]):.2e} to {max(fix[1:]):.2e}")
assert ex2 and kw * U[11] > 1 and hw[12] > 0.1 and sw[3] < 1e-11 and min(xsg[1:]) > 0.1 * U[24]
lg = lambda v: f"{math.log10(v):6.1f}"
print("chart, step         " + " ".join(f"{k:6d}" for k in range(9)))
for name, e in (("mixed", mix), ("fixed", fix), ("half ", hal)):
    print(f"chart, log10 {name}  " + " ".join(lg(v) for v in e))
n2 = 1000; f2 = (4 * n2**3 - 3 * n2**2 - n2) // 6
print(f"try: half steps to 1e-12: {next(k for k, v in enumerate(refine(A, F16, b, xs, 11, 53, 53, 30)[0]) if v < 1e-12)}; n = 1000: {stop + 1} steps {(stop + 1) * 4 * n2 * n2 / f2:.2%} of the factor")
print("ALL CHECKS PASS")
