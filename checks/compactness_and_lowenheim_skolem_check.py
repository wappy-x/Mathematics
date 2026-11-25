# Compactness and Lowenheim-Skolem -- the check behind the card.  Standard library
# only, nothing imported.  It runs the constructions behind the proofs.  No program
# can check infinitely many axioms; every claim about "all" uses a stated window.

# ---- 1. the axioms c > 0, c > 1, c > 2, ... ----
def first_fail(c, batch): return next((n for n in batch if not c > n), None)   # first axiom c > n broken
batches = [("first 10", list(range(10))), ("first 1000", list(range(1000))),
           ("scattered {3, 17, 999, 123456}", [3, 17, 999, 123456])]
for name, b in batches:
    c = max(b) + 1                     # one more than the largest number named
    assert first_fail(c, b) is None and first_fail(c - 1, b) == c - 1
    print(f"batch {name}: witness c = {c}, all {len(b)} axioms hold")
for c in [0, 10, 1000, 123457]:        # the whole list in the counting numbers
    n = first_fail(c, range(c + 2))
    assert n == c
    print(f"whole list in the counting numbers: c = {c} fails axiom c > {n}")
# N followed by a copy of the integers Z: element (0, k), k >= 0, or (1, k), any k
W = 50
window = [(0, k) for k in range(W + 1)] + [(1, k) for k in range(-W, W + 1)]
nxt = lambda x: (x[0], x[1] + 1)
less = lambda x, y: x < y              # block first, then position: lexicographic
zero, c = (0, 0), (1, 0)
assert all(nxt(x) != zero for x in window)
preds = [x for x in window if x not in (zero, (1, -W))   # (1, -W): its predecessor is
         and sum(1 for y in window if nxt(y) == x) == 1]      # just outside the window
assert len(preds) == len(window) - 2 and not any(less(x, y) and less(y, nxt(x)) for x in window for y in window)
numerals = [(0, n) for n in range(W + 1)]
above = [x for x in window if all(less(m, x) for m in numerals)]
assert c in above and (1, -1) in above and len(above) == 2 * W + 1
print(f"N then Z, window of {len(window)} elements: 0 has no predecessor, "
      f"{len(preds)} others checked to have one, nothing between x and next(x)")
print(f"elements above every numeral 0..{W}: {len(above)}, including c and c - 1")

# ---- 2. colouring an infinite board: squares touching at a side or a corner clash ----
def clash(a, b): return a != b and abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1
def colourings(n, fixed, k=4):        # every proper k-colouring of the n x n box
    if any(fixed[a] == fixed[b] for a in fixed for b in fixed if clash(a, b)): return []
    cells = [(x, y) for y in range(n) for x in range(n) if (x, y) not in fixed]
    col, out = dict(fixed), []
    def go(i):
        if i == len(cells): out.append(dict(col)); return
        x, y = cells[i]
        for colour in range(1, k + 1):
            if all(col.get((x + dx, y + dy)) != colour for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                col[(x, y)] = colour; go(i + 1); del col[(x, y)]
    go(0)
    return out
for n in range(1, 6):
    count, formula = len(colourings(n, {})), 4 if n == 1 else 24 * (2 ** (n - 1) - 1)
    assert count == formula
    print(f"box {n}x{n}: {count} proper 4-colourings (formula 24(2^(n-1) - 1): {formula})")
for n in range(2, 5):
    cols = colourings(n, {})
    ext = sum(1 for f in cols if colourings(n + 1, f))
    assert ext == len(cols)
    print(f"colourings of the {n}x{n} box that extend to {n + 1}x{n + 1}: {ext} of {len(cols)}")
# build the colouring piece by piece: each square takes the smallest colour
# that still extends to a proper colouring of the box one size larger
N, board = 8, {}
for size in range(1, N + 1):
    for cell in [(x, y) for y in range(size) for x in range(size) if (x, y) not in board]:
        board[cell] = next(k for k in range(1, 5) if colourings(size + 1, {**board, cell: k}))
assert all(board[a] != board[b] for a in board for b in board if clash(a, b))
assert all(board[(x, y)] == 1 + x % 2 + 2 * (y % 2) for (x, y) in board)
for y in range(4):
    print("row", y, "".join(str(board[(x, y)]) for x in range(N)))
print(f"{N}x{N} board built square by square: proper, equal to 1 + (x mod 2) + 2(y mod 2)")
trap, safe = {(0, 0): 1, (1, 0): 2, (0, 2): 3}, {(0, 0): 1, (1, 0): 2, (0, 2): 1}
assert len(colourings(3, trap)) == 0 and len(colourings(3, safe)) > 0
print(f"trap: corner 1, 2 and colour 3 two rows up: {len(colourings(3, trap))} completions "
      f"of the 3x3 box; with colour 1 there: {len(colourings(3, safe))}")
assert colourings(2, {}, k=3) == []
print(f"3 colours: the 2x2 box has {len(colourings(2, {}, k=3))} colourings, so the board has none")

# ---- 3. the real algebraic numbers are countable: list them by height ----
# height = degree + sum of |coefficients|; finitely many polynomials per height
def vectors(length, s):                # integer vectors with sum of |entries| = s
    return ([()] if s == 0 else []) if length == 0 else [(a,) + r for a in range(-s, s + 1) for r in vectors(length - 1, s - abs(a))]
def binom(n, k): return 0 if k < 0 or k > n else (1 if k == 0 else binom(n - 1, k - 1) * n // k)
def n_vectors(length, s):              # the same count, by a formula
    return 1 if s == 0 else sum(binom(length, k) * binom(s - 1, k - 1) * 2 ** k for k in range(1, length + 1))
def value(p, x): return p[0] if len(p) == 1 else value(p[:-1], x) * x + p[-1]   # Horner's rule
def real_roots(p):                     # road 1: sign changes on a 1/64 grid, then halving
    out, bound = [], sum(abs(a) for a in p) + 1
    for i in range(-64 * bound, 64 * bound):
        a, b = i / 64, (i + 1) / 64
        fa, fb = value(p, a), value(p, b)
        if fa == 0: out.append(a)
        elif fa * fb < 0:
            for _ in range(60):
                m = (a + b) / 2
                a, b = (m, b) if (value(p, m) < 0) == (fa < 0) else (a, m)
            out.append((a + b) / 2)
    return out
# road 2, exact integers: Sturm's theorem counts real roots; a gcd strips roots met before
def gcd(a, b): return gcd(b, a % b) if b else abs(a)
def content(p): return gcd(p[0], content(p[1:])) if p else 0
def prim(p):                           # leading zeros dropped, common factor divided out
    while p and p[0] == 0: p = p[1:]
    return [a // content(p) for a in p]
def pdm(a, b):                         # |lead of b|^k a = q b + r, all in integers
    q, s, t = [], abs(b[0]), 1 if b[0] > 0 else -1
    while len(a) >= len(b):
        q, a = [s * e for e in q] + [t * a[0]], [s * x - t * a[0] * (b + [0] * len(a))[i] for i, x in enumerate(a)][1:]
    return prim(q), prim(a)
def pgcd(a, b): return pgcd(b, pdm(a, b)[1]) if b else a
def deriv(p): return prim([a * (len(p) - 1 - i) for i, a in enumerate(p[:-1])])
def sturm(p):                          # real roots: sign changes at -infinity minus at +infinity
    seq = [p, deriv(p)]
    while pdm(seq[-2], seq[-1])[1]: seq.append([-a for a in pdm(seq[-2], seq[-1])[1]])
    ch = lambda v: sum(u * w < 0 for u, w in zip(v, v[1:]))
    return ch([f[0] * (-1) ** (len(f) - 1) for f in seq]) - ch([f[0] for f in seq])
H, listing, found, kept, total = 8, [], {}, [], 0
for h in range(2, H):
    made = 0
    for d in range(1, h):
        ps = [p for p in vectors(d + 1, h - d) if p[0] > 0]     # leading coefficient first
        assert 2 * len(ps) == n_vectors(d + 1, h - d) - n_vectors(d, h - d)
        made += len(ps)
        for p in ps:
            g = pdm(list(p), pgcd(list(p), deriv(list(p))))[0]   # each root once
            for k in kept: g = pdm(g, pgcd(g, k))[0]             # drop roots met before
            n = sturm(g) if len(g) > 1 else 0
            kept, total = kept + [g] * (n > 0), total + n
            for r in real_roots(p):
                if all(abs(r - q) > 1e-9 for q in listing):
                    listing.append(r); found[len(listing)] = (h, p, total - n, total)
    assert len(listing) == total, "decimal roots disagree with the exact count"
    print(f"height {h}: polynomials {made}, distinct real roots so far {len(listing)}")
for name, x, m in [("sqrt 2", 2 ** 0.5, [1, 0, -2]), ("golden ratio", (1 + 5 ** 0.5) / 2, [1, -1, -1]),
                   ("cube root of 2", 2 ** (1 / 3), [1, 0, 0, -2])]:
    k = next(i for i, q in enumerate(listing, 1) if abs(q - x) < 1e-9)
    assert not pdm(list(found[k][1]), m)[1] and found[k][2] < k <= found[k][3]   # m divides p; k in p's block
    print(f"{name} = {listing[k - 1]:.12f}: entry {k}, height {found[k][0]}, polynomial {found[k][1]}")
rationals = [found[k] for k in found if len(found[k][1]) == 2]
fractions = {(-b // gcd(a, b), a // gcd(a, b)) for a in range(1, H) for b in range(-H, H) if a + abs(b) <= H - 2}
assert len(rationals) == len(fractions), "rational entries are the fractions -b/a with a + |b| <= H - 2"
print(f"{len(rationals)} entries are rational (degree 1): none squares to 2")
print("ALL CHECKS PASS")
