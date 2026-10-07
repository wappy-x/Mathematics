# Integer partitions -- the check behind the card.  Nothing is imported.  A bar
# of 8 beats is split into notes a whole number of beats long, order ignored.
# p(n) is reached twice, by listing every split and by a build-up that lists
# none, and the flip of the dot diagram is then run on the splits themselves.
N, K = 8, 3
def splits(n, biggest):                  # road one: list the splits, biggest note first
    if n == 0:
        return [()]
    return [(a,) + r for a in range(min(biggest, n), 0, -1) for r in splits(n - a, a)]
def built_up(n):                         # road two: add one note length at a time
    p = [1] + [0] * n
    for a in range(1, n + 1):
        for i in range(a, n + 1):
            p[i] += p[i - a]
    return p
def few(n, k):                           # road three: R(n,k) = R(n-k,k) + R(n,k-1)
    if n == 0:
        return 1
    return 0 if n < 0 or k == 0 else few(n - k, k) + few(n, k - 1)
def flip(s):                             # the dot diagram turned over: rows become columns
    return tuple(sum(1 for a in s if a >= j) for j in range(1, s[0] + 1))
def rhythms(n):                          # order kept: every ordered writing of n
    return [()] if n == 0 else [(a,) + r for a in range(1, n + 1) for r in rhythms(n - a)]
def row(name, values):
    print(f"{name:<31}" + "".join(f"{v:>4}" for v in values))
cum = lambda xs: [sum(xs[:i + 1]) for i in range(len(xs))]
show = lambda s: "+".join(str(a) for a in s)
all8 = splits(N, N)
listed = [len(splits(n, n)) for n in range(N + 1)]
exact = [sum(1 for s in all8 if len(s) == k) for k in range(1, N + 1)]
longest = [sum(1 for s in all8 if s[0] == k) for k in range(1, N + 1)]
few_notes, short_notes = [s for s in all8 if len(s) <= K], [s for s in all8 if s[0] <= K]
ordered = rhythms(N)
collapsed = {tuple(sorted(r, reverse=True)) for r in ordered}
pairs = [f"{show(s)}/{show(flip(s))}" for s in few_notes]
print(f"a bar of {N} beats, notes a whole number of beats long, order ignored")
row("beats n", list(range(N + 1)))
row("splits p(n), by listing", listed)
row("splits p(n), by the build-up", built_up(N))
row("notes k, or longest note k", list(range(1, N + 1)))
row("splits with exactly k notes", exact)
row("splits whose longest note is k", longest)
row("splits with at most k notes", cum(exact))
row("splits with no note over k", cum(longest))
print(f"at most {K} notes: {cum(exact)[K - 1]}; no note over {K} beats: {cum(longest)[K - 1]}; "
      f"without listing, R(n=8, k=3) = R(n=5, k=3) + R(n=8, k=2) = {few(5, 3)} + {few(8, 2)} = {few(8, 3)}")
print(f"the flip carries the first collection onto the second, one for one: "
      f"{'yes' if sorted(flip(s) for s in few_notes) == sorted(short_notes) else 'no'}; "
      f"flipping twice returns every split: {'yes' if all(flip(flip(s)) == s for s in all8) else 'no'}")
print(f"the {len(few_notes)} splits with at most {K} notes, each with its flip:")
print("  " + "  ".join(pairs[:5]))
print("  " + "  ".join(pairs[5:]))
print(f"mistake 1, rhythms counted in order: {len(ordered)}, not {listed[N]}")
print(f"mistake 2, stars and bars for three named notes: {sum(1 for r in ordered if len(r) == 3)}, not {exact[2]}")
print(f"mistake 3, at most {K} notes read as exactly {K}: {exact[K - 1]}, not {cum(exact)[K - 1]}")
assert listed == built_up(N) == [1, 1, 2, 3, 5, 7, 11, 15, 22]
assert sorted(flip(s) for s in few_notes) == sorted(short_notes)
assert [few(N, k) for k in range(1, N + 1)] == cum(exact) == cum(longest)
assert collapsed == set(all8) and all(flip(flip(s)) == s for s in all8)
print("ALL CHECKS PASS")
