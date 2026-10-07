# The chromatic polynomial -- the check behind the card.  Nothing is imported.  Rooms are dots, a
# shared wall is a line, and a colouring is proper when no wall carries the same colour on both sides.
# Four roads to every count: try all q^n colourings, run the deletion-contraction recursion on
# polynomial coefficients, add and subtract over sets of walls, and the closed forms.
def ring(n): return (n, [(i, (i + 1) % n) for i in range(n)])
def path(n): return (n, [(i, i + 1) for i in range(n - 1)])
ROW, RING, TRI, PATH3, QS, Q = path(4), ring(4), ring(3), path(3), list(range(6)), 3
HATCH = (4, RING[1] + [(1, 3)])            # a hatch makes rooms 2 and 4 neighbours as well
def brute(g, q):                           # road 1: try every one of the q^n colourings
    n, edges = g
    return sum(all(code // q ** u % q != code // q ** v % q for u, v in edges) for code in range(q ** n))
def contract(g, e):                        # fuse a wall's two ends into one dot
    (n, edges), (u, v) = g, e
    to = {x: (u if x == v else x) - (1 if (u if x == v else x) > v else 0) for x in range(n)}
    fused = {(min(to[a], to[b]), max(to[a], to[b])) for a, b in edges if to[a] != to[b]}
    return (n - 1, sorted(fused))
def chrom(g):                              # road 2: deletion minus contraction
    n, edges = g
    if not edges: return [0] * n + [1]     # no walls left: q^n, every room free
    keep, gone = chrom((n, edges[1:])), chrom(contract(g, edges[0]))
    return [a - b for a, b in zip(keep, gone + [0] * (len(keep) - len(gone)))]
def at(p, q): return sum(a * q ** i for i, a in enumerate(p))
def pieces(n, edges):                      # how many separate pieces a set of walls leaves
    home = list(range(n))
    for _ in range(n):
        for a, b in edges: home[a] = home[b] = min(home[a], home[b])
    return len(set(home))
def by_sets(g, q):                         # road 3: add and subtract over sets of walls
    n, edges = g
    return sum((-1) ** bin(m).count("1") * q ** pieces(n, [e for i, e in enumerate(edges) if m >> i & 1])
               for m in range(2 ** len(edges)))
def chi(g): return next(q for q in range(1, 9) if brute(g, q) > 0)
def show(p):                               # coefficients into q^4 - 4q^3 + 6q^2 - 3q
    term = lambda i, a: ("" if abs(a) == 1 and i else str(abs(a))) + ("q" if i else "") + (f"^{i}" if i > 1 else "")
    return " ".join([("- " if a < 0 else "+ ") + term(i, a) for i, a in enumerate(p) if a][::-1]).lstrip("+ ")
hatch_closed, chis = Q * (Q - 1) * (Q - 2) ** 2, [chi(g) for g in (ROW, RING, TRI, HATCH)]
poly_chis = [min(q for q in range(1, 9) if at(chrom(g), q) > 0) for g in (ROW, RING, TRI, HATCH)]
tab = [("colours q", QS), ("row, every colouring tried", [brute(ROW, q) for q in QS]),
       ("row, q(q-1)^3", [q * (q - 1) ** 3 for q in QS]),
       ("ring, every colouring tried", [brute(RING, q) for q in QS]),
       ("ring, deletion minus contraction", [at(chrom(RING), q) for q in QS]),
       ("ring, add and subtract over wall sets", [by_sets(RING, q) for q in QS]),
       ("ring, (q-1)^4 + (q-1)", [(q - 1) ** 4 + (q - 1) for q in QS]),
       ("triangle, every colouring tried", [brute(TRI, q) for q in QS])]
print(f"the row: {ROW[0]} rooms, {len(ROW[1])} shared walls;  the ring: {RING[0]} rooms, "
      f"{len(RING[1])} walls;  the triangle: {TRI[0]} rooms, {len(TRI[1])} walls")
for lab, vals in tab: print(f"{lab:<37}" + "".join(f"{v:>5}" for v in vals))
print(f"the ring's polynomial, by recursion: {show(chrom(RING))}")
print(f"{Q} colours: row {brute(ROW, Q)} = ring {brute(RING, Q)} + triangle {brute(TRI, Q)}")
print(f"fewest colours that work, by search {chis}, off the polynomial {poly_chis}")
print(f"a hatch between rooms 2 and 4, {Q} colours: ring {brute(RING, Q)} - path {brute(PATH3, Q)} = {brute(HATCH, Q)}, and q(q-1)(q-2)^2 = {hatch_closed}")
print(f"rings of 3, 4 and 5 rooms: {Q} colours give {[brute(ring(n), Q) for n in (3, 4, 5)]}, 2 colours give {[brute(ring(n), 2) for n in (3, 4, 5)]}")
print(f"mistake 1, the wall between rooms 4 and 1 ignored: {brute(ROW, Q)}, not {brute(RING, Q)}")
print(f"mistake 2, the recurrence read with a plus: {brute(ROW, Q)} + {brute(TRI, Q)} = {brute(ROW, Q) + brute(TRI, Q)}, above the {brute(ROW, Q)} with no wall there at all")
print(f"mistake 3, the contraction's count alone: {brute(TRI, Q)}, the colourings where 4 and 1 match")
assert tab[3][1] == tab[4][1] == tab[5][1] == tab[6][1]
assert tab[1][1] == tab[2][1] == [by_sets(ROW, q) for q in QS]
assert brute(ROW, Q) == brute(RING, Q) + brute(TRI, Q) and chrom(RING) == [0, -3, 6, -4, 1]
assert brute(HATCH, Q) == brute(RING, Q) - brute(PATH3, Q) == hatch_closed and chis == [2, 2, 3, 3] == poly_chis
print("ALL CHECKS PASS")
