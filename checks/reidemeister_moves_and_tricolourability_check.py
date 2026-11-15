# Reidemeister moves and the three-colour test -- the check behind the card.
# Only Fraction (exact halves) and sqrt (the figure) are imported.  A diagram
# is a count of arcs and a list of crossings (over arc, under arc, under arc).
# Colourings are counted two ways: every paint job tried, and 3 to the power
# (arcs - rank) by elimination mod 3.  The three moves are checked on every
# colouring of their loose ends, and the linking number is found two ways.
from fractions import Fraction
from math import sqrt

P = 3                                        # number of colours: 0 red, 1 yellow, 2 blue

def paints(n, p):                            # every way to give n arcs a colour 0..p-1
    out = [[]]
    for _ in range(n):
        out = [c + [k] for c in out for k in range(p)]
    return out

def legal(cr, col, p, rule="mod"):           # the crossing rule, and two broken ones
    if rule == "none":
        return True
    if rule == "different":
        return all(len({col[o], col[a], col[b]}) == 3 for o, a, b in cr)
    return all((2 * col[o] - col[a] - col[b]) % p == 0 for o, a, b in cr)

def brute(n, cr, p=P, rule="mod"):           # road one: try every paint job
    return sum(legal(cr, c, p, rule) for c in paints(n, p))

def by_rank(n, cr, p=P):                     # road two: p ** (arcs - rank mod p)
    rows = []
    for o, a, b in cr:
        r = [0] * n
        r[o] += 2; r[a] -= 1; r[b] -= 1
        rows.append([x % p for x in r])
    rank = 0
    for col in range(n):
        piv = next((i for i in range(rank, len(rows)) if rows[i][col]), None)
        if piv is None:
            continue
        rows[rank], rows[piv] = rows[piv], rows[rank]
        inv = pow(rows[rank][col], p - 2, p)
        rows[rank] = [x * inv % p for x in rows[rank]]
        for i in range(len(rows)):
            if i != rank and rows[i][col]:
                f = rows[i][col]
                rows[i] = [(x - f * y) % p for x, y in zip(rows[i], rows[rank])]
        rank += 1
    return p ** (n - rank), rank

def inside(n, cr, ends, fixed, rule="mod"):  # colourings of a move's inside, ends fixed
    return sum(legal(cr, c, P, rule) and [c[e] for e in ends] == fixed
               for c in paints(n, P))

def same_inside(before, after, rule="mod"):  # equal on every colouring of the ends
    k = len(before[2])
    return all(inside(*before, f, rule) == inside(*after, f, rule) for f in paints(k, P))

D = {"circle": (1, []), "circle + R1 kink": (1, [(0, 0, 0)]),
     "circle + R2 poke": (2, [(0, 0, 1), (0, 1, 0)]),
     "trefoil": (3, [(0, 1, 2), (1, 2, 0), (2, 0, 1)]),
     "trefoil + R1 kink": (4, [(0, 1, 2), (1, 2, 0), (2, 3, 1), (3, 0, 3)]),
     "figure-eight": (4, [(0, 1, 2), (2, 3, 0), (1, 2, 3), (3, 0, 1)]),
     "two-circle unlink": (2, []), "Hopf link": (2, [(0, 1, 1), (1, 0, 0)])}
counts = {}
for name, (n, cr) in D.items():
    t, rank = by_rank(n, cr)
    counts[name] = brute(n, cr)
    print(f"{name}: arcs {n}, crossings {len(cr)}, rank {rank}; colourings "
          f"by brute force {counts[name]}, by 3^(arcs - rank) {t}")
    assert counts[name] == t                                   # two roads agree

MOVES = {"R1 kink, over first": ((1, [], [0, 0]), (2, [(0, 0, 1)], [0, 1])),
         "R1 kink, under first": ((1, [], [0, 0]), (2, [(1, 0, 1)], [0, 1])),
         "R2 poke": ((2, [], [0, 0, 1, 1]), (4, [(0, 1, 2), (0, 2, 3)], [0, 0, 1, 3])),
         "R3 slide": ((6, [(1, 3, 4), (0, 4, 5), (0, 1, 2)], [0, 0, 1, 2, 3, 5]),
                      (6, [(0, 1, 2), (0, 3, 4), (2, 4, 5)], [0, 0, 1, 2, 3, 5]))}
for name, (bef, aft) in MOVES.items():
    ok = same_inside(bef, aft)
    print(f"{name}: inside counts agree on all {P ** len(bef[2])} colourings of the ends: {'yes' if ok else 'no'}")
    assert ok                                                  # exhaustive: a proof for 3 colours
u, m, t = 1, 2, 0                                    # R3 worked: x under y comes out 2y - x
b2 = (2 * m - u) % P; b3 = (2 * t - b2) % P                          # before: under m, then t
m2 = (2 * t - m) % P; a2 = (2 * t - u) % P; a3 = (2 * m2 - a2) % P   # after: under t, then m
print(f"R3 worked, u, m, t = {u}, {m}, {t}: before u -> {b2} -> {b3}; "
      f"after m -> {m2}, u -> {a2} -> {a3}")
assert b3 == a3 == (2 * t - 2 * m + u) % P
print(f"trefoil one-colour 3 + all-different 6 = {counts['trefoil']}; unknot {counts['circle']}")
assert counts["trefoil"] == 3 + 6 and counts["trefoil"] != counts["circle"]

def lk_half(cr):                             # road one: half the signs between K1 and K2
    return Fraction(sum(s for o, w, s in cr if o != w), 2)

def lk_over(cr):                             # road two: only crossings where K1 is over
    return sum(s for o, w, s in cr if (o, w) == (0, 1))

hopf = [(0, 1, 1), (1, 0, 1)]
L = {"unlink": [], "Hopf link": hopf, "Hopf + R1 kink": hopf + [(0, 0, 1)],
     "Hopf + R2 poke": hopf + [(0, 1, 1), (0, 1, -1)], "Solomon link": hopf * 2}
for name, cr in L.items():
    print(f"linking number of {name}: half-sum {lk_half(cr)}, K1-over sum {lk_over(cr)}")
    assert lk_half(cr) == lk_over(cr)                          # two roads agree
assert lk_half(L["Hopf + R1 kink"]) == lk_half(L["Hopf + R2 poke"]) == 1

tre, tk = D["trefoil"], D["trefoil + R1 kink"]
print(f"mistake 1, no rule: trefoil {brute(*tre, rule='none')}, after a kink "
      f"{brute(*tk, rule='none')}; R1 inside agrees: "
      f"{'yes' if same_inside(*MOVES['R1 kink, over first'], rule='none') else 'no'}")
print(f"mistake 2, all different required: circle {brute(*D['circle'], rule='different')}, "
      f"after a kink {brute(*D['circle + R1 kink'], rule='different')}")
print(f"mistake 3, two colours: trefoil {brute(*tre, p=2)}, circle {brute(*D['circle'], p=2)}")
print(f"mistake 4, self-crossing counted: Hopf + R1 kink gives "
      f"{Fraction(sum(s for o, w, s in L['Hopf + R1 kink']), 2)}")
assert brute(*tk, rule="none") == 81 and brute(*D["circle + R1 kink"], rule="different") == 0
c = Fraction(-1, 4)                                            # figure: cos t = -1/4
y, h = c - 2 * (2 * c * c - 1), 3 * sqrt(15) / 16
print(f"figure, trefoil crossings at (0, {y}), ({float(y) * sqrt(3) / 2:.3f}, {-float(y) / 2:.3f}), "
      f"({-float(y) * sqrt(3) / 2:.3f}, {-float(y) / 2:.3f}); strand heights +{h:.3f} and -{h:.3f}")
print("ALL CHECKS PASS")
