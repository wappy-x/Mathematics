# Two particles -- the check behind the card.  Standard library only.
# Two spin-one-half electrons.  Four-entry states come from the Kronecker
# product.  The singlet fails the product test three ways (the test number,
# the reduced state, the best product fit); spin addition comes from the 4x4
# matrix S^2; the exchange rule is run on two electrons in a 1 nm box (formula
# against a grid); CHSH comes from 4x4 matrices, from -cos(a - b), and from the
# largest eigenvalue of the CHSH matrix, against every local strategy.
from math import cos, sin, pi, sqrt

def kron(A, B):
    p, q = len(B), len(B[0])
    return [[A[i // p][j // q] * B[i % p][j % q] for j in range(len(A[0]) * q)] for i in range(len(A) * p)]
def lin(a, A, b, B): return [[a * x + b * y for x, y in zip(r, s)] for r, s in zip(A, B)]
def mv(M, v): return [sum(m * x for m, x in zip(row, v)) for row in M]
def dot(u, v): return sum(x * y for x, y in zip(u, v))
def gap(A, B): return max(abs(x - y) for r, s in zip(A, B) for x, y in zip(r, s))
def eye(n): return [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
I2, SX, SZ = eye(2), [[0, 1], [1, 0]], [[1, 0], [0, -1]]
J = [[0, 1], [-1, 0]]                  # sigma_y = -i J, so sigma_y (x) sigma_y = -J (x) J: all real
def sig(deg): t = deg * pi / 180; return lin(cos(t), SZ, sin(t), SX)   # axis tilted deg from z towards x
def test(c): return c[0] * c[3] - c[1] * c[2]                           # c00 c11 - c01 c10
def z(x): return 0.0 if abs(x) < 5e-13 else x                           # print rounding noise as 0

class SplitMix64:                      # a small seeded generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

# ---- 1. the product test: entries ordered (up-up, up-down, down-up, down-down) ----
r = 1 / sqrt(2)
singlet, t_plus, t_zero, t_minus = [0, r, -r, 0], [1, 0, 0, 0], [0, r, r, 0], [0, 0, 0, 1]
prod = [x[0] for x in kron([[1], [0]], [[cos(pi / 6)], [sin(pi / 6)]])]  # A up along z, B 60 deg from z
print(f"product state  ({prod[0]:.4f}, {prod[1]:.4f}, {prod[2]:.4f}, {prod[3]:.4f})  test {test(prod):.4f}")
print(f"singlet        ({singlet[0]:.4f}, {singlet[1]:.4f}, {singlet[2]:.4f}, {singlet[3]:.4f})  test {test(singlet):.4f}")
assert abs(test(prod)) < 1e-15 and abs(test(singlet) - 0.5) < 1e-15
C = [[singlet[0], singlet[1]], [singlet[2], singlet[3]]]           # road 2: electron 1's own state, C C^T
rho = [[dot(C[i], C[j]) for j in range(2)] for i in range(2)]
purity = sum(rho[i][j] ** 2 for i in range(2) for j in range(2))
print(f"electron 1 alone: [[{rho[0][0]:.4f}, {rho[0][1]:.4f}], [{rho[1][0]:.4f}, {rho[1][1]:.4f}]], purity {purity:.4f} = 1 - 2 test^2 = {1 - 2 * test(singlet) ** 2:.4f}")
assert abs(purity - (1 - 2 * test(singlet) ** 2)) < 1e-12 and gap(rho, lin(0.5, I2, 0, I2)) < 1e-15
best = 0.0                              # road 3: closest product state, scanned every degree
for a in range(180):
    for b in range(180):
        u = (cos(a * pi / 180), sin(a * pi / 180)); v = (cos(b * pi / 180), sin(b * pi / 180))
        best = max(best, dot([u[0] * v[0], u[0] * v[1], u[1] * v[0], u[1] * v[1]], singlet) ** 2)
print(f"best product overlap^2 {best:.4f}  formula (1 + sqrt(1 - 4 test^2))/2 = {(1 + sqrt(1 - 4 * test(singlet) ** 2)) / 2:.4f}")
assert abs(best - 0.5) < 1e-12

# ---- 2. adding two spins: S^2 = (3/2) I + (1/2) sum_k sigma_k (x) sigma_k, in units of hbar^2 ----
SS = lin(1, lin(1, kron(SX, SX), -1, kron(J, J)), 1, kron(SZ, SZ))
S2 = lin(1.5, eye(4), 0.5, SS)
Sz = lin(0.5, kron(SZ, I2), 0.5, kron(I2, SZ))
for name, v, s in (("triplet up-up    ", t_plus, 1), ("triplet (ud+du)  ", t_zero, 1), ("triplet down-down", t_minus, 1), ("singlet (ud-du)  ", singlet, 0)):
    s2, sz = dot(v, mv(S2, v)), dot(v, mv(Sz, v))
    assert max(abs(x - s * (s + 1) * y) for x, y in zip(mv(S2, v), v)) < 1e-12   # eigenvector, eigenvalue s(s+1)
    print(f"{name}  S^2 = {s2:.4f} hbar^2  s = {(sqrt(1 + 4 * s2) - 1) / 2:.0f}  S_z = {z(sz):+.0f} hbar")
swap = [[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]
assert gap(lin(0.5, eye(4), 0.5, SS), swap) < 1e-15                         # swap = (I + sum sigma.sigma)/2
print(f"swap: triplet {dot(t_zero, mv(swap, t_zero)):+.0f}, singlet {dot(singlet, mv(swap, singlet)):+.0f};  trace S^2 = {sum(S2[i][i] for i in range(4)):.0f} = 3 x 2 + 0")
R = [[cos(pi / 6), -sin(pi / 6)], [sin(pi / 6), cos(pi / 6)]]               # turn both spins 60 deg about y
print(f"singlet after turning both spins 60 deg: overlap {dot(singlet, mv(kron(R, R), singlet)):.4f}")
assert abs(dot(singlet, mv(kron(R, R), singlet)) - 1) < 1e-12

# ---- 3. identical electrons in a 1 nm box ----
h, me, eV, eps0 = 6.62607015e-34, 9.1093837139e-31, 1.602176634e-19, 8.8541878188e-12   # CODATA 2022
L = 1e-9
E1 = h * h / (8 * me * L * L) / eV
print(f"E1 = h^2/(8 m L^2) = {E1:.6f} eV;  singlet, both n=1: {2 * E1:.6f} eV;  triplet, n=1 and 2: {5 * E1:.6f} eV;  gap {3 * E1:.6f} eV")
N = 200; xs = [(k + 0.5) / N for k in range(N)]                                # box in units of L
psi = lambda n, x: sqrt(2) * sin(n * pi * x)
def anti_norm(n1, n2):                  # grid norm^2 of psi_n1(x1) psi_n2(x2) - psi_n2(x1) psi_n1(x2), over 2
    return sum((psi(n1, x) * psi(n2, y) - psi(n2, x) * psi(n1, y)) ** 2 for x in xs for y in xs) / (2 * N * N)
pairs = sorted(((n1 * n1 + n2 * n2, n1, n2) for n1 in range(1, 4) for n2 in range(n1, 4)))
low = next(p for p in pairs if anti_norm(p[1], p[2]) > 0.5)
print(f"antisymmetric norm^2: (1,1) {anti_norm(1, 1):.4f}, (1,2) {anti_norm(1, 2):.4f};  lowest allowed pair ({low[1]},{low[2]}) at {low[0] * E1:.6f} eV")
assert (low[1], low[2]) == (1, 2)
a12 = 4 / (3 * pi)                       # overlap of psi_1 and psi_2 over the left half
same_cf = {+1: 0.5 + 2 * a12 ** 2, -1: 0.5 - 2 * a12 ** 2}
for sgn, name in ((+1, "symmetric (singlet)"), (-1, "antisymmetric (triplet)")):
    grid = sum((psi(1, x) * psi(2, y) + sgn * psi(2, x) * psi(1, y)) ** 2 / 2 for x in xs for y in xs if (x < 0.5) == (y < 0.5)) / (N * N)
    print(f"P(same half) {name}  formula {same_cf[sgn]:.4f}  grid {grid:.4f}")
    assert abs(grid - same_cf[sgn]) < 1e-4
print(f"P(same half) told-apart electrons  {0.5:.4f}")

# ---- 4. CHSH: S = E(a,b) + E(a,b') + E(a',b) - E(a',b') ----
a, a2, b, b2 = 0.0, 90.0, -135.0, 135.0
def E(state, x, y): return dot(state, mv(kron(sig(x), sig(y)), state))
pairs4 = ((a, b, 1), (a, b2, 1), (a2, b, 1), (a2, b2, -1))
for x, y, _ in pairs4:
    print(f"E({x:4.0f},{y:5.0f})  matrices {E(singlet, x, y):+.4f}  -cos(a-b) {-cos((x - y) * pi / 180):+.4f}")
    assert abs(E(singlet, x, y) + cos((x - y) * pi / 180)) < 1e-12
S_q = sum(s * E(singlet, x, y) for x, y, s in pairs4)
W = [[0.0] * 4 for _ in range(4)]       # road 3: the CHSH matrix; its largest eigenvalue by power iteration on W^2
for x, y, s in pairs4: W = lin(1, W, s, kron(sig(x), sig(y)))
v = [1.0, 0.3, -0.7, 0.2]
for _ in range(200): v = mv(W, mv(W, v)); n = sqrt(dot(v, v)); v = [t / n for t in v]
lam = sqrt(dot(v, mv(W, mv(W, v))))
print(f"CHSH singlet {S_q:.6f};  2 sqrt 2 = {2 * sqrt(2):.6f};  largest eigenvalue of the CHSH matrix {lam:.6f}")
assert abs(S_q - 2 * sqrt(2)) < 1e-12 and abs(lam - 2 * sqrt(2)) < 1e-9
local = [A0 * B0 + A0 * B1 + A1 * B0 - A1 * B1 for A0 in (1, -1) for A1 in (1, -1) for B0 in (1, -1) for B1 in (1, -1)]
print(f"all 16 local strategies: S in {sorted(set(local))}, largest {max(local)}")
assert max(abs(t) for t in local) == 2
def E_lhv(x, y): d = abs((x - y + 180) % 360 - 180); return -1 + 2 * d / 180   # hidden direction, sign readings
rng, M = SplitMix64(2026), 100000
S_lhv = S_sim_l = S_sim_q = 0.0
for x, y, s in pairs4:
    S_lhv += s * E_lhv(x, y); tot_l = tot_q = 0
    for _ in range(M):
        lmb = 360 * rng.next()
        A = 1 if cos((x - lmb) * pi / 180) >= 0 else -1; B = -1 if cos((y - lmb) * pi / 180) >= 0 else 1
        tot_l += A * B
        tot_q += 1 if rng.next() < (1 + E(singlet, x, y)) / 2 else -1         # +1: same readings
    S_sim_l += s * tot_l / M; S_sim_q += s * tot_q / M
print(f"hidden-direction model S {S_lhv:.4f}, simulated {S_sim_l:.4f};  quantum simulated {S_sim_q:.4f}  ({M} pairs per setting)")
assert abs(S_sim_l - S_lhv) < 4 * sqrt(4 * 0.75 / M) and abs(S_sim_q - S_q) < 4 * sqrt(4 * 0.5 / M)
th = [22.5 * k for k in range(9)]
print("chart, angle (deg)   " + " ".join(f"{t:6.1f}" for t in th))
print("chart, quantum E     " + " ".join(f"{z(E(singlet, 0, t)):+.3f}" for t in th))
print("chart, hidden-dir E  " + " ".join(f"{E_lhv(0, t):+.3f}" for t in th))

# ---- what breaks ----
print(f"wrong: two separate 50/50 spins  P(both up along z) {rho[0][0] * rho[0][0]:.4f}   (singlet {singlet[0] ** 2:.4f})")
swapped = ((a, b2, 1), (a, b, 1), (a2, b2, 1), (a2, b, -1))
print(f"wrong: plus sign (ud+du)  test {test(t_zero):.4f}, CHSH same directions {z(sum(s * E(t_zero, x, y) for x, y, s in pairs4)):.4f}, B's two swapped {sum(s * E(t_zero, x, y) for x, y, s in swapped):.4f}")
print(f"wrong: same-spin pair both in n=1  {2 * E1:.6f} eV   (allowed lowest {5 * E1:.6f} eV)")
print(f"outside the model: repulsion at 1 nm {eV / (4 * pi * eps0 * L):.6f} eV  vs  Pauli gap {3 * E1:.6f} eV")
print("ALL CHECKS PASS")
