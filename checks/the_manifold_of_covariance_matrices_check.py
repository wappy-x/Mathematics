# Covariance matrices: blend two risk estimates by the log-Euclidean and affine-invariant means.
import math
def mul(X, Y): return (X[0]*Y[0] + X[1]*Y[2], X[0]*Y[1] + X[1]*Y[3], X[2]*Y[0] + X[3]*Y[2], X[2]*Y[1] + X[3]*Y[3])
def lin(X, Y, s, t): return tuple(s*x + t*y for x, y in zip(X, Y))
def det(X): return X[0]*X[3] - X[1]*X[2]
def tr(X): return X[0] + X[3]
def inv(X): d = det(X); return (X[3]/d, -X[1]/d, -X[2]/d, X[0]/d)
def fro(X): return math.sqrt(sum(x*x for x in X))
def corr(M): return M[1] / math.sqrt(M[0]*M[3])
def gap(X, Y): return max(abs(x - y) for x, y in zip(X, Y))
def yn(ok): return "yes" if ok else "no"
I = (1.0, 0.0, 0.0, 1.0)
def eig(M):  # road 1: closed-form eigenvalues of a symmetric 2x2 matrix, smallest first
    m, r = (M[0] + M[3]) / 2, math.hypot((M[0] - M[3]) / 2, (M[1] + M[2]) / 2); return m - r, m + r
def fun(M, f):  # road 1: f applied along the eigenvectors (rotation angle th)
    th = 0.5 * math.atan2(M[1] + M[2], M[0] - M[3]); c, s = math.cos(th), math.sin(th)
    lo, hi = eig(M); f1, f2 = f(hi), f(lo)
    return (f1*c*c + f2*s*s, (f1 - f2)*c*s, (f1 - f2)*c*s, f1*s*s + f2*c*c)
def sqrt_db(M):  # Denman-Beavers square root, no eigenvectors: road 3 of the mean, inside road 2's log
    Y, Z = M, I
    for _ in range(60): Y, Z = lin(Y, inv(Z), 0.5, 0.5), lin(Z, inv(Y), 0.5, 0.5)
    return Y
def log_ser(M):  # road 2: take square roots until near I, then the artanh series
    k = 0
    while fro(lin(M, I, 1, -1)) > 0.05: M, k = sqrt_db(M), k + 1
    U = mul(lin(M, I, 1, -1), inv(lin(M, I, 1, 1))); U2, P, S = mul(U, U), U, (0.0,)*4
    for j in range(30): S, P = lin(S, P, 1, 2 / (2*j + 1)), mul(P, U2)
    return lin(S, S, 2**k, 0)
def exp_ser(X):  # road 2: Taylor series on X/1024, then square ten times
    Y, P, S = lin(X, X, 1/1024, 0), I, I
    for j in range(1, 20): P = lin(mul(P, Y), P, 1/j, 0); S = lin(S, P, 1, 1)
    for _ in range(10): S = mul(S, S)
    return S
def show(name, M): print(f"{name}: [[{M[0]:.4f}, {M[1]:.4f}], [{M[2]:.4f}, {M[3]:.4f}]]")
def geo(A, B, t):  # affine-invariant geodesic A^(1/2) (A^(-1/2) B A^(-1/2))^t A^(1/2)
    h, ih = fun(A, math.sqrt), fun(A, lambda x: 1 / math.sqrt(x))
    return mul(mul(h, fun(mul(mul(ih, B), ih), lambda x: x**t)), h)
def ai_log(P, Q): ih = fun(P, lambda x: 1 / math.sqrt(x)); return fun(mul(mul(ih, Q), ih), math.log)
def d_ai(P, Q): return fro(ai_log(P, Q))
def d_le(P, Q): return fro(lin(fun(P, math.log), fun(Q, math.log), 1, -1))
def mean_le(P, Q): return fun(lin(fun(P, math.log), fun(Q, math.log), 0.5, 0.5), math.exp)
A, B = (16.0, 2.0, 2.0, 4.0), (36.0, 9.0, 9.0, 9.0)   # calm and stress estimates, monthly returns in %
show("calm A", A); show("stress B", B)
for nm, M in (("A", A), ("B", B), ("C", (9.0, -3.0, -3.0, 9.0))):
    print(f"{nm}: stock volatility {math.sqrt(M[0]):.2f}%, bond volatility {math.sqrt(M[3]):.2f}%, correlation {corr(M):.4f}")
print(f"one asset: growth {36/16:.2f}, arithmetic {(16+36)/2:.6f}, geometric {math.sqrt(16*36):.6f}, ratio {math.sqrt(36/16):.6f}, distance {math.log(36/16):.6f}")
AiB = mul(inv(A), B); q = math.sqrt(tr(AiB)**2 - 4*det(AiB)); l1, l2 = (tr(AiB) + q) / 2, (tr(AiB) - q) / 2
print(f"A^-1 B: trace {tr(AiB):.6f}, det {det(AiB):.6f}, eigenvalues {l1:.6f} and {l2:.6f}")
ws = [(math.cos(k*math.pi/20000), math.sin(k*math.pi/20000)) for k in range(20000)]
qf = lambda M, w: M[0]*w[0]**2 + 2*M[1]*w[0]*w[1] + M[3]*w[1]**2
rq = [qf(B, w) / qf(A, w) for w in ws]   # road 2: scan every mix for its risk ratio
print(f"scan of mixes: largest risk ratio {max(rq):.6f}, smallest {min(rq):.6f}")
assert abs(max(rq) - l1) < 1e-6 and abs(min(rq) - l2) < 1e-6
dai = math.sqrt(math.log(l1)**2 + math.log(l2)**2)
print(f"ln {l1:.1f} = {math.log(l1):.6f}, ln {l2:.1f} = {math.log(l2):.6f}, affine-invariant distance {dai:.6f}")
assert abs(dai - d_ai(A, B)) < 1e-12
G1 = geo(A, B, 0.5)
al, be = math.sqrt(det(A)), math.sqrt(det(B)); S = lin(A, B, 1/al, 1/be)
print(f"closed form: sqrt det A {al:.6f}, sqrt det B {be:.6f}, det S {det(S):.6f}, scale {math.sqrt(al*be / det(S)):.6f}")
show("S = A/sqrt det A + B/sqrt det B", S)
G2 = lin(S, S, math.sqrt(al*be / det(S)), 0)                                  # road 2: 2x2 closed form
h = sqrt_db(A); ih = inv(h); G3 = mul(mul(h, sqrt_db(mul(mul(ih, B), ih))), h)  # road 3: Denman-Beavers
show("affine-invariant mean", G1)
print(f"closed form and Denman-Beavers roads agree within 1e-9: {yn(gap(G1, G2) < 1e-9 and gap(G1, G3) < 1e-9)}")
assert gap(G1, G2) < 1e-9 and gap(G1, G3) < 1e-9
print(f"G A^-1 G = B within 1e-9: {yn(gap(mul(mul(G1, inv(A)), G1), B) < 1e-9)}")
assert gap(mul(mul(G1, inv(A)), G1), B) < 1e-9
D = mul(inv(A), G1); qd = math.sqrt(tr(D)**2 - 4*det(D))
print(f"ratios of G to A: {(tr(D) + qd)/2:.6f} and {(tr(D) - qd)/2:.6f}, square roots of {l1:.1f} and {l2:.1f}")
assert abs((tr(D) + qd)/2 - math.sqrt(l1)) < 1e-9 and abs((tr(D) - qd)/2 - math.sqrt(l2)) < 1e-9
print(f"d(A, G) {d_ai(A, G1):.6f}, d(G, B) {d_ai(G1, B):.6f}, half of d(A, B) {dai/2:.6f}")
assert abs(d_ai(A, G1) - dai/2) < 1e-9 and abs(d_ai(G1, B) - dai/2) < 1e-9
def length(path, n):  # road 2: add up sqrt(tr((P^-1 dP)^2)) over n small steps
    tot = 0.0
    for k in range(n):
        P0, P1 = path(k / n), path((k + 1) / n); dP = lin(P1, P0, 1, -1); X = mul(inv(lin(P0, P1, 0.5, 0.5)), dP)
        tot += math.sqrt(tr(mul(X, X)))
    return tot
for n in (10, 100):
    print(f"length by {n} steps: geodesic {length(lambda t: geo(A, B, t), n):.6f}, straight line {length(lambda t: lin(A, B, 1 - t, t), n):.6f}")
assert abs(length(lambda t: geo(A, B, t), 100) - dai) < 1e-4 and length(lambda t: lin(A, B, 1 - t, t), 100) > dai + 0.001
lA, lB = fun(A, math.log), fun(B, math.log)
print(f"eigenvalues: A {eig(A)[1]:.6f}, {eig(A)[0]:.6f}; B {eig(B)[1]:.6f}, {eig(B)[0]:.6f}")
show("log A", lA); show("log B", lB)
print(f"log by series agrees within 1e-9: {yn(max(gap(lA, log_ser(A)), gap(lB, log_ser(B))) < 1e-9)}")
assert gap(lA, log_ser(A)) < 1e-9 and gap(lB, log_ser(B)) < 1e-9
dle = fro(lin(lA, lB, 1, -1)); L1 = mean_le(A, B); L2 = exp_ser(lin(log_ser(A), log_ser(B), 0.5, 0.5))
show("average of logs", lin(lA, lB, 0.5, 0.5)); print(f"log-Euclidean distance {dle:.6f}")
show("log-Euclidean mean", L1); print(f"series road agrees within 1e-9: {yn(gap(L1, L2) < 1e-9)}")
assert gap(L1, L2) < 1e-9
AR, HM = lin(A, B, 0.5, 0.5), inv(lin(inv(A), inv(B), 0.5, 0.5))
show("arithmetic mean", AR); show("mean of inverses, inverted", HM)
for nm, M in (("arithmetic", AR), ("inverses", HM), ("log-Euclidean", L1), ("affine-invariant", G1)):
    print(f"{nm}: det {det(M):.6f}, smallest variance {eig(M)[0]:.6f}, correlation {corr(M):.6f}")
print(f"det A {det(A):.6f}, det B {det(B):.6f}, sqrt(det A det B) {math.sqrt(det(A)*det(B)):.6f}")
print(f"arithmetic det over geometric det: {det(AR) / math.sqrt(det(A)*det(B)):.4f}")
assert abs(det(G1) - math.sqrt(det(A)*det(B))) < 1e-9 and abs(det(L1) - math.sqrt(det(A)*det(B))) < 1e-9
print(f"mean of inverses, inverted, equals the mean: affine-invariant {yn(gap(inv(geo(inv(A), inv(B), 0.5)), G1) < 1e-9)}, log-Euclidean {yn(gap(inv(mean_le(inv(A), inv(B))), L1) < 1e-9)}")
assert gap(inv(geo(inv(A), inv(B), 0.5)), G1) < 1e-9 and gap(inv(mean_le(inv(A), inv(B))), L1) < 1e-9
W = (1.0, 0.0, 0.0, 100.0); A2, B2 = mul(mul(W, A), W), mul(mul(W, B), W)   # bonds in basis points
G4, L4 = geo(A2, B2, 0.5), mean_le(A2, B2)
print(f"bonds in basis points: affine-invariant distance {d_ai(A2, B2):.6f}, log-Euclidean distance {d_le(A2, B2):.6f}")
print(f"stock variance of mean: affine-invariant {G4[0]:.4f} (was {G1[0]:.4f}), log-Euclidean {L4[0]:.4f} (was {L1[0]:.4f})")
print(f"correlation of mean: affine-invariant {corr(G4):.6f}, log-Euclidean {corr(L4):.6f}")
assert abs(d_ai(A2, B2) - dai) < 1e-9 and gap(G4, mul(mul(W, G1), W)) < 1e-6 and abs(L4[0] - L1[0]) > 0.3
E1, E2 = lin(A, B, 2, -1), geo(A, B, -1)
show("straight line at t = -1", E1); show("geodesic at t = -1", E2); show("A B^-1 A", mul(mul(A, inv(B)), A))
assert gap(E2, mul(mul(A, inv(B)), A)) < 1e-9 and E1[0] < 0 and eig(E2)[0] > 0
ts = [k / 4 - 1 for k in range(9)]
print("chart t: " + ", ".join(f"{t:.2f}" for t in ts))
print("chart straight: " + ", ".join(f"{eig(lin(A, B, 1 - t, t))[0]:.2f}" for t in ts))
print("chart geodesic: " + ", ".join(f"{eig(geo(A, B, t))[0]:.2f}" for t in ts))
Cm = (9.0, -3.0, -3.0, 9.0)   # third estimate, from a decade when bonds hedged stocks
show("third estimate C", Cm)
def ang(X, Y): return math.degrees(math.acos(tr(mul(X, Y)) / (fro(X) * fro(Y))))
tri = [(A, B, Cm), (B, Cm, A), (Cm, A, B)]
sai = sum(ang(ai_log(P, Q), ai_log(P, R)) for P, Q, R in tri)
lg = lambda P, Q: lin(fun(Q, math.log), fun(P, math.log), 1, -1)
sle = sum(ang(lg(P, Q), lg(P, R)) for P, Q, R in tri)
print(f"triangle A, B, C angle sum: affine-invariant {sai:.4f} deg, log-Euclidean {sle:.4f} deg")
assert sai < 179 and abs(sle - 180) < 1e-9
# try changing: the box's four answers, computed without editing the settings above
F, W10, Bn = (16.0, 0.0, 0.0, 4.0), (1.0, 0.0, 0.0, 10.0), (20.0, 3.0, 3.0, 5.0); Rn = mul(inv(A), Bn); qn = math.sqrt(tr(Rn)**2 - 4*det(Rn))
sflat = sum(ang(ai_log(P, Q), ai_log(P, R)) for P, Q, R in [(A, B, F), (B, F, A), (F, A, B)])
dn = length(lambda t: lin(A, Bn, 1 - t, t), 100) - length(lambda t: geo(A, Bn, t), 100)
print(f"try: bonds in tenths of a percent, log-Euclidean stock variance {mean_le(mul(mul(W10, A), W10), mul(mul(W10, B), W10))[0]:.4f}; flat triangle C = (16, 0, 0, 4), affine-invariant angle sum {sflat:.4f} deg")
print(f"try: B = (20, 3, 3, 5): risk ratios {(tr(Rn) + qn) / 2:.6f} and {(tr(Rn) - qn) / 2:.6f}, distance {d_ai(A, Bn):.6f}, straight line longer by {dn:.6f} at 100 steps")
show("try: weight one quarter, geodesic at t = 0.25", geo(A, B, 0.25))
print("ALL CHECKS PASS")
