# Pullbacks and pushouts -- the check behind the card.  Nothing is imported.
# A pullback of sets is a join of two tables on a shared key; a pushout glues
# two customer lists along a match table.  Each answer is reached by two or
# more roads: the definition row by row, a count by keys or by classes, and
# the universal property counted by brute force over every pair of maps.
ORDERS = [(1001, "Ana"), (1002, "Ben"), (1003, "Ana"), (1004, "Dev"), (1005, "Ben"), (1006, "Ana")]
ADDRESSES = [("Leeds", "Ana"), ("York", "Ana"), ("Hull", "Ben"), ("Bath", "Cai")]
KEYS = ["Ana", "Ben", "Cai", "Dev"]
SHOP1 = ["Ana", "Ben", "Cai", "Dev"]
SHOP2 = ["ana.k", "ben.r", "eve", "fay", "gus"]
MATCH = [("Ana", "ana.k"), ("Ben", "ben.r")]
FAULTY = MATCH + [("Ana", "ben.r"), ("Ben", "ana.k")]  # a shared household phone

def all_maps(n, m):                      # every map from n things to m things, as lists
    out = [[]]
    for _ in range(n):
        out = [f + [v] for f in out for v in range(m)]
    return out

def nested_loop_join(left, right):       # road 1: the definition, every pair tested
    return [(a, b) for a, ka in left for b, kb in right if ka == kb]

def count_by_key(left, right):           # road 2: group by key, multiply the counts
    rows = []
    for c in KEYS:
        n = sum(1 for _, k in left if k == c)
        m = sum(1 for _, k in right if k == c)
        rows.append((c, n, m, n * m))
    return rows

def glue(a_list, b_list, match):         # pushout: union-find on the disjoint union
    nodes = [("A", x) for x in a_list] + [("B", y) for y in b_list]
    parent = {v: v for v in nodes}
    def find(v):
        while parent[v] != v:
            v = parent[v]
        return v
    for x, y in match:
        parent[find(("A", x))] = find(("B", y))
    classes = {}
    for v in nodes:
        classes.setdefault(find(v), []).append(v[1])
    return sorted(sorted(c) for c in classes.values())

def maps_agreeing(a_list, b_list, match):  # road 2: maps into {0, 1} that agree on S
    ia = {x: n for n, x in enumerate(a_list)}
    ib = {y: n for n, y in enumerate(b_list)}
    good = 0
    for u in all_maps(len(a_list), 2):
        for v in all_maps(len(b_list), 2):
            if all(u[ia[x]] == v[ib[y]] for x, y in match):
                good += 1
    return good, 2 ** len(a_list) * 2 ** len(b_list)

def yn(t):
    return "yes" if t else "no"

join = nested_loop_join(ORDERS, ADDRESSES)
by_key = count_by_key(ORDERS, ADDRESSES)
print(f"orders {len(ORDERS)}, addresses {len(ADDRESSES)}, all pairs {len(ORDERS) * len(ADDRESSES)}")
print(f"road 1, every pair tested: {len(join)} matching rows")
for a, b in join:
    print(f"  order {a} -> {b}")
for c, n, m, nm in by_key:
    print(f"road 2, key {c}: {n} orders x {m} addresses = {nm}")
total = sum(r[3] for r in by_key)
print(f"road 2 total: {total}")
# universal property: matching pairs of maps from a 2-row table T
fa = [k for _, k in ORDERS]
gb = [k for _, k in ADDRESSES]
pairs = [(p, q) for p in all_maps(2, len(ORDERS)) for q in all_maps(2, len(ADDRESSES))]
matching = [(p, q) for p, q in pairs if all(fa[p[t]] == gb[q[t]] for t in range(2))]
jpos = [(ia, ib) for ia, (a, ka) in enumerate(ORDERS) for ib, (b, kb) in enumerate(ADDRESSES) if ka == kb]
through = [sum(1 for h in all_maps(2, len(jpos)) if all(jpos[h[t]] == (p[t], q[t]) for t in range(2)))
           for p, q in matching]
print(f"pairs of maps from a 2-row table: {len(pairs)}; matching: {len(matching)} = {len(join)} x {len(join)}")
print(f"maps into the join giving each matching pair: exactly one every time: {yn(set(through) == {1})}")
one_point = nested_loop_join([(a, 0) for a, _ in ORDERS], [(b, 0) for b, _ in ADDRESSES])
cards = [("Ana", "Ana"), ("Ben", "Ben")]   # loyalty-card holders, a subset of the keys
print(f"key set of one point: {len(one_point)} rows, the plain product")
print(f"key map a subset inclusion (card holders Ana, Ben): {len(nested_loop_join(ORDERS, cards))} rows, "
      f"the orders by card holders")
z4z6 = [(x, y) for x in range(4) for y in range(6) if x % 2 == y % 2]
closed = all(((x1 + x2) % 4, (y1 + y2) % 6) in z4z6 for x1, y1 in z4z6 for x2, y2 in z4z6)
inverses = all(((-x) % 4, (-y) % 6) in z4z6 for x, y in z4z6)
print(f"groups: clock-4 and clock-6 over parity: {len(z4z6)} of 24 pairs; "
      f"closed under adding {yn(closed)}, undos inside {yn(inverses)}")
zipped = [(a, b) for (a, ka), (b, kb) in zip(ORDERS, ADDRESSES)]
real = sum(1 for (a, ka), (b, kb) in zip(ORDERS, ADDRESSES) if ka == kb)
shared = [c for c in KEYS if any(k == c for _, k in ORDERS) and any(k == c for _, k in ADDRESSES)]
print(f"mistake, rows paired by position: {len(zipped)} rows, {real} a real match")
print(f"mistake, one row per shared key: {len(shared)} rows")
print(f"mistake, no key condition: {len(ORDERS) * len(ADDRESSES)} rows")
for name, m in (("true matches", MATCH), ("faulty matcher", FAULTY)):
    cls = glue(SHOP1, SHOP2, m)
    good, tot = maps_agreeing(SHOP1, SHOP2, m)
    print(f"{name}: {len(SHOP1)} + {len(SHOP2)} - {len(m)} = {len(SHOP1) + len(SHOP2) - len(m)}; "
          f"classes found {len(cls)}")
    print("  merged list: " + ", ".join("{" + ", ".join(c) + "}" for c in cls))
    print(f"  maps into two labels agreeing on the matches: {good} of {tot} = 2 to the {len(cls)}")
direct = lambda x, y: x == y or (x, y) in FAULTY or (y, x) in FAULTY
broken = direct("Ana", "ana.k") and direct("ana.k", "Ben") and not direct("Ana", "Ben")
print(f"faulty, direct matches only: Ana with ana.k {yn(direct('Ana', 'ana.k'))}, "
      f"ana.k with Ben {yn(direct('ana.k', 'Ben'))}, Ana with Ben {yn(direct('Ana', 'Ben'))}: "
      f"{'not transitive' if broken else 'no break in this chain'}")
assert len(join) == total == 8                                  # road 1 against road 2
assert len(matching) == len(join) ** 2 and set(through) == {1}  # universal property, brute force
assert len(one_point) == 24 and len(nested_loop_join(ORDERS, cards)) == 5
assert len(z4z6) == sum(sum(1 for x in range(4) if x % 2 == c) * sum(1 for y in range(6) if y % 2 == c)
                        for c in range(2)) and closed and inverses
c1, c2 = glue(SHOP1, SHOP2, MATCH), glue(SHOP1, SHOP2, FAULTY)
assert maps_agreeing(SHOP1, SHOP2, MATCH)[0] == 2 ** len(c1) and len(c1) == 4 + 5 - 2
assert maps_agreeing(SHOP1, SHOP2, FAULTY)[0] == 2 ** len(c2) and len(c2) == 6 != len(SHOP1) + len(SHOP2) - len(FAULTY)
assert (real, len(shared)) == (1, 2) and broken
print("ALL CHECKS PASS")
