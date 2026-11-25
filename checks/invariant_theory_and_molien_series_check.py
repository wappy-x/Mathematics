# Invariants of a finite group -- the check behind the card.  Only exact fractions
# are imported.  The group: the powers of the quarter turn A(x, y) = (-y, x), four
# matrices.  Field: the rationals.  Four roads to the number of invariants of each
# degree d: Molien's average of 1/det(I - tg); the rank of the Reynolds averages
# of the degree-d monomials; the average trace of g on degree-d polynomials; and the
# products u^i v^j w^k (k = 0 or 1) of the three generators.  Then a Grobner basis,
# lex x > y > u > v > w, finds the one relation among u, v, w.
from fractions import Fraction as Q
TOP, NAMES = 12, "xyuvw"
A, S, I2 = ((0, -1), (1, 0)), ((0, 1), (1, 0)), ((1, 0), (0, 1))   # turn, mirror swap, identity

def matmul(a, b): return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(2)) for j in range(2)) for i in range(2))
def closure(gens):                            # every product of the generators
    G = [I2]
    while (new := [m for g in G for h in gens if (m := matmul(g, h)) not in G]): G += list(dict.fromkeys(new))
    return G
def add(p, q, c=1):                           # p + c * q
    out = dict(p)
    for m, a in q.items():
        out[m] = out.get(m, 0) + c * a
        if out[m] == 0: del out[m]
    return out
def mul(p, q):
    out = {}
    for m, a in p.items(): out = add(out, {tuple(i + j for i, j in zip(m, e)): a * b for e, b in q.items()})
    return out
def pw(p, k):
    out = {(0,) * len(next(iter(p))): Q(1)}
    for _ in range(k): out = mul(out, p)
    return out
def act(f, g):                                # f(g(x, y)): x -> g00 x + g01 y, y -> g10 x + g11 y
    X, Y = ({m: Q(c) for m, c in (((1, 0), r[0]), ((0, 1), r[1])) if c} for r in g)
    out = {}
    for (a, b), c in f.items(): out = add(out, mul(pw(X, a), pw(Y, b)), c)
    return out
def reynolds(f, G):                           # the average of f over the group
    out = {}
    for g in G: out = add(out, act(f, g), Q(1, len(G)))
    return out
def rank(polys):                              # Gaussian elimination over Q
    rows, r = [dict(p) for p in polys if p], 0
    while rows:
        p = rows.pop(); m = max(p); r += 1
        rows = [q for q in (add(q, p, -q[m] / p[m]) if m in q else q for q in rows) if q]
    return r
def series(num, den):                         # power series of num / den up to t^TOP, den[0] = 1
    c = []
    for n in range(TOP + 1): c.append(Q(num[n] if n < len(num) else 0) - sum(den[k] * c[n - k] for k in range(1, min(n, len(den) - 1) + 1)))
    return c
def molien(G):
    terms = [series([1], [1, -(g[0][0] + g[1][1]), g[0][0] * g[1][1] - g[0][1] * g[1][0]]) for g in G]
    return [sum(t[n] for t in terms) / len(G) for n in range(TOP + 1)]
def monos(d): return [(a, d - a) for a in range(d, -1, -1)]
def show(p):
    out = ""
    for m in sorted(p, reverse=True):
        c, body = p[m], "*".join(NAMES[i] + (f"^{k}" if k > 1 else "") for i, k in enumerate(m) if k)
        txt = (body if abs(c) == 1 else f"{abs(c)}*{body}") if body else f"{abs(c)}"
        out += ("-" if c < 0 else "") + txt if not out else (" - " if c < 0 else " + ") + txt
    return out
def ints(c): return "[" + ", ".join(str(x) for x in c) + "]"

G, D4 = closure([A]), closure([A, S])
x, y = {(1, 0): Q(1)}, {(0, 1): Q(1)}
u, v = add(pw(x, 2), pw(y, 2)), mul(pw(x, 2), pw(y, 2))
w = add(mul(pw(x, 3), y), mul(x, pw(y, 3)), -1)
mol = molien(G)
closed = series([1, 0, 0, 0, 1], [1, 0, -1, 0, -1, 0, 1])     # (1 + t^4) / ((1 - t^2)(1 - t^4))
rey = [rank([reynolds({m: Q(1)}, G) for m in monos(d)]) for d in range(TOP + 1)]
trace = [sum(sum(act({m: Q(1)}, g).get(m, 0) for m in monos(d)) for g in G) / len(G) for d in range(TOP + 1)]
prods, span = [], []
for d in range(TOP + 1):
    P = [mul(mul(pw(u, i), pw(v, j)), pw(w, k)) for k in (0, 1) for j in range(TOP) for i in range(TOP) if 2 * i + 4 * j + 4 * k == d]
    prods.append(len(P)); span.append((rank(P), rank(P + [reynolds({m: Q(1)}, G) for m in monos(d)])))
print(f"field Q; group of the quarter turn (x, y) -> (-y, x): {len(G)} matrices " + " ".join(f"[{g[0][0]} {g[0][1]}; {g[1][0]} {g[1][1]}]" for g in G))
print("det(I - tg) for each: " + ", ".join(show({k: c for k, c in (((0,), 1), ((1,), -g[0][0] - g[1][1]), ((2,), g[0][0] * g[1][1] - g[0][1] * g[1][0])) if c}).replace("x", "t") for g in G))
print(f"degree d                            {ints(range(TOP + 1))}")
print(f"all polynomials of degree d         {ints(d + 1 for d in range(TOP + 1))}")
print(f"Molien, average of 1/det(I - tg)    {ints(mol)}")
print(f"(1 + t^4)/((1 - t^2)(1 - t^4))      {ints(closed)}")
print(f"rank of Reynolds images             {ints(rey)}")
print(f"average trace of g on degree d      {ints(trace)}")
print(f"products u^i v^j w^k, k <= 1        {ints(prods)}; independent and spanning: {'yes' if all(a == b == c for (a, b), c in zip(span, prods)) else 'no'}")
for m in [(1, 0), (2, 0), (1, 1), (4, 0), (3, 1), (2, 2)]: print(f"R({show({m: 1})}) = {show(reynolds({m: Q(1)}, G)) or 0}")
print(f"u = {show(u)}, v = {show(v)}, w = {show(w)}; each fixed by A: {'yes' if all(act(p, A) == p for p in (u, v, w)) else 'no'}")
lift = lambda p: {m + (0, 0, 0): c for m, c in p.items()}       # into Q[x, y, u, v, w]
var = lambda i: {tuple(int(j == i) for j in range(5)): Q(1)}
F = [add(var(2), lift(u), -1), add(var(3), lift(v), -1), add(var(4), lift(w), -1)]
def divides(a, b): return all(i <= j for i, j in zip(a, b))
def nf(p, B):                                 # remainder of p on division by the list B
    p, r = dict(p), {}
    while p:
        m = max(p); g = next((g for g in B if divides(max(g), m)), None)
        if g is None: r[m] = p.pop(m); continue
        p = add(p, mul({tuple(i - j for i, j in zip(m, max(g))): p[m] / g[max(g)]}, g), -1)
    return r
def spoly(f, g):
    a, b = max(f), max(g); l = tuple(map(max, a, b))
    return add(mul({tuple(i - j for i, j in zip(l, a)): 1 / f[a]}, f), mul({tuple(i - j for i, j in zip(l, b)): 1 / g[b]}, g), -1)
def buchberger(B):
    B, pairs = list(B), [(i, j) for j in range(len(B)) for i in range(j)]
    while pairs:
        i, j = pairs.pop(0)
        if (r := nf(spoly(B[i], B[j]), B)): pairs += [(k, len(B)) for k in range(len(B))]; B.append(r)
    keep = []
    for g in sorted(B, key=max):
        if not any(divides(max(h), max(g)) for h in keep): keep.append(g)
    red = [nf(g, [h for h in keep if h is not g]) for g in keep]
    return sorted(({m: c / r[max(r)] for m, c in r.items()} for r in red), key=max, reverse=True)
GB = buchberger(F)
elim = [g for g in GB if all(m[0] == m[1] == 0 for m in g)]
print(f"Grobner basis of <u - (x^2 + y^2), v - x^2y^2, w - (x^3y - xy^3)>, lex x > y > u > v > w: {len(GB)} polynomials")
print(f"free of x and y: {len(elim)}: {show(elim[0])} = 0")
rel = add(add(mul(pw(u, 2), v), pw(v, 2), -4), pw(w, 2), -1)      # u^2 v - 4 v^2 - w^2, put back in x, y
print(f"u^2*v - 4*v^2 - w^2 with u, v, w written in x and y: {show(rel) or 0}")
f4, f2 = lift(add(pw(x, 4), pw(y, 4))), lift(pw(x, 2))
print(f"normal form of x^4 + y^4: {show(nf(f4, GB))}; of x^2 (not invariant): {show(nf(f2, GB))}")
ev = lambda p, a, b: sum(c * Q(a) ** m[0] * Q(b) ** m[1] for m, c in p.items())
pts = [(g[0][0] * 3 + g[0][1], g[1][0] * 3 + g[1][1]) for g in G]   # the orbit of (3, 1)
print("at " + " and ".join(f"({a}, {b}): u, v, w = {ev(u, a, b)}, {ev(v, a, b)}, {ev(w, a, b)}" for a, b in pts)
      + f"; w^2 = {ev(w, 3, 1) ** 2}, v(u^2 - 4v) = {ev(v, 3, 1)} * {ev(u, 3, 1) ** 2 - 4 * ev(v, 3, 1)} = {ev(v, 3, 1) * (ev(u, 3, 1) ** 2 - 4 * ev(v, 3, 1))}")
mD4 = molien(D4); rD4 = [rank([reynolds({m: Q(1)}, D4) for m in monos(d)]) for d in range(TOP + 1)]
print(f"with the mirror (x, y) -> (y, x) added: {len(D4)} matrices; Molien {ints(mD4)}; Reynolds ranks agree: {'yes' if mD4 == rD4 else 'no'}; R(w) = {show(reynolds(w, D4)) or 0}")
free = series([1], [1, 0, -1, 0, -2, 0, 2, 0, 1, 0, -1])           # 1/((1 - t^2)(1 - t^4)^2): u, v, w taken as free
only = series([1], [1, -2, 1])                                     # 1/(1 - t)^2: the identity's term alone
print(f"mistake 1, identity term only: 1/(1 - t)^2 gives {ints(only[:6])} for d = 0..5, so {only[4]} at degree 4, not {mol[4]}")
print(f"mistake 2, u, v, w taken as free: 1/((1 - t^2)(1 - t^4)^2) gives {free[8]} at degree 8, not {mol[8]}; the extra one is w^2 = u^2*v - 4*v^2")
low = [r for d in (1, 2) for m in monos(d) if (r := reynolds({m: Q(1)}, G))]   # averages of degree <= 2 only
low4 = rank([mul(a, b) for a in low for b in low])
print(f"mistake 3, generators of degree <= 2 only: {rank(low)} independent one (u), and degree 4 holds {low4} product, not {mol[4]}")
tr2 = [{m: c % 2 for m, c in add({m: Q(1)}, act({m: Q(1)}, S)).items() if c % 2} for m in monos(2)]   # f + S(f), mod 2
print(f"mistake 4, field F_2, swap group {{I, S}}: f + S(f) for f = x^2, xy, y^2 gives {', '.join(show(t) or '0' for t in tr2)}; the invariant xy is never reached")
assert mol == closed == rey == trace and mol[:9] == [1, 0, 1, 0, 3, 0, 3, 0, 5]   # four roads to one count
assert prods == mol and all(a == b == c for (a, b), c in zip(span, prods))         # generators span, w^2 aside
assert len(elim) == 1 and elim[0] == {(0, 0, 2, 1, 0): 1, (0, 0, 0, 2, 0): -4, (0, 0, 0, 0, 2): -1} and rel == {}
assert nf(f4, GB) == {(0, 0, 2, 0, 0): 1, (0, 0, 0, 1, 0): -2} and any(m[0] + m[1] for m in nf(f2, GB))
assert ev(w, 3, 1) ** 2 == 576 == ev(v, 3, 1) * (ev(u, 3, 1) ** 2 - 4 * ev(v, 3, 1)) and len(G) == 4
assert len(pts) == 4 and len({(ev(u, a, b), ev(v, a, b), ev(w, a, b)) for a, b in pts}) == 1   # same values round the orbit
assert mD4 == rD4 and mD4[4] == 2 and reynolds(w, D4) == {} and free[8] == 6 == only[4] + 1 and low4 == 1 and tr2 == [u, {}, u]
print("ALL CHECKS PASS")
