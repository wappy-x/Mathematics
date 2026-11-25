# Proof complexity and resolution -- the check behind the card.  Only math is
# imported (log10, factorial).  The rota: n + 1 staff, n shifts, every staff member
# needs a shift and no two share one: the pigeonhole formula PHP(n + 1, n).
# Roads: brute force over every assignment; a hand-written resolution proof,
# checked line by line; a DPLL search read back as a resolution proof; a
# cutting-plane proof in integer arithmetic; Haken's critical assignments.
import math

def php(n):                      # variable i*n + j + 1 means "staff i works shift j"
    v = lambda i, j: i * n + j + 1
    cl = [frozenset(v(i, j) for j in range(n)) for i in range(n + 1)]
    for j in range(n):
        for i in range(n + 1):
            for k in range(i + 1, n + 1):
                cl.append(frozenset((-v(i, j), -v(k, j))))
    return cl

def holds(c, a):                 # a is a bitmask: bit v - 1 set means variable v is true
    return any((a >> (abs(l) - 1) & 1) == (l > 0) for l in c)

def models(cls, nv):             # road 1: try every assignment
    return sum(all(holds(c, a) for c in cls) for a in range(2 ** nv))

def name(l):                     # PHP(3, 2) only: staff a(nn), b(ob), k(im); shift 1 early, 2 late
    return ("-" if l < 0 else "") + "abk"[(abs(l) - 1) // 2] + str((abs(l) - 1) % 2 + 1)

def show(c):
    return " v ".join(name(l) for l in sorted(c, key=lambda l: (abs(l), l < 0))) or "empty"

def lit(s):
    return -lit(s[1:]) if s[0] == "-" else "abk".index(s[0]) * 2 + int(s[1])

def check(axioms, steps):        # the proof checker: every step a true resolvent of known clauses
    known = set(axioms)
    for ci, cj, x, r in steps:
        assert ci in known and cj in known and x in ci and -x in cj
        assert r == (ci | cj) - {x, -x} and not any(-l in r for l in r)
        known.add(r)
    return steps[-1][3] == frozenset()

def dpll(cls):                   # road 3: branch on variables in order, read the tree as resolution
    steps = []
    def go(asg):
        for c in cls:
            if all(asg.get(abs(l)) == (l < 0) for l in c):
                return c         # a clause this partial assignment makes false: a leaf
        x = len(asg) + 1
        asg[x] = True; c1 = go(asg)
        asg[x] = False; c0 = go(asg)
        del asg[x]
        if -x not in c1: return c1
        if x not in c0: return c0
        r = (c1 - {-x}) | (c0 - {x}); steps.append((c0, c1, x, r)); return r
    go({})
    return steps

def cutting_planes(n):           # road 4: lines are sum(coefficient * variable) >= right side
    v = lambda i, j: i * n + j + 1
    def comb(terms):             # a sum of earlier lines times whole numbers 0 or more
        co, rhs = {}, 0
        for m, (c, b) in terms:
            for k, a in c.items(): co[k] = co.get(k, 0) + m * a
            rhs += m * b
        return {k: a for k, a in co.items() if a}, rhs
    def div(line, d):            # divide by d, rounding the right side up
        assert all(a % d == 0 for a in line[0].values())
        return {k: a // d for k, a in line[0].items()}, -((-line[1]) // d)
    pair = lambda i, k, j: ({v(i, j): -1, v(k, j): -1}, -1)
    count, holes = 1, []
    for j in range(n):
        s = pair(0, 1, j)        # "at most one of staff 0 and 1 on shift j"
        for k in range(2, n + 1):
            s = div(comb([(k - 1, s)] + [(1, pair(i, k, j)) for i in range(k)]), k)
            count += 2
        holes.append(s)
    staff = [({v(i, j): 1 for j in range(n)}, 1) for i in range(n + 1)]
    return count, comb([(1, s) for s in staff + holes]), holes

def critical(n):                 # Haken: n staff matched one-to-one to n shifts, one left out
    out = []
    def place(rest, j, a):
        if j == n: out.append(a); return
        for i in rest:
            place([r for r in rest if r != i], j + 1, a | 1 << (i * n + j))
    for left in range(n + 1):
        place([i for i in range(n + 1) if i != left], 0, 0)
    return out

F = php(2)
print(f"PHP(3, 2): 3 staff, 2 shifts, 6 variables, {len(F)} clauses")
for t in range(0, 9, 3):
    print("  " + "   ".join(f"({t + s + 1}) {show(F[t + s])}" for s in range(3)))
print(f"road 1, brute force: {2 ** 6} assignments, {models(F, 6)} make every clause true")
HAND = [(2, 4, "b1", "-a1 v b2"), (3, 5, "k1", "-a1 v k2"), (10, 9, "b2", "-a1 v -k2"),
        (11, 12, "k2", "-a1"), (2, 7, "b2", "-a2 v b1"), (3, 8, "k2", "-a2 v k1"),
        (14, 6, "b1", "-a2 v -k1"), (15, 16, "k1", "-a2"), (1, 13, "a1", "a2"), (18, 17, "a2", "empty")]
L, steps = list(F), []
for i, j, p, claim in HAND:
    L.append(frozenset(lit(s) for s in claim.split(" v ")) if claim != "empty" else frozenset())
    steps.append((L[i - 1], L[j - 1], lit(p), L[-1]))
    print(f"  ({len(L)}) {claim:<9} from ({i}) and ({j}), on {p}")
ok = check(F, steps)
sound = all(holds(r, a) or not (holds(ci, a) and holds(cj, a)) for ci, cj, _, r in steps for a in range(64))
print(f"road 2, hand proof: {len(steps)} resolution steps, checker accepts and ends empty: {'yes' if ok else 'no'}")
print(f"  each step true wherever both its parents are true, all 64 assignments: {'yes' if sound else 'no'}")
crit = critical(2)
lone = [a for a in range(64) if [k for k in range(9) if not holds(F[k], a)] in ([0], [1], [2])]
print(f"critical assignments: {len(crit)} by matching, {len(lone)} by brute force, 3! = 6")
mono = lambda c: frozenset(x for l in c for x in ([l] if l > 0 else  # -x_ij becomes "someone else on j"
                 [k * 2 + (abs(l) - 1) % 2 + 1 for k in range(3) if k != (abs(l) - 1) // 2]))
agree = all(holds(r, a) == holds(mono(r), a) for _, _, _, r in steps for a in crit)
print(f"  (13) -a1 on critical assignments reads {show(mono(L[12]))}; all 10 lines agree: {'yes' if agree else 'no'}")
print("n  staff  vars  clauses  models  resolution-by-DPLL  cutting-plane-lines")
pts = []
for n in range(1, 7):
    cls = php(n)
    st = dpll(cls)
    cp, last, holes = cutting_planes(n)
    m = str(models(cls, n * (n + 1))) if n <= 3 else "-"
    assert check(cls, st) and last == ({}, 1)               # both proofs valid, cutting planes ends 0 >= 1
    assert all(h == ({j * 1 + i * n + 1: -1 for i in range(n + 1)}, -1) for j, h in enumerate(holes))
    assert len(critical(n)) == math.factorial(n + 1)
    pts.append((math.log10(len(st)), math.log10(cp)))
    print(f"{n}  {n + 1:>5}  {n * (n + 1):>4}  {len(cls):>7}  {m:>6}  {len(st):>18}  {cp:>19}")
print("chart, log10 resolution-by-DPLL:", ", ".join(f"{p[0]:.2f}" for p in pts))
print("chart, log10 cutting-plane lines:", ", ".join(f"{p[1]:.2f}" for p in pts))
two = [frozenset((1, 2)), frozenset((-1, -2))]          # Ann early or late, and not both
bad = (two[0] | two[1]) - {1, -1, 2, -2}
print(f"mistake 1, two pivots at once on a1 v a2 and -a1 v -a2: {show(bad)}, yet {models(two, 2)} of 4 assignments work")
fits = [a for a in range(64) if all(holds(c, a) for c in F[:8])]
print(f"mistake 2, clause (9) dropped: {len(fits)} rota fits, "
      f"{', '.join(name(v) for v in range(1, 7) if fits[0] >> (v - 1) & 1)} true")
print(f"mistake 3, DPLL's proof read as the shortest: {len(dpll(F))} steps, the hand proof has {len(HAND)}")
assert models(F, 6) == 0 and ok and sound and agree                 # unsatisfiable, and the proof holds
assert len(crit) == len(lone) == 6 and sorted(crit) == sorted(lone)  # two roads to Haken's assignments
assert bad == frozenset() and models(two, 2) == 2 and len(fits) == 1
print("ALL CHECKS PASS")
