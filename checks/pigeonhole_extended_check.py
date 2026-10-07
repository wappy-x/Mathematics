# Pigeonhole, extended -- the check behind the card.  Nothing is imported.  100
# emails go into 12 folders and the fullest folder is found three ways: by the
# formula, by dealing the emails out one at a time, and by trying every filing at
# small sizes.  Then ten days of arrivals, and a run totalling a multiple of 10.
N, K, M = 100, 12, 10
ARRIVALS = [23, 41, 17, 8, 36, 52, 12, 29, 4, 31]

def ceil_div(n, k):                          # road one: n divided by k, rounded up
    return -(-n // k)

def fullest(code, n, k):                     # the load of the fullest box in one filing
    loads, c = [0] * k, code
    for _ in range(n): loads[c % k] += 1; c //= k
    return max(loads)

def prefixes(vals):                          # running totals, the first one empty
    return [sum(vals[:j]) for j in range(len(vals) + 1)]

def first_repeat(rs):                        # the two boxes that must collide
    seen = {}
    for i, r in enumerate(rs):
        if r in seen: return seen[r], i
        seen[r] = i

def runs(vals, m):                           # road two: check every run directly
    return [(i + 1, j + 1, sum(vals[i:j + 1])) for i in range(len(vals))
            for j in range(i, len(vals)) if sum(vals[i:j + 1]) % m == 0]

loads, q, r = [0] * K, N // K, N % K
for i in range(N): loads[i % K] += 1         # road two: hand the emails out in turn
cases = [(n, k) for n in range(1, 9) for k in range(1, 5)]
attained = all(min(fullest(c, n, k) for c in range(k ** n)) == ceil_div(n, k) for n, k in cases)
pre, found = prefixes(ARRIVALS), runs(ARRIVALS, M)
rems = [p % M for p in pre]; i0, i1 = first_repeat(rems)
seed, pig, hit = 1, 0, 0
for _ in range(2000):                        # our own random numbers, nothing imported
    lst = []
    for _ in range(10):
        seed = (1103515245 * seed + 12345) % 2147483648; lst.append(seed % 97 + 1)
    pig += first_repeat([p % M for p in prefixes(lst)]) is not None
    hit += len(runs(lst, M)) > 0

print(f"{N} emails into {K} folders: average load {N}/{K} = {N / K:.4f}, rounded up {ceil_div(N, K)}")
print(f"cap every folder at {q}: {K} x {q} = {K * q}, {N - K * q} emails left over; evenly, {N} = {q} x {K} + {r}")
print(f"{r} folders of {q + 1} and {K - r} folders of {q}: {r * (q + 1)} + {(K - r) * q} = {N}")
print(f"dealt one at a time, folder loads: {loads}, fullest {max(loads)}")
print(f"every filing of n items into k boxes, n = 1..8, k = 1..4: {len(cases)} cases, bound met and attained: {'yes' if attained else 'no'}")
print(f"mistake 1, whole part of n/k plus 1, on 120 emails in {K} folders: {120 // K + 1}, the truth is {ceil_div(120, K)}\nmistake 2, 13 folders counted instead of {K}: {ceil_div(N, 13)}, not {ceil_div(N, K)}")
print(f"ten days of arrivals: {ARRIVALS}\nrunning totals, starting with the empty one: {pre}\nremainders after dividing by {M}: {rems}")
print(f"{len(pre)} totals into {M} remainder boxes: totals {pre[i0]} and {pre[i1]} both leave {rems[i1]}\ndays {i0 + 1} to {i1} sum to {pre[i1]} - {pre[i0]} = {pre[i1] - pre[i0]}, a multiple of {M}")
print(f"every run summing to a multiple of {M}, by search: {found}")
print(f"mistake 3, the empty total left out: {len(pre) - 1} totals, {M} boxes, nothing forced")
print(f"2000 random ten-day lists: {pig} found a run by remainders, {hit} by search")
assert ceil_div(N, K) == max(loads) and loads.count(q + 1) == r
assert attained and fullest(0, N, K) == N
assert (i0, i1) == (4, 7) and (i0 + 1, i1, pre[i1] - pre[i0]) in found
assert pig == 2000 and hit == 2000
print("ALL CHECKS PASS")
