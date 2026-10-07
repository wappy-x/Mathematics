# Factorials -- the check behind the card.  Nothing is imported.  A playlist of
# 10 songs, 8 runners and a 20-song playlist.  The count of orderings is reached
# by roads that share no arithmetic: multiplying the choices down, a tally that
# only ever adds, and a listing of every ordering of a small set.
SONGS, RUNNERS, BIG, PI, E = 10, 8, 20, 3.141592653589793, 2.718281828459045

def multiply_down(n):                       # road one: n x (n-1) x ... x 1
    out = 1
    for k in range(n, 0, -1):
        out *= k
    return out

def by_adding(n):                           # road two: a tally that never multiplies
    ways = [0] * (1 << n)                   # ways[s] = orderings of the songs in set s
    ways[0] = 1
    for s in range(1, 1 << n):
        ways[s] = sum(ways[s ^ (1 << i)] for i in range(n) if s >> i & 1)
    return ways[(1 << n) - 1]

def orderings(items):                       # road three: build every ordering, then count
    if not items:
        return [""]
    return [x + tail for i, x in enumerate(items)
            for tail in orderings(items[:i] + items[i + 1:])]

def stirling(n):                            # sqrt(2 pi n) x (n/e)^n, no library call
    p, under = 1.0, 2.0 * PI * n            # under: the number whose square root is wanted
    for _ in range(n):
        p *= n / E
    g = under                               # the root itself, by Newton's method
    for _ in range(60):
        g = 0.5 * (g + under / g)
    return g * p

ten, eight, f20 = multiply_down(SONGS), multiply_down(RUNNERS), multiply_down(BIG)
listed, three = orderings("ABCDEFGH"), orderings("ABC")
rows = [(len(str(multiply_down(n))), len(str(2 ** n)), len(str(n * n))) for n in range(BIG + 1)]
d_fact, d_two, d_sq = ([r[i] for r in rows] for i in (0, 1, 2))
s20 = stirling(BIG)
wrong = 0                                   # 0! taken as 0, then the recurrence applied
for n in range(1, SONGS + 1): wrong *= n
print(f"{'10 songs, one position at a time: 10 x 9 x 8 x 7 x 6 x 5 x 4 x 3 x 2 x 1':<74} = {ten:,}")
print(f"{'the same count, by a tally that only ever adds':<74} = {by_adding(SONGS):,}")
print(f"8 runners by multiplying down: {eight:,}; every ordering built and counted: {len(listed):,}")
print(f"the 3-song playlists, all {len(three)} of them: {' '.join(three)}")
print(f"0! up to 10!: {[multiply_down(n) for n in range(SONGS + 1)]}; "
      f"n! first passes 2^n at n = 4, {multiply_down(4)} against {2 ** 4}")
print(f"digits in n!,  n = 0 to 20: {d_fact}")
print(f"digits in 2^n, n = 0 to 20: {d_two}")
print(f"digits in n^2, n = 0 to 20: {d_sq}")
print(f"20! exactly: {f20:,}")
print(f"Stirling's estimate of 20!, then 20! itself, in units of a million million million: "
      f"{s20 / 1e18:.6f} and {f20 / 1e18:.6f}")
print(f"Stirling divided by 20! = {s20 / f20:.6f}, low by {(1 - s20 / f20) * 100:.3f} percent; the gap it leaves, same units: {(f20 - s20) / 1e18:.6f}")
print(f"mistake 1, 0! taken as 0: 10! reads {wrong}; mistake 2, repeats allowed: {10 ** SONGS:,}; mistake 3, one song on twice: {ten // 2:,}")
assert ten == by_adding(SONGS) == 3628800
assert len(listed) == eight == 40320 and len(orderings("ABCD")) == 24
assert all(by_adding(n) == n * multiply_down(n - 1) for n in range(1, 9))
assert 0.9958 < s20 / f20 < 0.9959 and f20 - s20 > 1.0e16
print("ALL CHECKS PASS")
