# Recurrences and the master theorem -- the check behind the card.  A phone
# library of 1,000,000 tracks (synthetic: 64-bit keys from SplitMix64, seed
# 2026) is sorted by merge sort, and each recurrence written from real code is
# totalled two ways: by the recurrence itself, and by a closed form, a level-by-
# level sum of the recursion tree, or a run that counts its own operations.
from math import log, log2                  # logs for printing and bounds only
N, SEED, M = 1_000_000, 2026, 0xFFFFFFFFFFFFFFFF
def splitmix(state):                        # SplitMix64, written out
    state = (state + 0x9E3779B97F4A7C15) & M
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return state, z ^ (z >> 31)
def merge_sort(xs, tally):                  # T(n) = T(floor n/2) + T(ceil n/2) + merge
    if len(xs) < 2: return xs
    h = len(xs) // 2
    a, b = merge_sort(xs[:h], tally), merge_sort(xs[h:], tally)
    out, i, j = [], 0, 0
    while i < len(a) and j < len(b):
        tally[0] += 1
        if a[i] <= b[j]: out.append(a[i]); i += 1
        else: out.append(b[j]); j += 1
    return out + a[i:] + b[j:]
def quicksort_first(xs):                    # pivot = first track; returns comparisons
    xs, count, stack = xs[:], 0, [(0, len(xs) - 1)]
    while stack:
        lo, hi = stack.pop()
        if lo >= hi: continue
        p, store = xs[lo], lo
        for i in range(lo + 1, hi + 1):
            count += 1
            if xs[i] < p: store += 1; xs[i], xs[store] = xs[store], xs[i]
        xs[lo], xs[store] = xs[store], xs[lo]
        stack += [(lo, store - 1), (store + 1, hi)]
    return count
def karatsuba(x, y, n, tally):              # x, y below 10^n; 3 half-size products
    if n == 1: tally[0] += 1; return x * y
    m = n // 2; p = 10 ** m
    x1, x0, y1, y0 = x // p, x % p, y // p, y % p
    z2, z0 = karatsuba(x1, y1, m, tally), karatsuba(x0, y0, m, tally)
    sign = (1 if x1 >= x0 else -1) * (1 if y0 >= y1 else -1)
    z1 = sign * karatsuba(abs(x1 - x0), abs(y0 - y1), m, tally) + z2 + z0
    return z2 * p * p + z1 * p + z0
def case(a, b, d):                          # the master theorem: d against log_b a
    w = log(a) / log(b)
    if abs(d - w) < 1e-12: return f"case 2, flat levels: n^{w:.3f} log n"
    return f"case 1, bottom heavy: n^{w:.3f}" if d < w else f"case 3, top heavy: n^{d:.3f}"
state, keys = SEED, []
for _ in range(N):
    state, k = splitmix(state)
    keys.append(k)
tally = [0]
library = merge_sort(keys, tally)
lucky = [0]; merge_sort(library, lucky)     # the same library handed over already sorted
W = [0] * (N + 1)                           # worst-case merge sort, by the recurrence
Q = [0] * (N + 1)                           # quicksort with the pivot at 10% rank
for n in range(2, N + 1):
    W[n] = W[n // 2] + W[n - n // 2] + n - 1
    Q[n] = Q[n // 10] + Q[n - 1 - n // 10] + n - 1
def closed_w(n):                            # n ceil(log2 n) - 2^ceil(log2 n) + 1
    k = (n - 1).bit_length()
    return n * k - 2 ** k + 1
def level_costs(n, split):                  # the recursion tree, one depth at a time
    level, rows = {n: 1}, []
    while level:
        rows.append(sum((s - 1) * c for s, c in level.items()))
        nxt = {}
        for s, c in level.items():
            for child in split(s):
                if child >= 2: nxt[child] = nxt.get(child, 0) + c
        level = nxt
    return rows
merge_rows = level_costs(N, lambda s: (s // 2, s - s // 2))
quick_rows = level_costs(N, lambda s: (s // 10, s - 1 - s // 10))
floor_bits = sum(log2(i) for i in range(2, N + 1))
H = -(0.1 * log(0.1) + 0.9 * log(0.9))      # the split's entropy, in nats
sorted_cmp = quicksort_first(library[:1000])
shuffled_cmp = quicksort_first(keys[:1000])
k_counts = []
for n, (x, y) in [(4, (3141, 2718)), (8, (31415926, 27182818)), (16, (3141592653589793, 2718281828459045))]:
    t = [0]; prod = karatsuba(x, y, n, t); k_counts.append(t[0])
K, NL = 20, 2 ** 20                         # the n log n join, on 2^20 tracks
join_rows = [2 ** j * (NL >> j) * (K - j) for j in range(K)]
print(f"library: {N} tracks, synthetic, SplitMix64 seed {SEED}; sorted: {'yes' if all(library[i] <= library[i + 1] for i in range(N - 1)) else 'no'}")
print(f"merge sort, comparisons counted on this library: {tally[0]}")
print(f"merge sort, the library handed over sorted:      {lucky[0]}")
print(f"merge sort, worst case by the recurrence:        {W[N]}")
print(f"merge sort, worst case by the closed form:       {closed_w(N)}")
print(f"merge sort, worst case by summing tree levels:   {sum(merge_rows)} over {len(merge_rows)} levels")
print(f"level 0 costs {merge_rows[0]}, level 19 costs {merge_rows[19]}; 2^20 - 1 = {2 ** 20 - 1}; 20 x n - (2^20 - 1) = {20 * N - (2 ** 20 - 1)}")
print(f"tree bound, 20 levels x {N}:                {20 * N}")
print(f"floor for any comparison sort, log2(n!):         {floor_bits:.0f}")
print(f"comparing every pair of tracks, n(n-1)/2:        {N * (N - 1) // 2}")
for n in (10_000, 100_000, 1_000_000):
    print(f"n = {n:>7}: merge worst / (n log2 n) = {W[n] / (n * log2(n)):.3f}, 10% pivot / (n log2 n) = {Q[n] / (n * log2(n)):.3f}")
print(f"quicksort, pivot at 10% rank, by the recurrence: {Q[N]}")
print(f"quicksort, pivot at 10% rank, by tree levels:    {sum(quick_rows)} over {len(quick_rows)} levels")
print(f"uneven-split estimate n ln n / H, H = {H:.4f}:    {N * log(N) / H:.0f}; ratio's limit ln 2 / H = {log(2) / H:.3f}")
print(f"first-element pivot, 1000 tracks already sorted: {sorted_cmp}  (n(n-1)/2 = {1000 * 999 // 2})")
print(f"first-element pivot, 1000 tracks in random order: {shuffled_cmp}")
print(f"the sorted case at 1,000,000 tracks: {N * (N - 1) // 2}")
print(f"karatsuba one-digit multiplies at 4, 8, 16 digits: {k_counts}; product right: {'yes' if prod == x * y else 'no'}")
print(f"karatsuba {x} x {y} = {prod}")
print(f"karatsuba at 1024 digits: 3^10 = {3 ** 10}; schoolbook 1024^2 = {1024 ** 2}; read as n log2 n: {1024 * 10}")
print(f"strassen at 1024 x 1024: 7^10 = {7 ** 10}; schoolbook 8^10 = {8 ** 10}")
for name, a, b, d in [("merge sort  2T(n/2)+n  ", 2, 2, 1), ("binary search T(n/2)+1 ", 1, 2, 0),
                      ("karatsuba   3T(n/2)+n  ", 3, 2, 1), ("strassen    7T(n/2)+n^2", 7, 2, 2)]:
    print(f"{name}  {case(a, b, d)}")
print(f"n log n join, 2^20 tracks, by levels: {sum(join_rows)}; closed form n k(k+1)/2: {NL * K * (K + 1) // 2}; read as n log2 n: {NL * K}")
depths = list(range(0, len(quick_rows), 5))
print(f"figure, depths {depths}")
print(f"figure, merge sort {[merge_rows[d] if d < len(merge_rows) else 0 for d in depths]}")
print(f"figure, 10% pivot  {quick_rows[::5]}")
assert all(library[i] <= library[i + 1] for i in range(N - 1)) and len(library) == N
assert W[N] == closed_w(N) == sum(merge_rows) == 18951425        # three roads to one number
assert lucky[0] < floor_bits < tally[0] <= W[N] < 20 * N          # sorted order beats the floor; this shuffle did not
assert Q[N] == sum(quick_rows) and 0.8 < Q[N] / (N * log(N) / H) < 1.0
assert sorted_cmp == 1000 * 999 // 2 and shuffled_cmp < sorted_cmp // 20
assert k_counts == [9, 27, 81] and prod == x * y                  # counted, against 3^k
assert sum(join_rows) == NL * K * (K + 1) // 2 and sum(join_rows) > 10 * NL * K
print("ALL CHECKS PASS")
