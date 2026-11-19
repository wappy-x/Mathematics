# Noether's theorem -- the check behind the card.  Standard library only.
# A skater spins at 1.5 rev/s and pulls her arms in. Model: a body that turns (angle psi,
# inertia I0) and two 3 kg arm masses at Cartesian points (x, y), each held by a stiff spring to
# a point on the body that is pulled from 0.65 m to 0.20 m. No coordinate is missing from L.
# Road 1: the closed form J = I w.  Road 2: RK4 on all five coordinates, J = g(q', X) watched.
# Road 3: Noether's test: flow the state along X and see whether L notices.
# Road 4: free flight on a sphere, three Killing fields, chart (phi, theta) against r x v.
from math import pi, sin, cos, sqrt, radians, degrees
I0, M, K = 0.80, 3.0, 1.0e7        # body kg m^2; each arm kg; arm spring N/m
R_OUT, R_IN, REV0 = 0.65, 0.20, 1.5  # arm radius out and in, m; starting spin, rev/s
DT, T_END, DRAG = 5e-5, 1.5, 0.0   # step s; run s; ice drag torque N m (0: none)

def r0(t):                         # where the body holds the arms: smooth pull from 0.25 s to 1.25 s
    u = min(max((t - 0.25) / 1.0, 0.0), 1.0)
    return R_OUT + (R_IN - R_OUT) * (3*u*u - 2*u*u*u)
def anchors(psi, t):               # arm k is held at angle psi + k pi on the body
    return [(r0(t)*cos(psi + k*pi), r0(t)*sin(psi + k*pi)) for k in (0, 1)]
def V(q, t):                       # spring energy, J
    psi, pts = q[0], [(q[1], q[2]), (q[3], q[4])]
    return sum(0.5*K*((x - a)**2 + (y - b)**2) for (x, y), (a, b) in zip(pts, anchors(psi, t)))
def L(q, v, t):                    # kinetic metric: I0 dpsi^2 + M (dx^2 + dy^2) per arm
    return 0.5*I0*v[0]**2 + 0.5*M*sum(c*c for c in v[1:]) - V(q, t)
def accel(q, v, t, drag):          # Euler-Lagrange: metric times acceleration = -grad V
    psi, f = q[0], [0.0]*5
    for k, (a, b) in enumerate(anchors(psi, t)):
        dx, dy = q[1+2*k] - a, q[2+2*k] - b
        f[1+2*k], f[2+2*k] = -K*dx, -K*dy
        f[0] += K*(dx*(-b) + dy*a)          # -dV/dpsi; d(anchor)/dpsi = (-b, a)
    return [(f[0] - drag) / I0] + [c / M for c in f[1:]]
def J(q, v):                       # g(q', X), X = turn everything about the vertical axis
    return I0*v[0] + M*sum(q[1+2*k]*v[2+2*k] - q[2+2*k]*v[1+2*k] for k in (0, 1))
def D(q, v):                       # g(q', X) for X = stretch the arms outward: not Killing
    return M*sum(q[1+2*k]*v[1+2*k] + q[2+2*k]*v[2+2*k] for k in (0, 1))
def inertia(q): return I0 + M*sum(q[1+2*k]**2 + q[2+2*k]**2 for k in (0, 1))
def rk4(q, v, t, h, drag):         # classical RK4 on the state (q, q')
    ad = lambda y, k, s: [a + s*b for a, b in zip(y, k)]
    a1 = accel(q, v, t, drag); v1 = v
    v2 = ad(v, a1, h/2); a2 = accel(ad(q, v1, h/2), v2, t + h/2, drag)
    v3 = ad(v, a2, h/2); a3 = accel(ad(q, v2, h/2), v3, t + h/2, drag)
    v4 = ad(v, a3, h); a4 = accel(ad(q, v3, h), v4, t + h, drag)
    q2 = [q[i] + h/6*(v1[i] + 2*v2[i] + 2*v3[i] + v4[i]) for i in range(5)]
    v2n = [v[i] + h/6*(a1[i] + 2*a2[i] + 2*a3[i] + a4[i]) for i in range(5)]
    return q2, v2n
def run(drag, dt=DT):
    w = 2*pi*REV0
    q, v, t, out = [0.0, R_OUT, 0.0, -R_OUT, 0.0], [w, 0.0, w*R_OUT, 0.0, -w*R_OUT], 0.0, []
    n = round(T_END / dt)
    for i in range(n + 1):
        if i % (n // 10) == 0: out.append((t, q[:], v[:]))
        if i < n: q, v = rk4(q, v, t, dt, drag); t = (i + 1)*dt
    return out

# Road 1: the closed form
I_out, I_in = I0 + 2*M*R_OUT**2, I0 + 2*M*R_IN**2
w0 = 2*pi*REV0; J0 = I_out*w0; rev_in = REV0*I_out/I_in
KE0, KE1 = 0.5*I_out*w0**2, 0.5*I_in*(J0/I_in)**2
print("inertia out %.4f kg m^2, in %.4f kg m^2, ratio %.4f" % (I_out, I_in, I_out/I_in))
print("closed form: w0 = %.4f rad/s, J = %.4f kg m^2/s; spin %.2f -> %.4f rev/s" % (w0, J0, REV0, rev_in))
print("spin energy %.1f J -> %.1f J; her arms supply %.1f J" % (KE0, KE1, KE1 - KE0))
# Road 2: all five coordinates stepped, no symmetry assumed by the code
snaps, half = run(DRAG), run(DRAG, DT/2)       # the second run checks the step size
Js = [J(q, v) for _, q, v in snaps]
print("chart t (s):       " + " ".join("%.2f" % t for t, _, _ in snaps))
print("chart spin (rev/s): " + " ".join("%.2f" % (v[0]/(2*pi)) for _, _, v in snaps))
print("chart I (kg m^2):  " + " ".join("%.2f" % inertia(q) for _, q, _ in snaps))
print("chart J (kg m^2/s): " + " ".join("%.2f" % j for j in Js))
tq, qe, ve = snaps[-1]
rev_sim, rev2 = ve[0]/(2*pi), half[-1][2][0]/(2*pi); jdrift = max(abs(j - Js[0]) for j in Js)/Js[0]
E0 = 0.5*sum(c*c for c in snaps[0][2][1:])*M + 0.5*I0*snaps[0][2][0]**2 + V(snaps[0][1], 0)
E1 = 0.5*sum(c*c for c in ve[1:])*M + 0.5*I0*ve[0]**2 + V(qe, tq)
print("stepped: spin at %.2f s = %.4f rev/s, at half the step %.4f (gap %.6f); J drift %.1e of J"
      % (tq, rev_sim, rev2, abs(rev2 - rev_sim), jdrift))
print("stepped: energy %.1f J -> %.1f J (the pull changes L with time)" % (E0, E1))
print("body alone I0 psi': %.2f -> %.2f kg m^2/s" % (I0*snaps[0][2][0], I0*ve[0]))
Ds = [D(q, v) for _, q, v in snaps]
print("stretch field X = (x, y): its momentum runs %.4f to %.4f kg m^2/s" % (max(Ds), min(Ds)))
# Road 3: Noether's test at t = 0.6 s, early in the pull
t3, q3, v3 = snaps[4]; e = 1e-6
def turn_all(q, v, s):             # the flow of X: every part turned by angle s
    c, z = cos(s), sin(s); out_q, out_v = [q[0] + s], [v[0]]
    for k in (0, 1):
        x, y, vx, vy = q[1+2*k], q[2+2*k], v[1+2*k], v[2+2*k]
        out_q += [c*x - z*y, z*x + c*y]; out_v += [c*vx - z*vy, z*vx + c*vy]
    return out_q, out_v
dL_all = (L(*turn_all(q3, v3, e), t3) - L(*turn_all(q3, v3, -e), t3)) / (2*e)
qb, qa = q3[:], q3[:]; qb[0] += e; qa[0] -= e
dL_body = (L(qb, v3, t3) - L(qa, v3, t3)) / (2*e)
print("Noether test at %.2f s: turn everything dL/ds = %.4f J/rad; turn body only %.1f J/rad"
      % (t3, dL_all + 0.0, dL_body))
def lie(X, x, y, d=1e-6):          # (L_X g)/m = d_i X_j + d_j X_i, by central differences
    G = [[(X(x + d, y)[j] - X(x - d, y)[j]) / (2*d) for j in (0, 1)],
         [(X(x, y + d)[j] - X(x, y - d)[j]) / (2*d) for j in (0, 1)]]
    return [[round(G[i][j] + G[j][i], 6) + 0.0 for j in (0, 1)] for i in (0, 1)]
lie_rot, lie_str = lie(lambda x, y: (-y, x), 0.3, 0.5), lie(lambda x, y: (x, y), 0.3, 0.5)
flat = lambda G: " ".join("%.1f" % c for r in G for c in r)
print("Killing test, (L_X g)/m entries: turn %s; stretch %s" % (flat(lie_rot), flat(lie_str)))
# What breaks: energy kept instead of J; drag on the blade
rev_energy, sd = REV0*sqrt(I_out/I_in), run(0.05); Jd = J(sd[-1][1], sd[-1][2])
print("energy kept by mistake: %.4f rev/s" % rev_energy)
print("blade drag 0.05 N m: J %.4f -> %.4f, spin at %.2f s %.4f rev/s"
      % (J(sd[0][1], sd[0][2]), Jd, sd[-1][0], sd[-1][2][0]/(2*pi)))
# Road 4: free flight on a sphere of radius 6371 km, London heading 288 deg at 900 km/h
RE, SPD, p, th, hd = 6371.0, 900.0, radians(90 - 51.5074), radians(-0.1278), radians(288)
dp, dth = -SPD*cos(hd)/RE, SPD*sin(hd)/(RE*sin(p))   # north is -phi; east is +theta
def kill(p, th, dp, dth):          # J_i = g(q', X_i), g = RE^2 (dphi^2 + sin^2 phi dtheta^2)
    X = [(-sin(th), -cos(p)/sin(p)*cos(th)), (cos(th), -cos(p)/sin(p)*sin(th)), (0.0, 1.0)]
    return [RE*RE*(dp*a + sin(p)**2*dth*b) for a, b in X]
def cart(p, th, dp, dth):          # the same from r x v in x, y, z
    r = [RE*sin(p)*cos(th), RE*sin(p)*sin(th), RE*cos(p)]
    u = [RE*(cos(p)*cos(th)*dp - sin(p)*sin(th)*dth), RE*(cos(p)*sin(th)*dp + sin(p)*cos(th)*dth),
         -RE*sin(p)*dp]
    return [r[1]*u[2] - r[2]*u[1], r[2]*u[0] - r[0]*u[2], r[0]*u[1] - r[1]*u[0]]
def geo(y):                        # geodesic equations of the sphere in the (phi, theta) chart
    return [y[2], y[3], sin(y[0])*cos(y[0])*y[3]**2, -2*cos(y[0])/sin(y[0])*y[2]*y[3]]
def fly(y, h):                     # RK4 on the geodesic equations for 6 hours, step h hours
    for _ in range(round(6 / h)):
        k1 = geo(y); k2 = geo([a + h/2*b for a, b in zip(y, k1)])
        k3 = geo([a + h/2*b for a, b in zip(y, k2)]); k4 = geo([a + h*b for a, b in zip(y, k3)])
        y = [a + h/6*(b + 2*c + 2*d + f) for a, b, c, d, f in zip(y, k1, k2, k3, k4)]
    return y
y, y2 = fly([p, th, dp, dth], 0.001), fly([p, th, dp, dth], 0.0005)   # steps of 3.6 s and 1.8 s
Ja, Jb, Jc = kill(p, th, dp, dth), kill(*y), cart(*y)
unit = lambda v: " ".join("%.6f" % (c / sqrt(sum(d*d for d in v)) + 0.0) for c in v)
print("sphere J/|J| start, chart: %s" % unit(Ja))
print("sphere J/|J| 6 h, chart:   %s" % unit(Jb))
print("sphere J/|J| 6 h, r x v:   %s" % unit(Jc))
print("after 6 h: %.2f N, %.2f W, %.6f deg from the half-step landing; |J| = RE x speed = %.1f km^2/h"
      % (90 - degrees(y[0]), -degrees(y[1]), degrees(max(abs(y[i] - y2[i]) for i in (0, 1))), sqrt(sum(j*j for j in Jb))))

assert abs(rev_sim - rev_in) < 2e-3 and abs(rev2 - rev_sim) < 1e-5   # road 2 against road 1; half step
assert jdrift < 1e-6 and abs(Js[0] - J0) < 1e-9             # J = g(q', X) kept by the stepper
assert abs(E1 - E0 - (KE1 - KE0)) < 0.5                     # energy rises by the arms' work
assert abs(dL_all) < 1e-6 and abs(dL_body) > 1.0            # X is a symmetry; body-only is not
assert lie_rot == [[0.0, 0.0], [0.0, 0.0]] and lie_str == [[2.0, 0.0], [0.0, 2.0]]
assert max(Ds) - min(Ds) > 0.1                              # stretch momentum is not kept
assert abs(Jd - (J0 - 0.05*T_END)) < 1e-4                   # drag drains exactly torque x time
assert max(abs(a - b) for a, b in zip(Ja, Jb)) < 1e-6 * RE*SPD    # three Killing fields: kept
assert max(abs(a - b) for a, b in zip(Jb, Jc)) < 1e-6 * RE*SPD    # chart against r x v
assert abs(sqrt(sum(j*j for j in Ja)) - RE*SPD) < 1e-6 and max(abs(a - b) for a, b in zip(y, y2)) < 1e-9
print("ALL CHECKS PASS")
