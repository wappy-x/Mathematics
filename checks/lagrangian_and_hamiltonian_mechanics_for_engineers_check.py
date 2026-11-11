# Lagrangian and Hamiltonian mechanics for engineers -- the check behind the card.
# Standard library only. Road 1: equations from T - V. Road 2: Newton-Euler free-body
# diagrams, link by link. Road 3: Hamilton's equations with dH/dq by numerical slopes.
from math import sin, cos, pi, sqrt
G = 9.81                                      # m/s^2, standard gravity 9.80665 rounded
GA = G                                        # gravity in the arm's plane, m/s^2: 0.0 lays the arm flat
M1, L1, M2, L2 = 4.0, 0.5, 2.5, 0.4           # upper arm and forearm: kg, m (uniform links)
A1, A2 = L1 / 2, L2 / 2                       # joint to centre of mass, m
I1, I2 = M1 * L1**2 / 12, M2 * L2**2 / 12     # each link about its own centre, kg m^2
def mass(q):                                  # the mass matrix, read off T
    c = cos(q[1]); m12 = I2 + M2 * (A2**2 + L1 * A2 * c)
    return [[I1 + I2 + M1 * A1**2 + M2 * (L1**2 + A2**2 + 2 * L1 * A2 * c), m12], [m12, I2 + M2 * A2**2]]
def grav(q, g=GA):                             # dV/dq: the torque gravity asks of each motor
    return [g * ((M1 * A1 + M2 * L1) * cos(q[0]) + M2 * A2 * cos(q[0] + q[1])), g * M2 * A2 * cos(q[0] + q[1])]
def vterm(q, v):                              # velocity terms of d/dt(dL/dq') - dL/dq
    h = M2 * L1 * A2 * sin(q[1]); return [-h * v[1] * (2 * v[0] + v[1]), h * v[0]**2]
def solve(m, b):                              # 2 x 2 linear solve, by Cramer's rule
    d = m[0][0] * m[1][1] - m[0][1] * m[1][0]
    return [(b[0] * m[1][1] - m[0][1] * b[1]) / d, (m[0][0] * b[1] - m[1][0] * b[0]) / d]
def torque_lagrange(q, v, a, sign=1.0):       # tau = M a + velocity terms + gravity; sign -1: L = T + V
    m, c, g = mass(q), vterm(q, v), grav(q)
    return [m[i][0] * a[0] + m[i][1] * a[1] + c[i] + sign * g[i] for i in range(2)]
def cross(r, f): return r[0] * f[1] - r[1] * f[0]
def newton_euler(q, v, a):                    # free-body diagrams; returns torques and elbow pin force
    u1, n1 = (cos(q[0]), sin(q[0])), (-sin(q[0]), cos(q[0]))
    u2, n2 = (cos(q[0] + q[1]), sin(q[0] + q[1])), (-sin(q[0] + q[1]), cos(q[0] + q[1]))
    w2, al2 = v[0] + v[1], a[0] + a[1]
    ac1 = [A1 * (a[0] * n1[i] - v[0]**2 * u1[i]) for i in range(2)]
    ae = [L1 * (a[0] * n1[i] - v[0]**2 * u1[i]) for i in range(2)]
    ac2 = [ae[i] + A2 * (al2 * n2[i] - w2**2 * u2[i]) for i in range(2)]
    f2 = [M2 * ac2[0], M2 * (ac2[1] + GA)]     # pin force of upper arm on forearm, N
    t2 = I2 * al2 + cross([A2 * u2[0], A2 * u2[1]], f2)
    t1 = t2 + cross([L1 * u1[0], L1 * u1[1]], f2) + I1 * a[0] + cross([A1 * u1[0], A1 * u1[1]], [M1 * ac1[0], M1 * (ac1[1] + GA)])
    return [t1, t2], f2
def V(q): return GA * (M1 * A1 * sin(q[0]) + M2 * (L1 * sin(q[0]) + A2 * sin(q[0] + q[1])))
def energy(q, v):
    m = mass(q); return 0.5 * sum(v[i] * m[i][j] * v[j] for i in range(2) for j in range(2)) + V(q)
def t_slices(q, v, n=2000):                   # T summed over thin slices of each link: no inertia formula used
    n1, n2 = (-sin(q[0]), cos(q[0])), (-sin(q[0] + q[1]), cos(q[0] + q[1]))
    return sum(0.5 * M1 / n * (s * L1 * v[0])**2 + 0.5 * M2 / n * sum((L1 * v[0] * n1[i] + s * L2 * (v[0] + v[1]) * n2[i])**2 for i in range(2)) for s in ((k + 0.5) / n for k in range(n)))
def H(q, p):                                  # Hamiltonian: kinetic energy in momenta, plus V
    v = solve(mass(q), p); return 0.5 * (p[0] * v[0] + p[1] * v[1]) + V(q)
def mom(s):                                   # joint momenta p = M q' from a state (angles, speeds)
    m = mass(s[:2]); return [m[i][0] * s[2] + m[i][1] * s[3] for i in range(2)]
def rk4(f, s, h, n):
    out = [s]
    for _ in range(n):
        k1 = f(s); k2 = f([x + h / 2 * k for x, k in zip(s, k1)])
        k3 = f([x + h / 2 * k for x, k in zip(s, k2)]); k4 = f([x + h * k for x, k in zip(s, k3)])
        s = [x + h / 6 * (a + 2 * b + 2 * c + d) for x, a, b, c, d in zip(s, k1, k2, k3, k4)]; out.append(s)
    return out
def lag_rate(s, vt=True):                     # power cut: tau = 0, solve M a = -(velocity terms) - gravity
    q, v = s[:2], s[2:]; c = vterm(q, v) if vt else [0.0, 0.0]; g = grav(q)
    return v + solve(mass(q), [-c[0] - g[0], -c[1] - g[1]])
def ham_rate(s, e=1e-6):                      # q' = dH/dp = M^-1 p,  p' = -dH/dq by central slopes
    q, p = s[:2], s[2:]
    dq = [(H([q[0] + e * (i == 0), q[1] + e * (i == 1)], p) - H([q[0] - e * (i == 0), q[1] - e * (i == 1)], p)) / (2 * e) for i in range(2)]
    return solve(mass(q), p) + [-dq[0], -dq[1]]
deg = lambda x: x * 180 / pi
sci = lambda x: f"{x:.2e}".replace("e-0", "e-")      # exponent written as Rust writes it
m0, h0 = mass([0.0, 0.0]), M2 * L1 * A2
print(f"arm: m1 {M1} kg, l1 {L1} m, m2 {M2} kg, l2 {L2} m, g {GA} m/s^2; I1 {I1:.6f}, I2 {I2:.6f} kg m^2")
print(f"mass matrix, arm straight out: M11 {m0[0][0]:.6f}, M12 {m0[0][1]:.6f}, M22 {m0[1][1]:.6f} kg m^2; h = m2 l1 a2 = {h0:.6f} kg m^2")
hold = torque_lagrange([0.0, 0.0], [0.0, 0.0], [0.0, 0.0]); hold_ne, f_hold = newton_euler([0.0, 0.0], [0.0, 0.0], [0.0, 0.0])
print(f"hold straight out: shoulder {hold[0]:.4f} N m, elbow {hold[1]:.4f} N m (Newton-Euler {hold_ne[0]:.4f}, {hold_ne[1]:.4f})")
lift = torque_lagrange([0.0, 0.0], [0.0, 0.0], [6.0, 0.0]); lift_ne, f_lift = newton_euler([0.0, 0.0], [0.0, 0.0], [6.0, 0.0])
print(f"start lift, shoulder 6 rad/s^2, elbow locked: shoulder {lift[0]:.4f} N m, elbow {lift[1]:.4f} N m (Newton-Euler {lift_ne[0]:.4f}, {lift_ne[1]:.4f})")
print(f"lift budget: shoulder gravity {hold[0]:.4f} + inertia {lift[0] - hold[0]:.4f}; elbow gravity {hold[1]:.4f} + coupling {lift[1] - hold[1]:.4f} N m")
print(f"elbow pin force on forearm: holding {f_hold[0] + 0.0:.4f}, {f_hold[1]:.4f} N; start of lift {f_lift[0] + 0.0:.4f}, {f_lift[1]:.4f} N (across, up)")
tests = [([0.3, 0.8], [1.5, -2.0], [4.0, -3.0]), ([-1.2, 2.1], [-0.7, 3.3], [-2.5, 6.0]), ([2.0, -1.0], [2.2, 1.1], [0.5, 1.5]),
         ([0.0, pi / 2], [3.0, 0.0], [0.0, 0.0]), ([-pi / 2, 0.4], [0.0, -4.0], [1.0, 1.0])]
ts, tm = t_slices([0.3, 0.8], [1.5, -2.0]), energy([0.3, 0.8], [1.5, -2.0]) - V([0.3, 0.8])
print(f"kinetic energy at 0.3, 0.8 rad moving at 1.5, -2.0 rad/s: mass matrix {tm:.6f} J, 2000 thin slices {ts:.6f} J")
gap = max(abs(x - y) for q, v, a in tests for x, y in zip(torque_lagrange(q, v, a), newton_euler(q, v, a)[0]))
spin = torque_lagrange([0.0, pi / 2], [3.0, 0.0], [0.0, 0.0])
print(f"Lagrange against Newton-Euler, 5 moving states: largest torque gap {sci(gap)} N m")
print(f"elbow bent 90 deg, shoulder turning 3 rad/s steadily: shoulder {spin[0]:.4f}, elbow {spin[1]:.4f} N m, of which velocity term {spin[1] - grav([0.0, pi / 2])[1]:.4f}")
S0 = [0.0, 0.0, 0.0, 0.0]                     # power-cut start: shoulder, elbow angles, rad; their speeds, rad/s
lag = rk4(lag_rate, S0, 0.001, 1000)
ham = rk4(ham_rate, S0[:2] + mom(S0), 0.001, 1000)
bad = rk4(lambda s: lag_rate(s, False), S0, 0.001, 300)
a0 = lag_rate(S0)[2:]
print(f"power cut, first instant: shoulder {a0[0]:.4f}, elbow {a0[1]:.4f}, forearm absolute {a0[0] + a0[1]:.4f} rad/s^2; forearm alone on a fixed elbow {-grav([0.0, 0.0])[1] / m0[1][1]:.4f}")
print("power cut, arm straight out at rest; t = 0, 0.1 ... 1 s")
print("  shoulder angle, deg:", " ".join(f"{deg(lag[k][0]):.1f}" for k in range(0, 1001, 100)))
print("  elbow angle, deg:   ", " ".join(f"{deg(lag[k][1]):.1f}" for k in range(0, 1001, 100)))
e_lag = [energy(s[:2], s[2:]) for s in lag]; e_ham = [H(s[:2], s[2:]) for s in ham]
print(f"at 1 s: Lagrange road {lag[-1][0]:.6f}, {lag[-1][1]:.6f} rad; Hamilton road {ham[-1][0]:.6f}, {ham[-1][1]:.6f} rad")
print(f"energy, J: Lagrange road {sci(min(e_lag))} to {sci(max(e_lag))}; Hamilton road {sci(min(e_ham))} to {sci(max(e_ham))}")
print(f"shoulder momentum p1: start {mom(lag[0])[0]:.4f}; at 1 s Lagrange road {mom(lag[-1])[0]:.4f}, Hamilton road {ham[-1][2]:.4f} kg m^2/s")
s3 = ham[300]; v3 = solve(mass(s3[:2]), s3[2:])
print(f"at 0.3 s: angles {deg(s3[0]):.2f}, {deg(s3[1]):.2f} deg; momenta p1 {s3[2]:.4f}, p2 {s3[3]:.4f} kg m^2/s; speeds {v3[0]:.4f}, {v3[1]:.4f} rad/s")
tip = lambda s: sqrt((L1 * s[2] * sin(s[0]) + L2 * (s[2] + s[3]) * sin(s[0] + s[1]))**2 + (L1 * s[2] * cos(s[0]) + L2 * (s[2] + s[3]) * cos(s[0] + s[1]))**2)
kpk = max(range(1001), key=lambda k: tip(lag[k]))
print(f"peak tip speed in the first second {tip(lag[kpk]):.3f} m/s at {kpk / 1000:.3f} s")
print(f"mistake, velocity terms dropped: elbow at 0.3 s {deg(bad[-1][1]):.2f} deg (true {deg(lag[300][1]):.2f}); energy {energy(bad[-1][:2], bad[-1][2:]):.4f} J (true 0)")
mist = torque_lagrange([0.0, 0.0], [0.0, 0.0], [6.0, 0.0], -1.0)
print(f"mistake, L = T + V: start-lift torques {mist[0]:.4f}, {mist[1]:.4f} N m; mistake, coupling M12 dropped: elbow {grav([0.0, 0.0])[1]:.4f} N m")
MP, LP, TH0 = 2.0, 0.5, pi / 3                # pendulum: 2 kg on a 0.5 m rod, released at 60 deg
def pend_rate(s):                             # Cartesian x, y with the rod as a constraint; lambda = -T
    x, y, vx, vy = s; t = MP * (vx * vx + vy * vy - G * y) / LP
    return [vx, vy, -t * x / (MP * LP), -G - t * y / (MP * LP)]
pend = rk4(pend_rate, [LP * sin(TH0), -LP * cos(TH0), 0.0, 0.0], 0.0001, 5000)
k = next(i for i in range(5000) if pend[i][0] > 0 >= pend[i + 1][0])
ten = [MP * (s[2]**2 + s[3]**2 - G * s[1]) / LP for s in pend[k:k + 2]]; fr = pend[k][0] / (pend[k][0] - pend[k + 1][0])
t_sim, t_energy = ten[0] + fr * (ten[1] - ten[0]), MP * G * (3 - 2 * cos(TH0))
print(f"pendulum 2 kg, 0.5 m, from 60 deg: tension at release {MP * G * cos(TH0):.4f} N; at the bottom, simulated {t_sim:.4f} N, energy formula {t_energy:.4f} N ({t_energy / (MP * G):.4f} x weight)")
print(f"  bottom reached at {(k + fr) / 10000:.4f} s; rod length drift {sci(sqrt(pend[k][0]**2 + pend[k][1]**2) - LP)} m")
print(f"outside the model: cable released from 120 deg, multiplier says tension {MP * G * cos(2 * pi / 3):.4f} N: a cable cannot push, it goes slack")
print(f"try: forearm 1.25 kg, holding {GA * (M1 * A1 + 1.25 * L1 + 1.25 * A2):.4f} N m; elbow up 90 deg, holding {grav([0.0, pi / 2])[0]:.4f} N m; pendulum from 90 deg, bottom tension {MP * G * 3:.4f} N")
fig = [(40 + 400 * L1 * cos(s[0]), 60 - 400 * L1 * sin(s[0]), 40 + 400 * (L1 * cos(s[0]) + L2 * cos(s[0] + s[1])), 60 - 400 * (L1 * sin(s[0]) + L2 * sin(s[0] + s[1]))) for s in (lag[0], lag[300])]
print("figure, 400 units per metre, shoulder 40.0,60.0: held elbow %.1f,%.1f tip %.1f,%.1f; at 0.3 s elbow %.1f,%.1f tip %.1f,%.1f" % (fig[0] + fig[1]))
com = [(40 + 400 * A1 * cos(s[0]), 60 - 400 * A1 * sin(s[0]), 40 + 400 * (L1 * cos(s[0]) + A2 * cos(s[0] + s[1])), 60 - 400 * (L1 * sin(s[0]) + A2 * sin(s[0] + s[1]))) for s in (lag[0], lag[300])]
print("figure, centres of mass: held %.1f,%.1f and %.1f,%.1f; at 0.3 s %.1f,%.1f and %.1f,%.1f" % (com[0] + com[1]))
assert abs(hold[0] - GA * (M1 * A1 + M2 * (L1 + A2))) < 1e-9 and gap < 1e-9          # Lagrange = statics = Newton-Euler
assert abs(ts - tm) < 1e-6 * tm                                                      # mass matrix = slice-by-slice energy
assert abs(lift[1] - lift_ne[1]) < 1e-9 and abs(lift[0] - lift_ne[0]) < 1e-9          # coupling torque seen by both roads
assert abs(lag[-1][0] - ham[-1][0]) < 1e-6 and abs(lag[-1][1] - ham[-1][1]) < 1e-6     # Lagrange road = Hamilton road
assert max(abs(e - e_lag[0]) for e in e_lag + e_ham) < 1e-6                         # energy conserved with motors off
assert abs(t_sim - t_energy) < 1e-3 * t_energy                                        # multiplier = energy + circular motion
print("ALL CHECKS PASS")
