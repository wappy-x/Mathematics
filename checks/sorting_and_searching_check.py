# Sorting and searching -- the check behind the card.  Standard library only:
# no sorted(), no bisect, no heapq.  Every sort and search is written out here
# and counts its own comparisons.  Roads: the decision-tree floor log2 n!,
# every one of the 40,320 orders of the eight tracks, the quicksort pair-count
# formula, and seeded runs on 1,000,000 synthetic keys from SplitMix64.
from math import log2, e, pi, sqrt
from itertools import permutations

def merge_sort(a, t):                # t = [comparisons, answer record or None, log or None]
    if len(a) <= 1:
        return a
    left, right = merge_sort(a[:len(a) // 2], t), merge_sort(a[len(a) // 2:], t)
    out, i, j, before = [], 0, 0, t[0]
    while i < len(left) and j < len(right):
        t[0] += 1
        take_left = left[i] <= right[j]          # ties go left, so equal keys keep their order
        if t[1] is not None:
            t[1].append(take_left)
        if take_left:
            out.append(left[i]); i += 1
        else:
            out.append(right[j]); j += 1
    if t[2] is not None:
        t[2].append(t[0] - before)
    return out + left[i:] + right[j:]

def quicksort(a, t, middle=False):   # partition around a pivot; an explicit stack, no recursion
    a, stack = list(a), [(0, len(a))]
    while stack:
        lo, hi = stack.pop()
        if hi - lo <= 1:
            continue
        if middle:
            m = (lo + hi) // 2; a[lo], a[m] = a[m], a[lo]
        p, less, more = a[lo], [], []
        for x in a[lo + 1:hi]:
            t[0] += 1                            # every other track meets the pivot once
            (less if x < p else more).append(x)
        if t[2] is not None:
            t[2].append((p, hi - lo - 1))
        a[lo:hi] = less + [p] + more
        stack += [(lo + len(less) + 1, hi), (lo, lo + len(less))]
    return a

def search(a, x):                    # halve the live range until x turns up
    lo, hi, probes = 0, len(a) - 1, 0
    while lo <= hi:
        mid = (lo + hi) // 2; probes += 1
        if a[mid] == x:
            return mid, probes
        if a[mid] < x: lo = mid + 1
        else: hi = mid - 1
    return -1, probes

def plain_sum(xs):                  # left to right, as the Rust does (sum() compensates)
    s = 0.0
    for x in xs:
        s += x
    return s
def floor_bits(n): return plain_sum(log2(k) for k in range(2, n + 1))  # log2 n!, the floor
def merge_worst(n): c = (n - 1).bit_length(); return n * c - 2 ** c + 1
def is_sorted(a): return all(a[i] <= a[i + 1] for i in range(len(a) - 1))
def yn(claim): return "yes" if claim else "no"
def comps(f, a, **kw): t = [0, None, None]; f(a, t, **kw); return t[0]

tracks = [214, 187, 263, 198, 305, 241, 176, 229]          # lengths in seconds
tm, tq = [0, None, []], [0, None, []]
by_merge, by_quick = merge_sort(tracks, tm), quicksort(tracks, tq)
print(f"eight tracks (seconds): {tracks}")
print(f"merge sort -> {by_merge}: comparisons per merge {tm[2]}, total {tm[0]}")
print(f"quicksort, first track as pivot: (pivot, comparisons) {tq[2]}, total {tq[0]}, same order: {yn(by_quick == by_merge)}")
found = [search(by_merge, x)[1] for x in by_merge]
print(f"binary search for 263: position {search(by_merge, 263)[0]}, probes {search(by_merge, 263)[1]}; probes for each track {found}, most {max(found)}")
n8 = 1
for k in range(2, 9):
    n8 *= k
three = [comps(merge_sort, list(o)) for o in permutations(tracks[:3])]
print(f"three tracks: 3! = {len(three)} orders; log2 6 = {floor_bits(3):.4f}; 2^2 = {2 ** 2} < 6; merge sort asks "
      f"{comps(merge_sort, tracks[:3])} on 214, 187, 263, fewest {min(three)}, most {max(three)}")
print(f"8! = {n8} orders; floor log2 8! = {floor_bits(8):.4f}; 2^15 = {2 ** 15}, so at least 16 in the worst case")
mtot = mmax = qtot = qmax = 0
records = set()
for order in permutations(tracks):
    t = [0, [], None]; merge_sort(list(order), t); records.add(tuple(t[1]))
    mtot += t[0]; mmax = max(mmax, t[0])
    c = comps(quicksort, list(order)); qtot += c; qmax = max(qmax, c)
harm8 = sum(n8 // k for k in range(1, 9))                  # 8! times H_8, a whole number
q_formula = 2 * 9 * harm8 - 4 * 8 * n8                     # 8! times (2(n+1)H_n - 4n)
print(f"all {n8} orders, merge sort: worst {mmax} (bound n*ceil(log2 n) - 2^ceil(log2 n) + 1 = {merge_worst(8)}), average {mtot / n8:.4f}")
print(f"all {n8} orders, quicksort: worst {qmax} = 8*7/2, total {qtot}, formula total {q_formula}, average {qtot / n8:.4f}, H_8 = {harm8 / n8:.4f}")
print(f"different yes/no answer records under merge sort: {len(records)}")
M = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return s, z ^ (z >> 31)
N, s, keys = 1_000_000, 2026, []
for _ in range(N):
    s, k = splitmix(s); keys.append(k)
lib_floor = floor_bits(N)
stirling = N * log2(N) - N * log2(e) + 0.5 * log2(2 * pi * N)
print(f"library: {N} synthetic keys, SplitMix64 seed 2026")
print(f"floor log2 n! = {lib_floor:.1f}; Stirling {stirling:.1f}; n log2 n = {N * log2(N):.1f}")
t = [0, None, None]; lib = merge_sort(keys, t)
print(f"merge sort counted {t[0]}; worst-case bound {merge_worst(N)}; in order: {yn(is_sorted(lib))}")
qs = comps(quicksort, keys)
q_mean = 2 * (N + 1) * plain_sum(1 / k for k in range(1, N + 1)) - 4 * N
q_sd = sqrt(7 - 2 * pi * pi / 3) * N
print(f"quicksort counted {qs}; average 2(n+1)H_n - 4n = {q_mean:.1f}; sd {q_sd:.1f}; off by {(qs - q_mean) / q_sd:.2f} sd")
probes = [search(lib, x) for x in lib]
right = all(p[0] == i for i, p in enumerate(probes))
most, avg = max(p[1] for p in probes), sum(p[1] for p in probes) / N
print(f"binary search for all {N} keys: all found where they sit: {yn(right)}; most {most} probes, average {avg:.4f}")
print(f"k looks name at most 2^k - 1 positions: 2^{most - 1} - 1 = {2 ** (most - 1) - 1} < {N} <= 2^{most} - 1 = {2 ** most - 1}")
playlist = lib[:1000]
print(f"sorted playlist of 1000: first-pivot quicksort {comps(quicksort, playlist)} = 1000*999/2; merge sort {comps(merge_sort, playlist)}")
print(f"whole library already sorted, first-pivot quicksort: {N * (N - 1) // 2}")
print(f"unsorted eight, binary search for 305: position {search(tracks, 305)[0]} after {search(tracks, 305)[1]} probes")
secs = [120 + k % 361 for k in keys]                       # whole-second lengths, 2:00 to 8:00
tally = [0] * 361
for x in secs:
    tally[x - 120] += 1
by_count = [120 + v for v in range(361) for _ in range(tally[v])]
print(f"counting sort on whole-second lengths: 0 comparisons, {N} + 361 steps, in order: {yn(is_sorted(by_count))}")
ordered8 = by_merge
print(f"try: eight already in order, merge sort {comps(merge_sort, ordered8)}, quicksort {comps(quicksort, ordered8)}")
print(f"try: middle track as pivot on the sorted 1000: {comps(quicksort, playlist, middle=True)}")
print(f"try: 2000000 tracks, floor {floor_bits(2 * N):.1f}, binary search at most {(2 * N).bit_length()} probes")
print(f"try: 16 tracks, floor {floor_bits(16):.4f}, merge sort worst {merge_worst(16)}")
assert mmax == merge_worst(8) and mmax >= 16 > floor_bits(8)       # brute force meets the bound
assert mtot / n8 >= floor_bits(8) and qtot / n8 >= floor_bits(8)   # the floor binds the average too
assert qtot == q_formula and qmax == 8 * 7 // 2 and by_quick == by_merge  # pair-count formula
assert len(records) == n8 and max(three) == 3 > floor_bits(3)        # every order needs its own leaf
assert is_sorted(lib) and t[0] <= merge_worst(N) and abs(qs - q_mean) < 4 * q_sd
assert right and most == N.bit_length() and comps(quicksort, playlist) == 1000 * 999 // 2
assert by_count == merge_sort(secs, [0, None, None]) and search(tracks, 305)[0] == -1
print("ALL CHECKS PASS")
