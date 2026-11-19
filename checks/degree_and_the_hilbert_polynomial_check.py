# Degree and the Hilbert polynomial -- the check behind the card.
# Standard library only.  Fraction keeps every rank exact over Q.  The twisted cubic
# (u, u^2, u^3) is the projective curve (x : y : z : w) = (a^2 b : a b^2 : b^3 : a^3).
# Road 1: HF(t) = monomials of degree t minus the rank of the ideal's degree-t part.
# Road 2: substitute the curve and count the distinct monomials a^i b^j it reaches.
# Road 3: count standard monomials, those outside the leading terms x^2, xy, y^2.
# Then planes slice the curve, and Hilbert polynomials are fitted and read.
from fractions import Fraction as Q
from math import comb, factorial
def monos(n, t):
    if n == 1: return [(t,)]
    return [(a,) + r for a in range(t, -1, -1) for r in monos(n - 1, t - a)]
def grevlex(e): return (sum(e), tuple(-c for c in reversed(e)))
def deg(p): return sum(next(iter(p)))
def times(p, m): return {tuple(a + b for a, b in zip(e, m)): c for e, c in p.items()}
def pivots(cols, rows):            # exact row reduction; returns the leading columns
    rows, piv = [r[:] for r in rows], []
    for j in range(len(cols)):
        k = next((i for i in range(len(piv), len(rows)) if rows[i][j]), None)
        if k is None: continue
        r = len(piv); rows[r], rows[k] = rows[k], rows[r]
        for i in range(r + 1, len(rows)):
            if rows[i][j]:
                f = rows[i][j] / rows[r][j]
                rows[i] = [a - f * b for a, b in zip(rows[i], rows[r])]
        piv.append(cols[j])
    return piv
def ideal_piece(gens, n, t):        # the degree-t part of the ideal, columns in grevlex order
    cols = sorted(monos(n, t), key=grevlex, reverse=True)
    rows = [times(g, m) for g in gens if deg(g) <= t for m in monos(n, t - deg(g))]
    return cols, pivots(cols, [[Q(r.get(c, 0)) for c in cols] for r in rows])
def hf(gens, n, t): cols, piv = ideal_piece(gens, n, t); return len(cols) - len(piv)
def fit(ts, vs):                   # Lagrange interpolation, power basis, lowest degree first
    out = [Q(0)] * len(ts)
    for ti, vi in zip(ts, vs):
        b, den = [Q(1)], Q(1)
        for tj in ts:
            if tj != ti:
                b = [(b[k - 1] if k else 0) - tj * (b[k] if k < len(b) else 0) for k in range(len(b) + 1)]
                den *= ti - tj
        out = [o + vi * c / den for o, c in zip(out, b)]
    while len(out) > 1 and out[-1] == 0: out.pop()
    return out
def show(p):
    s = ""
    for k in range(len(p) - 1, -1, -1):
        c = p[k]
        if c == 0: continue
        a = abs(c); num = "" if (a == 1 and k) else (str(a) if a.denominator == 1 else f"({a})")
        s += (" - " if c < 0 else " + ") + num + ("t^%d" % k if k > 1 else "t" if k == 1 else "")
    s = s[3:] if s.startswith(" + ") else "-" + s[3:]
    return s or "0"
def at(p, t): return sum(c * t ** k for k, c in enumerate(p))
X2, XY, Y2 = {(2, 0, 0, 0): 1, (0, 1, 0, 1): -1}, {(1, 1, 0, 0): 1, (0, 0, 1, 1): -1}, {(0, 2, 0, 0): 1, (1, 0, 1, 0): -1}
TC = [X2, XY, Y2]
def image(e): return (2 * e[0] + e[1] + 3 * e[3], e[0] + 2 * e[1] + 3 * e[2])   # x^p y^q z^r w^s -> a^i b^j
print("twisted cubic (u, u^2, u^3) = (x : y : z : w) = (a^2 b : a b^2 : b^3 : a^3); field Q, counts as over C")
vanish = all(sum(c for e, c in g.items() if image(e) == im) == 0 for g in TC for im in map(image, g))
print(f"equations x^2 - yw, xy - zw, y^2 - xz; each vanishes on the curve: {'yes' if vanish else 'no'}")
print("t | monomials | ideal I_t | HF = monomials - ideal | images a^i b^j | standard monomials")
H = []
for t in range(8):
    cols, piv = ideal_piece(TC, 4, t)
    ims = len({image(e) for e in cols})
    std = [e for e in cols if e[0] + e[1] <= 1]
    assert set(piv) == set(cols) - set(std)          # leading monomials are exactly those of x^2, xy, y^2
    H.append(len(cols) - len(piv))
    print(f"{t} | {len(cols)} | {len(piv)} | {H[-1]} | {ims} | {len(std)}")
    assert len(cols) == comb(t + 3, 3) and H[-1] == ims == len(std)
hp = fit(range(3, 7), H[3:7])
print(f"HP fitted through t = 3..6: {show(hp)}; predicts HF(7) = {at(hp, 7)}, computed {H[7]}")
print(f"read off: dimension = degree of HP = {len(hp) - 1}; degree = leading coefficient x 1! = {hp[-1]}")
assert hp == [1, 3] and at(hp, 7) == H[7]
def cubic_u(h): return [h[3], h[0], h[1], h[2]]     # x, y, z, w coefficients -> d + c u + b u^2 + a u^3
def ldiv(p, r):                                       # divide by (u - r) if r is a root
    q, acc = [], Q(0)
    for c in reversed(p): acc = acc * r + c; q.append(acc)
    return (list(reversed(q[:-1])), True) if acc == 0 else (p, False)
def lin(h): return {(1, 0, 0, 0): h[0], (0, 1, 0, 0): h[1], (0, 0, 1, 0): h[2], (0, 0, 0, 1): h[3]}
planes = [("11x - 6y + z - 6w", (11, -6, 1, -6)), ("z - 8w, a slicer layer", (0, 0, 1, -8)), ("x = 0", (1, 0, 0, 0)),
          ("5x - 4y + z - 2w, tangent", (5, -4, 1, -2)), ("z = 0, triple touch", (0, 0, 1, 0))]
res = {}
for name, h in planes:
    p = [Q(c) for c in cubic_u(h)]
    while p[-1] == 0: p.pop()
    inf, roots = 3 - (len(p) - 1), []
    for r in range(-30, 31):
        ok = True
        while ok and len(p) > 1: p, ok = ldiv(p, r); roots += [r] if ok else []
    left, res[name[:5]] = len(p) - 1, (roots, p, inf)
    sl = [hf(TC + [lin({k: v for k, v in zip(range(4), h)})], 4, t) for t in range(5)]
    print(f"plane {name}: rational roots u = {roots}; other complex {left}; at infinity {inf}; "
          f"total {len(roots) + left + inf}; slice HF t = 0..4: {sl}")
    assert len(roots) + left + inf == 3 and sl[1:] == [3, 3, 3, 3]
pts = [(u, u * u, u ** 3, 1) for u in (1, 2, 3)]
ev = []
for t in range(1, 5):
    cols = monos(4, t)
    ev.append(len(pivots(cols, [[Q(p[0] ** e[0] * p[1] ** e[1] * p[2] ** e[2] * p[3] ** e[3]) for e in cols] for p in pts])))
print(f"points (1, 1, 1), (2, 4, 8), (3, 9, 27): degree-t forms separate them, rank t = 1..4: {ev}")
assert ev == [3, 3, 3, 3]
s = 2026
def splitmix():
    global s
    s = (s + 0x9E3779B97F4A7C15) % 2 ** 64; z = s
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2 ** 64; z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2 ** 64
    return z ^ (z >> 31)
cnt = {"three real": 0, "one real": 0, "repeated": 0, "zero plane": 0}
for _ in range(1000):
    h = [splitmix() % 19 - 9 for _ in range(4)]
    d, c, b, a = cubic_u(h)
    D = 18 * a * b * c * d - 4 * b ** 3 * d + b * b * c * c - 4 * a * c ** 3 - 27 * a * a * d * d
    cnt["zero plane" if not any(h) else "three real" if D > 0 else "one real" if D < 0 else "repeated"] += 1
    syl = [[3 * a, 2 * b, c, 0], [0, 3 * a, 2 * b, c], [b, 2 * c, 3 * d, 0], [0, b, 2 * c, 3 * d]]   # Sylvester: F_u, F_v
    assert (len(pivots(range(4), [[Q(v) for v in row] for row in syl])) < 4) == (D == 0)   # shared root = repeated
print("1000 random planes, SplitMix64 seed 2026, coefficients -9..9: " + ", ".join(f"{k} {v}" for k, v in cnt.items()))
assert sum(cnt.values()) == 1000 and cnt["zero plane"] == 0
CONE = [{(2, 0, 0, 0): 1, (0, 2, 0, 0): 1, (0, 0, 2, 0): -1}]
models = [("P^3, no equations", [], 4), ("twisted cubic", TC, 4), ("cone x^2 + y^2 = z^2 in P^3", CONE, 4),
          ("its slice z = w, a conic", CONE + [{(0, 0, 1, 0): 1, (0, 0, 0, 1): -1}], 4),
          ("plane cubic y^2 z = x^3 - x z^2", [{(0, 2, 1): 1, (3, 0, 0): -1, (1, 0, 2): 1}], 3),
          ("two quadrics x^2 - yw, xy - zw", [X2, XY], 4)]
got = {}
for name, gens, n in models:
    v = H if gens is TC else [hf(gens, n, t) for t in range(8)]
    p = fit(range(3, 7), v[3:7]); d = len(p) - 1
    assert at(p, 7) == v[7]
    got[name] = (p[-1] * factorial(d), v, p[-1])
    print(f"{name}: HF t = 0..7 {v}; HP {show(p)}; dim {d}; degree {p[-1] * factorial(d)}")
assert [got[m[0]][0] for m in models] == [1, 3, 2, 2, 3, 4] and got["plane cubic y^2 z = x^3 - x z^2"][1][0] == 1
(rb, qb, _), (rc, _, ic), (rd, _, _) = res["z - 8"], res["x = 0"], res["5x - "]
qd = qb[1] ** 2 - 4 * qb[0] * qb[2]
print(f"mistake 1, real points only: plane z = 8w, real roots {rb}, leftover u^2 + 2u + 4 has discriminant {qd}: {len(rb)}, not 3")
print(f"mistake 2, affine chart only: plane x = 0 shows u = {rc[0]} alone: {len(rc)}, not 3; {ic} more lie at infinity")
print(f"mistake 3, distinct points only: the tangent plane shows u = {sorted(set(rd))}: {len(set(rd))}, not 3")
assert qd < 0 and qb == [4, 2, 1] and len(rb) == len(rc) == 1 and len(set(rd)) == 2 and res["z = 0"][0] == [0, 0, 0]
print(f"mistake 4, drop y^2 - xz: degree {got['two quadrics x^2 - yw, xy - zw'][0]}, not 3; the line x = w = 0 joins in")
print(f"mistake 5, cone's leading coefficient as degree: {got['cone x^2 + y^2 = z^2 in P^3'][2]}, not {got['cone x^2 + y^2 = z^2 in P^3'][0]}; forgot the 2!")
print(f"chart, t = 0..6: monomials {[comb(t + 3, 3) for t in range(7)]}; ideal {[comb(t + 3, 3) - H[t] for t in range(7)]}; HF {H[:7]}")
print("ALL CHECKS PASS")
