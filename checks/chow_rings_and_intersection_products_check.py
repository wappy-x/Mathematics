# The Chow ring: the check behind the card.  Standard library only.  Field: C for counts, F_101 for road 3.
# Road 1 multiplies classes in Z[H]/(H^3) and Z[a, b]/(a^2, b^2).  Road 2 eliminates y by a resultant
# and finds the roots, the ones at infinity included.  Road 3 tries every point over F_101.
from fractions import Fraction
from functools import reduce
from math import gcd
P = 101

def ring_mul(u, v, caps):                     # classes as {exponents: coefficient}; caps kill H^3, a^2, b^2
    r = {}
    for e, c in u.items():
        for f, d in v.items():
            k = tuple(i + j for i, j in zip(e, f))
            if all(k[i] < caps[i] for i in range(len(k))): r[k] = r.get(k, 0) + c * d
    return {k: c for k, c in r.items() if c}
def show(u, names):
    if not u: return "0"
    out = []
    for e in sorted(u, reverse=True):
        m = "".join(n + (f"^{p}" if p > 1 else "") for n, p in zip(names, e) if p)
        out.append(m if m and u[e] == 1 else f"{u[e]}{m}")
    return " + ".join(out)

def padd(p, q): return [(p[i] if i < len(p) else 0) + (q[i] if i < len(q) else 0) for i in range(max(len(p), len(q)))]
def pmul(p, q):                               # polynomials in x as coefficient lists, lowest power first
    r = [0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q): r[i + j] += a * b
    return r
def det(M):                                   # Laplace expansion along the first row
    if len(M) == 1: return M[0][0]
    tot = [0]
    for j in range(len(M)):
        t = pmul(M[0][j], det([row[:j] + row[j + 1:] for row in M[1:]]))
        tot = padd(tot, t if j % 2 == 0 else [-c for c in t])
    return tot
def ycoeffs(f, ey):                           # f as a polynomial in y of formal degree ey, top coefficient first
    out = []
    for j in range(ey, -1, -1):
        c = [0] * 5
        for (i, k), v in f.items():
            if k == j: c[i] += v
        out.append(c)
    return out
def resultant(f, ef, g, eg):                  # Sylvester determinant: zero exactly where f and g share a root y
    F, G, n = ycoeffs(f, ef), ycoeffs(g, eg), ef + eg
    rows = [[[0]] * i + F + [[0]] * (n - ef - 1 - i) for i in range(eg)]
    rows += [[[0]] * i + G + [[0]] * (n - eg - 1 - i) for i in range(ef)]
    r = det(rows)
    while len(r) > 1 and r[-1] == 0: r.pop()
    return r
def int_roots(r):                             # whole-number roots with multiplicity, by synthetic division
    found = []
    for x0 in range(-60, 61):
        while len(r) > 1:
            q, acc = [], 0
            for c in reversed(r): acc = acc * x0 + c; q.append(acc)
            if acc != 0: break
            r = list(reversed(q[:-1])); found.append(x0)
    return found, r

def fmt(r):                                   # made primitive, leading coefficient positive, leading term first
    g = reduce(gcd, r); r, out = [c // g * (1 if r[-1] > 0 else -1) for c in r], ""
    for k in range(len(r) - 1, -1, -1):
        if r[k] == 0: continue
        m = abs(r[k]); body = ("" if m == 1 and k else str(m)) + ("x" if k else "") + (f"^{k}" if k > 1 else "")
        out += (("-" if r[k] < 0 else "") if not out else (" - " if r[k] < 0 else " + ")) + body
    return out
def ev(f, home, X, Y, Z=1):                   # homogeneous value; X, Y are pairs (x0, x1) on P^1 x P^1
    if home == "P2": return sum(c * X**i * Y**j * Z**(f["d"] - i - j) for (i, j), c in f["t"].items())
    return sum(c * X[1]**i * X[0]**(f["dx"] - i) * Y[1]**j * Y[0]**(f["dy"] - j) for (i, j), c in f["t"].items())
def count_fp(f, g, home):                     # road 3: every point over F_101
    if home == "P2": pts = [(x, y, 1) for x in range(P) for y in range(P)] + [(x, 1, 0) for x in range(P)] + [(1, 0, 0)]
    else:
        line = [(1, x) for x in range(P)] + [(0, 1)]
        pts = [(X, Y) for X in line for Y in line]
    return [p for p in pts if ev(f, home, *p) % P == 0 and ev(g, home, *p) % P == 0]
def curve(t, **deg): return {"t": t, **deg}
C = curve({(1, 1): 1, (0, 0): -2}, dx=1, dy=1, d=2)                       # xy = 2
C2 = curve({(1, 1): 1, (1, 0): 1, (0, 1): -1, (0, 0): -3}, dx=1, dy=1, d=2)  # (x - 1)(y + 1) = 2
D = curve({(3, 0): 1, (1, 2): 21, (0, 3): -8, (1, 0): -21}, d=3)         # x^3 + 21xy^2 - 8y^3 - 21x = 0
Q = curve({(2, 0): 1, (1, 0): -4, (0, 0): -5, (1, 2): 5, (0, 2): 1, (0, 3): -2}, dx=2, dy=3)  # bidegree (2, 3)
AX = curve({(1, 1): 1}, dx=1, dy=1)                                       # the axes xy = 0
AX2 = curve({(1, 1): 1, (1, 0): -1, (0, 1): -1, (0, 0): 1}, dx=1, dy=1)  # (x - 1)(y - 1) = 0
CM = curve({(1, 1): 1, (0, 0): 2}, dx=1, dy=1)                            # xy = -2
L1 = curve({(1, 0): 1, (0, 1): 1, (0, 0): -2}, dx=1, dy=1)                # x + y = 2
L2 = curve({(1, 0): 1, (0, 1): 1, (0, 0): -1}, dx=1, dy=1)                # x + y = 1

H, a, b = {(1,): 1}, {(1, 0): 1}, {(0, 1): 1}
sc = lambda k, u: {e: k * c for e, c in u.items()}
add = lambda u, v: {e: u.get(e, 0) + v.get(e, 0) for e in set(u) | set(v) if u.get(e, 0) + v.get(e, 0)}
print("road 1, products in the Chow ring")
cc = ring_mul(sc(2, H), sc(3, H), (3,))
print(f"A(P^2) = Z[H]/(H^3): 2H x 3H = {show(cc, 'H')}; H x H x H = {show(ring_mul(ring_mul(H, H, (3,)), H, (3,)), 'H')}")
r11 = ring_mul(add(a, b), add(a, b), (2, 2)); r23 = ring_mul(add(sc(2, a), sc(3, b)), add(a, b), (2, 2))
print(f"A(P^1 x P^1) = Z[a, b]/(a^2, b^2): a x a = {show(ring_mul(a, a, (2, 2)), 'ab')}; (a + b)^2 = {show(r11, 'ab')}; "
      f"(2a + 3b)(a + b) = {show(r23, 'ab')}")
print(f"the same products in Z[a, b], no relations: (a + b)^2 = {show(ring_mul(add(a, b), add(a, b), (9, 9)), 'ab')}")

print(f"roads 2 and 3, the meeting points of real curves; road 3 tries all {(P + 1) ** 2} points of P^1 x P^1 over F_{P}")
cases = [("conic C and cubic D in P^2", C, 2, D, 3, "P2", cc[(2,)], [(1, 2, 1), (-1, -2, 1), (2, 1, 1), (-2, -1, 1), (8, 1, 2), (-8, -1, 2)]),
         ("C and C' in P^1 x P^1", C, 1, C2, 1, "P11", r11[(1, 1)], [((1, 2), (1, 1)), ((1, -1), (1, -2))]),
         ("axes xy = 0 and (x - 1)(y - 1) = 0", AX, 1, AX2, 1, "P11", r11[(1, 1)], [((1, 0), (1, 1)), ((1, 1), (1, 0))]),
         ("(2, 3)-curve Q and C", Q, 3, C, 1, "P11", r23[(1, 1)],
          [((1, 1), (1, 2)), ((1, -1), (1, -2)), ((1, 2), (1, 1)), ((1, -2), (1, -1)), ((1, 4), (2, 1))]),
         ("xy = 2 and xy = -2", C, 1, CM, 1, "P11", r11[(1, 1)], [((1, 0), (0, 1)), ((0, 1), (1, 0))]),
         ("xy = 2 and x + y = 1", C, 1, L2, 1, "P11", r11[(1, 1)], []),
         ("xy = 1 and x + y = 2", curve({(1, 1): 1, (0, 0): -1}, dx=1, dy=1), 1, L1, 1, "P11", r11[(1, 1)], [((1, 1), (1, 1))])]
res = {}
for name, f, ef, g, eg, home, want, pts in cases:
    R = resultant(f["t"], ef, g["t"], eg); N = f["d"] * g["d"] if home == "P2" else f["dx"] * eg + g["dx"] * ef
    roots, rest = int_roots(R); inf = N - (len(R) - 1); fp = count_fp(f, g, home)
    tail = f", rest has discriminant {rest[1]**2 - 4 * rest[0] * rest[2]}" if len(rest) == 3 else ""
    print(f"{name}: ring {want}; R(x) = {fmt(R)}, degree {N}: whole roots {roots}{tail}, at infinity {inf}; over F_{P} {len(fp)}")
    assert all(ev(f, home, *p) == 0 and ev(g, home, *p) == 0 for p in pts)   # each claimed point, put back exactly
    res[name] = (want, roots, inf, rest, fp)
sg = lambda v: str(v - P if v > P // 2 else v); P2fake = sorted(count_fp(C, C2, "P2"), key=lambda p: (-p[2], p))
print(f"mistake 1, C and C' counted in P^2: 2 x 2 = {len(P2fake)} points: " + ", ".join("(" + " : ".join(map(sg, p)) + ")" for p in P2fake))
aff = lambda X: "inf" if X[0] == 0 else sg(X[1])
far = res["xy = 2 and xy = -2"][4]; fin = [p for p in far if p[0][0] and p[1][0]]
print(f"mistake 2, xy = 2 and xy = -2 in the plane only: {len(fin)} points; in P^1 x P^1: " + ", ".join(f"({aff(X)}, {aff(Y)})" for X, Y in far))
rest = res["xy = 2 and x + y = 1"][3]
print(f"mistake 3, xy = 2 and x + y = 1 over R: x^2 - x + 2 has discriminant {rest[1]**2 - 4 * rest[0] * rest[2]}, so 0 points; over C 2")
print(f"mistake 4, xy = 1 and x + y = 2 without multiplicity: {len(set(res['xy = 1 and x + y = 2'][1]))} point, the double root x = 1")
cone, line = {(1, 0, 1): 1, (0, 2, 0): -1}, ([-1, 1], [0], [-2, 1])   # xz - y^2 by powers of (x, y, z); the line (s - 1 : 0 : s - 2 : s)
cs = reduce(padd, [reduce(pmul, [line[k] for k in range(3) for _ in range(e[k])], [c]) for e, c in cone.items()])  # the cone on the line
(m,), croots = [e[1] for e in cone if e[0] == 0], int_roots(cs)[0]; HH = len(croots); LL = Fraction(HH, m * m)  # x = 0 leaves -y^m: H = mL
print(f"cone xz = y^2 in P^3: plane x = 0 leaves y^{m} = 0, so H = {m}L; the line (s - 1 : 0 : s - 2 : s) meets it where "
      f"{fmt(cs).replace('x', 's')} = 0, at s = {croots}, so H.H = {HH} and L.L = {HH}/{m * m} = {LL}")
print("figure, C: xy = 2 and C': (x - 1)(y + 1) = 2 meet at (2, 1) and (-1, -2); asymptotes x = 0, y = 0, x = 1, y = -1; window -5..5")
assert cc == {(2,): 6} and ring_mul(ring_mul(H, H, (3,)), H, (3,)) == {}                     # ring arithmetic
assert r11 == {(1, 1): 2} and r23 == {(1, 1): 5}
for name, (want, roots, inf, rest, fp) in res.items():
    if name.startswith("xy = 2 and x + y"): assert len(rest) == 3 and len(roots) == 0 and len(fp) == 0
    else: assert len(roots) + inf == want                                    # resultant roots against the ring
    if name.startswith(("conic", "C and", "axes", "(2, 3)", "xy = 2 and xy")): assert len(fp) == want  # F_101 against the ring
assert sorted(res["conic C and cubic D in P^2"][1]) == [-4, -2, -1, 1, 2, 4] and res["conic C and cubic D in P^2"][2] == 0
assert len(P2fake) == 4 and ((1, 0, 0) in P2fake) and ((0, 1, 0) in P2fake)
assert LL == Fraction(1, 2) and res["xy = 2 and xy = -2"][2] == 1 and res["xy = 1 and x + y = 2"][1] == [1, 1]
print("ALL CHECKS PASS")
