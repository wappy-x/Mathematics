# Linearisation about an equilibrium -- the check behind the card.  Standard library only.
# Road 1: the slopes (Jacobians) written out by hand.  Road 2: the same slopes by nudging
# the curved model.  Road 3: the curved model stepped by RK4 against the straight one.
from math import sin, cos, tan, sqrt, cosh, acosh, log, exp, pi

G, L = 9.81, 0.613125                      # gravity m/s^2; pole length m, so G/L = 16 per s^2

def f(x, u):                               # curved model: state (p, v, th, w), input u = cart accel
    p, v, th, w = x
    return [v, u, w, (G * sin(th) - u * cos(th)) / L]

def h(x):                                  # outputs: encoder angle; tip position p + L sin th
    return [x[2], x[0] + L * sin(x[2])]

def by_hand(te):                           # Road 1, at lean te held by ue = G tan te
    ue = G * tan(te)
    A = [[0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, (G * cos(te) + ue * sin(te)) / L, 0]]
    return ue, A, [0, 1, 0, -cos(te) / L], [[0, 0, 1, 0], [1, 0, L * cos(te), 0]]

def by_nudge(te, e=1e-6):                  # Road 2: central differences, one variable at a time
    xe, ue = [0.0, 0.0, te, 0.0], G * tan(te)
    A = [[0.0] * 4 for _ in range(4)]; C = [[0.0] * 4 for _ in range(2)]
    for j in range(4):
        xp, xm = xe[:], xe[:]; xp[j] += e; xm[j] -= e
        for i in range(4): A[i][j] = (f(xp, ue)[i] - f(xm, ue)[i]) / (2 * e)
        for i in range(2): C[i][j] = (h(xp)[i] - h(xm)[i]) / (2 * e)
    B = [(a - b) / (2 * e) for a, b in zip(f(xe, ue + e), f(xe, ue - e))]
    return A, B, C

def gap(P, Q): return max(abs(a - b) for a, b in zip(sum(P, []), sum(Q, [])))

def rk4(rate, y, dt, n):                   # lean loop only: y = (th, w)
    for _ in range(n):
        k1 = rate(y); k2 = rate([a + dt / 2 * b for a, b in zip(y, k1)])
        k3 = rate([a + dt / 2 * b for a, b in zip(y, k2)]); k4 = rate([a + dt * b for a, b in zip(y, k3)])
        y = [a + dt / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]
    return y

def curved(u): return lambda y: [y[1], (G * sin(y[0]) - u(y) * cos(y[0])) / L]
def straight(a, b, u): return lambda y: [y[1], a * y[0] + b * u(y)]
off = lambda y: 0.0
K1, K2 = 32.0, 8.0                         # balancing rule u = L (32 th + 8 w), poles -4, -4
rule = lambda y: L * (K1 * y[0] + K2 * y[1])
fmt = lambda v: " ".join("%.3f" % x for x in v)

# ---- the upright operating point ----
ue, A, B, C = by_hand(0.0)
An, Bn, Cn = by_nudge(0.0)
print("equilibrium: rates at upright, u = 0:", fmt(f([0, 0, 0, 0], 0.0)))
print("A row 4 by hand", fmt(A[3]), "| by nudging", fmt(An[3]))
print("B by hand", fmt(B), "| by nudging", fmt(Bn))
print("C by hand", fmt(C[0]), "/", fmt(C[1]), "| D = 0")
print("eigenvalues 0, 0, +-%.4f per s; doubling ln2/4 = %.4f s" % (sqrt(A[3][2]), log(2) / sqrt(A[3][2])))
assert gap(A, An) < 1e-6 and gap([B], [Bn]) < 1e-6 and gap(C, Cn) < 1e-6

# ---- the leaning operating point, held by a steady push ----
te = 0.3
ue, Al, Bl, Cl = by_hand(te)
Aln, Bln, Cln = by_nudge(te)
print("lean %.1f rad (%.2f deg): ue = %.4f m/s^2; lean rates there" % (te, te * 180 / pi, ue), fmt(f([0, 0, te, 0], ue)[2:]))
print("lean: a = %.4f per s^2 (16/cos 0.3 = %.4f), b = %.4f, C tip row %s, growth %.4f per s"
      % (Al[3][2], 16 / cos(te), Bl[3], fmt(Cl[1]), sqrt(Al[3][2])))
assert gap(Al, Aln) < 1e-6 and abs(Bl[3] - Bln[3]) < 1e-6 and abs(Al[3][2] - 16 / cos(te)) < 1e-9 and gap(Cl, Cln) < 1e-6
print("tilted gravity sqrt(g^2 + ue^2) = %.4f m/s^2, over L = %.4f per s^2" % (sqrt(G * G + ue * ue), sqrt(G * G + ue * ue) / L))
for t in (0.1, 0.5):
    print("straight model off at %.1f rad: gravity term %.2f%%, motor term %.2f%%" % (t, 100 * (1 - sin(t) / t), 100 * (1 - cos(t))))

# ---- road 3: let go with the motor off; straight versus curved ----
lin = rk4(straight(16.0, 0.0, off), [0.001, 0.0], 0.001, 1000)[0]
tru = rk4(curved(off), [0.001, 0.0], 0.001, 1000)[0]
print("from 1 mrad, at 1 s: cosh %.4f mrad, straight RK4 %.4f, curved RK4 %.4f" % (cosh(4), 1000 * lin, 1000 * tru))
assert abs(lin - 0.001 * cosh(4)) < 1e-9

def reach(rate, y, target, dt=1e-4):       # time for the lean to reach target
    t = 0.0
    while y[0] < target: y = rk4(rate, y, dt, 1); t += dt
    return t
tl, tc = acosh(10) / 4, reach(curved(off), [0.05, 0.0], 0.5)
print("from 0.05 rad to 0.5 rad: straight acosh(10)/4 = %.4f s, curved %.4f s" % (tl, tc))

def err(a, b, u0, d, at):                  # curved minus straight, deviation d at the start
    yc = rk4(curved(lambda y: u0), [te0 + d, 0.0], 0.001, int(at / 0.001))
    ys = rk4(straight(a, b, lambda y: 0.0), [d, 0.0], 0.001, int(at / 0.001))
    return abs(yc[0] - te0 - ys[0])
te0 = 0.0; e1, e2 = err(16.0, B[3], 0.0, 0.02, 0.5), err(16.0, B[3], 0.0, 0.01, 0.5)
te0 = te;  g1, g2 = err(Al[3][2], Bl[3], ue, 0.02, 0.5), err(Al[3][2], Bl[3], ue, 0.01, 0.5)
print("error at 0.5 s in microrad, start 0.02 vs 0.01 rad: upright %.3f %.3f ratio %.2f | lean %.3f %.3f ratio %.2f"
      % (1e6 * e1, 1e6 * e2, e1 / e2, 1e6 * g1, 1e6 * g2, g1 / g2))
assert 7.5 < e1 / e2 < 8.5 and 7.5 < g1 / g2 < 8.5      # leftover is cubic at both points

# ---- the balancing rule designed on the straight model, run on the curved one ----
def caught(t0):
    y = [t0, 0.0]
    for _ in range(1000):
        y = rk4(curved(rule), y, 0.005, 1)
        if abs(y[0]) > pi / 2: return False
    return abs(y[0]) < 0.01
lo, hi = 0.5, 1.5
for _ in range(30): lo, hi = ((lo + hi) / 2, hi) if caught((lo + hi) / 2) else (lo, (lo + hi) / 2)
a, b = 0.5, 1.5                            # independent road: where 16 sin th = 32 th cos th
for _ in range(60): a, b = ((a + b) / 2, b) if tan((a + b) / 2) < 2 * (a + b) / 2 else (a, (a + b) / 2)
print("largest lean caught: by simulation %.4f rad (%.1f deg), root of tan th = 2 th %.4f rad" % (lo, lo * 180 / pi, a))
assert abs(lo - a) < 1e-3
s = rk4(curved(rule), [0.3, 0.0], 0.005, 200)[0]
print("from 0.3 rad at 1 s: straight 0.3(1+4t)e^-4t = %.5f rad, curved %.5f rad" % (0.3 * 5 * exp(-4), s))

print("bars, th 0.3 0.6 0.9 1.2: gravity 16 sin th", fmt([16 * sin(t) for t in (0.3, 0.6, 0.9, 1.2)]),
      "| rule 32 th cos th", fmt([32 * t * cos(t) for t in (0.3, 0.6, 0.9, 1.2)]))
# ---- what breaks ----
print("wrong: absolute th, u in the lean model: rate at the held point %.4f rad/s^2" % (Al[3][2] * te + Bl[3] * ue))
print("wrong: upright model used at the lean: a %.4f vs %.4f, b %.4f vs %.4f" % (A[3][2], Al[3][2], B[3], Bl[3]))
print("wrong: motor grip at the lean is %.2f%% weaker; lean in degrees: B entry x %.2f = %.2f, eigenvalues still +-%.4f"
      % (100 * (1 - Bl[3] / B[3]), 180 / pi, B[3] * 180 / pi, sqrt(A[3][2])))
print("wrong: slopes taken at 0.3 rad with u = 0, not a rest: lean rate %.4f rad/s^2" % (16 * sin(te)))

# ---- try changing ----
print("try: L = 1.0 m: growth %.4f per s, doubling %.4f s" % (sqrt(G / 1.0), log(2) / sqrt(G / 1.0)))
print("try: lean 0.6 rad: ue %.4f m/s^2, a %.4f, b %.4f" % (G * tan(0.6), 16 / cos(0.6), -cos(0.6) / L))
a, b = 0.5, 1.55
for _ in range(60): a, b = ((a + b) / 2, b) if tan((a + b) / 2) < 4 * (a + b) / 2 else (a, (a + b) / 2)
print("try: gains doubled (64, 16): largest lean caught %.4f rad (%.1f deg)" % (a, a * 180 / pi))

# ---- chart points ----
print("chart, th rad:        ", " ".join("%.1f" % (k / 10) for k in range(0, 17, 2)))
print("chart, 16 sin th:     ", " ".join("%.2f" % (16 * sin(k / 10)) for k in range(0, 17, 2)))
print("chart, 16 th:         ", " ".join("%.2f" % (16 * k / 10) for k in range(0, 17, 2)))
for t0 in (1.0, 1.2):
    y, row = [t0, 0.0], ["%.3f" % t0]
    for _ in range(10): y = rk4(curved(rule), y, 0.005, 20); row.append("%.3f" % min(y[0], pi / 2))
    print("chart, curved from %.1f:" % t0, " ".join(row))
print("chart, straight 1.0:  ", " ".join("%.3f" % ((1 + 0.4 * k) * exp(-0.4 * k)) for k in range(11)))
print("ALL CHECKS PASS")
