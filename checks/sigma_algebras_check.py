# Sigma-algebras -- the check behind the card.  Nothing is imported.
# A weather station logs rain (R) or dry (D) on each of three days: 8 outcomes.
# A set of outcomes is an 8-bit mask, bit i for outcome W[i]; a family of sets
# is a Python set of masks.  Three roads to each station's family: (1) test all
# 256 sets against the report, (2) close its yes/no questions under the rules,
# (3) count the report's blocks and raise 2 to that power.  Then every family on
# 1 to 4 points is tested against the rules, beside the count of partitions.
W = sorted((a + b + c for a in "DR" for b in "DR" for c in "DR"), key=lambda w: w.count("R"))
N, FULL = len(W), (1 << len(W)) - 1

def where(test):                              # the set of outcomes passing a test
    return sum(1 << i for i in range(N) if test(W[i]))

def show(mask):
    return "{" + " ".join(W[i] for i in range(N) if mask >> i & 1) + "}"

def broken_rule(fam, full):                   # the three rules, in order
    if full not in fam:
        return "rule 1, whole space missing"
    if any(full ^ a not in fam for a in fam):
        return "rule 2, a complement missing"
    if any(a | b not in fam for a in fam for b in fam):
        return "rule 3, a union missing"
    return "none"

def settled(report):                          # road 1: the sets the report decides
    same = [(i, j) for i in range(N) for j in range(N) if report(W[i]) == report(W[j])]
    return {s for s in range(FULL + 1) if all(s >> i & 1 == s >> j & 1 for i, j in same)}

def close(questions):                         # road 2: apply rules 1-3 until nothing is new
    fam = set(questions) | {FULL}
    while True:
        new = {FULL ^ a for a in fam} | {a | b for a in fam for b in fam}
        if new <= fam:
            return fam
        fam |= new

def blocks(report):                           # road 3: outcomes grouped by what is reported
    return len({report(w) for w in W})

def edges(report):                            # figure: block edges, 40 units per outcome
    xs = [20]
    for i in range(N):
        if i == N - 1 or report(W[i]) != report(W[i + 1]):
            xs.append(20 + 40 * (i + 1))
    return xs

rain = [where(lambda w, d=d: w[d] == "R") for d in range(3)]
at_least = [where(lambda w, k=k: w.count("R") >= k) for k in (1, 2, 3)]
week = lambda w: "R" in w
stations = [("no report", lambda w: "", []),
            ("day 1 so far", lambda w: w[:1], rain[:1]),
            ("days 1-2 so far", lambda w: w[:2], rain[:2]),
            ("full log", lambda w: w, rain),
            ("rain-day count", lambda w: w.count("R"), at_least),
            ("any rain this week", week, at_least[:1])]
print("outcomes, by rain days:", " ".join(W))
print(f"{'station':<20}{'blocks':>7}{'road 1':>8}{'road 2':>8}{'2^blocks':>10}  rule broken")
fams, reports = {}, {}
for name, report, questions in stations:
    f1, f2, k = settled(report), close(questions), blocks(report)
    fams[name], reports[name] = f1, report
    print(f"{name:<20}{k:>7}{len(f1):>8}{len(f2):>8}{2 ** k:>10}  {broken_rule(f1, FULL)}")
    assert f1 == f2, name                          # decided-by-report equals closed-up questions
    assert len(f1) == 2 ** k, name                 # the block count predicts the size
    assert broken_rule(f1, FULL) == "none", name   # and the three rules hold
print("the weekly station settles:")
for s in sorted(fams["any rain this week"], key=lambda s: bin(s).count("1")):
    print("   ", show(s))
i, j = next((i, j) for i in range(N) for j in range(i + 1, N)
            if week(W[i]) == week(W[j]) and (rain[1] >> i & 1) != (rain[1] >> j & 1))
print(f"'rain on day 2' is not settled weekly: {W[i]} and {W[j]} report alike, differ on day 2")
assert rain[1] not in fams["any rain this week"]
for chain in (["no report", "day 1 so far", "days 1-2 so far", "full log"],
              ["no report", "any rain this week", "rain-day count", "full log"]):
    nested = all(fams[a] <= fams[b] for a, b in zip(chain, chain[1:]))
    print("nested:", " inside ".join(str(len(fams[c])) for c in chain), "->", "yes" if nested else "no")
    assert nested                             # more information settles more

bad = {0, FULL, rain[0], rain[1]}
miss_c = sum(FULL ^ a not in bad for a in bad)
miss_u = len({a | b for a in bad for b in bad} - bad)
print(f"non-example (empty, whole, rain day 1, rain day 2): {broken_rule(bad, FULL)}")
print(f"  {miss_c} complements and {miss_u} union missing; closed up it has {len(close(bad))} sets,"
      f" the days 1-2 family: {'yes' if close(bad) == fams['days 1-2 so far'] else 'no'}")
assert (miss_c, miss_u) == (2, 1) and close(bad) == fams["days 1-2 so far"]
print(f"mistake, crediting the weekly station with every set: {FULL + 1} claimed, "
      f"{len(fams['any rain this week'])} settled")
print(f"mistake, counting blocks as sets for the rain-day count: {blocks(reports['rain-day count'])}"
      f" claimed, {len(fams['rain-day count'])} settled")

def binom(n, k):
    out = 1
    for t in range(k):
        out = out * (n - t) // (t + 1)
    return out

bell = [1]                                    # partitions of n points, by recurrence
for n in range(8):
    bell.append(sum(binom(n, k) * bell[k] for k in range(n + 1)))

def count_sigma(n):                           # test every family of subsets of n points
    m = 1 << n
    return sum(broken_rule({s for s in range(m) if code >> s & 1}, m - 1) == "none"
               for code in range(1 << m))

brute = [count_sigma(n) for n in range(1, 5)]
print("families tested on 1, 2, 3, 4 points:", [1 << (1 << n) for n in range(1, 5)])
print("sigma-algebras found by testing:     ", brute)
print("partitions of 1 to 8 points:         ", bell[1:])
print(f"sigma-algebras on the station's 8 outcomes: {bell[8]}")
assert brute == bell[1:5]                     # rule-testing and partition-counting agree

ins = [sum(1 for d in range(1, n + 1) if d % 2 == 0) for n in (10, 100, 1000)]
print("first rain on an even day, days 1-10/100/1000: in",
      "/".join(map(str, ins)), "out", "/".join(str(n - e) for n, e in zip((10, 100, 1000), ins)))
for name, report in (("try: rain count on days 1-2", lambda w: w[:2].count("R")),
                     ("try: rain on at least two days", lambda w: w.count("R") >= 2),
                     ("try: day 3 only reported", lambda w: w[2])):
    print(f"{name:<32} blocks {blocks(report)}, sets {len(settled(report))}")
for name in ("full log", "rain-day count", "any rain this week"):
    print(f"figure, {name}: block edges at x =", " ".join(map(str, edges(reports[name]))))
print("ALL CHECKS PASS")
