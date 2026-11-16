# Dirichlet's principle -- the check behind the card.  Standard library only.
# A soap film spans a circular wire loop of radius R = 5 cm whose rim is bent to
# the height g = a cos(2 theta), a = 1 cm.  Lengths in cm, energies in cm^2.
from math import pi, sin, cos, sqrt, atan, log2
R, a = 5.0, 1.0

def simpson(f, lo, hi, n):                       # Simpson's rule, written out
    w, s = (hi - lo) / n, f(lo) + f(hi)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(lo + k * w)
    return s * w / 3

def disc(f, n=120):                              # integral of f(x, y) over the disc, in polar form
    return simpson(lambda r: r * simpson(lambda t: f(r * cos(t), r * sin(t)), 0, 2 * pi, n), 0, R, n)

def energy(grad):                                # Dirichlet energy E = 1/2 * integral of |grad w|^2
    return 0.5 * disc(lambda x, y: grad(x, y)[0] ** 2 + grad(x, y)[1] ** 2)

u  = lambda x, y: a * (x * x - y * y) / R ** 2   # the harmonic film, a (r/R)^2 cos 2theta
gu = lambda x, y: (2 * a * x / R ** 2, -2 * a * y / R ** 2)
w  = lambda x, y: a * (x ** 4 - y ** 4) / R ** 4 # a rival film: same rim, flatter in the middle
gw = lambda x, y: (4 * a * x ** 3 / R ** 4, -4 * a * y ** 3 / R ** 4)
gv = lambda x, y: (gw(x, y)[0] - gu(x, y)[0], gw(x, y)[1] - gu(x, y)[1])   # v = w - u, zero on the rim
mix = lambda e: (lambda x, y: (gu(x, y)[0] + e * gv(x, y)[0], gu(x, y)[1] + e * gv(x, y)[1]))

xs = [R * k / 5 for k in range(-5, 6)]
print("film height along y = 0, x = -R..R in 11 steps:", ", ".join(f"{u(x, 0):.2f}" for x in xs), "cm")
print("film height along x = 0, y = -R..R in 11 steps:", ", ".join(f"{u(0, y):.2f}" for y in xs), "cm")
Eu, Ew, Ev = energy(gu), energy(gw), energy(gv)
print(f"E(u), harmonic film: quadrature {Eu:.6f}, exact pi a^2 = {pi * a * a:.6f} cm^2")
print(f"E(w), rival film:    quadrature {Ew:.6f}, exact 5 pi a^2/4 = {5 * pi * a * a / 4:.6f} cm^2")
print(f"gap E(w) - E(u) = {Ew - Eu:.6f}, E(w - u) = {Ev:.6f}, exact pi a^2/4 = {pi * a * a / 4:.6f} cm^2")
assert abs(Eu - pi * a * a) < 1e-6 and abs(Ew - 5 * pi * a * a / 4) < 1e-6   # Simpson error at n = 120 is below 1e-6
assert abs((Ew - Eu) - Ev) < 1e-6                # Pythagoras: two separate integrals agree
es = (-1, -0.5, 0, 0.5, 1)
fam = [energy(mix(e)) for e in es]
print("E(u + e v), e = -1, -0.5, 0, 0.5, 1:", ", ".join(f"{E:.4f}" for E in fam), "cm^2")
for e, E in zip(es, fam):
    assert abs(E - pi * a * a * (1 + e * e / 4)) < 1e-6
h = 1e-4                                         # first variation: nudge both ways, then integrate by parts
dq_u = (energy(mix(h)) - energy(mix(-h))) / (2 * h)
dq_w = (energy(mix(1 + h)) - energy(mix(1 - h))) / (2 * h)
ibp_w = disc(lambda x, y: -(w(x, y) - u(x, y)) * 12 * a * (x * x - y * y) / R ** 4)
print(f"first variation along v at u: quotient {abs(dq_u):.6f} cm^2")
print(f"first variation along v at w: quotient {dq_w:.6f}, minus integral of v times Laplacian(w) {ibp_w:.6f}, exact pi a^2/2 = {pi * a * a / 2:.6f} cm^2")
assert abs(dq_u) < 1e-6 and abs(dq_w - pi * a * a / 2) < 1e-5 and abs(ibp_w - pi * a * a / 2) < 1e-6
lap = lambda f, x, y, s: (f(x + s, y) + f(x - s, y) + f(x, y + s) + f(x, y - s) - 4 * f(x, y)) / (s * s)
for s in (0.2, 0.1):
    print(f"Laplacian by centred differences at (3, 1) cm, step {s:.1f} cm: u {abs(lap(u, 3, 1, s)):.6f}, w {lap(w, 3, 1, s):.6f} per cm")
assert abs(lap(u, 3, 1, 0.1)) < 1e-9 and abs(lap(w, 3, 1, 0.1) - 96 * a / R ** 4) < 1e-6

def direct(N):                                   # direct method: lower a grid energy one node at a time
    M, hr, ht = 2 * N, R / N, pi / N             # rings r_i = i hr, angles j ht; ring N is the wire
    W = [[0.0] * M for _ in range(N)] + [[a * cos(2 * j * ht) for j in range(M)]]
    rad = [(i + 0.5) * ht for i in range(N)]     # weight of the radial edge from ring i to ring i + 1
    ang = [0.0] + [1 / (i * ht) for i in range(1, N)] + [0.5 / (N * ht)]   # angular edges on ring i
    def E():
        s = 0.0
        for i in range(N):
            for j in range(M):
                s += rad[i] * (W[i + 1][j] - W[i][0 if i == 0 else j]) ** 2
        for i in range(1, N + 1):
            for j in range(M):
                s += ang[i] * (W[i][(j + 1) % M] - W[i][j]) ** 2
        return 0.5 * s
    om, hist = 2 / (1 + sin(pi / N)), [E()]      # over-relaxed: each move still lowers the energy
    for sweep in range(1, 5001):
        c = 0.0
        for j in range(M):
            c += W[1][j]
        big = abs(om * (c / M - W[0][0]))
        W[0] = [W[0][0] + om * (c / M - W[0][0])] * M
        for i in range(1, N):
            for j in range(M):
                nb = rad[i - 1] * W[i - 1][0 if i == 1 else j] + rad[i] * W[i + 1][j] + ang[i] * (W[i][j - 1] + W[i][(j + 1) % M])
                step = om * (nb / (rad[i - 1] + rad[i] + 2 * ang[i]) - W[i][j])
                W[i][j] += step
                big = max(big, abs(step))
        hist.append(E())
        if big < 1e-13:
            break
    return hist[-1], W[N // 2][0], all(hist[k + 1] <= hist[k] + 1e-12 for k in range(len(hist) - 1)), sweep

errs, herrs = [], []
for N in (8, 16, 32):
    En, mid, falls, sw = direct(N)
    errs.append(En - pi * a * a); herrs.append(mid - a / 4)
    print(f"grid of {N} rings x {2 * N} angles: energy {En:.6f} cm^2 (error {En - pi * a * a:.6f}), height at ({R / 2:.1f}, 0) {mid:.6f} cm, {sw} sweeps, energy fell every sweep: {falls}")
    assert falls
print(f"exact height at ({R / 2:.1f}, 0) {u(R / 2, 0):.2f} cm; observed order, energy: {log2(errs[0] / errs[1]):.3f}, {log2(errs[1] / errs[2]):.3f}; height: {log2(herrs[0] / herrs[1]):.3f}, {log2(herrs[1] / herrs[2]):.3f}")
assert abs(errs[2]) < 0.005 * a * a and abs(herrs[2]) < 0.001 * a and 1.9 < log2(errs[1] / errs[2]) < 2.1

c = a / R ** 2                                   # the real area of the harmonic film, no small-slope shortcut
area_q = disc(lambda x, y: sqrt(1 + gu(x, y)[0] ** 2 + gu(x, y)[1] ** 2))
area_x = 2 * pi / (12 * c * c) * ((1 + 4 * c * c * R * R) ** 1.5 - 1)
print(f"steepest slope of the film {2 * c * R:.2f}; area: quadrature {area_q:.6f}, exact {area_x:.6f}, flat disc {pi * R * R:.6f} cm^2")
print(f"extra area: true {area_x - pi * R * R:.4f} cm^2, small-slope model E(u) = {Eu:.4f} cm^2, model high by {100 * (Eu / (area_x - pi * R * R) - 1):.2f} %")
print(f"film energy at 0.025 N/m per face (illustrative), two faces: true {2 * 0.025 * (area_x - pi * R * R) * 100:.2f} uJ, model {2 * 0.025 * Eu * 100:.2f} uJ")
assert abs(area_q - area_x) < 1e-6

# What breaks 1 (Hadamard 1906): rim g = sum 1/n^2 cos(n! theta) cm is continuous, |g| < pi^2/6 cm,
# but its harmonic film has energy (pi/2) sum n!/n^4 cm^2, which grows without bound.
part, fact, sums = 0.0, 1, []
for n in range(1, 11):
    fact *= n
    part += fact / n ** 4
    sums.append(pi / 2 * part)
print(f"Hadamard rim: height at most pi^2/6 = {pi * pi / 6:.3f} cm; energy with the first N terms, N = 1..10:", ", ".join(f"{s:.2f}" for s in sums), "cm^2")
def hgrad2(r, t):                                # |grad|^2 of the first three terms: modes 1, 2 and 6
    gr = gt = 0.0
    for n, k in ((1, 1), (2, 2), (3, 6)):
        gr += k / n ** 2 * (r / R) ** (k - 1) / R * cos(k * t)
        gt -= k / n ** 2 * (r / R) ** (k - 1) / R * sin(k * t)
    return gr * gr + gt * gt
E3 = 0.5 * simpson(lambda r: r * simpson(lambda t: hgrad2(r, t), 0, 2 * pi, 240), 0, R, 240)
print(f"Hadamard rim, first three terms by quadrature: {E3:.6f} cm^2, by the series: {sums[2]:.6f} cm^2")
assert abs(E3 - sums[2]) < 1e-6 and sums[9] - sums[8] > sums[8] - sums[7] > 10

# What breaks 2 (Weierstrass 1870): J[y] = integral over [-1, 1] of x^2 y'^2, y(-1) = -1, y(1) = 1.
# The ramps y = atan(x/e)/atan(1/e) push J toward 0, yet J = 0 needs y' = 0: no ramp attains it.
for e in (0.1, 0.01, 0.001):
    A = atan(1 / e)
    closed = e / A - e * e / ((1 + e * e) * A * A)
    quad = simpson(lambda x: x * x * (e / (e * e + x * x) / A) ** 2, -1, 1, 100000)
    print(f"Weierstrass ramp, width {e}: J = {closed:.6f} (closed form), {quad:.6f} (Simpson)")
    assert abs(closed - quad) < 1e-6
print("ALL CHECKS PASS")
