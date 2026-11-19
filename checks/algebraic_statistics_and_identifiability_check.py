# Algebraic statistics and identifiability -- the check behind the card.
# Standard library only.  A two-coin mixture: with chance pi pick coin A (heads
# chance a), else coin B (heads chance b), flip it 4 times.  Road 1 eliminates
# the parameters by hand (a linear recurrence) and solves the fibre exactly.
# Road 2 finds every cubic that vanishes on the model by interpolation mod a
# prime.  Road 3 counts parameter points on a grid by brute force.
from fractions import Fraction as F
from math import comb, isqrt, prod

def dist(pi, a, b, n=4):               # chance of k heads in n flips, k = 0..n
    return [comb(n, k) * (pi * a**k * (1 - a)**(n - k) + (1 - pi) * b**k * (1 - b)**(n - k))
            for k in range(n + 1)]
def hankel_det(q):                     # det [[q0,q1,q2],[q1,q2,q3],[q2,q3,q4]]
    return (q[0] * (q[2] * q[4] - q[3] * q[3]) - q[1] * (q[1] * q[4] - q[3] * q[2])
            + q[2] * (q[1] * q[3] - q[2] * q[2]))
def recurrence(q):                     # solve q2 = s q1 - r q0, q3 = s q2 - r q1
    d = q[0] * q[2] - q[1] * q[1]
    return (q[0] * q[3] - q[1] * q[2]) / d, (q[1] * q[3] - q[2] * q[2]) / d
def fsqrt(x):                          # exact square root of a rational, or None
    if x < 0: return None
    n, d = isqrt(x.numerator), isqrt(x.denominator)
    return F(n, d) if F(n * n, d * d) == x else None
def fibre(p):                          # every (pi, a, b) giving p, by elimination
    q = [p[k] / comb(4, k) for k in range(5)]
    s, r = recurrence(q)               # odds x = a/(1-a) are roots of t^2 - s t + r
    A, B, C = 1 + s + r, -(s + 2 * r), r   # eliminant in a: A a^2 + B a + C = 0
    disc = B * B - 4 * A * C; root = fsqrt(disc)
    if root is None: return s, r, (A, B, C), disc, []
    r1, r2 = (-B + root) / (2 * A), (-B - root) / (2 * A)
    pts = []
    for a, b in ((r1, r2), (r2, r1)):  # pi from q0 = alpha + beta, q1 = alpha x + beta y
        x, y = a / (1 - a), b / (1 - b)
        pts.append(((q[1] - y * q[0]) / (x - y) * (1 + x)**4, a, b))
    return s, r, (A, B, C), disc, pts
def rank(rows):                        # exact Gaussian elimination
    m, rk = [list(r) for r in rows], 0
    for c in range(len(m[0])):
        piv = next((i for i in range(rk, len(m)) if m[i][c] != 0), None)
        if piv is None: continue
        m[rk], m[piv] = m[piv], m[rk]
        for i in range(len(m)):
            if i != rk and m[i][c] != 0:
                f = m[i][c] / m[rk][c]; m[i] = [u - f * v for u, v in zip(m[i], m[rk])]
        rk += 1
    return rk
def jac_rank(pi, a, b, n):             # rank of d(p_1..p_n)/d(pi, a, b), exact
    dk = lambda t, k: k * t**(k - 1) * (1 - t)**(n - k) - (n - k) * t**k * (1 - t)**(n - k - 1)
    return rank([[comb(n, k) * (a**k * (1 - a)**(n - k) - b**k * (1 - b)**(n - k)),
                  comb(n, k) * pi * dk(a, k), comb(n, k) * (1 - pi) * dk(b, k)] for k in range(1, n + 1)])

pi0, a0, b0 = F(2, 5), F(4, 5), F(1, 2)
p = dist(pi0, a0, b0); q = [p[k] / comb(4, k) for k in range(5)]
pA, pB = dist(F(1), a0, b0), dist(F(0), a0, b0)
print("example: pi = 2/5, coin A heads 4/5, coin B heads 1/2, 4 flips")
for k in range(5):
    print(f"k={k}  p = {str(p[k]):<12} {float(p[k]) * 100:7.3f}%   one sequence q = {q[k]}")
print("chart, mixture %  " + " ".join(f"{float(v) * 100:6.2f}" for v in p))
print("chart, coin A part " + " ".join(f"{float(pi0 * v) * 100:6.2f}" for v in pA))
print("chart, coin B part " + " ".join(f"{float((1 - pi0) * v) * 100:6.2f}" for v in pB))
s, r, eli, disc, pts = fibre(p)
print(f"road 1: s = {s}, r = {r}; third equation leaves {q[4] - (s * q[3] - r * q[2])}")
print(f"        Hankel determinant at the example = {hankel_det(q)}")
print(f"        eliminant {eli[0]} a^2 + ({eli[1]}) a + {eli[2]}, discriminant {disc}")
U = 50000**2                           # the worked numbers, in units of 1/50000 squared
print(f"        x U: q0q3-q1q2 = {(q[0]*q[3]-q[1]*q[2])*U}, q0q2-q1^2 = {(q[0]*q[2]-q[1]**2)*U}, q1q3-q2^2 = {(q[1]*q[3]-q[2]**2)*U}")
for t in pts: print(f"        fibre point pi = {t[0]}, a = {t[1]}, b = {t[2]} (alpha = {t[0] * (1 - t[1])**4})")

P = 2**31 - 1                          # road 2: interpolation modulo a prime
state = 20261117
def rnd():                             # SplitMix64, seed 20261117
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return (z ^ (z >> 31)) % P
def monos(deg, n=5):          # exponent vectors of degree deg, sorted
    if n == 0: return [()] if deg == 0 else []
    return [(e,) + rest for e in range(deg, -1, -1) for rest in monos(deg - e, n - 1)]
def kernel_mod(rows, ncol):            # basis of the null space mod P
    m, piv, rk = [r[:] for r in rows], [], 0
    for c in range(ncol):
        i = next((i for i in range(rk, len(m)) if m[i][c]), None)
        if i is None: continue
        m[rk], m[i] = m[i], m[rk]; inv = pow(m[rk][c], P - 2, P)
        m[rk] = [v * inv % P for v in m[rk]]
        for j in range(len(m)):
            if j != rk and m[j][c]: f = m[j][c]; m[j] = [(u - f * v) % P for u, v in zip(m[j], m[rk])]
        piv.append(c); rk += 1
    free = [c for c in range(ncol) if c not in piv]
    return [[(1 if c == f else 0) if c not in piv else (-m[piv.index(c)][f]) % P for c in range(ncol)] for f in free]
pts_mod = []
for _ in range(60):                    # random (alpha, beta, x, y): q_k = alpha x^k + beta y^k, k = 0..5
    al, be, x, y = rnd(), rnd(), rnd(), rnd()
    pts_mod.append([(al * pow(x, k, P) + be * pow(y, k, P)) % P for k in range(6)])
def ev(e, v): return prod(pow(vi, ei, P) for ei, vi in zip(e, v)) % P
kern = {}
for deg in (1, 2, 3):
    ms = monos(deg); kern[deg] = kernel_mod([[ev(e, v) for e in ms] for v in pts_mod], len(ms))
    print(f"road 2: degree {deg}: {len(ms)} monomials, vanishing combinations {len(kern[deg])}")
ms, vec = monos(3), kern[3][0]
lead = next(c for c in vec if c); inv = pow(lead, P - 2, P)
coef = [(c * inv) % P for c in vec]; coef = [c - P if c > P // 2 else c for c in coef]
terms = [(c, e) for c, e in zip(coef, ms) if c]
name = lambda e: "*".join(f"q{i}" + (f"^{k}" if k > 1 else "") for i, k in enumerate(e) if k)
print("        the cubic: " + " ".join(f"{'+' if c > 0 else '-'}{abs(c) if abs(c) > 1 else ''}{name(e)}" for c, e in terms).lstrip("+"))
m6 = monos(3, 6); k5 = len(kernel_mod([[ev(e, v) for e in m6] for v in pts_mod], len(m6)))   # 5 flips: q0..q5
print(f"road 2, 5 flips: degree 3 in q0..q5: {len(m6)} monomials, vanishing combinations {k5}")
agree = all(sum(c * ev(e, v) for c, e in terms) % P == hankel_det(v) % P   # same function as det H
            for v in [[rnd() for _ in range(5)] for _ in range(20)])

grid = lambda n: {(i, j, l): tuple(dist(F(i, 10), F(j, 10), F(l, 10), n)) for i in range(1, 10) for j in range(11) for l in range(11)}
g4 = grid(4)
hits = [t for t, v in g4.items() if v == tuple(p)]
fair = [t for t, v in g4.items() if v == tuple(dist(pi0, F(1, 2), F(1, 2)))]
print(f"road 3: grid of {len(g4)} points; same p as the example: {hits}; same p as two fair coins: {len(fair)}")
print("flips n  outcomes  free coords  Jacobian rank  codimension")
for n in (2, 3, 4, 5):
    rk = jac_rank(pi0, a0, b0, n); print(f"{n:>7} {n + 1:>9} {n:>12} {rk:>14} {n - rk:>12}")
alt = (F(27, 125), F(9, 10), F(19, 35))
print(f"break, 2 flips: {[str(v) for v in dist(*alt, 2)]} vs {[str(v) for v in dist(pi0, a0, b0, 2)]}")
print(f"break, 2 flips at 4 flips: {[str(v) for v in dist(*alt)]}")
avg = [(u + v) / 2 for u, v in zip(*pts)]
print(f"break, a = b = 1/2: Jacobian rank {jac_rank(pi0, F(1, 2), F(1, 2), 4)}; average of the two fibre points {[str(v) for v in avg]}")
pc = [F(v, 161) for v in (1, 12, 48, 72, 28)]
sc, rc, elc, dc, ptc = fibre(pc)
print(f"break, complex coins: sum {sum(pc)}, det {hankel_det([pc[k] / comb(4, k) for k in range(5)])}, s = {sc}, r = {rc}, odds discriminant {sc * sc - 4 * rc}, fibre points {len(ptc)}")
print(f"break, binomials left in: det of p-Hankel = {hankel_det(p)}")
print(f"try, b = 1/5: {[(str(t[0]), str(t[1]), str(t[2])) for t in fibre(dist(pi0, a0, F(1, 5)))[4]]}")
print(f"try, a = 3/4, b = 1/4, pi = 1/2: {[(str(t[0]), str(t[1]), str(t[2])) for t in fibre(dist(F(1, 2), F(3, 4), F(1, 4)))[4]]}")

assert sum(p) == 1 and (s, r) == (a0 / (1 - a0) + b0 / (1 - b0), a0 / (1 - a0) * b0 / (1 - b0))
assert hankel_det(q) == 0 and hankel_det(p) != 0
assert sorted(pts) == sorted([(pi0, a0, b0), (1 - pi0, b0, a0)])
assert sorted(hits) == [(4, 8, 5), (6, 5, 8)] and len(fair) == 9
assert [len(kern[d]) for d in (1, 2, 3)] == [0, 0, 1] and agree and k5 == comb(4, 3)   # 3 x 3 minors of 3 x 4
assert dist(*alt, 2) == dist(pi0, a0, b0, 2) and dist(*alt) != p
assert [jac_rank(pi0, a0, b0, n) for n in (2, 3, 4)] == [2, 3, 3]
assert hankel_det([pc[k] / comb(4, k) for k in range(5)]) == 0 and ptc == [] and sc * sc - 4 * rc < 0
print("ALL CHECKS PASS")
