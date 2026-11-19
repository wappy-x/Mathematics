# The Nullstellensatz -- the check behind the card.  Standard library only.
# Polynomials are dicts {(ex, ey, ez): Fraction}, in x > y > z.  Certificates
# are checked by expanding them exactly, found by solving a linear system,
# and cross-checked against points counted over the small fields F_p.
from fractions import Fraction as Q
from itertools import product

def P(*terms):                          # P((c, (ex, ey, ez)), ...)
    out = {}
    for c, m in terms:
        out[m] = out.get(m, 0) + Q(c)
    return {m: c for m, c in out.items() if c != 0}

def add(f, g):
    return P(*[(c, m) for m, c in f.items()], *[(c, m) for m, c in g.items()])

def mul(f, g):
    return P(*[(a * b, tuple(i + j for i, j in zip(m, n)))
               for m, a in f.items() for n, b in g.items()])

def combo(mults, gens):                 # a1*f1 + a2*f2 + ...
    out = {}
    for a, f in zip(mults, gens):
        out = add(out, mul(a, f))
    return out

def show(f, names="xyz"):               # leading term first, fractions in lowest terms
    s = ""
    for m in sorted(f, reverse=True):
        c = f[m]
        mono = "".join(v + (f"^{e}" if e > 1 else "") for v, e in zip(names, m) if e)
        a = abs(c)
        body = str(a) if not mono else mono if a == 1 else (
            f"{a}{mono}" if a.denominator == 1 else f"({a}){mono}")
        s += ("-" if c < 0 else "") + body if not s else (" - " if c < 0 else " + ") + body
    return s or "0"

def monos(n, d):                        # exponents with total degree <= d, n variables
    return [m + (0,) * (3 - n) for m in product(range(d + 1), repeat=n) if sum(m) <= d]

def search(gens, target, n, d):         # solve target = sum a_i g_i, deg a_i <= d
    cols = [(i, m) for i in range(len(gens)) for m in monos(n, d)]
    prods = [mul({m: Q(1)}, gens[i]) for i, m in cols]
    keys = sorted(set(target).union(*prods))
    rows = [[p.get(k, Q(0)) for p in prods] + [target.get(k, Q(0))] for k in keys]
    piv, r = [], 0
    for c in range(len(cols)):          # Gauss-Jordan elimination, written out
        k = next((i for i in range(r, len(rows)) if rows[i][c] != 0), None)
        if k is None:
            continue
        rows[r], rows[k] = rows[k], rows[r]
        rows[r] = [v / rows[r][c] for v in rows[r]]
        for i in range(len(rows)):
            if i != r and rows[i][c] != 0:
                rows[i] = [a - rows[i][c] * b for a, b in zip(rows[i], rows[r])]
        piv.append(c)
        r += 1
    if any(row[-1] != 0 for row in rows[r:]):
        return None                     # inconsistent: no certificate at this degree
    mults = [{} for _ in gens]
    for i, c in enumerate(piv):
        mults[cols[c][0]] = add(mults[cols[c][0]], {cols[c][1]: rows[i][-1]})
    return mults

def none(r):
    return "no certificate at this degree" if r is None else "found"

def count(gens, p):                     # common zeros in F_p x F_p
    ev = lambda f, x, y: sum(int(c) * x**m[0] * y**m[1] for m, c in f.items()) % p
    return [(x, y) for x in range(p) for y in range(p) if all(ev(f, x, y) == 0 for f in gens)]

X, Y, Z, ONE = P((1, (1, 0, 0))), P((1, (0, 1, 0))), P((1, (0, 0, 1))), P((1, (0, 0, 0)))
primes = [2, 3, 5, 7]
F = [P((1, (1, 1, 0)), (-1, (0, 0, 0))), X]                   # x y - 1, x
print(f"system 1, over C: {show(F[0])} = 0 and {show(F[1])} = 0")
hand = combo([P((-1, (0, 0, 0))), Y], F)
print(f"road 1, the certificate by hand: (-1)({show(F[0])}) + (y)({show(F[1])}) = {show(hand)}")
print(f"road 2, search with constant multipliers: {none(search(F, ONE, 2, 0))}")
found = search(F, ONE, 2, 1)
print(f"road 2, search with degree-1 multipliers: a1 = {show(found[0])}, a2 = {show(found[1])}")
print(f"road 2, expanded: {show(combo(found, F))}")
pts1 = [len(count(F, p)) for p in primes]
print(f"road 3, common zeros over F_p for p = {primes}: {pts1}")
print(f"sign slip: (1)({show(F[0])}) + (y)({show(F[1])}) = {show(combo([ONE, Y], F))}")
G = [P((1, (0, 1, 0)), (-1, (2, 0, 0))), Y]                   # y - x^2, y
print(f"system 2, over C: {show(G[0])} = 0 and {show(G[1])} = 0")
pts2 = [count(G, p) for p in primes]
print(f"common zeros over F_p for p = {primes}: {[len(s) for s in pts2]}, all at (0, 0): "
      f"{'yes' if all(s == [(0, 0)] for s in pts2) else 'no'}")
kill = lambda f: {m: c for m, c in f.items() if m[1] == 0 and m[0] < 2}   # y -> 0, x^2 -> 0
print(f"the test map (y -> 0, then x^2 -> 0) sends the generators to {show(kill(G[0]))}, "
      f"{show(kill(G[1]))} and x to {show(kill(X))}")
print(f"search for x = a1 g1 + a2 g2, degree <= 3: {none(search(G, X, 2, 3))}")
sq = search(G, mul(X, X), 2, 0)
print(f"x^2 = ({show(sq[0])})({show(G[0])}) + ({show(sq[1])})({show(G[1])})")
R = G + [P((1, (0, 0, 0)), (-1, (1, 0, 1)))]                   # add 1 - x z
cert = search(R, ONE, 3, 2)
print(f"Rabinowitsch: 1 = sum a_i g_i with g3 = {show(R[2])}:")
for i in range(3):
    print(f"  a{i + 1} = {show(cert[i])}")
print(f"  expanded: {show(combo(cert, R))}")
m = max(k[2] for a in cert[:2] for k in a)                     # highest power of z
back = [P(*[(c, (k[0] + m - k[2], k[1], 0)) for k, c in a.items()]) for a in cert[:2]]
print(f"put z = 1/x, multiply by x^{m}: x^{m} = ({show(back[0])})({show(G[0])}) + "
      f"({show(back[1])})({show(G[1])}), expanded {show(combo(back, G))}")
H = [P((1, (2, 0, 0)), (1, (0, 0, 0)))]                       # x^2 + 1
gi = lambda f: tuple(int(sum(c * t[k[0] % 4] for k, c in f.items())) for t in ((1, 0, -1, 0), (0, 1, 0, -1)))   # f at x = i: i^e runs 1, i, -1, -i
print(f"break 1: {show(H[0])} at x = i gives {gi(H[0])}; search for 1, degree <= 4: "
      f"{none(search(H, ONE, 1, 4))}")
print(f"break 1: zeros of {show(H[0])} over F_p for p = {primes}: "
      f"{[len([x for x in range(p) if (x * x + 1) % p == 0]) for p in primes]}")
real1 = add(mul(X, X), mul(P((-1, (0, 0, 0))), H[0]))
print(f"break 1, real certificate: x^2 + (-1)({show(H[0])}) = {show(real1)}")
arm = lambda p: [P((1, (2, 0, 0)), (1, (0, 2, 0)), (-9, (0, 0, 0))),
                 P((1, (2, 0, 0)), (-2 * p, (1, 0, 0)), (1, (0, 2, 0)), (p * p - 4, (0, 0, 0)))]
A6 = arm(6)
print(f"break 2, arm aimed 6 m away: {show(A6[0], 'ab')} = 0 and {show(A6[1], 'ab')} = 0")
a6 = Q(41, 12); b6sq = 9 - a6 * a6
print(f"break 2, elbow a = {a6}, b^2 = {b6sq}; reach checks {a6 * a6 + b6sq} and "
      f"{(a6 - 6) ** 2 + b6sq}")
lin = add(A6[0], mul(P((-1, (0, 0, 0))), A6[1]))
sos = P((Q(144, 385), (0, 2, 0)))
shift = P((Q(1, 12), (1, 0, 0)), (Q(41, 144), (0, 0, 0)))      # (a + 41/12)/12
inI = add(A6[0], mul(P((-1, (0, 0, 0))), mul(shift, lin)))     # b^2 + 385/144
real2 = add(sos, mul(P((Q(-144, 385), (0, 0, 0))), inI))
print(f"break 2: {show(A6[0], 'ab')} - ({show(A6[1], 'ab')}) = {show(lin, 'ab')}; "
      f"in the ideal: {show(inI, 'ab')}")
print(f"break 2, real certificate: {show(sos, 'ab')} - (144/385)({show(inI, 'ab')}) = {show(real2, 'ab')}")
a4 = Q(21, 8); b4sq = 9 - a4 * a4
print(f"arm at 4 m: elbow a = {a4}, b^2 = {b4sq}, b = +-{float(b4sq) ** 0.5:.6f} m")
print("figure, hyperbola xy = 1 through", " ".join(f"({t}, {1 / t})" for t in map(Q, [0.25, 0.5, 1, 2, 4])))
print("figure, parabola y = x^2 through", " ".join(f"({t}, {t * t})" for t in [-2, -1, 0, 1, 2]),
      "and the line y = 0, meeting at (0, 0)")
assert hand == ONE and combo(found, F) == ONE                  # two certificates, expanded
assert search(F, ONE, 2, 0) is None and pts1 == [0, 0, 0, 0]  # no point anywhere we can count
assert kill(G[0]) == {} and kill(G[1]) == {} and kill(X) == X  # x is not in <y - x^2, y>
assert combo(cert, R) == ONE and combo(back, G) == mul(X, X) and m == 2
assert gi(H[0]) == (0, 0) and real1 == P((-1, (0, 0, 0))) and real2 == P((-1, (0, 0, 0)))
assert (a6 - 6) ** 2 + b6sq == 4 and (a4 - 4) ** 2 + b4sq == 4 and b6sq < 0 < b4sq
print("ALL CHECKS PASS")
