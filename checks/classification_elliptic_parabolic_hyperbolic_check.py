# Elliptic, parabolic, hyperbolic -- the check behind the card.  Only math is imported.
# Road one finds each principal matrix's eigenvalues by Jacobi rotations.  Road two counts
# their signs from the characteristic polynomial by Descartes' rule, with no eigenvalues.
# Road three scans the principal symbol over unit directions.  The three behaviours are
# checked by a series against a relaxed grid and a formula against a stepped grid.
from math import sqrt, pi, cos, sin, cosh, log, atan2

def jacobi(A):                             # road one: rotate the off-diagonal entries away
    a = [row[:] for row in A]; n = len(a)
    for _ in range(30):
        for p in range(n):
            for q in range(p + 1, n):
                t = 0.5 * atan2(2 * a[p][q], a[q][q] - a[p][p]); c, s = cos(t), sin(t)
                for k in range(n):
                    a[k][p], a[k][q] = c * a[k][p] - s * a[k][q], s * a[k][p] + c * a[k][q]
                for k in range(n):
                    a[p][k], a[q][k] = c * a[p][k] - s * a[q][k], s * a[p][k] + c * a[q][k]
    ev = sorted((a[i][i] for i in range(n)), reverse=True)
    big = max(abs(v) for v in ev)
    return [0.0 if abs(v) < 1e-12 * big else v for v in ev]

def charpoly(A):                           # det(lambda I - A), highest power first
    if len(A) == 2:
        return [1.0, -(A[0][0] + A[1][1]), A[0][0] * A[1][1] - A[0][1] * A[1][0]]
    (a, b, c), (d, e, f), (g, h, i) = A
    det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
    return [1.0, -(a + e + i), a * e - b * d + a * i - c * g + e * i - f * h, -det]

def descartes(cp):                         # road two: root signs read off the coefficients
    zero = 0
    while cp[-1] == 0: cp = cp[:-1]; zero += 1
    m = len(cp) - 1
    flips = lambda c: sum(1 for u, v in zip(c, c[1:]) if u * v < 0)
    return flips(cp), flips([x * (-1) ** (m - k) for k, x in enumerate(cp)]), zero

def symbol(A, xi): return sum(A[i][j] * xi[i] * xi[j] for i in range(len(A)) for j in range(len(A)))

def scan(A):                               # road three: the symbol over unit directions
    if len(A) == 2: ds = [(cos(pi * j / 360), sin(pi * j / 360)) for j in range(360)]
    else: ds = [(sin(pi * i / 180) * cos(pi * j / 180), sin(pi * i / 180) * sin(pi * j / 180), cos(pi * i / 180))
                for i in range(181) for j in range(360)]
    ps = [symbol(A, d) for d in ds]; lo, hi = min(ps), max(ps); tol = 1e-9 * max(abs(lo), abs(hi))
    return lo, hi, "both signs" if lo < -tol and hi > tol else ("touches 0" if min(abs(lo), abs(hi)) <= tol else "never 0")

def family(pos, neg, zero, n):
    if zero == 0 and max(pos, neg) == n: return "elliptic"
    if zero == 1 and max(pos, neg) == n - 1: return "parabolic"
    if zero == 0 and min(pos, neg) == 1: return "hyperbolic"
    return "none of the three"

KAP, C = 1.2e-5, sqrt(2000 / 0.2)          # steel diffusivity m^2/s; drum speed m/s from 2000 N/m over 0.2 kg/m^2
CASES = [("held steady  u_xx + u_yy = 0 in (x, y)", [[1, 0], [0, 1]]),
         ("cooling      kappa(u_xx + u_yy) - u_t = 0 in (x, y, t)", [[KAP, 0, 0], [0, KAP, 0], [0, 0, 0]]),
         ("drum ringing c^2(u_xx + u_yy) - u_tt = 0 in (x, y, t)", [[C * C, 0, 0], [0, C * C, 0], [0, 0, -1]]),
         ("trap         u_xx + u_yy + u_zz + 4(u_xy + u_yz + u_xz)", [[1, 2, 2], [2, 1, 2], [2, 2, 1]]),
         ("halved right u_xx + 2u_xy + u_yy, off-diagonal 1", [[1, 1], [1, 1]]),
         ("not halved   u_xx + 2u_xy + u_yy, off-diagonal 2", [[1, 2], [2, 1]])]
fams = {}
for name, A in CASES:
    ev = jacobi(A); n = len(A)
    s1 = (sum(v > 0 for v in ev), sum(v < 0 for v in ev), sum(v == 0 for v in ev))
    s2 = descartes(charpoly(A)); lo, hi, s3 = scan(A)
    fams[name[:12].strip()] = family(*s1, n)
    print(f"{name}: eigenvalues {', '.join(f'{v:.6f}' for v in ev)}; signs +{s1[0]} -{s1[1]} 0x{s1[2]}"
          f" -> {family(*s1, n)}; Descartes +{s2[0]} -{s2[1]} 0x{s2[2]}; scan {lo:.6f} to {hi:.6f}, {s3}")
    assert s1 == s2                         # eigenvalue signs and coefficient signs agree
    assert (s3 == "both signs") == (s1[0] > 0 and s1[1] > 0) and (s3 == "touches 0") == (s1[2] > 0)

# characteristic surfaces: the cone r = c t for the drum, the slices t = const for cooling
for x, y, t in [(0.3, 0.1, 0.002), (-0.2, 0.25, 0.004)]:
    e = 1e-6; phi = lambda x, y, t: sqrt(x * x + y * y) - C * t
    g = [(phi(x + e, y, t) - phi(x - e, y, t)) / (2 * e), (phi(x, y + e, t) - phi(x, y - e, t)) / (2 * e),
         (phi(x, y, t + e) - phi(x, y, t - e)) / (2 * e)]
    pc = symbol(CASES[2][1], g)
    print(f"cone at ({x}, {y}, {t}): drum symbol on the cone's normal, size {abs(pc):.6f} against c^2 = {C * C:.0f}")
    assert abs(pc) < 1e-4 * C * C
print(f"slice t = const: cooling symbol {symbol(CASES[1][1], [0, 0, 1]):.1f}, drum symbol {symbol(CASES[2][1], [0, 0, 1]):.1f}")
lo_, hi_ = 0.0, 1e6                         # front speed s with symbol(n, -s) = 0, by bisection
for _ in range(200):
    mid = (lo_ + hi_) / 2
    lo_, hi_ = (mid, hi_) if symbol(CASES[2][1], [1, 0, -mid]) > 0 else (lo_, mid)
print(f"travel: drum front speed by bisection {lo_:.6f} m/s, formula sqrt(T/sigma) {C:.6f} m/s; "
      f"centre tap reaches long edges after {0.25 / C * 1000:.2f} ms, short edges {0.5 / C * 1000:.2f} ms; "
      f"lowest note {C / 2 * sqrt(1 / 1 ** 2 + 1 / 0.5 ** 2):.2f} Hz")
assert abs(lo_ - C) < 1e-6

# settle: steady plate 1 m by 0.5 m, long edge y = 0 at 100 C, other edges 0 C, centre value
term = lambda n: 400 / (n * pi) * sin(n * pi / 2) / (2 * cosh(n * pi * 0.25))
ser = sum(term(n) for n in range(1, 16, 2))
nx, ny, w = 40, 20, 1.78
u = [[100.0 if j == 0 and 0 < i < nx else 0.0 for i in range(nx + 1)] for j in range(ny + 1)]
for sweep in range(1, 3001):
    big = 0.0
    for j in range(1, ny):
        for i in range(1, nx):
            d = w * ((u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4 - u[j][i]); u[j][i] += d; big = max(big, abs(d))
    if big < 1e-10: break
print(f"settle: centre {ser:.4f} C by series to n = 15 (first omitted term {abs(term(17)):.6f} C), "
      f"{u[ny // 2][nx // 2]:.4f} C by relaxation at h = 0.025 m in {sweep} sweeps")
assert abs(ser - u[ny // 2][nx // 2]) < 0.1

# spread: a weld spot across a 1 m strip, explicit steps, its variance against 2 kappa t
h, r = 0.01, 0.25; dt = r * h * h / KAP; v = [0.0] * 101; v[50] = 1.0
for _ in range(288): v = [0.0] + [v[j] + r * (v[j - 1] - 2 * v[j] + v[j + 1]) for j in range(1, 100)] + [0.0]
var = sum((j * h - 0.5) ** 2 * v[j] for j in range(101)) / sum(v)
print(f"spread: after {288 * dt:.1f} s the spot's standard width is {100 * sqrt(var):.4f} cm on the grid, "
      f"{100 * sqrt(2 * KAP * 600):.4f} cm from sqrt(2 kappa t); slowest mode of the plate fades with time constant "
      f"{1 / (KAP * pi * pi * 5):.1f} s; at 0.5 m after 1 s the kernel is 10^{-0.25 / (4 * KAP) / log(10):.1f} of its peak")
assert abs(sqrt(var) - sqrt(2 * KAP * 600)) < 1e-4

# uniform ellipticity: a tapered plate, thickness 10 mm at x = 0 down to the tip, steel k = 50 W/(m K)
def taper(tip, eps=0.0):                   # A(x) = k h(x) I; theta, heat flow per metre of width, middle temperature
    hx = lambda x: 0.010 * (1 - (1 - tip / 0.010) * x)
    theta = min(scan([[50 * hx(i / 100), 0], [0, 50 * hx(i / 100)]])[0] for i in range(101) if i / 100 <= 1 - eps)
    m = 2000; L = 1 - eps; f = lambda x: 1 / (50 * hx(x))
    simp = lambda b: (b / m / 3) * sum((1 if k in (0, m) else 4 if k % 2 else 2) * f(b * k / m) for k in range(m + 1))
    q = 100 / simp(L)
    return theta, q, 100 - q * simp(0.5)
for tip in (0.002, 0.001):
    th, q, mid = taper(tip); a = 1 - tip / 0.010
    qf = 100 * 0.5 * a / log(1 / (1 - a)); midf = 100 - qf * log(1 / (1 - a / 2)) / (0.5 * a)
    print(f"taper to {tip * 1000:.0f} mm: theta {th:.4f} W/K; heat flow {q:.4f} W/m (closed form {qf:.4f}); middle {mid:.4f} C (closed form {midf:.4f})")
    assert abs(th - 50 * tip) < 1e-12 and abs(q - qf) < 1e-6 and abs(mid - midf) < 1e-6
for eps in (1e-3, 1e-6):                    # knife edge, cut eps short of the tip: theta = 50 * 0.01 * eps
    q = 100 * 0.5 / log(1 / eps)
    print(f"knife edge cut {eps:.6f} m short: theta {50 * 0.010 * eps:.7f} W/K; heat flow {q:.4f} W/m; middle {100 - q * log(2) / 0.5:.4f} C")

# what breaks: a ringing steel plate bends, a fourth-order equation; E 200 GPa, nu 0.3, 5 mm, 7850 kg/m^3
D = 200e9 * 0.005 ** 3 / (12 * (1 - 0.3 ** 2)); m = 7850 * 0.005
print(f"steel plate: D {D:.1f} N m, mass {m:.2f} kg/m^2; bending wave speed {sqrt(D / m) * 2 * pi / 1.0:.2f} m/s "
      f"at 1 m wavelength, {sqrt(D / m) * 2 * pi / 0.1:.2f} m/s at 0.1 m: no single speed")
# try changing: the trap's off-diagonal entries
for off in (0.4, -0.5):
    ev = jacobi([[1, off, off], [off, 1, off], [off, off, 1]])
    print(f"try: trap off-diagonal {off:.1f}: eigenvalues {', '.join(f'{v:.6f}' for v in ev)}")
print(f"try: drum tension 8000 N/m: speed {sqrt(8000 / 0.2):.1f} m/s, long edges after {0.25 / sqrt(8000 / 0.2) * 1000:.3f} ms, "
      f"lowest note {sqrt(8000 / 0.2) / 2 * sqrt(5):.2f} Hz")
assert fams["held steady"] == "elliptic" and fams["cooling"] == "parabolic" and fams["drum ringing"] == "hyperbolic"
assert fams["trap"] == "hyperbolic" and fams["halved right"] == "parabolic" and fams["not halved"] == "hyperbolic"
print("ALL CHECKS PASS")
