# Godel's completeness theorem -- the check behind the card.  Standard library
# only, nothing imported.  It runs Henkin's construction on T, the theory of a
# strict order where every point has one after it: witnesses c0 < c1 < c2 ..., then
# Lindenbaum's yes-or-no pass over every atom ci < cj, then the model read off
# the result.  It also checks the 4-line refutation of the cycle theory.
# Consistency test: T's order axioms are Horn clauses (at most one positive
# part), so a set of atoms and negated atoms is consistent with them exactly
# when its transitive closure has no ci < ci and hits no negated atom.  The
# point-after axiom can always be met by new points above, so it adds nothing.

def closure(pos):                        # forward chaining with transitivity
    known = set(pos)
    while True:
        new = {(i, l) for (i, j) in known for (k, l) in known if j == k} - known
        if not new:
            return known
        known |= new

def consistent(pos, neg):
    c = closure(pos)
    return all(i != j for (i, j) in c) and not (c & neg)

def lindenbaum(n, witnesses, yes_first):  # decide every atom, in a fixed list
    pos = {(i, i + 1) for i in range(n - 1)} if witnesses else set()
    neg = set()
    for a in [(i, j) for i in range(n) for j in range(n)]:
        if yes_first:
            (pos if consistent(pos | {a}, neg) else neg).add(a)
        else:
            (neg if consistent(pos, neg | {a}) else pos).add(a)
    return closure(pos), neg

def waiting(n, rel):                     # points with nothing above them
    return [i for i in range(n) if not any((i, j) in rel for j in range(n))]

def show(rel):
    return " ".join(f"c{i}<c{j}" for (i, j) in sorted(rel)) or "(none)"

def all_relations(n):                    # brute force: every relation on n points
    pairs = [(i, j) for i in range(n) for j in range(n)]
    for mask in range(2 ** len(pairs)):
        yield {p for b, p in enumerate(pairs) if mask >> b & 1}

def is_order(n, r):                      # irreflexive and transitive, checked directly
    return all((i, i) not in r for i in range(n)) and all(
        (i, k) in r for (i, j) in r for (j2, k) in r if j == j2)

def two_way(r):
    return any((j, i) in r for (i, j) in r)

L = lambda x, y: ("<", x, y)
IRR = ("not", L("x", "x"))
TRANS = ("imp", ("and", L("x", "y"), L("y", "z")), L("x", "z"))
HYP = ("and", L("a", "b"), L("b", "a"))  # the cycle claim, with witnesses a, b

def match(schema, f, sub):               # is f the schema with x, y, z filled in?
    if isinstance(schema, str):
        return sub.setdefault(schema, f) == f if schema in "xyz" else schema == f
    return (isinstance(f, tuple) and len(f) == len(schema) and f[0] == schema[0]
            and all(match(s, g, sub) for s, g in zip(schema[1:], f[1:])))

def check(proof, axioms):                # each line must earn its place
    for k, (f, why) in enumerate(proof):
        ok = (f == HYP if why == "hypothesis" else
              why in axioms and match(axioms[why], f, {}) if why in ("transitivity", "irreflexivity") else
              why.startswith("mp") and ("imp", proof[int(why[3]) - 1][0], f) == proof[int(why[5]) - 1][0])
        if not ok:
            return f"line {k + 1} rejected"
    lines = [f for f, _ in proof]
    return "contradiction reached" if any(("not", g) in lines for g in lines) else "no contradiction"

proof = [(HYP, "hypothesis"), (("imp", HYP, L("a", "a")), "transitivity"),
         (L("a", "a"), "mp 1 2"), (("not", L("a", "a")), "irreflexivity")]
words = ["a<b and b<a", "(a<b and b<a) -> a<a", "a<a", "not a<a"]

print("Henkin stages for T: stage n has c0..c(n-1) and witnesses c(i) < c(i+1)")
for n in range(1, 7):
    rel, neg = lindenbaum(n, True, True)
    assert rel == {(i, j) for i in range(n) for j in range(n) if i < j}
    assert len(rel) == n * (n - 1) // 2 and len(rel) + len(neg) == n * n
    print(f"stage {n}: atoms decided {n * n}, true {len(rel)}, "
          f"waiting for a witness {['c%d' % i for i in waiting(n, rel)]}")
yes4, _ = lindenbaum(4, True, True)
no4, _ = lindenbaum(4, True, False)
print(f"stage 4, yes-first pass: {show(yes4)}")
print(f"stage 4, no-first pass gives the same set: {'yes' if no4 == yes4 else 'no'}")
brute = [r for r in all_relations(4) if is_order(4, r) and {(0, 1), (1, 2), (2, 3)} <= r]
print(f"brute force over {2 ** 16} relations on 4 points: {len(brute)} model(s) "
      f"with the witness facts, equal to Lindenbaum's: {'yes' if brute == [yes4] else 'no'}")
counts = {"orders": [], "T": [], "cycle": [], "cycle, no transitivity": []}
for n in range(1, 5):
    rels = list(all_relations(n))
    orders = [r for r in rels if is_order(n, r)]
    counts["orders"].append(len(orders))
    counts["T"].append(sum(1 for r in orders if not waiting(n, r)))
    counts["cycle"].append(sum(1 for r in orders if two_way(r)))
    counts["cycle, no transitivity"].append(
        sum(1 for r in rels if two_way(r) and all((i, i) not in r for i in range(n))))
for k, v in counts.items():
    print(f"models on 1, 2, 3, 4 points, {k}: {v}")
print("refutation of the cycle theory:")
for k, (f, why) in enumerate(proof):
    print(f"  {k + 1}. {words[k]:24s} {why}")
print(f"checker: {check(proof, {'transitivity': TRANS, 'irreflexivity': IRR})}")
print(f"forward chaining from a<b, b<a reaches a<a: {'yes' if (0, 0) in closure({(0, 1), (1, 0)}) else 'no'}")
print(f"mistake 1, no witnesses, no-first pass on 4 points: true atoms {show(lindenbaum(4, False, False)[0])}, "
      f"points with nothing above {len(waiting(4, lindenbaum(4, False, False)[0]))} of 4")
everything = {(i, j) for i in range(4) for j in range(4)}
print(f"mistake 2, every atom added unchecked: {len(everything)} true, c(i)<c(i) at "
      f"{sum(1 for i in range(4) if (i, i) in everything)} points, consistent: "
      f"{'yes' if consistent(everything, set()) else 'no'}")
print(f"mistake 3, finite search for T finds {counts['T']}, yet stage 6 above is consistent")
print(f"mistake 4, transitivity dropped: checker says {check(proof, {'irreflexivity': IRR})}; "
      f"a 2-point model exists: {counts['cycle, no transitivity'][1]}")
assert counts["orders"] == [1, 3, 19, 219] and counts["T"] == [0, 0, 0, 0]
assert brute == [yes4] and no4 == yes4 and counts["cycle"] == [0, 0, 0, 0]
assert check(proof, {"transitivity": TRANS, "irreflexivity": IRR}) == "contradiction reached"
assert check([(HYP, "hypothesis"), (("imp", HYP, L("b", "b")), "transitivity")], {"transitivity": TRANS}) == "line 2 rejected"
assert check(proof[:2] + [(L("b", "b"), "mp 1 2")], {"transitivity": TRANS}) == "line 3 rejected"   # modus ponens must match
assert not consistent({(0, 1), (1, 2)}, {(0, 2)})   # transitivity forces c0<c2, which was denied
assert not consistent({(0, 1), (1, 0)}, set()) and consistent(yes4, everything - yes4)
assert check(proof, {"irreflexivity": IRR}) == "line 2 rejected" and counts["cycle, no transitivity"][1] == 1
print("ALL CHECKS PASS")
