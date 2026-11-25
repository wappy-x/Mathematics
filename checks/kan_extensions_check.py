# Kan extensions -- the check behind the card.  Nothing is imported.
# A meter is read on days 1, 3 and 5.  F sends each reading day to the log so
# far.  An order is a category with one arrow from a to b when a <= b, so a
# functor on it is a set for each day and a map for each a <= b.  The left and
# right Kan extensions along days {1, 3, 5} -> days 1..6 are built from the
# general colimit and limit, checked against the last-or-next-reading shortcut,
# and checked by their defining property: natural maps counted on both sides.
READ = {1: 1204, 3: 1236, 5: 1271}                     # meter readings, kWh
A, B = [1, 3, 5], [1, 2, 3, 4, 5, 6]
F = {a: [f"d{d}:{READ[d]}" for d in A if d <= a] for a in A}   # log so far
keep = lambda j, k, x: x                               # F(j <= k): the log only grows

def colim(J, S, fmap):          # disjoint union of S[j], glued along every j <= k
    root = {(j, x): (j, x) for j in J for x in S[j]}
    def find(e):
        while root[e] != e:
            e = root[e]
        return e
    for j in J:
        for k in J:
            if j < k:
                for x in S[j]:
                    root[find((j, x))] = find((k, fmap(j, k, x)))
    cls = {}
    for e in root:
        cls.setdefault(find(e), []).append(f"{e[0]}/{e[1]}")
    return sorted("+".join(sorted(c)) for c in cls.values())

def lim(J, S, fmap):            # tuples, one entry per j, that agree along every j <= k
    tups = [[]]
    for j in J:
        tups = [t + [(j, x)] for t in tups for x in S[j]]
    good = [t for t in tups if all(fmap(j, k, x) == y for j, x in t for k, y in t if j < k)]
    return [",".join(f"{j}/{x}" for j, x in t) or "*" for t in good]

def lan(J0, S, fmap, strict=False):                    # left extension along J0 -> B
    sets = {b: colim([a for a in J0 if a < b or (a == b and not strict)], S, fmap) for b in B}
    def m(b, c, x):                                    # a class at b lies in one class at c
        return next(y for y in sets[c] if x.split("+")[0] in y.split("+"))
    return sets, m

def ran(J0, S, fmap):                                  # right extension along J0 -> B
    sets = {b: lim([a for a in J0 if a >= b], S, fmap) for b in B}
    def m(b, c, x):                                    # forget the entries for days before c
        return ",".join(p for p in x.split(",") if p != "*" and int(p.split("/")[0]) >= c) or "*"
    return sets, m

def funcs(X, Y):                                       # every function X -> Y, as image tuples
    out = [()]
    for _ in X:
        out = [f + (y,) for f in out for y in Y]
    return out

def nat(objs, X, xm, Y, ym):    # count natural maps X => Y on a chain of objects
    ways = {f: 1 for f in funcs(X[objs[0]], Y[objs[0]])}
    for c, d in zip(objs, objs[1:]):
        new = {}
        for g in funcs(X[d], Y[d]):
            n = sum(w for f, w in ways.items()
                    if all(ym(c, d, f[i]) == g[X[d].index(xm(c, d, x))] for i, x in enumerate(X[c])))
            if n:
                new[g] = n
        ways = new
    return sum(ways.values())

def test_functor(size, step):                          # G on days 1..6 from one-day steps
    S = {b: [str(v) for v in range(size(b))] for b in B}
    def m(b, c, x):
        for d in range(b, c):
            x = str(step(d, int(x)))
        return x
    return S, m

TESTS = [("two states, held", test_functor(lambda b: 2, lambda d, v: v)),
         ("counter to 2", test_functor(lambda b: 3, lambda d, v: min(v + 1, 2))),
         ("2 states on odd days, 1 on even", test_functor(lambda b: 1 + b % 2, lambda d, v: 0))]
ent = lambda n: f"{n} entry" if n == 1 else f"{n} entries"
label = lambda c: c.replace(",", "+").split("+")[0].split("/")[1]   # the entry a class carries

L, Lm = lan(A, F, keep)
R, Rm = ran(A, F, keep)
print("== the readings: F sends a reading day to the log so far ==")
for a in A:
    print(f"F({a}) = {F[a]}")
print("== the extensions to every day, by the colimit and limit formulas ==")
for b in B:
    last, nxt = max(a for a in A if a <= b), [a for a in A if a >= b]
    lab_l, lab_r = sorted(label(c) for c in L[b]), sorted(label(c) for c in R[b] if c != "*")
    r = f"{ent(len(R[b]))}, newest {lab_r[-1]}" if nxt else f"{len(R[b])} point, no reading"
    print(f"day {b}: left {ent(len(L[b]))}, newest {lab_l[-1]} | right {r}")
    assert lab_l == F[last] and len(lab_l) == len(L[b])                  # shortcut: last reading
    assert (lab_r == F[nxt[0]] and len(lab_r) == len(R[b])) if nxt else R[b] == ["*"]
print(f"day 0, before any reading: left {ent(len(colim([], F, keep)))} (the empty set)")
print("== the defining property: natural maps counted on both sides ==")
GK = lambda S: {a: S[a] for a in A}
for name, (S, m) in TESTS:
    l1, l2 = nat(B, L, Lm, S, m), nat(A, F, keep, GK(S), m)
    r1, r2 = nat(A, GK(S), m, F, keep), nat(B, S, m, R, Rm)
    print(f"G = {name}: Nat(Lan F, G) = {l1}, Nat(F, G K) = {l2}; Nat(G K, F) = {r1}, Nat(G, Ran F) = {r2}")
    assert l1 == l2 and r1 == r2                                         # the two adjunctions
print("== limits and colimits: extend along the functor to one point ==")
X = {a: ["0", "1"] for a in A}
cf, lf = colim(A, F, keep), lim(A, F, keep)
print(f"colimit of F: {ent(len(cf))}; Nat(F, constant 2-set) = {nat(A, F, keep, X, keep)} = 2^{len(cf)}")
print(f"limit of F: {ent(len(lf))}; Nat(constant 2-set, F) = {nat(A, X, keep, F, keep)} = {len(lf)}^2")
assert nat(A, F, keep, X, keep) == 2 ** len(cf) and nat(A, X, keep, F, keep) == len(lf) ** 2
print("== adjoints: 3x <= y exactly when x <= floor(y/3) ==")
grid = range(-30, 31)
lan_id = {y: max(x for x in range(-100, 101) if 3 * x <= y) for y in grid}   # Lan along 3x
ran_id = {x: min(y for y in range(-100, 101) if x <= y // 3) for x in grid}  # Ran along floor
print(f"left extension of the identity along 3x, at y = 20: {lan_id[20]} packs")
print(f"right extension of the identity along floor(y/3), at x = 6: {ran_id[6]} boxes")
ok_l, ok_r = all(lan_id[y] == y // 3 for y in grid), all(ran_id[x] == 3 * x for x in grid)
print(f"equals floor(y/3) on all {len(grid)} y: {'yes' if ok_l else 'no'}; equals 3x on all {len(grid)} x: {'yes' if ok_r else 'no'}")
assert ok_l and ok_r and lan_id[20] == 6 and ran_id[6] == 18
print("== what breaks ==")
glued = sum(len(F[a]) for a in A)
print(f"glue forgotten at day 6: {ent(glued)}, not {len(L[6])}")
print(f"agreement forgotten at day 2: {len(F[3]) * len(F[5])} tuples, not {len(R[2])}")
Ls, Lsm = lan(A, F, keep, strict=True)
S, m = TESTS[2][1]
print(f"strict a < b: day 3 gets {ent(len(Ls[3]))}, not {len(L[3])}; with G = {TESTS[2][0]}, "
      f"Nat(strict, G) = {nat(B, Ls, Lsm, S, m)} against Nat(F, G K) = {nat(A, F, keep, GK(S), m)}")
print(f"left and right swapped at day 6: {ent(len(L[6]))} against {len(R[6])} point")
assert glued == 6 and len(L[6]) == 3 and len(R[2]) == 2 and len(Ls[3]) == 1
assert nat(B, Ls, Lsm, S, m) != nat(A, F, keep, GK(S), m)
print("ALL CHECKS PASS")
