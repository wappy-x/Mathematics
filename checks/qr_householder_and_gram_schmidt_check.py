# QR two ways: the check behind the card.  Standard library only.
# 200 fuel readings (illustrative, simulated), one every 50 km.  Fit a line by
# Householder reflections and by Gram-Schmidt, test R against its closed form,
# measure lost orthogonality as the fitted degree rises, and count the flops.
from math import sqrt, log10
U = 2.0 ** -53                                   # unit roundoff of a double
def sci(v):                                      # 1.23e-10, the form Rust prints
    m, e = f"{v:.2e}".split("e"); return f"{m}e{int(e)}"
def rng(seed, M=(1 << 64) - 1):                  # SplitMix64, uniform in [0, 1)
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & M
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        yield ((z ^ (z >> 31)) >> 11) * U
FL = [0]                                         # flop counter for vector work
def dot(u, v):
    s = 0.0
    for a, b in zip(u, v): s += a * b
    FL[0] += 2 * len(u) - 1; return s
def axpy(f, v, w):                               # w - f v
    FL[0] += 2 * len(v); return [b - f * a for a, b in zip(v, w)]
def gram_schmidt(A, modified=False, passes=1):   # A, Q: lists of columns
    Q, R = [], [[0.0] * len(A) for _ in A]
    for j, a in enumerate(A):
        v = a
        for _ in range(passes):
            base = v                             # classical projects this, modified the running v
            for k in range(j):
                r = dot(Q[k], v if modified else base)
                v = axpy(r, Q[k], v)
                R[k][j] += r
        R[j][j] = sqrt(dot(v, v)); FL[0] += len(v)
        Q.append([b / R[j][j] for b in v])
    return Q, R
def householder(A):                              # the reflectors and R; Q is never formed
    W, V, n = [a[:] for a in A], [], len(A)
    for k in range(n):
        x = W[k][k:]
        nx = sqrt(dot(x, x))
        s = 1.0 if x[0] >= 0 else -1.0           # sign that avoids cancellation
        v = x[:]; v[0] += s * nx
        vv = 2.0 * nx * (nx + abs(x[0]))         # = v.v, without a second dot product
        V.append((v, vv))
        W[k][k:] = [-s * nx] + [0.0] * (len(x) - 1)
        for j in range(k + 1, n):
            W[j][k:] = axpy(2.0 * dot(v, W[j][k:]) / vv, v, W[j][k:])
    return V, [[W[j][i] if i <= j else 0.0 for j in range(n)] for i in range(n)]
def reflect(V, y, back=False):                   # H_n...H_1 y, or H_1...H_n y
    y = y[:]
    for k in (range(len(V) - 1, -1, -1) if back else range(len(V))):
        v, vv = V[k]
        y[k:] = axpy(2.0 * dot(v, y[k:]) / vv, v, y[k:])
    return y
def thin_q(V, m):                                # Q's n columns: the reflections applied to I's
    return [reflect(V, [1.0 if i == j else 0.0 for i in range(m)], True) for j in range(len(V))]
def loss(Q):                                     # largest entry of Q^T Q - I, in size
    return max(abs(dot(Q[i], Q[j]) - (1.0 if i == j else 0.0)) for i in range(len(Q)) for j in range(len(Q)))
def solve_r(R, z):                               # back substitution
    c = [0.0] * len(z)
    for i in range(len(z) - 1, -1, -1):
        s = z[i]
        for j in range(i + 1, len(z)): s -= R[i][j] * c[j]
        c[i] = s / R[i][i]
    return c
def smax(T):                                     # largest stretch, by power iteration on T^T T
    v, n = [1.0] * len(T), len(T)
    for _ in range(400):
        w = [dot(row, v) for row in T]
        w = [dot([row[j] for row in T], w) for j in range(n)]
        t = sqrt(dot(w, w)); v = [a / t for a in w]
    return sqrt(t)
def kappa(R):                                    # condition number with columns scaled to length 1
    n = len(R); c = [sqrt(dot([R[i][j] for i in range(n)], [R[i][j] for i in range(n)])) for j in range(n)]
    S = [[R[i][j] / c[j] for j in range(n)] for i in range(n)]
    inv = [solve_r(S, [1.0 if i == j else 0.0 for i in range(n)]) for j in range(n)]  # columns
    return smax(S) * smax([[inv[j][i] for j in range(n)] for i in range(n)])
g, m = rng(2026), 200
d = [0.05 * i for i in range(m)]                 # thousands of km on the trip meter
noise = lambda: dot([next(g) for _ in range(12)], [1.0] * 12) - 6.0  # mean 0, spread 1
y = [7.2 + 0.03 * di + 0.25 * noise() for di in d]  # litres per 100 km, illustrative
ones = [1.0] * m
mean = dot(ones, d) / m
dc = [di - mean for di in d]; ss = dot(dc, dc)   # centred distances
closed = [sqrt(m), sqrt(m) * mean, sqrt(ss)]
print(f"data,n={m},d from 0.00 to {d[-1]:.2f} thousand km,mean d={mean:.4f},sum d={mean * m:.2f},sum (d-mean)^2={ss:.6f}")
print(f"R closed form,r11={closed[0]:.6f},r12={closed[1]:.6f},r22={closed[2]:.6f}")
V, Rh = householder([ones, d])
Qg, Rg = gram_schmidt([ones, d])
for name, R in (("householder", Rh), ("gram-schmidt", Rg)):
    print(f"R {name},r11={R[0][0]:.6f},r12={R[0][1]:.6f},r22={R[1][1]:.6f}")
    for got, want in zip((abs(R[0][0]), abs(R[0][1]), abs(R[1][1])), closed):
        assert abs(got - want) < 1e-12 * want, (name, got, want)
v0, vv = V[0][0][0], V[0][1]; f = 2.0 * mean * m / vv
print(f"first reflector,v1={v0:.6f},v.v={vv:.6f},f={f:.6f},new top of d=-f*v1={-f * v0:.6f}")
assert abs(-f * v0 + closed[1]) < 1e-12 * closed[1]       # the hand route to r12 against the closed form
yb = dot(ones, y) / m; sxy = dot(dc, [yi - yb for yi in y])
cf = [yb - sxy / ss * mean, sxy / ss]
ch = solve_r(Rh, reflect(V, y)[:2])
cg = solve_r(Rg, [dot(q, y) for q in Qg])
for name, c in (("centred formula", cf), ("householder", ch), ("gram-schmidt", cg)):
    print(f"fit {name},intercept={c[0]:.6f} L/100km,slope={c[1]:.6f} L/100km per 1000 km")
assert all(abs(c[0] - cf[0]) < 1e-12 and abs(c[1] - cf[1]) < 1e-12 for c in (ch, cg))  # both QR fits = formula
print(f"line fit loss of orthogonality,householder={sci(loss(thin_q(V, m)))},gram-schmidt={sci(loss(Qg))}")
print("degree,kappa,classical,modified,householder,classical/(u kappa^2),modified/(u kappa)")
cols, pts = [ones], [[], [], []]
for p in range(1, 11):
    cols.append([a * b for a, b in zip(cols[-1], d)])
    V, R = householder(cols)
    k = kappa(R)
    lc, lm, lh = loss(gram_schmidt(cols)[0]), loss(gram_schmidt(cols, True)[0]), loss(thin_q(V, m))
    print(f"{p},{sci(k)},{sci(lc)},{sci(lm)},{sci(lh)},{lc / (U * k * k):.3f},{lm / (U * k):.3f}")
    for lst, val in zip(pts, (lc, lm, lh)): lst.append(f"{log10(val):.2f}")
    assert lh < 1e-14                            # Householder: orthogonal to rounding, any kappa
    assert 0.1 < lm / (U * k) < 10               # modified: near u kappa (lower limit: this code, this table)
    if p >= 3: assert lc > 10 * lm and lc > 0.1 * U * k * k  # classical: near u kappa^2, as run here
for name, lst in zip(("classical", "modified", "householder"), pts):
    print(f"chart log10 loss {name}," + ",".join(lst))
(Qc, Rc), res = gram_schmidt(cols), 0.0
for j in range(11):                              # each column's worst miss over its largest entry
    for i in range(m):
        res = max(res, abs(cols[j][i] - dot([Qc[k][i] for k in range(j + 1)], [Rc[k][j] for k in range(j + 1)])) / cols[j][m - 1])
l2 = loss(gram_schmidt(cols, passes=2)[0])
print(f"degree 10,classical twice loss={sci(l2)},classical A-QR relative residual={sci(res)}")
assert l2 < 1e-14 and res < 1e-13
print("cost,m,n,gram-schmidt,2mn^2,householder R,2mn^2-2n^3/3,householder thin Q extra")
for n in (2, 11, 50):
    A = [[next(g) for _ in range(m)] for _ in range(n)]
    FL[0] = 0; gram_schmidt(A); fg = FL[0]
    FL[0] = 0; V, R = householder(A); fh = FL[0]
    FL[0] = 0; thin_q(V, m); fq = FL[0]
    print(f"cost,{m},{n},{fg},{2 * m * n * n},{fh},{2 * m * n * n - 2 * n ** 3 / 3:.1f},{fq}")
    assert fg == n * (n - 1) // 2 * (4 * m - 1) + n * (3 * m - 1)
    assert fh == sum((2 * (m - k) - 1) + (n - k - 1) * (4 * (m - k) - 1) for k in range(n))
x = [1.0, 1.0]                                   # the figure: two readings, both ones
v = householder([x])[0][0][0]
hx = axpy(2.0 * dot(v, x) / dot(v, v), v, x)     # reflect x in full, with v.v by dot product
print(f"figure,x=(1,1),Hx=({hx[0]:.6f},{hx[1]:.6f}),v=({v[0]:.6f},{v[1]:.6f}),midpoint=({(x[0] + hx[0]) / 2:.6f},{(x[1] + hx[1]) / 2:.6f})")
assert abs(hx[0] + sqrt(2.0)) < 1e-15 and abs(hx[1]) < 1e-15
print("ALL CHECKS PASS")
