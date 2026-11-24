# Algebraic multigrid -- the check behind the card.  Standard library only.  A Ruge-Stuben hierarchy
# from the matrix alone, on a pipe network and an anisotropic plate, against geometric MG, IC(0) and CG.
import heapq, itertools; from math import sqrt, cos, sin, pi
M64, state = (1 << 64) - 1, [20261124]
def nxt():                                   # SplitMix64, written out
    state[0] = z = (state[0] + 0x9E3779B97F4A7C15) & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def sci(v): m, x = f"{v:.3e}".split("e"); return m + "e" + str(int(x))  # as Rust
def rdot(r, x):                              # a sparse row, pairs (j, a), times the vector x
    acc = 0.0
    for j, a in r: acc += a * x[j]
    return acc
def dot(u, v): return rdot(enumerate(u), v)
def mv(A, x): return [rdot(r, x) for r in A]
def nnz(A): return sum(len(r) for r in A)
def rows(d): return [sorted(r.items()) for r in d]
def off(r, i): return [(j, a) for j, a in r if j != i]
def strong(A, th):                           # j is strong for i if -a_ij >= th * (largest -a_ik)
    big = [max(-a for _, a in off(r, i)) for i, r in enumerate(A)]
    return [[j for j, a in off(r, i) if big[i] > 0 and -a >= th * big[i]] for i, r in enumerate(A)]
def split(S):                                # Ruge-Stuben first pass: 1 = C point, 0 = F point
    n = len(S); ST, cf = [[] for _ in range(n)], [-1] * n
    for i, j in ((i, j) for i in range(n) for j in S[i]): ST[j].append(i)   # ST[j]: depend strongly on j
    lam = [len(t) for t in ST]; heap = [(-lam[i], i) for i in range(n)]; heapq.heapify(heap)
    def bump(k, d): lam[k] += d; heapq.heappush(heap, (-lam[k], k))
    while heap:
        l, i = heapq.heappop(heap)
        if cf[i] != -1 or -l != lam[i]: continue
        cf[i] = 1
        for j in [j for j in ST[i] if cf[j] == -1]:
            cf[j] = 0
            for k in [k for k in S[j] if cf[k] == -1]: bump(k, 1)
        for k in [k for k in S[i] if cf[k] == -1]: bump(k, -1)
    return cf
def interp(A, S, cf, scale=True):            # direct interpolation, Stuben (2001)
    ci = list(itertools.accumulate([0] + cf[:-1])); P = []
    for i, r in enumerate(A):
        Pi = [j for j in S[i] if cf[j]]; neg = negP = dg = 0.0
        for j, a in r:
            if j == i or a > 0: dg += a      # a positive entry joins the diagonal
            else: neg += a; negP += a if j in Pi else 0.0
        P.append([(ci[i], 1.0)] if cf[i] else [(ci[j], -(neg / negP if scale else 1.0) * a / dg) for j, a in r if j in Pi])
    return P, sum(cf)
def rap(A, P, nc):                           # Galerkin coarse matrix P^T A P, and its flops
    Ac, fl = [dict() for _ in range(nc)], 0
    for i, r in enumerate(A):
        d = {}
        for j, a in r:
            for J, w in P[j]: d[J] = d.get(J, 0.0) + a * w; fl += 2
        for I, p in P[i]:
            for J, v in sorted(d.items()): Ac[I][J] = Ac[I].get(J, 0.0) + p * v; fl += 2
    return rows(Ac), fl
def setup(A, Ps=None, th=0.25, scale=True):  # Ps given: geometric coarsening instead
    lv, fl = [[A, None]], 0
    while len(lv[-1][0]) > 50 and (Ps is None or len(lv) <= len(Ps)):
        S = strong(lv[-1][0], th); P, nc = Ps[len(lv) - 1] if Ps else interp(lv[-1][0], S, split(S), scale)
        Ac, f = rap(lv[-1][0], P, nc); fl += f; lv[-1][1] = P; lv.append([Ac, None])
    return lv, ic0([[(j, dict(r).get(j, 0.0)) for j in range(len(lv[-1][0]))] for r in lv[-1][0]]), fl   # IC(0) of a full matrix: exact
def ic0(A):                                  # incomplete Cholesky: keep A's own nonzeros only
    L = []
    for i, r in enumerate(A):
        row = {}
        for k, a in [(k, a) for k, a in r if k < i]: row[k] = (a - rdot([(j, v) for j, v in row.items() if j in L[k][0]], L[k][0])) / L[k][1]
        L.append((row, sqrt(dict(r)[i] - rdot(row.items(), row))))
    return L
def icsolve(L, r):                           # L y = r, then L^T z = y
    y = r[:]
    for i in range(len(r)): y[i] = (y[i] - rdot(L[i][0].items(), y)) / L[i][1]
    for i in range(len(r) - 1, -1, -1):
        y[i] /= L[i][1]
        for k, v in L[i][0].items(): y[k] -= v * y[i]
    return y
def gs(A, x, b, order):                      # one Gauss-Seidel sweep
    for i in order: x[i] = (b[i] - rdot(off(A[i], i), x)) / dict(A[i])[i]
def vcyc(H, b, l=0):                         # one V-cycle, starting from x = 0
    if H[0][l][1] is None: return icsolve(H[1], b)   # coarsest level: solve exactly
    A, P = H[0][l]; n = len(A); x = [0.0] * n; gs(A, x, b, range(n))
    r = [u - v for u, v in zip(b, mv(A, x))]; rc = [0.0] * len(H[0][l + 1][0])
    for i, I, w in ((i, I, w) for i in range(n) for I, w in P[i]): rc[I] += w * r[i]
    ec = vcyc(H, rc, l + 1); x = [u + rdot(p, ec) for u, p in zip(x, P)]
    gs(A, x, b, range(n - 1, -1, -1)); return x
def pcg(A, b, M, tol=1e-8):                  # preconditioned conjugate gradient
    x, r = [0.0] * len(b), b[:]; z = M(r); p = z[:]; rz, nb, h = dot(r, z), sqrt(dot(b, b)), [1.0]
    while h[-1] >= tol and len(h) <= 2 * len(b):  # CG needs at most n steps without rounding; allow 2n
        q = mv(A, p); a = rz / dot(p, q); x = [u + a * v for u, v in zip(x, p)]; r = [u - a * v for u, v in zip(r, q)]
        z = M(r); rz2 = dot(r, z); be = rz2 / rz; p = [u + be * v for u, v in zip(z, p)]; rz = rz2
        h.append(sqrt(dot(r, r)) / nb)
    assert h[-1] < tol, "CG did not converge"; return x, h
def vfactor(A, b, H, k=10):                  # V-cycles alone: residual factor per cycle
    x = [0.0] * len(b)
    for _ in range(k + 1): r = [u - v for u, v in zip(b, mv(A, x))]; x = [u + v for u, v in zip(x, vcyc(H, r))]
    return (sqrt(dot(r, r)) / sqrt(dot(b, b))) ** (1.0 / k)
def vflops(lv): return sum(6 * nnz(A) + 4 * nnz(P) + 2 * len(A) for A, P in lv[:-1]) + 2 * len(lv[-1][0]) ** 2
def levels(H): return "/".join(str(len(l[0])) for l in H[0])
def network():                               # 10 rows of 25 junctions, 465 + 35 pipes
    d, b = [{i: 0.1} for i in range(250)], [0.0] * 250   # customers: 0.1 L/s per metre of head
    for i in range(250):
        for j in ([i + 1] if i % 25 < 24 else []) + ([i + 25] if i < 225 else []) + [-1] * ((i < 25) + (i % 25 == 0)):
            g = [0.5, 1.0, 2.0, 4.0][nxt() % 4]; d[i][i] += g   # pipe sizes, L/s per metre
            if j < 0: b[i] += 50.0 * g       # a feed from the main at 50 m
            else: d[j][j] += g; d[i][j] = d[j][i] = -g
    return rows(d), b
def plate(N, e):                             # conductivity 1 along x, e along y; heater at centre
    d = [{k: 2.0 + 2.0 * e} for k in range(N * N)]; b = [0.0] * (N * N); b[N * N // 2] = 1.0
    for k in range(N * N):
        for m, c, ok in ((k - 1, 1.0, k % N > 0), (k + 1, 1.0, k % N < N - 1), (k - N, e, k >= N), (k + N, e, k < N * N - N)):
            if ok: d[k][m] = -c
    return rows(d), b
def geo(N):                                  # bilinear interpolation, every other point both ways
    Ps = []
    while N * N > 50:
        n = (N - 1) // 2; w1 = lambda i: [((i - 1) // 2, 1.0)] if i % 2 else [(k, 0.5) for k in (i // 2 - 1, i // 2) if 0 <= k < n]
        Ps.append(([sorted((J * n + I, a * c) for J, a in w1(k // N) for I, c in w1(k % N)) for k in range(N * N)], n * n)); N = n
    return Ps
def mu(e):                                   # Gauss-Seidel smoothing factor over high frequencies
    cs = [(cos(p * pi / 128), sin(p * pi / 128), abs(p) >= 64) for p in range(-128, 128)]
    return max(sqrt(((c1 + e * c2) ** 2 + (s1 + e * s2) ** 2) / ((2 + 2 * e - c1 - e * c2) ** 2 + (s1 + e * s2) ** 2)) for c1, s1, h1 in cs for c2, s2, h2 in cs if h1 or h2)
def three(A, b, H): L = ic0(A); return [pcg(A, b, M) for M in (lambda r: r, lambda r: icsolve(L, r), lambda r: vcyc(H, r))]
A3 = [[(0, 4.6), (1, -4.0), (2, -0.5)], [(0, -4.0), (1, 4.1)], [(0, -0.5), (2, 0.6)]]; S3 = strong(A3, 0.25); P3, _ = interp(A3, S3, [0, 1, 1]); w = (4.5 / 4.0) * 4.0 / 4.6
print(f"hand,cut={0.25 * 4.0:.2f},junction1_strong_to=" + "+".join(str(j + 1) for j in S3[0]) + f",alpha={4.5 / 4.0:.4f},weight={w:.6f},code={P3[0][0][1]:.6f}")
ms = [mu(e) for e in (1.0, 0.1, 0.01, 0.001)]; print("smoothing,eps=1/0.1/0.01/0.001,gauss_seidel_mu=" + "/".join(f"{m:.4f}" for m in ms))
assert S3[0] == [1] and abs(P3[0][0][1] - w) < 1e-15 and abs(ms[0] - 0.5) < 1e-3 and all(abs(m - (1 - 2 * e)) < 5 * e * e for m, e in zip(ms[2:], (0.01, 0.001)))
A, b = network(); H = setup(A); runs = three(A, b, H); x = runs[2][0]   # the network: no grid used
r = [u - v for u, v in zip(b, mv(A, x))]; tr = sqrt(dot(r, r) / dot(b, b)); gap = max(abs(u - v) for y, _ in runs[:2] for u, v in zip(y, x))
print(f"network,junctions={len(A)},nonzeros={nnz(A)},levels={levels(H)},operator_complexity={sum(nnz(l[0]) for l in H[0]) / nnz(A):.3f},vcycle_factor={vfactor(A, b, H):.4f}")
print("network,cg_steps_plain/ic0/amg=" + "/".join(str(len(h) - 1) for _, h in runs) + f",true_residual={sci(tr)},max_gap_m={sci(gap)},heads_m={max(x):.4f}..{min(x):.4f}")
assert tr < 1.01e-8 and gap < 1e-4 and len(runs[2][1]) < len(runs[1][1]) < len(runs[0][1]); fac = {}
for e, name, args in (("0.01", "amg", ()), ("0.01", "geometric", (geo(63),)), ("0.01", "theta_0", (None, 0.0)), ("0.01", "no_alpha", (None, 0.25, False)), ("1", "amg", ()), ("1", "geometric", (geo(63),))):
    A, b = plate(63, float(e)); H = setup(A, *args); fac[e, name] = vfactor(A, b, H); print(f"plate63,eps={e},{name},levels={levels(H)},vcycle_factor={fac[e, name]:.4f}")
assert fac["0.01", "amg"] < 0.3 < fac["0.01", "geometric"] and max(fac["1", "amg"], fac["1", "geometric"]) < 0.3 and fac["0.01", "theta_0"] > 2 * fac["0.01", "amg"]
A, b = plate(63, 0.01); H = setup(A); S = strong(A, 0.25); cf = split(S); P, _ = interp(A, S, cf); one = [1.0] * len(A)
ones = [abs(rdot(P[i], one) - 1.0) for i in range(len(A)) if not cf[i] and abs(rdot(A[i], one)) < 1e-12]; asym = max(abs(dict(Ac[J]).get(I, 0.0) - a) for Ac, _ in H[0] for I in range(len(Ac)) for J, a in Ac[I])
print(f"plate63,first_level,C={sum(cf)},F={len(cf) - sum(cf)},strong_per_row={nnz(S) / len(S):.3f},zero_sum_F_rows={len(ones)},max_weight_sum_minus_1={sci(max(ones))},coarse_asymmetry={sci(asym)}"); assert max(ones) < 1e-12 and asym < 1e-12 and nnz(S) == 2 * 63 * 62
for N in (31, 63, 127):
    A, b = plate(N, 0.01); H = setup(A); runs = three(A, b, H); n, z = len(A), nnz(A); k = [len(h) - 1 for _, h in runs]
    base = 2 * z + 10 * n; fl = [k[0] * base, k[1] * (base + 2 * z), k[2] * (base + vflops(H[0])) + H[2]]
    print(f"plate,N={N},unknowns={n},cg_steps={k[0]}/{k[1]}/{k[2]},flops_per_unknown={fl[0] / n:.0f}/{fl[1] / n:.0f}/{fl[2] / n:.0f},amg_setup={H[2]:,},vcycle={vflops(H[0]):,}"); assert k[2] <= 10 < k[1] < k[0] and max(abs(u - v) for u, v in zip(runs[1][0], runs[2][0])) < 1e-6 * max(runs[2][0])
print("ALL CHECKS PASS")
