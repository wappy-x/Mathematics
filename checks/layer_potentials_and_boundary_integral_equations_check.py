# Layer potentials -- the check behind the card.  Standard library only.
# A 5 cm steel bar lies across a stream of water at 1 m/s.  Lengths are scaled
# by its radius a = 2.5 cm, so its rim is the unit circle.  Roads: (1) the
# closed form from the constant circle kernel, (2) a Nystrom solve of the
# boundary equation, (3) the potential summed by quadrature against a known
# harmonic function, (4) the jumps read off near the rim from both sides.
import math
TAU, A_M, U = 2 * math.pi, 0.025, 1.0      # 2 pi; bar radius in m; stream in m/s

def fx(v): return 0.0 if abs(v) < 5e-7 else v       # no "-0.000000"
def show(label, *vals): print(label + "," + ",".join(" %.6f" % fx(v) for v in vals))

def circle(t):                    # point, outward unit normal, speed |gamma'|, curvature
    return (math.cos(t), math.sin(t)), (math.cos(t), math.sin(t)), 1.0, 1.0
def oval(t, b=0.6):               # flattened pipe: semi-axes 2.5 cm and 1.5 cm
    J = math.sqrt(math.sin(t) ** 2 + (b * math.cos(t)) ** 2)
    return (math.cos(t), b * math.sin(t)), (b * math.cos(t) / J, math.sin(t) / J), J, b / J ** 3

def dk(x, y, ny):                 # double-layer kernel: d Phi(x - y) / d n_y
    dx, dy = x[0] - y[0], x[1] - y[1]
    return (dx * ny[0] + dy * ny[1]) / (dx * dx + dy * dy) / TAU
def sk(x, y): return -math.log(math.hypot(x[0] - y[0], x[1] - y[1])) / TAU

def nodes(curve, N): return [(TAU * j / N,) + curve(TAU * j / N) for j in range(N)]
def dlayer(curve, N, mu, x): return sum(dk(x, y, n) * mu(t) * J * TAU / N for t, y, n, J, k in nodes(curve, N))
def slayer(curve, N, sig, x): return sum(sk(x, y) * sig(t) * J * TAU / N for t, y, n, J, k in nodes(curve, N))

def nystrom(curve, N, half, adjoint=False):   # matrix of half*I + K  (or + K')
    nd = nodes(curve, N); A = [[0.0] * N for _ in range(N)]
    for i, (ti, xi, ni, Ji, ki) in enumerate(nd):
        for j, (tj, yj, nj, Jj, kj) in enumerate(nd):
            kern = -kj / (2 * TAU) if i == j else (dk(yj, xi, ni) if adjoint else dk(xi, yj, nj))
            A[i][j] = kern * Jj * TAU / N + (half if i == j else 0.0)
    return A, nd
def solve(A, b):                  # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            for k in range(c, n + 1): M[r][k] -= f * M[c][k]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - sum(M[r][k] * x[k] for k in range(r + 1, n))) / M[r][r]
    return x
def at(r, th): return (r * math.cos(th), r * math.sin(th))

print("kernel on the circle: double layer, adjoint, -1/(4 pi)")
x0, y0 = circle(0.3)[0], circle(2.1)
show("kernel,theta=0.3,phi=2.1", dk(x0, y0[0], y0[1]), dk(y0[0], x0, circle(0.3)[1]), -1 / (2 * TAU))
assert abs(dk(x0, y0[0], y0[1]) + 1 / (2 * TAU)) < 1e-12

print("interior Dirichlet: rim temperature cos(theta) K")
A, nd = nystrom(circle, 16, -0.5)
mu = solve(A, [math.cos(t) for t, *_ in nd])
show("Nystrom N=16: mu at theta=0, 90, 180 deg", mu[0], mu[4], mu[8])
assert max(abs(m + 2 * math.cos(t)) for m, (t, *_) in zip(mu, nd)) < 1e-12   # closed form -2 cos
MU = lambda t: -2 * math.cos(t)
for r, deg in [(0.5, 0), (0.9, 60), (0.3, 135)]:
    u = dlayer(circle, 4000, MU, at(r, math.radians(deg)))
    show("u at r=%.1f, %d deg: layer, r cos(theta)" % (r, deg), u, r * math.cos(math.radians(deg)))
    assert abs(u - r * math.cos(math.radians(deg))) < 1e-9

print("jump of the double layer along theta=0 (N=40000)")
for r in [0.9, 0.99, 0.999, 1.001, 1.01, 1.1]:
    show("D mu at r=%.3f" % r, dlayer(circle, 40000, MU, at(r, 0.0)))
onrim = sum(-1 / (2 * TAU) * MU(t) * TAU / 4000 for t in [TAU * j / 4000 for j in range(4000)])
show("on the rim: K mu, then K mu - mu/2 and K mu + mu/2", onrim, onrim + 1, onrim - 1)
assert abs(dlayer(circle, 40000, MU, at(1.001, 0)) - dlayer(circle, 40000, MU, at(0.999, 0)) + 2) < 3e-3

print("chart: D mu along theta=0, distance in cm")
rs = [0.1 + 0.2 * i for i in range(15)]           # equal steps of 0.5 cm, none on the rim
print("chart,cm," + ",".join(" %.2f" % (2.5 * r) for r in rs))
print("chart,K," + ",".join(" %.2f" % fx(dlayer(circle, 4000, MU, at(r, 0))) for r in rs))

print("single layer, sigma = 2 cos(theta): inside r cos, outside cos/r")
SG = lambda t: 2 * math.cos(t)
show("S sigma at r=0.5 and r=2, theta=0", slayer(circle, 4000, SG, at(0.5, 0)), slayer(circle, 4000, SG, at(2, 0)))
assert abs(slayer(circle, 4000, SG, at(2, 0)) - 0.5) < 1e-9
h = 1e-4
din = (slayer(circle, 40000, SG, at(0.999 + h, 0)) - slayer(circle, 40000, SG, at(0.999 - h, 0))) / (2 * h)
dout = (slayer(circle, 40000, SG, at(1.001 + h, 0)) - slayer(circle, 40000, SG, at(1.001 - h, 0))) / (2 * h)
show("slope at r=0.999 and r=1.001, jump", din, dout, din - dout)
assert abs(din - dout - 2) < 3e-3

print("flow past the bar: exterior Neumann, d u/dn = -cos(theta)")
A, nd = nystrom(circle, 16, -0.5, adjoint=True)
sg = solve(A, [-math.cos(t) for t, *_ in nd])
show("Nystrom N=16: sigma at theta=0, 90 deg", sg[0], sg[4])
assert max(abs(s - 2 * math.cos(t)) for s, (t, *_) in zip(sg, nd)) < 1e-12
def speed(r, th):                 # m/s, centred differences of U a (r cos + S sigma)
    phi = lambda rr, tt: U * A_M * (rr * math.cos(tt) + slayer(circle, 4000, SG, at(rr, tt)))
    vr = (phi(r + h, th) - phi(r - h, th)) / (2 * h * A_M)
    vt = (phi(r, th + h) - phi(r, th - h)) / (2 * h * r * A_M)
    return math.hypot(vr, vt)
show("speed m/s at 5 cm from centre, top and front", speed(2, math.pi / 2), speed(2, math.pi))
assert abs(speed(2, math.pi / 2) - U * (1 + 1 / 4)) < 1e-6
show("surface speed m/s at the top, 2U; Reynolds number 2aU/nu", 2 * U, 2 * A_M * U / 1e-6)

print("interior Neumann: (I/2 + K') sigma = h, Fredholm alternative")
A, nd = nystrom(circle, 16, 0.5, adjoint=True)
show("row sum of the matrix (kills constants)", max(abs(sum(row)) for row in A))
show("test integral of h=1 and h=cos", TAU, sum(math.cos(t) * TAU / 16 for t, *_ in nd))
for c in [0.0, 0.7]:
    res = max(abs(sum(A[i][j] * (2 * math.cos(nd[j][0]) + c) for j in range(16)) - math.cos(nd[i][0])) for i in range(16))
    assert res < 1e-12
show("sigma = 2cos + 0.7 also solves h=cos; u at r=0.5", slayer(circle, 4000, lambda t: SG(t) + 0.7, at(0.5, 0)))

print("what breaks")
show("jump sign flipped: mu = +2cos, u at r=0.5", dlayer(circle, 4000, lambda t: 2 * math.cos(t), at(0.5, 0)))
show("jump dropped: rim value K mu with mu=-2cos", onrim)
show("double layer of 1: inside, outside r=2", dlayer(circle, 4000, lambda t: 1.0, at(0.5, 0)), dlayer(circle, 4000, lambda t: 1.0, at(2, 0)))
A, nd = nystrom(circle, 16, -0.5, adjoint=True)
leak = solve(A, [1.0] * 16)
show("leaky bar h=1: sigma, u at r=2 and r=10, ln r", leak[0], slayer(circle, 4000, lambda t: -1.0, at(2, 0)), slayer(circle, 4000, lambda t: -1.0, at(10, 0)), math.log(10))
assert abs(slayer(circle, 4000, lambda t: -1.0, at(10, 0)) - math.log(10)) < 1e-9
big = lambda t: ((2 * math.cos(t), 2 * math.sin(t)), (math.cos(t), math.sin(t)), 2.0, 0.5)
show("first kind, S of 1 inside radius 1 and radius 2", slayer(circle, 4000, lambda t: 1.0, at(0.5, 0)), slayer(big, 4000, lambda t: 1.0, at(0.5, 0)), -2 * math.log(2))
assert abs(slayer(big, 4000, lambda t: 1.0, at(0.5, 0)) + 2 * math.log(2)) < 1e-9   # needs the weight J = 2

print("flattened pipe (oval 2.5 x 1.5 cm): rim data x^2 - y^2, u at (0.5, 0.2)")
for N in [8, 16, 32, 64]:
    A, nd = nystrom(oval, N, -0.5)
    m = solve(A, [y[0] ** 2 - y[1] ** 2 for t, y, *_ in nd])
    u = sum(dk((0.5, 0.2), y, n) * m[j] * J * TAU / N for j, (t, y, n, J, k) in enumerate(nd))
    if N < 64: print("oval, N=%d, u=%.6f, error=%.1e" % (N, u, abs(u - 0.21)))
assert abs(u - 0.21) < 1e-10
A, nd = nystrom(oval, 64, -0.5, adjoint=True)       # exterior Neumann with K': u = x / (x^2 + y^2) outside
sg = solve(A, [((y[1] ** 2 - y[0] ** 2) * n[0] - 2 * y[0] * y[1] * n[1]) / (y[0] ** 2 + y[1] ** 2) ** 2 for t, y, n, J, k in nd])
ue = sum(sk((1.5, 0.5), y) * sg[j] * J * TAU / 64 for j, (t, y, n, J, k) in enumerate(nd))
show("oval, exterior Neumann N=64: S sigma at (1.5, 0.5), x/(x^2+y^2)", ue, 1.5 / (1.5 ** 2 + 0.5 ** 2))
assert abs(ue - 0.6) < 1e-9
print("ALL CHECKS PASS")
