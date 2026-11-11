# Predictive control -- the check behind the card.  Standard library only.
# Cart and pendulum, motor current limited to 1 A, sampled at 20 Hz.  Each tick: plan 20 moves
# by a quadratic program, apply the first, replan.  Roads: active-set solve, accelerated projected
# gradient, a costate (backward) gradient as an optimality certificate, and LQR as the no-limit case.
from math import sqrt, exp
M, m, l, g, kf, T, N, UMAX = 1.0, 0.2, 0.735, 9.8, 4.0, 0.05, 20, 1.0
Q, R, D = [1.0, 0.1, 10.0, 0.1], 0.1, 0.125           # weights; push 0.5 N = 0.125 A of motor current
Ac = [[0, 1, 0, 0], [0, 0, -m * g / M, 0], [0, 0, 0, 1], [0, 0, (M + m) * g / (M * l), 0]]
Bc = [0, kf / M, 0, -kf / (M * l)]                    # states: cart p, cart v, angle th, rate w

def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def mv(X, v): return [sum(a * b for a, b in zip(r, v)) for r in X]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def tr(X): return [list(r) for r in zip(*X)]
def solve(X, b):                                       # Gauss-Jordan with partial pivoting
    n = len(b); X = [X[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(X[r][c])); X[c], X[p] = X[p], X[c]
        for r in range(n):
            if r != c:
                f = X[r][c] / X[c][c]
                for j in range(c, n + 1): X[r][j] -= f * X[c][j]
    return [X[i][n] / X[i][i] for i in range(n)]

Z = [Ac[i] + [Bc[i]] for i in range(4)] + [[0.0] * 5]  # Van Loan: exp([[A, B], [0, 0]] T)
E = [[float(i == j) for j in range(5)] for i in range(5)]; term = [r[:] for r in E]
for k in range(1, 20):
    term = [[v * T / 256 / k for v in r] for r in mm(term, Z)]; E = [[a + b for a, b in zip(r, s)] for r, s in zip(E, term)]
for _ in range(8): E = mm(E, E)
A = [r[:4] for r in E[:4]]; B = [r[4] for r in E[:4]]

P = [[Q[i] * (i == j) for j in range(4)] for i in range(4)]   # LQR: Riccati iteration, stable form
for it in range(100000):
    PB = mv(P, B); K = [dot(PB, [A[i][j] for i in range(4)]) / (R + dot(B, PB)) for j in range(4)]
    Acl = [[A[i][j] - B[i] * K[j] for j in range(4)] for i in range(4)]
    Pn = [[a + Q[i] * (i == j) + R * K[i] * K[j] for j, a in enumerate(r)] for i, r in enumerate(mm(tr(Acl), mm(P, Acl)))]
    done = max(abs(Pn[i][j] - P[i][j]) for i in range(4) for j in range(4)) < 1e-10; P = Pn
    if done: break

def build(n, Pt):                                      # condensed: cost = U'HU + 2 (F x0)'U + const
    AB, Ak = [B[:]], [[[float(i == j) for j in range(4)] for i in range(4)]]
    for k in range(n): AB.append(mv(A, AB[-1])); Ak.append(mm(A, Ak[-1]))
    W = lambda k: Pt if k == n else [[Q[i] * (i == j) for j in range(4)] for i in range(4)]
    H = [[R * (i == j) + sum(dot(AB[k - 1 - i], mv(W(k), AB[k - 1 - j])) for k in range(max(i, j) + 1, n + 1))
          for j in range(n)] for i in range(n)]
    F = [[sum(dot(AB[k - 1 - i], mv(W(k), [Ak[k][a][c] for a in range(4)])) for k in range(i + 1, n + 1))
          for c in range(4)] for i in range(n)]
    return H, F

def active_set(H, f, lo, hi):                          # road 1: fix moves at limits until KKT holds
    n, fix = len(f), {}
    while True:
        free = [i for i in range(n) if i not in fix]
        s = solve([[H[i][j] for j in free] for i in free], [-f[i] - sum(H[i][j] * v for j, v in fix.items()) for i in free]) if free else []
        U = [fix.get(i, 0.0) for i in range(n)]
        for i, v in zip(free, s): U[i] = v
        out = [(max(U[i] - hi[i], lo[i] - U[i]), i) for i in free if U[i] > hi[i] or U[i] < lo[i]]
        if out: i = max(out)[1]; fix[i] = hi[i] if U[i] > hi[i] else lo[i]; continue
        gr = [dot(H[i], U) + f[i] for i in range(n)]
        bad = [i for i, v in fix.items() if (v == hi[i] and gr[i] > 0) or (v == lo[i] and gr[i] < 0)]
        if not bad: return U
        del fix[max(bad, key=lambda i: abs(gr[i]))]

def fista(H, f, lo, hi, iters):                        # road 2: accelerated projected gradient
    v = [1.0] * len(f)
    for _ in range(300): w = mv(H, v); L = max(abs(a) for a in w); v = [a / L for a in w]
    x = [0.0] * len(f); y, t = x[:], 1.0
    for _ in range(iters):
        xn = [min(h, max(lo_, a - (b + c) / L)) for a, b, c, lo_, h in zip(y, mv(H, y), f, lo, hi)]
        tn = (1 + sqrt(1 + 4 * t * t)) / 2; y = [a + (t - 1) / tn * (a - b) for a, b in zip(xn, x)]; x, t = xn, tn
    return x

def costate(x0, U, Pt):                                # road 3: simulate the plan, gradient by costate
    xs = [x0]
    for u in U: xs.append([a + b * u for a, b in zip(mv(A, xs[-1]), B)])
    J = sum(dot(Q, [v * v for v in x]) + R * u * u for x, u in zip(xs, U)) + dot(xs[-1], mv(Pt, xs[-1]))
    lam, grad = [2 * v for v in mv(Pt, xs[-1])], [0.0] * len(U)
    for k in range(len(U) - 1, -1, -1):
        grad[k] = 2 * R * U[k] + dot(B, lam)
        lam = [2 * q * v + a for q, v, a in zip(Q, xs[k], mv(tr(A), lam))]
    return J, grad, xs

def run(mode, d, ticks, H=None, F=None, um=UMAX, r=2.0):  # closed loop on the 20 Hz model
    x, dh, prev, log = [0.0] * 4, 0.0, None, []
    for k in range(ticks):
        if mode == "free" and prev:                    # disturbance state: what the last move missed
            e = [a - b - c * prev[1] for a, b, c in zip(x, mv(A, prev[0]), B)]; dh += 0.2 * (dot(B, e) / dot(B, B) - dh)
        xs_us = solve([[A[i][j] - (i == j) for j in range(4)] + [B[i]] for i in range(4)] + [[1, 0, 0, 0, 0]], [-b * dh for b in B] + [r])
        xe, us = [a - b for a, b in zip(x, xs_us[:4])], xs_us[4]
        if mode == "clip": u = max(-um, min(um, us - dot(K, xe)))
        else: n = len(F); u = us + active_set(H, mv(F, xe), [-um - us] * n, [um - us] * n)[0]
        log.append((x, u, dh, xe)); prev = (x, u)
        x = [a + b * (u + d) for a, b in zip(mv(A, x), B)]
    return log

H, F = build(N, P); x0 = [-2.0, 0.0, 0.0, 0.0]           # at rest, 2 m short of the target
U = active_set(H, mv(F, x0), [-UMAX] * N, [UMAX] * N); Uf = fista(H, mv(F, x0), [-UMAX] * N, [UMAX] * N, 20000)
J0, grad, plan = costate(x0, U, P); Uu = solve(H, [-v for v in mv(F, x0)])
kkt_free = max(abs(gv) for gv, u in zip(grad, U) if abs(u) < UMAX)
kkt_sign = min(-gv * u for gv, u in zip(grad, U) if abs(u) == UMAX)     # > 0: each limit is pressed against
mpc, clip = run("mpc", 0.0, 120, H, F), run("clip", 0.0, 120)
Js = [costate(e, active_set(H, mv(F, e), [-UMAX] * N, [UMAX] * N), P)[0] for _, _, _, e in mpc]
fall = lambda lg: next((f"{k * T:.2f} s" for k, (x, *_) in enumerate(lg) if abs(x[2]) > 0.5), "never")
plain, free = run("mpc", D, 200, H, F), run("free", D, 200, H, F)
ol = plan[0]
for u in U: ol = [a + b * (u + D) for a, b in zip(mv(A, ol), B)]           # the tick-0 plan, never replanned
H5, F5 = build(5, [[Q[i] * (i == j) for j in range(4)] for i in range(4)]); short = run("mpc", 0.0, 80, H5, F5)
H10, F10 = build(10, P); m10 = run("mpc", 0.0, 120, H10, F10)
clip15, mpc05, free2 = run("clip", 0.0, 120, um=1.5), run("mpc", 0.0, 120, H, F, um=0.5), run("free", 2 * D, 200, H, F)
f4 = lambda v: f"{v:.4f}"
print("discrete pendulum pole e^(4T)", f4(A[2][2] + sqrt(A[2][3] * A[3][2])), " B", " ".join(f4(b) for b in B))
print("LQR gain K", " ".join(f4(k) for k in K), " Riccati sweeps", it + 1)
print("tick-0 plan, A:", " ".join(f"{u:.3f}" for u in U))
print("road 2 projected gradient, largest gap", f"{max(abs(a - b) for a, b in zip(U, Uf)):.2e}")
print("road 3 costate: free-move gradient below 1e-9", kkt_free < 1e-9, " limit push", f4(kkt_sign), " plan cost", f4(J0))
print("no limit: QP first move", f4(Uu[0]), " LQR -K x0", f4(-dot(K, x0)))
print("plan angle peak rad", f4(max(abs(x[2]) for x in plan)), " plan end p", f4(plan[-1][0] + 2))
print("MPC: peak angle", f4(max(abs(x[2]) for x, *_ in mpc)), " p at 5.95 s", f4(mpc[-1][0][0]), " moves = plan to 1e-9", max(abs(a[1] - b) for a, b in zip(mpc, U)) < 1e-9)
print("MPC: optimal cost ticks 0,1,2,10", " ".join(f4(Js[k]) for k in (0, 1, 2, 10)), " rises", sum(b > a for a, b in zip(Js, Js[1:])))
print("MPC: cost drops", f4(Js[0] - Js[1]), f4(Js[1] - Js[2]), " stage costs", " ".join(f4(dot(Q, [v * v for v in e]) + R * u * u) for _, u, _, e in mpc[:2]))
print("clipped LQR: first moves", " ".join(f"{u:.3f}" for _, u, *_ in clip[:6]), " angle past 0.5 rad at", fall(clip))
print("push, plain MPC: p at 9.95 s", f4(plain[-1][0][0]), " offset", f4(plain[-1][0][0] - 2), " formula d/K_p", f4(D / K[0]))
print("push, offset-free: p at 9.95 s", f4(free[-1][0][0]), " d estimate", f4(free[-1][2]), " current", f4(free[-1][1]))
print("push, plan never replanned: angle at 1 s", f4(ol[2]), " planned", f4(plan[-1][2]))
print("N=5, no terminal cost: p at 2 s", f4(short[40][0][0]), " angle past 0.5 rad at", fall(short))
print("try: N=10 with P, peak angle", f4(max(abs(x[2]) for x, *_ in m10)), " limit 1.5 A, clipped LQR falls:", fall(clip15))
print("try: limit 0.5 A, MPC peak angle", f4(max(abs(x[2]) for x, *_ in mpc05)), " p at 5.95 s", f4(mpc05[-1][0][0]), " falls:", fall(mpc05))
print("try: push 1 N, offset-free p at 9.95 s", f4(free2[-1][0][0]), " current", f4(free2[-1][1]))
print("chart current, MPC  ", " ".join(f"{u:.2f}" for _, u, *_ in mpc[:20]))
print("chart current, clip ", " ".join(f"{u:.2f}" for _, u, *_ in clip[:20]))
print("chart p, plain      ", " ".join(f"{plain[k][0][0]:.2f}" for k in range(0, 200, 10)))
print("chart p, offset-free", " ".join(f"{free[k][0][0]:.2f}" for k in range(0, 200, 10)))
assert abs(A[2][2] + sqrt(A[2][3] * A[3][2]) - exp(0.2)) < 1e-9, "Van Loan pole vs e^(4T)"
assert max(abs(a - b) for a, b in zip(U, Uf)) < 1e-3, "active set vs projected gradient"
assert kkt_free < 1e-9 and kkt_sign > 0, "costate gradient certifies the plan"
assert abs(Uu[0] + dot(K, x0)) < 1e-8, "no limits: first planned move is the LQR move"
assert all(abs(u) <= UMAX + 1e-12 for _, u, *_ in mpc + free) and max(abs(x[2]) for x, *_ in mpc) < 0.25, "MPC keeps limits"
assert abs(plain[-1][0][0] - 2 - D / K[0]) < 1e-4 and abs(free[-1][0][0] - 2) < 1e-4, "offset, and its removal"
assert sum(b > a + 1e-9 for a, b in zip(Js, Js[1:])) == 0, "optimal cost never rises"
print("ALL CHECKS PASS")
