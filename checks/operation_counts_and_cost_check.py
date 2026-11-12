# Counting the work: Cramer's rule against elimination on a 20 by 20 system.
# Standard library only. Every number on the card is printed here. Each flop
# (one + - * or / on two numbers) is counted where it happens, then compared
# with the formulas proved on the card.
import math

N, TILE, CACHE, NM = 20, 16, 1280, 48     # unknowns; tile, cache size and n for the memory model

def comma(k): return f"{k:,}"
def sci(x): m, e = f"{x:.2e}".split("e"); return f"{m}e{int(e)}"

def table(n):                            # M = 200(I - A): 200 on the diagonal, -a_ij * 200 off it
    return [[200.0 if i == j else -float((3 * i + 7 * j + 10) % 11) for j in range(n)] for i in range(n)]

def det_elim(M):                         # elimination to a staircase, then multiply the diagonal
    A, n, f, sign = [r[:] for r in M], len(M), 0, 1.0
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(A[r][k]))
        if p != k: A[k], A[p], sign = A[p], A[k], -sign
        for i in range(k + 1, n):
            m = A[i][k] / A[k][k]; f += 1
            for j in range(k + 1, n): A[i][j] -= m * A[k][j]; f += 2
    d = A[0][0]
    for k in range(1, n): d *= A[k][k]; f += 1
    return sign * d, f

def solve(M, b):                         # elimination with the right side, then back substitution
    A, n, f = [r[:] + [b[i]] for i, r in enumerate(M)], len(M), 0
    for k in range(n):
        p = max(range(k, n), key=lambda r: abs(A[r][k]))
        A[k], A[p] = A[p], A[k]
        for i in range(k + 1, n):
            m = A[i][k] / A[k][k]; f += 1
            for j in range(k + 1, n + 1): A[i][j] -= m * A[k][j]; f += 2
    x = [0.0] * n
    for i in reversed(range(n)):
        s = A[i][n]
        for j in range(i + 1, n): s -= A[i][j] * x[j]; f += 2
        x[i] = s / A[i][i]; f += 1
    return x, f

def cramer(M, b):                        # x_i = det(M with column i replaced by b) / det(M)
    D, f = det_elim(M); x = []
    for i in range(len(M)):
        Di, g = det_elim([r[:i] + [b[k]] + r[i + 1:] for k, r in enumerate(M)])
        x.append(Di / D); f += g + 1
    return x, f

def cofactor(M):                         # expansion along the top row, counted
    if len(M) == 1: return M[0][0], 0
    total, f = 0.0, 0
    for j in range(len(M)):
        sub, g = cofactor([r[:j] + r[j + 1:] for r in M[1:]])
        term = M[0][j] * sub; f += g + 1
        if j == 0: total = term
        else: total = total - term if j % 2 else total + term; f += 1
    return total, f

E = lambda n: (4 * n**3 + 9 * n**2 - 7 * n) // 6      # solve by elimination
D = lambda n: (4 * n**3 - 3 * n**2 + 5 * n - 6) // 6  # one determinant by elimination
K = lambda n: (n + 1) * D(n) + n                     # Cramer, determinants by elimination
def C(n): return 0 if n == 1 else n * C(n - 1) + 2 * n - 1   # one cofactor determinant
def C_series(n): return sum((2 * k - 1) * (math.factorial(n) // math.factorial(k)) for k in range(2, n + 1))
Q = lambda n: (n + 1) * C(n) + n                     # Cramer, determinants by cofactors

M = table(N); xt = [10.0 + i for i in range(1, N + 1)]   # known output, $ billion (illustrative)
b = [sum(M[i][j] * xt[j] for j in range(N)) for i in range(N)]
xe, fe = solve(M, b); xc, fc = cramer(M, b)
rel = lambda x: max(abs(x[i] - xt[i]) for i in range(N)) / max(xt)
print(f"system: n = {N}, M = 200(I - A), known x_1..x_20 = 11..30, b_1 = {b[0]:.0f}; M is {N * N} numbers, {8 * N * N:,} bytes")
print(f"elimination: x_1 = {xe[0]:.9f}, x_20 = {xe[-1]:.9f}, true error {sci(rel(xe))}")
print(f"Cramer:      x_1 = {xc[0]:.9f}, x_20 = {xc[-1]:.9f}, true error {sci(rel(xc))}")
print(f"det M = {sci(det_elim(M)[0])}")
print(f"counted, n = {N}: solve {comma(fe)}; Cramer by elimination {comma(fc)}; one det {comma(det_elim(M)[1])}")
print(f"formula, n = {N}: solve {comma(E(N))}; Cramer by elimination {comma(K(N))}; one det {comma(D(N))}; solve = {N * (N - 1) // 2} + {comma((N - 1) * N * (2 * N - 1) // 3)} + {N * (N - 1)} + {N * N}")
assert fe == E(N) and fc == K(N) and det_elim(M)[1] == D(N)
assert rel(xe) < 1e-13 and rel(xc) < 1e-13
cf = [cofactor([r[:n] for r in M[:n]]) for n in range(1, 9)]
print("cofactor flops counted, n = 1..8:", " ".join(str(f) for _, f in cf))
print("by recurrence:                   ", " ".join(str(C(n)) for n in range(1, 9)))
assert [f for _, f in cf] == [C(n) for n in range(1, 9)] == [C_series(n) for n in range(1, 9)]
d8 = det_elim([r[:8] for r in M[:8]])[0]
print(f"8 by 8 det: cofactors {sci(cf[7][0])}, elimination {sci(d8)}, relative gap {sci(abs(cf[7][0] - d8) / abs(d8))}")
assert abs(cf[7][0] - d8) < 1e-12 * abs(d8)
r20 = C(20) / math.factorial(20)
print(f"C(20) = {comma(C(20))}; C(20)/20! = {r20:.12f}; e = {math.e:.12f}")
assert C(20) == C_series(20) and abs(r20 - math.e) < 1e-12
print(f"Cramer by cofactors, n = {N}: {comma(Q(N))} = {sci(Q(N))} flops")
for n in (5, 10, 20, 30, 100, 1000, 10000):
    q = sci(Q(n)) if n <= 30 else "-"
    print(f"growth n = {n:>5}: solve {sci(E(n)):>8}  Cramer-elim {sci(K(n)):>8}  ratio {K(n) / E(n):7.1f}  Cramer-cofactor {q}")
yr = 1e11 * 365.25 * 86400
print(f"at an illustrative 1e11 flops/s: solve {sci(E(N) / 1e11)} s; Cramer-cofactor {Q(N) / yr:.1f} years")
for name, F in (("solve", E), ("Cramer-elim", K), ("Cramer-cofactor", Q)):
    print(f"chart, log10 {name}:", ", ".join(f"{math.log10(F(n)):.2f}" for n in range(2, 21, 2)))

def traffic(n, t, cache, blocked):       # numbers fetched by a cache that drops the least recent
    lru, miss, f = {}, 0, 0
    def touch(a):
        nonlocal miss
        if a in lru: del lru[a]
        else:
            miss += 1
            if len(lru) == cache: del lru[next(iter(lru))]
        lru[a] = 1
    step = t if blocked else n
    for ii in range(0, n, step):
        for jj in range(0, n, step):
            for kk in range(0, n, step):
                for i in range(ii, ii + step):
                    for j in range(jj, jj + step):
                        touch(2 * n * n + i * n + j)
                        for k in range(kk, kk + step):
                            touch(i * n + k); touch(n * n + k * n + j); f += 2
                        touch(2 * n * n + i * n + j)
    return f, miss

fn, mn = traffic(NM, TILE, CACHE, False); fb, mb = traffic(NM, TILE, CACHE, True)
pn, pb = NM**3 + 2 * NM**2, 2 * NM**3 // TILE + NM**2
print(f"memory: C = AB, n = {NM}, tile {TILE}, cache holds {CACHE} numbers")
print(f"plain loop: flops {comma(fn)}, numbers fetched {comma(mn)} (model {comma(pn)}), flops per number {fn / mn:.2f}")
print(f"tiled loop: flops {comma(fb)}, numbers fetched {comma(mb)} (model {comma(pb)}), flops per number {fb / mb:.2f}")
assert fn == fb == 2 * NM**3 and abs(mn - pn) < 0.02 * pn and abs(mb - pb) < 0.02 * pb
print(f"intensity, n = 20: matrix times vector {N * (2 * N - 1)}/{N * N + 2 * N} = {N * (2 * N - 1) / (N * N + 2 * N):.2f}; "
      f"matrix times matrix {N * N * (2 * N - 1)}/{3 * N * N} = {(2 * N - 1) / 3:.2f}")
peak, feed = 1e11, 2.5e9                 # illustrative: flops/s, and numbers/s from memory (20 GB/s)
big = 2e9 / (2e9 / 64 + 1e6)
print(f"illustrative machine: {peak / 1e9:.0f} Gflop/s, {8 * feed / 1e9:.0f} GB/s = {sci(feed)} numbers/s, balance {peak / feed:.0f} flops per number")
for name, I in (("plain loop", fn / mn), ("tile 16", fb / mb), ("tile 64, n = 1000", big)):
    print(f"  {name:<18} {I:6.2f} flops per number -> {min(peak, I * feed) / 1e9:6.2f} Gflop/s")
print(f"what breaks: multiplies and divides only, n = 20: {N * (N - 1) // 2 + (N - 1) * N * (2 * N - 1) // 6 + N * (N - 1) // 2 + N * (N + 1) // 2}")
print(f"what breaks: leading term 2n^3/3 at n = 5: {2 * 125 / 3:.1f}, exact {E(5)}")
print(f"what breaks: Cramer by elimination over solve, n = 20: {K(N) / E(N):.1f} times")
print(f"tracker: 10,000,000 plain adds = {comma(10**7)} flops; Kahan, 4 flops a step = {comma(4 * 10**7)}")
print(f"try: n = 10, Cramer-cofactor {comma(Q(10))}; tile 8 fetched {comma(traffic(NM, 8, CACHE, True)[1])}; "
      f"cache 8192, plain loop fetched {comma(traffic(NM, TILE, 8192, False)[1])}")
print("ALL CHECKS PASS")
