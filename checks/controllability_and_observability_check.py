# Can you steer every state, and can you see every state -- the check behind the card.
# Standard library only. Cart on a rail, motor sets its acceleration u (m/s^2), rod upright on a hinge.
# State x = (p cart m, v cart m/s, th lean rad, om lean rate rad/s): p'' = u, th'' = 16 th - u/l.
import math

L, G = 0.613125, 9.81
a, c = G / L, 1 / L                                      # a = g/l = 16 per s^2, c = 1/l per m
A = [[0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, a, 0]]
B = [0, 1, 0, -c]
CART, PIVOT, TIP = [1, 0, 0, 0], [0, 0, 1, 0], [1, 0, L, 0]  # tip sensor reads p + l th
LEAN = [0, 0, 0.05, 0]
def f(x, d=4): return f"{0.0 if abs(x) < 0.5 * 10 ** -d else x:.{d}f}"
def sci(x):
    if abs(x) < 1e-15: return "0"
    e = math.floor(math.log10(abs(x))); return f"{x / 10 ** e:.3f}e{e}"
def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def tr(X): return [list(r) for r in zip(*X)]
def mv(X, v): return [sum(r[j] * v[j] for j in range(len(v))) for r in X]
def dot(u, v): return sum(p * q for p, q in zip(u, v))
def eye(n): return [[float(i == j) for j in range(n)] for i in range(n)]
def expm(X, t):                                          # e^(Xt): scale down by 256, Taylor series, square 8 times
    E = eye(len(X)); P = eye(len(X)); Y = [[v * t / 256 for v in r] for r in X]
    for k in range(1, 20):
        P = [[v / k for v in r] for r in mm(P, Y)]; E = [[e + p for e, p in zip(r, q)] for r, q in zip(E, P)]
    for _ in range(8): E = mm(E, E)
    return E
def rank(M, tol=1e-9):                                   # road 1 to a rank: Gaussian elimination
    M = [r[:] for r in M]; r = 0
    for j in range(len(M[0])):
        if r == len(M): break
        p = max(range(r, len(M)), key=lambda i: abs(M[i][j]))
        if abs(M[p][j]) < tol: continue
        M[r], M[p] = M[p], M[r]
        for i in range(len(M)):
            if i != r: M[i] = [x - M[i][j] / M[r][j] * y for x, y in zip(M[i], M[r])]
        r += 1
    return r
def jacobi(S):                                           # eigenvalues (ascending) and eigenvectors of symmetric S
    n = len(S); S = [r[:] for r in S]; V = eye(n)
    for _ in range(40):
        for p in range(n):
            for q in range(p + 1, n):
                if S[p][q] == 0: continue
                t = 0.5 * math.atan2(2 * S[p][q], S[q][q] - S[p][p]); co, si = math.cos(t), math.sin(t)
                for k in range(n): S[k][p], S[k][q] = co * S[k][p] - si * S[k][q], si * S[k][p] + co * S[k][q]
                for k in range(n): S[p][k], S[q][k] = co * S[p][k] - si * S[q][k], si * S[p][k] + co * S[q][k]
                for k in range(n): V[k][p], V[k][q] = co * V[k][p] - si * V[k][q], si * V[k][p] + co * V[k][q]
    o = sorted(range(n), key=lambda i: S[i][i]); return [S[i][i] for i in o], [[V[k][i] for k in range(n)] for i in o]
def svrank(M): return sum(1 for s in jacobi(mm(tr(M), M))[0] if s > 1e-9)   # road 2: count nonzero singular values
def ctrb(A, B):                                          # columns B, AB, A^2 B, A^3 B
    cols = [B[:]]
    for _ in range(len(A) - 1): cols.append(mv(A, cols[-1]))
    return tr(cols)
def obsv(A, C): return tr(ctrb(tr(A), C))                # duality: rows C, CA, CA^2, CA^3
def gram(A, B, T, N=400):                                # integral of e^(At) B B^T e^(A^T t), Simpson's rule
    n, h = len(A), T / N; E1, E = expm(A, T / N), eye(len(A)); W = [[0.0] * n for _ in range(n)]
    for k in range(N + 1):
        w, v = (1 if k in (0, N) else 4 if k % 2 else 2) * h / 3, mv(E, B)
        W = [[W[i][j] + w * v[i] * v[j] for j in range(n)] for i in range(n)]; E = mm(E, E1)
    return W
def solve(M, b):
    n = len(M); M = [r[:] + [b[i]] for i, r in enumerate(M)]
    for i in range(n):
        p = max(range(i, n), key=lambda r: abs(M[r][i])); M[i], M[p] = M[p], M[i]
        for r in range(n):
            if r != i: M[r] = [x - M[r][i] / M[i][i] * y for x, y in zip(M[r], M[i])]
    return [M[i][n] / M[i][i] for i in range(n)]
def quad(x, W): return dot(x, mv(W, x))
def push(t, eta, T):                                     # u(t) = B^T e^(A^T (T-t)) eta, written out for this A
    s = T - t; return eta[0] * s + eta[1] - c * eta[2] * math.sinh(4 * s) / 4 - c * eta[3] * math.cosh(4 * s)
def fly(T, N=4000):                                      # road 2: fly the cheapest push through the plant with RK4
    eta, h, x, E, peak = solve(gram(A, B, T), [1, 0, 0, 0]), T / N, [0.0] * 4, 0.0, 0.0
    fx = lambda x, u: [x[1], u, x[3], a * x[2] - c * u]
    for k in range(N):
        u0, u1, u2 = push(k * h, eta, T), push(k * h + h / 2, eta, T), push(k * h + h, eta, T)
        k1 = fx(x, u0); k2 = fx([p + h / 2 * q for p, q in zip(x, k1)], u1)
        k3 = fx([p + h / 2 * q for p, q in zip(x, k2)], u1); k4 = fx([p + h * q for p, q in zip(x, k3)], u2)
        x = [p + h / 6 * (q + 2 * r + 2 * s + w) for p, q, r, s, w in zip(x, k1, k2, k3, k4)]
        E += h / 6 * (u0 * u0 + 4 * u1 * u1 + u2 * u2); peak = max(peak, abs(x[2]))
    return x, E, peak, eta
# ---- 1. the two rank tests ----
Cm = ctrb(A, B); print("columns B, AB, A2B, A3B:", " | ".join(" ".join(f(v) for v in col) for col in tr(Cm)))
print("controllability rank", rank(Cm), "by elimination,", svrank(Cm), "by singular values")
assert rank(Cm) == svrank(Cm) == 4 and abs(Cm[3][2] + a * c) < 1e-12
for name, C, k in (("cart encoder", CART, 2), ("pivot encoder", PIVOT, 2), ("tip sensor", TIP, 4)):   # k: rank by hand
    O = obsv(A, C); r3 = mm(mm(mm([C], A), A), A)[0]           # C A^3 as row times A, not from the dual
    assert max(abs(O[3][j] - r3[j]) for j in range(4)) < 1e-12 and rank(O) == svrank(O) == k
    print(f"{name}: observability rank {rank(O)}; rows", " | ".join(" ".join(f(v, 2) for v in r) for r in O))
# ---- 2. what the cart encoder cannot see: rod upright vs rod leaning 0.05 rad, no push ----
for t in (0.25, 0.5):
    x1, x2 = mv(expm(A, t), [0, 0, 0, 0]), mv(expm(A, t), LEAN)
    print(f"t {t} s: encoder {f(x1[0])} m and {f(x2[0])} m; lean {f(x1[2])} and {f(x2[2])} rad")
    assert x1[0] == x2[0] == 0 and abs(x2[2] - 0.05 * math.cosh(4 * t)) < 1e-12
# ---- 3. PBH, mode by mode: eigenvalues 0, 0, +4, -4 ----
for lam in (0, 4, -4):
    M = [[lam * (i == j) - A[i][j] for j in range(4)] for i in range(4)]
    ro = [rank(M + [C]) for C in (CART, PIVOT, TIP)]
    print(f"PBH at {lam}: steer rank {rank([r + [b] for r, b in zip(M, B)])}; see rank cart {ro[0]}, pivot {ro[1]}, tip {ro[2]}")
    assert ro[0] == (4 if lam == 0 else 3) and ro[1] == (3 if lam == 0 else 4) and ro[2] == 4
# ---- 4. transfer functions: the cart encoder's hides the +4 pole ----
for s in (1.0, 2.0):
    R = solve([[s * (i == j) - A[i][j] for j in range(4)] for i in range(4)], B); gc, gt = R[0], R[0] + L * R[2]
    print(f"G at s = {s:.0f}: cart {f(gc)}, 1/s^2 = {f(1 / s ** 2)}; tip {f(gt)}, -16/(s^2(s^2-16)) = {f(-16 / (s * s * (s * s - 16)))}")
    assert abs(gc - 1 / s ** 2) < 1e-12 and abs(gt + a / (s * s * (s * s - a))) < 1e-12
# ---- 5. controllability Gramian: the price of moving the cart 1 m, rod upright and still at both ends ----
T = 2.0; W = gram(A, B, T)
print("Wc(2 s) diagonal", " ".join(f(W[i][i]) for i in range(4)), "; p-v entry", f(W[0][1]), "; lean entry", f(c * c / 16, 5), "x", f(math.sinh(8 * T) / 16 - T / 2, 0))
assert abs(W[2][2] - c * c / 16 * (math.sinh(8 * T) / 16 - T / 2)) < 1e-6 * W[2][2]
bare = [[0, 1], [0, 0]]
for t_ in (2.0, 1.0, 3.0):
    e_rod, e_bare = solve(gram(A, B, t_), [1, 0, 0, 0])[0], solve(gram(bare, [0, 1], t_), [1, 0])[0]
    print(f"1 m in {t_:.0f} s: price {f(e_rod, 3)} with rod, {f(e_bare, 3)} bare cart (12/T^3 = {f(12 / t_ ** 3, 3)}), ratio {f(e_rod / e_bare, 2)}")
    assert abs(e_bare - 12 / t_ ** 3) < 1e-9
for t_ in (2.0, 1.0):
    x, E, peak, eta = fly(t_)
    print(f"flown {t_:.0f} s: lands", " ".join(f(v) for v in x), f"; energy {f(E, 3)}; peak lean {f(peak)} rad = {f(math.degrees(peak), 1)} deg; sin off by {f(100 * (1 - math.sin(peak) / peak), 1)}%")
    assert abs(x[0] - 1) < 1e-4 and max(abs(v) for v in x[1:]) < 1e-3 and abs(E - eta[0]) < 1e-4 * eta[0]
eta = solve(W, [1, 0, 0, 0])
print("chart t:", " ".join(f(k * 0.25, 2) for k in range(9)))
print("chart push with rod:", " ".join(f(push(k * 0.25, eta, T), 3) for k in range(9)))
print("chart push bare cart:", " ".join(f(6 / T ** 2 * (1 - 2 * k * 0.25 / T), 3) for k in range(9)))
for st in (LEAN, [0, 1, 0, 0]): print("price to reach", " ".join(f(v, 2) for v in st), "in 2 s:", f(dot(st, solve(W, st))))
ev, vec = jacobi(W); print("Wc eigenvalues", " ".join(sci(e) for e in ev), "; hardest", " ".join(f(v, 3) for v in vec[0]))
assert abs(dot(vec[0], mv(W, vec[0])) - ev[0]) < 1e-9 and abs(sum(ev) - sum(W[i][i] for i in range(4))) < 1e-6
S = [1, 1, 180 / math.pi, 180 / math.pi]; evd, vecd = jacobi([[S[i] * W[i][j] * S[j] for j in range(4)] for i in range(4)])
print("same, angles in degrees: smallest", sci(evd[0]), "; hardest", " ".join(f(v, 3) for v in vecd[0]))
# ---- 6. observability Gramian by duality: Wo(A, C) = Wc(A^T, C^T), window 0.5 s ----
To = 0.5
for name, C in (("cart encoder", CART), ("tip sensor", TIP), ("sensor 1 cm up the rod", [1, 0, 0.01, 0])):
    Wo = gram(tr(A), C, To); print(f"Wo(0.5 s) {name}: eigenvalues", " ".join(sci(v) for v in jacobi(Wo)[0]), "; lean 0.05 rad gives", sci(quad(LEAN, Wo)), "m^2 s")
direct = L * L * 0.0025 * (math.sinh(8 * To) / 16 + To / 2)  # integral of (l 0.05 cosh 4t)^2, by hand
assert abs(quad(LEAN, gram(tr(A), TIP, To)) - direct) < 1e-9 and quad(LEAN, gram(tr(A), CART, To)) < 1e-15
# ---- 7. outside the model, and what breaks ----
xp = mv(expm(A, 2), [0, 0.1, 0, 0]); print(f"pivot encoder, cart drifting 0.1 m/s: after 2 s cart {f(xp[0])} m off, lean still {f(xp[2])} rad")
M_, m_ = 1.0, 0.1; Af = [[0, 1, 0, 0], [0, 0, -m_ * G / M_, 0], [0, 0, 0, 1], [0, 0, (M_ + m_) * G / (M_ * L), 0]]
wf = math.sqrt(Af[3][2]); pf = mv(expm(Af, 0.5), LEAN)[0]
print(f"force-driven 1 kg cart, 0.1 kg bob: cart-encoder rank {rank(obsv(Af, CART))}; lean 0.05 rad moves cart {f(1000 * pf, 2)} mm in 0.5 s")
assert abs(pf + m_ * G / M_ * 0.05 * (math.cosh(wf * 0.5) - 1) / wf ** 2) < 1e-12
print("Wc lean-lean entry: T = 2 s", sci(W[2][2]), "; T = 4 s", sci(gram(A, B, 4.0)[2][2]))
print("ALL CHECKS PASS")
