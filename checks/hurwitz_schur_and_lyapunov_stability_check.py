# Stability of a state-space model, the check behind the card.  Standard library only (math).  Cart and
# pendulum upright, pole 0.613125 m so g/l = 9.81 / 0.613125 = 16 per s^2; x = (cart p m, speed v m/s, tilt th rad, rate w rad/s),
# u = cart acceleration m/s^2.  Roads: polynomial roots vs simulated growth; Lyapunov P by solve, hand formula
# and integral; sampled loop by trace and determinant vs powers; positive definite by minors vs Cholesky.
from math import log, sqrt, sin, cos, cosh, sinh, prod
def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
tr, eye = lambda X: [list(r) for r in zip(*X)], lambda n: [[float(i == j) for j in range(n)] for i in range(n)]
def add(X, Y, c=1.0): return [[a + c * b for a, b in zip(r, s)] for r, s in zip(X, Y)]
f = lambda x, d=4: f"{round(x, d) + 0.0:.{d}f}"; fl = lambda xs, d=4: " ".join(f(x, d) for x in xs)
def expm(X, t):                                    # e^(Xt): shrink t by halving, Taylor, square back up
    s = 0
    while max(abs(a) for r in X for a in r) * abs(t) / 2 ** s > 0.1: s += 1
    Y, E, T = [[a * t / 2 ** s for a in r] for r in X], eye(len(X)), eye(len(X))
    for k in range(1, 16): T = [[a / k for a in r] for r in mm(T, Y)]; E = add(E, T)
    for _ in range(s): E = mm(E, E)
    return E
def solve(M, y):                                   # Gaussian elimination with row swaps; (x, det)
    n, M, det = len(M), [r[:] + [b] for r, b in zip(M, y)], 1.0
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        if abs(M[p][c]) < 1e-12: return None, 0.0
        if p != c: M[c], M[p], det = M[p], M[c], -det
        det *= M[c][c]
        for i in range(c + 1, n): M[i] = [a - M[i][c] / M[c][c] * b for a, b in zip(M[i], M[c])]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x, det
def lyap(A, Q, disc=False):                        # A'P + PA = -Q, or sampled A'PA - P = -Q
    n = len(A); ix = [(i, j) for i in range(n) for j in range(n)]
    if disc: M = [[A[k][i] * A[l][j] - (i == k and j == l) for k, l in ix] for i, j in ix]
    else: M = [[A[k][i] * (l == j) + (i == k) * A[l][j] for k, l in ix] for i, j in ix]
    x, det = solve(M, [-Q[i][j] for i, j in ix])
    return (None if x is None else [x[i * n:(i + 1) * n] for i in range(n)]), det
def lyap_int(A, T, N):                             # Simpson's rule on e^(A't) I e^(At) over 0..T
    h = T / N; E1, E, S = expm(A, h), eye(len(A)), [[0.0] * len(A) for _ in A]
    for k in range(N + 1):
        S = add(S, mm(tr(E), E), (1 if k in (0, N) else 4 if k % 2 else 2) * h / 3); E = mm(E, E1)
    return S
def charpoly(A):                                   # Faddeev-LeVerrier: det(sI - A), highest power first
    n, c, M = len(A), [1.0], [[0.0] * len(A) for _ in A]
    for k in range(1, n + 1):
        M = add(mm(A, M), eye(n), c[-1]); AM = mm(A, M); c.append(-sum(AM[i][i] for i in range(n)) / k)
    return c
def roots(c):                                      # Durand-Kerner: all roots at once, complex
    n = len(c) - 1; z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(3000):
        for i in range(n):
            z[i] -= sum(a * z[i] ** (n - k) for k, a in enumerate(c)) / prod(z[i] - z[j] for j in range(n) if j != i)
    return sorted(z, key=lambda w: -w.real)
def minors(P): return [solve([r[:k] for r in P[:k]], [0.0] * k)[1] for k in range(1, len(P) + 1)]
def cholesky_ok(P):                                # P = L L' exists with positive pivots iff P > 0
    n = len(P); L = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = P[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
            if i == j and s <= 0: return False
            L[i][j] = sqrt(s) if i == j else s / L[j][j]
    return True
A = [[0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, 16, 0]]; c = charpoly(A); lam = roots(c)
print("open loop: det(sI - A) coefficients", fl(c, 1), "| eigenvalues", fl([z.real for z in lam]))
th = lambda t: expm(A, t)[2][2]                    # tilt in mrad, released at 1 mrad from rest
print(f"tilt from 1 mrad: at 1 s {f(th(1), 2)} mrad; growth ln(th(3)/th(2)) = {f(log(th(3) / th(2)))} per s;"
      f" doubling {f(log(2) / 4)} s; cart nudged to 0.1 m/s is at {f(0.1 * expm(A, 10)[0][1])} m after 10 s")
h = 0.01; zd = roots(charpoly(expm(A, h)))
print(f"sampled every {h} s: eigenvalues of e^(Ah)", fl([z.real for z in zd], 6), f"| e^(4h) = {f(2.718281828459045 ** (4 * h), 6)}")
Ac = [[0, 1], [-8, -6]]; t2, d2 = Ac[0][0] + Ac[1][1], Ac[0][0] * Ac[1][1] - Ac[0][1] * Ac[1][0]  # angle loop
print(f"angle loop: trace {f(t2, 1)} det {f(d2, 1)} eigenvalues {f((t2 + sqrt(t2 * t2 - 4 * d2)) / 2, 1)}"
      f" {f((t2 - sqrt(t2 * t2 - 4 * d2)) / 2, 1)}; feedback u = {f(24 * 0.613125, 3)} th + {f(6 * 0.613125, 3)} w")
P, det = lyap(Ac, eye(2)); Pi = lyap_int(Ac, 20, 4000); cc, dd = 8, 6   # hand: the three entry equations
hand = [cc * (1 + 1 / cc) / (2 * dd) + dd / (2 * cc), 1 / (2 * cc), (1 + 1 / cc) / (2 * dd)]
print("P11 P12 P22: solve", fl([P[0][0], P[0][1], P[1][1]], 6), "| hand", fl(hand, 6), "| integral", fl([Pi[0][0], Pi[0][1], Pi[1][1]], 6))
print("P leading minors", fl(minors(P), 7), "| Cholesky", cholesky_ok(P))
V = lambda s: P[0][0] * s[0] ** 2 + 2 * P[0][1] * s[0] * s[1] + P[1][1] * s[1] ** 2
x0 = [0.1, 0.0]; lmax = (P[0][0] + P[1][1] + sqrt((P[0][0] - P[1][1]) ** 2 + 4 * P[0][1] ** 2)) / 2
Vd = 2 * sum(x0[i] * P[i][j] * sum(Ac[j][k] * x0[k] for k in range(2)) for i in range(2) for j in range(2))
print(f"from th = 0.1 rad: V = {f(V(x0), 6)}, V' = 2 x'PAx = {f(Vd, 6)}; largest eigenvalue of P {f(lmax)},"
      f" so V falls at least as e^(-{f(1 / lmax)} t)")
traj = lambda t: [sum(expm(Ac, t)[i][j] * x0[j] for j in range(2)) for i in range(2)]
print("chart, t s:       ", fl([0.5 * k for k in range(7)], 1))
print("chart, V x 1000:  ", fl([1000 * V(traj(0.5 * k)) for k in range(7)], 3))
print("chart, bound x1000", fl([1000 * V(x0) * 2.718281828459045 ** (-0.5 * k / lmax) for k in range(7)], 3))
print("chart, tilt mrad open  ", fl([th(0.1 * k) for k in range(11)], 2))
print("chart, tilt mrad closed", fl([10 * traj(0.1 * k)[0] for k in range(11)], 2))
def Mdig(h):                                       # held input: one e^() of the plant with its input column
    G = expm([[0, 1, 0], [16, 0, -1], [0, 0, 0]], h)   # top-left e^(Ah), right column the push held h s
    return [[G[i][j] + G[i][2] * (24, 6)[j] for j in range(2)] for i in range(2)]
def rho(M):                                        # spectral radius of a 2x2 from trace and determinant
    t, d = M[0][0] + M[1][1], M[0][0] * M[1][1] - M[0][1] * M[1][0]; r = (t * t - 4 * d + 0j) ** 0.5
    return max(abs((t + r) / 2), abs((t - r) / 2)), t, d
def rho_pow(M, k=2000):                             # the same number from steps: growth of |M^j x| over j = k..2k
    x, s = [1.0, 1.0], 0.0
    for j in range(2 * k):
        x = [M[0][0] * x[0] + M[0][1] * x[1], M[1][0] * x[0] + M[1][1] * x[1]]; n = sqrt(x[0] ** 2 + x[1] ** 2)
        s, x = s + (log(n) if j >= k else 0.0), [x[0] / n, x[1] / n]
    return 2.718281828459045 ** (s / k)
for hh in (0.01, 0.2, 0.5):
    r, t, d = rho(Mdig(hh))
    print(f"digital angle loop, h = {hh} s: M {fl(sum(Mdig(hh), []))}; trace {f(t)} det {f(d)}; Jury |det| < 1 and |trace| < 1 + det:"
          f" {abs(d) < 1 and abs(t) < 1 + d}; radius {f(r)}, by powers {f(rho_pow(Mdig(hh)))}")
lo, hi = 0.2, 0.5
for _ in range(60): lo, hi = ((lo + hi) / 2, hi) if rho(Mdig((lo + hi) / 2))[0] < 1 else (lo, (lo + hi) / 2)
print(f"slowest safe sampling: h = {f(lo)} s, {f(1 / lo, 2)} samples per s")
Pd, _ = lyap(Mdig(0.01), eye(2), disc=True); S, Mk = eye(2), eye(2); M1 = Mdig(0.01)
for _ in range(3000): Mk = mm(Mk, M1); S = add(S, mm(tr(Mk), Mk))
print("sampled P x h, solve", fl([0.01 * Pd[0][0], 0.01 * Pd[0][1], 0.01 * Pd[1][1]]), "| by the series", fl([0.01 * S[0][0], 0.01 * S[0][1], 0.01 * S[1][1]]))
fn = lambda s: [s[1], 16 * sin(s[0]) - (24 * s[0] + 6 * s[1]) * cos(s[0])]
def falls(th0, h=0.001):                           # RK4 on the curved pendulum for 5 s: V always falling? top tilt
    s, v, ok, top = [th0, 0.0], V([th0, 0.0]), True, th0
    for _ in range(5000):
        k1 = fn(s); k2 = fn([a + h / 2 * b for a, b in zip(s, k1)]); k3 = fn([a + h / 2 * b for a, b in zip(s, k2)])
        k4 = fn([a + h * b for a, b in zip(s, k3)]); s = [a + h / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(s, k1, k2, k3, k4)]
        ok, v, top = ok and V(s) < v, V(s), max(top, abs(s[0]))
    return ok, top, s[0]
for th0 in (0.3, 0.9, 1.0): r = falls(th0); print(f"curved pendulum from {th0} rad: V falls at every step {r[0]}; largest tilt {f(r[1])}, tilt at 5 s {f(r[2])} rad")
K = [-1.5, -3.125, -52.5 * 0.613125, -13.125 * 0.613125]; Bv = [0, 1, 0, -1 / 0.613125]
Acl = [[A[i][j] - Bv[i] * K[j] for j in range(4)] for i in range(4)]
cl = charpoly(Acl); P4, _ = lyap(Acl, eye(4)); P4i = lyap_int(Acl, 40, 8000)
print("full loop: coefficients", fl(cl, 4), "| eigenvalues", fl([z.real for z in roots(cl)]))
print("full loop P minors", fl(minors(P4), 3), "| Cholesky", cholesky_ok(P4),
      "| solve vs integral, largest gap", f(max(abs(P4[i][j] - P4i[i][j]) for i in range(4) for j in range(4)), 7))
Po, do = lyap([[0, 1], [16, 0]], eye(2)); Pf, _ = lyap([[0, 1], [-8, 6]], eye(2))
print(f"wrong: Lyapunov on the open angle loop: solution {Po}, system determinant {f(do)}")
print("wrong: rate gain sign flipped, eigenvalues", fl([z.real for z in roots(charpoly([[0, 1], [-8, 6]]))], 1),
      "P", fl([Pf[0][0], Pf[0][1], Pf[1][1]], 6))
print(f"wrong: half-plane test on the sampled loop's {f(rho(M1)[0])}: real part > 0; try: pole 0.24525 m:"
      f" eigenvalue {f(sqrt(9.81 / 0.24525))}, doubling {f(log(2) / sqrt(9.81 / 0.24525))} s")
Pq, _ = lyap(Ac, [[10, 0], [0, 1]]); print("try: Q = diag(10, 1): P", fl([Pq[0][0], Pq[0][1], Pq[1][1]], 6), "minors", fl(minors(Pq), 6))
assert max(abs(z.real - e) for z, e in zip(lam, (4, 0, 0, -4))) < 1e-6         # roots of s^4 - 16 s^2
assert abs(log(th(3) / th(2)) - lam[0].real) < 1e-6                              # simulated growth = top eigenvalue
assert abs(max(abs(z) for z in zd) - 2.718281828459045 ** (4 * h)) < 1e-9        # sampling maps lambda to e^(lambda h)
assert max(abs(a - b) for a, b in zip([P[0][0], P[0][1], P[1][1]], hand)) < 1e-12  # solve = hand formula
assert max(abs(P[i][j] - Pi[i][j]) for i in range(2) for j in range(2)) < 1e-8     # solve = integral
assert max(abs(P4[i][j] - P4i[i][j]) for i in range(4) for j in range(4)) < 1e-6 and cholesky_ok(P4)
assert all(abs(rho(Mdig(x))[0] - rho_pow(Mdig(x))) < 1e-6 for x in (0.01, 0.2, 0.5))  # trace-det = powers
assert abs(1 + sum(rho(Mdig(lo))[1:])) < 1e-9                                  # edge: Jury's 1 + trace + det = 0
assert max(abs(Pd[i][j] - S[i][j]) for i in range(2) for j in range(2)) < 1e-6   # sampled P: solve = series
ch, sh = cosh(2), sinh(2)                          # closed form at h = 0.5: e^(Ah) by cosh and sinh, push by integrating
assert max(abs(Mdig(0.5)[i][j] - ([[ch, sh / 4], [4 * sh, ch]][i][j] - [(ch - 1) / 16, sh / 4][i] * (24, 6)[j])) for i in range(2) for j in range(2)) < 1e-9
assert Po is None and not cholesky_ok(Pf); assert falls(0.9)[0] and not falls(1.0)[0]  # no certificate; P is local
print("ALL CHECKS PASS")
