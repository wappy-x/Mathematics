# Linear-time sorting and selection -- the check behind the card.  Standard library only:
# no sorted(), heapq or random; every sort and select is written out and counts its own steps.
# Roads: radix against merge sort; quickselect's pair count against its closed form, all 40,320
# orders of eight tracks and seeded runs; median of medians against its worst-case recurrence.
from math import log, log2; from functools import reduce; from itertools import permutations
def splitmix(s):                     # SplitMix64: the seeded coin for data and pivots
    while True:
        s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1)
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
        yield z ^ (z >> 31)
def radix(items, base, passes, t, stable=True):  # items are (plays, id); sort by plays
    for p in range(passes):
        tally = [0] * base
        for it in items:
            tally[it[0] // base**p % base] += 1; t[0] += 1   # one tally per track
        start, s = [0] * base, 0
        for v in range(base):
            start[v] = s; s += tally[v]; t[0] += 1           # one running sum per bucket
        out = [None] * len(items)
        for it in items:
            d = it[0] // base**p % base; t[0] += 1           # one placement per track
            if stable: out[start[d]] = it; start[d] += 1
            else: out[start[d] + tally[d] - 1] = it; tally[d] -= 1   # fills each bucket backwards
        items = out
    return items
def merge_sort(a, t):                # compares plays only; ties go left, so it is stable
    if len(a) <= 1: return a
    L, R = merge_sort(a[:len(a) // 2], t), merge_sort(a[len(a) // 2:], t)
    out, i, j = [], 0, 0
    while i < len(L) and j < len(R):
        t[0] += 1
        if L[i][0] <= R[j][0]: out.append(L[i]); i += 1
        else: out.append(R[j]); j += 1
    return out + L[i:] + R[j:]
def quickselect(a, k, t, coin=None):  # k-th smallest; pivot first, or chosen by the coin
    while True:
        if len(a) == 1: return a[0]
        pi = 0 if coin is None else next(coin) % len(a)
        p, less, more = a[pi], [], []
        for x in a[:pi] + a[pi + 1:]:
            t[0] += 1; (less if x < p else more).append(x)
        if k <= len(less): a = less
        elif k == len(less) + 1: return p
        else: k, a = k - len(less) - 1, more
def isort(a, t):                     # insertion sort, counting comparisons
    a = list(a)
    for i in range(1, len(a)):
        x, j = a[i], i - 1
        while j >= 0:
            t[0] += 1
            if a[j] <= x: break
            a[j + 1] = a[j]; j -= 1
        a[j + 1] = x
    return a
def mom(a, k, t, g=5, rounds=None):  # median of medians: worst-case linear selection
    while True:
        if len(a) <= g: return isort(a, t)[k - 1]
        meds = [s[(len(s) - 1) // 2] for s in (isort(a[i:i + g], t) for i in range(0, len(a), g))]
        p = mom(meds, (len(meds) + 1) // 2, t, g)
        less = [x for x in a if x < p]; more = [x for x in a if x > p]; t[0] += len(a) - 1   # counts a one-pass split
        if rounds is not None: rounds.append((len(a), len(meds), p, len(less), len(more)))
        if k <= len(less): a = less
        elif k == len(less) + 1: return p
        else: k, a = k - len(less) - 1, more
def worst(N, g):                     # mom's worst case at every size up to N, made non-decreasing
    W = [0] * (N + 1)
    for n in range(1, N + 1):
        if n <= g: c = n * (n - 1) // 2
        else:
            q, r, m = n // g, n % g, -(-n // g)
            side = n - 1 - max(0, (g + 1) // 2 * (-(-m // 2) - 2))   # guaranteed cut off
            c = q * g * (g - 1) // 2 + r * (r - 1) // 2 + W[m] + (n - 1) + W[side]
        W[n] = max(W[n - 1], c)
    return W
def add(xs): return reduce(lambda s, x: s + x, xs, 0.0)   # left to right, as in Rust
def H(n): return add(1 / i for i in range(1, n + 1))
def knuth(n, k): return 2 * ((n + 1) * H(n) - (n + 3 - k) * H(n + 1 - k) - (k + 2) * H(k) + n + 3)
def pairs(n, k):                     # sum over pairs i<j of 2/(span+1), grouped by span
    s = add(2 * (k - i) / (k - i + 1) for i in range(1, k)) + add(2 * (j - k) / (j - k + 1) for j in range(k + 1, n + 1))
    for d in range(2, n):
        c = min(k - 1, n - d) - max(1, k + 1 - d) + 1
        if c > 0: s += 2 * c / (d + 1)
    return s

eight = [(x, i) for i, x in enumerate([47, 12, 85, 43, 19, 82, 15, 40])]
t = [0]; print("eight, pass 1 by ones digit:", [x for x, _ in radix(eight, 10, 1, t)], "steps", t[0])
t = [0]; print("eight, both passes:", [x for x, _ in radix(eight, 10, 2, t)], "steps", t[0])
print("eight, unstable passes:", [x for x, _ in radix(eight, 10, 2, [0], stable=False)])
e8 = [x for x, _ in eight]; t = [0]; print("eight, quickselect k=4, first pivot:", quickselect(e8, 4, t), "comparisons", t[0])
rd = []; t = [0]; print("eight, median of medians:", mom(e8, 4, t, rounds=rd), "comparisons", t[0], "round", rd)
tot, mw = 0, 0
for p in permutations(e8):
    t = [0]; assert quickselect(list(p), 4, t) == 40; tot += t[0]
    t = [0]; assert mom(list(p), 4, t) == 40; mw = max(mw, t[0])
N, coin, lib = 1_000_000, splitmix(2026), []; W5 = worst(N, 5)
print(f"all 40320 orders: quickselect average {tot / 40320:.4f}, pair sum {pairs(8, 4):.4f}, closed form {knuth(8, 4):.4f}")
print("all 40320 orders: median of medians worst", mw, "recurrence bound", W5[8])
assert abs(tot / 40320 - pairs(8, 4)) < 1e-9 and abs(pairs(8, 4) - knuth(8, 4)) < 1e-9 and mw <= W5[8]
for i in range(N):
    r = next(coin); lib.append(((r >> 44) * ((r >> 24) & 0xFFFFF) >> 20, i))
print("library: 1000000 synthetic play counts, SplitMix64 seed 2026, plays = a*b >> 20, max", max(x for x, _ in lib))
tm, tr, tc, tu = [0], [0], [0], [0]
ms, rs, cs, us = merge_sort(lib, tm), radix(lib, 1024, 2, tr), radix(lib, 2**20, 1, tc), radix(lib, 1024, 2, tu, False)
print(f"merge sort {tm[0]} comparisons; floor log2 n! = {add(log2(i) for i in range(1, N + 1)):.1f} for different keys")
print("radix base 1024, 2 passes:", tr[0], "steps; counting sort base 2^20:", tc[0], "steps, 1048576 counters")
print("radix and counting sort equal merge sort, ties in track order:", rs == ms and cs == ms)
assert rs == ms and cs == ms and tr[0] == 2 * (2 * N + 1024) and tc[0] == 2 * N + 2**20
print("unstable passes: adjacent pairs out of order", sum(us[i][0] > us[i + 1][0] for i in range(N - 1)))
for b in (2, 16, 256, 1024, 2**20):
    d = -(-20 // round(log2(b))); print(f"bars, base {b}: {d} passes, {d * (2 * N + b)} steps")
keys = [x * 2**20 + i for x, i in lib]; K = N // 2; truth = ms[K - 1]
tq, tm5, r5 = [0], [0], []; qv = quickselect(keys, K, tq, splitmix(7)); mv = mom(keys, K, tm5, rounds=r5)
print("median play count", truth[0], "(track", truth[1], "); quickselect", qv >> 20, "; median of medians", mv >> 20)
assert qv == mv == truth[0] * 2**20 + truth[1]
E = pairs(N, K)
print(f"quickselect {tq[0]} comparisons; expected {E:.1f} = closed form {knuth(N, K):.1f}; 2n(1+ln2) = {2 * N * (1 + log(2)):.1f}")
runs = []
for s in range(400):
    t = [0]; quickselect(keys[:1001], 501, t, splitmix(100 + s)); runs.append(t[0])
mean = sum(runs) / 400; sd = (add((x - mean) ** 2 for x in runs) / 399) ** 0.5
print(f"400 runs on 1001 tracks: mean {mean:.1f}, expected {pairs(1001, 501):.1f}, sd {sd:.1f}, off by {(mean - pairs(1001, 501)) / (sd / 20):.2f} se")
print(f"library run off by {(tq[0] - E) / (sd / 1001 * N):.2f} sd, sd scaled up from 1001 tracks")
assert abs(mean - pairs(1001, 501)) < 4 * sd / 20 and abs(tq[0] - E) < 4 * sd / 1001 * N
worst_n = max(range(1, N + 1), key=lambda n: W5[n] / n)
print(f"median of medians {tm5[0]} comparisons; worst-case recurrence {W5[N]}; 30n = {30 * N}; largest W(n)/n {W5[worst_n] / worst_n:.2f} at n={worst_n}")
print(f"median of medians on the library: {len(r5)} rounds; round 1 split {r5[0][0]} tracks into {r5[0][3]} below and {r5[0][4]} above, at least {3 * (-(-r5[0][1] // 2) - 2)} each guaranteed")
assert tm5[0] <= W5[N] and all(W5[n] <= 30 * n for n in range(1, N + 1)) and all(min(lo, hi) >= 3 * (-(-m // 2) - 2) for _, m, _, lo, hi in r5)
W3 = worst(N, 3)
for n in (1000, 10000, 100000, N):
    a, b, c, d = [0], [0], [0], [0]
    merge_sort(lib[:n], a); radix(lib[:n], 1024, 2, b); quickselect(keys[:n], n // 2, c, splitmix(7)); mom(keys[:n], n // 2, d)
    print(f"per track at n={n}: merge {a[0] / n:.2f}, radix {b[0] / n:.2f}, quickselect {c[0] / n:.2f}, mom {d[0] / n:.2f}, mom bound {W5[n] / n:.2f}, groups of 3 bound {W3[n] / n:.2f}")
t = [0]; quickselect(list(range(1000)), 500, t); print(f"sorted playlist of 1000, first-pivot quickselect: {t[0]}; library formula {K * N - K * (K + 1) // 2}")
assert t[0] == 500 * 1000 - 500 * 501 // 2 and W3[N] > W3[1000] * N // 1000 + 15 * N
rd = []; mom(keys[:45], 23, [0], rounds=rd); n45, g45, p45, lo, hi = rd[0]; m = (g45 + 1) // 2
print("figure,", n45, "tracks,", g45, "groups; grid guarantees", 3 * (m - 1) + 2, "below,", 3 * (g45 - m) + 2, "above; pivot plays", p45 >> 20, "; actual", lo, "below,", hi, "above")
print(f"try: base 256 needs 3 passes, {3 * (2 * N + 256)} steps; quickselect at k=1 expects {pairs(N, 1):.1f}")
print(f"try: groups of 7 bound {worst(N, 7)[N] / N:.2f} per track; 2000000 tracks, quickselect expects {knuth(2 * N, N):.1f}")
print("ALL CHECKS PASS")
