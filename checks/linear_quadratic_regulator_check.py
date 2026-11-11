# The LQR -- the check behind the card.  Standard library only (math).  Cart and pendulum, linearised
# upright.  State x, stored as z = (cart position p in m, cart speed v in m/s, angle theta in rad, angle rate
# w in rad/s); input u = cart acceleration the motor commands, m/s^2.  p'' = u and theta'' = 16 theta - c u,
# with c = 1/(rod length) = 16/9.81 per m.  Cost J = integral of (qp p^2 + qt theta^2 + r u^2) dt.  Roads: (1) the
# Riccati equation stepped backward in time left (tau) until it stops moving; (2) Newton's method on Lyapunov
# equations, from a pole-placement gain; (3) poles from Kalman's identity, which never sees P; (4) simulating the loop.
from math import sin, cos, pi
a, c = 16.0, 16.0 / 9.81
A = [[0.0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, a, 0]]
B, R4 = [0.0, 1, 0, -c], range(4)
def mv(M, v): return [sum(M[i][k] * v[k] for k in R4) for i in R4]
def quad(P, z): return sum(z[i] * P[i][j] * z[j] for i in R4 for j in R4)
def closed(K): return [[A[i][j] - B[i] * K[j] for j in R4] for i in R4]
def ric_rhs(P, Q, r):                    # dP/dtau = A'P + PA + Q - P B B' P / r
    PB = mv(P, B)
    return [[sum(P[i][k] * A[k][j] + A[k][i] * P[k][j] for k in R4) + Q[i][j] - PB[i] * PB[j] / r
             for j in R4] for i in R4]
def add(X, Y, f): return [[X[i][j] + f * Y[i][j] for j in R4] for i in R4]
def ric_ode(Q, r, h=0.002, marks=()):    # road 1: RK4 from P = 0 (no time left) backward
    P, s, seen, step = [[0.0] * 4 for _ in R4], 0.0, {}, 1.0
    while step >= 1e-13 and s < 40:          # stop when a step no longer moves P, or give up after 40 s
        k1 = ric_rhs(P, Q, r); k2 = ric_rhs(add(P, k1, h / 2), Q, r)
        k3 = ric_rhs(add(P, k2, h / 2), Q, r); k4 = ric_rhs(add(P, k3, h), Q, r)
        new = [[P[i][j] + h / 6 * (k1[i][j] + 2 * k2[i][j] + 2 * k3[i][j] + k4[i][j]) for j in R4] for i in R4]
        step = max(abs(new[i][j] - P[i][j]) for i in R4 for j in R4)
        P, s = new, s + h
        seen.update({m: [x / r for x in mv(P, B)] for m in marks if abs(s - m) < h / 2})
    assert step < 1e-13, "the Riccati equation did not settle in 40 s of time left"; return P, s, seen
def solve(M, y):                         # Gaussian elimination with row swaps
    n = len(y); M = [M[i][:] + [y[i]] for i in range(n)]
    for i in range(n):
        p = max(range(i, n), key=lambda k: abs(M[k][i])); M[i], M[p] = M[p], M[i]
        for k in range(i + 1, n):
            f = M[k][i] / M[i][i]
            for j in range(i, n + 1): M[k][j] -= f * M[i][j]
    x = [0.0] * n
    for i in reversed(range(n)): x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def cost_matrix(K, Q, r):                # P_K with F'P + PF + Q + r K'K = 0, F = A - BK: J = z0' P_K z0
    F, M, y = closed(K), [[0.0] * 16 for _ in range(16)], [0.0] * 16
    for i in R4:
        for j in R4:
            y[4 * i + j] = -(Q[i][j] + r * K[i] * K[j])
            for k in R4: M[4 * i + j][4 * k + j] += F[k][i]; M[4 * i + j][4 * i + k] += F[k][j]
    x = solve(M, y); return [x[4 * i:4 * i + 4] for i in R4]
def newton(K, Q, r):                     # road 2: cost the gain, improve it, repeat (Kleinman)
    for n in range(1, 50):
        P = cost_matrix(K, Q, r); K2 = [x / r for x in mv(P, B)]
        if max(abs(K2[i] - K[i]) for i in R4) < 1e-10: return P, K2, n
        K = K2
    raise AssertionError("Newton's method did not settle in 49 rounds")
def charpoly(F):                         # Faddeev-LeVerrier: coefficients of det(sI - F)
    cf, M = [1.0], [[0.0] * 4 for _ in R4]
    for k in range(1, 5):
        M = [[sum(F[i][m] * M[m][j] for m in R4) + (cf[-1] if i == j else 0) for j in R4] for i in R4]
        cf.append(-sum(sum(F[i][m] * M[m][i] for m in R4) for i in R4) / k)
    return cf
def roots(cf):                           # Durand-Kerner on a monic quartic
    z = [(0.4 + 0.9j) ** k for k in R4]
    for _ in range(300):
        nz = []
        for i in R4:
            d = [z[i] - z[j] for j in R4 if j != i]; d = d[0] * d[1] * d[2]
            nz.append(z[i] - ((((z[i] + cf[1]) * z[i] + cf[2]) * z[i] + cf[3]) * z[i] + cf[4]) / d)
        z = nz
    return tidy(z)
def tidy(z): return sorted((complex(round(w.real, 9), abs(round(w.imag, 9))) for w in z), key=lambda w: (w.real, w.imag))
def kalman_poles(qp, qt, r):             # road 3: left roots of s^4(s^2-a)^2 + (qp/r)(s^2-a)^2 + (qt c^2/r) s^4
    al, be = qp / r, qt * c * c / r      # as a quartic in w = s^2
    ws = roots([1.0, -2 * a, a * a + al + be, -2 * a * al, al * a * a])
    return tidy([-(w ** 0.5) if (w ** 0.5).real > 0 else w ** 0.5 for w in ws])
def hurwitz(cf):                         # every root of a quartic in the left half-plane
    _, a3, a2, a1, a0 = cf
    return min(cf) > 0 and a3 * a2 > a1 and a3 * a2 * a1 > a1 * a1 + a3 * a3 * a0
def simulate(K, qp, qt, r, z0, h=0.001, t_end=10.0, rhs=None):   # road 4: RK4 on the loop, cost by trapezoids
    F, z, J, pu, px, st, sx, th = closed(K), z0[:], 0.0, 0.0, 0.0, 0.0, 0.0, []
    d, run = rhs or (lambda w: mv(F, w)), lambda z, u: qp * z[0] ** 2 + qt * z[2] ** 2 + r * u * u
    for n in range(int(t_end / h) + 1):
        u = -sum(K[j] * z[j] for j in R4)
        if n % 100 == 0 and n <= 2000: th.append(1000 * z[2])
        pu, px = max(pu, abs(u)), max(px, abs(z[0]))
        if abs(z[2]) > 0.005: st = n * h
        if abs(z[2]) > pi / 2: break         # the rod has fallen past horizontal
        if abs(z[0]) > 0.01: sx = n * h
        k1 = d(z); k2 = d([z[i] + h / 2 * k1[i] for i in R4])
        k3 = d([z[i] + h / 2 * k2[i] for i in R4]); k4 = d([z[i] + h * k3[i] for i in R4])
        z2 = [z[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in R4]
        J += h / 2 * (run(z, u) + run(z2, -sum(K[j] * z2[j] for j in R4))); z = z2
    return J, pu, px, st, sx, th, z
def Qm(qp, qt): return [[(qp if i == 0 else qt if i == 2 else 0.0) if i == j else 0.0 for j in R4] for i in R4]
fmt = lambda v, f="{:9.3f}": " ".join(f.format(x) for x in v)
pole = lambda ps: "  ".join(dict.fromkeys(f"{round(p.real, 4) + 0.0:.4f}" + (f" +- {p.imag:.4f}j" if p.imag > 5e-5 else "") for p in ps))
Z0, res = [0.0, 0.0, 0.05, 0.0], {}      # pendulum knocked 0.05 rad (2.9 degrees) off upright, at rest
K0 = [-16 / a, -32 / a, -(16 / a + a + 24) / c, -(32 / a + 8) / c]   # pole placement: all four poles at -2
print(f"rod l = {1 / c:.6f} m | open-loop poles:", pole(roots(charpoly(A))), "| det(sI - A + B K0):", fmt(charpoly(closed(K0)), "{:.4f}"))
designs = [("base (Bryson)", 4.0, 100.0, 0.04), ("cheap motor", 4.0, 100.0, 0.004), ("tight angle", 4.0, 1000.0, 0.04)]
for name, qp, qt, r in designs:
    Q = Qm(qp, qt); P1, s_end, fin = ric_ode(Q, r, marks=(0.25, 0.5, 1.0, 2.0, 5.0))
    P, K, its = newton(K0, Q, r)
    pa, pk = roots(charpoly(closed(K))), kalman_poles(qp, qt, r)
    J, pu, px, st, sx, th, _ = simulate(K, qp, qt, r, Z0)
    lo, hi = 0.0, 1.0
    for _ in range(50): lo, hi = (lo, (lo + hi) / 2) if hurwitz(charpoly(closed([(lo + hi) / 2 * k for k in K]))) else ((lo + hi) / 2, hi)
    res[name] = (Q, r, P, K, quad(P, Z0), th, fin)
    print(f"{name}: qp = {qp:g}, qt = {qt:g}, r = {r:g}")
    print(f"  K by Riccati ODE ({s_end:.2f} s to go): {fmt([x / r for x in mv(P1, B)])}")
    print(f"  K by Newton ({its} rounds):          {fmt(K)}   same P to 1e-8: {'yes' if max(abs(P1[i][j] - P[i][j]) for i in R4 for j in R4) < 1e-8 else 'no'}")
    print(f"  poles of A - BK:      {pole(pa)}")
    print(f"  poles, Kalman's identity: {pole(pk)}")
    print(f"  J = x0'P x0 = {quad(P, Z0):.6f}; simulated {J:.6f}")
    print(f"  peak push {pu:.2f} m/s^2, peak cart {100 * px:.1f} cm, angle inside 5 mrad after {st:.3f} s, cart inside 1 cm after {sx:.3f} s")
    print(f"  smallest safe gain scale {hi:.3f}; stable at 0.5 and at 1000: {'yes' if all(hurwitz(charpoly(closed([m * k for k in K]))) for m in (0.5, 1000)) else 'no'}")
    assert abs(quad(P, Z0) - J) < 1e-4 * J and max(abs(P1[i][j] - P[i][j]) for i in R4 for j in R4) < 1e-8
    assert max(abs(p - q) for p, q in zip(pa, pk)) < 1e-6 and abs(K[0] + (qp / r) ** 0.5) < 1e-8 and hi < 0.5
Q, r, P, K, J, th, fin = res["base (Bryson)"]
print("base P, rows:"); [print("  " + fmt(row, "{:10.4f}")) for row in P]
print(f"base gain on theta = (P[theta][v] - c P[theta][w]) / r = ({P[2][1]:.4f} - {c:.4f} x {P[2][3]:.4f}) / {r} = {(P[2][1] - c * P[2][3]) / r:.3f}")
for m in (0.25, 0.5, 1.0, 2.0, 5.0): print(f"base, finite horizon {m} s to go: K = {fmt(fin[m])}")
nudged = min(quad(cost_matrix([K[j] * (1 + e * (j == m)) for j in R4], Q, r), Z0) for m in R4 for e in (-0.05, 0.05))
print(f"base, cheapest of 8 gains nudged 5%: J = {nudged:.6f} (optimum {J:.6f})")
print("chart, angle in mrad at t = 0 to 2 s by 0.1 s:")
for name in res: print(f"  {name:<14}" + fmt(res[name][5], "{:.1f}"))
bad = [("K = B'P, R^-1 forgotten", [r * k for k in K]), ("u = +Kx, sign flipped", [-k for k in K]), ("k_p alone flipped", [-K[0]] + K[1:])]
for label, Kb in bad: print(f"mistake, {label}: poles {pole(roots(charpoly(closed(Kb))))}")
K_q0 = [x / r for x in mv(ric_ode(Qm(0.0, 100.0), r)[0], B)]; zend = simulate(K_q0, 0.0, 100.0, r, Z0)[6]
print(f"mistake, angle-only weight: K = {fmt(K_q0)}; after 10 s cart at {zend[0]:.3f} m, still moving {zend[1]:.4f} m/s")
_, K_deg, _ = newton(K0, Qm(4.0, 100.0 * (180 / 3.141592653589793) ** 2), r)
print(f"mistake, angle weight meant for degrees: opening push {-sum(K_deg[j] * Z0[j] for j in R4):.1f} m/s^2")
_, K10, _ = newton(K0, Qm(40.0, 1000.0), 0.4); dear = simulate(newton(K0, Q, 0.4)[1], 4.0, 100.0, 0.4, Z0)
big = simulate(K, 4.0, 100.0, r, [2 * x for x in Z0])
print(f"try, all weights x10: same gains to 1e-8: {'yes' if max(abs(K10[i] - K[i]) for i in R4) < 1e-8 else 'no'}")
print(f"try, r = 0.4: peak push {dear[1]:.2f} m/s^2, angle inside 5 mrad after {dear[3]:.3f} s")
print(f"try, start at 0.10 rad: J = {big[0]:.6f}, peak push {big[1]:.2f} m/s^2")
assert nudged > J and abs(big[0] - 4 * J) < 1e-4 * big[0] and max(abs(K10[i] - K[i]) for i in R4) < 1e-8
assert max(p.real for p in roots(charpoly(closed([r * k for k in K])))) > 0 and abs(zend[1]) > 0.01
def curved(z): u = -sum(K[j] * z[j] for j in R4); return [z[1], u, z[3], a * sin(z[2]) - c * u * cos(z[2])]
cv = [simulate(K, 4.0, 100.0, r, [0.0, 0.0, x, 0.0], rhs=curved) for x in (0.05, 1.1)]   # the real, curved rod
print(f"curved rod, base gain: from 0.05 rad angle inside 5 mrad after {cv[0][3]:.3f} s; from 1.10 rad the angle passes 90 degrees after {cv[1][3]:.3f} s")
assert max(abs(p - q) for p, q in zip(cv[0][5], th)) < 0.1 and abs(cv[1][6][2]) > pi / 2   # small knock: as straight; big: falls
print("ALL CHECKS PASS")
