# Cech cohomology of O(d) on projective space -- the check behind the card.
# Standard library only.  P^n has coordinates x_0..x_n and the cover U_i = {x_i != 0}.
# A section of O(d) over the overlap U_I is a sum of Laurent monomials x^a of degree d
# (exponents add to d) with a_j >= 0 for every j outside I.  The code keeps the
# exponents in the box [-B, B]: the complex splits monomial by monomial, so the box
# loses nothing that lies inside it.
from fractions import Fraction
from itertools import combinations, product
from math import comb

def rank(columns):                         # exact rank over Q, sparse elimination
    pivots = {}
    for col in columns:
        v = {k: Fraction(x) for k, x in col.items()}
        while v:
            r = min(v)
            if r not in pivots:
                pivots[r] = v
                break
            p, f = pivots[r], v[r] / pivots[r][r]
            for k, x in p.items():
                y = v.get(k, 0) - f * x
                if y: v[k] = y
                else: v.pop(k, None)
    return len(pivots)

def cech(m, d, B, opens=None, signed=True):    # m = n + 1 coordinates
    opens = opens or list(range(m))
    mons = [a for a in product(range(-B, B + 1), repeat=m) if sum(a) == d]
    faces = [list(combinations(opens, p + 1)) for p in range(len(opens))]
    basis = [[(I, a) for I in F for a in mons if all(a[j] >= 0 for j in range(m) if j not in I)]
             for F in faces]
    index = [{e: k for k, e in enumerate(b)} for b in basis]
    deltas = []                            # delta^p as a list of sparse columns
    for p in range(len(faces) - 1):
        cols = []
        for I, a in basis[p]:
            col = {}
            for J in faces[p + 1]:
                if set(I) < set(J):        # J = I plus one index, at position pos
                    pos = [j for j in J if j not in I][0]
                    col[index[p + 1][(J, a)]] = (-1) ** J.index(pos) if signed else 1
            cols.append(col)
        deltas.append(cols)
    dims = [len(b) for b in basis]
    rk = [rank(c) for c in deltas] + [0]
    h = [dims[p] - rk[p] - (rk[p - 1] if p else 0) for p in range(len(dims))]
    return dims, h, deltas, index

def sign_count(m, d):                      # road two: count monomials by their signs
    top = sum(1 for a in product(range(0, max(d, -1) + 1), repeat=m) if sum(a) == d)
    low = sum(1 for a in product(range(d, 0), repeat=m) if sum(a) == d)
    return top, low

def formula(n, d):                         # road three: the binomial counts
    return (comb(d + n, n) if d >= 0 else 0), (comb(-d - 1, n) if d <= -n - 1 else 0)

def hilbert(n, d):                         # road four: Euler characteristic, a polynomial in d
    v = Fraction(1)
    for i in range(1, n + 1):
        v = v * (d + i) / i
    return v

table = {}
for n, B, ds in ((1, 6, range(-4, 4)), (2, 5, range(-5, 3)), (3, 4, (-5, -4, 0, 1))):
    for d in ds:
        dims, h, _, _ = cech(n + 1, d, B)
        table[n, d] = h
        chi = sum((-1) ** p * c for p, c in enumerate(dims))
        print(f"P^{n} O({d:2}): box {B}, cochain dims {dims}; h = {h}; "
              f"signs (h^0, h^{n}) = {sign_count(n + 1, d)}; formula {formula(n, d)}; "
              f"Euler {chi} = Hilbert {hilbert(n, d)}")
        assert (h[0], h[n]) == sign_count(n + 1, d) == formula(n, d)   # rank vs count vs formula
        assert all(x == 0 for x in h[1:n]) and chi == hilbert(n, d)    # middle zero; Euler road
dims, h, deltas, index = cech(2, -2, 6)
reached = {}
for k in range(-4, 3):                     # x^-2 t^k = x^(-2-k) y^k on the overlap, t = y/x
    a = (-2 - k, k)
    reached[k] = "U_x" if a[1] >= 0 else "U_y" if a[0] >= 0 else "neither"
print("O(-2) on P^1, overlap term x^-2 t^k, t = y/x: " +
      ", ".join(f"t^{k} {w}" for k, w in reached.items()))
im = rank(deltas[0])
for a, name in (((-1, -1), "1/(xy)"), ((-3, 1), "y/x^3")):
    v = {index[1][((0, 1), a)]: 1}
    inside = rank(deltas[0] + [v]) == im
    print(f"cocycle {name}: rank of coboundaries {im}, with it added {rank(deltas[0] + [v])}; "
          f"a coboundary: {'yes' if inside else 'no'}")
    assert inside == (a != (-1, -1))       # only 1/(xy) is a real class
for n in (1, 2):                           # Serre duality: h^n(O(d)) = h^0(O(-n-1-d))
    pairs = [(d, table[n, d][n], table[n, -n - 1 - d][0]) for d in range(-n - 3, 1)
             if (n, -n - 1 - d) in table]
    print(f"duality on P^{n}, (d, h^{n}(O(d)), h^0(O({-n - 1}-d))): {pairs}")
    assert all(x == y for _, x, y in pairs)
genus = [(e, table[2, -e][2], (e - 1) * (e - 2) // 2) for e in range(1, 6)]
print(f"plane curve of degree e: (e, h^2(P^2, O(-e)), (e-1)(e-2)/2) = {genus}")
assert all(x == y for _, x, y in genus)
betti = [1 if k % 2 == 0 else 0 for k in range(5)]    # one cell in each even real dimension
print(f"P^2: Betti numbers {betti}; h^q(O) for q = 0, 1, 2: {table[2, 0]}")
_, hu, _, _ = cech(3, 0, 5, signed=False)
_, h2u, _, _ = cech(3, 2, 5, signed=False)
print(f"mistake 1, no signs in delta: h^0(P^2, O) = {hu[0]}, h^0(P^2, O(2)) = {h2u[0]}")
miss = [cech(3, 0, B, opens=[0, 1])[1][1] for B in (3, 5)]
print(f"mistake 2, only U_x and U_y on P^2: h^1(O) = {miss[0]} in box 3, {miss[1]} in box 5")
print(f"mistake 3, cocycles not divided by coboundaries, O(-2) on P^1: {dims[1]} in box 6, "
      f"{cech(2, -2, 9)[0][1]} in box 9; classes {h[1]}")
print(f"mistake 4, O(2) for O(-2) on P^1: h = {table[1, 2]} against {table[1, -2]}")
assert hu[0] == 0 and h2u[0] == 0 and miss[0] < miss[1] and dims[1] > h[1] == 1
for d in (2, -4):
    rng = range(0, d + 1) if d >= 0 else range(d, 0)
    dots = sorted(a[:2] for a in product(rng, repeat=3) if sum(a) == d)
    print(f"figure, d = {d}: (a, b) of the classes x^a y^b z^c, c = d - a - b: {dots}")
print("ALL CHECKS PASS")
