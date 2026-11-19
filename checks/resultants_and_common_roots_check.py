# The resultant -- the check behind the card.  Imports: fractions, for exact
# rationals, and math, for one square root and one angle; neither knows any
# resultant.  A polynomial is a list of coefficients, constant term first.
from fractions import Fraction as Q
from math import atan2, degrees, sqrt

def trim(p):
    p = list(p)
    while p and p[-1] == 0: p.pop()
    return p

def show(p, v="t"):                       # leading term first, as the card writes it
    terms = []
    for k in range(len(p) - 1, -1, -1):
        if p[k] == 0: continue
        a = abs(p[k])
        body = ("" if a == 1 and k else str(a)) + (v if k else "") + (f"^{k}" if k > 1 else "")
        terms.append(("-" if p[k] < 0 else "+", body))
    if not terms: return "0"
    return ("-" if terms[0][0] == "-" else "") + terms[0][1] + "".join(f" {s} {b}" for s, b in terms[1:])

def add(p, q):
    return trim([(p[i] if i < len(p) else 0) + (q[i] if i < len(q) else 0) for i in range(max(len(p), len(q)))])

def mul(p, q):
    r = [0] * (len(p) + len(q) - 1) if p and q else []
    for i, a in enumerate(p):
        for j, b in enumerate(q): r[i + j] += a * b
    return trim(r)

def ev(p, x):                             # Horner: exact value at x
    s = 0
    for c in reversed(p): s = s * x + c
    return s

def sylvester(f, g, zero):                # deg g shifted rows of f, deg f shifted rows of g
    m, n = len(f) - 1, len(g) - 1
    rows = [[zero] * i + f[::-1] + [zero] * (n - 1 - i) for i in range(n)]
    return rows + [[zero] * i + g[::-1] + [zero] * (m - 1 - i) for i in range(m)]

def det_rows(M):                          # road one: row reduction over the rationals
    M, d, N = [[Q(x) for x in r] for r in M], Q(1), len(M)
    for c in range(N):
        p = next((r for r in range(c, N) if M[r][c] != 0), None)
        if p is None: return Q(0)
        if p != c: M[c], M[p], d = M[p], M[c], -d
        d *= M[c][c]
        for r in range(c + 1, N):
            k = M[r][c] / M[c][c]
            M[r] = [M[r][j] - k * M[c][j] for j in range(N)]
    return d

def perms(n):                             # every ordering of 0..n-1, with its sign
    if n == 1: return [([0], 1)]
    return [(p[:i] + [n - 1] + p[i:], s * (-1) ** (n - 1 - i)) for p, s in perms(n - 1) for i in range(n)]

def det_perm(M):                          # road two: the permutation sum; entries are polynomials
    total = []
    for p, s in perms(len(M)):
        term = [s]
        for r in range(len(M)): term = mul(term, M[r][p[r]])
        total = add(total, term)
    return total

def gcd(a, b):                            # road three: Euclid, made monic
    a, b = trim([Q(x) for x in a]), trim([Q(x) for x in b])
    while b:
        r = a
        while len(r) >= len(b):
            k, s = r[-1] / b[-1], len(r) - len(b)
            r = trim([r[i] - (k * b[i - s] if i >= s else 0) for i in range(len(r))])
        a, b = b, r
    return [c / a[-1] for c in a]

def rat_roots(p):                         # rational root test: plus or minus u/v, u | constant, v | top
    dv = lambda n: [d for d in range(1, abs(n) + 1) if n % d == 0]
    c = sorted({Q(s * u, v) for u in dv(p[0]) for v in dv(p[-1]) for s in (1, -1)})
    return [x for x in c if ev(p, x) == 0]

def lst(xs): return ", ".join(str(x) for x in xs) or "none"
def num(M): return [[[x] if x else [] for x in r] for r in M]
def gear_b(c): return [c, -20, c]         # 10 x 2t = c(1 + t^2): gear B's tip at height c
fA = add([3, 0, 3], [-5, 0, 5])           # 5 cos = 3, cleared: 3(1 + t^2) - 5(1 - t^2) = 0
f, g, g9 = [c // 2 for c in fA], gear_b(8), gear_b(9)   # f is fA halved
S = sylvester(f, g, 0)
print(f"gear A, tip radius 5 cm, gauge x = 3 cm: 3(1 + t^2) - 5(1 - t^2) = {show(fA)}, halved f = {show(f)}")
print(f"gear B, tip radius 10 cm, gauge y = 8 cm: g = {show(g)}")
print("Sylvester rows:", " ".join(str(r) for r in S))
print(f"Res_t(f, g): row reduction {det_rows(S)}, 24-term permutation sum {show(det_perm(num(S)))}")
h = gcd(f, g)
print(f"Euclid: gcd(f, g) = {show(h)}, degree {len(h) - 1}")
assert len(h) == 2                        # a shared root exists: the gcd has degree 1
(lo, hi), a2, t0 = rat_roots(f), f[-1] ** (len(g) - 1), -h[0]   # road four: f's roots and 4^2; t0: the gcd's root
print(f"rational roots: f {lst(rat_roots(f))}; g {lst(rat_roots(g))}")
print(f"product formula: 4^2 x g({hi}) x g({lo}) = {a2} x {ev(g, hi)} x {ev(g, lo)} = {a2 * ev(g, hi) * ev(g, lo)}")
co, si = (1 - t0 ** 2) / (1 + t0 ** 2), 2 * t0 / (1 + t0 ** 2)
print(f"contact: t = {t0}, cos = {co}, sin = {si}, angle {degrees(atan2(si, co)):.3f} degrees")
print(f"substitution: f({t0}) = {ev(f, t0)}, g({t0}) = {ev(g, t0)}; tip A at ({5 * co}, {5 * si}), tip B at ({10 * co}, {10 * si})")
A, B = [-8, 4], [-1, -2]
print(f"certificate: A = {show(A)}, B = {show(B)}, A f + B g = {show(add(mul(A, f), mul(B, g)))}")
p9 = a2 * ev(g9, hi) * ev(g9, lo)
print(f"gauge y = 9 cm: g = {show(g9)}, Res = {det_rows(sylvester(f, g9, 0))}, product {a2} x {ev(g9, hi)} x {ev(g9, lo)} = {p9}, "
      f"gcd {show(gcd(f, g9))}, Res(f, 2g) = {det_rows(sylvester(f, [2 * c for c in g9], 0))}")
E = det_perm(sylvester([[-1], [], [4]], [[0, 1], [-20], [0, 1]], []))
fam = all(det_rows(sylvester(f, gear_b(c), 0)) == ev(E, c) for c in range(-10, 11))
print(f"eliminate t: Res_t(f, c t^2 - 20t + c) = {show(E, 'c')}, roots c = {lst(rat_roots(E))}")
print(f"same as row reduction at c = -10..10: {'yes' if fam else 'no'}")
pyth = [2500 * (Q(3, 5) ** 2 - 1), 0, Q(2500, 10 ** 2)]   # cos^2 + sin^2 - 1 at cos = 3/5, sin = c/10, times 2500
print(f"Pythagoras: 2500((3/5)^2 + (c/10)^2 - 1) = {show(pyth, 'c')}; same as the eliminant: {'yes' if pyth == E else 'no'}")
print(f"figure, centre (0, 0), circle A r 5, circle B r 10, gauge x = 3, gauge y = 8, tip A ({5 * co}, {5 * si}), tip B ({10 * co}, {10 * si})")

def arm(d):                               # elbow (u, v): u^2 + v^2 = 9, (u - d)^2 + v^2 = 4; eliminate v
    E = det_perm(sylvester([[-9, 0, 1], [], [1]], [[d * d - 4, -2 * d, 1], [], [1]], []))
    a = next(iter(rat_roots(E)), Q(0))      # its rational root, 0 if none
    return E, a, 9 - a * a

for d in (4, 6):
    Ea, a, b2 = arm(d)
    tail = f"v = +-{sqrt(b2):.4f} m, two elbows" if b2 > 0 else "one elbow, arm straight" if b2 == 0 else "no real elbow"
    print(f"arm, target ({d}, 0) m: Res_v = {show(Ea, 'u')}, u = {a} m, v^2 = {b2}, {tail}")
print(f"arm eliminant at target 4 m is (8u - 21)^2: {'yes' if arm(4)[0] == mul([-21, 8], [-21, 8]) else 'no'}")
fx, gx = [1, 0, 11], [2, 0, 22]           # gauges x = 6 and x = 12, past both tips
t2 = -gcd(fx, gx)[0]                      # the shared value of t^2
print(f"gauges x = 6, x = 12: f = {show(fx)}, g = {show(gx)}, Res = {det_rows(sylvester(fx, gx, 0))}, "
      f"gcd {show(gcd(fx, gx))}, so t^2 = {t2}, cos = {(1 - t2) / (1 + t2)}: no real angle")
fy, gy = [[-1], [0, 1]], [[-2], [0, 1]]
Exy, at0 = det_perm(sylvester(fy, gy, [])), [show(trim([ev(c, 0) for c in p])) for p in (fy, gy)]
print(f"ct - 1 and ct - 2: Res_t = {show(Exy, 'c')}, zero at c = "
      f"{lst([x for x in range(-9, 10) if ev(Exy, x) == 0])}, where they read {at0[0]} and {at0[1]}")
wf, wg = [t for t in range(-9, 10) if ev(f, t) == 0], [t for t in range(-9, 10) if ev(g, t) == 0]
print(f"whole-number search t = -9..9: f {lst(wf)}; g {lst(wg)}; shared {lst([t for t in wf if t in wg])}")
assert det_rows(S) == 0 and fam                                    # two determinant roads agree
assert all((len(gcd(f, gear_b(c))) > 1) == (det_rows(sylvester(f, gear_b(c), 0)) == 0) for c in range(-10, 11))  # Euclid agrees
assert p9 == det_rows(sylvester(f, g9, 0)) == 425                  # product formula vs determinant
assert ev(f, t0) == 0 == ev(g, t0) and (5 * co, 10 * si) == (3, 8)
assert add(mul(A, f), mul(B, g)) == [] and rat_roots(E) == [-8, 8] and pyth == E   # Pythagoras vs the determinant
Ea, a, b2 = arm(4)
assert Ea == mul([-21, 8], [-21, 8]) and a * a + b2 == 9 and (a - 4) ** 2 + b2 == 4
assert Exy == [0, -1]
print("ALL CHECKS PASS")
