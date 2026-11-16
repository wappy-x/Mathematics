# Helmholtz and eigenfunctions -- the check behind the card.  Standard library only.
# A steel plate 0.6 m by 0.4 m, 3 mm thick, simply supported on all four edges.
# Its mode shapes are the eigenfunctions of -Laplacian on the rectangle with zero
# edge values.  Road 1: separated sines.  Road 2: a grid, solved by power iteration.
# Road 3: the Rayleigh quotient of a dome.  Then the dome is expanded in the modes.
import math
PI = math.pi
A, B, H = 0.6, 0.4, 0.003                 # plate sides and thickness, m
E, NU, RHO = 207e9, 0.30, 7850.0          # steel: Young's modulus Pa, Poisson's ratio, kg/m^3

def total(xs):                            # plain left-to-right sum, as in the Rust
    s = 0.0
    for x in xs:
        s += x
    return s

def lam(m, n):                            # road 1: eigenvalue of -Laplacian, 1/m^2
    return PI * PI * (m * m / (A * A) + n * n / (B * B))

def grid_eigs(h, k, iters):               # road 2: 5-point -Laplacian, zero on the edge
    nx, ny = round(A / h) - 1, round(B / h) - 1
    n = nx * ny
    def neg_lap(v):
        out = [0.0] * n
        for j in range(ny):
            for i in range(nx):
                p = j * nx + i
                s = 4.0 * v[p]
                if i > 0: s -= v[p - 1]
                if i < nx - 1: s -= v[p + 1]
                if j > 0: s -= v[p - nx]
                if j < ny - 1: s -= v[p + nx]
                out[p] = s / (h * h)
        return out
    c = 8.0 / (h * h)                     # above every grid eigenvalue (Gershgorin)
    found, vals = [], []
    for _ in range(k):
        v = [1.0 + ((7 * p) % 13) / 13.0 for p in range(n)]
        for _ in range(iters):            # power iteration on c*I - (-Laplacian)
            w = neg_lap(v)
            v = [c * v[p] - w[p] for p in range(n)]
            for u in found:               # remove the modes already found
                d = total(v[p] * u[p] for p in range(n))
                v = [v[p] - d * u[p] for p in range(n)]
            norm = math.sqrt(total(x * x for x in v))
            v = [x / norm for x in v]
        w = neg_lap(v)
        vals.append(total(v[p] * w[p] for p in range(n)))
        found.append(v)
    return vals

def simpson(f, lo, hi, panels):           # composite Simpson rule, panels even
    step = (hi - lo) / panels
    s = f(lo) + f(hi)
    for i in range(1, panels):
        s += (4 if i % 2 else 2) * f(lo + i * step)
    return s * step / 3

def coef(m, n):                           # unit dome's coefficient on mode (m,n), by quadrature
    ix = simpson(lambda x: x * (A - x) * math.sin(m * PI * x / A), 0, A, 400)
    iy = simpson(lambda y: y * (B - y) * math.sin(n * PI * y / B), 0, B, 400)
    return 4 / (A * B) * 16 / (A * A * B * B) * ix * iy

D = E * H * H * H / (12 * (1 - NU * NU))  # bending stiffness, N m
S = math.sqrt(D / (RHO * H))              # m^2/s: plate omega = lambda * S
hz = lambda lv: lv * S / (2 * PI)
modes = sorted((lam(m, n), m, n) for m in range(1, 9) for n in range(1, 9))
l1 = modes[0][0]
print(f"plate {A} m x {B} m x {H * 1000:.0f} mm steel: D = {D:.2f} N m, rho H = {RHO * H:.2f} kg/m^2, "
      f"sqrt(D/(rho H)) = {S:.4f} m^2/s")
print("mode  lambda (1/m^2)  omega (rad/s)  f (Hz)  plate ratio  membrane ratio")
for lv, m, n in modes[:4]:
    print(f"({m},{n})  {lv:13.3f}  {lv * S:12.2f}  {hz(lv):7.2f}  {lv / l1:10.3f}  {math.sqrt(lv / l1):13.3f}")
Dz = simpson(lambda z: E * z * z / (1 - NU * NU), -H / 2, H / 2, 2)   # D again: each layer's stiffness times z^2
def bih(h):                               # plate law, road 2: 13-point stencil for Delta^2 on phi_11 at the centre
    p = lambda i, j: math.sin(PI * (0.5 + i * h / A)) * math.sin(PI * (0.5 + j * h / B))
    return (20 * p(0, 0) - 8 * (p(1, 0) + p(-1, 0) + p(0, 1) + p(0, -1)) + 2 * (p(1, 1) + p(1, -1) + p(-1, 1)
            + p(-1, -1)) + p(2, 0) + p(-2, 0) + p(0, 2) + p(0, -2)) / (h * h * h * h) / p(0, 0)
b1, b2 = bih(0.05), bih(0.025)
brich = (4 * b2 - b1) / 3                 # Richardson, as for the grid road
fs = S * math.sqrt(brich) / (2 * PI)      # the first note, from the plate equation itself
print(f"plate law, second road: D by layers through the thickness {Dz:.2f} N m; 13-point stencil for Delta^2 phi_11 / phi_11:")
print(f"  h = 0.05 m {b1:.1f}, h = 0.025 m {b2:.1f}, order {math.log2((l1 * l1 - b1) / (l1 * l1 - b2)):.2f}, "
      f"Richardson {brich:.1f}, lambda_11^2 = {l1 * l1:.1f} 1/m^4; first note {fs:.2f} Hz")
first3 = [(m, n) for _, m, n in modes[:3]]
grids = {h: grid_eigs(h, 3, 6000) for h in (0.05, 0.025)}
print("grid road, first three eigenvalues of -Laplacian (1/m^2):")
for h, vals in grids.items():
    print(f"  h = {h} m: " + ", ".join(f"{x:.3f}" for x in vals))
rich = [(4 * grids[0.025][i] - grids[0.05][i]) / 3 for i in range(3)]
order = [math.log2((modes[i][0] - grids[0.05][i]) / (modes[i][0] - grids[0.025][i])) for i in range(3)]
print("  Richardson (4 x fine - coarse)/3: " + ", ".join(f"{x:.3f}" for x in rich))
print("  observed order: " + ", ".join(f"{x:.2f}" for x in order))
def rq(X, dX, Y, dY):                     # Rayleigh quotient of the shape X(x) Y(y), slopes dX, dY, by Simpson
    gx, gy = simpson(lambda x: X(x) * X(x), 0, A, 200), simpson(lambda y: Y(y) * Y(y), 0, B, 200)
    dx, dy = simpson(lambda x: dX(x) * dX(x), 0, A, 200), simpson(lambda y: dY(y) * dY(y), 0, B, 200)
    return (dx * gy + gx * dy) / (gx * gy)
R = rq(lambda x: x * (A - x), lambda x: A - 2 * x, lambda y: y * (B - y), lambda y: B - 2 * y)   # road 3: the dome
print(f"Rayleigh quotient of the dome x(a-x)y(b-y): R = {R:.3f} 1/m^2; "
      f"10/a^2 + 10/b^2 = {10 / (A * A) + 10 / (B * B):.3f}; lambda_1 = {l1:.3f}; R/lambda_1 = {R / l1:.4f}")
print(f"  f from R: {hz(R):.2f} Hz against {hz(l1):.2f} Hz")
c11, pi6 = coef(1, 1), PI * PI * PI * PI * PI * PI
print(f"unit dome 16 x(a-x) y(b-y)/(a^2 b^2): c11 by quadrature {c11:.6f}, 1024/pi^6 = {1024 / pi6:.6f}")
print(f"  c21 = {abs(coef(2, 1)):.6f}, c31 = {coef(3, 1):.6f}, c13 = {coef(1, 3):.6f}, c33 = {coef(3, 3):.6f}")
exact = [(m, n, 1024 / (pi6 * m * m * m * n * n * n)) for m in range(1, 60, 2) for n in range(1, 60, 2)]
parseval = total(c * c for _, _, c in exact)
print(f"  sum of c^2 over odd m, n < 60: {parseval:.6f}; mean-square rule (4/ab) int f^2 = 1024/900 = {1024 / 900:.6f}")
print(f"  share in mode (1,1): {100 * c11 * c11 / (1024 / 900):.2f} %")
for M in (1, 3, 5, 11, 21):
    s = total(c * (1 if (m + n) % 4 == 2 else -1) for m, n, c in exact if m <= M and n <= M)
    print(f"  centre value from modes m, n <= {M:2d}: {s:.6f}, error {s - 1:+.1e}")
Rexp = total(lam(m, n) * c * c for m, n, c in exact) / parseval
print(f"  R rebuilt from the expansion, sum lambda c^2 / sum c^2: {Rexp:.3f} 1/m^2, "
      f"short by {R - Rexp:.1e} (modes past 59 left out)")
strike = [math.sin(m * PI * 0.15 / A) * math.sin(n * PI * 0.10 / B) for m, n in first3]
centre = [abs(math.sin(m * PI / 2) * math.sin(n * PI / 2)) for m, n in first3]
print("strike at (0.15, 0.10) m, mode weights: " + ", ".join(f"{mn} {w:.3f}" for mn, w in zip(["(1,1)", "(2,1)", "(1,2)"], strike)))
print("strike at the centre, mode weights:     " + ", ".join(f"{mn} {w:.3f}" for mn, w in zip(["(1,1)", "(2,1)", "(1,2)"], centre)))
lim = 2 * PI * 20000 / S                  # lambda of a 20 kHz plate note
count = sum(1 for m in range(1, 400) for n in range(1, 400) if lam(m, n) <= lim)
weyl = A * B * lim / (4 * PI)
weyl2 = weyl - 2 * (A + B) * math.sqrt(lim) / (4 * PI)
print(f"plate notes below 20 kHz: lambda <= {lim:.0f} 1/m^2; count {count}; Weyl ab L/(4 pi) = {weyl:.1f}; with edge term {weyl2:.1f}")
print("mistakes:")
print(f"  membrane sqrt rule for the plate's 2nd note: {hz(l1) * math.sqrt(modes[1][0] / l1):.2f} Hz, not {hz(modes[1][0]):.2f} Hz")
R1 = rq(lambda x: 1.0, lambda x: 0.0, lambda y: 1.0, lambda y: 0.0)   # flat shape: slopes 0, not 0 on the edge
print(f"  trial w = 1 ignores the zero edge: R = {R1:.3f}, below lambda_1 = {l1:.3f}")
print(f"  c11 without dividing by int phi^2 = ab/4 = {A * B / 4:.2f} m^2: {c11 * A * B / 4:.6f}")
print(f"  omega read as hertz: {l1 * S:.2f} 'Hz' for a {hz(l1):.2f} Hz note")
print(f"figure, px per m 200: plates at x 20, 170, 320, y 30, size {A * 200:.0f} x {B * 200:.0f}; "
      f"nodal line of (2,1) at x {170 + A / 2 * 200:.0f}; of (1,2) at y {30 + B / 2 * 200:.0f}")
assert first3 == [(1, 1), (2, 1), (1, 2)]
assert all(abs(rich[i] / modes[i][0] - 1) < 5e-4 for i in range(3))     # grid meets sines
assert all(1.9 < p < 2.1 for p in order)                                 # second order, as claimed
assert l1 < R < 1.02 * l1 and abs(R - (10 / (A * A) + 10 / (B * B))) < 1e-6   # Rayleigh bound
assert abs(c11 - 1024 / pi6) < 1e-9 and abs(coef(2, 1)) < 1e-12        # quadrature meets formula
assert abs(parseval - 1024 / 900) < 1e-8 and 0 < R - Rexp < 2e-4         # the expansion is complete
assert abs(count - weyl2) < 15                                           # Weyl's count
assert abs(Dz / D - 1) < 1e-12 and abs(fs / hz(l1) - 1) < 1e-4          # plate law: D and the note by two roads
print("ALL CHECKS PASS")
