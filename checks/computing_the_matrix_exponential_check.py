# Computing e^A -- the check behind the card.  Only math is imported.
# Moler and Van Loan's A = [[-49, 24], [-64, 31]], eigenvalues -1 and -17.
# Roads to e^A: (1) interpolating e^x at the eigenvalues, (2) eigenvectors V e^D V^-1,
# (3) the Taylor series in floating point, (4) scaling and squaring with Pade [6/6].
# Then the square root and the logarithm of e^A through its Schur form.
# math.exp and math.log are the library's, used for scalars only.
import math
U, A, I = 2.0 ** -53, [[-49.0, 24.0], [-64.0, 31.0]], [[1.0, 0.0], [0.0, 1.0]]
def mul(X, Y): return [[X[i][0] * Y[0][j] + X[i][1] * Y[1][j] for j in range(2)] for i in range(2)]
def lin(a, X, b, Y): return [[a * X[i][j] + b * Y[i][j] for j in range(2)] for i in range(2)]
def inv(X):
    d = X[0][0] * X[1][1] - X[0][1] * X[1][0]
    return [[X[1][1] / d, -X[0][1] / d], [-X[1][0] / d, X[0][0] / d]]
def tr(X): return [[X[0][0], X[1][0]], [X[0][1], X[1][1]]]
def n1(X): return max(abs(X[0][j]) + abs(X[1][j]) for j in range(2))   # largest column total
def rel(X, Y): return n1(lin(1, X, -1, Y)) / n1(Y)
def sci(v): return f"{v:.3e}"
def fm(X, d=7): return "[[" + "], [".join(", ".join(f"{v:.{d}f}" for v in r) for r in X) + "]]"
def interp(X, l1, l2):          # e^X = (e^l1 (X - l2 I) - e^l2 (X - l1 I)) / (l1 - l2)
    return lin(math.exp(l1) / (l1 - l2), lin(1, X, -l2, I), -math.exp(l2) / (l1 - l2), lin(1, X, -l1, I))
def eigvec(X, l1, l2):          # V e^D V^-1 with eigenvectors (x12, l - x11)
    V = [[X[0][1], X[0][1]], [l1 - X[0][0], l2 - X[0][0]]]
    return mul(mul(V, [[math.exp(l1), 0.0], [0.0, math.exp(l2)]]), inv(V)), n1(V) * n1(inv(V))
def taylor(X, terms=150):
    S, T, big = I, I, []
    for k in range(1, terms):
        T = lin(1.0 / k, mul(T, X), 0, I)
        S, big = lin(1, S, 1, T), big + [max(abs(v) for r in T for v in r)]
    return S, big
FAC = [math.factorial(k) * 1.0 for k in range(27)]
C = [FAC[12 - k] * FAC[6] / (FAC[12] * FAC[k] * FAC[6 - k]) for k in range(7)]   # Pade [6/6] of e^x
CERR = FAC[6] ** 2 / (FAC[12] * FAC[13])                                       # e^x - r(x) ~ CERR x^13
def pade6(X):                   # N = E + O, D = E - O: even and odd parts, four products
    X2 = mul(X, X); X4 = mul(X2, X2); X6 = mul(X4, X2)
    E = lin(1, lin(C[0], I, C[2], X2), 1, lin(C[4], X4, C[6], X6))
    O = mul(X, lin(1, lin(C[1], I, C[3], X2), C[5], X4))
    return mul(inv(lin(1, E, -1, O)), lin(1, E, 1, O))
def expm(X, s):
    R = pade6(lin(2.0 ** -s, X, 0, I))
    for _ in range(s): R = mul(R, R)
    return R
def pw(X, k):
    P = I
    for _ in range(k): P = mul(P, X)
    return P
def choose_s(X):                # smallest s with leading backward error CERR ||X^13|| / ||X|| <= u
    s = 0
    while CERR * n1(pw(lin(2.0 ** -s, X, 0, I), 13)) / n1(lin(2.0 ** -s, X, 0, I)) > U: s += 1
    return s
REF = interp(A, -1.0, -17.0)
EV, kV = eigvec(A, -1.0, -17.0)
print(f"A = [[-49, 24], [-64, 31]]; trace {A[0][0] + A[1][1]:.1f}, det {A[0][0] * A[1][1] - A[0][1] * A[1][0]:.1f} -> eigenvalues -1, -17")
print("interpolation e^A =", fm(REF))
print(f"eigenvectors  e^A = {fm(EV)}; kappa(V) = {kV:.1f}; rel diff {sci(rel(EV, REF))}")
assert abs(REF[0][0] + 2 * math.exp(-1) - 3 * math.exp(-17)) < 1e-15 and rel(EV, REF) < 1e-14
TS, big = taylor(A)
kmax = max(range(len(big)), key=lambda k: big[k]) + 1
print(f"Taylor in doubles: {fm(TS)}; rel error {sci(rel(TS, REF))}")
print(f"largest term entry {sci(big[kmax - 1])} at k = {kmax}; 17^17/17! = {sci(17.0 ** 17 / FAC[17])}; times u {sci(big[kmax - 1] * U)}")
assert 1e-10 < rel(TS, REF) < 1e-7
fr = [(math.factorial(12 - k) * 720, math.factorial(12) * math.factorial(k) * math.factorial(6 - k)) for k in range(7)]
print("Pade [6/6] c_k:", ", ".join(f"{p // math.gcd(p, q)}/{q // math.gcd(p, q)}" for p, q in fr))
ec = [1.0 / FAC[k] for k in range(14)]
res = []
for k in range(14):             # coefficient of x^k in Q(x) e^x - P(x), Q(x) = P(-x)
    acc = 0.0
    for j in range(min(k, 6) + 1): acc += C[j] * (-1) ** j * ec[k - j]
    res.append(acc - (C[k] if k <= 6 else 0))
print(f"Q e^x - P, terms x^0..x^12: max size {sci(max(abs(v) for v in res[:13]))}; x^13 term {sci(res[13])}; (6!)^2/(12! 13!) = {sci(CERR)}")
assert max(abs(v) for v in res[:13]) < 1e-15 and abs(abs(res[13]) / CERR - 1) < 1e-9
print("s, ||X||, ||X^13||^(1/13), leading backward error:")
for s in range(3, 7):
    X = lin(2.0 ** -s, A, 0, I)
    print(f"  {s}, {n1(X):.4f}, {n1(pw(X, 13)) ** (1 / 13):.4f}, {sci(CERR * n1(pw(X, 13)) / n1(X))}")
s = choose_s(A)
mvl = 0
while n1(A) * 2.0 ** -mvl > 0.5: mvl += 1
eps66 = 2.0 ** (3 - 12) * FAC[6] ** 2 / (FAC[12] * FAC[13])
E = expm(A, s)
print(f"chosen s = {s}; guaranteed rule ||X|| <= 1/2 gives s = {mvl}, bound {sci(eps66)} ||X||")
print(f"scaling and squaring e^A = {fm(E)}")
print(f"rel error {sci(rel(E, REF))}; ||A|| u = {sci(n1(A) * U)}; ratio {rel(E, REF) / (n1(A) * U):.2f}")
assert s == 5 and mvl == 8 and rel(E, REF) < 1e2 * n1(A) * U
b17 = CERR * 8 * (17 / 8) ** 13
print(f"s = 3: backward error on the -17 mode {sci(b17)}; seen in e^A as e^-17 x that = {sci(math.exp(-17) * b17)}")
sweep = [rel(expm(A, k), REF) for k in range(12)]
print("chart, s: " + ", ".join(str(k) for k in range(12)))
print("chart, log10 rel error: " + ", ".join(f"{math.log10(v):.2f}" for v in sweep))
assert sweep[0] > 1e-3 and sweep[11] > 10 * sweep[5]
print("chart, log10 largest Taylor term, k = 0..40 by 4: " + ", ".join(f"{math.log10(([1.0] + big)[k]):.2f}" for k in range(0, 41, 4)))
hump = max((n1(interp(lin(t / 1000, A, 0, I), -t / 1000, -17 * t / 1000)), t / 1000) for t in range(1, 1001))
mid = [n1(interp(lin(t, A, 0, I), -t, -17 * t)) for t in (0.125, 0.25)]   # e^(A/8), e^(A/4): squarings for s = 5
print(f"hump: ||e^(tA)|| peaks at {hump[0]:.4f} at t = {hump[1]:.3f}; at t = 1/8, 1/4: {mid[0]:.4f}, {mid[1]:.4f}; at t = 1: {n1(REF):.4f}")
assert hump[0] > 4 and abs(hump[1] - 0.15) < 0.1 and min(mid) > n1(REF)
d = 2.0 ** -30                  # nearly defective: B = [[-1, 1], [0, -1 + d]]
B = [[-1.0, 1.0], [0.0, -1.0 + d]]
phi = 1 + d / 2 + d * d / 6     # (e^d - 1)/d by its series: no cancellation
BX = [[math.exp(-1), math.exp(-1) * phi], [0.0, math.exp(-1 + d)]]
BV, kB = eigvec(B, -1.0, -1.0 + d)
bt = [rel(BV, BX), rel(expm(B, choose_s(B)), BX), rel(taylor(B, 40)[0], BX)]
print(f"near-defective B, gap 2^-30: kappa(V) = {sci(kB)}; kappa(V) u = {sci(kB * U)}")
print(f"  rel error: eigenvectors {sci(bt[0])}, scaling and squaring (s = {choose_s(B)}) {sci(bt[1])}, Taylor {sci(bt[2])}; eigenvectors / (kappa(V) u) = {bt[0] / (kB * U):.3f}")
assert bt[0] > 1e5 * bt[1] and bt[1] < 1e-15 and bt[2] < 1e-15
def schur(M):                   # real 2 by 2, real eigenvalues: M = Q T Q^T
    t, dt = M[0][0] + M[1][1], M[0][0] * M[1][1] - M[0][1] * M[1][0]
    l1 = t / 2 + math.copysign(math.sqrt((M[0][0] - M[1][1]) ** 2 / 4 + M[0][1] * M[1][0]), t)
    a, b = (M[0][1], l1 - M[0][0]), (l1 - M[1][1], M[1][0])
    q = a if abs(a[0]) + abs(a[1]) >= abs(b[0]) + abs(b[1]) else b
    r = math.sqrt(q[0] ** 2 + q[1] ** 2)
    Q = [[q[0] / r, -q[1] / r], [q[1] / r, q[0] / r]]
    return Q, mul(tr(Q), mul(M, Q))
def tsqrt(T):
    r1, r2 = math.sqrt(T[0][0]), math.sqrt(T[1][1])
    return [[r1, T[0][1] / (r1 + r2)], [0.0, r2]]
Q, T = schur(REF)
print(f"Schur form of e^A: diagonal {T[0][0]:.10f}, {sci(T[1][1])}; corner {T[0][1]:.7f}; below {sci(abs(T[1][0]))}")
R = mul(Q, mul(tsqrt(T), tr(Q)))
H = interp(lin(0.5, A, 0, I), -0.5, -8.5)
print(f"square root = {fm(R)}; vs e^(A/2): rel error {sci(rel(R, H))}; residual R^2 - M: {sci(rel(mul(R, R), REF))}")
assert rel(R, H) < 1e-10 and rel(mul(R, R), REF) < 1e-14
W, k = [[T[0][0], T[0][1]], [0.0, T[1][1]]], 0
while max(abs(W[0][0] - 1), abs(W[1][1] - 1)) > 0.25: W, k = tsqrt(W), k + 1
X, P, L = lin(1, W, -1, I), I, [[0.0, 0.0], [0.0, 0.0]]
for j in range(1, 40): P = mul(P, X); L = lin(1, L, (-1) ** (j + 1) / j, P)   # log(I + X)
LG = mul(Q, mul(lin(2.0 ** k, L, 0, I), tr(Q)))
dd = T[0][1] * (math.log(T[1][1]) - math.log(T[0][0])) / (T[1][1] - T[0][0])
LP = mul(Q, mul([[math.log(T[0][0]), dd], [0.0, math.log(T[1][1])]], tr(Q)))
print(f"log by {k} square roots + series: {fm(LG, 9)}; rel error vs A {sci(rel(LG, A))}")
print(f"log by Parlett's divided difference: rel error vs A {sci(rel(LP, A))}; u ||e^A|| / (e^-17 ||A||) = {sci(U * n1(REF) / (math.exp(-17) * n1(A)))}; ratio {rel(LP, A) / (U * n1(REF) / (math.exp(-17) * n1(A))):.2f}")
assert rel(LG, A) < 1e-9 and rel(LP, LG) < 1e-12
print("mistake, Pade [6/6] with no scaling (s = 0): rel error", sci(sweep[0]))
print(f"mistake, over-scaling s = 11: rel error {sci(sweep[11])}, {sweep[11] / sweep[5]:.0f} times s = 5; 2^6 = {2 ** 6}")
kt = next(k for k in range(kmax, len(big)) if big[k - 1] < U)
print(f"flops at n = 100: [6/6] with s = 5: {sci(9 * 2e6 + 8e6 / 3)}; Taylor, {kt} terms until a term < u: {sci(kt * 2e6)}")
for g in (2.0 ** -20, 2.0 ** -40):
    Bg = [[-1.0, 1.0], [0.0, -1.0 + g]]
    Bx = [[math.exp(-1), math.exp(-1) * (1 + g / 2 + g * g / 6)], [0.0, math.exp(-1 + g)]]
    print(f"try: gap {sci(g)}: eigenvectors {sci(rel(eigvec(Bg, -1.0, -1.0 + g)[0], Bx))}; scaling and squaring {sci(rel(expm(Bg, choose_s(Bg)), Bx))}")
print("ALL CHECKS PASS")
