# Quantum oscillator check: the vibration of one H-35Cl molecule.  Standard library only.
# Levels in units of hbar*omega reached four ways: the ladder formula n + 1/2, ladder steps
# applied to a Gaussian on a grid, the grid matrix's eigenvalues by Sturm counting, and the
# power series shot out to xi = 6 with the energy found by bisection.
from math import pi, sqrt, exp, floor

h, c, u, eV, kB = 6.62607015e-34, 299792458.0, 1.66053906892e-27, 1.602176634e-19, 1.380649e-23
hbar = h / (2 * pi)                                       # CODATA 2022; h, c, e, kB exact
mH, mCl, mD = 1.00782503223, 34.968852682, 2.01410177812  # atomic masses, u (NIST)
we, wexe, re, Be = 2990.9463, 52.8186, 127.4552, 10.593416  # cm^-1, cm^-1, pm, cm^-1 (NIST WebBook)
wN2, wO2 = 2358.57, 1580.193                              # N2 and O2 vibration, cm^-1 (NIST WebBook)
mu_u = mH * mCl / (mH + mCl)                              # reduced mass, u
mu = mu_u * u
omega = 2 * pi * c * we * 100                             # angular frequency, rad/s
k = mu * omega ** 2                                       # bond stiffness, N/m
gap = hbar * omega / eV                                   # one rung, eV
x0 = sqrt(hbar / (mu * omega)) * 1e12                     # natural length, pm
kT = kB * 298.15 / eV                                     # thermal energy at 25 C, eV

L, dx = 8.0, 0.01                                         # grid in xi = x / x0
N = int(round(2 * L / dx)) + 1
xs = [-L + i * dx for i in range(N)]
def slope(f): return [0.0] + [(f[i + 1] - f[i - 1]) / (2 * dx) for i in range(1, N - 1)] + [0.0]
def up(f):   g = slope(f); return [(xs[i] * f[i] - g[i]) / sqrt(2) for i in range(N)]   # a-dagger
def down(f): g = slope(f); return [(xs[i] * f[i] + g[i]) / sqrt(2) for i in range(N)]   # a
def size(f): return sqrt(sum(v * v for v in f) * dx)
def energy(f):                                            # <f|H|f>/<f|f>, H = -1/2 d2 + 1/2 xi^2
    top = sum(f[i] * (-(f[i + 1] - 2 * f[i] + f[i - 1]) / (2 * dx * dx) + 0.5 * xs[i] ** 2 * f[i])
              for i in range(1, N - 1))
    return top / sum(v * v for v in f)
psi = [exp(-x * x / 2) for x in xs]
kill = size(down(psi)) / size(psi)                        # a on the ground state: should be 0
grow = size(up(up(psi))) / size(up(psi))                  # a-dagger on state 1: size grows by sqrt 2
ladder, f = [], psi
for n in range(5):
    ladder.append(energy(f)); f = up(f)

diag = [1 / (dx * dx) + 0.5 * x * x for x in xs[1:-1]]    # the same H as a tridiagonal matrix
off2 = (0.5 / (dx * dx)) ** 2
def count_below(lam):                                     # Sturm count: eigenvalues below lam
    cnt, q = 0, 1.0
    for i, d in enumerate(diag):
        q = d - lam - (off2 / q if i else 0.0)
        if q == 0.0: q = 1e-300
        if q < 0: cnt += 1
    return cnt
def matrix_level(n):
    lo, hi = 0.0, 20.0
    for _ in range(50):
        mid = (lo + hi) / 2
        if count_below(mid) > n: hi = mid
        else: lo = mid
    return (lo + hi) / 2
matrix = [matrix_level(n) for n in range(5)]

def series(eps, start, xi):                               # y(xi) = sum a_j xi^j, psi = y e^(-xi^2/2)
    a, total = 1.0, 0.0
    for j in range(start, 300, 2):
        total += a * xi ** j
        a *= (2 * j + 1 - 2 * eps) / ((j + 1) * (j + 2))  # the recurrence from Hermite's equation
    return total
def shoot(n, xi=6.0):                                     # find eps where the tail at xi flips sign
    lo, hi = n + 0.1, n + 2.1                             # the only root of level n's parity in here
    s_lo = series(lo, n % 2, xi) > 0
    assert s_lo != (series(hi, n % 2, xi) > 0), "no sign change: the root is outside the bracket"
    for _ in range(60):
        mid = (lo + hi) / 2
        if (series(mid, n % 2, xi) > 0) == s_lo: lo = mid
        else: hi = mid
    return (lo + hi) / 2
shot = [shoot(n) for n in range(5)]

print(f"reduced mass {mu_u:.6f} u   omega {omega:.5e} rad/s   stiffness {k:.1f} N/m")
print(f"rung hbar*omega {gap:.5f} eV   floor E0 {gap / 2:.5f} eV   wavelength {1e4 / we:.4f} um")
print(f"natural length x0 {x0:.3f} pm   ground spread x0/sqrt2 {x0 / sqrt(2):.3f} pm"
      f" = {100 * x0 / sqrt(2) / re:.2f} % of {re} pm")
print(f"hbar {hbar:.4e} J s   mu {mu:.4e} kg   h/hbar {2 * pi:.2f}   bond {re:.1f} pm   xi=2.5 is {2.5 * x0:.1f} pm")
print(f"kT at 298.15 K {kT:.5f} eV   rung/kT {gap / kT:.3f}   share above v=0 {exp(-gap / kT):.3e}")
print(f"N2 rung {wN2:.1f} cm^-1 = {wN2 / we * gap / kT:.1f} kT   O2 rung {wO2:.1f} cm^-1 = {wO2 / we * gap / kT:.1f} kT"
      f"   HCl rotation comb 2 Be {2 * Be:.0f} cm^-1")
print(f"a on ground state, size ratio {kill:.2e};  a-dagger on state 1, size ratio {grow:.6f}")
print(" n   formula   ladder grid   matrix grid   series shot   level eV")
for n in range(5):
    print(f"{n:2d} {n + 0.5:9.4f} {ladder[n]:13.6f} {matrix[n]:13.6f} {shot[n]:13.9f} {(n + 0.5) * gap:10.5f}")
a_s = [1.0]
for j in (0, 2, 4): a_s.append(a_s[-1] * (2 * j + 1 - 5) / ((j + 1) * (j + 2)) + 0.0)
print("series at eps 2.5: a0 a2 a4 a6 " + " ".join(f"{v:.1f}" for v in a_s)
      + f";  psi(6) {series(2.5, 0, 6) * exp(-18):.3e}")
print(f"series at eps 2.6: psi(6) {series(2.6, 0, 6) * exp(-18):.3e}")
print("gaps v->v+1, cm^-1: v  harmonic  anharmonic")
anh = [we - 2 * wexe * (v + 1) for v in range(10)]
for v in (0, 1, 2, 3, 4, 5, 9):
    print(f"  {v:2d} {we:9.1f} {anh[v]:10.1f}")
De = we * we / (4 * wexe)
print(f"v=0 gap below the spring model by {100 * (we - anh[0]) / we:.1f} %;  corrected line {1e4 / anh[0]:.4f} um")
print(f"Morse: top bound level v={floor(we / (2 * wexe) - 0.5)}   De {De:.0f} cm^-1 = {De * 100 * h * c / eV:.3f} eV")
print(f"wrong: drop the half, E0 {0.0:.5f} eV;  h for hbar, E0 {gap / 2 * 2 * pi:.4f} eV")
print(f"wrong: H mass alone {we * sqrt(mu_u / mH):.1f} cm^-1 = {1e4 / (we * sqrt(mu_u / mH)):.4f} um")
print(f"wrong: box ladder, 0->2 line {we * 8 / 3:.1f} cm^-1 vs oscillator {2 * we:.1f} cm^-1")
muD = mD * mCl / (mD + mCl)
print(f"try: D-35Cl {we * sqrt(mu_u / muD):.1f} cm^-1 = {1e4 / (we * sqrt(mu_u / muD)):.4f} um;"
      f"  share above v=0 at 1000 K {exp(-gap * eV / (kB * 1000)):.4f}")
walled = [shoot(n, 2.5) for n in (0, 4)]
print(f"try: shoot to xi=2.5, levels {walled[0]:.4f} {walled[1]:.4f}, rises {walled[0] - 0.5:.4f} {walled[1] - 4.5:.4f}")
Ve = lambda r: 0.5 * k * ((r - re) * 1e-12) ** 2 / eV
a_m = sqrt(k / (2 * De * 100 * h * c)) * 1e-12            # Morse width, 1/pm
Vm = lambda r: De * 100 * h * c / eV * (1 - exp(-a_m * (r - re))) ** 2
print("figure, r pm   " + " ".join(f"{r:5d}" for r in range(100, 200, 10)))
print("figure, V harm " + " ".join(f"{Ve(r):5.2f}" for r in range(100, 200, 10)))
print("figure, Morse  " + " ".join(f"{Vm(r):5.2f}" for r in range(100, 200, 10)))
for v in range(4):
    w = sqrt(2 * (v + 0.5) * gap * eV / k) * 1e12
    print(f"figure, v={v} at {(v + 0.5) * gap:.3f} eV, turning points {re - w:.1f} {re + w:.1f} pm")

assert all(abs(ladder[n] - (n + 0.5)) < 2e-3 for n in range(5)), "ladder steps on the grid"
assert all(abs(matrix[n] - (n + 0.5)) < 1e-3 for n in range(5)), "matrix eigenvalues"
assert all(abs(shot[n] - (n + 0.5)) < 1e-6 for n in range(5)), "series shooting"
assert kill < 1e-3, "lowering operator must kill the Gaussian"
assert abs(grow - sqrt(2)) < 1e-3, "raising state 1 multiplies its size by sqrt(2)"
print("ALL CHECKS PASS")
