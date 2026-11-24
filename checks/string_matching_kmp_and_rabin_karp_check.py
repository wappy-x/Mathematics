# Finding a pattern in text -- the check behind the card.  Nothing is imported.
# A synthetic play log: 1,000,000 plays, each written as one letter for the playlist it came
# from (A, B or C, coded 1, 2, 3), drawn by SplitMix64 with seed 2026.  Search it for ABABAC
# three ways.  Every cost counts letter comparisons, never time.
M64 = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def code(w): return [" ABC".index(ch) for ch in w]
def failure(p):                         # pi[q]: longest proper border of p[0..q]
    pi, k, cost = [0] * len(p), 0, 0
    for q in range(1, len(p)):
        while True:
            cost += 1
            if p[k] == p[q]: k += 1; break
            if k == 0: break
            k = pi[k - 1]
        pi[q] = k
    return pi, cost
def borders_brute(p):                   # road 2: try every length, longest first
    return [max(L for L in range(q + 1) if p[:L] == p[q + 1 - L:q + 1]) for q in range(len(p))]
def kmp(t, p, pi, trace=None):          # the text index i only ever goes up
    hits, q, cost = [], 0, 0
    for i in range(len(t)):
        while True:
            cost += 1
            if p[q] == t[i]: q += 1; break
            if q == 0: break
            q = pi[q - 1]
        if trace is not None: trace.append(q)
        if q == len(p): hits.append(i - len(p) + 1); q = pi[q - 1]
    return hits, cost
def naive(t, p):                        # slide one place, re-read from the pattern's start
    hits, cost = [], 0
    for s in range(len(t) - len(p) + 1):
        j = 0
        while j < len(p):
            cost += 1
            if t[s + j] != p[j]: break
            j += 1
        if j == len(p): hits.append(s)
    return hits, cost
def H(w, b, mod):                       # fingerprint: w read as a number in base b, mod p
    h = 0
    for c in w: h = (h * b + c) % mod
    return h
def rabin_karp(t, p, b, mod, verify=True):
    m, top = len(p), 1
    for _ in range(m - 1): top = top * b % mod
    hp, ht = H(p, b, mod), H(t[:m], b, mod)
    hits, false, cost = [], 0, 0
    for s in range(len(t) - m + 1):
        if s: ht = ((ht - t[s - 1] * top) * b + t[s + m - 1]) % mod   # the roll
        if ht != hp: continue
        if not verify: hits.append(s); continue
        j = 0
        while j < m:
            cost += 1
            if t[s + j] != p[j]: break
            j += 1
        if j == m: hits.append(s)
        else: false += 1
    return hits, false, cost
P, m = code("ABABAC"), 6
pi, build = failure(P)
print("pattern ABABAC; failure table", *pi, f"({build} comparisons to build)")
assert pi == borders_brute(P) == [0, 0, 1, 2, 3, 0]
hand = code("ABABABACABABAC")
tr = []; hk, ck = kmp(hand, P, pi, tr); hn, cn = naive(hand, P)
print("hand log ABABABACABABAC, state after each letter:", *tr)
print(f"hand log matches start at {hk}: KMP {ck} comparisons, naive {cn}")
hr, fr, cr = rabin_karp(hand, P, 10, 101)
print("hand fingerprints, base 10 mod 101: pattern", H(P, 10, 101), "windows",
      *[H(hand[s:s + m], 10, 101) for s in range(len(hand) - m + 1)])
roll = (H(hand[:m], 10, 10**9) - hand[0] * 10**5) * 10 + hand[m]    # no mod: digits show
print(f"hand roll, window 0 to 1: ({H(hand[:m], 10, 10**9)} - {hand[0]} x 100000) x 10 + {hand[m]} = {roll}")
nt, _ = kmp(hand, P, [0] * m)
print(f"hand Rabin-Karp: matches {hr}, false hits {fr}, check comparisons {cr}")
print("hand log, no table (restart the pattern, keep the text):", nt)
_, c1 = kmp(code("ABABAA"), P, pi); _, c2 = kmp(code("AAAAAC"), code("AAAAAB"), failure(code("AAAAAB"))[0])
print(f"one letter can cost more: ABABAA takes {c1}, {c1 - 5} on its last A; AAAAAC searched for AAAAAB takes {c2}, {c2 - 5} = m on the C")
assert roll == H(hand[1:m + 1], 10, 10**9) == 212121 and hk == hn == hr == [2, 8] and fr == 1 and nt == [8] and c1 == 9 and c2 == 11
s, log = 2026, []
for _ in range(1_000_000):
    s, z = splitmix(s); log.append(z % 3 + 1)
n = len(log)
s, z = splitmix(s); b0 = z % 101; s, z = splitmix(s); b1 = z % 1_000_000_007
hits_k, cost_k = kmp(log, P, pi); hits_n, cost_n = naive(log, P)
hits_r, false_r, ver_r = rabin_karp(log, P, b1, 1_000_000_007)
print(f"log of {n:,} plays: {len(hits_k):,} matches; first at {hits_k[0]:,}, last at {hits_k[-1]:,}")
print(f"comparisons: KMP {cost_k:,} ({cost_k / n:.4f} per play), naive {cost_n:,} ({cost_n / n:.4f})")
print(f"Rabin-Karp, p = 1,000,000,007, base {b1:,}: false hits {false_r}, check comparisons {ver_r:,}")
print(f"bound on expected false hits, (n - m + 1) x 5 / p = {(n - m + 1) * 5 / 1_000_000_007:.4f}")
assert hits_k == hits_n == hits_r and cost_k <= 2 * n and false_r == 0
alt = [1, 2] * 500_000                  # ABAB...: the log that punishes re-reading
ak, ca = kmp(alt, P, pi); an, cna = naive(alt, P)
print(f"alternating log ABAB...: matches {len(ak)}, KMP {ca:,}, naive {cna:,}")
assert ak == an == [] and ca <= 2 * n and cna == 6 * 499_998 + 499_997
count, idx = [0] * 729, 0               # road 2 for the fingerprints: window types, exact
for i, c in enumerate(log):
    idx = (idx * 3 + c - 1) % 729
    if i >= m - 1: count[idx] += 1
allw = []
for v in range(729):
    w, x = [], v
    for _ in range(m): w.append(x % 3 + 1); x //= 3
    allw.append(w[::-1])
tab = sum(failure(w)[0] == borders_brute(w) for w in allw)   # road 2 for the table: every word
print(f"failure tables: linear build equals brute force for {tab} of {len(allw)} six-letter words")
hpP = [H(P, b, 101) for b in range(101)]
bad = [sum(H(w, b, 101) == hpP[b] for b in range(101)) if w != P else 0 for w in allw]
worst = max(bad)
print(f"every 6-letter word against ABABAC, mod 101: at most {worst} bad bases of 101 (bound 5)")
print("a word with the most:", "".join(" ABC"[c] for c in allw[bad.index(worst)]), "; words with none:", bad.count(0) - 1)
_, f0, _ = rabin_karp(log, P, b0, 101)
f0_types = sum(count[v] for v in range(729) if allw[v] != P and H(allw[v], b0, 101) == hpP[b0])
nonmatch = n - m + 1 - len(hits_k)
mean_f = sum(count[v] * bad[v] for v in range(729)) / 101
print(f"mod 101, base {b0}: false hits by rolling {f0:,}, by counting window types {f0_types:,}")
print(f"mod 101, averaged over all 101 bases: {mean_f:,.1f} false hits; bound 5/101 x {nonmatch:,} = {5 * nonmatch / 101:,.1f}")
assert worst <= m - 1 and f0 == f0_types and mean_f <= 5 * nonmatch / 101 and tab == len(allw)
r1, f1, _ = rabin_karp(log, P, 1, 1_000_000_007); r2, _, _ = rabin_karp(log, P, b0, 101, verify=False)
print(f"base 1 (fingerprint = letter sum): false hits {f1:,}")
print(f"mod 101 with no check: reports {len(r2):,} matches, true {len(hits_k):,}")
nl, _ = kmp(log, P, [0] * m)
print(f"no failure table on the log: finds {len(nl):,} of {len(hits_k):,}")
f1_sum = sum(count[v] for v in range(729) if sum(allw[v]) == sum(P) and allw[v] != P)
assert f1 == f1_sum and len(r2) == len(hits_k) + f0 and len(nl) < len(hits_k)
rows = []
for mm in (50, 100, 150, 200, 250, 300):  # worst case: AAA...A searched for AA...AB
    tt, pp = [1] * 5000, [1] * (mm - 1) + [2]
    _, ck2 = kmp(tt, pp, failure(pp)[0]); _, cn2 = naive(tt, pp)
    assert cn2 == mm * (5000 - mm + 1) and ck2 == 2 * 5000 - mm + 1
    rows.append((mm, cn2, ck2))
print("growth, text A x 5,000, pattern A..AB of length m:", *[f"m={a}" for a, _, _ in rows])
print("  naive, m(n - m + 1):", *[f"{c:,}" for _, c, _ in rows])
print("  KMP, 2n - m + 1:", *[f"{c:,}" for _, _, c in rows])
print("ALL CHECKS PASS")
