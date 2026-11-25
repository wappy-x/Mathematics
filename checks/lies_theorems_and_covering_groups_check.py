# Lie's theorems and covering groups -- the check behind the card.  Standard library only.
# Matrices are lists of rows of complex numbers; exp is its power series, written out.
import math

def mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]

def add(a, b, s=1.0):
    return [[x + s * y for x, y in zip(r, q)] for r, q in zip(a, b)]

def scale(a, s):
    return [[s * x for x in r] for r in a]

def eye(n):
    return [[complex(i == j) for j in range(n)] for i in range(n)]

def dag(a):                                  # conjugate transpose, the inverse in SU(2)
    return [[a[j][i].conjugate() for j in range(len(a))] for i in range(len(a))]

def gap(a, b):                               # Frobenius size of a - b
    return math.sqrt(sum(abs(x - y) ** 2 for r, q in zip(a, b) for x, y in zip(r, q)))

def expm(a):                                 # I + a + a^2/2! + ..., 60 terms
    out, term = eye(len(a)), eye(len(a))
    for k in range(1, 60):
        term = scale(mul(term, a), 1.0 / k)
        out = add(out, term)
    return out

def br(a, b):                                # the bracket [a, b] = ab - ba
    return add(mul(a, b), mul(b, a), -1.0)

def power(a, n):
    out = eye(len(a))
    for _ in range(n):
        out = mul(out, a)
    return out

def f(v, d=6):                               # fixed decimals, never a "-0"
    return f"{0.0 if abs(v) < 0.5 * 10 ** -d else v:.{d}f}"

def cx(m):
    return [[complex(x) for x in r] for r in m]

L = [cx([[0, 0, 0], [0, 0, -1], [0, 1, 0]]), cx([[0, 0, 1], [0, 0, 0], [-1, 0, 0]]),
     cx([[0, -1, 0], [1, 0, 0], [0, 0, 0]])]                 # so(3): unit roll, pitch, yaw rates
X = [[[0j, -0.5j], [-0.5j, 0j]], [[0j, -0.5 + 0j], [0.5 + 0j, 0j]],
     [[-0.5j, 0j], [0j, 0.5j]]]                                # su(2): -i/2 times the Pauli matrices
I2, I3, TAU = eye(2), eye(3), 2 * math.pi

def table(g):                                # largest miss in [g1,g2] = g3 and its cyclic turns
    return max(gap(br(g[k], g[(k + 1) % 3]), g[(k + 2) % 3]) for k in range(3))

def ad(u):                                   # the double cover: X_j-part of u X_k u^-1
    return [[(-2 * sum(mul(X[j], mul(u, mul(X[k], dag(u))))[i][i] for i in range(2))).real
             for k in range(3)] for j in range(3)]

def preimage(r):                             # one of the two U over a rotation r, via its quaternion
    t = r[0][0] + r[1][1] + r[2][2]
    c = [1 + t, 1 + 2 * r[0][0] - t, 1 + 2 * r[1][1] - t, 1 + 2 * r[2][2] - t]
    m, s = c.index(max(c)), math.sqrt(max(c)) / 2
    p = [r[2][1] - r[1][2], r[0][2] - r[2][0], r[1][0] - r[0][1]]          # pairs with w
    o = [r[0][1] + r[1][0], r[0][2] + r[2][0], r[1][2] + r[2][1]]          # xy, xz, yz
    q = {0: [s, p[0] / (4 * s), p[1] / (4 * s), p[2] / (4 * s)],
         1: [p[0] / (4 * s), s, o[0] / (4 * s), o[1] / (4 * s)],
         2: [p[1] / (4 * s), o[0] / (4 * s), s, o[2] / (4 * s)],
         3: [p[2] / (4 * s), o[1] / (4 * s), o[2] / (4 * s), s]}[m]
    return add(scale(I2, q[0]), add(scale(X[0], 2 * q[1]), add(scale(X[1], 2 * q[2]), scale(X[2], 2 * q[3]))))

def lift(steps, laps):                       # follow the tilted full-turn loop up into SU(2)
    u, worst, half = I2, 0.0, []
    for s in range(1, steps * laps + 1):
        t = s / steps
        a = expm(scale(L[0], (t % 1) * 50 * math.pi / 180))
        r = [[z.real for z in row] for row in mul(a, mul(expm(scale(L[2], TAU * (t % 1))), dag(a)))]
        v = preimage(r)
        u = v if gap(v, u) < gap(scale(v, -1), u) else scale(v, -1)        # the nearer sign
        worst = max(worst, gap(cx(ad(u)), cx(r)))
        if s % 30 == 0 and s <= steps:
            half.append((u[0][0] + u[1][1]).real / 2)
    return u, worst, half

print(f"so(3) brackets [Lx,Ly] = Lz and cyclic: {'yes' if table(L) < 1e-12 else 'no'}")
print(f"su(2) brackets [X1,X2] = X3 and cyclic: {'yes' if table(X) < 1e-12 else 'no'}")
h = 1e-4
dgap = max(gap(cx(add(ad(expm(scale(X[m], h))), ad(expm(scale(X[m], -h))), -1.0)), scale(L[m], 2 * h)) / (2 * h)
           for m in range(3))
print(f"derivative of the double cover sends X1, X2, X3 to Lx, Ly, Lz: {'yes' if dgap < 1e-8 else 'no'}")
z360, s360, s720 = expm(scale(L[2], TAU)), expm(scale(X[2], TAU)), expm(scale(X[2], 2 * TAU))
closed = [math.cos(-math.pi), math.cos(math.pi)]
print(f"exp(360 deg yaw) in SO(3) is I: {'yes' if gap(z360, I3) < 1e-9 else 'no'}")
print(f"exp(360 deg yaw) in SU(2), series: diagonal {f(s360[0][0].real)}, {f(s360[1][1].real)}")
print(f"exp(360 deg yaw) in SU(2), closed form e^(-i pi), e^(i pi): {f(closed[0])}, {f(closed[1])}")
print(f"exp(720 deg yaw) in SU(2) is I: {'yes' if gap(s720, I2) < 1e-9 else 'no'}")
u1, w1, half = lift(360, 1)
u2, w2, _ = lift(360, 2)
print(f"lift of the tilted 360 deg loop, 360 steps: ends at -I: {'yes' if gap(u1, scale(I2, -1)) < 1e-9 else 'no'}")
print(f"lift of the same loop run twice, 720 steps: ends at +I: {'yes' if gap(u2, I2) < 1e-9 else 'no'}")
print(f"every lifted step lies over its rotation: {'yes' if max(w1, w2) < 1e-9 else 'no'}")
ang = list(range(30, 361, 30))
print("chart, turn angle in deg: 0, " + ", ".join(str(a) for a in ang))
print("chart, half trace of the lift in SU(2): 1.000, " + ", ".join(f(v, 3) for v in half))
print("chart, (trace - 1)/2 of the turn in SO(3): 1.000, " + ", ".join(f(math.cos(a * math.pi / 180), 3) for a in ang))
print(f"spin-1/2 guess Phi(exp(theta Lz)) = exp(theta X3): theta 0 gives +I, theta 360 deg gives "
      f"{'-I' if gap(s360, scale(I2, -1)) < 1e-9 else '?'}, gap {f(gap(I2, s360))}, same rotation I")
A, B = scale(L[1], 0.4), scale(L[2], 1.2)
prod = {n: gap(power(mul(expm(scale(A, 1 / n)), expm(scale(B, 1 / n))), n), expm(add(A, B))) for n in (1, 10, 100)}
print(f"Lie product formula, pitch 0.4, yaw 1.2: gap N = 1 {f(prod[1])}, N = 10 {f(prod[10])}, N = 100 {f(prod[100])}")
comm = {}
for n in (10, 100):
    a, b = expm(scale(A, 1 / n)), expm(scale(B, 1 / n))
    comm[n] = gap(power(mul(mul(a, b), mul(dag(a), dag(b))), n * n), expm(br(A, B)))
print(f"commutator formula, same rates: gap N = 10 {f(comm[10])}, N = 100 {f(comm[100])}")
R2 = math.sqrt(2)
def miss(n, slope):                          # second motor's distance from 0 when the first is back at 0
    return abs(n * slope - round(n * slope))
best, rec = 1.0, []
for n in range(1, 1001):
    if miss(n, R2) < best - 1e-12:
        best = miss(n, R2)
        rec.append(n)
pell = [1, 2]
while 2 * pell[-1] + pell[-2] <= 1000:
    pell.append(2 * pell[-1] + pell[-2])
print(f"slope sqrt 2 on the motor torus, record returns by search, n <= 1000: {rec}")
print(f"the same list from the Pell rule q -> 2q + q_prev: {'yes' if rec == pell else 'no'}")
print("miss at each record, in turns: " + ", ".join(f(miss(n, R2)) for n in rec))
print("miss at each record, in degrees: " + ", ".join(f(360 * miss(n, R2), 3) for n in rec))
print(f"n times miss at n = 985: {f(985 * miss(985, R2))}; 1/(2 sqrt 2) = {f(1 / (2 * R2))}")
print(f"slope 3/2 closes exactly at n = 2: {'yes' if miss(2, 1.5) == 0 else 'no'}")
assert table(L) < 1e-12 and table(X) < 1e-12                      # one bracket table, two algebras
assert dgap < 1e-8                                                # the double cover's derivative matches them
assert gap(s360, scale(I2, -1)) < 1e-9 and abs(closed[0] - s360[0][0].real) < 1e-9 and gap(z360, I3) < 1e-9
assert gap(u1, scale(I2, -1)) < 1e-9 and gap(u2, I2) < 1e-9        # lifting road, from rotations alone
assert all(abs(v - math.cos(a * math.pi / 360)) < 1e-9 for v, a in zip(half, ang))
assert 8 < prod[10] / prod[100] < 12 and 8 < comm[10] / comm[100] < 12   # errors shrink like 1/n
assert rec == pell and abs(985 * miss(985, R2) - 1 / (2 * R2)) < 1e-3
print("ALL CHECKS PASS")
