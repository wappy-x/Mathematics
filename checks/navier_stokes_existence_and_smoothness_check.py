# Navier-Stokes existence and smoothness -- the check behind the card.  Standard
# library only.  It tests the hypotheses of the Clay versions A to D on concrete
# data; it does not, and cannot, test the conjecture itself.
# Units: lengths in cm, speeds in m/s, so time is in units of 0.01 s and water's
# kinematic viscosity 1.0e-6 m^2/s becomes NU = 1.0e-4.
import math
NU = 1.0e-6 / (0.01 * 1.0)

def en(x, p=4):                     # e-notation written the way Rust writes it
    m, ex = f"{x:.{p}e}".split("e")
    return f"{m}e{int(ex)}"

def swirl(x, y, z, g):             # u = (-y, x, 0) g(r): water turning about the z-axis
    r = math.sqrt(x * x + y * y + z * z)
    s = g(r)
    return (-y * s, x * s, 0.0)

GAUSS = lambda r: 2.0 * math.exp(-r * r)          # version A datum: dies off fast
SLOW = lambda r: (1.0 + r * r) ** -1.5              # smooth, finite energy, slow tail

def div(f, x, y, z, d=1e-4):                        # divergence by central differences
    return ((f(x + d, y, z)[0] - f(x - d, y, z)[0]) + (f(x, y + d, z)[1] - f(x, y - d, z)[1])
            + (f(x, y, z + d)[2] - f(x, y, z - d)[2])) / (2 * d)

# ---- road 1: grid sums over the cube [-6, 6]^3, spacing 0.25 ----
h, n, d = 0.25, 24, 1e-4
E = Y = W = 0.0
for i in range(-n, n + 1):
    for j in range(-n, n + 1):
        for k in range(-n, n + 1):
            x, y, z = i * h, j * h, k * h
            u = swirl(x, y, z, GAUSS)
            E += 0.5 * sum(c * c for c in u)
            for e in ((d, 0, 0), (0, d, 0), (0, 0, d)):       # gradient by differences
                up = swirl(x + e[0], y + e[1], z + e[2], GAUSS)
                um = swirl(x - e[0], y - e[1], z - e[2], GAUSS)
                Y += sum(((up[c] - um[c]) / (2 * d)) ** 2 for c in range(3))
            ex = math.exp(-(x * x + y * y + z * z))            # vorticity, by hand
            W += (4 * x * z * ex) ** 2 + (4 * y * z * ex) ** 2 + ((4 - 4 * (x * x + y * y)) * ex) ** 2
E, Y, W = E * h ** 3, Y * h ** 3, W * h ** 3
E_exact = (math.pi / 2) ** 1.5                      # 1/2 * 4 * 2 * (sqrt(pi)/(2*2^1.5)) * (pi/2)
print(f"house: Clay list 7 problems, 1 solved (Poincare), 6 open; nu = {en(NU, 1)} in cm, m/s units")
print(f"swirl peak speed {2 * math.sqrt(0.5) * math.exp(-0.5):.4f} m/s at {math.sqrt(0.5):.4f} cm from the axis")
print(f"swirl energy E0: grid {E:.6f}, closed form (pi/2)^1.5 = {E_exact:.6f}")
print(f"swirl in joules (x 1000 kg/m^3 x 1e-6 m^3/cm^3): {en(E * 1e-3)} J")
print(f"swirl enstrophy: grad u squared {Y:.6f}; vorticity squared {W:.6f}")
divs = [div(lambda a, b, c: swirl(a, b, c, GAUSS), *p) for p in ((0.3, -0.7, 0.5), (1.1, 0.4, -0.9))]
print("swirl divergence at two points ~0:", "yes" if max(abs(v) for v in divs) < 1e-6 else "no")
squeeze = lambda a, b, c: (a * math.exp(-a * a), 0.0, 0.0)
print(f"a squeezing field (x e^(-x^2), 0, 0) at x = 0: divergence {div(squeeze, 0.0, 0.0, 0.0):.4f}")
prod = math.sqrt(2 * E) * math.sqrt(Y)
print(f"small-start size |u0| |grad u0| = {prod:.4f} = {en(prod / NU ** 2)} nu^2")
print(f"speed scale that brings it to 1 nu^2: {en(1 / math.sqrt(prod / NU ** 2))} of the swirl's")

# ---- the decay condition (4) along the x-axis: (1 + r)^3 |u(r, 0, 0)| ----
rs = [0, 1, 2, 4, 8, 16, 32, 64]
fa = [(1 + r) ** 3 * r * GAUSS(r) for r in rs]
fs = [(1 + r) ** 3 * r * SLOW(r) for r in rs]
print("chart, r (cm):", ", ".join(str(r) for r in rs))
print("chart, Gaussian swirl (1+r)^3 |u|:", ", ".join(f"{v:.3f}" for v in fa))
print("chart, slow swirl (1+r)^3 |u|:", ", ".join(f"{v:.3f}" for v in fs))
for K in (3, 6, 10):                                 # largest value of (1+r)^K |u| on the grid
    mx, at = max(((1 + q / 100) ** K * (q / 100) * GAUSS(q / 100), q / 100) for q in range(6401))
    print(f"Gaussian swirl: largest (1+r)^{K} |u| on a 0.01 cm grid to r = 64 is {mx:.4f}, at r = {at:.2f}")
    assert (1 + 64) ** K * 64 * GAUSS(64) < 1e-100 < mx
# slow swirl energy: (4 pi / 3) int r^4 SLOW(r)^2 dr; put r = tan(t), so dr = (1 + r^2) dt
m, rt = 2000, lambda q: math.tan(q * math.pi / 2 / m)
simp = sum((1 if q in (0, m) else 4 if q % 2 else 2) * rt(q) ** 4 * SLOW(rt(q)) ** 2 * (1 + rt(q) ** 2)
           for q in range(m + 1)) * (math.pi / 2 / m) / 3
print(f"slow swirl energy: Simpson {4 * math.pi / 3 * simp:.6f}, closed form pi^2/4 = {math.pi ** 2 / 4:.6f}")

# ---- the periodic case: Taylor-Green flow in the unit cube, an exact solution ----
kw = 2 * math.pi
def tg(x, y, t):
    f = math.exp(-2 * kw * kw * NU * t)
    return (math.sin(kw * x) * math.cos(kw * y) * f, -math.cos(kw * x) * math.sin(kw * y) * f)
def tgp(x, y, t):
    return 0.25 * (math.cos(2 * kw * x) + math.cos(2 * kw * y)) * math.exp(-4 * kw * kw * NU * t)
def residual(x, y, t, P, e=1e-4):                    # Navier-Stokes, term by term, by differences
    u, out = tg(x, y, t), []
    for c in range(2):
        dt = (tg(x, y, t + e)[c] - tg(x, y, t - e)[c]) / (2 * e)
        dx = (tg(x + e, y, t)[c] - tg(x - e, y, t)[c]) / (2 * e)
        dy = (tg(x, y + e, t)[c] - tg(x, y - e, t)[c]) / (2 * e)
        lap = (tg(x + e, y, t)[c] + tg(x - e, y, t)[c] + tg(x, y + e, t)[c] + tg(x, y - e, t)[c] - 4 * u[c]) / e ** 2
        gp = ((P(x + e, y, t) - P(x - e, y, t)) if c == 0 else (P(x, y + e, t) - P(x, y - e, t))) / (2 * e)
        out.append(abs(dt + u[0] * dx + u[1] * dy + gp - NU * lap))
    return max(out)
pts = [(0.13, 0.71, 0.0), (0.42, 0.05, 50.0), (0.88, 0.37, 400.0)]
res = max(residual(*p, tgp) for p in pts)
bad = max(residual(*p, lambda a, b, c: -tgp(a, b, c)) for p in pts)
print(f"Taylor-Green: residual below 1e-5 at 3 points: {'yes' if res < 1e-5 else 'no'}; "
      f"pressure sign flipped: residual {bad:.4f}")
cell = sum(0.5 * sum(c * c for c in tg(i / 8, j / 8, 0.0)) for i in range(8) for j in range(8)) / 64
print(f"Taylor-Green energy per unit cell: grid {cell:.6f}, by hand 1/4 = {0.25:.6f}")
for N in (1, 10, 100):
    print(f"same flow read on all of space: energy in {N}^3 cells = {cell * N ** 3:.2f}")
half = math.log(2) / (4 * kw * kw * NU)
print(f"half-life of its energy: ln 2 / (4 k^2 nu) = {half:.4f} units = {half * 0.01:.4f} s")
print(f"Gaussian swirl is not periodic: |u(1.5,0,0) - u(0.5,0,0)| = "
      f"{abs(swirl(1.5, 0, 0, GAUSS)[1] - swirl(0.5, 0, 0, GAUSS)[1]):.4f}")

# ---- A against C: a toy world with D data and F forces (one of them zero) ----
D, F = 2, 2
tally = {}
for w in range(2 ** (D * F)):                       # bit (d, f) set: that pair breaks down
    a = all(not (w >> (d * F + 0)) & 1 for d in range(D))     # force 0 never breaks
    c = w != 0                                                  # some pair breaks
    tally[(a, c)] = tally.get((a, c), 0) + 1
print(f"toy worlds {2 ** (D * F)}: A and C {tally.get((True, True), 0)}, A only {tally.get((True, False), 0)}, "
      f"C only {tally.get((False, True), 0)}, neither {tally.get((False, False), 0)}")
print("checked for D, F <= 3: 'neither' never happens")
assert [tally.get(k, 0) for k in ((False, False), (False, True), (True, False), (True, True))] == \
       [0, 2 ** (D * F) - 2 ** (D * (F - 1)), 1, 2 ** (D * (F - 1)) - 1]   # the printed tally, against the formula
for D2 in range(1, 4):
    for F2 in range(1, 4):
        cnt = [0, 0, 0, 0]
        for w in range(2 ** (D2 * F2)):
            a = all(not (w >> (d * F2)) & 1 for d in range(D2))
            cnt[2 * a + (w != 0)] += 1
        assert cnt == [0, 2 ** (D2 * F2) - 2 ** (D2 * (F2 - 1)), 1, 2 ** (D2 * (F2 - 1)) - 1]
assert abs(E - E_exact) < 1e-9 and abs(Y - W) < 1e-6 * W        # two roads, twice
assert abs(4 * math.pi / 3 * simp - math.pi ** 2 / 4) < 1e-9
assert max(abs(v) for v in divs) < 1e-6 and abs(div(squeeze, 0, 0, 0) - 1) < 1e-6
assert res < 1e-5 and bad > 0.1 and abs(cell - 0.25) < 1e-12
assert fs[-1] > fs[-2] > fs[-3] > fs[-4] and fs[-1] > 60 and fa[-1] < 1e-100
print("ALL CHECKS PASS")
