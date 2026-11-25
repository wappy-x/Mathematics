# Caratheodory's conjecture -- the check behind the card.  Standard library only.
# Umbilics of an ellipsoid and an egg found two ways, their indices by walking a loop,
# Euler characteristics by Gauss-Bonnet, a torus with none, and the October 2026 seed.
from math import sin, cos, atan2, sqrt, pi, ceil; from fractions import Fraction as Fr

A, B, C = 3.0, 2.0, 1.0                      # ellipsoid semi-axes, cm (a pebble, illustrative)
EB, EC = 2.2, 3.0                            # egg: width scale and half-length, cm (illustrative)
def ell(p):                                  # F = x2/a2 + y2/b2 + z2/c2 - 1: gradient, Hessian, F
    return [2*p[0]/A**2, 2*p[1]/B**2, 2*p[2]/C**2], [2/A**2, 2/B**2, 2/C**2], \
        p[0]**2/A**2 + p[1]**2/B**2 + p[2]**2/C**2 - 1
def mkegg(k):                                # F = x2 + y2 - b2 (1 - z2/c2) (1 + k z)2
    def egg(p):
        z = p[2]; u, u1, u2 = 1 - z*z/EC**2, -2*z/EC**2, -2/EC**2
        w, w1, w2 = (1 + k*z)**2, 2*k*(1 + k*z), 2*k*k
        return [2*p[0], 2*p[1], -EB**2*(u1*w + u*w1)], [2.0, 2.0, -EB**2*(u2*w + 2*u1*w1 + u*w2)], \
            p[0]**2 + p[1]**2 - EB**2*u*w
    rho = lambda th: EB*sin(th)*(1 + k*EC*cos(th))            # profile radius at z = c cos(th)
    return egg, rho
dot = lambda u, v: u[0]*v[0] + u[1]*v[1] + u[2]*v[2]
crs = lambda u, v: [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
unit = lambda u: [x/sqrt(dot(u, u)) for x in u]
def frame(n, t):                             # tangent pair (t1, t2) with t1, t2, n right-handed
    t1 = unit([t[i] - dot(t, n)*n[i] for i in range(3)]); return t1, crs(n, t1)
def shape(surf, p, t=None):                  # 2x2 shape matrix in a tangent frame, outward normal
    g, h, _ = surf(p); n = unit(g); ng = sqrt(dot(g, g))
    t1, t2 = frame(n, t if t else ([0, 0, 1] if abs(n[2]) < 0.9 else [1, 0, 0]))
    q = lambda u, v: sum(u[i]*h[i]*v[i] for i in range(3))/ng
    return q(t1, t1), q(t1, t2), q(t2, t2)
gap = lambda m: sqrt((m[0] - m[2])**2 + 4*m[1]**2)      # kappa1 - kappa2
epoint = lambda th, ph: [A*sin(th)*cos(ph), B*sin(th)*sin(ph), C*cos(th)]
f6 = lambda x: f"{x:.6f}"
def turns(angles):                           # add up the turning of a line (angle mod 180 deg)
    return sum((b - a + pi/2) % pi - pi/2 for a, b in zip(angles, angles[1:]))/(2*pi)
def index(surf, p0, r=0.01, N=720):         # walk a loop round p0, follow a principal line
    g, _, _ = surf(p0); n0 = unit(g)
    e1, e2 = frame(n0, [0, 0, 1] if abs(n0[2]) < 0.9 else [1, 0, 0]); angs = []
    for k in range(N + 1):
        q = [p0[i] + r*(cos(2*pi*k/N)*e1[i] + sin(2*pi*k/N)*e2[i]) for i in range(3)]
        for _ in range(30):                  # slide along the normal onto the surface
            gq, _, F = surf(q); q = [q[i] - F/dot(gq, n0)*n0[i] for i in range(3)]
        m = shape(surf, q, e1); angs.append(0.5*atan2(2*m[1], m[0] - m[2]))
    return turns(angs)
def simpson(f, a, b, n):
    return (b - a)/n/3*sum((1 if k in (0, n) else 4 if k % 2 else 2)*f(a + k*(b - a)/n) for k in range(n + 1))

# Road 1: the closed form for the ellipsoid's umbilics
ux, uz = A*sqrt((A*A - B*B)/(A*A - C*C)), C*sqrt((B*B - C*C)/(A*A - C*C))
print(f"ellipsoid {A:g} x {B:g} x {C:g} cm: closed form umbilics at x = +-{f6(ux)}, y = 0, z = +-{f6(uz)}")
# Road 2: blind search -- grid minima of (kappa1 - kappa2)^2, then a pattern search
NT, NP = 60, 120
G = [[gap(shape(ell, epoint((i + .5)*pi/NT, j*2*pi/NP)))**2 for j in range(NP)] for i in range(NT)]
found = []
for i in range(1, NT - 1):
    for j in range(NP):
        if all(G[i][j] <= G[i+di][(j+dj) % NP] for di in (-1, 0, 1) for dj in (-1, 0, 1)):
            th, ph, st, best = (i + .5)*pi/NT, j*2*pi/NP, 0.05, G[i][j]
            while st > 1e-12:
                moved = False
                for dt, dp in ((st, 0), (-st, 0), (0, st), (0, -st)):
                    v = gap(shape(ell, epoint(th + dt, ph + dp)))**2
                    if v < best: best, th, ph, moved = v, th + dt, ph + dp, True
                if not moved: st /= 2
            if sqrt(best) < 1e-6 and all(sum((epoint(th, ph)[k] - q[k])**2 for k in range(3)) > 1e-6 for q in found):
                found.append(epoint(th, ph))
found.sort(key=lambda p: (-p[0], -p[2]))
print(f"blind search: {NT*NP} grid points, umbilics found {len(found)}")
for p in found:
    m = shape(ell, p)
    print(f"  umbilic ({f6(p[0])}, {f6(abs(p[1]))}, {f6(p[2])}), both curvatures {f6(m[0])} per cm, gap {gap(m):.9f}")
    assert abs(abs(p[0]) - ux) < 1e-6 and abs(abs(p[2]) - uz) < 1e-6 and abs(p[1]) < 1e-6
    assert abs(m[0] - A*C/B**3) < 1e-9 and abs(m[2] - A*C/B**3) < 1e-9          # a c / b^3
assert len(found) == 4
eidx = [index(ell, p) for p in found]
print("ellipsoid: principal line turns per loop, degrees", [f"{360*i:.2f}" for i in eidx])
def ell_KdA(th, NPH=64):                     # Gaussian curvature times area, round one circle
    s = 0.0
    for j in range(NPH):
        ph = 2*pi*j/NPH; m = shape(ell, epoint(th, ph))
        rt = [A*cos(th)*cos(ph), B*cos(th)*sin(ph), -C*sin(th)]
        rp = [-A*sin(th)*sin(ph), B*sin(th)*cos(ph), 0]
        s += (m[0]*m[2] - m[1]**2)*sqrt(dot(crs(rt, rp), crs(rt, rp)))*2*pi/NPH
    return s
chi_e = simpson(ell_KdA, 0, pi, 200)/(2*pi)
print(f"ellipsoid: Gauss-Bonnet total curvature / 2 pi = {f6(chi_e)}; index sum {Fr(round(2*sum(eidx)), 2)}")
assert all(abs(i - 0.5) < 1e-6 for i in eidx) and abs(chi_e - 2) < 1e-6

# The egg: a surface of revolution, umbilics at its two poles
K0 = 0.04; egg, rho = mkegg(K0)              # skew 0.04 per cm: blunt end up, pointed end down
rho1 = lambda th: EB*cos(th)*(1 + K0*EC*cos(th)) - EB*K0*EC*sin(th)**2
poles = [[0, 0, EC], [0, 0, -EC]]
for p in poles:
    m = shape(egg, p); R = EB**2*(1 + K0*p[2])**2/EC
    print(f"egg pole z = {p[2]:+.0f} cm: curvature {f6(m[0])} = 1/{f6(R)} per cm, gap {gap(m):.9f}")
    assert abs(m[0] - 1/R) < 1e-12 and gap(m) < 1e-12
profile = lambda surf, rh: [(lambda m: (m[0], m[2]))(shape(surf, [rh(t), 0, EC*cos(t)], [0, 0, 1]))
                           for t in (pi*(k + .5)/2000 for k in range(2000))]   # (meridian, round)
prof = profile(egg, rho)
print(f"egg: length {2*EC:g} cm, widest {f6(2*max(rho(pi*k/2000) for k in range(2001)))} cm; "
      f"smallest Gaussian curvature {f6(min(a*b for a, b in prof))} per cm2")
print(f"egg: round-the-circle curvature beats meridian curvature at {sum(b > a for a, b in prof)} of 2000 profile points")
assert all(b > a for a, b in prof)
gidx = [index(egg, p) for p in poles]
egg_KdA = lambda th: (lambda m: (m[0]*m[2] - m[1]**2)*rho(th)*sqrt(rho1(th)**2 + (EC*sin(th))**2)*2*pi)(
    shape(egg, [rho(th), 0, EC*cos(th)]))
chi_g = simpson(egg_KdA, 0, pi, 2000)/(2*pi)
print(f"egg: line turns per loop {[f'{360*i:.2f}' for i in gidx]}; Gauss-Bonnet / 2 pi = {f6(chi_g)}")
assert all(abs(i - 1) < 1e-6 for i in gidx) and abs(chi_g - 2) < 1e-6
# What breaks 1: a blunter egg (skew 0.06 per cm) grows whole circles of umbilics
egg6, rho6 = mkegg(0.06); p6 = profile(egg6, rho6)
flips = [k for k in range(1999) if (p6[k][1] > p6[k][0]) != (p6[k+1][1] > p6[k+1][0])]
print(f"blunter egg: the two curvatures swap order {len(flips)} time, near z = {EC*cos(pi*(flips[0] + 1)/2000):.3f} cm:"
      " a whole circle of umbilics there")
assert len(flips) == 1
# What breaks 2: a torus (the pasta ring, a = 1.5 mm tube, b = 4 mm ring) has no umbilic at all
ta, tb = 1.5, 4.0
tg = min(1/ta - cos(v)/(tb + ta*cos(v)) for v in (2*pi*k/3600 for k in range(3600)))
chi_t = simpson(lambda v: (1/ta)*cos(v)/(tb + ta*cos(v))*ta*(tb + ta*cos(v))*2*pi, 0, 2*pi, 200)/(2*pi)
print(f"torus: smallest kappa1 - kappa2 = {f6(tg)} per mm, umbilics 0; Gauss-Bonnet / 2 pi = {abs(chi_t):.6f}")
assert abs(tg - (1/ta - 1/(ta + tb))) < 1e-12 and abs(chi_t) < 1e-9
# Model umbilics on z = (x2 + y2)/2 + cubic: the line of the Hessian, walked round the origin
def germ(d, e, N=720):                       # d = f_xx - f_yy, e = f_xy
    return turns([0.5*atan2(2*e(cos(2*pi*k/N), sin(2*pi*k/N)), d(cos(2*pi*k/N), sin(2*pi*k/N))) for k in range(N + 1)])
lemon = germ(lambda x, y: 4*x, lambda x, y: 2*y)          # cubic x^3 + x y^2
star = germ(lambda x, y: 12*x, lambda x, y: -6*y)         # cubic x^3 - 3 x y^2
print(f"model germs: lemon x^3 + xy^2 index {lemon:+.6f}, star x^3 - 3xy^2 index {star:+.6f}")
assert abs(lemon - 0.5) < 1e-9 and abs(star + 0.5) < 1e-9
# Exact arithmetic: Poincare-Hopf sums and the fewest umbilics each index bound allows
print("sums:", Fr(1, 2)*4, "= 4 x 1/2 (ellipsoid);", 1*2, "= 2 x 1 (egg); 5 lemons + 1 star:", Fr(5, 2) - Fr(1, 2))
for name, m in (("Loewner, index <= 1", Fr(1)), ("index < 2, so <= 3/2", Fr(3, 2)), ("no bound but 2", Fr(2))):
    print(f"  {name}: fewest umbilics = ceil(2 / {m}) = {ceil(Fr(2)/m)}")
# The October 2026 seed F = a(x) - a(y) + sin x sin y, a(t) = sin^4 t + 3 sin^2 t
app = lambda t: 6 - 16*sin(t)**4                          # a''(t), worked out by hand
aa, h = (lambda t: sin(t)**4 + 3*sin(t)**2), 1e-4           # check a'' by a finite difference
assert max(abs(app(t/100) - (aa(t/100 + h) - 2*aa(t/100) + aa(t/100 - h))/h/h) for t in range(315)) < 1e-5
M = 400; mz = min(sqrt((app(pi*i/M) + app(pi*j/M))**2 + 4*(cos(pi*i/M)*cos(pi*j/M))**2)/4 for i in range(M) for j in range(M))
print(f"seed: smallest |F_zz| on a {M} x {M} grid of one period = {f6(mz)}; a'' runs from {app(pi/2):g} to {app(0):g}")
assert mz > 0.17
S = 50                                       # figure: pixels per cm, umbilics then egg poles
print("figure," + ";".join(f"{200 + S*p[0]:.1f} {190 - S*p[2]:.1f}" for p in found) + f";560 {190 - S*EC:.0f};560 {190 + S*EC:.0f}")
print("ALL CHECKS PASS")
