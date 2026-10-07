# Level, slope and curvature -- the check behind the card.  Standard library only.
# 500 synthetic daily changes of the slice E zero curve at its six pillars, then PCA
# two ways: Jacobi rotations and power iteration.  Nothing imported knows the answer.
from math import log, sqrt, cos, pi, exp

T = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0]
D = {0.0: 1.0, 0.5: 1 / 1.02, 1.0: 1 / 1.042}                  # the two deposits
for n, s in ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)):  # the bootstrap ladder
    D[float(n)] = (1.0 - s * sum(D[float(j)] for j in range(1, n))) / (1.0 + s)
ZERO = [-log(D[t]) / t * 1e4 for t in T]                        # zero rates in bp, continuous

state = 20260928                                                # our own random numbers
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2.0**53
def gauss():
    u1 = unif(); u2 = unif()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)            # Box-Muller

SLOPE = [(t - 2.5) / 2.5 for t in T]                            # shapes used only to make data
BEND = [1.0 - 2.0 * ((t - 2.5) / 2.5) ** 2 for t in T]
X = []
for day in range(500):                                          # bp changes, one row a day
    lv, sl, cv = 5.0 * gauss(), 2.0 * gauss(), 1.0 * gauss()
    X.append([lv + sl * SLOPE[i] + cv * BEND[i] + 1.3 * gauss() for i in range(6)])

def cov(rows):                                                  # centred, divide by n
    n, m = len(rows), len(rows[0])
    mu = [sum(r[j] for r in rows) / n for j in range(m)]
    return [[sum((r[i] - mu[i]) * (r[j] - mu[j]) for r in rows) / n for j in range(m)] for i in range(m)]

def jacobi(A):                                                  # road 1: rotate until diagonal
    m = len(A); A = [row[:] for row in A]
    V = [[float(i == j) for j in range(m)] for i in range(m)]
    for sweep in range(100):
        off = sum(A[i][j] ** 2 for i in range(m) for j in range(m) if i != j)
        if off < 1e-24: break
        for p in range(m):
            for q in range(p + 1, m):
                if abs(A[p][q]) < 1e-300: continue
                th = (A[q][q] - A[p][p]) / (2.0 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1.0))
                c = 1.0 / sqrt(t * t + 1.0); s = t * c
                for k in range(m):
                    akp, akq = A[k][p], A[k][q]
                    A[k][p], A[k][q] = c * akp - s * akq, s * akp + c * akq
                for k in range(m):
                    apk, aqk = A[p][k], A[q][k]
                    A[p][k], A[q][k] = c * apk - s * aqk, s * apk + c * aqk
                for k in range(m):
                    vkp, vkq = V[k][p], V[k][q]
                    V[k][p], V[k][q] = c * vkp - s * vkq, s * vkp + c * vkq
    pairs = sorted(((A[i][i], [V[k][i] for k in range(m)]) for i in range(m)), key=lambda p: -p[0])
    return [p[0] for p in pairs], [p[1] for p in pairs]

def power(A, k):                                                # road 2: multiply, deflate, repeat
    m = len(A); A = [row[:] for row in A]; vals, vecs = [], []
    for _ in range(k):
        v = [1.0 + 0.1 * i for i in range(m)]
        for it in range(3000):
            w = [sum(A[i][j] * v[j] for j in range(m)) for i in range(m)]
            nw = sqrt(sum(x * x for x in w)); v = [x / nw for x in w]
        lam = sum(v[i] * A[i][j] * v[j] for i in range(m) for j in range(m))
        vals.append(lam); vecs.append(v)
        A = [[A[i][j] - lam * v[i] * v[j] for j in range(m)] for i in range(m)]
    return vals, vecs

def orient(vecs):                                               # fix the arbitrary signs
    tests = [lambda v: sum(v), lambda v: v[-1] - v[0], lambda v: v[2] + v[3] - v[0] - v[-1]]
    return [[-x for x in v] if tests[k](v) < 0 else v for k, v in enumerate(vecs)]

def share3(rows):
    lam = jacobi(cov(rows))[0]
    return sum(lam[:3]) / sum(lam), lam[0] / sum(lam)
S = cov(X)
lam, U = jacobi(S); U = orient(U[:3])
plam, PU = power(S, 3); PU = orient(PU)
trace = sum(S[i][i] for i in range(6))
dot = lambda a, b: sum(x * y for x, y in zip(a, b))
mu = [sum(r[j] for r in X) / 500 for j in range(6)]
Z = [[r[j] - mu[j] for j in range(6)] for r in X]
resid = sum(dot(z, z) - sum(dot(z, u) ** 2 for u in U) for z in Z) / 500   # leftover, day by day
sc = [[dot(z, u) for u in U] for z in Z]
offcov = max(abs(sum(s[a] * s[b] for s in sc) / 500) for a in range(3) for b in range(a + 1, 3))

def gram(vs):                                                   # hand-made flat / line / bowl
    out = []
    for v in vs:
        for u in out: v = [x - dot(v, u) * y for x, y in zip(v, u)]
        nv = sqrt(dot(v, v)); out.append([x / nv for x in v])
    return out
H = gram([[1.0] * 6, T, [t * t for t in T]])
hand = sum(sum(S[i][j] * h[i] * h[j] for i in range(6) for j in range(6)) for h in H) / trace
LEV = []; y = ZERO[:]
for r in X:
    y = [a + b for a, b in zip(y, r)]; LEV.append(y)
sd = [sqrt(S[i][i]) for i in range(6)]
PCT = [r[:5] + [r[5] / 100.0] for r in X]                       # the 5-year column left in percent

f = lambda v: " ".join(f"{x:8.4f}" for x in v)
print("tenor, years          " + " ".join(f"{t:8.1f}" for t in T))
print("slice E zero, %       " + f([z / 100 for z in ZERO]))
print("sd of daily change bp " + f(sd))
print(f"total variance, bp^2  {trace:10.4f}")
print("eigenvalues, Jacobi   " + f(lam))
print("eigenvalues, power    " + f(plam))
print("share of each, %      " + f([100 * l / trace for l in lam]))
print("cumulative share, %   " + f([100 * sum(lam[:k + 1]) / trace for k in range(6)]))
for k, name in enumerate(("level", "slope", "curvature")):
    print(f"{name + ' loading':<22}" + f(U[k]))
    print(f"{name + ' (power road)':<22}" + f(PU[k]))
print("factor sd, bp a day   " + f([sqrt(l) for l in lam[:3]]))
print(f"leftover, direct bp^2 {resid:10.4f}")
print(f"leftover, l4+l5+l6    {sum(lam[3:]):10.4f}")
print(f"largest score cov     {offcov:10.4f}")
print(f"wrong: hand shapes, % {100 * hand:10.4f}")
lv3, lv1 = share3(LEV)
print(f"wrong: levels 1st, %  {100 * lv1:10.4f}")
print(f"wrong: levels 3, %    {100 * lv3:10.4f}")
print(f"wrong: 5y %, 5y load  {orient(jacobi(cov(PCT))[1][:1])[0][5]:10.4f}")
print(f"wrong: 3 tenors, %    {100 * share3([[r[1], r[3], r[5]] for r in X])[0]:10.4f}")
print("house: 3-sd shock of each factor on the slice E curve")
price = lambda z: 100.0 * exp(-z[5] / 1e4 * 5.0)
rows = [("base", ZERO)]
for k, name in enumerate(("level", "slope", "curvature")):
    mv = [3.0 * sqrt(lam[k]) * u for u in U[k]]
    rows.append((name, [z + m for z, m in zip(ZERO, mv)]))
    print(f"{'chart, ' + name + ' bp':<22}" + " ".join(f"{m:8.2f}" for m in mv))
    print(f"{'  zero % after':<22}" + f([(z + m) / 100 for z, m in zip(ZERO, mv)]))
print("5y zero-coupon, $100  " + " ".join(f"{n}={price(z):.4f}" for n, z in rows))

assert max(abs(a - b) for a, b in zip(lam, plam)) < 1e-8, "two eigen-solvers agree"
assert max(abs(a - b) for u, v in zip(U, PU) for a, b in zip(u, v)) < 1e-6, "same shapes"
assert abs(sum(lam) - trace) < 1e-9, "eigenvalues add up to the total variance"
assert abs(resid - sum(lam[3:])) < 1e-8, "day-by-day leftover equals the dropped eigenvalues"
assert offcov < 1e-8, "factor scores are uncorrelated"
assert hand < sum(lam[:3]) / trace, "no other three shapes capture more"
assert 0.965 < sum(lam[:3]) / trace < 0.975, "about 97 percent in three factors"
print("ALL CHECKS PASS")
