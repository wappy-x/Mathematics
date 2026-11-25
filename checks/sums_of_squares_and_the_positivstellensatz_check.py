# Sums of squares and the Positivstellensatz -- the check behind the card.
# Standard library only.  Polynomials are dicts {(ex, ey): Fraction}, x > y.
# Every certificate is multiplied out exactly; Gram matrices are tested for
# positive semidefinite by their principal minors and split into squares.
from fractions import Fraction as Q
from itertools import combinations

def P(*terms):                                  # P((coefficient, (ex, ey)), ...)
    out = {}
    for c, m in terms:
        out[m] = out.get(m, 0) + Q(c)
    return {m: c for m, c in out.items() if c != 0}
def add(*fs):
    return P(*[(c, m) for f in fs for m, c in f.items()])
def mul(*fs):
    out = {(0, 0): Q(1)}
    for g in fs:
        out = P(*[(a * b, (m[0] + n[0], m[1] + n[1])) for m, a in out.items() for n, b in g.items()])
    return out

k = lambda c: P((c, (0, 0)))                    # a constant

def show(f, v="xy"):                            # leading term first
    s = ""
    for m in sorted(f, key=lambda m: (sum(m), m), reverse=True):
        mono = "".join(n + (f"^{e}" if e > 1 else "") for n, e in zip(v, m) if e)
        a = abs(f[m])
        body = str(a) if not mono else mono if a == 1 else f"{a}{mono}" if a.denominator == 1 else f"({a}){mono}"
        s += (("-" if f[m] < 0 else "") if not s else (" - " if f[m] < 0 else " + ")) + body
    return s or "0"

det = lambda A: A[0][0] if len(A) == 1 else sum((-1) ** j * A[0][j] * det([r[:j] + r[j + 1:] for r in A[1:]]) for j in range(len(A)))
minors = lambda A: [det([[A[i][j] for j in S] for i in S]) for r in range(1, len(A) + 1) for S in combinations(range(len(A)), r)]
psd = lambda A: min(minors(A)) >= 0             # every principal minor at least 0

def squares(A, z):                              # A = L D L^T, pivoting from the last monomial
    A, out = [row[:] for row in A], []
    for p in reversed(range(len(A))):
        d = A[p][p]
        if d == 0:
            continue
        l = [A[i][p] / d for i in range(p + 1)]
        out.append((d, add(*[mul(k(l[i]), z[i]) for i in range(p + 1)])))
        A = [[A[i][j] - d * l[i] * l[j] if i <= p and j <= p else A[i][j] for j in range(len(A))] for i in range(len(A))]
    return out

sos = lambda parts: add(*[mul(k(d), q, q) for d, q in parts])
ev = lambda f, x, y=0: sum(c * Q(x) ** m[0] * Q(y) ** m[1] for m, c in f.items())

def says(parts, v="xy"):                        # d1(q1)^2 + d2(q2)^2 + ...
    w = [str(d) if q == k(1) else ("" if d == 1 else f"{d}" if d.denominator == 1 else f"({d})") + f"({show(q, v)})^2"
         for d, q in parts]
    return " + ".join(w).replace("+ -", "- ")

X, Y = P((1, (1, 0))), P((1, (0, 1)))
p = P((1, (4, 0)), (4, (3, 0)), (6, (2, 0)), (4, (1, 0)), (5, (0, 0)))
print(f"p = {show(p)}")
s1 = add(mul(add(X, k(1)), add(X, k(1)), add(X, k(1)), add(X, k(1))), k(4))
print(f"road 1, ((x + 1)^2)^2 + 2^2 expands to {show(s1)}")
z = [k(1), X, mul(X, X)]
cons = {d: [(i, j) for i in range(3) for j in range(3) if i + j == d] for d in range(5)}
print("road 2, Gram matrix on (1, x, x^2), coefficients matched: " + " | ".join(
      f"x^{d}: " + " + ".join(f"Q{i}{j}" for i, j in cons[d]) + f" = {p.get((d, 0), 0)}" for d in range(5)))
G = lambda t, g=0: [[5 - g, Q(2), Q(t)], [Q(2), 6 - 2 * Q(t), Q(2)], [Q(t), Q(2), Q(1)]]
for t in [Q(-3, 2), Q(-1), Q(0), Q(1), Q(2)]:
    A = G(t)
    print(f"t = {t}: Q = {[[str(a) for a in r] for r in A]}".replace("'", "") +
          f", least principal minor {min(minors(A))}, det {det(A)}, PSD {'yes' if psd(A) else 'no'}")
grid = [Q(j, 8) for j in range(-24, 25)]
ok = [t for t in grid if psd(G(t))]
print(f"road 2, PSD on the grid t = j/8, -3 <= t <= 3: from {min(ok)} to {max(ok)}, {len(ok)} points")
spl = {t: squares(G(t), z) for t in [Q(1), Q(0), Q(-1), Q(2)]}
for t in [Q(1), Q(0), Q(-1)]:
    print(f"t = {t}: p = {says(spl[t])}")
f1, f2 = add(mul(X, X), k(1)), add(mul(X, X), mul(k(4), X), k(5))
print(f"road 3, (x^2 + 1)(x^2 + 4x + 5) = {show(mul(f1, f2))}")
a, b, c, d = X, k(1), add(X, k(2)), k(1)
plus = [add(mul(a, c), mul(b, d)), add(mul(a, d), mul(k(-1), b, c))]
minus = [add(mul(a, c), mul(k(-1), b, d)), add(mul(a, d), mul(b, c))]
print(f"road 3, u = x, v = x + 2: (uv + 1)^2 + (u - v)^2 = ({show(plus[0])})^2 + ({show(plus[1])})^2; "
      f"(uv - 1)^2 + (u + v)^2 = ({show(minus[0])})^2 + ({show(minus[1])})^2")
vals = [(ev(p, Q(j, 100)), Q(j, 100)) for j in range(-500, 501)]
print(f"road 4, p at x = j/100 for -5 <= x <= 5: least value {min(vals)[0]} at x = {min(vals)[1]}")
best = max(g for g in [Q(j, 4) for j in range(12, 21)] if any(psd(G(t, g)) for t in grid))
print(f"SOS lower bound: largest gamma = j/4 with p - gamma a sum of squares: {best}; "
      f"p - 4 = {says(squares(G(1, 4), z))}; p(-1) - 17/4 = {ev(p, -1) - Q(17, 4)}")
M = P((1, (4, 2)), (1, (2, 4)), (-3, (2, 2)), (1, (0, 0)))
print(f"M = {show(M)}; AM-GM at (1, 1): terms x^4y^2, x^2y^4, 1 = 1, 1, 1; mean 1, geometric mean 1, M = {ev(M, 1, 1)}")
mg = [(ev(M, Q(i, 20), Q(j, 20)), i, j) for i in range(-40, 41) for j in range(-40, 41)]
low = min(mg)[0]
print(f"M on the grid x, y = j/20 in [-2, 2]: least value {low}, at {sum(v == low for v, _, _ in mg)} points, "
      f"negative at {sum(v < 0 for v, _, _ in mg)}")
inside = lambda u, v: v <= 2 * u and u <= 2 * v and u + v <= 6   # triangle (0,0), (4,2), (2,4)
half = [(i, j) for i in range(4) for j in range(4) if inside(2 * i, 2 * j)]
print(f"Newton triangle (0, 0), (4, 2), (2, 4) holds (2, 2): {'yes' if inside(2, 2) else 'no'}; "
      f"half of it holds the monomials {', '.join(show(P((1, m))) for m in half)}")
pairs = [(m, n) for m in half for n in half if (m[0] + n[0], m[1] + n[1]) == (2, 2)]
sm = lambda a, b: (a[0] + b[0], a[1] + b[1])     # Gram entry (a, b) multiplies the monomials a and b
GM = [[M.get(sm(a, b), Q(0)) / sum(sm(c, d) == sm(a, b) for c in half for d in half) for b in half] for a in half]
zGz = add(*[mul(k(GM[i][j]), P((1, a)), P((1, b))) for i, a in enumerate(half) for j, b in enumerate(half)])
print(f"products giving x^2y^2: {', '.join(show(P((1, m))) + ' times ' + show(P((1, n))) for m, n in pairs)}, so the Gram diagonal entry for xy must be {GM[1][1]}, "
      f"for M - gamma with any gamma too; the Gram matrix this forces on those monomials gives back M: {'yes' if zGz == M else 'no'}, PSD: {'yes' if psd(GM) else 'no'}")
r2 = add(mul(X, X), mul(Y, Y))
art = add(mul(X, X, Y, Y, add(r2, k(1)), add(r2, k(-2)), add(r2, k(-2))), mul(add(mul(X, X), mul(k(-1), Y, Y)), add(mul(X, X), mul(k(-1), Y, Y))))
print(f"Artin: (x^2 + y^2)^2 M - [x^2y^2(x^2 + y^2 + 1)(x^2 + y^2 - 2)^2 + (x^2 - y^2)^2] = {show(add(mul(r2, r2, M), mul(k(-1), art)))}")
h, g = add(r2, k(-1)), add(X, k(-2))
cert = add(mul(k(Q(1, 3)), add(mul(g, g), mul(Y, Y))), mul(k(Q(4, 3)), g), mul(k(Q(-1, 3)), h))
print(f"system {show(h)} = 0, {show(g)} >= 0; road 1, (1/3)((x - 2)^2 + y^2) + (4/3)(x - 2) - (1/3)(x^2 + y^2 - 1) = {show(cert)}")
C = lambda c, s, w=2: [[w * c - s - 1, -c / 2, Q(0)], [-c / 2, s, Q(0)], [Q(0), Q(0), s]]   # wall at x >= w
feas = lambda w: [(s, c) for s in [Q(j, 24) for j in range(25)] for c in [Q(j, 24) for j in range(73)] if psd(C(c, s, w))]
s0, c0 = min(feas(2))
print(f"road 2, Gram search on (1, x, y), s and c in steps of 1/24: first feasible s = {s0}, c = {c0}, "
      f"sigma0 = {says(squares(C(c0, s0), [k(1), X, Y]))}")
circ = [(Q(1 - u * u, 1 + u * u), Q(2 * u, 1 + u * u)) for u in [Q(j, 10) for j in range(-30, 31)]]
print(f"road 3, circle points ((1 - u^2)/(1 + u^2), 2u/(1 + u^2)), u = j/10: largest x = {max(x for x, _ in circ)}, "
      f"all on the circle: {'yes' if all(ev(h, x, y) == 0 for x, y in circ) else 'no'}")
f_1, f_2 = add(mul(X, X), mul(Y, Y), k(-9)), add(mul(X, X), mul(k(-8), X), mul(Y, Y), k(12))
inI = add(f_1, mul(k(Q(-1, 8)), add(X, k(Q(21, 8))), add(f_1, mul(k(-1), f_2))))
lift = add(Y, k(-2))
arm = mul(k(Q(64, 121)), add(mul(lift, lift), mul(k(4), lift), mul(k(-1), inI)))
print(f"arm, 3 m and 2 m links, target 4 m: {show(f_1, 'ab')} = 0, {show(f_2, 'ab')} = 0; in the ideal: {show(inI, 'ab')}; "
      f"b = +-{float(Q(135, 64)) ** 0.5:.6f} m")
print(f"arm, elbow at least 2 m up: (64/121)((b - 2)^2 + 4(b - 2) - ({show(inI, 'ab')})) = {show(arm, 'ab')}")
print(f"break, t = 2: p = {says(spl[Q(2)])}")
cx = add(h, mul(k(-1), add(X, k(2)), g))
print(f"break, over C: x = 2, y^2 = {-ev(h, 2)}; "
      f"real certificate (1/3)y^2 - (1/3)({show(cx)}) = {show(add(mul(k(Q(1, 3)), Y, Y), mul(k(Q(-1, 3)), cx)))}")
s3, c3 = min(feas(3))
print(f"try: t = 3 gives least principal minor {min(minors(G(3)))}; gamma = 4 leaves t = {', '.join(str(t) for t in grid if psd(G(t, 4)))}; "
      f"wall at x >= 3: first s = {s3}, c = {c3}; wall at x >= 1: {len(feas(1))} feasible pairs")
print("figure, circle centre (0, 0) radius 1; wall x = 2; nearest circle point (1, 0); gap 1")
assert s1 == p and sos(spl[Q(1)]) == p and sos(spl[Q(0)]) == p and sos(spl[Q(-1)]) == p
assert mul(f1, f2) == p and add(mul(*plus[:1] * 2), mul(*plus[1:] * 2)) == p and add(mul(minus[0], minus[0]), mul(minus[1], minus[1])) == p
assert (min(ok), max(ok)) == (-1, 1) and not psd(G(Q(9, 8))) and det(G(0)) == 6
assert min(vals) == (4, -1) and best == 4 and sos(squares(G(1, 4), z)) == add(p, k(-4))
assert ev(M, 1, 1) == 0 == low and all(v >= 0 for v, _, _ in mg) and len(pairs) == 1 and zGz == M and GM[1][1] == -3 and not psd(GM)
assert add(mul(r2, r2, M), mul(k(-1), art)) == {} and cert == k(-1) and arm == k(-1)
assert (s0, c0) == (Q(1, 3), Q(4, 3)) and sos(squares(C(c0, s0), [k(1), X, Y])) == add(cert, mul(k(Q(-4, 3)), g), mul(k(Q(1, 3)), h))
assert (s3, c3) == (Q(1, 8), Q(3, 4)) and feas(1) == [] and max(x for x, _ in circ) == 1 and inI == add(mul(Y, Y), k(Q(-135, 64))) and min(d for d, _ in spl[Q(2)]) < 0
print("ALL CHECKS PASS")
