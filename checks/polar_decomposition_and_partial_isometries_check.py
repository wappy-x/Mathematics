# Polar decomposition and partial isometries: the check behind the card.
# Standard library only. Real scalars. Square roots, eigenvectors and U are built by hand:
# a Jacobi eigen solver, a 2x2 closed form and the iteration X <- X + (A - X^2)/2.
import math

def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]
def tp(A): return [list(r) for r in zip(*A)]
def gap(A, B): return max(abs(a - b) for r, s in zip(A, B) for a, b in zip(r, s))
def eye(n): return [[float(i == j) for j in range(n)] for i in range(n)]
def f6(x): return f"{0.0 if abs(x) < 5e-7 else x:.6f}"
def fm(A): return "[" + ", ".join("[" + ", ".join(f6(x) for x in r) + "]" for r in A) + "]"
def apply(A, x): return [sum(a * b for a, b in zip(r, x)) for r in A]

def jacobi(A):  # eigenvalues and eigenvector columns of a symmetric matrix
    n = len(A); A = [r[:] for r in A]; V = eye(n)
    for _ in range(60):
        if sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j) < 1e-26: break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for M in (A, V):
                    for k in range(n): M[k][p], M[k][q] = c * M[k][p] - s * M[k][q], s * M[k][p] + c * M[k][q]
                for k in range(n): A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return [A[i][i] for i in range(n)], V

def polar(T):  # |T| = sqrt(T*T) and U: |T|v -> Tv on the eigenvectors with stretch > 0, zero on the rest
    n = len(T); w, V = jacobi(mul(tp(T), T)); sig = [math.sqrt(max(x, 0.0)) for x in w]
    P = [[sum(V[i][k] * sig[k] * V[j][k] for k in range(n)) for j in range(n)] for i in range(n)]
    U = [[0.0] * n for _ in range(n)]
    for k in [k for k in range(n) if sig[k] > 1e-9]:
        u = [sum(T[i][m] * V[m][k] for m in range(n)) / sig[k] for i in range(n)]
        for i in range(n):
            for j in range(n): U[i][j] += u[i] * V[j][k]
    return P, U, sig, V

def zeros(A): return sum(1 for x in jacobi(A)[0] if abs(x) < 1e-9)  # dimension of the kernel of a symmetric A

print("1. the two-sample effect T = [[0, 2], [0, 0]]: read sample 2, double it, write it in slot 1")
T = [[0.0, 2.0], [0.0, 0.0]]; A = mul(tp(T), T)
P, U, sig, _ = polar(T)
s = math.sqrt(A[0][0] * A[1][1] - A[0][1] * A[1][0]); r = math.sqrt(A[0][0] + A[1][1] + 2 * s)
P2 = [[(A[i][j] + s * (i == j)) / r for j in range(2)] for i in range(2)]  # road 2: closed form for 2x2
c = 4.0; X, its = [[0.0, 0.0], [0.0, 0.0]], []  # road 3: X <- X + (A/c - X^2)/2, c at least the top of A
for k in range(7):
    its.append(math.sqrt(c) * X[1][1]); X2 = mul(X, X)
    X = [[X[i][j] + (A[i][j] / c - X2[i][j]) / 2 for j in range(2)] for i in range(2)]
P3 = [[math.sqrt(c) * x for x in row] for row in X]
print("T*T =", fm(A)); print("|T| by Jacobi    =", fm(P)); print("|T| by 2x2 rule  =", fm(P2)); print("|T| by iteration =", fm(P3))
print("iteration on the stretch 2, steps 0 to 6:", ", ".join(f6(x) for x in its))
assert gap(P, [[0, 0], [0, 2]]) < 1e-12 and gap(P2, P) < 1e-12 and gap(P3, P) < 1e-9
print("U =", fm(U), "  U|T| - T, largest entry:", f6(gap(mul(U, P), T)))
assert gap(mul(U, P), T) < 1e-12 and gap(U, [[0, 1], [0, 0]]) < 1e-12
print("U*U =", fm(mul(tp(U), U)), "keeps span(e2);  UU* =", fm(mul(U, tp(U))), "keeps span(e1)")
assert gap(mul(tp(U), U), [[0, 0], [0, 1]]) < 1e-12 and gap(mul(U, tp(U)), [[1, 0], [0, 0]]) < 1e-12
x = [3.0, 5.0]; Tx, Px = apply(T, x), apply(P, x)
print("x = (3, 5): Tx =", fm([Tx]), " |T|x =", fm([Px]), " lengths", f6(math.hypot(*Tx)), "and", f6(math.hypot(*Px)))
assert abs(math.hypot(*Tx) - math.hypot(*Px)) < 1e-12 and abs(math.hypot(*Tx) - 10) < 1e-12
W = [[0.0, 1.0], [1.0, 0.0]]
print("the swap W =", fm(W), " W|T| - T:", f6(gap(mul(W, P), T)), " W*W - I:", f6(gap(mul(tp(W), W), eye(2))))
assert gap(mul(W, P), T) < 1e-12 and gap(mul(tp(W), W), eye(2)) < 1e-12
print("kernel of T: dimension", zeros(A), "  directions T misses: dimension", zeros(mul(T, tp(T))))
assert zeros(A) == 1 and zeros(mul(T, tp(T))) == 1
Te = [[0.0, 2.0], [0.5, 0.0]]; Pe, Ue, _, _ = polar(Te)  # an invertible neighbour: e1 now goes to 0.5 e2
print("T =", fm(Te), " |T| =", fm(Pe), " U =", fm(Ue), " U*U - I:", f6(gap(mul(tp(Ue), Ue), eye(2))))
assert gap(Ue, W) < 1e-12 and gap(mul(Ue, Pe), Te) < 1e-12

print("2. the delay S, cut to N samples; x = (1, 1/2, 1/4, ...)")
for N in (4, 8, 16, 32):
    S = [[float(i == j + 1) for j in range(N)] for i in range(N)]
    P, U, sig, V = polar(S)
    kv = [V[i][k] for k in range(N) if sig[k] < 1e-9 for i in range(N)]  # the kernel vector of |S_N|
    wv, Q = jacobi(mul(S, tp(S))); mv = [Q[i][k] for k in range(N) if abs(wv[k]) < 1e-9 for i in range(N)]
    xs = [0.5 ** i for i in range(N)]
    ok, om = abs(sum(a * b for a, b in zip(kv, xs))), abs(sum(a * b for a, b in zip(mv, xs)))
    D = [[float(i == j and i < N - 1) for j in range(N)] for i in range(N)]
    print(f"N = {N:2d}: |S_N| - diag(1, ..., 1, 0): {f6(gap(P, D))}, U_N - S_N: {f6(gap(U, S))}, kernel {zeros(mul(tp(S), S))}, "
          f"missed {zeros(mul(S, tp(S)))}; x along the kernel {ok:.3e}, along the missed direction {f6(om)}")
    assert gap(U, S) < 1e-12 and gap(P, D) < 1e-12 and abs(ok - 0.5 ** (N - 1)) < 1e-15 and abs(om - 1) < 1e-12
y = [3, 1, 4, 1, 5]; z = [0] + y[1:]  # advance (drop the first sample), then delay: S S* y
print("delay after advance on (3, 1, 4, 1, 5):", z, " energy", sum(v * v for v in y), "->", sum(v * v for v in z))
assert sum(v * v for v in z) == 43

print("3. the running total V on an N-point midpoint grid of [0, 1]")
ex = [2 / ((2 * n - 1) * math.pi) for n in (1, 2)]
print("   N  sigma_1   error       sigma_2   error")
errs = []
for N in (8, 16, 32, 64):
    h = 1 / N; Vn = [[h if j < i else h / 2 if j == i else 0.0 for j in range(N)] for i in range(N)]
    P, U, sig, V = polar(Vn)
    o = sorted(range(N), key=lambda k: -sig[k]); s1, s2 = sig[o[0]], sig[o[1]]
    v1 = [V[i][o[0]] for i in range(N)]; v1 = [-a for a in v1] if sum(v1) < 0 else v1
    u1 = [a / s1 / math.sqrt(h) for a in apply(Vn, v1)]
    du = max(abs(u1[i] - math.sqrt(2) * math.sin(math.pi * (i + 0.5) * h / 2)) for i in range(N))
    e1, e2, eu, er = s1 - ex[0], s2 - ex[1], gap(mul(tp(U), U), eye(N)), gap(mul(U, P), Vn)
    print(f"{N:4d}  {f6(s1)}  {e1:.3e}  {f6(s2)}  {e2:.3e}")
    errs.append(abs(e1)); assert eu < 1e-9 and er < 1e-9 and du < 1e-9
assert all(3.5 < errs[k] / errs[k + 1] < 4.5 for k in range(3))  # error falls like 1/N^2
print("exact: sigma_1 = 2/pi =", f6(ex[0]), " sigma_2 = 2/(3 pi) =", f6(ex[1]), " error ratios",
      ", ".join(f"{errs[k] / errs[k + 1]:.3f}" for k in range(3)))
print("at every N: U*U - I, U|V| - V and u_1 - sqrt2 sin(pi x/2) on the grid all below 1e-9")

print("what breaks")
P, U, _, _ = polar(T); Pl = polar(tp(T))[0]  # |T*| = sqrt(T T*), the stretch for the left form
print("U|T*| in place of U|T|:", fm(mul(U, Pl)), " largest error", f6(gap(mul(U, Pl), T)))
assert gap(mul(U, Pl), T) > 1.9 and gap(Pl, [[2, 0], [0, 0]]) < 1e-12
print("U*U x for x = (3, 5), as if U were unitary:", fm([apply(mul(tp(U), U), x)]))
assert gap([apply(mul(tp(U), U), x)], [[0, 5]]) < 1e-12
for N in (4, 8, 16, 32):  # the cyclic delay C_N is unitary; the input it sends to e1 is e_N
    C = [[float(i == (j + 1) % N) for j in range(N)] for i in range(N)]
    pre = apply(tp(C), [float(i == 0) for i in range(N)]); ov = sum(a * 0.5 ** i for i, a in enumerate(pre))
    print(f"cyclic delay C_N, N = {N:2d}: C_N*C_N - I {f6(gap(mul(tp(C), C), eye(N)))}; the input sent to e1 overlaps x by {ov:.3e}")
    assert gap(mul(tp(C), C), eye(N)) < 1e-12 and abs(ov - 2.0 ** (1 - N)) < 1e-15
print("ALL CHECKS PASS")
