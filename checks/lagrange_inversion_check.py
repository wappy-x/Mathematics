# Lagrange inversion -- the check behind the card.  Nothing is imported.  T = x phi(T) fixes a series T,
# and Lagrange reads its coefficients as (1/n) [t^(n-1)] phi(t)^n.  Three tree families, n = 1 to 6, three
# roads each: Lagrange, iterating the equation, and building every tree as a child-count code or parent map.
N = 6
def choose(n, k): return 1 if k == 0 else choose(n, k - 1) * (n - k + 1) // k   # C(n, k), "n choose k"
def mul(a, b, lab=False, cut=N):         # series product cut above x^cut; lab: labelled (EGF) counts
    out = [0] * (cut + 1)
    for i in range(cut + 1):
        for j in range(cut + 1 - i): out[i + j] += a[i] * b[j] * (choose(i + j, i) if lab else 1)
    return out
def power(phi, n, lab=False):            # phi(t)^n
    out = [1] + [0] * N
    for _ in range(n): out = mul(out, phi, lab)
    return out
def digits(m, base, n): return [m // base ** i % base for i in range(n)]
def slots(cs): return [1 + sum(c - 1 for c in cs[:k + 1]) for k in range(len(cs))]   # open slots after each node
def is_code(cs): run = slots(cs); return run[-1] == 0 and min(run[:-1], default=1) > 0   # closes one tree, at the end only
def listed(d, left, need=1):             # build every tree code node by node, weighted by the slots it fills
    if need == 0 or left == 0: return int(need == left == 0)
    return sum(choose(d, c) * listed(d, left - 1, need + c - 1) for c in range(d + 1))
def iterate(d):                          # rounds of T <- x (1 + T)^d
    t = [0] * (N + 1)
    for _ in range(N): t = [0] + power([1] + t[1:], d)[:N]
    return t[1:]
def climb(f, v, k): return v if k == 0 else climb(f, f[v], k - 1)
def parent_maps(n):                      # every map v -> parent(v); a rooted tree's upward walks share one end
    trees, roads = 0, set()
    for m in range(n ** n):
        if len({climb(f := digits(m, n, n), v, n) for v in range(n)}) == 1:
            trees, roads = trees + 1, roads | {frozenset(frozenset((v, f[v])) for v in range(n) if f[v] != v)}
    return trees, len(roads)
def row(label, vals): print(f"{label:<44}" + "".join(f"{v:>7}" for v in vals))
ones = [1] * (N + 1)                     # e^t as labelled counts: one way to make a set of any size
lag = {d: [power(power([1, 1] + [0] * (N - 1), d), n)[n - 1] // n for n in range(1, N + 1)] for d in (2, 3)}
lab = [power(ones, n, True)[n - 1] for n in range(1, N + 1)]   # n! (1/n) [t^(n-1)] e^(nt), kept whole
sets, rec = [1] + [0] * N, [0] * (N + 1)                       # road two for x e^T: grow e^T and T together
for n in range(1, N + 1):
    rec[n] = n * sets[n - 1]
    sets[n] = sum(choose(n - 1, k) * rec[k + 1] * sets[n - 1 - k] for k in range(n))
maps = [parent_maps(n) for n in range(1, N + 1)]
for d, name in ((2, "binary, T = x(1+T)^2"), (3, "ternary, T = x(1+T)^3")):
    row(name + ", by Lagrange", lag[d]); row("  by iterating the equation", iterate(d)); row("  by listing tree codes", [listed(d, n) for n in range(1, N + 1)])
row("rooted labelled, T = x e^T, n! [x^n] T", lab); row("  by the exponential formula", rec[1:]); row("  by listing parent maps", [t for t, _ in maps])
b8, t12, e4, turns = choose(8, 3), choose(12, 3), power(ones, 4, True)[3], [[2, 1, 0, 0][k:] + [2, 1, 0, 0][:k] for k in range(4)]
rotations = [sum(is_code(cs[k:] + cs[:k]) for k in range(4)) for m in range(81) if sum(cs := digits(m, 3, 4)) == 3]
dice = mul(die := [0] + [1] * 6 + [0] * 6, die, cut=12)        # the shelf's two dice, by the series product up to x^12
print(f"n = 4: (1+t)^8 has 8 x 7 x 6 / (3 x 2 x 1) = {b8} at t^3, {b8} / 4 = {b8 // 4}; (1+t)^12 has {t12} at t^3, {t12} / 4 = {t12 // 4}")
print(f"n = 4: e^(4t) has {e4}/6 at t^3, and 4! x (1/4) x {e4}/6 = {24 * e4 // 4 // 6}")
print(f"lists of 4 child counts from 0 to 2 summing to 3: {len(rotations)}; each has one tree rotation: {'yes' if set(rotations) == {1} else 'no'}")
print(f"turns of 2, 1, 0, 0: {turns}; open slots of the first {slots(turns[0])}; trees {[int(is_code(t)) for t in turns]}")
print(f"4 villages: {maps[3][0]} rooted trees, {maps[3][1]} distinct road sets; Cayley 4^2 = {4 ** 2}")
print(f"the shelf's two dice: {dice[7]} ways at x^7, {sum(dice)} in all")
print(f"mistake 1, no 1/n: {b8}; mistake 2, t^4 not t^3: {choose(8, 4)} / 4 = {choose(8, 4) / 4:.1f}")
print(f"mistake 3, no n! for labelled trees: {e4} / 24 = {e4 / 24:.3f}")
print(f"mistake 4, rooted trees read as road plans: {maps[3][0]}, not {maps[3][1]}")
assert lag[2] == iterate(2) == [listed(2, n) for n in range(1, N + 1)] and lag[2][3] == 14   # three roads, binary
assert lag[3] == iterate(3) == [listed(3, n) for n in range(1, N + 1)] and lag[3][3] == 55   # three roads, ternary
assert lab == rec[1:] == [t for t, _ in maps] == [n ** (n - 1) for n in range(1, N + 1)]    # three roads, labelled
assert set(rotations) == {1} and maps[3][1] == 4 ** 2 and dice == [sum(a + b == s for a in range(1, 7) for b in range(1, 7)) for s in range(13)]   # cycle lemma, Cayley, dice by listing
print("ALL CHECKS PASS")
