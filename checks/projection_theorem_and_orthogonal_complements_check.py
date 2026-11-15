# Projection theorem and orthogonal complements -- the check behind the card.
# Standard library only.  The seven-day record is done in exact fractions; the
# alternating projections and the infinite tail run in floats.  Nothing imported
# knows the answer: the fits, the matrix, the pooling and the sums are written out.
from fractions import Fraction as F
import math

y = [F(v) for v in (8, 10, 9, 11, 12, 12, 15)]   # daily mean temperature, deg C (illustrative)
t = [F(v) for v in range(-3, 4)]                  # day, counted from the middle day
one = [F(1)] * 7

def dot(u, v): return sum((a * b for a, b in zip(u, v)), F(0))
def sub(u, v): return [a - b for a, b in zip(u, v)]
def num(q): return str(q.numerator) if q.denominator == 1 else f"{float(q):.4f}".rstrip("0").rstrip(".")
def vec(v): return "(" + ", ".join(num(q) for q in v) + ")"
def yn(c): return "yes" if c else "no"
def line(a, b): return [a + b * s for s in t]
def fit(v): return line(dot(v, one) / 7, dot(v, t) / 28)          # P_M: nearest straight line
def front(v):                                                     # P_2: one level days 1-3, one days 4-7
    lo, hi = (v[0] + v[1] + v[2]) / 3, (v[3] + v[4] + v[5] + v[6]) / 4
    return [lo] * 3 + [hi] * 4

def warming(v):                                                   # P_C: pool adjacent violators
    blocks = []                                                   # each block: [sum, count]
    for x in v:
        blocks.append([x, 1])
        while len(blocks) > 1 and blocks[-2][0] / blocks[-2][1] > blocks[-1][0] / blocks[-1][1]:
            s, n = blocks.pop()
            blocks[-1][0] += s
            blocks[-1][1] += n
    return [s / n for s, n in blocks for _ in range(n)]

# ---- the split y = P y + r, three roads to the same line ----
a, b = dot(y, one) / 7, dot(y, t) / 28
p = line(a, b)
r = sub(y, p)
H28 = [[4 + int(t[i] * t[j]) for j in range(7)] for i in range(7)]  # 28 P = 4 J + t t^T
mul = lambda A, B: [[sum(A[i][k] * B[k][j] for k in range(7)) for j in range(7)] for i in range(7)]
Pmat_y = [sum(H28[i][j] * y[j] for j in range(7)) / 28 for i in range(7)]
HH = mul(H28, H28)
grid = [(F(10) + F(i, 2), F(1, 2) + F(j, 4)) for i in range(5) for j in range(5)]
miss = {g: dot(sub(y, line(*g)), sub(y, line(*g))) for g in grid}
formula_ok = all(miss[(aa, bb)] == 4 + 7 * (aa - 11) ** 2 + 28 * (bb - 1) ** 2 for aa, bb in grid)
best = min(grid, key=lambda g: miss[g])
print(f"record y, deg C: {vec(y)}; days t = {vec(t)}")
print(f"line fit: a = <y,1>/<1,1> = {num(dot(y, one))}/7 = {num(a)}, b = <y,t>/<t,t> = {num(dot(y, t))}/28 = {num(b)}")
print(f"trend P y = {vec(p)}")
print(f"residual r = y - P y = {vec(r)}")
print(f"<r,1> = {num(dot(r, one))}, <r,t> = {num(dot(r, t))}")
print(f"Pythagoras: |y|^2 = {num(dot(y, y))} = |P y|^2 {num(dot(p, p))} + |r|^2 {num(dot(r, r))}")
print(f"P y by the matrix 28P = 4J + t t^T: {vec(Pmat_y)}; same: {yn(Pmat_y == p)}")
print(f"P P = P exactly: {yn(HH == [[28 * v for v in row] for row in H28])}; "
      f"P symmetric: {yn(all(H28[i][j] == H28[j][i] for i in range(7) for j in range(7)))}")
print(f"trace P = {num(F(sum(H28[i][i] for i in range(7)), 28))}, "
      f"trace (I - P) = {num(7 - F(sum(H28[i][i] for i in range(7)), 28))}")
print(f"P(P y) = P y: {yn(fit(p) == p)}; P r = {vec(fit(r))}")
print(f"25 rival lines: least squared miss {num(miss[best])} at a = {num(best[0])}, b = {num(best[1])}; "
      f"4 + 7(a - 11)^2 + 28(b - 1)^2 on all 25: {yn(formula_ok)}")

# ---- the warming-only records: a closed convex cone, not a subspace ----
pc = warming(y)
rc = sub(y, pc)
steps = [[F(0)] * j + [F(1)] * (7 - j) for j in range(1, 7)]       # s_j: 1 from day j+1 on
cert = max(dot(rc, s) for s in steps)
print(f"warming-only fit P_C y = {vec(pc)}, squared miss {num(dot(rc, rc))}")
print(f"certificate: <r,1> = {num(dot(rc, one))}, <r,P_C y> = {num(dot(rc, pc))}, largest <r,s_j> = {num(cert)}")
print(f"P_C(P_C y) = P_C y: {yn(warming(pc) == pc)}; P_C(-y) = {vec(warming([-v for v in y]))}; "
      f"-P_C y = {vec([-v for v in pc])}")

# ---- alternating projections: lines, then front steps, then lines ... ----
s4 = [F(0)] * 3 + [F(1)] * 4
w = sub(s4, [F(4, 7)] * 7)                                         # the front step, minus its mean
cos2 = dot(t, w) ** 2 / (dot(t, t) * dot(w, w))
print(f"front fit P_2 y = {vec(front(y))}, squared miss {num(dot(sub(y, front(y)), sub(y, front(y))))}")
print(f"angle between the two fits: cos^2 = {num(cos2)}, angle {math.degrees(math.acos(math.sqrt(cos2))):.4f} deg")
x, dist = [float(v) for v in y], []
for k in range(1, 51):
    x = fit(x) if k % 2 else front(x)
    sq = 0.0
    for v in x:
        sq += (v - 11.0) * (v - 11.0)
    dist.append(math.sqrt(sq))
print("step k: distance from the all-11 record, closed form sqrt(28) (3/4)^((k-1)/2)")
for k in list(range(1, 9)) + [20, 50]:
    print(f"  {k:2d}: {dist[k - 1]:.4f}  {math.sqrt(28) * 0.75 ** ((k - 1) / 2):.4f}")

# ---- what breaks if you drop a piece ----
q = line((y[0] + y[6]) / 2, (y[6] - y[0]) / 6)                      # line through days 1 and 7
rq = sub(y, q)
qq = line((q[0] + q[6]) / 2, (q[6] - q[0]) / 6)
print(f"mistake 1, endpoint line: a = {num(q[3])}, b = {num(q[4] - q[3])}; Q Q = Q: {yn(qq == q)}; "
      f"squared miss {num(dot(rq, rq))}; <r,1> = {num(dot(rq, one))}, <r,t> = {num(dot(rq, t))}")
x3 = fit(front(fit(y)))
print(f"mistake 2, one round taken as the answer: slope {num(x3[4] - x3[3])}, {dist[2]:.4f} from the all-11 record")
print("mistake 3, finite records against the tail 1, 1/2, 1/3, ... in l2:")
basel, tails = math.pi * math.pi / 6, []
for n in (1, 10, 100, 1000, 10000):
    head, road2, K = 0.0, 0.0, 2000000
    for k in range(n, 0, -1):
        head += 1.0 / (k * k)
    for k in range(K, n, -1):                                     # summed smallest first
        road2 += 1.0 / (k * k)
    road1 = basel - head
    road2 += 1.0 / K - 0.5 / K ** 2 + 1.0 / (6 * K ** 3)        # Euler-Maclaurin tail past K
    tails.append(math.sqrt(road1))
    print(f"  N = {n:5d}: best miss {math.sqrt(road1):.6f} (direct sum {math.sqrt(road2):.6f}), "
          f"sqrt(N) x miss {math.sqrt(n * road1):.4f}")
    assert abs(road1 - road2) < 1e-9
print("closed subspace of l2: keep the even places of the tail, cut at N")
for n in (10, 100, 1000, 10000):
    ev, od = 0.0, 0.0
    for k in range(1, n + 1):
        if k % 2: od += 1.0 / (k * k)
        else: ev += 1.0 / (k * k)
    print(f"  N = {n:5d}: |P y|^2 {ev:.6f}, |r|^2 {od:.6f}, cut to P y {math.sqrt(basel / 4 - ev):.6f}")
    assert abs(ev - basel / 4) < 1 / n and abs(od - 3 * basel / 4) < 1 / n
print(f"  limits: pi^2/24 {basel / 4:.6f} + pi^2/8 {3 * basel / 4:.6f} = pi^2/6 {basel:.6f}; miss {math.sqrt(3 * basel / 4):.6f}")
pts = [(40 + 70 * d, 220.0) if k % 2 == 0 else (40 + 70 * d * math.sqrt(0.75), 220 - 35 * d)
       for k, d in enumerate(dist[:6])]
print("figure, " + "; ".join(f"({u:.1f}, {v:.1f})" for u, v in pts))

assert (a, b) == (11, 1) and Pmat_y == p and best == (11, 1) and formula_ok   # three roads, one line
assert dot(r, one) == 0 and dot(r, t) == 0 and dot(y, y) == dot(p, p) + dot(r, r)
assert HH == [[28 * v for v in row] for row in H28] and fit(r) == [0] * 7  # P P = P, P r = 0
assert dot(rc, one) == 0 and dot(rc, pc) == 0 and cert <= 0 and warming(pc) == pc
assert cos2 == F(3, 4) and all(abs(d - math.sqrt(28) * 0.75 ** (k / 2)) < 1e-12 for k, d in enumerate(dist))
assert qq == q and dot(rq, rq) > dot(r, r) and all(u > v > 0 for u, v in zip(tails, tails[1:]))
print("ALL CHECKS PASS")
