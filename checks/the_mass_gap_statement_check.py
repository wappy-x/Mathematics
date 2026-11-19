# Mass gap: the Yang-Mills prize problem stated precisely -- the check behind the card.
# Nothing is imported except math.  Energies in MeV, lengths in fm (1 fm = 1e-15 m).
# Part 1: what a gap means for the strong force (range of a force, a photon in a box).
# Part 2: a toy with a provable gap, one plaquette of SU(2) lattice gauge theory.
# Roads to the toy's gap: its matrix in the spin-j basis, a finite-difference grid
# at two step sizes, and the decay of a correlation in imaginary time (no eigensolver).
import math
HBARC = 6.62607015e-34 * 299792458 / (2 * math.pi) / 1.602176634e-13 * 1e15   # MeV fm, exact SI
M_PI, M_GB = 139.57039, 1730.0          # charged pion (PDG 2024); lightest glueball (lattice, 1999)
print(f"hbar c = {HBARC:.6f} MeV fm")
print(f"inputs: charged pion {M_PI:.5f} MeV, lightest glueball {M_GB:.0f} MeV")
r_pi, r_gb = HBARC / M_PI, HBARC / M_GB
print(f"range hbar c / m: pion {r_pi:.4f} fm, lightest glueball {r_gb:.4f} fm, photon infinite")
print(f"glueball correlation left at 1 fm: exp(-1/{r_gb:.4f}) = {math.exp(-1 / r_gb):.6f}")
print(f"potential at 1 fm over potential at 2 fm: Coulomb (massless) {2.0:.2f}, Yukawa with pion {2 * math.exp(1 / r_pi):.2f}")
mu, h = 1 / r_pi, 1e-3                  # road check: exp(-mu r)/r solves -phi'' - (2/r) phi' + mu^2 phi = 0
yuk = lambda r: math.exp(-mu * r) / r
res = [-(yuk(r + h) - 2 * yuk(r) + yuk(r - h)) / h**2 - (2 / r) * (yuk(r + h) - yuk(r - h)) / (2 * h) + mu**2 * yuk(r) for r in (0.5, 1.0, 2.0)]
print("Yukawa field equation residual at 0.5, 1, 2 fm: " + " ".join(f"{abs(x):.6f}" for x in res))
box = [1, 2, 4, 8, 16, 32]
pho = [2 * math.pi * HBARC / L for L in box]
print("lowest photon energy in a box of side L fm, 2 pi hbar c / L (MeV): " + " ".join(f"{e:.2f}" for e in pho))
print(f"  L = 10 fm: {2 * math.pi * HBARC / 10:.2f} MeV; L = 1000 fm: {2 * math.pi * HBARC / 1000:.2f} MeV")
print("chart, photon: " + ", ".join(f"{e:.0f}" for e in pho) + f"; gapped theory: {M_GB:.0f} at every L")
print(f"one massless quantum of a 1 km wave, 2 pi hbar c / lambda: {2 * math.pi * HBARC / 1e18 * 1e15:.4f} neV")

def below(d, e, x):                     # how many eigenvalues of a tridiagonal matrix lie below x
    c, q = 0, 1.0
    for i in range(len(d)):
        q = d[i] - x - (e[i - 1] ** 2 / q if i else 0.0)
        if q == 0.0: q = 1e-300
        c += q < 0
    return c
def eig(d, e, k):                       # k-th eigenvalue by bisection (Sturm count)
    lo, hi = min(d) - 4 * max(map(abs, e)), max(d) + 4 * max(map(abs, e))
    for _ in range(200):
        m = (lo + hi) / 2
        lo, hi = (lo, m) if below(d, e, m) > k else (m, hi)
    return (lo + hi) / 2
def spin_basis(g2, N):                  # u_n = sin(n theta), n = 2j + 1; H = (g2/2) C + (4/g2)(1 - cos theta)
    return [g2 / 8 * (n * n - 1) + 4 / g2 for n in range(1, N + 1)], [-2 / g2] * (N - 1)
def grid(g2, M):                        # same H on theta in (0, pi), u = 0 at both ends, M intervals
    s = math.pi / M
    return [g2 / 8 * (2 / s**2 - 1) + 4 / g2 * (1 - math.cos(k * s)) for k in range(1, M)], [-g2 / 8 / s**2] * (M - 2)
print("one SU(2) plaquette, lattice units: g^2, E0, E1, gap, strong-coupling guess 3 g^2 / 8")
gap = {}
for g2 in (0.25, 1.0, 4.0, 16.0):
    d, e = spin_basis(g2, 30)
    E0, E1 = eig(d, e, 0), eig(d, e, 1)
    gap[g2] = E1 - E0
    print(f"  {g2:5.2f} {E0:.6f} {E1:.6f} {gap[g2]:.6f} {3 * g2 / 8:.6f}")
fd = {}
for M in (200, 400):
    d, e = grid(1.0, M)
    fd[M] = eig(d, e, 1) - eig(d, e, 0)
    print(f"  grid, {M} steps, g^2 = 1: gap {fd[M]:.6f}, off by {gap[1.0] - fd[M]:.6f}")
ratio = (gap[1.0] - fd[200]) / (gap[1.0] - fd[400])
print(f"  grid error ratio, 200 over 400 steps: {ratio:.2f} (second order predicts 4)")

d, e = spin_basis(1.0, 30)              # road three: imaginary time, dv/dtau = -(H - shift) v
N = len(d)
def Hv(v, s):
    return [(d[i] - s) * v[i] + (e[i - 1] * v[i - 1] if i else 0.0) + (e[i] * v[i + 1] if i < N - 1 else 0.0) for i in range(N)]
def step(v, s, dt):
    k1 = Hv(v, s); k2 = Hv([v[i] - dt / 2 * k1[i] for i in range(N)], s)
    k3 = Hv([v[i] - dt / 2 * k2[i] for i in range(N)], s); k4 = Hv([v[i] - dt * k3[i] for i in range(N)], s)
    return [v[i] - dt / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in range(N)]
dot = lambda a, b: sum(x * y for x, y in zip(a, b))
v = [1.0] + [0.0] * (N - 1)
for _ in range(3000):                   # 30 units of imaginary time cools any start to the vacuum
    v = step(v, 0.0, 0.01); n = math.sqrt(dot(v, v)); v = [x / n for x in v]
E0 = dot(v, Hv(v, 0.0))
O = [(v[i - 1] if i else 0.0) + (v[i + 1] if i < N - 1 else 0.0) for i in range(N)]   # Tr U = 2 cos theta
avg = dot(v, O)
w = [O[i] - avg * v[i] for i in range(N)]   # Tr U with its vacuum average removed
print(f"imaginary time, g^2 = 1: vacuum energy {E0:.6f}, vacuum average of Tr U {avg:.6f}")
C, u = [], w[:]
for t in range(9):
    C.append(dot(w, u))
    for _ in range(100): u = step(u, E0, 0.01)
meff = [math.log(C[t] / C[t + 1]) for t in range(8)]
print("  tau, C(tau), effective mass ln(C(tau)/C(tau+1))")
for t in range(8):
    print(f"  {t} {C[t]:.10f} {meff[t]:.6f}")
print(f"  bound C(tau) <= C(0) exp(-gap tau) holds at every tau: {'yes' if all(C[t] <= C[0] * math.exp(-gap[1.0] * t) * (1 + 1e-9) for t in range(9)) else 'no'}")
print("toy continuum limit: Delta = (gap in lattice units) hbar c / a, against the required 1730 MeV")
for a in (0.1, 0.05):
    print(f"  a = {a:.2f} fm: toy {gap[0.25] * HBARC / a:.0f} MeV; required gap in lattice units {M_GB * a / HBARC:.4f}")
print(f"what breaks: first-step effective mass {meff[0]:.6f} against gap {gap[1.0]:.6f}, {100 * (meff[0] / gap[1.0] - 1):.1f}% high")

assert abs(HBARC - 197.3269804) < 1e-6                          # CODATA 2022 value of hbar c
assert max(abs(x) for x in res) < 1e-3 * mu**2 * yuk(2.0)       # exp(-mu r)/r solves the static field equation
assert abs(gap[1.0] - fd[400]) < 1e-3 and 3.5 < ratio < 4.5     # spin basis and grid agree, at second order
assert abs(meff[7] - gap[1.0]) < 1e-4 and meff[0] > meff[3] > meff[7]   # correlation decay gives the gap
assert abs(gap[16.0] - 6.0) < 0.01 and abs(gap[0.25] - 2.0) < 0.05     # strong and weak coupling limits
assert all(g > 0 for g in gap.values())                          # the toy has a gap at every coupling
assert all(C[t] <= C[0] * math.exp(-gap[1.0] * t) * (1 + 1e-9) for t in range(9))
print("ALL CHECKS PASS")
