# The graph Laplacian and spectral clustering -- the check behind the card.  Standard library only.
# The network is synthetic, generated here from seed 2026 by SplitMix64.  Eigenvalues come from
# Jacobi rotations (six friends) and power iteration (5,000 people); pieces are counted by flooding.
from math import sqrt
MASK = (1 << 64) - 1

class SplitMix:                       # SplitMix64: the same stream in Python and Rust
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def towns(n, inside, across, seed):   # synthetic: two towns of n/2, random distinct pairs
    rng, half, seen, edges = SplitMix(seed), n // 2, set(), []
    def add(u, v):
        key = (min(u, v), max(u, v))
        if u == v or key in seen: return 0
        seen.add(key); edges.append(key); return 1
    for base in (0, half):
        made = 0
        while made < inside: made += add(base + rng.next() % half, base + rng.next() % half)
    while across > 0: across -= add(rng.next() % half, half + rng.next() % half)
    return edges

def neighbours(n, edges):
    nb = [[] for _ in range(n)]
    for u, v in edges: nb[u].append(v); nb[v].append(u)
    return nb

def lap(nb, x):                       # L x, never storing L: degree times own value minus neighbours'
    return [len(nb[i]) * x[i] - sum(x[j] for j in nb[i]) for i in range(len(nb))]

def rayleigh(edges, x):               # x.Lx / x.x, with x.Lx summed edge by edge
    return sum((x[u] - x[v]) ** 2 for u, v in edges) / sum(v * v for v in x)

def power(nb, c, steps, deflate, r=None):  # repeat x <- c x - L x, rescaled; deflate removes the average
    n, rng = len(nb), SplitMix(7); r = r or [1.0] * n  # r: square-root degrees, for the normalised Laplacian
    x = [(rng.next() >> 11) / 2.0 ** 53 - 0.5 for _ in range(n)]
    for _ in range(steps):
        if deflate: m = sum(a * b for a, b in zip(x, r)) / sum(b * b for b in r); x = [v - m * b for v, b in zip(x, r)]
        y = lap(nb, [a / b for a, b in zip(x, r)]); x = [c * a - b / q for a, b, q in zip(x, y, r)]
        s = sqrt(sum(v * v for v in x)); x = [v / s for v in x]
    return x

def residual(nb, x, lam): return sqrt(sum((a - lam * b) ** 2 for a, b in zip(lap(nb, x), x)))
def judge(edges, x, n):               # read signs: side sizes, people in their right town, links cut
    side = [v > 0 for v in x]
    right = sum(side[i] == (i < n // 2) for i in range(n))
    return sum(side), max(right, n - right), sum(side[u] != side[v] for u, v in edges)

def jacobi(a):                        # all eigenvalues of a small symmetric matrix, by rotations
    a, n = [row[:] for row in a], len(a)
    for _ in range(50):
        for p in range(n):
            for q in range(p + 1, n):
                if abs(a[p][q]) < 1e-300: continue
                th = (a[q][q] - a[p][p]) / (2 * a[p][q])
                t = (1 if th >= 0 else -1) / (abs(th) + sqrt(th * th + 1))
                c = 1 / sqrt(t * t + 1); s = t * c
                for k in range(n):
                    akp, akq = a[k][p], a[k][q]
                    a[k][p], a[k][q] = c * akp - s * akq, s * akp + c * akq
                for k in range(n):
                    apk, aqk = a[p][k], a[q][k]
                    a[p][k], a[q][k] = c * apk - s * aqk, s * apk + c * aqk
    return sorted(a[i][i] for i in range(n))

def pieces(nb):                       # count connected pieces by flooding, no eigenvalues at all
    seen, count = [False] * len(nb), 0
    for s in range(len(nb)):
        if seen[s]: continue
        count += 1; seen[s] = True; stack = [s]
        while stack:
            for w in nb[stack.pop()]:
                if not seen[w]: seen[w] = True; stack.append(w)
    return count

def f6(vs): return " ".join(f"{v:.6f}" if abs(v) > 5e-7 else "0.000000" for v in vs)
def matrix(n, edges):
    nb = neighbours(n, edges)
    return [[len(nb[i]) if i == j else -(j in nb[i]) for j in range(n)] for i in range(n)]

# ---- six friends: Ana Ben Cal | Dev Eve Fay, one bridge Cal-Dev ----
SIX = [(0, 1), (0, 2), (1, 2), (2, 3), (3, 4), (3, 5), (4, 5)]
ev = jacobi(matrix(6, SIX))
closed = (5 - sqrt(17)) / 2
f = power(neighbours(6, SIX), 6.0, 400, True); f = [v / f[0] for v in f]
print("six: degrees", [len(r) for r in neighbours(6, SIX)], " Cal's row", matrix(6, SIX)[2])
print("six: eigenvalues", f6(ev))
print(f"six: lambda2 Jacobi {ev[1]:.6f}  (5 - sqrt 17)/2 {closed:.6f}  Rayleigh {rayleigh(SIX, f):.6f}")
print("six: Fiedler vector, Ana = 1:", f6(f), " links cut", judge(SIX, f, 6)[2],
      f" edge sum {sum((f[u] - f[v]) ** 2 for u, v in SIX):.6f}  length^2 {sum(v * v for v in f):.6f}")
ev0 = jacobi(matrix(6, SIX[:3] + SIX[4:])); zeros = sum(abs(v) < 1e-9 for v in ev0)
print("six, bridge cut: eigenvalues", f6(ev0), f" zeros {zeros}  pieces by flood",
      pieces(neighbours(6, SIX[:3] + SIX[4:])), " exactly 0.0:", sum(v == 0.0 for v in ev0))
prod = ev[1] * ev[2] * ev[3] * ev[4] * ev[5]
trees = sum(pieces(neighbours(6, [e for i, e in enumerate(SIX) if i not in (a, b)])) == 1
            for a in range(7) for b in range(a + 1, 7))
print(f"six: product of nonzero eigenvalues / 6 = {prod / 6:.6f}  spanning trees by listing {trees}"
      f"  4 x cut / n for Ana Ben Cal | Dev Eve Fay {4 * 1 / 6:.6f}")
assert abs(ev[1] - closed) < 1e-9 and abs(rayleigh(SIX, f) - closed) < 1e-9 and judge(SIX, f, 6)[2] == 1
assert zeros == 2 == pieces(neighbours(6, SIX[:3] + SIX[4:])) and round(prod / 6) == trees == 9
# ---- 5,000 people in two towns of 2,500: 25,000 links inside each town, 1,250 across ----
N, IN, ACROSS = 5000, 25000, 1250
E = towns(N, IN, ACROSS, 2026); nb = neighbours(N, E)
deg = [len(r) for r in nb]
print(f"big: people {N}  links {len(E)} = 2 x {IN} inside + {ACROSS} across  degree min {min(deg)} mean {sum(deg) / N:.6f} max {max(deg)}")
top = power(nb, 0.0, 300, False); lmax = rayleigh(E, top); c = lmax + 1
x = power(nb, c, 400, True); lam2 = rayleigh(E, x); size, right, cut = judge(E, x, N); bound = 4 * ACROSS / N
print(f"big: largest eigenvalue, 300-step estimate {lmax:.6f}  shift c {c:.6f}")
print(f"big: lambda2 {lam2:.6f}  residual below 1e-9 {'yes' if residual(nb, x, lam2) < 1e-9 else 'no'}  bound 4 x 1250 / 5000 {bound:.6f}")
print(f"big: sign split {size} | {N - size}  in their right town {right}  links cut {cut}")
s = sorted(v * sqrt(N) for v in x)
print("chart, rank:entry x sqrt(n):", " ".join(f"{min(i * 250, N - 1) + 1}:{s[min(i * 250, N - 1)]:.2f}" for i in range(21)))
assert lam2 <= bound and right == N and cut == ACROSS and residual(nb, x, lam2) < 1e-6 and pieces(nb) == 1
Ecut = [e for e in E if (e[0] < N // 2) == (e[1] < N // 2)]
z = power(neighbours(N, Ecut), c, 200, True)
print(f"big, the 1250 across removed: lambda2 {f6([rayleigh(Ecut, z)])}  pieces by flood {pieces(neighbours(N, Ecut))}")
assert rayleigh(Ecut, z) < 1e-9 and pieces(neighbours(N, Ecut)) == 2
# ---- what breaks ----
w = power(nb, c, 400, False); ws = judge(E, w, N)[0]
print(f"mistake, average not removed: value {f6([rayleigh(E, w)])}  split {ws} | {N - ws}")
ts, tr, tc = judge(E, top, N)
print(f"mistake, top eigenvector after 300 steps: split {ts} | {N - ts}  in right town {tr}  links cut {tc} of {len(E)}")
Et = E + [(0, 5000), (5000, 5001), (5001, 5002)]
t = power(neighbours(N + 3, Et), c, 1000, True); weight = sum(v * v for v in t[N:]) + t[0] ** 2
ts, tr, tc = judge(Et, t, N)
print(f"tail of 3 on person 0: lambda2 {rayleigh(Et, t):.6f}  weight on the 4 {weight:.6f}  "
      f"split {ts} | {N + 3 - ts}  right town {tr}  links cut {tc}")
assert rayleigh(Et, t) < lam2 and weight > 0.5
for across in (10000, 20000):
    Ew = towns(N, IN, across, 2026); nw = neighbours(N, Ew); xw = power(nw, c, 400, True)
    xn = power(nw, 2.0, 400, True, [sqrt(len(a)) for a in nw]); (sw, rw, _), rn = judge(Ew, xw, N), judge(Ew, xn, N)[1]
    print(f"try: {across} across (each person: {2 * IN / (N / 2):.0f} home, {across / (N / 2):.0f} across), lambda2 {rayleigh(Ew, xw):.4f}  town split 4 x cut / n {4 * across / N:.6f}  sign split {sw} | {N - sw}  in their right town {rw}  normalised L {rn}")
x30 = power(nb, c, 30, True)
print(f"try: 30 steps only, in their right town {judge(E, x30, N)[1]}  lambda2 {rayleigh(E, x30):.6f}")
print("ALL CHECKS PASS")
