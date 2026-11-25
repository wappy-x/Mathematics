# Moment maps and symplectic reduction -- the check behind the card.  Standard library only.
# Yaw turns (the circle group SO(2)) act on the plane's phase space z = (x, y, px, py).
# Road 1: the moment map from its definition, iota_X omega = dJ, by finite differences.
# Road 2: the planar Kepler problem stepped in all four coordinates (RK4): J and H stay put.
# Road 3: the reduced system at J = 6, one radial degree of freedom, against the full run
#         and against the closed-form turning points and period.
# Road 4: SO(3): the moment map r x p is equivariant; a tumbling drone's body momentum
#         stays on a sphere, its coadjoint orbit.
from math import pi, sin, cos, sqrt, asin
M, K, WIND = 1.0, 12.0, 0.05       # mass kg; pull k in N m^2 (force k/r^2); wind push N
Z0 = [2.0, 0.0, 0.0, 3.0]          # x m, y m, px kg m/s, py kg m/s
ZT = [1.3, -0.7, 0.4, 2.1]         # a second test point, nothing special about it

def dot(a, b):                     # plain left-to-right sum, so Rust matches it bit for bit
    t = 0.0
    for u, v in zip(a, b): t += u*v
    return t
def J(z): return z[0]*z[3] - z[1]*z[2]
def H(z, f=0.0): return (z[2]**2 + z[3]**2)/(2*M) - K/sqrt(z[0]**2 + z[1]**2) - f*z[0]
def turn(z, s, momenta=True):      # yaw by angle s; the momenta turn too unless told not to
    c, n = cos(s), sin(s)
    px, py = (c*z[2] - n*z[3], n*z[2] + c*z[3]) if momenta else (z[2], z[3])
    return [c*z[0] - n*z[1], n*z[0] + c*z[1], px, py]
def grad(f, z, h=1e-5):            # central differences
    out = []
    for i in range(4):
        a, b = list(z), list(z); a[i] += h; b[i] -= h
        out.append((f(a) - f(b))/(2*h))
    return out
def gen(z, momenta=True, h=1e-6):  # the generating field X: velocity of the turn at s = 0
    a, b = turn(z, h, momenta), turn(z, -h, momenta)
    return [(a[i] - b[i])/(2*h) for i in range(4)]
def iota(X): return [-X[2], -X[3], X[0], X[1]]   # iota_X omega in (dx, dy, dpx, dpy) parts
def curl(alpha, z, h=1e-4):        # largest entry of d(alpha) for a one-form field alpha
    g = [[(alpha([z[k] + h*(k == i) for k in range(4)])[j] - alpha([z[k] - h*(k == i) for k in range(4)])[j])/(2*h)
          for j in range(4)] for i in range(4)]
    return max(abs(g[i][j] - g[j][i]) for i in range(4) for j in range(4))
def rk4(F, z, dt):
    k1 = F(z); k2 = F([a + dt/2*b for a, b in zip(z, k1)])
    k3 = F([a + dt/2*b for a, b in zip(z, k2)]); k4 = F([a + dt*b for a, b in zip(z, k3)])
    return [a + dt/6*(b + 2*c + 2*d + e) for a, b, c, d, e in zip(z, k1, k2, k3, k4)]
def full(f):                       # Hamilton's equations in x, y, px, py
    def F(z):
        r = sqrt(z[0]**2 + z[1]**2); r3 = r*r*r
        return [z[2]/M, z[3]/M, -K*z[0]/r3 + f, -K*z[1]/r3]
    return F
def reduced(c):                    # (r, pr, theta): one radial freedom plus the angle rebuilt
    return lambda s: [s[1]/M, c*c/(M*s[0]**3) - K/s[0]**2, c/(M*s[0]**2)]
def veff(r, c): return c*c/(2*M*r*r) - K/r

# Road 1: the moment map from its definition
c = J(Z0)
gap = max(abs(a - b) for z in (Z0, ZT) for a, b in zip(iota(gen(z)), grad(J, z)))
d_full, d_pos = curl(lambda z: iota(gen(z)), ZT), curl(lambda z: iota(gen(z, False)), ZT)
XH = lambda z, f: (lambda g: [g[2], g[3], -g[0], -g[1]])(grad(lambda w: H(w, f), z))
pb0 = dot(grad(J, ZT), XH(ZT, 0.0))
pbw = dot(grad(J, ZT), XH(ZT, WIND))
print(f"moment map J at the start: {c:.6f} kg m^2/s")
print(f"iota_X omega minus dJ, largest gap at two points: {gap:.1e}")
print(f"d(iota_X omega): turn x and p {d_full:.6f}; turn x only {d_pos:.6f}")
print(f"dJ/dt = {{J, H}} at test point: no wind {abs(pb0):.1e}, wind 0.05 N {pbw:.6f}")
assert gap < 1e-6
assert d_full < 1e-5 and abs(d_pos - 1.0) < 1e-5 and abs(pbw - 0.035) < 1e-6

# closed forms for the reduced orbit at J = 6
E = H(Z0); disc = sqrt(K*K + 2*E*c*c/M)
r_lo, r_hi = (-K + disc)/(2*E), (-K - disc)/(2*E)
a = -K/(2*E); P = 2*pi*sqrt(M*a**3/K); rc = c*c/(M*K)
print(f"energy E {E:.6f} J; Veff(2) {veff(2.0, c):.6f} J; well bottom r {rc:.6f} m, Veff {veff(rc, c):.6f} J")
print(f"kinetic {(Z0[2]**2 + Z0[3]**2)/(2*M):.6f} J, pull {K/Z0[0]:.6f} J; turning points {r_lo:.6f} m and {r_hi:.6f} m")
print(f"semi-major axis {a:.6f} m; period {P:.6f} s")
print("chart Veff r=1.5..8:", " ".join(f"{veff(1.5 + 0.5*i, c):.2f}" for i in range(14)))

# Road 2 (full, four coordinates) against Road 3 (reduced, one radial freedom), at two steps
for N in (2000, 4000):
    dt, z, s = P/N, list(Z0), [Z0[0], Z0[2], 0.0]   # start on the x axis: r = x, pr = px
    jd = hd = gr = 0.0; rq = []
    for i in range(1, N + 1):
        z, s = rk4(full(0.0), z, dt), rk4(reduced(c), s, dt)
        jd, hd = max(jd, abs(J(z) - c)), max(hd, abs(H(z) - E))
        gr = max(gr, abs(sqrt(z[0]**2 + z[1]**2) - s[0]))
        if i % (N//4) == 0: rq.append(s[0])
        if i == N//2: xh, th = z[0], s[2]
    print(f"N={N}: J drift {jd:.1e}, H drift {hd:.1e}, full x at P/2 {xh:.6f}, reduced r gap {gr:.1e}")
print(f"reduced r at P/4, P/2, 3P/4, P: {' '.join(f'{v:.6f}' for v in rq)}")
print(f"angle rebuilt from theta' = J/(m r^2): {th:.6f} rad at P/2, {s[2]:.6f} rad at P")
far = r_lo + r_hi - Z0[0]          # the turning point opposite the start
assert abs(xh + far) < 1e-6 and jd < 1e-9 and gr < 1e-6
assert abs(rq[1] - far) < 1e-6 and abs(rq[3] - Z0[0]) < 1e-6 and abs(s[2] - 2*pi) < 1e-6

# What breaks: a wind push breaks the symmetry; dropping J^2/(2 m r^2) lets the body fall in
z, tq = list(Z0), 0.0              # tq: the wind's torque -y F summed over time, trapezoid rule
for i in range(4000):
    y_ = z[1]; z = rk4(full(WIND), z, P/4000); tq -= WIND*(y_ + z[1])/2*P/4000
s, t = [2.0, 0.0, 0.0], 0.0
while s[0] > 0.05: s, t = rk4(reduced(0.0), s, 1e-5), t + 1e-5
u = asin(sqrt(0.05/2.0)); tf = sqrt(M*2.0**3/(2*K))*(pi/2 - u + sin(u)*cos(u))
print(f"wind 0.05 N: J after one period {J(z):.6f} kg m^2/s; 6 plus the torque's time integral {c + tq:.6f}")
print(f"no J^2/(2 m r^2) term: reaches r = 0.05 m at {t:.4f} s (closed form {tf:.4f} s), r = 0 at {pi/2*sqrt(M*8/(2*K)):.4f} s")
print("dimensions: phase space 4, level set J = 6 is 3, reduced 3 - 1 = 2; SO(3) on 6: 6 - 3 - 1 = 2")
assert abs(J(z) - c) > 0.01 and abs(J(z) - (c + tq)) < 1e-5 and abs(t - tf) < 1e-4

# Road 4: SO(3). J = r x p is equivariant: J(R r, R p) = R J(r, p)
def cross(a, b): return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
def rot(v, n, t):                  # Rodrigues: turn v by angle t about unit axis n
    w = cross(n, v); d = dot(n, v)
    return [v[i]*cos(t) + w[i]*sin(t) + n[i]*d*(1 - cos(t)) for i in range(3)]
def qrot(v, n, t):                 # the same turn by the unit quaternion (cos t/2, n sin t/2)
    q0, q = cos(t/2), [x*sin(t/2) for x in n]; w = cross(q, v); u = cross(q, w)
    return [v[i] + 2*q0*w[i] + 2*u[i] for i in range(3)]
rv, pv, ax = [2.0, 0.0, 0.5], [0.0, 3.0, 0.4], [1/3, 2/3, 2/3]
J3 = cross(rv, pv); RJ = rot(J3, ax, 0.7); JR = cross(rot(rv, ax, 0.7), rot(pv, ax, 0.7))
QJ = qrot(J3, ax, 0.7)
f3 = lambda v: " ".join(f"{x:.6f}" for x in v)
print(f"J(r, p) = {f3(J3)}; R J = {f3(RJ)}; J(R r, R p) = {f3(JR)}")
print(f"R J by a unit quaternion instead: {f3(QJ)}")
print(f"|J| before and after the turn: {sqrt(dot(J3, J3)):.6f} {sqrt(dot(JR, JR)):.6f}")
assert max(abs(a - b) for a, b in zip(RJ, JR)) < 1e-12 and max(abs(a - b) for a, b in zip(RJ, QJ)) < 1e-12

# A drone tossed spinning about its middle axis: Euler's equations Pi' = Pi x Omega
I = [0.010, 0.012, 0.020]          # principal moments of inertia, kg m^2
ke = lambda P_: dot([x/(2*w) for x, w in zip(P_, I)], P_)   # kinetic energy, J
body = lambda P_: cross(P_, [P_[i]/I[i] for i in range(3)])
Pi = [I[0]*0.05, I[1]*3.0, I[2]*0.05]; L0 = sqrt(dot(Pi, Pi))
E0 = ke(Pi); y0 = ymin = Pi[1]; ld = ed = 0.0
for i in range(20000):
    Pi = rk4(body, Pi, 1e-3); ymin = min(ymin, Pi[1])
    ld = max(ld, abs(sqrt(dot(Pi, Pi)) - L0))
    ed = max(ed, abs(ke(Pi) - E0))
print(f"tumbling drone: |Pi| {1000*L0:.6f} g m^2/s, drift {1000*ld:.1e}; energy {1000*E0:.6f} mJ, drift {1000*ed:.1e}")
print(f"Pi_y starts {1000*y0:.6f}, lowest {1000*ymin:.6f} g m^2/s; a flip sends it near -|Pi|")
assert ld < 1e-9 and ed < 1e-9 and ymin < -0.9*L0
print("ALL CHECKS PASS")
