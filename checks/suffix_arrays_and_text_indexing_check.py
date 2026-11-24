# Suffix arrays -- the check behind the card.  Standard library only: no sorted(), no
# bisect.  Roads: suffixes sorted by a written-out merge sort against prefix doubling;
# neighbour LCPs compared directly against Kasai's method; distinct substrings by formula
# against a brute-force set; pattern counts by binary search, full scan and the BWT.
from math import log2

def splitmix(s):                      # SplitMix64: returns (new state, output)
    s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return s, z ^ (z >> 31)

def msort(a, less):                   # merge sort with a "comes before" test
    if len(a) <= 1: return a
    l, r, out, i, j = msort(a[:len(a) // 2], less), msort(a[len(a) // 2:], less), [], 0, 0
    while i < len(l) and j < len(r):
        if less(r[j], l[i]): out.append(r[j]); j += 1
        else: out.append(l[i]); i += 1
    return out + l[i:] + r[j:]

def lcp_direct(t, a, b):              # letters shared by suffixes a and b, one by one
    return next(h for h in range(len(t) + 1) if max(a, b) + h >= len(t) or t[a + h] != t[b + h])

def naive_sa(t, cnt):                 # compare whole suffixes letter by letter
    def less(i, j):                   # the suffix that runs out first comes first
        h = lcp_direct(t, i, j); cnt[0] += min(h + 1, len(t) - max(i, j))
        return i + h == len(t) or (j + h < len(t) and t[i + h] < t[j + h])
    return msort(list(range(len(t))), less)

def bucket(idx, key, size):           # stable sort by a small whole-number key
    b = [[] for _ in range(size)]
    for i in idx: b[key(i)].append(i)
    return [i for x in b for i in x]

def doubling(t):                      # rank by first 2 letters, then 4, 8, ...
    n, rank, k, log = len(t), [ord(c) for c in t], 1, []
    while True:
        r = rank
        key = lambda i: (r[i], r[i + k] if i + k < n else -1)
        sa = bucket(range(n), lambda i: key(i)[1] + 1, max(r) + 2)
        sa, rank = bucket(sa, lambda i: r[i], max(r) + 1), [0] * n
        for a in range(1, n): rank[sa[a]] = rank[sa[a - 1]] + (key(sa[a]) != key(sa[a - 1]))
        log.append((2 * k, rank))
        if rank[sa[-1]] == n - 1: return sa, log
        k *= 2

def kasai(t, sa, cnt):                # LCP array, counting letters compared
    n, h, rank, lcp = len(t), 0, {i: a for a, i in enumerate(sa)}, [0] * len(t)
    for i in range(n):
        if rank[i] == 0: h = 0; continue
        j, h0 = sa[rank[i] - 1], h
        while max(i, j) + h < n and t[i + h] == t[j + h]: h += 1
        cnt[0] += h - h0 + (max(i, j) + h < n)
        lcp[rank[i]], h = h, max(h - 1, 0)   # the next suffix keeps all but one letter
    return lcp

def bound(t, sa, p, upper, cnt):      # first rank whose suffix starts > p (or >= p)
    lo, hi, looks = 0, len(sa), 0
    while lo < hi:
        mid = (lo + hi) // 2; looks += 1; s = t[sa[mid]:sa[mid] + len(p)]
        q = next((q for q in range(len(s)) if s[q] != p[q]), len(s))
        cnt[0] += min(q + 1, len(s))
        c = 0 if q == len(p) else (-1 if q == len(s) or s[q] < p[q] else 1)
        if c < 0 or (upper and c == 0): lo = mid + 1
        else: hi = mid
    return lo, looks

def scan(t, p, cnt):                  # try every start, stop at the first mismatch
    hits = 0
    for i in range(len(t) - len(p) + 1):
        q = next((q for q in range(len(p)) if t[i + q] != p[q]), len(p))
        cnt[0] += min(q + 1, len(p)); hits += q == len(p)
    return hits

def bwt(t):                           # last column of the sorted rotations of t + "$"
    return "".join((t + "$")[i - 1] for i in doubling(t + "$")[0])

def backward_count(L, p):             # FM-index style: read the pattern right to left
    lo, hi = 0, len(L)
    for c in reversed(p):
        C = sum(x < c for x in L)     # letters in the text smaller than c
        lo, hi = C + L.count(c, 0, lo), C + L.count(c, 0, hi)
        if lo >= hi: return 0
    return hi - lo

def inverse_bwt(L):                   # walk last-to-first from the "$" row
    row, out = 0, []
    for _ in range(len(L) - 1):
        c = L[row]; out.append(c); row = sum(x < c for x in L) + L.count(c, 0, row)
    return "".join(reversed(out))

def index_report(t, p):
    c1, c2, c3, c4 = [0], [0], [0], [0]; sa, log = doubling(t)
    assert naive_sa(t, c1) == sa, "doubling and merge sort disagree"
    lcp = kasai(t, sa, c2); assert c2[0] <= 2 * len(t), "Kasai compared over 2n letters"
    assert lcp[1:] == [lcp_direct(t, sa[a - 1], sa[a]) for a in range(1, len(t))], "Kasai"
    (lo, l1), (hi, l2) = bound(t, sa, p, False, c3), bound(t, sa, p, True, c3)
    assert hi - lo == scan(t, p, c4) == backward_count(bwt(t), p), "pattern counts disagree"
    return sa, lcp, len(log), c1[0], c2[0], lo, hi, l1 + l2, c3[0], c4[0]

w = "banana"; n = len(w); sa, lcp, rounds, nv, ks, lo, hi, looks, sc, scn = index_report(w, "ana")
print("banana suffix array:", *sa, "| suffixes:", *[w[i:] for i in sa])
print("banana LCP:", *lcp, "| sum", sum(lcp))
for k, r in doubling(w)[1]: print(f"doubling: ranks by first {k} letters:", *r)
print(f"rounds {rounds}; merge sort letters compared {nv}; Kasai letters compared {ks}")
assert sa == [5, 3, 1, 0, 4, 2] and lcp == [0, 1, 3, 0, 0, 2]
brute = len({w[i:j] for i in range(n) for j in range(i + 1, n + 1)})
print(f"distinct substrings: {n * (n + 1) // 2} - {sum(lcp)} = {n * (n + 1) // 2 - sum(lcp)}; brute force {brute}")
assert n * (n + 1) // 2 - sum(lcp) == brute == 15
print(f"search 'ana': ranks {lo} to {hi - 1}, count {hi - lo}, starts", *msort(sa[lo:hi], lambda a, b: a < b), f"| looks {looks}, letters {sc} (promise {2 * 3 * (int(log2(n)) + 1)}); scan letters {scn}")
print("BWT of banana$:", bwt(w), "| inverse:", inverse_bwt(bwt(w)), "| backward count 'ana':", backward_count(bwt(w), "ana"))
assert bwt(w) == "annb$aa" and inverse_bwt(bwt(w)) == w

words = "love night blue river fire home dream summer road heart rain gold city moon light song".split()
s, cat, plays = 2026, [], []
for _ in range(50):
    s, a = splitmix(s); s, b = splitmix(s); cat.append(words[a % 16] + " " + words[b % 16])
for _ in range(2000): s, z = splitmix(s); plays.append(cat[z % 50])
t = "|".join(plays); N = len(t); sa, lcp, rounds, nv, ks, lo, hi, looks, sc, scn = index_report(t, "love")
print(f"play log: 2000 plays of 50 titles, seed 2026, {N} characters, {rounds} doubling rounds")
print(f"merge sort letters compared {nv} ({nv / (N * log2(N)):.2f} per n log2 n); Kasai {ks} (2n = {2 * N}); longest repeat {max(lcp)}")
print(f"distinct substrings: {N * (N + 1) // 2} - {sum(lcp)} = {N * (N + 1) // 2 - sum(lcp)}")
p3 = t[:300]; l3 = kasai(p3, doubling(p3)[0], [0]); f3 = 300 * 301 // 2 - sum(l3)
b3 = len({p3[i:j] for i in range(300) for j in range(i + 1, 301)})
print(f"first 300 characters: formula {f3}, brute force {b3}"); assert f3 == b3
pr = 2 * 4 * (int(log2(N)) + 1); assert sc <= pr, "search broke its promise"
print(f"search 'love': count {hi - lo}, looks {looks}, letters {sc} (promise {pr}); scan letters {scn}")
for m in (250, 500, 1000, 2000):
    u = "|".join(plays[:m]); r = index_report(u, "love")
    print(f"chart, {m} plays, {len(u)} characters, count {r[6] - r[5]}, suffix array letters {r[8]}, scan letters {r[9]}")
L = 1_000_000 * round(N / 2000); lk = int(log2(L)) + 1     # titles as long as the log's own plays
print(f"library: 1000000 titles x {L // 1_000_000} characters ({N} / 2000 plays, rounded) = {L}; looks per boundary {lk}; letters at most {2 * lk * 4}; array bytes {4 * L}")
print(f"breaks: n(n+1)/2 without LCP = {n * (n + 1) // 2}, true 15")
u0, u1 = bound(w, list(range(n)), "na", False, [0])[0], bound(w, list(range(n)), "na", True, [0])[0]
print(f"breaks: binary search on unsorted starts 0..5 for 'na': count {u1 - u0}, true {scan(w, 'na', [0])}")
rot = lambda x: "".join(r[-1] for r in msort([x[i:] + x[:i] for i in range(len(x))], lambda a, b: a < b))
print(f"breaks: rotations without $: banana -> {rot('banana')}, nanaba -> {rot('nanaba')}")
for m in (250, 500, 1000):
    c = [0]; naive_sa("a" * m, c); print(f"breaks: merge sort on {m} a's: letters compared {c[0]}, doubling rounds {len(doubling('a' * m)[1])}")
print("ALL CHECKS PASS")
