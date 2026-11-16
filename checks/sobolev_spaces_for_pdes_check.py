# Sobolev spaces for PDEs -- the check behind the card.  Standard library only.
# A square rubber sheet, 1 m x 1 m, rim held at height 0, tension T = 200 N/m.
# Roads: closed-form energies against midpoint quadrature; the Poincare constant
# 1/(pi sqrt 2) against inverse iteration on grids; the sag under a uniform load
# by a double sine series against an SOR grid solve, both against the Poincare
# bounds.  What breaks: a needle, a sheer wall, a free rim, a change of unit.
import math
PI = math.pi
T, B, F, R = 200.0, 0.02, 16.0, 0.5   # tension N/m; lift m; load N/m^2; needle's outer radius m
CP = 1 / (PI * math.sqrt(2))           # Poincare constant of the unit square, m

def sci(x):                            # same digits in Python and Rust: 1.234e-05
    e = math.floor(math.log10(abs(x)))
    m = x / 10 ** e
    if round(abs(m), 3) >= 10: m, e = m / 10, e + 1
    return f"{m:.3f}e{'+' if e >= 0 else '-'}{abs(e):02d}"

def quad2(f, M=400):                   # midpoint rule on the unit square
    h = 1 / M
    return sum(f((i + .5) * h, (j + .5) * h) for i in range(M) for j in range(M)) * h * h

def grad2(u, x, y, d=1e-6):            # |grad u|^2 by centred differences
    return ((u(x + d, y) - u(x - d, y)) / (2 * d)) ** 2 + ((u(x, y + d) - u(x, y - d)) / (2 * d)) ** 2

def radial(g, r0, r1, n=4000):         # integral of g(r) 2 pi r dr, midpoint rule in s = ln r
    a, b = math.log(r0), math.log(r1); ds = (b - a) / n
    return sum(g(math.exp(a + (k + .5) * ds)) * 2 * PI * math.exp(2 * (a + (k + .5) * ds)) for k in range(n)) * ds

def dr(p, r): return (p(r * (1 + 1e-6)) - p(r * (1 - 1e-6))) / (2e-6 * r)

print(f"sheet 1 m x 1 m, T = {T:.0f} N/m, lift b = {B} m; C_P = 1/(pi sqrt 2) = {CP:.6f} m")
print("shape | ||u||^2 (m^4) closed, quadrature | ||grad u||^2 (m^2) closed, quadrature | energy (J) | ||u||/||grad u|| (m)")
bump = lambda x, y: B * math.sin(PI * x) * math.sin(PI * y)
pyr = lambda x, y: B * (1 - max(abs(2 * x - 1), abs(2 * y - 1)))
for name, u, n2, g2 in (("bump", bump, B * B / 4, B * B * PI * PI / 2), ("pyramid", pyr, B * B / 6, 4 * B * B)):
    qn, qg = quad2(lambda x, y: u(x, y) ** 2), quad2(lambda x, y: grad2(u, x, y))
    print(f"{name} | {sci(n2)}, {sci(qn)} | {g2:.6f}, {qg:.6f} | {T / 2 * g2:.6f} | {math.sqrt(n2 / g2):.6f}")
    assert abs(qn - n2) < 1e-4 * n2 and abs(qg - g2) < 1e-2 * g2 and math.sqrt(n2 / g2) <= CP + 1e-12
    if name == "bump": assert abs(math.sqrt(qn / qg) - CP) < 1e-6   # the bump attains C_P: no smaller constant works

def needle(eps):                       # lift b at the centre, log profile out to R, zero beyond
    l = math.log(R / eps)
    p = lambda r: B * math.log(R / r) / l
    n2 = PI * eps * eps * B * B + 2 * PI * B * B / l ** 2 * (R * R / 4 - eps * eps * (l * l / 2 + l / 2 + 0.25))
    g2 = 2 * PI * B * B / l
    qn = PI * eps * eps * B * B + radial(lambda r: p(r) ** 2, eps, R)
    qg = radial(lambda r: dr(p, r) ** 2, eps, R)
    assert abs(qn - n2) < 1e-6 * n2 and abs(qg - g2) < 1e-6 * g2
    return n2, g2, l
n2, g2, l = needle(1e-3)
print(f"needle, tip 1 mm | {sci(n2)} | {g2:.6f} | {T / 2 * g2:.6f} | {math.sqrt(n2 / g2):.6f}")
print(f"  ln(R/eps) = {l:.5f}; slope at the tip b/(eps ln(R/eps)) = {B / (1e-3 * l):.3f}")
chart = [T / 2 * needle(10.0 ** -k)[1] for k in range(2, 11)]
print("chart, needle energy (J) at eps = 1e-2 ... 1e-10 m:", ", ".join(f"{e:.4f}" for e in chart))
assert all(chart[k + 1] < chart[k] for k in range(8))
print(f"  energy 0.001 J needs eps = R exp(-{PI * B * B * T / 0.001:.2f}) = {sci(R * math.exp(-PI * B * B * T / 0.001))} m")
print(f"knife edge along the midline: ||grad u||^2 >= 4 b^2 = {4 * B * B:.6f} m^2, energy >= {T / 2 * 4 * B * B:.6f} J")
assert chart[-1] < T / 2 * 4 * B * B

def lam1(N):                           # smallest eigenvalue of the grid -Laplacian, inverse iteration
    v = [[0.0 if i in (0, N) or j in (0, N) else 1.0 for j in range(N + 1)] for i in range(N + 1)]
    w = [[0.0] * (N + 1) for _ in range(N + 1)]
    for _ in range(12):
        sor(N, v, w)
        vw = sum(v[i][j] * w[i][j] for i in range(N + 1) for j in range(N + 1))
        ww = sum(w[i][j] ** 2 for i in range(N + 1) for j in range(N + 1))
        mx = max(max(row) for row in w); v = [[x / mx for x in row] for row in w]
    return vw / ww

def sor(N, rhs, u, tol=1e-14):         # solve -Lap_h u = rhs, zero rim, in place
    h2 = 1 / N / N; om = 2 / (1 + math.sin(PI / N))
    while True:
        big = 0.0
        for i in range(1, N):
            for j in range(1, N):
                d = om * ((u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] + h2 * rhs[i][j]) / 4 - u[i][j])
                u[i][j] += d; big = max(big, abs(d))
        if big < tol: return u

print(f"Poincare: lambda_1 = 2 pi^2 = {2 * PI * PI:.6f} /m^2, C_P = {CP:.6f} m")
errs = []
for N in (10, 20, 40):
    lh, exact = lam1(N), 8 * N * N * math.sin(PI / (2 * N)) ** 2
    errs.append(2 * PI * PI - lh)
    print(f"  grid h = {1 / N:.4f} m: inverse iteration {lh:.6f}, grid formula {exact:.6f}, C_P,h = {1 / math.sqrt(lh):.6f} m")
    assert abs(lh - exact) < 1e-8 * exact
    assert abs(1 / math.sqrt(lh) - CP) < 0.2 / N ** 2   # grid constants close in on C_P at order h^2
orders = [math.log2(errs[k] / errs[k + 1]) for k in range(2)]
print(f"  observed order of lambda_1: {orders[0]:.3f}, {orders[1]:.3f}")
assert all(1.9 < o < 2.1 for o in orders)

K = 999                                # sag under the load: double sine series, odd m, n <= K
c = s2 = g2 = 0.0
for m in range(1, K + 1, 2):
    for n in range(1, K + 1, 2):
        lm = PI * PI * (m * m + n * n); a = F / T * 16 / (PI * PI * m * n * lm)
        c += a * (-1) ** ((m + n) // 2 - 1); s2 += a * a / 4; g2 += lm * a * a / 4
print(f"sag, f = {F:.0f} N/m^2 (1.5 mm rubber at 1100 kg/m^3 weighs {1.5e-3 * 1100 * 9.81:.2f} N/m^2):")
print(f"  series to m, n <= {K}: centre {c:.6f} m, ||u||^2 = {sci(s2)} m^4, ||grad u||^2 = {sci(g2)} m^2,"
      f" energy {T / 2 * g2:.6f} J; centre tail <= {sci(F / T / (PI * PI * K))} m")
cs = []
for N in (20, 40, 80):
    u = sor(N, [[F / T] * (N + 1) for _ in range(N + 1)], [[0.0] * (N + 1) for _ in range(N + 1)])
    work = sum(F * u[i][j] for i in range(N + 1) for j in range(N + 1)) / N / N
    cs.append(u[N // 2][N // 2])
    print(f"  grid h = {1 / N:.4f} m: centre {u[N // 2][N // 2]:.6f} m, ||grad u||^2 = work/T = {sci(work / T)} m^2")
    assert abs(work / T - g2) < 8 / N / N * g2 and abs(cs[-1] - c) < 2 / N / N * c
print(f"  observed order of the centre sag: {math.log2((cs[0] - c) / (cs[1] - c)):.3f}, {math.log2((cs[1] - c) / (cs[2] - c)):.3f}")
fn = F * 1.0                           # ||f|| over the unit square, N/m
print(f"  Poincare bounds: ||grad u|| = {math.sqrt(g2):.6f} <= C_P ||f||/T = {CP * fn / T:.6f} m;"
      f" ||u|| = {math.sqrt(s2):.6f} <= C_P^2 ||f||/T = {CP * CP * fn / T:.6f} m^2")
assert math.sqrt(g2) <= CP * fn / T and math.sqrt(s2) <= CP * CP * fn / T
print(f"coercivity: alpha = 1/(1 + C_P^2) = {1 / (1 + CP * CP):.6f} (m); in cm, C_P = {100 * CP:.4f}, alpha = {1 / (1 + 1e4 * CP * CP):.6f}")
print("what breaks:")
for d, mm in ((1e-2, "10"), (1e-3, "1"), (1e-4, "0.1")):   # plateau of radius 0.1 m, wall width d
    a = 0.1; g = radial(lambda r: (B / d) ** 2, a, a + d)
    print(f"  sheer wall, plateau 0.1 m, wall {mm} mm: ||grad u||^2 = {g:.6f} m^2, energy {T / 2 * g:.4f} J")
    assert abs(g - PI * B * B * (2 * a + d) / d) < 1e-6 * g
fan = lambda x, y: B * (1 - math.atan2(y, x) / PI)   # a 2 cm step in the rim at the origin: the sheet fans around it
for d, mm in ((1e-2, "10"), (1e-3, "1"), (1e-4, "0.1")):   # half circles from radius d out to R
    g = radial(lambda r: grad2(fan, 0.0, r), d, R) / 2
    print(f"  rim step 2 cm, fan cut off {mm} mm from the step: ||grad u||^2 = {g:.6f} m^2, energy {T / 2 * g:.4f} J")
    assert abs(g - B * B / PI * math.log(R / d)) < 1e-4 * g   # the floor (T b^2 / 2 pi) ln(R/d), attained
print(f"  free rim, whole sheet lifted 2 cm: ||u||^2 = {sci(B * B)} m^4, ||grad u||^2 = 0; net load {fn:.0f} N, needs 0")
print("ALL CHECKS PASS")
