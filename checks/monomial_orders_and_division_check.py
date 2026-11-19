# Monomial orders and division -- the check behind the card.  Standard library
# only; Fraction is exact arithmetic, nothing more.  Field: Q, the rationals.
# A monomial x^a y^b z^c is the exponent triple (a, b, c); a polynomial is a
# dict from triples to coefficients.  The division is written out below.
from fractions import Fraction as Q

KEYS = {"lex": lambda m: (m[0], m[1], m[2]),                 # road one: sort keys
        "grlex": lambda m: (sum(m), m[0], m[1], m[2]),
        "grevlex": lambda m: (sum(m), -m[2], -m[1], -m[0]),
        "bad": lambda m: (-sum(m), m[0], m[1], m[2]),       # 1 ranks highest
        "skew": lambda m: (2 * sum(m) + 3 * (sum(m) == 2), m[0], m[1], m[2])}  # degree 2 between 3 and 4

def bigger(order, p, q):                    # road two: the rules, read in words
    d = [p[i] - q[i] for i in range(3)]
    if order != "lex" and sum(d) != 0:
        return sum(d) > 0                   # graded: total degree decides first
    nz = [v for v in d if v != 0]
    if not nz:
        return False
    return nz[0] > 0 if order != "grevlex" else nz[-1] < 0

def mono(m): return "".join(v + ("^" + str(e) if e > 1 else "") for v, e in zip("xyz", m) if e) or "1"

def show(f, order="lex"):
    out = ""
    for m in sorted(f, key=KEYS[order], reverse=True):
        c, t = f[m], mono(m)
        a = abs(c)
        body = (str(a) if a != 1 or t == "1" else "") + ("" if t == "1" else t)
        out += ("-" if c < 0 else "") + body if not out else (" - " if c < 0 else " + ") + body
    return out or "0"

def P(*terms):                              # P((coef, (a, b, c)), ...)
    f = {}
    for c, m in terms:
        f[m] = f.get(m, 0) + Q(c)
    return {m: c for m, c in f.items() if c != 0}

def add(f, g, s=1):
    return P(*[(c, m) for m, c in f.items()], *[(s * c, m) for m, c in g.items()])

def mul(f, g):
    return P(*[(c * d, tuple(i + j for i, j in zip(m, n))) for m, c in f.items() for n, d in g.items()])

def lt(f, order): return max(f, key=KEYS[order])

def divide(f, fs, order, max_steps=10**6, trace=None):
    qs, r, p, steps = [{} for _ in fs], {}, dict(f), 0
    while p and steps < max_steps:
        steps += 1
        m = lt(p, order)
        for i, g in enumerate(fs):
            n = lt(g, order)
            if all(a >= b for a, b in zip(m, n)):          # LT(g) divides LT(p)
                t = {tuple(a - b for a, b in zip(m, n)): p[m] / g[n]}
                s = f"{show({m: p[m]})} = {show(t)} * {show({n: g[n]})}"
                qs[i], p = add(qs[i], t), add(p, mul(t, g), -1)
                if trace is not None:
                    trace.append(f"{s}, left {show(p, order)}")
                break
        else:                                              # stuck: move it to r
            if trace is not None:
                trace.append(f"{show({m: p[m]})} fits no divisor: to the remainder")
            r, p = add(r, {m: p[m]}), add(p, {m: p[m]}, -1)
    return qs, r, p

def at(f, x, y):
    return sum(c * Q(x) ** m[0] * Q(y) ** m[1] for m, c in f.items())

def yn(b): return "yes" if b else "no"
def ranked(ms, order):
    return " > ".join(mono(m) for m in sorted(ms, key=KEYS[order], reverse=True))

X, Y, ONE = (1, 0, 0), (0, 1, 0), (0, 0, 0)
box = [(a, b, c) for a in range(4) for b in range(4) for c in range(4) if a + b + c <= 3]
tri = [(0, 3, 0), (1, 0, 2), (2, 0, 0)]
deg2 = [m for m in box if sum(m) == 2]
two = [m for m in box if m[2] == 0 and sum(m) <= 2]
def rules(o):                               # brute force on the 20 monomials
    mult = all(KEYS[o](tuple(i + k for i, k in zip(p, g))) > KEYS[o](tuple(j + k for j, k in zip(q, g)))
               for p in box for q in box for g in box if KEYS[o](p) > KEYS[o](q))
    return mult, all(KEYS[o](m) > KEYS[o](ONE) for m in box if m != ONE)
print(f"field Q; {len(box)} monomials of degree <= 3 in x > y > z")
for o in ("lex", "grlex", "grevlex"):
    agree = all(bigger(o, p, q) == (KEYS[o](p) > KEYS[o](q)) for p in box for q in box)
    mult, least = rules(o)
    print(f"{o}: rules = sort key {yn(agree)}; respects multiplying {yn(mult)}; 1 smallest {yn(least)}")
    assert agree and mult and least
    print(f"  {' + '.join(map(mono, tri))} leads with {mono(lt(P(*[(1, m) for m in tri]), o))}; degree 2: {ranked(deg2, o)}")
    print(f"  in x, y up to degree 2: {ranked(two, o)}")
for o, why in (("bad", "lower degree ranks higher"), ("skew", "degree 2 ranked between 3 and 4")):
    print(f"{o} order ({why}): respects multiplying {yn(rules(o)[0])}; 1 smallest {yn(rules(o)[1])}")
f, g = P((1, (2, 1, 0)), (1, X)), P((1, (1, 1, 0)), (-1, ONE))
(q,), r, _ = divide(f, [g], "lex", trace=(tr := []))
print(f"divide {show(f)} by {show(g)}, lex:")
for i, s in enumerate(tr):
    print(f"  step {i + 1}: {s}")
same = all(divide(f, [g], o)[:2] == ([q], r) for o in ("grlex", "grevlex"))
print(f"  quotient {show(q)}, remainder {show(r)}; same in grlex and grevlex: {yn(same)}")
print(f"  rebuilt {show(q)}*({show(g)}) + {show(r)} = {show(add(mul(q, g), r))}")
print(f"  at x = 4/5, y = 5/4: xy = {at(g, '4/5', '5/4') + 1}, f = {at(f, '4/5', '5/4')}, remainder = {at(r, '4/5', '5/4')}")
assert add(mul(q, g), r) == f and at(f, "4/5", "5/4") == at(r, "4/5", "5/4") == Q(8, 5)
h, f1, f2 = P((1, (2, 1, 0)), (1, (1, 2, 0)), (1, (0, 2, 0))), g, P((1, (0, 2, 0)), (-1, ONE))
rems = []
for name, fs in (("(xy - 1, y^2 - 1)", [f1, f2]), ("(y^2 - 1, xy - 1)", [f2, f1])):
    qs, r, _ = divide(h, fs, "lex", trace=(tr := []))
    print(f"divide {show(h)} by {name}, lex:")
    for i, s in enumerate(tr):
        print(f"  step {i + 1}: {s}")
    back = add(add(mul(qs[0], fs[0]), mul(qs[1], fs[1])), r)
    vals = [(at(h, *pt), at(r, *pt)) for pt in ((1, 1), (-1, -1))]
    print(f"  quotients {show(qs[0])} and {show(qs[1])}, remainder {show(r)}; rebuilt: {yn(back == h)}")
    print(f"  f and remainder at (1, 1): {vals[0][0]}, {vals[0][1]}; at (-1, -1): {vals[1][0]}, {vals[1][1]}")
    assert back == h and all(a == b for a, b in vals)
    assert all(not all(a >= b for a, b in zip(m, lt(d, "lex"))) for m in r for d in fs)
    rems.append(r)
diff = add(rems[0], rems[1], -1)
combo = add(mul(P((1, X)), f2), mul(P((1, Y)), f1), -1)
print(f"remainders differ by {show(diff)} = x(y^2 - 1) - y(xy - 1): {yn(diff == combo)}")
assert rems[0] == P((1, X), (1, Y), (1, ONE)) and rems[1] == P((2, X), (1, ONE)) and diff == combo
qs, r, _ = divide(combo, [f1, f2], "lex")
print(f"mistake, -x + y is in the ideal yet its remainder is {show(r)}")
assert r == combo != {}
print(f"mistake, stopping at the first stuck term leaves {show(add(h, mul(P((1, X), (1, Y)), f1), -1))}")
par, x2 = P((1, X), (-1, (0, 2, 0))), P((1, (2, 0, 0)))
for o in ("lex", "grlex"):
    qs, r, _ = divide(x2, [par], o)
    print(f"mistake, x^2 by x - y^2 in {o}: leading term {show({lt(par, o): par[lt(par, o)]})}, "
          f"remainder {show(r, o)}, at x = 9, y = 3: {at(r, 9, 3)}")
    assert add(mul(qs[0], par), r) == x2 and at(r, 9, 3) == 81
qs, r, p = divide(P((1, ONE)), [P((1, ONE), (-1, X))], "bad", max_steps=10)
print(f"mistake, 1 by 1 - x with 1 ranked highest, 10 steps: quotient {show(qs[0], 'bad')}, left {show(p)}")
assert p == P((1, (10, 0, 0))) and len(qs[0]) == 10 and rules("bad") == (True, False)
left = [divide(P((1, (4, 0, 0))), [P((1, (2, 0, 0)), (1, (3, 0, 0)))], "skew", max_steps=k)[2] for k in range(1, 6)]
print(f"mistake, x^4 by x^2 + x^3 in the skew order, steps 1 to 5 leave {', '.join(show(p) for p in left)}")
assert left[4] == P((-1, (9, 0, 0))) and rules("skew") == (False, True)
pts = lambda ms: " ".join(f"({m[0]},{m[1]})" for m in sorted(ms, key=KEYS["lex"], reverse=True))
print(f"figure, staircase corners {pts([lt(f1, 'lex'), lt(f2, 'lex')])}; f terms {pts(h)}; remainder terms {pts(rems[0])}")
print("ALL CHECKS PASS")
