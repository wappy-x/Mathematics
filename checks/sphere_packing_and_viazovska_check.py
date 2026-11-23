# Sphere packing in dimensions 8 and 24 -- the check behind the card.  Standard
# library only.  Exact counts: E8 and Leech vectors by enumeration and by
# modular forms.  Floats: densities, oranges in a crate, and the magic function.
from fractions import Fraction
from itertools import product
from math import pi, sqrt, exp, sin, factorial, comb

def sigma(k, n): return sum(d ** k for d in range(1, n + 1) if n % d == 0)

def ball8(rad): return pi ** 4 / 24 * rad ** 8          # volume of an 8-dim ball

# 1. E8 = integer points with even sum, plus half-integer points with even sum
shells = {2: 0, 4: 0, 6: 0}
for v in product(range(-2, 3), repeat=8):                # whole-number coordinates
    n = sum(x * x for x in v)
    if n in shells and sum(v) % 2 == 0: shells[n] += 1
for v in product((-3, -1, 1, 3), repeat=8):              # coordinates v/2, v odd
    n = Fraction(sum(x * x for x in v), 4)
    if n in shells and sum(v) % 4 == 0: shells[n] += 1
e4 = {2 * m: 240 * sigma(3, m) for m in (1, 2, 3)}       # q-coefficients of E4
print("E8 vectors of squared length 2, 4, 6, counted:", [shells[n] for n in (2, 4, 6)])
print("the same from E4 = 1 + 240 sum sigma3(n) q^n:  ", [e4[n] for n in (2, 4, 6)])
hole = {d: min(sum((x - 0.5) ** 2 for x in v) for v in product((0, 1), repeat=d) if sum(v) % 2 == 0)
        for d in (3, 8)}                                 # nearest even-sum point to (1/2, ..., 1/2)
for d in (3, 8):
    print(f"dim {d}: hole (1/2,...,1/2) sits {sqrt(hole[d]):.6f} from the lattice; minimum distance {sqrt(2):.6f}")
N = 100
pts = 1 + sum(240 * sigma(3, m) for m in range(1, N + 1))
print(f"E8 points with squared length <= {2 * N}: {pts}; ball volume / covolume 1 = "
      f"{ball8(sqrt(2 * N)):.1f}; ratio {pts / ball8(sqrt(2 * N)):.4f}")
r = sqrt(2) / 2                                          # ball radius: half of sqrt 2
dens = {"Z8": ball8(0.5) / 1, "D8": ball8(r) / 2, "E8": ball8(r) / 1}
print("density Z8 %.6f, D8 %.6f, E8 %.6f = pi^4/384 %.6f" % (*dens.values(), pi ** 4 / 384))
def theta8(t): return 1 + sum(240 * sigma(3, m) * exp(-pi * t * 2 * m) for m in range(1, 40))
gauss = theta8(1)                                        # sum of exp(-pi t |x|^2) over E8 at t = 1
print(f"Poisson, covolume 1, self-dual: sum at t = 0.8 {theta8(0.8):.9f}; t^-4 x sum at 1/t {theta8(1.25) / 0.8 ** 4:.9f}")
print(f"Gaussian test exp(-pi x^2) summed over E8: {gauss:.6f}, above its value 1 at 0")

# 2. Leech lattice: theta = E12 - (65520/691) Delta, against the Golay code count
tau = [0] * 6; tau[1] = 1                                # Delta = q prod (1 - q^n)^24
for n in range(1, 6):
    for _ in range(24):
        for k in range(5, n - 1, -1): tau[k] -= tau[k - n]
leech = [Fraction(65520, 691) * (sigma(11, m) - tau[m]) for m in (1, 2, 3)]
print("Leech vectors of squared length 2, 4, 6 from modular forms:", [int(x) for x in leech])
g = [1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1]                 # x^11+x^10+x^6+x^5+x^4+x^2+1
rows = [[0] * i + g + [0] * (11 - i) for i in range(12)] # cyclic code of length 23
words = []
for c in product((0, 1), repeat=12):
    w = [sum(c[i] * rows[i][j] for i in range(12)) % 2 for j in range(23)]
    words.append(w + [sum(w) % 2])                       # extend by a parity bit
wt = [sum(w) for w in words]
octads = wt.count(8)
print(f"Golay code: {len(words)} words, minimum weight {min(x for x in wt if x)}, {octads} octads")
kiss = octads * 2 ** 7 + 24 * 2 ** 12 + comb(24, 2) * 4
print(f"Leech shortest vectors from the code: {octads}*2^7 + 24*2^12 + 276*4 = {kiss}")
print(f"density Leech pi^12/12! {pi ** 12 / factorial(12):.10f}")

# 3. Oranges, 8 cm across, in a cube crate; densities in dimensions 2 and 3
for side in (40, 80):
    cubic = (side // 8) ** 3
    layers = int((side - 8) / (8 / sqrt(2))) + 1          # square layers, 5.657 cm apart
    m = side // 8
    pyr = sum(m * m if k % 2 == 0 else (m - 1) ** 2 for k in range(layers))
    print(f"crate {side} cm: cubic stacking {cubic} oranges, grocer's pyramid {pyr} ({layers} layers)")
print(f"density cubic {pi / 6:.6f}, pyramid pi/sqrt18 {pi / sqrt(18):.6f}, plane hexagonal {pi / sqrt(12):.6f}")
print(f"figure, unit 40 px, square hole radius {(sqrt(2) - 1) / 2:.6f}, hex row gap {sqrt(3) / 2:.6f}, square density {pi / 4:.6f}")

# 4. Viazovska's magic function g from phi0 (E2, E4, E6) and psi (theta functions)
def qsum(s, f):                                         # sum of f(n) q^n, q = exp(-2 pi s)
    q = exp(-2 * pi * s)
    return sum(f(n) * q ** n for n in range(1, 80))
def delta(s):                                            # E4^3 - E6^2 = 1728 q prod (1 - q^n)^24
    q, d = exp(-2 * pi * s), 1.0
    for n in range(1, 80): d *= (1 - q ** n) ** 24
    return 1728 * q * d
def phi0(s):                                             # 1728 (E2E4 - E6)^2 / (E4^3 - E6^2) at z = i s
    return 1728 * (720 * qsum(s, lambda n: n * sigma(3, n))) ** 2 / delta(s)
def phi0_inv(t):                                         # phi0(i/t): directly, or moved by z -> -1/z
    if t <= 1: return phi0(1 / t)
    e4 = 1 + 240 * qsum(t, lambda n: sigma(3, n))
    return 1728 * (720 * qsum(t, lambda n: n * sigma(3, n)) - 6 * e4 / (pi * t)) ** 2 / delta(t)
def theta(s):                                            # theta00, theta01, theta10 at i s
    a = 1 + 2 * sum(exp(-pi * s * n * n) for n in range(1, 40))
    b = 1 + 2 * sum((-1) ** n * exp(-pi * s * n * n) for n in range(1, 40))
    return a, b, 2 * sum(exp(-pi * s * (n + 0.5) ** 2) for n in range(40))
def psiI(s): a, b, c = theta(s); return 128 * (a**4 + b**4) / c**8 + 128 * (b**4 - c**4) / a**8
def psiS(s): a, b, c = theta(s); return -128 * (a**4 + c**4) / b**8 - 128 * (c**4 - b**4) / a**8
def expansion(t, sgn):                                   # large t: from the q-series' first terms
    return (sgn - 1) * 36 / pi**2 * exp(2 * pi * t) + 8640 * t / pi - (18144 - sgn * 5184) / pi**2
def AB(t, sgn, far=4):                                   # A (sgn -1) and B (sgn +1)
    if t < 0.25: return sgn * 368640 / pi**2 * t * t * exp(-pi / t)
    if t > far: return expansion(t, sgn)
    psi = psiI(t) if t >= 1 else -t * t * psiS(1 / t)
    return -t * t * phi0_inv(t) + sgn * 36 / pi**2 * psi
def simpson(f, lo, hi, m):
    h = (hi - lo) / m
    return h / 3 * sum((1 if k in (0, m) else 4 if k % 2 else 2) * f(lo + k * h) for k in range(m + 1))
def gval(r, sgn):                                        # g(r) (sgn -1, r > sqrt 2) or g-hat(r)
    c = pi * r * r
    body = simpson(lambda t: AB(t, sgn) * exp(-c * t) if t > 0 else 0.0, 0, 4, 3200)
    tail = (sgn - 1) * 36 / pi**2 * exp(8 * pi - 4 * c) / (c - 2 * pi) \
        + 8640 / pi * exp(-4 * c) * (4 / c + 1 / c**2) - (18144 - sgn * 5184) / pi**2 * exp(-4 * c) / c
    return pi / 2160 * sin(pi * r * r / 2) ** 2 * (body + tail)
t0 = 1.5
print(f"phi0(i/t) at t = 1.5: direct {phi0(1 / t0):.4f}, via z -> -1/z {phi0_inv(t0):.4f}")
print(f"psiI(i t) at t = 1.5: {psiI(t0):.4f}; -t^2 psiS(i/t): {-t0 * t0 * psiS(1 / t0):.4f}")
grid = [0.25, 0.5, 1, 2, 4]
print("t      :       0.25         0.5           1           2           4")
print("A(t)   :", "  ".join(f"{AB(t, -1):>11.4e}" for t in grid))
print("B(t)   :", "  ".join(f"{AB(t, 1):>11.4e}" for t in grid))
fine = [0.25 + k / 100 for k in range(376)]
print("checked on t = 0.25 to 4 in steps of 0.01: A < 0:", all(AB(t, -1) < 0 for t in fine),
      " B > 0:", all(AB(t, 1) > 0 for t in fine))
print(f"t = 4, A direct {AB(4, -1):.6e}, expansion {expansion(4, -1):.6e}; "
      f"B direct {AB(4, 1):.3f}, expansion {expansion(4, 1):.3f}")
print(f"g-hat(0.02) {gval(0.02, 1):.6f}; g-hat(0.05) {gval(0.05, 1):.6f}; g-hat(1) {gval(1, 1):.6f}; g-hat(sqrt3) {gval(sqrt(3), 1):.6f}")
print(f"g(sqrt3) {gval(sqrt(3), -1):.6f}; g(sqrt5) {gval(sqrt(5), -1):.7f}")

assert [shells[n] for n in (2, 4, 6)] == [e4[n] for n in (2, 4, 6)] == [240, 2160, 6720]
assert abs(pts / ball8(sqrt(2 * N)) - 1) < 0.05 and hole[8] == 2 and hole[3] < 2
assert abs(theta8(0.8) - theta8(1.25) / 0.8 ** 4) < 1e-9 and gauss > 1
assert [int(x) for x in leech] == [0, 196560, 16773120] == [0, kiss, 16773120]
assert octads == 759 and min(x for x in wt if x) == 8 and len(set(map(tuple, words))) == 4096
assert abs(phi0(1 / t0) / phi0_inv(t0) - 1) < 1e-9
assert abs(AB(4, 1) / expansion(4, 1) - 1) < 1e-4 and abs(AB(4, -1) / expansion(4, -1) - 1) < 1e-9
assert abs(psiI(t0) / (-t0 * t0 * psiS(1 / t0)) - 1) < 1e-9
assert all(AB(t, -1) < 0 < AB(t, 1) for t in fine) and abs(gval(0.02, 1) - 1) < 0.002
assert gval(sqrt(3), -1) < 0 < gval(sqrt(3), 1) and gval(sqrt(5), -1) < 0
print("ALL CHECKS PASS")
