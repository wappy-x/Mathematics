# Natural transformations and Yoneda -- the check behind the card.  Nothing is
# imported.  A finite set is {0, ..., n-1}; a function between finite sets is a
# tuple t, with t[i] the place member i goes.  Three roads: every naturality
# square checked by brute force; Yoneda's rebuild of a family from one value;
# a blind search over every candidate family, counted against Yoneda's count.

def fmap(f, xs):                       # the list functor on arrows: f slot by slot
    return [f(x) for x in xs]

def rev(xs):                           # reversal: moves slots, never reads a value
    return [xs[len(xs) - 1 - i] for i in range(len(xs))]

def pounds(p):                         # pence to price text: the arrow f
    return "£" + str(p // 100) + "." + str(p // 10 % 10) + str(p % 10)

def show(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"

def yn(claim):
    return "yes" if claim else "no"

def functions(m, n):                   # every function from an m-set to an n-set
    out = [()]
    for _ in range(m):
        out = [t + (y,) for t in out for y in range(n)]
    return out

def lists(m, k):                       # every list of length k over an m-set
    return [list(t) for t in functions(k, m)]

def squares(eta, sizes, lengths):      # (squares checked, squares that fail)
    checked = failed = 0
    for m in sizes:
        for n in sizes:
            for f in functions(m, n):
                for k in lengths:
                    for xs in lists(m, k):
                        checked += 1
                        down_then_across = fmap(lambda x: f[x], eta(m, xs))
                        across_then_down = eta(n, fmap(lambda x: f[x], xs))
                        failed += down_then_across != across_then_down
    return checked, failed

# 1. The square on one real list: shelf prices in pence, f = write as text.
prices = [250, 199, 1200]
route_a, route_b = fmap(pounds, rev(prices)), rev(fmap(pounds, prices))
print(f"prices in pence {show(prices)}, as text {show(fmap(pounds, prices))}")
print(f"reverse, then write as text: {show(route_a)}")
print(f"write as text, then reverse: {show(route_b)}")
print(f"the square commutes for reversal: {yn(route_a == route_b)}")
sort_a, sort_b = fmap(pounds, sorted(prices)), sorted(fmap(pounds, prices))
print(f"sort, then write as text: {show(sort_a)}")
print(f"write as text, then sort: {show(sort_b)}")
print(f"the square commutes for sorting: {yn(sort_a == sort_b)}")
neg, add1 = (lambda x: -x), (lambda x: x + 1)
print(f"refunds, f = negate: sort then negate {show(fmap(neg, sorted(prices)))}, "
      f"negate then sort {show(sorted(fmap(neg, prices)))}")
print(f"f = add 1p: sort then add {show(fmap(add1, sorted(prices)))}, "
      f"add then sort {show(sorted(fmap(add1, prices)))}: agree {yn(fmap(add1, sorted(prices)) == sorted(fmap(add1, prices)))}")
print(f"mistake, reverse numbers but leave text alone: {show(route_a)} against {show(fmap(pounds, prices))}")

# 2. Brute force: every function between sets of 1 to 3 members, every list up to length 4.
rev_checked, rev_failed = squares(lambda m, xs: rev(xs), (1, 2, 3), range(5))
sort_checked, sort_failed = squares(lambda m, xs: sorted(xs), (1, 2, 3), range(5))
print(f"reversal: {rev_checked} squares checked, {rev_failed} fail")
print(f"sorting: {sort_checked} squares checked, {sort_failed} fail")

# 3. Yoneda's rebuild: reversal on 3-lists is fixed by one value, its answer on [0, 1, 2].
generic = [0, 1, 2]
recipe = rev(generic)
all3 = [xs for m in (1, 2, 3) for xs in lists(m, 3)]
rebuilt = all(rev(xs) == fmap(lambda i: xs[i], recipe) for xs in all3)
print(f"reversal of the generic list {show(generic)} is {show(recipe)}")
print(f"rev(xs) = map (slot of xs) over {show(recipe)}, for all {len(all3)} lists of length 3: {yn(rebuilt)}")
print(f"example: [a, b, c] -> slots {show(recipe)} -> {show(fmap(lambda i: 'abc'[i], recipe))}")
recipes_ok = [p for p in functions(3, 3)
              if squares(lambda m, xs: [xs[p[0]], xs[p[1]], xs[p[2]]], (1, 2, 3), (3,))[1] == 0]
print(f"recipes p: 3 -> 3 tried as families on 3-lists: {len(recipes_ok)} of {3 ** 3} pass every square")

# 4. Blind search on pairs: any rule pairs -> pairs at sets of 1 and 2 members.
P = lists(2, 2)                        # the 4 pairs over {0, 1}
survivors = []
for c in functions(4, 4):              # 256 candidate rules at the 2-member set
    eta = lambda m, xs: xs if m == 1 else P[c[P.index(xs)]]
    if squares(eta, (1, 2), (2,))[1] == 0:
        survivors.append(P[c[1]])      # each survivor's answer on the generic pair [0, 1]
print(f"candidate rules on pairs: {len(functions(4, 4))}; natural: {len(survivors)}")
print(f"their answers on the generic pair [0, 1]: {show(survivors)}")
print(f"Yoneda's count, functions 2 -> 2: {len(functions(2, 2))}")

# 5. Groups alongside: the 6 rearrangements of 3 slots, composed.
G = [p for p in functions(3, 3) if len(set(p)) == 3]
idx = {p: i for i, p in enumerate(G)}
def comp(p, q): return tuple(p[q[i]] for i in range(3))
e = (0, 1, 2)
nat = [phi for phi in functions(6, 6)  # phi(h g) = phi(h) g for every h, g
       if all(G[phi[idx[comp(h, g)]]] == comp(G[phi[idx[h]]], g) for h in G for g in G)]
left = all(G[phi[i]] == comp(G[phi[idx[e]]], G[i]) for phi in nat for i in range(6))
print(f"group of {len(G)} rearrangements; reversal is {list(G[idx[(2, 1, 0)]])}")
print(f"maps G -> G respecting composing on the right: {len(nat)} of {6 ** 6}")
print(f"each is 'compose with phi(identity) on the left': {yn(left)}")
cayley = {tuple(idx[comp(a, h)] for h in G) for a in G}
print(f"Cayley: {len(G)} members give {len(cayley)} different rearrangements of the group")

assert route_a == route_b and sort_a != sort_b                    # one square each way
assert rev_failed == 0 and sort_failed > 0 and rev_checked == 4820  # brute force
assert rebuilt and recipe == [2, 1, 0] and len(recipes_ok) == 3 ** 3  # Yoneda's rebuild
assert survivors == lists(2, 2) and len(survivors) == len(functions(2, 2))   # blind count
assert len(nat) == len(G) and left and len(cayley) == len(G)       # Cayley, one object
print("ALL CHECKS PASS")
