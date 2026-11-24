# Spectral sequences in outline -- the check behind the card.  Standard library only.
# Page arithmetic only: entries of a page are groups Z, Z/n or 0 (or ranks over Q), and a
# differential d_r kills what it maps one for one.  Every list stops at degree N = 8.
from itertools import product
N = 8

def cyc(m):                                   # the group Z/m, with Z/0 = Z and Z/1 = 0
    m = abs(m)
    return "Z" if m == 0 else "0" if m == 1 else f"Z/{m}"

def rk(g):                                    # rank over Q: only Z survives
    return 1 if g == "Z" else 0

# Part 1. Circle bundles over S^2, Euler number c (n here).  Cells e0, e1 over the base point,
# e2, e3 over the rest; the one coboundary that jumps columns is delta(e1) = n e2.
NAMES = {0: "S2 x S1", 1: "S3, Hopf", 2: "RP3, rotations", 3: "lens space L(3,1)"}

def by_page(n):                               # road one: E2 page, then d2 = n
    e2 = {(0, 0): "Z", (0, 1): "Z", (2, 0): "Z", (2, 1): "Z"}
    einf = dict(e2)
    einf[(0, 1)] = "Z" if n == 0 else "0"     # kernel of d2 out of (0,1)
    einf[(2, 0)] = cyc(n)                     # cokernel of d2 into (2,0)
    return [next((g for (p, q), g in einf.items() if p + q == k), "0") for k in range(4)], e2, einf

def by_cochains(n):                           # road two: the whole cochain complex, no pages
    delta = [0, n, 0]                         # C^0 -> C^1 -> C^2 -> C^3, each a copy of Z
    out = []
    for k in range(4):
        d_out = delta[k] if k < 3 else 0
        d_in = delta[k - 1] if k > 0 else 0
        out.append("0" if d_out != 0 else cyc(d_in))
    return out

def chi(page):                                # Euler characteristic of a page, ranks over Q
    return sum((-1) ** (p + q) * rk(g) for (p, q), g in page.items())

print("Circle bundles over S2, Euler number c: cohomology H0..H3 over Z")
for n in range(4):
    h, e2, einf = by_page(n)
    assert h == by_cochains(n)
    assert chi(e2) == chi(einf) == 2 * 0      # chi(base) x chi(fibre) = 2 x 0
    print(f"  c = {n}  {NAMES[n]:<18} page {', '.join(h):<13} cochains {', '.join(by_cochains(n)):<13}"
          f" ranks over Q {[rk(g) for g in h]}  chi E2 {chi(e2)}, E-infinity {chi(einf)}")

# Part 2. Pages that must end empty.  A list s[0..N] of ranks survives when a differential
# of reach `gap` can kill everything except s[0] = 1:
#   each entry dies by going out:   s[k] <= s[k - gap]  (k >= 1; nothing below 0)
#   each entry dies by being hit:   s[k] <= s[k + gap]  (k + gap <= N)
def survives(s, gap):
    out = all(s[k] <= (s[k - gap] if k >= gap else 0) for k in range(1, N + 1))
    hit = all(s[k] <= s[k + gap] for k in range(0, N + 1 - gap))
    return out and hit

def by_recursion(gap):                        # road one: solve the page degree by degree
    s = [1]
    for k in range(1, N + 1):
        s.append(s[k - gap] if k >= gap else 0)
    return s

def by_search(gap, rule=survives):            # road two: every list of ranks 0, 1, 2
    return [[1, *t] for t in product(range(3), repeat=N) if rule([1, *t], gap)]

for m in (2, 3, 4):                           # path fibration of S^m: d_m, reach m - 1
    print(f"Loop space of S{m}: ranks of H0..H{N} = {by_recursion(m - 1)}")
loop = by_search(2)
print(f"Loop space of S3, exhaustive: {3 ** N} lists tried, {len(loop)} survives: {loop[0]}")
for q in range(2, 7, 2):
    print(f"  d3 : E3(0,{q}) = Z  ->  E3(3,{q - 2}) = Z, one for one")

def rows_survive(b, gap):                     # K(Z,2): rows q = 0 and 1, both copies of b
    row1 = all(b[p] <= b[p + gap] for p in range(0, N + 1 - gap))      # (p,1) goes out to (p+2,0)
    row0 = all(b[p] <= (b[p - gap] if p >= gap else 0) for p in range(1, N + 1))  # (p,0) is hit
    return row1 and row0
kz2 = by_search(2, rows_survive)
cells = [1 if p % 2 == 0 else 0 for p in range(N + 1)]   # CP-infinity: one cell per even dimension
print(f"K(Z,2) from fibre S1, exhaustive: {len(kz2)} survives: {kz2[0]}; cells of CP-infinity {cells}")
assert loop == [by_recursion(2)] and kz2 == [cells]
assert by_recursion(1) == [1] * (N + 1) and by_recursion(3) == [1, 0, 0, 1, 0, 0, 1, 0, 0]

# What breaks.  Stop at E2: both columns keep the true list, and each diagonal is read as an answer.
e2_loop = [loop[0][k] + (loop[0][k - 3] if k >= 3 else 0) for k in range(N + 1)]
print(f"Stop at E2 for the loop space: E2(3,0) = Z stays; the point PS3 would get ranks {e2_loop} in H0..H{N}")

# A page with columns 0 and 3, both holding s, and one differential d_r: r columns right, r - 1 rows
# down.  Every nonzero entry but (0,0) must die, going out or hit; a partner past degree N is not tested.
def emptied_by(s, r):
    for p in (0, 3):
        for q in range(1 if p == 0 else 0, N + 1):
            out = p + r in (0, 3) and q - r + 1 >= 0 and s[q] <= s[q - r + 1]
            hit = p - r in (0, 3) and (q + r - 1 > N or s[q] <= s[q + r - 1])
            if s[q] and not (out or hit):
                return False
    return True
by_d3, by_d2 = by_search(3, emptied_by), by_search(2, emptied_by)
print(f"One differential on columns 0 and 3, every rank list: emptied by d3: {len(by_d3)}, {by_d3[0]}; by d2: {len(by_d2)}")
e2_hopf = by_page(1)[1]
naive = [sum(rk(g) for (p, q), g in e2_hopf.items() if p + q == k) for k in range(4)]
print(f"Stop at E2 for the Hopf bundle: H0..H3 ranks {naive}, true {[rk(g) for g in by_page(1)[0]]}")

def rank1(col, mod):                          # rank of a one-column matrix, over Q (mod 0) or mod p
    return 1 if any((x % mod if mod else x) != 0 for x in col) else 0
bd2 = [2, 0]                                  # Klein bottle: cell c has boundary 2a + 0b; bd1 = 0
klein = {mod: [1, 2 - rank1(bd2, mod), 1 - rank1(bd2, mod)] for mod in (0, 2)}
untwisted = [1, 2, 1]                         # H(S1) x H(S1), as if the fibre were never flipped
print(f"Klein bottle as a circle over a circle: untwisted page {untwisted}, true over Q {klein[0]},"
      f" true mod 2 {klein[2]}")
print(f"RP3 over Q {[rk(g) for g in by_page(2)[0]]}, the same as S3; over Z H2 = {by_page(2)[0][2]}")
assert by_d3 == loop and by_d2 == [] and e2_loop == [1, 0, 1, 1, 1, 1, 1, 1, 1]
assert naive == [1, 1, 1, 1] and klein[0] == [1, 1, 0] and klein[2] == untwisted
assert by_page(2)[0][2] == "Z/2" and [rk(g) for g in by_page(2)[0]] == [rk(g) for g in by_page(1)[0]]
print("ALL CHECKS PASS")
