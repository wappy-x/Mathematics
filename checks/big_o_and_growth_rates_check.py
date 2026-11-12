# Big-O and growth rates -- the check behind the card.  Standard library only;
# math supplies log2 and log10 for two ladder rows, nothing else.  A cost is a
# count of comparisons or steps, never a time.  Each count is reached twice:
# by a formula, and by running the method and letting it count its own work.
import math

def scan(tracks, target):                # read the titles in order until a match
    count = 0
    for t in tracks:
        count += 1
        if t == target:
            return True, count
    return False, count

def halving(tracks, target):             # binary search: only sound on sorted tracks
    lo, hi, count = 0, len(tracks) - 1, 0
    while lo <= hi:
        mid = (lo + hi) // 2
        count += 1                       # one three-way comparison per probe
        if tracks[mid] == target:
            return True, count
        if tracks[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return False, count

def halving_worst(n):                    # every track and every gap, as targets
    tracks = list(range(0, 2 * n, 2))    # sorted stand-ins for the titles
    return max(halving(tracks, x)[1] for x in range(-1, 2 * n))

def floor_log2_plus_1(n):                # the formula: halve n down to 0, count
    k = 0
    while n > 0:
        n //= 2
        k += 1
    return k

def pair_check(n):                       # compare every track with every later one
    count = 0
    for i in range(n):
        for j in range(i + 1, n):
            count += 1
    return count

def pairs(n):                            # the formula for the pair check
    return n * (n - 1) // 2

def playlists(n, minutes):               # try every subset of n tracks
    lengths = [3 + 7 * i % 5 for i in range(n)]
    tried = hits = 0
    for mask in range(2 ** n):
        tried += 1
        hits += sum(lengths[i] for i in range(n) if mask >> i & 1) == minutes
    ways = [1] + [0] * minutes           # second road: count by a running table
    for m in lengths:
        for t in range(minutes, m - 1, -1):
            ways[t] += ways[t - m]
    return tried, hits, ways[minutes]

N = 1000000
scan_n = scan(range(N), -1)[1]
half_n, half_2n = halving_worst(N), halving_worst(2 * N)
print(f"library of n = {N} tracks; cost = comparisons; worst case")
print(f"scan: formula n = {N}; counted, title absent = {scan_n}")
print(f"halving: formula floor(log2 n) + 1 = {floor_log2_plus_1(N)}; counted = {half_n}")
print(f"scan / halving = {scan_n // half_n}")
print(f"doubled to {2 * N}: scan {scan(range(2 * N), -1)[1]}, halving {half_2n} "
      f"(formula {floor_log2_plus_1(2 * N)})")
small = all(halving_worst(n) == floor_log2_plus_1(n) for n in range(1, 301))
print(f"halving counted = formula for every n from 1 to 300: {'yes' if small else 'no'}")
print("figure, n, scan, halving:", " | ".join(
    f"{n} {scan(range(n), -1)[1]} {halving_worst(n)}" for n in [1, 2, 4, 8, 16, 32, 64, 128]))
print("doubling test, counted at n = 1000 and n = 2000:")
print(f"  constant, read slot k: 1 -> 1")
print(f"  halving: {halving_worst(1000)} -> {halving_worst(2000)}")
print(f"  scan: {scan(range(1000), -1)[1]} -> {scan(range(2000), -1)[1]}")
print(f"  pair check: {pair_check(1000)} -> {pair_check(2000)}"
      f" (formula n(n-1)/2: {pairs(1000)} -> {pairs(2000)})")
for n in (10, 11, 12):
    tried, hits, table = playlists(n, 30)
    print(f"  every subset of {n} tracks: tried {tried} (2^n = {2 ** n}), "
          f"30-minute playlists {hits} (table {table})")
print(f"ladder at n = {N}:")
print(f"  constant 1; log2 n rounded up {floor_log2_plus_1(N - 1)}; n {N}")
print(f"  n log2 n {int(N * math.log2(N) + 0.5)}; n(n-1)/2 {pairs(N)}")
print(f"  2^n has {int(N * math.log10(2)) + 1} digits")
print("each rung divided by the one below, at n = 16 and n = 1024:")
for name, f in [("log2 n / 1", lambda n, L: f"{L}"), ("n / log2 n", lambda n, L: f"{n / L:.1f}"),
                ("n log2 n / n", lambda n, L: f"{L}"), ("n^2 / (n log2 n)", lambda n, L: f"{n / L:.1f}"),
                ("2^n / n^2", lambda n, L: f"2^{n - 2 * L}")]:
    print(f"  {name}: {f(16, 4)}, {f(1024, 10)}")
sq = max((n + 1) ** 2 / n ** 2 for n in range(4, 1001))      # what one more track does to n^2
step = min(2 * n * n / (n + 1) ** 2 for n in range(4, 1001)) # ... and so to 2^n / n^2
print(f"  2^n / n^2 from n = 4: n^2 grows by at most {sq} per track, so the ratio by at least {step}")
print("Theta(n) for a scan with bookkeeping, 2n + 3 steps:")
upper = all(2 * n + 3 <= 3 * n for n in range(3, 100001))
print(f"  2n + 3 <= 3n for n = 3 to 100000: {'yes' if upper else 'no'}; at n = 2: {2 * 2 + 3} > {3 * 2}")
first = next(n for n in range(1, 10 ** 6) if pairs(n) > 1000 * n)
print(f"n(n-1)/2 <= 1000 n first fails at n = {first} (formula 2c + 2 = {2 * 1000 + 2})")
print("crossover, pair check n(n-1)/2 against 50 n steps:")
tie = next(n for n in range(2, 10 ** 6) if pairs(n) >= 50 * n)
print(f"  equal at n = {tie} (formula 2 x 50 + 1 = {2 * 50 + 1}); counted at n = {tie}: "
      f"{pair_check(tie)} against {50 * tie}")
print(f"  at n = 20: {pair_check(20)} against {50 * 20}; at n = {N}: "
      f"{pairs(N)} against {50 * N}")
print("figure, n, pairs, 50n:", " | ".join(
    f"{n} {pairs(n)} {50 * n}" for n in range(0, 201, 20)))
log = [7, 3, 9, 1, 5, 8, 2]              # the play log, in listening order: unsorted
print(f"mistake, halving the unsorted play log {log} for track 3: found "
      f"{'yes' if halving(log, 3)[0] else 'no'} after {halving(log, 3)[1]}; scan finds it at {scan(log, 3)[1]}")
print(f"mistake, best case quoted: scan finds the first track in {scan(range(N), 0)[1]}, worst {scan_n}")
print(f"mistake, c growing with n: n(n-1)/2 over n is {(N - 1) / 2} at {N}, {(2 * N - 1) / 2} at {2 * N}")
print(f"mistake, log10 for halvings: log10 n = {len(str(N)) - 1}, halvings {half_n}")
assert scan_n == N and half_n == floor_log2_plus_1(N) == 20 and half_2n == 21  # run = formula
assert small and pair_check(2000) == 2000 * 1999 // 2                          # run = formula
assert all(playlists(n, 30)[0] == 2 ** n and playlists(n, 30)[1] == playlists(n, 30)[2]
           for n in (10, 11, 12))                                              # two roads
assert upper and first == 2 * 1000 + 2 and tie == 2 * 50 + 1                 # search = algebra
assert sq == (5 / 4) ** 2 and step == 2 / sq                                  # search = algebra
assert all(2 ** (4 + k) * 25 ** k >= 32 ** k * (4 + k) ** 2 for k in range(21))  # ratio >= 1.28^k
assert halving(log, 3) == (False, 3) and scan(log, 3) == (True, 2)
print("ALL CHECKS PASS")
