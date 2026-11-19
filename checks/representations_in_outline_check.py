# Representation in outline -- the check behind the card.  Standard library
# only.  The snowflake's twelve moves (wing 05's 2-by-2 turns and flips) act
# on its six arms: each move shuffles a list of six arm lengths, and that
# shuffle is a 6-by-6 matrix.  The list then splits into pieces no move mixes.
from math import cos, sin, radians, sqrt

ARM = [30 + 60 * i for i in range(6)]                 # arm i points this way, degrees
TIP = [(cos(radians(a)), sin(radians(a))) for a in ARM]
X = [1.12, 0.96, 1.08, 0.92, 1.04, 0.88]              # one crystal's arm lengths, mm

def turn(t):
    c, s = cos(radians(t)), sin(radians(t))
    return [[c, -s], [s, c]]

def flip(p):
    c, s = cos(radians(2 * p)), sin(radians(2 * p))
    return [[c, s], [s, -c]]

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))]
            for i in range(len(A))]

def close(A, B, tol=1e-9):
    return all(abs(a - b) < tol for ra, rb in zip(A, B) for a, b in zip(ra, rb))

def f(v):                                             # 4 decimals, never "-0.0000"
    return f"{0.0 if abs(v) < 5e-5 else v:.4f}"

def fl(vs):
    return "[" + ", ".join(f(v) for v in vs) + "]"

NAME = [f"R{60 * k}" for k in range(6)] + [f"F{30 * m}" for m in range(6)]
M2 = [turn(60 * k) for k in range(6)] + [flip(30 * m) for m in range(6)]
M2X2 = [turn(120 * k) for k in range(6)] + [flip(60 * m) for m in range(6)]  # angles doubled

def lands(M, i):                                      # which tip does arm i's tip land on?
    x, y = TIP[i]
    u, v = M[0][0] * x + M[0][1] * y, M[1][0] * x + M[1][1] * y
    return min(range(6), key=lambda j: (TIP[j][0] - u) ** 2 + (TIP[j][1] - v) ** 2)

PERM = [[lands(M, i) for i in range(6)] for M in M2]
RHO = [[[1.0 if p[j] == i else 0.0 for j in range(6)] for i in range(6)] for p in PERM]
WRONG = [[[1.0 if p[i] == j else 0.0 for j in range(6)] for i in range(6)] for p in PERM]
which = lambda M: next(k for k in range(12) if close(M2[k], M))

good = bad = 0
for g in range(12):
    for h in range(12):
        gh = which(mul(M2[g], M2[h]))                 # the group's own product, in 2x2
        good += close(RHO[gh], mul(RHO[g], RHO[h]))
        bad += not close(WRONG[gh], mul(WRONG[g], WRONG[h]))
chi = [sum(R[i][i] for i in range(6)) for R in RHO]   # trace = arms left in place
print(f"moves: {' '.join(NAME)}")
print(f"arm i goes to, under R60: {PERM[1]}; under F30: {PERM[7]}; under F0: {PERM[6]}")
print(f"pairs (g, h) with rho(gh) = rho(g) rho(h): {good} of 144")
print(f"trace of rho(g), arms left in place: {[int(c) for c in chi]}")
print(f"copies of the all-equal piece, sum of traces / 12: {f(sum(chi) / 12)}")
print(f"pieces counted by traces, sum of squares {int(sum(c * c for c in chi))} / 12 = "
      f"{f(sum(c * c for c in chi) / 12)}")

# Road 1: projectors built by averaging over the group, weighted by a trace.
alt = [1.0 if sorted(p[i] for i in (0, 2, 4)) == [0, 2, 4] else -1.0 for p in PERM]
char = {"all equal": ([1.0] * 12, 1), "alternating": (alt, 1),
        "tilt (once round)": ([M[0][0] + M[1][1] for M in M2], 2),
        "three-wave (twice round)": ([M[0][0] + M[1][1] for M in M2X2], 2)}
PROJ = {}
for name, (ch, d) in char.items():
    PROJ[name] = [[d / 12 * sum(ch[g] * RHO[g][i][j] for g in range(12)) for j in range(6)]
                  for i in range(6)]
road1 = {n: [sum(P[i][j] * X[j] for j in range(6)) for i in range(6)] for n, P in PROJ.items()}

# Road 2: an explicit basis of waves round the arms, and dot products.
def wave(fn, m):
    return [fn(radians(m * a)) for a in ARM]
BASIS = {"all equal": [[1.0] * 6], "alternating": [[(-1.0) ** i for i in range(6)]],
         "tilt (once round)": [wave(cos, 1), wave(sin, 1)],
         "three-wave (twice round)": [wave(cos, 2), wave(sin, 2)]}
dot = lambda a, b: sum(p * q for p, q in zip(a, b))
road2 = {}
for n, vs in BASIS.items():
    coeff = [dot(X, v) / dot(v, v) for v in vs]
    road2[n] = [sum(c * v[i] for c, v in zip(coeff, vs)) for i in range(6)]
size = lambda v: sqrt(dot(v, v))
alt_sum = sum((-1) ** i * X[i] for i in range(6))
print(f"arm lengths x, mm: {fl(X)}")
print(f"sum {f(sum(X))}, mean {f(sum(X) / 6)}; alternating sum {f(alt_sum)}, / 6 = {f(alt_sum / 6)}")
print(f"x minus the mean: {fl([v - sum(X) / 6 for v in X])}")
for n in char:
    sizes = [size([sum(PROJ[n][i][j] * sum(RHO[g][j][k] * X[k] for k in range(6))
                       for j in range(6)) for i in range(6)]) for g in range(12)]
    print(f"{n}: {fl(road1[n])}  size {f(size(road1[n]))} mm, "
          f"same after all 12 relabellings: {'yes' if max(sizes) - min(sizes) < 1e-12 else 'no'}")
    assert all(abs(a - b) < 1e-12 for a, b in zip(road1[n], road2[n]))   # two roads agree
    assert max(sizes) - min(sizes) < 1e-12                                # size ignores the labels
dev = size([v - sum(X) / 6 for v in X])
parts = [size(road1[n]) for n in list(char)[1:]]
print(f"squared sizes: {' + '.join(f(p * p) for p in parts)} = {f(sum(p * p for p in parts))}")
print(f"deviation from the mean, mm: {f(dev)}; from the pieces by Pythagoras: "
      f"{f(sqrt(sum(p * p for p in parts)))}")

# Change of basis: every rho(g) becomes blocks of size 1, 1, 2, 2.
cols = [[c / size(v) for c in v] for vs in BASIS.values() for v in vs]
B = [[cols[j][i] for j in range(6)] for i in range(6)]
Bt = [list(r) for r in zip(*B)]
block = [0, 1, 2, 2, 3, 3]
leak = max(abs(mul(mul(Bt, RHO[g]), B)[i][j]) for g in range(12)
           for i in range(6) for j in range(6) if block[i] != block[j])
T = mul(mul(Bt, RHO[1]), B)
print(f"largest entry outside the 1,1,2,2 blocks, over all 12 moves: {f(leak)}")
print(f"R60 on the tilt plane: [[{f(T[2][2])}, {f(T[2][3])}], [{f(T[3][2])}, {f(T[3][3])}]]")
print(f"R60 on the three-wave plane: [[{f(T[4][4])}, {f(T[4][5])}], [{f(T[5][4])}, {f(T[5][5])}]]")

# What breaks.
arm0 = [sum(RHO[g][0][k] * X[k] for k in range(6)) - sum(X) / 6 for g in range(12)]
disc = lambda a: (T[a][a] + T[a + 1][a + 1]) ** 2 - 4 * (T[a][a] * T[a + 1][a + 1] - T[a][a + 1] * T[a + 1][a])
S = [[1.0, 1.0], [0.0, 1.0]]                          # a shear: the group of all S^t, t real
on_line = lambda v: abs(v[0][0] * mul(S, v)[1][0] - v[1][0] * mul(S, v)[0][0]) < 1e-12
kept = sum(on_line([[a / 10], [1.0]]) for a in range(-100, 101))
print(f"mistake 1, indices read backwards: rho(gh) = rho(g) rho(h) fails for {bad} of 144 pairs")
print(f"mistake 2, arm 0's own excess over relabellings: from {f(min(arm0))} to {f(max(arm0))} mm")
print(f"mistake 3, R60 on the tilt plane: tr^2 - 4 det = {f(disc(2))}; on the three-wave plane: {f(disc(4))}; no real axis")
print(f"mistake 4, shear [[1, 1], [0, 1]]: x-axis kept: {'yes' if on_line([[1.0], [0.0]]) else 'no'}; lines through (a, 1) kept: {kept} of 201")
assert good == 144 and bad == 72 and kept == 0       # a representation; its mirror and the shear fail
assert [int(c) for c in chi] == [6, 0, 0, 0, 0, 0, 0, 2, 0, 2, 0, 2]   # independent count of fixed arms
assert abs(sum(c * c for c in chi) / 12 - 4) < 1e-12 and leak < 1e-12
assert abs(alt_sum / 6 - road1["alternating"][0]) < 1e-12 and max(abs(disc(a) + 3) for a in (2, 4)) < 1e-12
assert abs(dev - sqrt(sum(p * p for p in parts))) < 1e-12 and abs(parts[0] - 0.08 * sqrt(6)) < 1e-12
print("ALL CHECKS PASS")
