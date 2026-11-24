# Knaster-Tarski -- the check behind the card.  Nothing is imported.  The 16 subsets of {1, 2, 3, 4}
# ordered by "inside", and f(S) = {1} plus every step of S along the arrows 1 -> 2, 3 -> 4, 4 -> 3.
ARROWS, U = {1: {2}, 3: {4}, 4: {3}}, frozenset({1, 2, 3, 4})
ALL = [frozenset(x for x in U if n >> (x - 1) & 1) for n in range(16)]      # all 16 subsets
def f(S): return frozenset({1}).union(*(ARROWS.get(x, set()) for x in S))
def show(S): return "{" + ", ".join(map(str, sorted(S))) + "}"
def run(S, n): return [S] if n == 0 else [S] + run(f(S), n - 1)           # S, f(S), f(f(S)), ...
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
up, down, odd = run(frozenset(), 3), run(U, 1), run(frozenset({3}), 4)
reach, todo = {1}, [1]                                    # second road: walk the arrows from 1
while todo: todo += [y for y in ARROWS.get(todo.pop(), ()) if y not in reach]; reach |= set(todo)
fixed, closed = [S for S in ALL if f(S) == S], [S for S in ALL if f(S) <= S]
post, pairs = [S for S in ALL if S <= f(S)], [(S, T) for S in ALL for T in ALL if S <= T]
meet, join = U.intersection(*closed), frozenset().union(*post)      # third road: Tarski's formula
fr = [(0, 1)]                                             # the fractions: x -> (2x + 2) / (x + 2)
for _ in range(6): p, q = fr[-1]; p, q = 2 * p + 2 * q, p + 2 * q; fr.append((p // gcd(p, q), q // gcd(p, q)))
print("climb from the empty set:", ", ".join(map(show, up)))
print("climb down from the top:", ", ".join(map(show, down)), "| walk from 1 reaches", show(reach))
print(f"order kept on {sum(f(S) <= f(T) for S, T in pairs)} of {len(pairs)} pairs S inside T")
print(f"fixed points among {len(ALL)} subsets: {', '.join(map(show, fixed))}")
print(f"closed sets (f(S) inside S): {len(closed)}, all of them in common {show(meet)}")
print(f"sets inside their own f(S): {len(post)}, all of them together {show(join)}")
print("climb from {3}:", ", ".join(map(show, odd)), "| complement map, fixed points:", sum(U - S == S for S in ALL))
print("fractions climb:", ", ".join(f"{p}/{q}" for p, q in fr[:6]), f"= {fr[5][0] / fr[5][1]:.5f}, never fixed")
assert up[-1] == up[-2] == frozenset(reach) == meet == fixed[0] and len(fixed) == 2 and down[-1] == join == U == fixed[1]
assert len(pairs) == 81 and len(closed) == 2 and len(post) == 6 and frozenset().union(*closed) == U and all(f(S) <= f(T) for S, T in pairs) and not any(U - S == S for S in ALL)
assert odd[2] == odd[4] != odd[3] and all(fr[i] != fr[i + 1] for i in range(6)) and fr[5] == (41, 29)
print("ALL CHECKS PASS")
