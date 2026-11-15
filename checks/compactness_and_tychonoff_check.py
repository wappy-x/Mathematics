# Compactness and Tychonoff -- the check behind the card.  Standard library only.
# A point of the circle is a fraction of a turn, from 0 (the glue point) up to
# 1, so every test is exact.  Part 1 finds the smallest finite subcover of one
# cover of the circle three ways.  Part 2 removes the glue point and watches
# that fail.  Part 3 tests the infinite cube of dials on 20 coordinates: it
# illustrates, it does not prove.  Part 4 checks the finite cases of Zorn's
# lemma and of Kelley's step on every case, so those finite cases are proved.
from fractions import Fraction as F
from itertools import combinations, product

def yn(claim):
    return "yes" if claim else "no"

def arc(n):                                # U_0 round the glue point; U_n for n >= 1
    return (F(-1, 10), F(1, 10)) if n == 0 else (F(1, n + 2), F(1, n))

def inside(t, n):                          # is the point t, 0 <= t < 1, in U_n?
    a, b = arc(n)
    return a < t < b or a < t - 1 < b      # an arc may run past the glue point

def covers(ns):                            # coverage can change only at an arc's end,
    ends = sorted({e % 1 for n in ns for e in arc(n)} | {F(0)})   # so test the ends
    gaps = [(x + y) / 2 for x, y in zip(ends, ends[1:] + [ends[0] + 1])]  # and gaps
    return all(any(inside(t % 1, n) for n in ns) for t in ends + gaps)

def names(ns):
    return ", ".join(f"U_{n}" for n in ns)

POOL = range(14)                           # U_0 .. U_13; every later arc sits in (0, 1/14), inside U_0
print("Part 1: the circle in turns; U_0 = (-1/10, 1/10), U_n = (1/(n+2), 1/n)")
reach, walk = arc(0)[1], [0]               # road 1: walk round from the glue point
while reach <= 1 + arc(0)[0]:
    n = max((m for m in POOL if inside(reach, m)), key=lambda m: arc(m)[1])
    walk.append(n)
    reach = arc(n)[1]
print(f"road 1, walk from the glue point: {len(walk)} arcs: {names(walk)}")
best = next(k for k in range(1, 15) if any(covers(c) for c in combinations(POOL, k)))
smallest = [c for c in combinations(POOL, best) if covers(c)]
print(f"road 2, search U_0..U_13, smallest selections first: {best} arcs; "
      f"{len(smallest)} cover of that size: {names(smallest[0])}")
witness = [F(0)] + [F(1, k) for k in range(2, 11)]
hits = [sum(inside(t, n) for n in POOL) for t in witness]
print("road 3, points 0, 1/2, 1/3, ..., 1/10: arcs holding each: " + " ".join(map(str, hits)))
print(f"each needs its own arc, so at least {len(witness)} arcs; U_0..U_9 cover: {yn(covers(range(10)))}")

print("Part 2: the glue point removed; U_1, U_2, U_3, ... still cover what is left")
for N in (10, 100, 1000):
    miss = F(1, N + 2)
    assert not any(inside(miss, n) for n in range(1, N + 1)) and inside(miss, N + 1)
    print(f"  U_1..U_{N} miss the point {miss} turn = {360 * miss} degrees; U_{N + 1} holds it")
zero_left = not any(inside(F(0), n) for n in range(1, 1001))
gone = next(n for n in range(1, 2000) if inside(F(1, 1000), n))
print(f"  leftover after U_1..U_n: the closed arc [0, 1/(n+2)]; 0 in none of U_1..U_1000: {yn(zero_left)}")
print(f"  with 0 removed, the leftovers lose the point 1/1000 at n = {gone}: no common point")
open_gone = next(n for n in range(1, 2000) if not F(0) < F(1, 1000) < F(1, n))
print(f"mistake, open arcs (0, 1/n) in the whole circle: 0 in none; 1/1000 gone at n = {open_gone}")

print("Part 3: the cube of dials [0, 1]^N, on its first 20 dials")
D = 20
e = {n: tuple(F(int(i == n)) for i in range(1, D + 1)) for n in range(1, D + 1)}
near = {}
for m in (3, 10):
    near[m] = [n for n in e if all(e[n][i] < F(1, 2) for i in range(m))]
    print(f"  open set 'dials 1..{m} below 1/2' round 0 holds e_n for {len(near[m])} of n = 1..{D}, "
          f"from n = {near[m][0]}")
in_box = [n for n in e if all(x < F(1, 2) for x in e[n])]
sup = {max(abs(a - b) for a, b in zip(e[m], e[n])) for m in e for n in e if m != n}
print(f"mistake, box 'every dial below 1/2': holds e_n for {len(in_box)} of n = 1..{D}")
print(f"mistake, largest-gap distance between e_m and e_n, m != n: always {min(sup)}")
k = 8
corners = list(product((0, 1), repeat=k))  # box for pattern s: dial i in [0, 2/3) or (1/3, 1]
def in_pattern(x, s):
    return all(xi < F(2, 3) if si == 0 else xi > F(1, 3) for xi, si in zip(x, s))
per_corner = {sum(in_pattern(c, s) for s in corners) for c in corners}
print(f"mistake, box topology: on {k} dials {len(corners)} corners, each in exactly "
      f"{min(per_corner)} of the {2 ** k} boxes, so all {2 ** k} are needed")

print("Part 4: finite cases, every case checked")
S = frozenset("abc")
SUBS = [frozenset(c) for r in range(4) for c in combinations(sorted(S), r)]
fams = [frozenset(f) for r in range(len(SUBS) + 1) for f in combinations(SUBS, r)]
def fip(f):                                # every finite subfamily has a common point
    return all(S.intersection(*g) for r in range(1, len(f) + 1) for g in combinations(f, r))
good = [f for f in fams if fip(f)]
incl_excl = 3 * 2 ** 4 - 3 * 2 ** 2 + 1 * 2 ** 1
top = [f for f in good if not any(f < g for g in good)]
by_point = all(any(f == {A for A in SUBS if x in A} for x in S) for f in top)
decides = all(A in f or S - A in f for f in top for A in SUBS)
print(f"Zorn, 3 points: {len(fams)} families of subsets; {len(good)} have the FIP "
      f"(inclusion-exclusion {incl_excl}); {len(top)} maximal")
print(f"  each maximal one is the {len(top[0])} sets holding one point: {yn(by_point)}; "
      f"holds A or its outside: {yn(decides)}")
m = 10                                     # ten boxes of two socks, plus the extra point p
masks = {}
for y in product(("left", "right", "p"), repeat=m):
    key = sum(1 << i for i, v in enumerate(y) if v != "p")
    masks[key] = masks.get(key, 0) + 1
common = {T: sum(c for M, c in masks.items() if M & T == T) for T in range(2 ** m)}
formula = all(common[T] == 2 ** bin(T).count("1") * 3 ** (m - bin(T).count("1")) for T in common)
print(f"Kelley, {m} boxes of 2 socks plus p: {3 ** m} points; all {2 ** m} subfamilies of F_1..F_{m} "
      f"meet: {yn(min(common.values()) > 0)}; smallest common set {min(common.values())} = the full picks")
print(f"  common points of F_1, F_2, F_3: {common[7]}; of all {m}: {common[2 ** m - 1]}")
assert walk == [0, 9, 8, 7, 6, 5, 4, 3, 2, 1] and smallest == [tuple(range(10))]   # roads 1, 2
assert hits == [1] * 10 and best == len(witness)                       # road 3 lower bound
assert zero_left and gone == 999 and open_gone == 1000
assert [len(near[3]), len(near[10]), len(in_box)] == [D - 3, D - 10, 0] and sup == {1}
assert per_corner == {1} and len(good) == incl_excl and len(top) == 3 and by_point
assert formula and common[2 ** m - 1] == 2 ** m and decides
print("figure, arcs in degrees from east: " + "; ".join(
    f"U_{n} {360 * arc(n)[0]}..{360 * arc(n)[1]}" for n in range(10)))
print("ALL CHECKS PASS")
