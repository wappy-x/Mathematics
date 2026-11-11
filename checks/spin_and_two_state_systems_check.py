# Spin one-half -- the check behind the card.  Standard library only.
# Silver atoms through Stern-Gerlach magnets.  The chance of "up" along a
# tilted magnet comes three ways: the half-angle formula, the eigenvector of
# a 2x2 matrix found from its quadratic, and the column (1, 0) turned 60 deg by
# the power series of the matrix exponential.  The turning in time comes three
# ways: the closed form, RK4 on Schrodinger's equation, and the same series.
from math import cos, sin, pi, sqrt

h = 6.62607015e-34; hbar = h / (2 * pi)   # Planck constant, exact in SI, J s
muB = 9.2740100657e-24                    # Bohr magneton, J/T (CODATA 2022)
g = 2.00231930436092                      # electron g factor, size (CODATA 2022)
m_Ag = 107.8682 * 1.66053906892e-27       # one silver atom, kg (IUPAC, CODATA)
GAM_E = 28024.9513861                     # electron gyromagnetic ratio / 2 pi, MHz/T (CODATA 2022)

I2 = ((1, 0), (0, 1))
SX = ((0, 1), (1, 0)); SY = ((0, -1j), (1j, 0)); SZ = ((1, 0), (0, -1))
def mul(A, B): return tuple(tuple(sum(A[r][k] * B[k][c] for k in range(2)) for c in range(2)) for r in range(2))
def comb(a, A, b, B): return tuple(tuple(a * A[r][c] + b * B[r][c] for c in range(2)) for r in range(2))
def gap(A, B): return max(abs(A[r][c] - B[r][c]) for r in range(2) for c in range(2))
def sig(n): return comb(1, comb(n[0], SX, n[1], SY), n[2], SZ)          # n . sigma
def app(A, v): return (A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1])
def prob(u, v): return abs(u[0].conjugate() * v[0] + u[1].conjugate() * v[1]) ** 2
def axis(deg): t = deg * pi / 180; return (sin(t), 0.0, cos(t))      # tilted from z towards x
def U(theta, n): return comb(cos(theta / 2), I2, -1j * sin(theta / 2), sig(n))   # closed form
def U_series(theta, n):                                   # road 3: sum of (-i theta n.s / 2)^k / k!
    X = comb(-0.5j * theta, sig(n), 0, I2); term, tot = I2, I2
    for k in range(1, 40): term = comb(1 / k, mul(term, X), 0, I2); tot = comb(1, tot, 1, term)
    return tot

def up_vector(M):        # road 2: eigenvector for the + root of lambda^2 = p^2 + |q|^2
    p, q = M[0][0].real, M[0][1]
    lam = sqrt(p * p + abs(q) ** 2)
    if abs(q) < 1e-15: return (1, 0) if p > 0 else (0, 1)
    v = (q, lam - p); s = sqrt(abs(v[0]) ** 2 + abs(v[1]) ** 2)
    return (v[0] / s, v[1] / s)

class SplitMix64:        # a small seeded generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

up_z, up_x = (1, 0), (1 / sqrt(2), 1 / sqrt(2))
assert gap(mul(SX, SY), comb(1j, SZ, 0, I2)) < 1e-15                        # sx sy = i sz
assert max(gap(mul(S, S), I2) for S in (SX, SY, SZ, sig(axis(60)))) < 1e-15  # each squares to I
print("sigma_x sigma_y = i sigma_z, and every n.sigma squares to I: yes")

# ---- the split: the force, the drift through the magnet, the gap at its exit ----
dBdz, L, v = 1000.0, 0.035, 500.0           # T/m, m, m/s
F = 0.5 * g * muB * dBdz; a = F / m_Ag; tm = L / v
z1 = 0.5 * a * tm * tm
print(f"moment {0.5 * g * muB * 1e24:.4f} x 10^-24 J/T, atom {m_Ag * 1e25:.4f} x 10^-25 kg, hbar {hbar * 1e34:.9f} x 10^-34 J s")
print(f"force on one atom      {F * 1e21:.4f} x 10^-21 N")
print(f"acceleration           {a:.1f} m/s^2, time in magnet {tm * 1e6:.1f} us")
print(f"each beam moves        {z1 * 1e3:.4f} mm, gap between spots {2 * z1 * 1e3:.4f} mm")
zs, vs, K = 0.0, 0.0, 1000                # road 2 for the drift: step the flight (half kick, drift, half kick)
for _ in range(K): vs += a * tm / K / 2; zs += vs * tm / K; vs += a * tm / K / 2
assert abs(zs - z1) < 1e-9 * z1

# ---- a second magnet tilted 60 degrees: three roads to P(up) ----
P_formula = cos(60 * pi / 360) ** 2
P_eig = prob(up_vector(sig(axis(60))), up_z)
P_turn = abs(app(U_series(pi / 3, (0, 1, 0)), up_z)[0]) ** 2   # road 3: turn (1, 0) by 60 deg about y
rng, N = SplitMix64(2026), 100000         # not a road: atoms drawn with that chance show a real count's scatter
hits = sum(1 for _ in range(N) if rng.next() < P_eig)
print(f"P(up) tilt 60 deg      formula {P_formula:.6f}  eigenvector {P_eig:.6f}  turned {P_turn:.6f}  simulated {hits / N:.5f}")
print(f"of 10000 atoms         {10000 * P_formula:.0f} up, {10000 * (1 - P_formula):.0f} down")
print(f"overlap at 60 deg      {sqrt(P_eig):.6f}, axis (n_x, n_z) = ({axis(60)[0]:.6f}, {axis(60)[2]:.6f})")
assert abs(P_formula - P_eig) < 1e-12
assert abs(P_formula - P_turn) < 1e-12
assert abs(hits - N * P_formula) < 4 * sqrt(N * P_formula * (1 - P_formula))
for d in (0, 90, 120, 180):
    print(f"P(up) tilt {d:3d} deg     {prob(up_vector(sig(axis(d))), up_z):.6f}")

# ---- z, then x, keep +x, then z again: the first answer is erased ----
p1 = prob(up_vector(sig(axis(90))), up_z); p2 = prob(up_z, up_vector(sig(axis(90))))
print(f"z -> x -> z            10000 -> {10000 * p1:.0f} kept -> {10000 * p1 * p2:.0f} up, {10000 * p1 * (1 - p2):.0f} down")
assert abs(p2 - 0.5) < 1e-12

# ---- turning in time: field B along z, energy matrix H = (g muB B / 2) sigma_z ----
B = 0.5
w = g * muB * B / hbar                                    # rad/s
print(f"Larmor rate at {B:.3f} T {w / 1e9:.4f} x 10^9 rad/s; f = w/2pi = {w / 2 / pi / 1e9:.4f} GHz, period {2 * pi / w * 1e12:.4f} ps")
assert abs(w / (2 * pi * B) / 1e6 - GAM_E) < 1e-3          # against CODATA's gamma_e / 2 pi
print(f"turns in the magnet    {w / 2 / pi * tm:.0f};  beam moves in 72 ps  {v * 72e-12 * 1e9:.1f} nm")
psi, dt, n_steps = up_x, 0.008, 9000                      # RK4 in picoseconds, 72 ps
f = lambda y: app(comb(-0.5j * w * 1e-12, SZ, 0, I2), y)
row_cf, row_rk, row_z, tilt = [], [], [], up_vector(sig(axis(60)))
for k in range(n_steps + 1):
    if k % 1000 == 0:
        t = k * dt * 1e-12
        row_cf.append(cos(w * t / 2) ** 2); row_rk.append(prob(up_x, psi))
        assert gap(U(w * t, (0, 0, 1)), U_series(w * t, (0, 0, 1))) < 1e-12
        row_z.append(prob(up_z, app(U(w * t, (0, 0, 1)), tilt)))      # start tilted 60 deg
    k1 = f(psi); k2 = f(tuple(p + dt / 2 * q for p, q in zip(psi, k1)))
    k3 = f(tuple(p + dt / 2 * q for p, q in zip(psi, k2))); k4 = f(tuple(p + dt * q for p, q in zip(psi, k3)))
    psi = tuple(p + dt / 6 * (q1 + 2 * q2 + 2 * q3 + q4) for p, q1, q2, q3, q4 in zip(psi, k1, k2, k3, k4))
assert max(abs(x - y) for x, y in zip(row_cf, row_rk)) < 1e-8
assert max(abs(x - P_formula) for x in row_z) < 1e-12                    # z-chance never moves
print("chart, t (ps)          " + " ".join(f"{8 * i:5d}" for i in range(10)))
print("chart, phase wt (deg)  " + " ".join(f"{w * 8e-12 * i * 180 / pi:5.0f}" for i in range(10)))
print("chart, P(+x) formula   " + " ".join(f"{x:5.3f}" for x in row_cf))
print("chart, P(+x) RK4       " + " ".join(f"{x:5.3f}" for x in row_rk))
print("chart, P(+z) from 60   " + " ".join(f"{x:5.3f}" for x in row_z))
print(f"one full turn          U(2 pi) = {U(2 * pi, (0, 0, 1))[0][0].real:.6f} I, U(4 pi) = {U(4 * pi, (0, 0, 1))[0][0].real:.6f} I")
assert gap(U_series(2 * pi, axis(60)), comb(-1, I2, 0, I2)) < 1e-12

# ---- what breaks, and where the numbers are used ----
f_true = w / 2 / pi
print(f"wrong: cos^2(60 deg)   {cos(60 * pi / 180) ** 2:.6f}   (right {P_formula:.6f})")
print(f"wrong: amplitudes      {cos(pi / 6) + sin(pi / 6):.6f} total chance")
print(f"wrong: g left out      {muB * B / h / 1e9:.4f} GHz   (right {f_true / 1e9:.4f})")
print(f"wrong: z remembered    {10000 * p1:.0f} up, 0 down   (right {10000 * p1 * p2:.0f}, {10000 * p1 * (1 - p2):.0f})")
fE = g * muB * 50e-6 / h                  # weak field: electron and nucleus lock into spin 1, rate halves
print(f"Earth 50 uT, electron  {fE / 1e6:.4f} MHz, silver atom weak field ~{fE / 2e6:.4f} MHz")
print(f"ESR at 9.5 GHz needs   {h * 9.5e9 / (g * muB):.4f} T;  at 0.339 T  {g * muB * 0.339 / h / 1e9:.4f} GHz")
print(f"MRI proton at 1.5 T    {42.577478461 * 1.5:.4f} MHz")
print("ALL CHECKS PASS")
