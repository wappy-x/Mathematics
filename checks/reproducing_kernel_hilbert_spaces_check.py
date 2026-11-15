# Reproducing kernels -- the check behind the card.  Standard library only; the solver is written out.
# Three thermometers in a borehole and a Gaussian kernel in base 2, k(x, z) = 2^-((x - z)/1 m)^2,
# so at whole-metre depths every kernel value is an exact fraction.
from fractions import Fraction as F
import math

depth = [1, 2, 3]                           # thermometer depths, m
temp = [16, 13, 12]                         # one July day, deg C (illustrative)
deep = 10                                   # deep-ground temperature, deg C (illustrative)
y = [F(t - deep) for t in temp]             # readings above the deep value: 6, 3, 2
lam = F(1, 16)                              # the charge on the size of the fit

def kq(x, z): return F(1, 2 ** ((x - z) ** 2))      # exact, whole-metre depths only
def kf(x, z): return 2.0 ** (-(x - z) ** 2)
def num(q): return str(q.numerator) if q.denominator == 1 else f"{float(q):.4f}"
def vec(v): return "(" + ", ".join(num(q) for q in v) + ")"
def c2f(v): return f"{0.0 if abs(v) < 0.005 else v:5.2f}"   # no "-0.00"
def mv(A, v): return [sum((a * b for a, b in zip(row, v)), 0 * v[0]) for row in A]
def dot(u, v): return sum((a * b for a, b in zip(u, v)), 0 * u[0])

def solve(A, b):                            # Gauss-Jordan with partial pivoting
    n = len(b)
    M = [list(row) + [v] for row, v in zip(A, b)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [a - f * e for a, e in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def ridge(cent, xs, ys, lm):                # min sum (y - f)^2 + lm |f|^2 over span of k at cent
    B = [[kf(x, z) for z in cent] for x in xs]
    G = [[kf(a, b) for b in cent] for a in cent]
    A = [[sum(B[i][r] * B[i][s] for i in range(len(xs))) + lm * G[r][s] for s in range(len(cent))]
         for r in range(len(cent))]
    c = solve(A, [sum(B[i][r] * ys[i] for i in range(len(xs))) for r in range(len(cent))])
    fit = mv(B, c)
    return c, sum((a - b) ** 2 for a, b in zip(ys, fit)) + lm * dot(c, mv(G, c))

# ---- the finite rehearsal: functions on the three depths ----
K = [[kq(a, b) for b in depth] for a in depth]
Kinv = [solve(K, [F(int(i == j)) for i in range(3)]) for j in range(3)]   # columns = rows (symmetric)
reads = [dot(y, mv(Kinv, K[j])) for j in range(3)]                        # <y, k_x> with <f,g> = f K^-1 g
print("Gram matrix K, rows:", "; ".join(vec(r) for r in K))
print("K^-1 x 225, rows: " + "; ".join(vec([225 * v for v in r]) for r in Kinv))
print(f"<y, k_x> on the three depths reads off y: {vec(reads)}")
print(f"base-2 kernel = exp(-d^2/(2 l^2)) with reach l = 1/sqrt(2 ln 2) = {1 / math.sqrt(2 * math.log(2)):.4f} m")

# ---- kernel ridge: the best fit is a sum of kernels at the data points ----
KL = [[K[i][j] + lam * (i == j) for j in range(3)] for i in range(3)]
alpha = solve(KL, y)
fitted = mv(K, alpha)
resid = [a - b for a, b in zip(y, fitted)]
norm2 = dot(alpha, mv(K, alpha))
J = dot(resid, resid) + lam * norm2
print(f"alpha = (K + I/16)^-1 y = {vec(alpha)}  exactly {', '.join(str(a) for a in alpha)}")
print(f"by hand: 16(K + I/16) rows {'; '.join(vec([16 * v for v in r]) for r in KL)}; 16y = {vec([16 * v for v in y])}")
print(f"  a1 - a3 = {num(alpha[0] - alpha[2])}, a1 + a3 = {alpha[0] + alpha[2]} = {num(alpha[0] + alpha[2])}, 89 a2 = {num(89 * alpha[1])}")
print(f"fit at 1, 2, 3 m: {vec([f + deep for f in fitted])} deg C; residuals {vec(resid)}")
print(f"residual / lambda = {vec([r / lam for r in resid])} (equals alpha)")
print(f"|f|^2 = alpha.K.alpha = {num(norm2)}, |f| = {math.sqrt(norm2):.4f}; "
      f"J* = misses {num(dot(resid, resid))} + lambda |f|^2 {num(lam * norm2)} = {num(J)}")
f = lambda x: sum(float(a) * kf(x, d) for a, d in zip(alpha, depth))
grid = [i / 2 for i in range(11)]
print("depth m:  " + " ".join(f"{x:5.1f}" for x in grid))
print("fit - 10:  " + " ".join(c2f(f(x)) for x in grid))
for a, d in zip(alpha, depth):
    print(f"bump {d} m: " + " ".join(c2f(float(a) * kf(x, d)) for x in grid))
k1, k3 = kf(1.5, 1), kf(1.5, 3)
print(f"by hand at 1.5 m: k = {k1:.4f}, {k1:.4f}, {k3:.4f}; (a1 + a2) x {k1:.4f} = {float(alpha[0] + alpha[1]) * k1:.4f}, "
      f"a3 x {k3:.4f} = {float(alpha[2]) * k3:.4f}")
print(f"answer: 1.5 m reads {deep + f(1.5):.4f} deg C, 2.5 m {deep + f(2.5):.4f}, surface 0 m {deep + f(0):.4f}")
big = max(abs(f(i / 100)) for i in range(0, 801))
print(f"largest |f| on 0 to 8 m: {big:.4f} <= |f| sqrt(k(x,x)) = {math.sqrt(norm2):.4f}")

# ---- representer: a direction off the span only adds cost ----
kz = [kq(0, d) for d in depth]                                  # bump at the surface, 0 m
cz = solve(K, kz)                                               # its projection onto the span
g_at = [kz[i] - dot(K[i], cz) for i in range(3)]                # g = k_0 - projection, at the data
g2 = 1 - dot(kz, cz)                                            # |g|^2
cent4 = [0] + depth
K4 = [[kq(a, b) for b in cent4] for a in cent4]
coef = [F(1)] + [a - c for a, c in zip(alpha, cz)]              # f + g on centres 0, 1, 2, 3
vals = [dot(K4[i + 1], coef) for i in range(3)]
Jg = sum((a - b) ** 2 for a, b in zip(y, vals)) + lam * dot(coef, mv(K4, coef))
print(f"g = k_0 minus its projection: g at 1, 2, 3 m = {vec(g_at)}; |g|^2 = {num(g2)} = {g2}")
print(f"J(f + g) = {num(Jg)} = J* + lambda |g|^2 = {num(J + lam * g2)}")
def cost(a):
    r = [u - v for u, v in zip(y, mv(K, a))]
    return dot(r, r) + lam * dot(a, mv(K, a))
nudge = min(cost([alpha[i] + F(s, 100) * (i == j) for i in range(3)]) for s in (-1, 1) for j in range(3))
print(f"six nudges of one alpha by 0.01: least J = {num(nudge)} > J*")

# ---- a second road: ordinary ridge on M explicit features ----
c2 = 2 * math.log(2)
def phi(x, M): return [2.0 ** (-(x - 2) ** 2) * (c2 ** 0.5 * (x - 2)) ** m / math.sqrt(math.factorial(m)) for m in range(M)]
yf, gaps = [float(v) for v in y], []
print("M features: prediction at 1.5 m (deg C), gap to the kernel answer")
for M in (1, 2, 3, 4, 6, 8, 12, 16, 20):
    P = [phi(d, M) for d in depth]
    A = [[sum(P[i][r] * P[i][s] for i in range(3)) + float(lam) * (r == s) for s in range(M)] for r in range(M)]
    w = solve(A, [sum(P[i][r] * yf[i] for i in range(3)) for r in range(M)])
    pred = dot(phi(1.5, M), w)
    gaps.append(abs(pred - f(1.5)))
    print(f"  M = {M:2d}: {deep + pred:.6f}  gap {gaps[-1]:.9f}")

# ---- what breaks ----
box = [[int(abs(a - b) < 1) for b in (1, 1.9, 2.8)] for a in (1, 1.9, 2.8)]
cbox = [1, -1, 1]
qbox = dot(cbox, mv(box, cbox))
print(f"mistake 1, box kernel at 1, 1.9, 2.8 m: rows {box}; c = (1, -1, 1) gives c.K.c = {qbox}")
print("mistake 2, L2 tents of norm 1 and half-width w: value at the peak")
spikes = []
for wd, lab in ((1.0, "1"), (0.01, "0.01"), (0.0001, "0.0001")):
    h, n = math.sqrt(3 / (2 * wd)), 20000
    sq = sum((h * (1 - abs(-wd + (i + 0.5) * 2 * wd / n) / wd)) ** 2 for i in range(n)) * 2 * wd / n
    spikes.append(h / math.sqrt(sq))
    print(f"  w = {lab} m: peak {spikes[-1]:.4f}, formula sqrt(3/(2w)) = {math.sqrt(3 / (2 * wd)):.4f}")
xs4, ys4 = [1, 2, 2.1, 3], [6.0, 3.0, 4.0, 2.0]
for lm in (0.0, 0.0625):
    c4, _ = ridge(xs4, xs4, ys4, lm)
    p = lambda x: sum(a * kf(x, d) for a, d in zip(c4, xs4))
    print(f"mistake 3, extra sensor 2.1 m at 14 deg C, lambda = {lm:.4f}: alpha = ({', '.join(f'{a:.2f}' for a in c4)}),"
          f" fit at 1.5 m {deep + p(1.5):.2f}, at 2.5 m {deep + p(2.5):.2f}")
    if lm == 0: wild = max(abs(a) for a in c4)
araw = [float(a) for a in solve(KL, [F(t) for t in temp])]
fr = lambda x: sum(a * kf(x, d) for a, d in zip(araw, depth))
print(f"mistake 4, deep 10 deg C not removed: fit at 1.5 m {fr(1.5):.2f}, at 5 m {fr(5):.2f} deg C")
_, Jelse = ridge([0.5, 2.5, 4.5], depth, yf, float(lam))
print(f"mistake 5, kernels centred at 0.5, 2.5, 4.5 m instead: J = {Jelse:.4f} against J* = {float(J):.4f}")

assert reads == y and resid == [lam * a for a in alpha]                 # reproducing; residual = lambda alpha
assert all(v == 0 for v in g_at) and g2 > 0 and Jg == J + lam * g2       # representer, exactly
assert nudge > J and Jelse > float(J) + 0.1 and big <= math.sqrt(norm2)
assert gaps[-1] < 1e-9 and all(a > b for a, b in zip(gaps[:6], gaps[1:7]))  # features meet the kernel
assert qbox == -1 and all(abs(s - math.sqrt(3 / (2 * w))) < 1e-3 * s for s, w in zip(spikes, (1.0, 0.01, 0.0001)))
assert wild > 10 * max(abs(float(a)) for a in alpha)
print("ALL CHECKS PASS")
