# Highest weights and Weyl's dimension formula -- the check behind the card.
# Standard library only.  The group is SU(3); a highest weight is a pair (a, b)
# of whole numbers.  Each size is found four ways: Weyl's product, a count of
# traceless tensors, building the representation from its top vector by
# lowering operators, and Weyl's character formula as a ratio of determinants.
from math import comb, gcd

def weyl(a, b):                      # product over the 3 positive roots
    return (a + 1) * (b + 1) * (a + b + 2) / 2

def weyl_no_rho(a, b):               # the same product with the + rho shift left out
    return a * b * (a + b) / 2

def tensors(a, b):                   # Sym^a(3) x Sym^b(3bar), minus the trace part
    return comb(a + 2, 2) * comb(b + 2, 2) - comb(a + 1, 2) * comb(b + 1, 2)

# A state is a polynomial in x1, x2, x3 (quark) and y1, y2, y3 (antiquark):
# a dict from the six exponents to a whole-number coefficient.
def E(i, j, poly):                   # E_ij = x_i d/dx_j - y_j d/dy_i
    out = {}
    for m, c in poly.items():
        for src, dst, sign in ((j, i, 1), (3 + i, 3 + j, -1)):
            if m[src]:
                n = list(m); n[src] -= 1; n[dst] += 1
                out[tuple(n)] = out.get(tuple(n), 0) + sign * c * m[src]
    return {k: v for k, v in out.items() if v}

def build(a, b):                     # span of everything lowering reaches from the top
    rows, queue = {}, []             # rows: weight (exponent of x minus exponent of y)
    def insert(w):                   # exact elimination in whole numbers
        m = next(iter(w))
        wt = tuple(m[k] - m[3 + k] for k in range(3))
        for piv, r in rows.get(wt, []):
            if piv in w:
                c, d = w[piv], r[piv]
                w = {k: d * w.get(k, 0) - c * r.get(k, 0) for k in set(w) | set(r)}
                w = {k: v for k, v in w.items() if v}
                if not w:
                    return
        g = 0
        for v in w.values():
            g = gcd(g, v)
        w = {k: v // g for k, v in w.items()}
        rows.setdefault(wt, []).append((max(w), w))
        queue.append(w)
    top = {(a, 0, 0, 0, 0, b): 1}    # x1^a y3^b: the highest weight vector
    assert not E(0, 1, top) and not E(1, 2, top)   # both raising operators kill it
    insert(top)
    while queue:
        p = queue.pop()
        for i, j in ((1, 0), (2, 1)):  # the two lowering operators
            q = E(i, j, p)
            if q:
                insert(q)
    return {wt: len(r) for wt, r in rows.items()}

def labels(mu):                      # a weight in the (a, b) coordinates
    return (mu[0] - mu[1], mu[1] - mu[2])

def det3(M):
    return (M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1])
            - M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0])
            + M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0]))

def weyl_character(a, b, z):         # Weyl's formula: alternating sum over alternating sum
    lam = (a + b, b, 0)
    num = det3([[zi ** (lam[j] + 2 - j) for j in range(3)] for zi in z])
    den = det3([[zi ** (2 - j) for j in range(3)] for zi in z])
    assert num % den == 0
    return num // den

def built_character(ch, b, z):       # sum of multiplicity times z^(weight + b)
    return sum(n * z[0] ** (m[0] + b) * z[1] ** (m[1] + b) * z[2] ** (m[2] + b)
               for m, n in ch.items())

def by_labels(ch):
    out = {}
    for m, n in ch.items():
        out[labels(m)] = out.get(labels(m), 0) + n
    return out

def times(c1, c2):                   # character of a tensor product
    out = {}
    for w1, n1 in c1.items():
        for w2, n2 in c2.items():
            w = (w1[0] + w2[0], w1[1] + w2[1])
            out[w] = out.get(w, 0) + n1 * n2
    return out

def split(ch):                       # peel off highest weights, one at a time
    ch, parts = dict(ch), []
    while any(ch.values()):
        top = max((w for w, n in ch.items() if n), key=lambda w: (w[0] + w[1], w[0]))
        parts.append(top)
        for w, n in by_labels(build(*top)).items():
            ch[w] -= n
    return parts

z = (1, 2, 3)
print("(a, b)  Weyl  tensors  built  character at z = (1, 2, 3): built, Weyl")
squares = 0
for s in range(4):
    for a in range(s, -1, -1):
        b = s - a
        ch = build(a, b)
        d, cb, cw = sum(ch.values()), built_character(ch, b, z), weyl_character(a, b, z)
        print(f"({a}, {b})  {int(weyl(a, b)):4d}  {tensors(a, b):7d}  {d:5d}  {cb:6d}, {cw}")
        assert weyl(a, b) == tensors(a, b) == d and cb == cw
        squares += d * d
for a, b in ((1, 0), (1, 1), (3, 0)):
    print(f"by hand, ({a}, {b}): Weyl {a + 1} x {b + 1} x {a + b + 2} / 2 = {int(weyl(a, b))}; "
          f"tensors {comb(a + 2, 2) * comb(b + 2, 2)} - {comb(a + 1, 2) * comb(b + 1, 2)}")
print(f"matrix entries of these ten, the sum of size squared: {squares}")
adj = by_labels(build(1, 1))
print(f"adjoint (1, 1): {len(adj)} distinct weights, {sum(adj.values())} states, "
      f"weight (0, 0) held {adj[(0, 0)]} times")
q, qb = by_labels(build(1, 0)), by_labels(build(0, 1))
for name, ch in (("3 x 3bar", times(q, qb)), ("3 x 3", times(q, q)),
                 ("3 x 3 x 3", times(times(q, q), q))):
    parts = split(ch)
    sizes = " + ".join(str(int(weyl(*p))) for p in parts) + f" = {sum(ch.values())}"
    print(f"{name} = {parts} -> {sizes}; colourless singlets: {parts.count((0, 0))}")
assert split(times(q, qb)) == [(1, 1), (0, 0)]
assert split(times(times(q, q), q)) == [(3, 0), (1, 1), (1, 1), (0, 0)]
for name, ab in (("3", (1, 0)), ("8", (1, 1)), ("10", (3, 0))):
    pts = sorted(((p, p + 2 * r), n) for (p, r), n in by_labels(build(*ab)).items())
    print(f"figure, {name}: " + " ".join(f"({X},{Y})x{n}" for (X, Y), n in pts))
print(f"mistake 1, non-dominant (-3, 0) in Weyl's product: {weyl(-3, 0):.3f}, no such representation")
print(f"mistake 2, half-integer (1/2, 0) in Weyl's product: {weyl(0.5, 0):.3f}, not a count")
print(f"mistake 3, dropping rho for the quark (1, 0): {weyl_no_rho(1, 0):.3f} states")
print(f"mistake 4, counting weight points for the adjoint: {len(adj)}, not {sum(adj.values())}")
assert len(adj) == 7 and adj[(0, 0)] == 2
print("ALL CHECKS PASS")
