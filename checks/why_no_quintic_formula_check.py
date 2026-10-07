# Why there is no quintic formula -- the check behind the card.  Nothing is imported.  The
# group half peels the shuffles of 3, 4 and 5 roots by commutators; a shuffle of n places is
# a tuple of destinations, right-hand factor first.  The number half finds the root of
# x^5 - x - 1 and the radical root of x^5 - 2 by halving a bracket and again by Newton's step.
def shuffles(n):                               # every rearrangement of n places
    out = [()]
    for _ in range(n): out = [s + (d,) for s in out for d in range(1, n + 1) if d not in s]
    return out
def comp(a, b): return tuple(a[j - 1] for j in b)       # do b first, then a
def inv(a): return tuple(a.index(i) + 1 for i in range(1, len(a) + 1))
def odd(a): return sum(1 for i in range(len(a))         # pairs out of order
                       for j in range(i + 1, len(a)) if a[i] > a[j]) % 2
def bracket(a, b): return comp(comp(a, b), comp(inv(a), inv(b)))
def close(gens, ident):                        # smallest group holding the gens
    G = set(gens) | {ident}
    while G != (bigger := G | {comp(a, b) for a in G for b in G}): G = bigger
    return sorted(G)
def peel(G, ident): return close([bracket(a, b) for a in G for b in G], ident)
def ladder(n, steps=4):                     # group sizes down the peeling chain
    ident, G, sizes = tuple(range(1, n + 1)), shuffles(n), []
    for _ in range(steps): sizes.append(len(G)); G = peel(G, ident)
    return sizes
def chain(sizes): return " -> ".join(str(v) for v in sizes)
E5, S5 = tuple(range(1, 6)), shuffles(5)       # road two is the even shuffles,
A5, first = [s for s in S5 if not odd(s)], peel(S5, E5)    # road one the commutators
threes = [s for s in A5 if sum(1 for i, d in enumerate(s, 1) if d != i) == 3]
commutators = {bracket(a, b) for a in A5 for b in A5}
built, s3, s4, s5 = close(threes, E5), ladder(3), ladder(4), ladder(5)
lo_pair = next((a, b) for a in A5 for b in A5 if bracket(a, b) == (2, 3, 1, 4, 5))
print(f"shuffles of 3, 4 and 5 roots: {len(shuffles(3))}, {len(shuffles(4))} and {len(S5)}")
print(f"peeled by commutators, 3 roots: {chain(s3)}; 4 roots: {chain(s4)} -- both reach 1")
print(f"peeled by commutators, 5 roots: {chain(s5)} -- stuck at {s5[-1]}")
print(f"the first peel of the 120 is exactly the {len(A5)} even shuffles: {first == A5}")
print(f"all {len(threes)} three-place cycles are commutators of even shuffles: "
      f"{all(t in commutators for t in threes)}; they build all {len(built)}")
print(f"smallest such pair: [2, 3, 1, 4, 5] from {list(lo_pair[0])} and {list(lo_pair[1])}")
def five(x): return x * x * x * x * x
hard, easy = lambda x: five(x) - x - 1, lambda x: five(x) - 2
def halve(h, lo, hi, steps=50):                # both curves rise across 1 to 2
    for _ in range(steps):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if h(mid) < 0 else (lo, mid)
    return (lo + hi) / 2
def newton(h, slope, x, steps=8):
    for _ in range(steps): x = x - h(x) / slope(x)
    return x
eb, hb = halve(easy, 1.0, 2.0), halve(hard, 1.0, 2.0)
en = newton(easy, lambda x: 5 * x * x * x * x, 1.2)
hn = newton(hard, lambda x: 5 * x * x * x * x - 1, 1.2)
print(f"x^5 - 2 at x = 1 and x = 2: {easy(1.0):.2f} and {easy(2.0):.2f}; "
      f"x^5 - x - 1 there: {hard(1.0):.2f} and {hard(2.0):.2f}")
print(f"x^5 - 2, the radical case: 50 halvings give {eb:.10f}, 8 Newton steps {en:.10f}")
print(f"that root's fifth power, by five multiplications: {five(eb):.10f}")
print(f"x^5 - x - 1: 50 halvings give {hb:.10f}, 8 Newton steps from 1.2 {hn:.10f}")
print(f"the four mistakes come out at a residual of {hard(eb):.10f}, a radical answer of "
      f"{eb:.10f}, a peel stuck at {s5[-1]} instead of 1, and a root of {hb:.10f} all the same")
assert first == A5 and len(A5) == 60 and s5 == [120, 60, 60, 60]
assert all(t in commutators for t in threes) and built == A5 and len(threes) == 20
assert s3 == [6, 3, 1, 1] and s4 == [24, 12, 4, 1]
assert abs(hb - hn) < 1e-12 and abs(five(hb) - hb - 1) < 1e-12 and abs(five(eb) - 2) < 1e-12
print("ALL CHECKS PASS")
