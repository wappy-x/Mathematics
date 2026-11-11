# LQG on the balancing pendulum -- the check behind the card.  Standard library only.
# Regulator (LQR) and estimator (Kalman filter) are designed apart, then joined.  Roads: loop
# poles by two polynomials; cost by formula, covariance and simulation; margins by test and by run.
from math import sqrt, cosh, sinh, log, cos, pi
g, l, h = 9.81, 9.81 / 16, 0.01                # gravity m/s^2, pole length m (g/l = 16), tick s
a = g / l; w = sqrt(a); ch, sh = cosh(w * h), sinh(w * h)
A = [[ch, sh / w], [w * sh, ch]]               # exact one-tick step of (angle, rate)
B = [[-(ch - 1) / (a * l)], [-sh / (w * l)]]   # what one tick of cart acceleration u does
C = [[1.0, 0.0]]                               # the encoder reads the angle only
Q, R = [[100.0, 0.0], [0.0, 0.0]], 0.04        # prices: angle, rate, motor effort
SD, SV = 1.0 * l, 0.005                        # gust (1 rad/s^2 on the pole) in m/s^2; encoder rad

def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def tr(X): return [list(r) for r in zip(*X)]
def ad(X, Y, s=1.0): return [[x + s * y for x, y in zip(p, q)] for p, q in zip(X, Y)]
def eye(n): return [[float(i == j) for j in range(n)] for i in range(n)]
def sc(X, s): return [[s * x for x in r] for r in X]

def lqr(Q, R):                                 # regulator Riccati recursion, run until it settles
    P = Q
    for _ in range(5000):
        s = R + mm(mm(tr(B), P), B)[0][0]; K = sc(mm(mm(tr(B), P), A), 1.0 / s)
        P = ad(Q, mm(mm(tr(A), P), ad(A, mm(B, K), -1)))
    return K, P, s
def kalman(sd, sv):                            # filter Riccati recursion, run until it settles
    Wn = sc(mm(B, tr(B)), sd * sd); S = Wn     # gusts enter where the motor does
    for _ in range(5000):
        M = sc(mm(S, tr(C)), 1.0 / (S[0][0] + sv * sv))
        Sf = ad(S, mm(M, mm(C, S)), -1)        # error covariance just after a correction
        S = ad(mm(mm(A, Sf), tr(A)), Wn)
    return M, Sf
def charpoly(F):                               # Faddeev-LeVerrier: [1, c1, c2, ...]
    n = len(F); Mk = eye(n); c = [1.0]
    for k in range(1, n + 1):
        AM = mm(F, Mk); ck = -sum(AM[i][i] for i in range(n)) / k
        c.append(ck); Mk = ad(AM, eye(n), ck)
    return c
def stable(c):                                 # Schur-Cohn-Jury: every root inside the unit circle?
    while len(c) > 1:
        k = c[-1] / c[0]
        if abs(k) >= 1: return False
        c = [c[i] - k * c[-1 - i] for i in range(len(c) - 1)]
    return True
def loop(K, M, kg=1.0, Mu=None):               # state (x, z), z = prediction; plant receives kg * u
    Mu = M if Mu is None else Mu               # u = -K (z + Mu (y - C z)),  y = C x + v
    Hx, Hz, hv = sc(mm(K, mm(Mu, C)), -1), sc(mm(K, ad(eye(2), mm(Mu, C), -1)), -1), -mm(K, Mu)[0][0]
    AM = mm(A, M); AMC = mm(AM, C)
    F = [r1 + r2 for r1, r2 in zip(ad(A, mm(B, Hx), kg), sc(mm(B, Hz), kg))]
    F += [r1 + r2 for r1, r2 in zip(ad(AMC, mm(B, Hx)), ad(ad(A, AMC, -1), mm(B, Hz)))]
    G = [[B[0][0], kg * B[0][0] * hv], [B[1][0], kg * B[1][0] * hv],
         [0.0, AM[0][0] + B[0][0] * hv], [0.0, AM[1][0] + B[1][0] * hv]]
    return F, G, Hx[0] + Hz[0], hv             # u = H . state + hv * v
def raw(K):                                    # no filter: angle straight in, rate by differencing
    k1, k2 = K[0][0], K[0][1] / h              # state (angle, rate, last reading)
    F = [r + [B[i][0] * k2] for i, r in enumerate(ad(A, sc(mm(B, [[k1 + k2, 0.0]]), -1)))] + [[1.0, 0.0, 0.0]]
    G = [[B[0][0], -B[0][0] * (k1 + k2)], [B[1][0], -B[1][0] * (k1 + k2)], [0.0, 1.0]]
    return F, G, [-(k1 + k2), 0.0, k2], -(k1 + k2)
def cost(F, G, H, hv, sd=SD, sv=SV):           # steady covariance: S = F S F' + G N G'
    GNG = mm(mm(G, [[sd * sd, 0.0], [0.0, sv * sv]]), tr(G)); S = [[0.0] * len(F) for _ in F]
    for _ in range(4000): S = ad(mm(mm(F, S), tr(F)), GNG)
    u2 = mm(mm([H], S), tr([H]))[0][0] + hv * hv * sv * sv
    return Q[0][0] * S[0][0] + Q[1][1] * S[1][1] + R * u2, S, u2
def margin(ok, lo, hi):                        # bisect for the input gain where stability is lost
    for _ in range(60):
        mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if ok(mid) == ok(lo) else (lo, mid)
    return 0.5 * (lo + hi)
def margins(M): return [margin(lambda k: stable(charpoly(loop(K, M, k)[0])), 1.0, e) for e in (0.01, 100.0)]
def run(F, steps=1000):                        # noise-free loop from a nudge: size after 10 s / before
    x = [0.01] + [0.0] * (len(F) - 1)
    for _ in range(steps): x = [sum(F[i][j] * x[j] for j in range(len(x))) for i in range(len(x))]
    return sqrt(sum(v * v for v in x)) / 0.01

K, P, s = lqr(Q, R)
M, Sf = kalman(SD, SV)
F, G, H, hv = loop(K, M)
pr, pe, p4 = charpoly(ad(A, mm(B, K), -1)), charpoly(mm(A, ad(eye(2), mm(M, C), -1))), charpoly(F)
prod = [sum(pr[i] * pe[k - i] for i in range(3) if 0 <= k - i <= 2) for k in range(5)]
J_full = SD * SD * mm(mm(tr(B), P), B)[0][0]
J_sep = J_full + s * mm(mm(K, Sf), tr(K))[0][0]
J_cov, S, u2 = cost(F, G, H, hv)

st, mask = 20251025, (1 << 64) - 1             # splitmix64, then Box-Muller for bell-curve draws
def unif():
    global st
    st = (st + 0x9E3779B97F4A7C15) & mask; z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & mask; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & mask
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
xi, acc = [0.0] * 4, 0.0
for _ in range(200000):
    d, v = SD * gauss(), SV * gauss()
    u = sum(H[j] * xi[j] for j in range(4)) + hv * v
    acc += Q[0][0] * xi[0] ** 2 + Q[1][1] * xi[1] ** 2 + R * u * u
    xi = [sum(F[i][j] * xi[j] for j in range(4)) + G[i][0] * d + G[i][1] * v for i in range(4)]
J_sim = acc / 200000

M_ltr, _ = kalman(100.0, SV)                   # recovery: design the filter for 100 m/s^2 gusts
gm = [margin(lambda k: stable(charpoly(ad(A, mm(B, K), -k))), 1.0, e) for e in (0.01, 100.0)]
gm += margins(M) + margins(M_ltr)
grow = [run(ad(A, mm(B, K), -3.0)), run(loop(K, M, 3.0)[0]), run(loop(K, M, 2.5)[0])]
wrong = [cost(*loop(sc(K, 0.8), M))[0], cost(*loop(sc(K, 1.2), M))[0], cost(*loop(K, M, 1.0, [[0.0], [0.0]]))[0],
         cost(*raw(K))[0], cost(*loop(K, M_ltr))[0]]
tries = []
for sd, sv in ((SD, SV / 10), (SD * 10, SV)):
    Mt, _ = kalman(sd, sv); tries.append([1000 * cost(*loop(K, Mt), sd, sv)[0]] + margins(Mt))

def f(v, p=4): return " ".join(f"{x:10.{p}f}" for x in v)
def zs(c): re = -c[1] / 2; return [re, sqrt(c[2] - re * re), sqrt(c[2])]
for name, v in [("open-loop pole sqrt(g/l), rad/s", [w]), ("A row 1, row 2", A[0] + A[1]), ("B", tr(B)[0]),
                ("LQR gain K, per rad and rad/s", K[0]), ("Kalman gain M", tr(M)[0]),
                ("char poly, regulator A - BK", pr), ("char poly, estimator A(I - MC)", pe),
                ("their product", prod), ("char poly, whole 4-state loop", p4),
                ("regulator poles re, im, size", zs(pr)), ("estimator poles re, im, size", zs(pe)),
                ("cost per tick x1000: see all", [1000 * J_full]), ("  separation formula", [1000 * J_sep]),
                ("  loop covariance", [1000 * J_cov]), ("  simulated, 200000 ticks", [1000 * J_sim]),
                ("rms angle, estimate error (deg)", [sqrt(S[0][0]) * 180 / pi, sqrt(Sf[0][0]) * 180 / pi]),
                ("rms encoder noise deg, motor", [SV * 180 / pi, sqrt(u2)]),
                ("gain margin LQR low, high", gm[0:2]), ("gain margin LQG low, high", gm[2:4]),
                ("gain margin LQG recovered", gm[4:6]), ("10 s at 3x: LQR, LQG; 2.5x: LQG", grow),
                ("wrong x1000: 0.8K, 1.2K, no corr.", [1000 * x for x in wrong[:3]]),
                ("wrong x1000: raw, recovery filter", [1000 * x for x in wrong[3:]]),
                ("try encoder /10: cost, margins", tries[0]), ("try gusts x10: cost, margins", tries[1])]:
    print(f"{name:<34}" + f(v))
print("chart t(s)   true LQG   estimate   LQR (deg)")
x, z, xr = [0.05, 0.0], [[0.0], [0.0]], [0.05, 0.0]  # 0.05 rad tilt; estimator starts at upright
for k in range(121):
    xh = ad(z, sc(M, x[0] - z[0][0]))          # correct by the reading (noise-free run)
    if k % 10 == 0: print(f"chart {k * h:5.2f}", f([x[0] * 180 / pi, xh[0][0] * 180 / pi, xr[0] * 180 / pi], 3))
    u = -mm(K, xh)[0][0]; ur = -(K[0][0] * xr[0] + K[0][1] * xr[1])
    x = [A[i][0] * x[0] + A[i][1] * x[1] + B[i][0] * u for i in range(2)]
    xr = [A[i][0] * xr[0] + A[i][1] * xr[1] + B[i][0] * ur for i in range(2)]
    z = ad(mm(A, xh), sc(B, u))

assert max(abs(p - q) for p, q in zip(prod, p4)) < 1e-9, "separation: loop poles = regulator + estimator poles"
assert abs(J_sep - J_cov) < 1e-9 * J_cov, "separation cost formula vs covariance of the whole loop"
assert abs(J_sim - J_cov) < 0.03 * J_cov, "simulation within 3% of the covariance cost"
assert all(c > J_cov for c in wrong), "every departure from LQR gain on Kalman estimate costs more"
assert grow[0] < 1 and grow[1] > 1 and grow[2] < 1 and 2.5 < gm[3] < 3.0, "running the loop agrees with the test"
assert gm[2] > gm[0] and gm[3] < gm[1] and gm[4] < gm[2], "LQG margins narrower; recovery widens them"
print("ALL CHECKS PASS")
