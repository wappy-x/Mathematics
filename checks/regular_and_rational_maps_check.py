# Regular and rational maps -- the check behind the card.  Standard library only.
# The cone C: x^2 + y^2 = z^2.  A regular map psi from the plane into it, and its
# pullback on coordinate rings; then the projection phi from the apex onto the
# screen z = 1, and exactly where phi is undefined.  Fractions keep it exact.
from fractions import Fraction as Q
from math import comb

def padd(a, b):                                # polynomials in s, t: {(i, j): coefficient}
    out = dict(a)
    for m, c in b.items():
        out[m] = out.get(m, 0) + c
    return {m: c for m, c in out.items() if c}

def pmul(a, b):
    out = {}
    for (i, j), c in a.items():
        for (k, l), e in b.items():
            out[(i + k, j + l)] = out.get((i + k, j + l), 0) + c * e
    return {m: c for m, c in out.items() if c}

def show(p):                                   # leading term first: degree, then power of s
    out = ""
    for (i, j) in sorted(p, key=lambda m: (-m[0] - m[1], -m[0])):
        c = p[(i, j)]
        mono = (f"s^{i}" if i > 1 else "s" * i) + (f"t^{j}" if j > 1 else "t" * j)
        body = (str(abs(c)) if abs(c) != 1 or not mono else "") + mono
        out += ((" - " if c < 0 else " + ") if out else ("-" if c < 0 else "")) + body
    return out or "0"

X, Y, Z = {(2, 0): 1, (0, 2): -1}, {(1, 1): 2}, {(2, 0): 1, (0, 2): 1}   # psi, as polynomials
def cone_of(x, y, z): return padd(padd(pmul(x, x), pmul(y, y)), {m: -c for m, c in pmul(z, z).items()})
def psi(s, t): return (s * s - t * t, 2 * s * t, s * s + t * t)
def cone(v): return v[0] * v[0] + v[1] * v[1] - v[2] * v[2]
def phi(v): return (Q(v[0]) / v[2], Q(v[1]) / v[2])          # the screen z = 1, focal length 1
def cam(v): return (v[0], v[1], v[2])                         # phi aimed at P^2: the formula (x : y : z)
def tri(v): return "(" + ", ".join(str(c) for c in v) + ")"

P = 1_000_003                                  # rank mod a prime: a lower bound for the rank over Q
def rank_mod(rows):
    rows, r = [list(x) for x in rows], 0
    for col in range(len(rows[0])):
        piv = next((i for i in range(r, len(rows)) if rows[i][col] % P), None)
        if piv is None: continue
        rows[r], rows[piv] = rows[piv], rows[r]
        inv = pow(rows[r][col], P - 2, P)
        for i in range(len(rows)):
            if i != r and rows[i][col] % P:
                f = rows[i][col] * inv % P
                rows[i] = [(a - f * b) % P for a, b in zip(rows[i], rows[r])]
        r += 1
    return r

def ppow(a, n):
    out = {(0, 0): 1}
    for _ in range(n): out = pmul(out, a)
    return out

print("cone C: x^2 + y^2 - z^2 = 0; psi(s, t) = (s^2 - t^2, 2st, s^2 + t^2); phi(x, y, z) = (x/z, y/z)")
print(f"psi(2, 1) = {tri(psi(2, 1))}, cone value {cone(psi(2, 1))}; psi(3, 2) = {tri(psi(3, 2))}, cone value {cone(psi(3, 2))}")
print(f"pullback of x^2 + y^2 - z^2: {show(cone_of(X, Y, Z))}")
print(f"pullback of x: {show(X)}; of y: {show(Y)}; of z + x: {show(padd(Z, X))}; of z - x: {show(padd(Z, {m: -c for m, c in X.items()}))}")
print(f"z - x at (3, 4, 5) is {5 - 3}; 2t^2 at (s, t) = (2, 1) is {2 * 1 * 1}")
ranks = []
for d in range(1, 6):
    rows = []
    for a in range(d + 1):
        for b in range(d + 1 - a):
            img = pmul(pmul(ppow(X, a), ppow(Y, b)), ppow(Z, d - a - b))
            rows.append([img.get((i, 2 * d - i), 0) for i in range(2 * d + 1)])
    ranks.append(rank_mod(rows))
    print(f"degree {d}: {len(rows)} monomials in x, y, z; images span {ranks[-1]} of the {2 * d + 1} forms of degree "
          f"{2 * d} in s, t; kernel {len(rows) - ranks[-1]} = multiples of the cone's equation, {comb(d, 2)}")

for v in ((3, 4, 5), (6, 8, 10), (-3, -4, -5), (5, 12, 13)):
    print(f"phi{tri(v)} = {tri(phi(v))}")
for v in ((3, 4, 5), (5, 12, 13), (1, 0, 1)):
    near = tuple(Q(c, 1000) for c in v)
    print(f"toward the apex along {tri(v)}: phi{tri(near)} = {tri(phi(near))}")
gi = lambda a, b: (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])  # complex product
print(f"over C: (1, i, 0) has x^2 + y^2 - z^2 = {gi((1, 0), (1, 0))[0] + gi((0, 1), (0, 1))[0]} and z = 0; "
      f"its ray (1 : i : 0) never meets the screen")

found = {}
for p in (7, 13):
    pts = [(x, y, z) for x in range(p) for y in range(p) for z in range(p) if (x * x + y * y - z * z) % p == 0]
    def norm(v):
        i = next(k for k in range(3) if v[k] % p)
        inv = pow(v[i], p - 2, p)
        return tuple(c * inv % p for c in v)
    lines = {norm(v) for v in pts if any(v)}
    hits = {norm(psi(s, t)) for s in range(p) for t in range(p) if (s, t) != (0, 0)}
    reach = {tuple(c % p for c in psi(s, t)) for s in range(p) for t in range(p)}
    blank = [(s, t) for s in range(p) for t in range(p) if (s, t) != (0, 0) and not any(c % p for c in psi(s, t))]
    on_screen_bad = sum(1 for v in pts if v[2] == 0)
    undef = [v for v in pts if not any(c % p for c in cam(v))]              # the camera's formula, at every point
    demand = {(norm(v), norm(cam(v))) for v in pts if v not in undef}       # (line through the apex, its image)
    imgs = {b for a, b in demand}
    found[p] = on_screen_bad
    print(f"over F_{p}: {len(pts)} points on the cone; {len(lines)} lines through the apex; "
          f"psi reaches {len(hits)} lines and {len(reach)} points; z = 0 at {on_screen_bad}")
    print(f"  (x : y : z) has a nonzero entry at {len(pts) - len(undef)} points and is undefined at {len(undef)}, the apex; "
          f"the {len(lines)} lines give {len(imgs)} different images")
    print(f"  psi(s : t) has all three entries 0 at {len(blank)} of the {p * p - 1} pairs other than (0, 0)")
    assert len(pts) == p * p == 1 + len(lines) * (p - 1) and lines == hits and not blank and len(reach) == (p * p + 1) // 2
    assert on_screen_bad == (1 if p % 4 == 3 else 2 * p - 1)
    assert undef == [(0, 0, 0)] and len(demand) == len(imgs) == len(lines) == p + 1    # one image per line, all different

u, v = phi((3, 4, 5))
print(f"circle u^2 + v^2 = 1, seen from (-1, 0): v/(1 + u) = {v / (1 + u)}, (1 - u)/v = {(1 - u) / v} at {tri((u, v))}")
same = all(b / (1 + a) == (1 - a) / b for a, b in (phi(psi(s, t)) for s, t in ((2, 1), (3, 2), (1, 3), (5, -2), (4, 7))))
print(f"the two formulas agree at 5 more circle points: {'yes' if same else 'no'}")
print(f"at (-1, 0): v/(1 + u) is 0/0; (1 - u)/v is 2/0, the point (2 : 0) = (1 : 0) of P^1")

bad = cone_of(X, Y, {(2, 0): 1, (0, 2): 2})
print(f"mistake 1, z = s^2 + 2t^2: pullback of the cone's equation {show(bad)}; (2, 1) gives (3, 4, 6), cone value {cone((3, 4, 6))}")
circ7 = [(a, b) for a in range(7) for b in range(7) if (a * a + b * b - 1) % 7 == 0]
f1, f2 = lambda a, b: (b % 7, (1 + a) % 7), lambda a, b: ((1 - a) % 7, b % 7)   # (v : 1 + u) and (1 - u : v)
flag1 = sum(1 for a, b in circ7 if f1(a, b)[1] == 0)                     # v/(1 + u) has a zero denominator
flag2 = sum(1 for a, b in circ7 if not any(f1(a, b)) and not any(f2(a, b)))   # both formulas (0 : 0)
agree = all((f1(a, b)[0] * f2(a, b)[1] - f1(a, b)[1] * f2(a, b)[0]) % 7 == 0 for a, b in circ7)
print(f"mistake 2, one formula over F_7: v/(1 + u) flags {flag1} of the {len(circ7)} circle points; "
      f"both formulas fail as points of P^1 at {flag2}; they agree wherever both are defined: {'yes' if agree else 'no'}")
print(f"mistake 3, aim at the screen, not at P^2: over F_13, {found[13]} undefined points, not 1")
print(f"mistake 4, fill the apex by one approach: {tri(phi((3, 4, 5)))} along one line, {tri(phi((5, 12, 13)))} along another")
k, ox, oy = 60, 210, 190                       # figure: 60 units per metre, side view y = 0
fig = lambda x, z: f"({ox + k * Q(x)}, {oy - k * Q(z)})"
print(f"figure, {k} units per metre, side view y = 0: apex {fig(0, 0)}; (2, 0, 2) at {fig(2, 2)} -> {fig(1, 1)}; "
      f"(-1.5, 0, 1.5) at {fig(Q(-3, 2), Q(3, 2))} -> {fig(-1, 1)}; (-1, 0, -1) at {fig(-1, -1)} -> {fig(1, 1)}")

assert cone_of(X, Y, Z) == {} and cone(psi(2, 1)) == 0 and cone(psi(3, 2)) == 0     # psi lands on C
assert ranks == [2 * d + 1 for d in range(1, len(ranks) + 1)]                                   # pullback is injective
assert phi((3, 4, 5)) == phi((-3, -4, -5)) != phi((5, 12, 13)) and same and bad != {}
assert len(circ7) == 8 and flag1 == 1 and flag2 == 0 and agree                       # P^1 target: no bad point
print("ALL CHECKS PASS")
