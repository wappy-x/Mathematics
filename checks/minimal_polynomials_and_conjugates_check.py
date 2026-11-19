# Minimal polynomials -- the check behind the card.  Standard library only.
# A number in Q(a), a = 2^(1/4), is four fractions [c0, c1, c2, c3], meaning
# c0 + c1 a + c2 a^2 + c3 a^3; multiplying uses a^4 = 2.  Road 1 finds a minimal
# polynomial exactly, as the first power that is a mix of lower powers.  Road 2
# multiplies (x - c) over the conjugates c as complex numbers and rounds.
from fractions import Fraction as F
import math

def mul(u, v):
    w = [F(0)] * 7
    for i in range(4):
        for j in range(4):
            w[i + j] += u[i] * v[j]
    return [w[k] + (2 * w[k + 4] if k < 3 else 0) for k in range(4)]

def solve(cols, t):  # coefficients c with sum c[j] cols[j] = t, or None
    k = len(cols)
    m = [[cols[j][r] for j in range(k)] + [t[r]] for r in range(4)]
    piv, row = [], 0
    for c in range(k):
        p = next((r for r in range(row, 4) if m[r][c] != 0), None)
        if p is None:
            continue
        m[row], m[p] = m[p], m[row]
        m[row] = [x / m[row][c] for x in m[row]]
        for r in range(4):
            if r != row and m[r][c] != 0:
                m[r] = [x - m[r][c] * y for x, y in zip(m[r], m[row])]
        piv.append(c); row += 1
    if any(m[r][k] != 0 for r in range(row, 4)):
        return None
    sol = [F(0)] * k
    for r, c in enumerate(piv):
        sol[c] = m[r][k]
    return sol

def minpoly(v):  # monic coefficients, constant term first
    pw = [[F(1), F(0), F(0), F(0)]]
    while True:
        nxt = mul(pw[-1], v)
        c = solve(pw, nxt)
        if c is not None:
            return [-x for x in c] + [F(1)]
        pw.append(nxt)

def from_roots(rs):
    p = [complex(1)]
    for r in rs:
        p = [(p[k - 1] if k > 0 else 0) - r * (p[k] if k < len(p) else 0) for k in range(len(p) + 1)]
    return p

def show(p):
    t = [(c, ("" if abs(c) == 1 and k else str(abs(c))) + ("x" if k else "") + (f"^{k}" if k > 1 else ""))
         for k, c in reversed(list(enumerate(p))) if c]
    return ("-" if t[0][0] < 0 else "") + t[0][1] + "".join((" - " if c < 0 else " + ") + w for c, w in t[1:])

def horner(p, x):
    y = 0
    for c in reversed(p):
        y = y * x + c
    return y

def eisenstein(p, q):
    return p[-1] % q != 0 and all(c % q == 0 for c in p[:-1]) and p[0] % (q * q) != 0

al = math.sqrt(math.sqrt(2))
conj = [al, 1j * al, -al, -1j * al]
cl = lambda x: 0.0 if abs(x) < 5e-10 else x
fmt = lambda z: f"{cl(z.real):+.6f} {cl(z.imag):+.6f}i"
print(f"a = 2^(1/4) = {al:.11f}")
print(f"A0 paper: long side 2^(1/4) m = {1000 * al:.0f} mm, short side 2^(-1/4) m = {1000 / al:.0f} mm")
A = [F(0), F(1), F(0), F(0)]
elems = [("a", A, lambda t: t), ("a^2", mul(A, A), lambda t: t * t),
         ("b = a + a^2", [F(0), F(1), F(1), F(0)], lambda t: t + t * t)]
pw = [[F(1), F(0), F(0), F(0)]]
for _ in range(4):
    pw.append(mul(pw[-1], elems[2][1]))
print("powers of b over 1, a, a^2, a^3: " + "; ".join(f"b^{k} {[int(c) for c in v]}" for k, v in enumerate(pw)))
polys = {}
for name, v, f in elems:
    m = [int(c) for c in minpoly(v)]
    vals = [f(c) for c in conj]
    distinct = []
    for z in vals:
        if all(abs(z - d) > 1e-9 for d in distinct):
            distinct.append(z)
    q = from_roots(distinct)
    road2 = [round(c.real) for c in q]
    err = max(abs(c - r) for c, r in zip(q, road2))
    print(f"{name}: road 1 {show(m)}, degree {len(m) - 1}; road 2 {show(road2)}, within 1e-9: {err < 1e-9}")
    print("  conjugates: " + ", ".join(fmt(z) for z in distinct))
    assert m == road2 and err < 1e-9, "the two roads must agree"
    polys[name] = (m, distinct)
b = al + al * al
mb = polys["b = a + a^2"][0]
print(f"b = {b:.11f}; b^4 - 4b^2 - 8b + 2 = {cl(horner(mb, b)):.9f}")
print(f"sum of b's conjugates {cl(sum(polys['b = a + a^2'][1]).real):+.6f}, product {from_roots(polys['b = a + a^2'][1])[0].real:+.6f}")
m3 = [3 * c for c in polys["a"][0]]
print(f"drop monic: {show(m3)} at a: {cl(horner(m3, al)):.9f}; made monic: {show([c // m3[-1] for c in m3])}")
f4 = [-2, 0, 0, 0, 1]
print("rational root test, x^4 - 2 at 1, -1, 2, -2:", [horner(f4, r) for r in (1, -1, 2, -2)])
def pair_search(rs, loud):  # how many pairs of roots give a whole-number quadratic factor
    ints = 0
    for i, j in [(i, j) for i in range(4) for j in range(i + 1, 4)]:
        s, p = -(rs[i] + rs[j]), rs[i] * rs[j]
        whole = all(abs(z - round(z.real)) < 1e-9 for z in (s, p))
        ints += whole
        if loud: print(f"  roots {i},{j}: x^2 + ({fmt(s)})x + ({fmt(p)})  whole: {whole}")
    return ints
ints = pair_search(conj, True)
e4, eb = eisenstein(f4, 2), eisenstein(mb, 2)
print(f"Eisenstein at 2: x^4 - 2 {e4}, {show(mb)} {eb}; whole-number quadratic factors found: {ints}")
g4, r44 = [4, 0, 0, 0, 1], [1 + 1j, 1 - 1j, -1 + 1j, -1 - 1j]
e44, i44 = eisenstein(g4, 2), pair_search(r44, False)
print(f"control, x^4 + 4: Eisenstein at 2 {e44}; whole-number quadratic factors found: {i44}")
assert (e4, eb, ints) == (True, True, 0) and (e44, i44) == (False, 2), "both tests must say yes and no"
assert len(polys["a^2"][1]) == 2 and polys["a^2"][0] == [-2, 0, 1], "a^2 has degree 2, two conjugates"
z8 = complex(math.cos(math.pi / 4), math.sin(math.pi / 4)) * al
print(f"x^8 - 4 at a: {cl(horner([-4, 0, 0, 0, 0, 0, 0, 0, 1], al)):.9f}; its root e^(i pi/4) a into x^4 - 2: {fmt(horner(f4, z8))}")
fac = [round(c.real) for c in from_roots(r44)]
print("x^4 + 4 at 1, -1, 2, -2, 4, -4:", [horner(g4, r) for r in (1, -1, 2, -2, 4, -4)],
      f"yet (x^2 + 2x + 2)(x^2 - 2x + 2) = {show(fac)}")
assert fac == g4, "x^4 + 4 factors with no rational root"
r2 = math.sqrt(2)
print("over Q(root 2), x^2 - root 2 at a, -a, ia:", ", ".join(fmt(complex(z * z - r2)) for z in (al, -al, 1j * al)))
best, arg, n = 1e9, None, 0
for c in range(11 ** 5):
    p = [(c // 11 ** k) % 11 - 5 for k in range(5)]
    if any(p):
        n += 1
        v = abs(horner(p, math.pi))
        if v < best:
            best, arg = v, p
print(f"pi: {n} integer polynomials, degree <= 4, coefficients -5..5; smallest |p(pi)| = {best:.6e} at {show(arg)}")
direct = abs(3 - 4 * math.pi + 5 * math.pi ** 2 + 5 * math.pi ** 3 - 2 * math.pi ** 4)
assert n == 11 ** 5 - 1 and arg == [3, -4, 5, 5, -2] and abs(best - direct) < 1e-12, "the search must cover the box"
assert best > 1e-6, "no small polynomial vanishes at pi"
print("ALL CHECKS PASS")
