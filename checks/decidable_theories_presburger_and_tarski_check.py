# Decidable theories -- the check behind the card.  Standard library only.
# Part 1: a decision procedure for Presburger arithmetic (0, 1, +, <, on the
#         numbers 0, 1, 2, ...) by quantifier elimination with congruences,
#         checked against brute-force search on every x up to 59.
# Part 2: definable sets are eventually periodic; the squares are not.
# Part 3: over the reals, "some x has x^2 + bx + c = 0" against a grid search.
T, F, COUNT = ("T",), ("F",), [0]
def gcd(a, b): return gcd(b, a % b) if b else a
def lcm(a, b): return a * b // gcd(a, b)
def atom(kind, m, cs, k):          # cs.(x, y, w) + k >= 0, or m divides it ("dvd"), or not ("ndvd")
    if any(cs): return (kind, m, tuple(cs), k)
    return T if (k >= 0 if kind == "ge" else (k % m == 0) == (kind == "dvd")) else F
def join(op, fs):                  # "and" / "or", flattened, constants folded, repeats dropped
    (stop, unit), out = (F, T) if op == "and" else (T, F), []
    for f in fs:
        for g in (f[1] if f[0] == op else (f,)):
            if g == stop: return stop
            if g != unit and g not in out: out.append(g)
    return unit if not out else out[0] if len(out) == 1 else (op, tuple(out))
def amap(f, fn):                   # apply fn to every atom of a quantifier-free formula
    if f[0] in ("and", "or"): return join(f[0], [amap(g, fn) for g in f[1]])
    return f if f in (T, F) else fn(f)
def atoms(f): return [a for g in f[1] for a in atoms(g)] if f[0] in ("and", "or") else [] if f in (T, F) else [f]
def neg(f):                        # push "not" down to the atoms
    if f[0] in ("and", "or"): return join("or" if f[0] == "and" else "and", [neg(g) for g in f[1]])
    if f in (T, F): return F if f == T else T
    kind, m, cs, k = f
    if kind == "ge": return atom("ge", None, [-c for c in cs], -k - 1)
    return atom("ndvd" if kind == "dvd" else "dvd", m, cs, k)
def elim(v, f, keep_div=True, offsets=True):   # "some v >= 0 has f", rewritten without v
    L = 1
    for a in atoms(f):
        if a[2][v]: L = lcm(L, abs(a[2][v]))
    def scale(a):                  # make v's coefficient +1 or -1: z stands for L * v
        kind, m, cs, k = a
        if not cs[v]: return a
        c = L // abs(cs[v]); cs2 = [c * x for x in cs]; cs2[v] = 1 if cs[v] > 0 else -1
        return atom(kind, m and m * c, cs2, k * c)
    unit = [0, 0, 0]; unit[v] = 1
    g = join("and", [amap(f, scale), atom("dvd", L, unit, 0) if keep_div else T, atom("ge", None, unit, 0)])
    D, B = 1, []
    for kind, m, cs, k in atoms(g):
        if cs[v] and kind != "ge": D = lcm(D, m)
        if kind == "ge" and cs[v] == 1:            # z >= -(rest): a lower bound
            b = ([0 if i == v else -cs[i] for i in range(3)], -k)
            if b not in B: B.append(b)
    def put(a, b, j):              # replace z by b + j
        kind, m, cs, k = a; cz = cs[v]
        return atom(kind, m, [0 if i == v else cs[i] + cz * b[0][i] for i in range(3)], k + cz * (b[1] + j))
    COUNT[0] += len(B) * (D if offsets else 1)
    return join("or", [amap(g, lambda a: put(a, b, j)) for b in B for j in range(D if offsets else 1)])
def qe(f, **kw):
    if f[0] in ("and", "or"): return join(f[0], [qe(g, **kw) for g in f[1]])
    if f[0] == "not": return neg(qe(f[1], **kw))
    if f[0] == "ex": return elim(f[1], qe(f[2], **kw), **kw)
    if f[0] == "all": return neg(elim(f[1], neg(qe(f[2], **kw)), **kw))
    return f
def holds(f, x):
    if f in (T, F): return f == T
    if f[0] in ("and", "or"): return (all if f[0] == "and" else any)(holds(g, x) for g in f[1])
    kind, m, cs, k = f; s = cs[0] * x + k
    return s >= 0 if kind == "ge" else (s % m == 0) == (kind == "dvd")
def show(f):                       # print a formula in x alone
    if f in (T, F): return "true" if f == T else "false"
    if f[0] in ("and", "or"): return "(" + f" {f[0]} ".join(show(g) for g in f[1]) + ")"
    kind, m, cs, k = f
    t = ("-x" if cs[0] < 0 else "x") + (f" + {k}" if k > 0 else f" - {-k}" if k < 0 else "")
    return f"{t} >= 0" if kind == "ge" else f"{m} {'|' if kind == 'dvd' else 'does not divide'} {t}"
def eq(cs, k): return join("and", [atom("ge", None, cs, k), atom("ge", None, [-c for c in cs], -k)])
def iff(a, b): return ("and", (("or", (("not", a), b)), ("or", (a, ("not", b)))))
EVEN = ("ex", 1, ("or", (eq([1, -2, 0], 0), eq([1, -2, 0], -1))))      # x = 2y or x = 2y + 1
THIRD = ("ex", 1, eq([-1, 3, 0], -1))                                 # 3y = x + 1
STAMP = ("ex", 1, ("ex", 2, eq([1, -3, -5], 0)))                      # x = 3y + 5w
X = range(60)
brute = {"EVEN": [any(x in (2 * y, 2 * y + 1) for y in X) for x in X],
         "THIRD": [any(3 * y == x + 1 for y in range(61)) for x in X],
         "STAMP": [any(3 * y + 5 * w == x for y in X for w in X) for x in X]}
print("part 1: quantifier elimination, free variable x = 0 to 59")
psi = {}
for name, f in (("EVEN", EVEN), ("THIRD", THIRD), ("STAMP", STAMP)):
    COUNT[0] = 0; psi[name] = p = qe(f)
    got = [holds(p, x) for x in X]
    print(f"{name:<5}: candidates {COUNT[0]:>3}, atoms left {len(atoms(p)):>3}, true for {sum(got)} of 60, brute force {sum(brute[name])} of 60")
    assert got == brute[name], "elimination disagrees with search"
print("EVEN  becomes", show(psi["EVEN"]))
print("THIRD becomes", show(psi["THIRD"]))
mod3 = [holds(psi["THIRD"], x) for x in X] == [x % 3 == 2 for x in X]
print("THIRD true exactly when x mod 3 = 2:", mod3, " at x = 4:", holds(psi["THIRD"], 4), " at x = 5:", holds(psi["THIRD"], 5), " STAMP false at:", *[x for x in X if not holds(psi["STAMP"], x)])
SENT = [("for all x, some y: x = 2y or x = 2y + 1", ("all", 0, EVEN)),
        ("for all x, some y: 3y = x + 1", ("all", 0, THIRD)),
        ("for all x: (some y: 3y = x + 1) iff 3 divides x + 1", ("all", 0, iff(THIRD, atom("dvd", 3, [1, 0, 0], 1)))),
        ("for all x >= 8, some y, w: x = 3y + 5w", ("all", 0, ("or", (atom("ge", None, [-1, 0, 0], 7), STAMP)))),
        ("for all x >= 7, some y, w: x = 3y + 5w", ("all", 0, ("or", (atom("ge", None, [-1, 0, 0], 6), STAMP))))]
verdict = []
for text, s in SENT:
    COUNT[0] = 0; r = qe(s); verdict.append(r)
    print(f"decide: {text:<52} -> {'true' if r == T else 'false'}  ({COUNT[0]} candidates)")
assert verdict == [T, F, T, T, F] and mod3, "the five verdicts, and 3y = x + 1 means x mod 3 = 2"
fam = [(a, m, k, r) for a in (1, 2, 3) for m in (2, 3, 4, 5) for k in (0, 1, 2) for r in (0, 1, 2)]
bad = [(a, m, k, r) for a, m, k, r in fam if [holds(qe(("ex", 1, ("and", (atom("ge", None, [-1, a, 0], -k),
       atom("ge", None, [1, -a, 0], k + 2), atom("dvd", m, [0, 1, 0], r))))), x) for x in X]
       != [any(x + k <= a * y <= x + k + 2 and (y + r) % m == 0 for y in range(70)) for x in X]]
print(f"family: some y, x + k <= ay <= x + k + 2 and m | y + r, a <= 3, m <= 5, k, r <= 2: {len(fam) - len(bad)} of {len(fam)} agree")
assert not bad, "elimination disagrees with search on the family"
print("part 2: eventually periodic sets")
for name, p in psi.items():
    per, start = 1, 0
    for kind, m, cs, k in atoms(p):
        if kind == "ge": start = max(start, abs(k) + 1)
        else: per = lcm(per, m)
    ok = all(holds(p, x) == holds(p, x + per) for x in range(start, start + 300))
    print(f"{name:<5}: repeats with period {per} from x = {start}: {ok}")
    assert ok, "a definable set must be eventually periodic"
sq = set(n * n for n in range(200))
broken = sum(any(n * n >= s and n * n + p not in sq for n in range(200)) for p in range(1, 41) for s in range(101))
print(f"squares: (period p <= 40, start s <= 100) pairs broken by some n^2 with n^2 + p not square: {broken} of 4040")
assert broken == 4040, "no period fits the squares"
for name, row in psi.items(): print(f"{name:<7}", "".join("#" if holds(row, x) else "." for x in range(30)))
print("squares", "".join("#" if x in sq else "." for x in range(30)))
print("what breaks")
for label, name, f, kw in (("drop 'L divides z'", "THIRD", THIRD, dict(keep_div=False)),
                           ("offset j = 0 only", "STAMP", STAMP, dict(offsets=False))):
    r = [holds(qe(f, **kw), x) for x in X]
    print(f"{label}: {name} true for {sum(r)} of 60 (truth {sum(brute[name])})")
    assert r != brute[name], "a broken elimination must give a wrong set"
print("part 3: some real x has x^2 + bx + c = 0, for b, c = -6 to 6")
agree = roots = 0
for b in range(-6, 7):
    for c in range(-6, 7):
        disc = b * b - 4 * c >= 0
        grid = any(k * k + 4 * b * k + 16 * c <= 0 for k in range(-60, 61))   # 16 f(k/4), x from -15 to 15
        agree += disc == grid; roots += disc
for b, c in ((-6, 8), (2, 1), (1, 1)):
    print(f"b = {b}, c = {c}: b^2 - 4c = {b * b - 4 * c}, grid finds x^2 + bx + c <= 0:", any(k * k + 4 * b * k + 16 * c <= 0 for k in range(-60, 61)))
print(f"b^2 - 4c >= 0 against a grid search: agree on {agree} of 169, real root in {roots}")
cube = all(-64 - 4 * b + c < 0 < 64 + 4 * b + c for b in range(-6, 7) for c in range(-6, 7))
print("x^3 + bx + c changes sign between x = -4 and x = 4 for all 169 pairs:", cube)
print("x^2 - 2: b^2 - 4c =", 0 - 4 * -2, "  whole-number roots up to 1000:", [x for x in range(-1000, 1001) if x * x == 2] or "none")
assert agree == 169, "discriminant and grid disagree"
print("ALL CHECKS PASS")
