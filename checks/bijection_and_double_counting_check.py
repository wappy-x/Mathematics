# Bijections and double counting -- the check behind the card.  Nothing is
# imported.  Twenty teams play a single round robin.  The matches are counted
# twice over: by listing every one, and by arithmetic.  Then the ways to pick
# the playoff six are matched one to one with the ways to pick the fourteen
# who miss out, by swapping every mark in a twenty-mark string.
N, K, SMALL = 20, 6, [2, 3, 4, 5, 6]

def factorial(n):                        # written out here, nothing imported
    out = 1
    for i in range(2, n + 1):
        out *= i
    return out

def choose(n, k):                        # road two: n! / (k! x (n-k)!)
    return factorial(n) // (factorial(k) * factorial(n - k))

def matches(n):                          # road one: each match written once
    return [(a, b) for a in range(1, n + 1) for b in range(a + 1, n + 1)]

def slips(n):                            # one slip per team, per opponent
    return [(a, b) for a in range(1, n + 1) for b in range(1, n + 1) if a != b]

def marks(teams):                        # a set of teams as a twenty-mark string
    return "".join("1" if t in teams else "0" for t in range(1, N + 1))

listed, ordered = matches(N), slips(N)
tally = {}
for a, b in ordered:                     # file each slip under the match it names
    m = (min(a, b), max(a, b))
    tally[m] = tally.get(m, 0) + 1
counts = sorted(set(tally.values()))
by_listing = [len(matches(m)) for m in SMALL]
six = [s for s in range(1 << N) if bin(s).count("1") == K]
fourteen = [s for s in range(1 << N) if bin(s).count("1") == N - K]
flipped = sorted(s ^ ((1 << N) - 1) for s in six)          # swap every mark
buckets = len({(s & -s).bit_length() for s in six})
pick = [2, 5, 9, 11, 14, 20]
rest = [t for t in range(1, N + 1) if t not in pick]
print(f"league of {N} teams, each plays {N - 1} others")
print(f"road one, by listing: {len(ordered)} slips (team, opponent) and {len(listed)} matches")
print(f"road two, by arithmetic: {N} x {N - 1} / 2 = {N * (N - 1) // 2} matches, and C({N}, 2) = {choose(N, 2)}")
print(f"slips per match, smallest and largest: {counts[0]} and {counts[-1]}")
print(f"the five-team grid: {5 * 5} cells, {5} blanked, {5 * 4} filled, {5 * 4 // 2} matches")
print("teams          " + "".join(f"{m:>4}" for m in SMALL))
print("matches listed " + "".join(f"{v:>4}" for v in by_listing))
print("n(n-1)/2       " + "".join(f"{m * (m - 1) // 2:>4}" for m in SMALL))
print(f"strings of {N} marks: {1 << N} in all; picking {K} of {N} by listing them: {len(six)}, by formula C({N}, {K}) = {choose(N, K)}")
print(f"picking {N - K} of {N}: by listing marks {len(fourteen)}, by formula C({N}, {N - K}) = {choose(N, N - K)}")
print(f"swapping marks sends the {K}-team strings onto the {N - K}-team strings, none repeated: "
      f"{'yes' if flipped == fourteen else 'no'}")
print(f"one pick: {pick} -> {marks(pick)} -> swapped -> {marks(rest)} -> {rest}")
print(f"mistake 1, stopping at the slips: {len(ordered)} matches, not {len(listed)}")
print(f"mistake 2, letting a team play itself: {N * N} slips, {N * N // 2} matches")
print(f"mistake 3, filing the {len(six)} picks under their smallest team: {buckets} buckets")
assert len(listed) == N * (N - 1) // 2 == len(ordered) // 2
assert by_listing == [m * (m - 1) // 2 for m in SMALL]
assert len(six) == choose(N, K) and len(fourteen) == choose(N, N - K)
assert flipped == fourteen and counts == [2]
print("ALL CHECKS PASS")
