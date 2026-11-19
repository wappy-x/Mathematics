# Frenet-Serret frame -- the check behind the card.  Standard library only.
# A camera rig rides a climbing left turn r(t) = L(t, t^2/2, t^3/3), L = 15 m,
# in metres east, north, up.  Its axes T, N, B come by three roads that share
# no step: exact t-derivatives turned into s-derivatives by the chain rule;
# finite differences after relabelling the track by arc length; and the
# Frenet-Serret equations stepped by RK4 from the start of the turn.
from math import sqrt, acos, degrees

L, V = 15.0, 15.0                      # track scale (m); train speed (m/s)

def add(a, b, k=1.0): return tuple(a[i] + k * b[i] for i in range(3))
def mul(a, k): return tuple(k * x for x in a)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def size(a): return sqrt(dot(a, a))
def unit(a): return mul(a, 1 / size(a))
def f(x, d=4): return f"{(0.0 if abs(x) < 0.5 * 10 ** -d else x):.{d}f}"
def vec(a, d=4): return "(" + ", ".join(f(x, d) for x in a) + ")"
def ang(a, b): return degrees(acos(max(-1.0, min(1.0, dot(unit(a), unit(b))))))
def dunit(w, wp):                      # d/dt of w/|w|, for w(t) with derivative wp
    return mul(add(mul(wp, dot(w, w)), w, -dot(w, wp)), size(w) ** -3)

def r(t): return (L * t, L * t * t / 2, L * t ** 3 / 3)
def speed(t): return L * sqrt(1 + t * t + t ** 4)      # ds/dt: metres of track per unit t

def exact(t):                          # road 1: r' = L(1, t, t^2), r'' = L(0, 1, 2t)
    T, B = unit((1, t, t * t)), unit((t * t, -2 * t, 1))   # B lies along r' x r''
    q = t ** 4 + 4 * t * t + 1
    return T, cross(B, T), B, sqrt(q) / (L * (1 + t * t + t ** 4) ** 1.5), 2 / (L * q)

def arc(t, n=2000):                    # s(t), metres from the start, by Simpson's rule
    h, total = t / n, speed(0) + speed(t)
    for i in range(1, n):
        total += (4 if i % 2 else 2) * speed(i * h)
    return h / 3 * total

def p(s):                              # the track relabelled by arc length: Newton on s(t) = s
    t = s / L
    for _ in range(40):
        step = (arc(t) - s) / speed(t)
        t -= step
        if abs(step) < 1e-14: break
    return r(t)

def fd_frame(s, h):                    # road 2: differences in s alone
    a, b, c = p(s - h), p(s), p(s + h)
    T, Tp = unit(mul(add(c, a, -1), 0.5 / h)), mul(add(add(c, b, -2), a), h ** -2)
    N = unit(Tp)
    return T, N, cross(T, N), size(Tp)

def fd_all(s, h):
    T, N, B, k = fd_frame(s, h)
    m, pl = fd_frame(s - h, h), fd_frame(s + h, h)
    Bp, Np = mul(add(pl[2], m[2], -1), 0.5 / h), mul(add(pl[1], m[1], -1), 0.5 / h)
    return T, N, B, k, -dot(Bp, N), Np

def ride(t1, n=200, keep=1.0):         # road 3: RK4 on the Frenet-Serret equations, in t
    def rhs(t, y):
        _, T, N, B = y
        _, _, _, k, tau = exact(t)
        v = speed(t)                   # d/dt = (ds/dt) d/ds
        return (mul(T, v), mul(N, v * k), mul(add(mul(T, -k * keep), B, tau), v), mul(N, -tau * v))
    def nudge(y, d, c): return tuple(add(y[j], d[j], c) for j in range(4))
    y, h = ((0.0, 0.0, 0.0),) + exact(0)[:3], t1 / n
    for i in range(n):
        t = i * h
        k1 = rhs(t, y); k2 = rhs(t + h / 2, nudge(y, k1, h / 2))
        k3 = rhs(t + h / 2, nudge(y, k2, h / 2)); k4 = rhs(t + h, nudge(y, k3, h))
        y = nudge(nudge(nudge(nudge(y, k1, h / 6), k2, h / 3), k3, h / 3), k4, h / 6)
    return y

t1 = 1.0
T, N, B, k, tau = exact(t1)
s1, v1 = arc(t1), speed(t1)
dTdt, dBdt = dunit((1, t1, t1 * t1), (0, 1, 2 * t1)), dunit((t1 * t1, -2 * t1, 1), (2 * t1, -2, 0))
Tp, Bp = mul(dTdt, 1 / v1), mul(dBdt, 1 / v1)
Np = add(mul(T, -k), B, tau)
print(f"hand point t = 1: position {vec(r(t1))} m, ds/dt = {f(v1)} m, arc length from the start s = {f(s1)} m")
print(f"T = {vec(T)}, climbing at {f(ang(T, (T[0], T[1], 0)), 2)} degrees")
print(f"dT/dt = {vec(dTdt)}; T' = dT/ds = {vec(Tp)} per m")
print(f"kappa = |T'| = {f(size(Tp))} /m, radius 1/kappa = {f(1 / size(Tp), 2)} m; N = {vec(N)}")
print(f"B = T x N = {vec(B)}")
print(f"dB/dt = {vec(dBdt)}; B' = {vec(Bp)} per m; tau = -B'.N = {f(-dot(Bp, N))} /m")
print(f"closed forms: kappa = sqrt(2)/45 = {f(k, 6)} /m, tau = 1/45 = {f(tau, 6)} /m")
print(f"N' = -kappa T + tau B = {vec(Np, 5)} per m")
print(f"frame checks: T.N {f(dot(T, N))}, T.B {f(dot(T, B))}, N.B {f(dot(N, B))}, lengths {f(size(T))} {f(size(N))} {f(size(B))}")
errs = []
for h in (0.4, 0.2):
    T2, N2, B2, k2, tau2, Np2 = fd_all(s1, h)
    errs.append((abs(k2 - k), abs(tau2 - tau), size(add(Np2, Np, -1))))
    print(f"road 2, arc-length differences, step {h} m: kappa {f(k2, 6)}, tau {f(tau2, 6)}, N' {vec(Np2, 5)}")
    print(f"  errors: kappa {errs[-1][0]:.2e}, tau {errs[-1][1]:.2e}, N' {errs[-1][2]:.2e}; T off by {ang(T2, T):.1e} degrees")
print(f"halving the step cuts the errors by {f(errs[0][0] / errs[1][0], 2)}, {f(errs[0][1] / errs[1][1], 2)} and {f(errs[0][2] / errs[1][2], 2)}")
P3, T3, N3, B3 = ride(t1)
gap = max(size(add(T3, T, -1)), size(add(N3, N, -1)), size(add(B3, B, -1)))
print(f"road 3, RK4 from the start frame, 200 steps: T {vec(T3)}, N {vec(N3)}, B {vec(B3)}")
print(f"  frame misses road 1 by {gap:.1e}; position {vec(P3)} m misses r(1) by {size(add(P3, r(t1), -1)):.1e} m")
print(f"rig at {f(V, 1)} m/s: roll about T {f(tau * V)} rad/s = {f(degrees(tau * V), 2)} deg/s; "
      f"about N 0; about B {f(k * V)} rad/s = {f(degrees(k * V), 2)} deg/s")
spin = V * sqrt(k * k + tau * tau)
print(f"rig total spin V sqrt(kappa^2 + tau^2) = {f(spin)} rad/s = {f(degrees(spin), 2)} deg/s"
      f"; push toward N, kappa V^2 = {f(k * V * V)} m/s^2")
for tc in (0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5):
    e = exact(tc)
    print(f"chart, t {f(tc, 2)}: s {f(arc(tc), 2)} m, kappa {f(e[3])} /m, tau {f(e[4])} /m")
bad = unit((0, 1, 2 * t1))
print(f"mistake 1, N along r'': {vec(bad)}; dot with T {f(dot(bad, T))}, {f(ang(bad, N), 2)} degrees off N")
print(f"mistake 2, |dT/dt| as kappa: {f(size(dTdt))}, radius {f(1 / size(dTdt), 2)} m instead of {f(1 / k, 2)} m")
bflip = cross(N, T)
print(f"mistake 3, B = N x T: {vec(bflip)}; tau = -B'.N comes out {f(dot(Bp, N))} /m")
P4, T4, N4, B4 = ride(t1, keep=0.0)
print(f"mistake 4, N' without -kappa T: at t = 1, T.N = {f(dot(T4, N4))}, T off by {f(ang(T4, T), 2)} degrees")
c = 1 / 450                            # S-bend y = c x^3: kappa is 0 at x = 0
def sN(x): return unit(dunit((1, 3 * c * x * x, 0), (0, 6 * c * x, 0)))   # N = unit dT/dx
Nm, Npl = sN(-1.0), sN(1.0)
print(f"S-bend y = x^3/450: N at x = -1 m {vec(Nm)}, at x = +1 m {vec(Npl)}, {f(ang(Nm, Npl), 2)} degrees apart")
o = lambda q: (70 + 8 * (q[0] + q[1]) / sqrt(2), 170 - 8 * (-q[0] + q[1] + 2 * q[2]) / sqrt(6))
print("figure, track:", " ".join(f"{o(r(i / 10))[0]:.1f},{o(r(i / 10))[1]:.1f}" for i in range(16)))
for tf in (0.0, 1.0):
    e, base = exact(tf), o(r(tf))
    tips = [o(add(r(tf), e[j], 6.0)) for j in range(3)]
    print(f"figure, frame at t {f(tf, 1)}: base {base[0]:.1f},{base[1]:.1f}; T N B tips "
          + " ".join(f"{x:.1f},{y:.1f}" for x, y in tips))
assert abs(k - sqrt(2) / 45) < 1e-12 and abs(tau - 1 / 45) < 1e-12         # hand values
assert abs(size(Tp) - k) < 1e-12 and abs(-dot(Bp, N) - tau) < 1e-12        # chain rule = closed form
assert errs[1][0] < 1e-5 and errs[1][1] < 1e-5 and errs[1][2] < 1e-5       # road 2 agrees
assert all(3.5 < errs[0][j] / errs[1][j] < 4.5 for j in range(3))           # error falls as h^2
assert gap < 1e-8 and size(add(P3, r(t1), -1)) < 1e-6                     # road 3 agrees
assert abs(dot(T4, N4)) > 0.01 and ang(Nm, Npl) > 179.9                    # the failures show
print("ALL CHECKS PASS")
