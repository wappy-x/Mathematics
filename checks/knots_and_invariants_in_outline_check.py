# Knots and invariants in outline -- the check behind the card.  Standard
# library only.  Road 1 builds the trefoil as a closed curve in space, looks
# down on it, and reads the diagram: its crossings, their order, over or under.
# Road 2 works with that reading alone, a Gauss code, and tests every choice
# of over and under two ways for a proof that the loop is the unknot.
from itertools import permutations, product
from math import cos, sin, pi

STEPS = 720                                       # straight pieces per loop
trefoil = lambda t: (sin(t) + 2 * sin(2 * t), cos(t) - 2 * cos(2 * t), sin(3 * t))
ring_a = lambda t: (cos(t), sin(t), 0.0)          # the Hopf link: two rings,
ring_b = lambda t: (1 + cos(t), 0.3 * sin(t), sin(t))   # hooked through each other once

def crossings(loops):
    """Every point where two pieces cross, seen from above, with heights."""
    pts = [[f(2 * pi * k / STEPS) for k in range(STEPS)] for f in loops]
    segs = [(c, k) for c in range(len(loops)) for k in range(STEPS)]
    found = []
    for i, (c1, k1) in enumerate(segs):
        p, q = pts[c1][k1], pts[c1][(k1 + 1) % STEPS]
        for c2, k2 in segs[i + 1:]:
            if c1 == c2 and (k2 - k1) % STEPS in (1, STEPS - 1):
                continue                          # neighbours share an end point
            r, s = pts[c2][k2], pts[c2][(k2 + 1) % STEPS]
            d = (q[0] - p[0]) * (s[1] - r[1]) - (q[1] - p[1]) * (s[0] - r[0])
            if d == 0:
                continue
            u = ((r[0] - p[0]) * (s[1] - r[1]) - (r[1] - p[1]) * (s[0] - r[0])) / d
            v = ((r[0] - p[0]) * (q[1] - p[1]) - (r[1] - p[1]) * (q[0] - p[0])) / d
            if 0 <= u < 1 and 0 <= v < 1:
                z1, z2 = p[2] + u * (q[2] - p[2]), r[2] + v * (s[2] - r[2])
                xy = (p[0] + u * (q[0] - p[0]), p[1] + u * (q[1] - p[1]))
                found.append((c1, k1 + u, c2, k2 + v, z1 > z2, xy))
    return found

def gauss_code(found):
    """Walk the loop from t = 0; name crossings 1, 2, 3 in order of first visit."""
    visits = sorted([(f[1], f[4], n) for n, f in enumerate(found)]
                    + [(f[3], not f[4], n) for n, f in enumerate(found)])
    names = {}
    for _, _, n in visits:
        names.setdefault(n, len(names) + 1)
    return [(names[n], up) for _, up, n in visits], names

def show(word):
    return " ".join(("O" if up else "U") + str(c) for c, up in word)

def descending(word):
    """Road A: some start and direction meets every crossing first as over."""
    n = len(word)
    for start, step in product(range(n), (1, -1)):
        seen, ok = set(), True
        for j in range(n):
            c, up = word[(start + step * j) % n]
            if c not in seen:
                seen.add(c)
                ok = ok and up
        if ok:
            return True
    return n == 0

def untwists(word):
    """Road B: delete kinks (a crossing visited twice in a row) until none is left."""
    word = list(word)
    while word:
        n = len(word)
        hit = [i for i in range(n) if word[i][0] == word[(i + 1) % n][0]]
        if not hit:
            return False
        word = [w for j, w in enumerate(word) if j not in (hit[0], (hit[0] + 1) % n)]
    return True

def gaps(word):                                   # letters between a crossing's two visits
    pos = {}
    for i, (c, _) in enumerate(word):
        pos.setdefault(c, []).append(i)
    return [pos[c][1] - pos[c][0] - 1 for c in sorted(pos)]

def choose(shadow, pick):                         # over/under: pick says first visit is over
    seen = {}
    return [(c, pick[c - 1] == (seen.setdefault(c, k) == k)) for k, c in enumerate(shadow)]

alternating = lambda w: all(w[i][1] != w[(i + 1) % len(w)][1] for i in range(len(w)))
yn = lambda claim: "yes" if claim else "no"

tre = crossings([trefoil])
code, names = gauss_code(tre)
hopf = crossings([ring_a, ring_b])
between = sum(1 for f in hopf if f[0] != f[2])
print("Road 1: the trefoil as a curve in space, seen from above")
print(f"crossings in the drawing: {len(tre)}")
print(f"walk from t = 0: {show(code)}")
print(f"over and under alternate: {yn(alternating(code))}")
spots = sorted((names[n], f[5]) for n, f in enumerate(tre))
print("figure, " + ", ".join(f"crossing {c} at ({x:.3f}, {y:.3f})" for c, (x, y) in spots))
print(f"Hopf link: 2 loops, crossings between them {between}, of a loop with itself {len(hopf) - between}")
print("Road 2: the Gauss code alone")
print(f"letters between the two visits to crossings 1, 2, 3: {gaps(code)}")
print(f"the trefoil as drawn: descending {yn(descending(code))}, untwists {yn(untwists(code))}")
diagrams = [choose([c for c, _ in code], pick) for pick in product((True, False), repeat=3)]
down = [d for d in diagrams if descending(d)]
stuck = [d for d in diagrams if not descending(d)]
runs = {frozenset((s + j) % 6 for j in range(3)) for s in range(6)}
in_a_row = sum(frozenset(k for k, (_, up) in enumerate(d) if up) in runs for d in diagrams)
print(f"the 8 over/under choices on the trefoil's shadow: {len(down)} descending, {len(stuck)} not")
print(f"over at three passages in a row, counted directly: {in_a_row}")
print(f"the two that are not: {show(stuck[0])} and {show(stuck[1])}; "
      f"both alternate: {yn(all(alternating(d) for d in stuck))}")
flips = [descending([(c, up != (c == x)) for c, up in code]) for x in (1, 2, 3)]
print(f"change crossing 1, 2 or 3 alone, then descending: {', '.join(yn(f) for f in flips)}")
print("every Gauss word, every over/under choice, for n = 1 to 3 crossings:")
census = {}
for n in (1, 2, 3):
    words = sorted(set(permutations([c for c in range(1, n + 1) for _ in (0, 1)])))
    even = [w for w in words if all(g % 2 == 0 for g in gaps([(c, 0) for c in w]))]
    ds = [choose(w, pick) for w in even for pick in product((True, False), repeat=n)]
    dn, kn = [descending(d) for d in ds], [untwists(d) for d in ds]
    census[n] = (len(ds), sum(dn), sum(kn), [d for d, a, b in zip(ds, dn, kn) if not (a or b)])
    print(f"n = {n}: {len(words)} words, {len(even)} pass the even test, {len(ds)} diagrams; "
          f"descending {sum(dn)}, untwist by kinks {sum(kn)}, either {len(ds) - len(census[n][3])}")
left = census[3][3]
abc = all(d[0][0] == d[3][0] and d[1][0] == d[4][0] and d[2][0] == d[5][0] for d in left)
print(f"neither at 3 crossings: {len(left)}, all of shape abcabc: {yn(abc)}, "
      f"all alternating: {yn(all(alternating(d) for d in left))}")
kinked, granny = code + [(4, True), (4, False)], code + [(c + 3, up) for c, up in code]
print(f"kinked trefoil {show(kinked)}: {len(kinked) // 2} crossings, descending {yn(descending(kinked))}")
print(f"granny knot, two trefoils joined: {len(granny) // 2} crossings, descending {yn(descending(granny))}")
print(f"mistake 1, crossings in one drawing: unknot round {len(crossings([ring_a]))}, with one kink {len(gaps([(1, True), (1, False)]))}")
print(f"mistake 2, loops counted: unknot 1, trefoil {len([trefoil])}, Hopf link {len([ring_a, ring_b])}")
print(f"mistake 3, the shadow without over/under: {len(down)} of {len(diagrams)} choices are the unknot")
assert len(tre) == 3 and show(code) == "O1 U2 O3 U1 O2 U3"       # road 1 matches the hand reading
assert alternating(code) and not descending(code) and gaps(code) == [2, 2, 2]
assert len(down) == in_a_row == 6                                 # descending = over three in a row
assert all(flips) and between == 2 and len(hopf) == 2
assert all(census[n][0] == census[n][1] == census[n][2] for n in (1, 2))   # roads A and B agree
assert len(left) == 12 and abc and all(alternating(d) for d in left)
print("ALL CHECKS PASS")
