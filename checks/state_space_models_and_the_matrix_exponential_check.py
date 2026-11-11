# State space: cart and pendulum, x' = Ax + Bu, y = Cx + Du.  Standard library only.
# Every number on the card is printed here.  Four roads to the state at 0.5 s:
# closed form (cosh, sinh), series e^(At) plus Simpson's rule, exact 100 Hz steps, RK4.
from math import cosh, sinh, sin, cos, exp, pi
g, l = 9.81, 0.613125                     # gravity m/s^2, rod length m
a, c = g / l, 1 / l                       # 16 per s^2, and 1.631 rad per m
w = a ** 0.5                              # 4 per s: the falling rod's growth rate
A = [[0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1], [0, 0, a, 0]]   # state (p, v, theta, omega)
B = [0, 1, 0, -c]                         # input u: cart acceleration, m/s^2
C, D = [0, 0, 1, 0], 0                    # the encoder reads the tilt only
x0, T = [0, 0, 0.05, 0], 0.5              # start tilted 0.05 rad; read at 0.5 s
def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(4)) for j in range(4)] for i in range(4)]
def mv(X, v): return [sum(X[i][k] * v[k] for k in range(4)) for i in range(4)]
def add(*vs): return [sum(z) for z in zip(*vs)]
def scale(s, v): return [s * z for z in v]
def series(t, shift=0):                   # shift 0: e^(At); shift 1: integral of e^(As) ds, 0..t
    S = [[(t if shift else 1.0) * (i == j) for j in range(4)] for i in range(4)]
    term = [r[:] for r in S]
    for k in range(1, 60):
        term = [[z * t / (k + shift) for z in r] for r in mm(term, A)]
        S = [[S[i][j] + term[i][j] for j in range(4)] for i in range(4)]
    return S
def closed(t, x, u, sign=1):              # road 1: e^(At) by blocks, convolution done by hand
    ch, sh = cosh(w * t), sinh(w * t)
    free = [x[0] + t * x[1], x[1], ch * x[2] + sh / w * x[3], w * sh * x[2] + ch * x[3]]
    forced = [u * t * t / 2, u * t, -sign * c * u * (ch - 1) / a, -sign * c * u * sh / w]
    return free, forced
def simpson(t, x, u, n=200):              # road 2: the formula itself, integral by Simpson's rule
    h, acc = t / n, [0.0] * 4
    for i in range(n + 1):
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        acc = add(acc, scale(w * h / 3 * u, mv(series(t - i * h), B)))
    return add(mv(series(t), x), acc)
def stepped(t, x, u, dt=0.01):            # road 3: exact 100 Hz steps, x_{k+1} = Phi x_k + Gam u
    Phi, Gam = series(dt), mv(series(dt, 1), B)
    for _ in range(round(t / dt)): x = add(mv(Phi, x), scale(u, Gam))
    return x
def rk4(f, t, x, dt=0.001):               # road 4: a plain numerical integrator
    for _ in range(round(t / dt)):
        k1 = f(x); k2 = f(add(x, scale(dt / 2, k1))); k3 = f(add(x, scale(dt / 2, k2))); k4 = f(add(x, scale(dt, k3)))
        x = add(x, scale(dt / 6, add(k1, scale(2, k2), scale(2, k3), k4)))
    return x
lin = lambda u: (lambda x: add(mv(A, x), scale(u, B)))
nonlin = lambda u: (lambda x: [x[1], u, x[3], (g * sin(x[2]) - u * cos(x[2])) / l])
def solve(M, b):                          # Gaussian elimination, for G(s) = C (sI - A)^-1 B + D
    M = [r[:] + [b[i]] for i, r in enumerate(M)]
    for i in range(4):
        p = max(range(i, 4), key=lambda r: abs(M[r][i])); M[i], M[p] = M[p], M[i]
        for r in range(4):
            if r != i: M[r] = [M[r][j] - M[r][i] / M[i][i] * M[i][j] for j in range(5)]
    return [M[i][4] / M[i][i] for i in range(4)]
def push_for(t, th0, rod=l):              # constant push that brings the tilt to 0 at time t
    ch = cosh(t * (g / rod) ** 0.5)
    return th0 * g * ch / (ch - 1)
def row(name, v): print(f"{name:<38}" + "".join(f"{z if abs(z) > 5e-7 else 0.0:>11.6f}" for z in v))
E = series(T)
row("g/l, 1/l, rate; degrees 0.05, 0.5 rad", [a, c, w, 0.05 * 180 / pi, 0.5 * 180 / pi])
row("e^(At) at 0.5 s, tilt rows", E[2][2:] + E[3][2:])
row("  closed form cosh, sinh/4, 4 sinh", [cosh(2), sinh(2) / 4, 4 * sinh(2)])
free, per = closed(T, x0, 1.0)
row("free part (p, v, tilt, rate)", free)
row("forced part per 1 m/s^2", per)
u = -free[2] / per[2]
row("push u that zeroes tilt at 0.5 s", [u, push_for(T, 0.05)])
r1 = add(*closed(T, x0, u)); r2 = simpson(T, x0, u); r3 = stepped(T, x0, u); r4 = rk4(lin(u), T, x0)
for name, r in [("1 closed form", r1), ("2 series + Simpson", r2), ("3 exact 100 Hz steps", r3), ("4 RK4, 1 ms", r4)]:
    row(name, r)
for r in (r2, r3, r4): assert max(abs(p - q) for p, q in zip(r, r1)) < 1e-9
assert abs(u - push_for(T, 0.05)) < 1e-12
y = sum(ci * xi for ci, xi in zip(C, r1)) + D * u
Phi, Gam = series(0.01), mv(series(0.01, 1), B)
row("encoder y at 0.5 s; hold push g*tilt", [y, a * 0.05 / c])
row("one 0.01 s step: Phi tilt row, Gamma", Phi[2][2:] + [Gam[1], Gam[2]])
s = 5.0
Gs = sum(ci * xi for ci, xi in zip(C, solve([[s * (i == j) - A[i][j] for j in range(4)] for i in range(4)], B))) + D
row("G(5): by (sI-A)^-1, by -c/(s^2-16)", [Gs, -c / (s * s - 16)])
assert abs(Gs + c / (s * s - 16)) < 1e-12
nl = rk4(nonlin(u), T, x0)
row("nonlinear rod, same push, 0.5 s", nl)
big = rk4(nonlin(push_for(T, 0.5)), T, [0, 0, 0.5, 0])
row("start 0.5 rad: linear push, rod tilt", [push_for(T, 0.5), big[2], big[2] * 180 / pi])
assert abs(nl[2]) < 0.001 and big[2] > 0.1           # second road for both: the same runs at half the step
assert abs(rk4(nonlin(u), T, x0, 0.0005)[2] - nl[2]) < 1e-6 and abs(rk4(nonlin(push_for(T, 0.5)), T, [0, 0, 0.5, 0], 0.0005)[2] - big[2]) < 1e-6
# ---- what breaks ----
f2, p2 = closed(T, x0, u, sign=-1)
lump = mv(E, scale(u * T, B))             # all 0.5 s of push delivered as one kick at t = 0
ew = [[exp(A[i][j] * T) for j in range(4)] for i in range(4)]
row("wrong: no convolution term", [free[2]])
row("wrong: whole push as a kick at 0", [free[2] + lump[2]])
row("wrong: e^(a_ij t) entry by entry", [mv(ew, x0)[2]])
row("wrong: B sign flipped", [f2[2] + p2[2]])
assert abs(free[2] + lump[2] - r2[2]) > 0.1 and abs(f2[2] + p2[2] - r4[2]) > 0.1
# ---- how it moves, and the chart ----
for tt in [0.1, 0.2, 0.3, 0.4, 0.5]:
    fr, fo = closed(tt, x0, u)
    row(f"t={tt:.1f}: free, forced, total tilt", [fr[2], fo[2], fr[2] + fo[2]])
grid = [k / 10 for k in range(11)]
for name, uu in [("chart, motor off", 0.0), ("chart, hold push", a * 0.05 / c), ("chart, push u", u)]:
    print(name.ljust(17) + "".join(f"{add(*closed(tt, x0, uu))[2]:7.2f}" for tt in grid))
# ---- try changing ----
row("try: tilt 0.1; by 0.25 s; by 1 s", [push_for(T, 0.1), push_for(0.25, 0.05), push_for(1.0, 0.05)])
row("try: rod 1.2 m", [push_for(T, 0.05, 1.2)])
print("ALL CHECKS PASS")
