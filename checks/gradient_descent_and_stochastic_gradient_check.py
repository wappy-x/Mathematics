# Gradient descent and stochastic gradient -- the check behind the card.  Standard
# library only.  Synthetic shop: 20,000 orders, 12 numbers each, made by the rule
# below from SplitMix64 seed 2026.  Fit 12 weights and a bias by squared error.
from math import log, sqrt
MASK, N, D, P = (1 << 64) - 1, 20000, 12, 13
state = [0]
def rnd():                                     # SplitMix64, a uniform number in [0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & MASK
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
TRUE_W, TRUE_B = [3, -2, 1.5, 0, 4, -1, 2, 0.5, -3, 1, 2.5, -0.5], 40.0
state[0], X, Y = 2026, [], []
for i in range(N):                             # each order: a shared size z plus its own wobble
    z = 2 * rnd() - 1
    x = [z + 0.3 * (2 * rnd() - 1) for j in range(D)]
    y = TRUE_B
    for j in range(D): y += TRUE_W[j] * x[j]
    X.append(x + [1.0]); Y.append(y + 10 * (rnd() + rnd() + rnd() - 1.5))   # noise, sd 5 pounds
A, c, yy = [[0.0] * P for _ in range(P)], [0.0] * P, 0.0
for x, y in zip(X, Y):                         # summed products, added once: H = A, grad = A w - c
    yy += y * y / N
    for j in range(P):
        c[j] += 2 * x[j] * y / N
        for k in range(P): A[j][k] += 2 * x[j] * x[k] / N
def mul(M, v):
    out = []
    for row in M:
        s = 0.0
        for k in range(P): s += row[k] * v[k]
        out.append(s)
    return out
def risk(w, M=A, cc=c):                        # mean squared error, in pounds squared
    Mw, s = mul(M, w), yy
    for j in range(P): s += 0.5 * w[j] * Mw[j] - cc[j] * w[j]
    return s
def grad(w, M=A, cc=c): return [g - cj for g, cj in zip(mul(M, w), cc)]
G = [r[:] + [cj] for r, cj in zip(A, c)]      # road 1: exact bottom, by elimination
for j in range(P):
    for r in range(j + 1, P):
        f = G[r][j] / G[j][j]
        for k in range(j, P + 1): G[r][k] -= f * G[j][k]
best = [0.0] * P
for j in range(P - 1, -1, -1):
    s = G[j][P]
    for k in range(j + 1, P): s -= G[j][k] * best[k]
    best[j] = s / G[j][j]
R0 = risk(best)
def excess(w, M=A, cc=c): return risk(w, M, cc) - R0
def worst(w): return max(abs(w[j] - best[j]) for j in range(P))
print(f"orders {N}, numbers per order {D}, mean order value {c[P - 1] / 2:.4f} pounds")
print("best weights " + " ".join(f"{v:.2f}" for v in best[:D]) + f"; bias {best[D]:.2f}")
print(f"lowest risk {R0:.4f} pounds squared, typical miss {sqrt(R0):.2f} pounds")
rowg = [0.0] * P                               # road 2: the gradient at zero, order by order
for x, y in zip(X, Y):
    for j in range(P): rowg[j] += 2 * (0.0 - y) * x[j] / N
def rowrisk(w): return sum((sum(a * b for a, b in zip(w, x)) - y) ** 2 for x, y in zip(X, Y)) / N   # from the orders
zero, h = [0.0] * P, 1e-3
fd = [(rowrisk([h if k == j else 0.0 for k in range(P)]) - rowrisk([-h if k == j else 0.0 for k in range(P)])) / (2 * h) for j in range(P)]
g0 = grad(zero)
print(f"gradient at zero: bias {g0[D]:.4f}, weight 1 {g0[0]:.4f}; row sum {rowg[D]:.4f}, {rowg[0]:.4f}; difference quotient {fd[D]:.4f}, {fd[0]:.4f}")
def eig(M, shift):                             # power iteration on M - shift I
    v = [1.0 + 0.01 * j for j in range(P)]
    for _ in range(100000):
        u = [a - shift * b for a, b in zip(mul(M, v), v)]
        top = max(abs(a) for a in u)
        v = [a / top for a in u]
    u = [a - shift * b for a, b in zip(mul(M, v), v)]
    num, den = 0.0, 0.0
    for a, b in zip(u, v): num += a * b; den += b * b
    return num / den
def below(M, mu):                              # road 3b: curvatures below mu = negative pivots
    G, neg = [[M[i][j] - mu * (i == j) for j in range(P)] for i in range(P)], 0   # of M - mu I
    for j in range(P):
        neg += G[j][j] < 0
        for r in range(j + 1, P):
            f = G[r][j] / G[j][j]
            for k in range(j, P): G[r][k] -= f * G[j][k]
    return neg
lmax = eig(A, 0.0); lmin = lmax + eig(A, lmax)
print(f"first plain step, size 0.2: bias {-0.2 * g0[D]:.4f}, weight 1 {-0.2 * g0[0]:.4f}")
print(f"steepest curvature {lmax:.4f}, gentlest {lmin:.5f}, ratio {lmax / lmin:.1f}; step limit 2/steepest {2 / lmax:.4f}")
cnt = [below(A, m) for m in (lmin - 1e-4, lmin + 1e-4, 0.07, lmax - 1e-4, lmax + 1e-4)]
print(f"curvatures counted below gentlest -/+ 0.0001: {cnt[0]}, {cnt[1]}; below 0.07: {cnt[2]}; below steepest -/+ 0.0001: {cnt[3]}, {cnt[4]}")
def descend(eta, beta, steps, M=A, cc=c, sign=1):
    w, v, trace = [0.0] * P, [0.0] * P, [excess([0.0] * P, M, cc)]
    for t in range(steps):
        g = grad(w, M, cc)
        v = [beta * v[j] - sign * eta * g[j] for j in range(P)]
        w = [w[j] + v[j] for j in range(P)]
        trace.append(excess(w, M, cc))
    return w, trace
print("step size, excess risk after 50 passes: " + ", ".join(f"{e} -> {descend(e, 0, 50)[1][-1]:.4f}" for e in (0.05, 0.1, 0.2, 0.24, 0.25)))
wg, tg = descend(0.2, 0.0, 50)
wm, tm = descend(0.2, 0.8, 50)
slow = (1 - 0.2 * lmin) ** 2
print(f"plain, late shrink per pass {tg[50] / tg[49]:.4f}; predicted (1 - 0.2 x gentlest)^2 = {slow:.4f}; passes to cut slow error tenfold {log(10) / -log(1 - 0.2 * lmin):.0f}")
print(f"slow factor per pass {1 - 0.2 * lmin:.5f}, slow error left after 50 passes {(1 - 0.2 * lmin) ** 50:.3f}")
print(f"multiply-adds per pass {2 * N * P}; mini-batch steps per pass {N // 100}, in 50 passes {50 * N // 100}")
def sgd(eta, B, passes, seed):                 # mini-batches, reshuffled every pass
    state[0], w, idx, trace = seed, [0.0] * P, list(range(N)), [excess([0.0] * P)]
    for p in range(passes):
        for i in range(N - 1, 0, -1):
            j = int(rnd() * (i + 1)); idx[i], idx[j] = idx[j], idx[i]
        for s in range(0, N, B):
            g = [0.0] * P
            for i in idx[s:s + B]:
                x, e = X[i], -Y[i]
                for j in range(P): e += w[j] * x[j]
                for j in range(P): g[j] += 2 * e * x[j] / B
            for j in range(P): w[j] -= eta * g[j]
        trace.append(excess(w))
    return w, trace
ws, ts = sgd(0.05, 100, 50, 7)
wq, tq = sgd(0.0125, 100, 50, 7)
floor = [0.0, 0.0]
for k, t in enumerate((ts, tq)):
    for p in range(31, 51): floor[k] += t[p] / 20
print(f"mini-batch jitter floor, mean excess over passes 31-50: step 0.05 -> {floor[0]:.4f}, step 0.0125 -> {floor[1]:.4f}, ratio {floor[0] / floor[1]:.2f}")
for name, t in (("plain, step 0.2   ", tg), ("momentum 0.8      ", tm), ("mini-batch of 100 ", ts)):
    print(name + " " + " ".join(f"{t[p]:9.4f}" for p in (0, 1, 2, 5, 10, 20, 30, 40, 50)))
print(f"typical miss after 50 plain passes {sqrt(R0 + tg[50]):.3f} pounds, at the bottom {sqrt(R0):.3f}")
for name, w, t in (("plain", wg, tg), ("momentum", wm, tm), ("mini-batch", ws, ts)):
    print(f"after 50 passes, {name}: excess {t[50]:.4f}, worst weight off by {worst(w):.3f} pounds")
print("chart, log10 excess: " + " | ".join(" ".join(f"{log(t[p], 10):.2f}" for p in range(0, 51, 5)) for t in (tg, tm, ts)))
Np = [r[:] for r in A]; cp = c[:]               # what breaks: number 1 recorded 100 times too large
for k in range(P): Np[0][k] *= 100; Np[k][0] *= 100
cp[0] *= 100
lp = eig(Np, 0.0)
print(f"breaks: step 0.25 -> {descend(0.25, 0, 50)[1][-1]:.1f}; sum not mean, one step -> {descend(0.2 * N, 0, 1)[1][-1]:.3e}; uphill -> {descend(0.2, 0, 50, sign=-1)[1][-1]:.3e}")
print(f"breaks: number 1 x100: steepest {lp:.2f}, {lp / lmax:.0f} times; step 0.2, 3 passes -> {descend(0.2, 0, 3, Np, cp)[1][-1]:.3e}; safe step {1.9 / lp:.6f} -> {descend(1.9 / lp, 0, 50, Np, cp)[1][-1]:.4f}")
assert max(abs(g0[j] - rowg[j]) + abs(g0[j] - fd[j]) for j in range(P)) < 1e-6   # three gradients agree
assert max(abs(v) for v in grad(best)) < 1e-9 and abs(best[D] - TRUE_B) < 0.2       # bottom is flat, bias recovered
assert 0.995 < (tg[50] / tg[49]) / slow < 1.005                                      # rate meets prediction
assert cnt[:2] == [0, 1] and cnt[3:] == [P - 1, P]                                  # curvatures, second road
assert descend(0.24, 0, 50)[1][-1] < 10 < descend(0.25, 0, 50)[1][-1] and 0.24 < 2 / lmax < 0.25   # cliff at 2/steepest
assert tm[50] < tg[50] / 10 and floor[0] < tg[50] / 2 and worst(ws) < worst(wg) / 5 # momentum, mini-batch win
assert 2 < floor[0] / floor[1] < 16                                                 # quarter step, smaller jitter
print("ALL CHECKS PASS")
