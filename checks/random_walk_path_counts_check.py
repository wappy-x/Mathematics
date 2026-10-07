# Counting coin-flip paths -- the check behind the card.  Nothing is imported.
# Ten fair flips scored +1 for heads and -1 for tails; the path is the running
# total.  Every count is reached twice: once by walking all 2^n sequences step
# by step, once from a closed form built out of a product written out here.
N, M = 10, 4                              # ten flips, and a four-flip warm-up

def choose(n, k):                         # C(n, k), built here, nothing imported
    top, bot = 1, 1
    for i in range(k):
        top, bot = top * (n - i), bot * (i + 1)
    return top // bot if 0 <= k <= n else 0

def catalan(m):                           # the m-th Catalan number
    return choose(2 * m, m) // (m + 1)

def walk(n):                              # road one: every +1/-1 sequence, one at a time
    ends = [0] * (2 * n + 1)              # ends[h + n] counts paths finishing at height h
    dyck = high = 0                       # never below zero; strictly above zero between
    for code in range(2 ** n):
        s, low, inner = 0, 0, n           # height, lowest height, lowest before the end
        for k in range(1, n + 1):
            s += 1 if (code >> (k - 1)) & 1 else -1
            low = min(low, s)
            inner = min(inner, s) if k < n else inner
        ends[s + n] += 1
        dyck += 1 if s == 0 and low >= 0 else 0
        high += 1 if s == 0 and inner > 0 else 0
    return ends, dyck, high

def formula(n):                           # road two: the closed forms, nothing listed
    ends = [choose(n, (n + h) // 2) if (n + h) % 2 == 0 else 0 for h in range(-n, n + 1)]
    return ends, catalan(n // 2), catalan(n // 2 - 1)

def row(name, values):
    print(f"{name:<24}" + "".join(f"{v:>5}" for v in values))

seen, dyck, high = walk(N)
calc, dyck_c, high_c = formula(N)
small, small_dyck, small_high = walk(M)
evens = list(range(-N, N + 1, 2))
print(f"{N} flips scored +1/-1: 2^{N} = {2 ** N} sequences, {sum(seen)} paths listed")
row("ending height", evens)
row("paths, by listing", [seen[h + N] for h in evens])
row("paths, by C(n, (n+h)/2)", [calc[h + N] for h in evens])
print(f"end level, height 0: listed {seen[N]}, C({N}, {N // 2}) = {calc[N]}")
print(f"end at +2:           listed {seen[N + 2]}, C({N}, {(N + 2) // 2}) = {calc[N + 2]}")
print(f"never below zero:    listed {dyck}, C({N}, {N // 2})/{N // 2 + 1} = {dyck_c}")
print(f"strictly above zero: listed {high}, C({N - 2}, {N // 2 - 1})/{N // 2} = {high_c}")
print(f"{M} flips: {2 ** M} sequences, {small[M]} end level, {small_dyck} never below zero, "
      f"{small_high} strictly above")
print(f"mistake 1, ending at +1 in {N} flips: {N} + 1 is odd, so {calc[N + 1]} paths")
print(f"mistake 2, C({N}, 2) from the height, not the head count: {choose(N, 2)}, not {calc[N + 2]}")
print(f"mistake 3, {calc[N]} shared among {N // 2} instead of {N // 2 + 1}: "
      f"{calc[N] / (N // 2):.1f}, not a whole number")
print(f"mistake 4, the never-below count used for the strictly-above one: {dyck}, not {high}")
assert seen == calc                                      # two roads, one distribution
assert sum(calc) == 2 ** N and seen[N] == 252            # the whole row sums to 2^n
assert (dyck, high) == (42, 14) == (dyck_c, high_c)      # listing against closed form
assert small == [1, 0, 4, 0, 6, 0, 4, 0, 1] and (small_dyck, small_high) == (2, 1)
print("ALL CHECKS PASS")
