# Parameterised complexity -- the check behind the card.  Standard library only.
# A festival street plan: 60 junctions, 84 streets, at most 10 officers.  An officer at a
# junction watches every street that meets it.  Roads to the answer: (1) the bounded search
# tree; (2) the kernel, then the same tree on what is left; (3) certificates: a cover checked
# street by street, and 10 streets sharing no junction, which force at least 10 officers;
# (4) brute force over every set of junctions, on 300 small random plans.
from math import comb, log10

def festival(n):              # hubs 0-9, partners 10-19, junction 20 meets every hub, 21.. side streets
    st = []
    for j in range(21, n):
        if j < 33: st.append((0, j))                         # 12 side streets off square 0
        elif j < 45: st.append((1, j))                       # 12 off square 1
        else: st += [(2 + j % 8, j), (2 + (j + 3) % 8, j)]   # the rest join two smaller hubs
    st += [(20, h) for h in range(10)] + [(h, (h + 1) % 10) for h in range(10)]
    return st + [(h, 10 + h) for h in range(10)]

def tree(st, k, on, cnt):     # ROAD 1: an unwatched street needs an officer at one of its two ends
    cnt[0] += 1                                              # nodes of the search tree
    for u, v in st:
        cnt[1] += 1                                          # steps: streets looked at
        if not on[u] and not on[v]: break
    else: return True                                        # every street is watched
    if k == 0: return False                                  # a street unwatched and nobody left
    for w in (u, v):
        on[w] = True
        if tree(st, k - 1, on, cnt): return True
        on[w] = False
    return False

def kernel(n, st, k, big=lambda d, k: d > k):   # ROAD 2, part one: shrink the plan first
    forced, steps = [], 0
    while True:
        deg = [0] * n
        for u, v in st: deg[u] += 1; deg[v] += 1
        steps += len(st)
        b = [w for w in range(n) if deg[w] and big(deg[w], k)]
        if not b or len(b) > k: break                        # nothing forced, or too many forced
        forced += b; k -= len(b)
        st = [(u, v) for u, v in st if u not in b and v not in b]
    return forced, st, k, steps, len(b) <= k and len(st) <= k * k

def solve(n, st, k, big=lambda d, k: d > k):    # ROAD 2: kernel, then the tree on what is left
    forced, rest, k2, steps, alive = kernel(n, st, k, big)
    on, cnt = [w in forced for w in range(n)], [0, 0]
    ok = alive and tree(rest, k2, on, cnt)
    return ok, [w for w in range(n) if on[w]], forced, len(rest), k2, steps + cnt[1], cnt[0]

def matching(st):             # ROAD 3: streets sharing no junction; each needs an officer of its own
    used, m = set(), []
    for u, v in st:
        if u not in used and v not in used: m.append((u, v)); used |= {u, v}
    return m

n, K = 60, 10
st = festival(n)
deg = [sum(w in s for s in st) for w in range(n)]
on, c10 = [False] * n, [0, 0]
yes10 = tree(st, K, on, c10)
cover = [w for w in range(n) if on[w]]
watched = all(u in cover or v in cover for u, v in st)       # separate verifier
c9 = [0, 0]; yes9 = tree(st, K - 1, [False] * n, c9)
ok, kcov, forced, left, k2, ksteps, knodes = solve(n, st, K)
ok9, _, forced9, left9, k29, ksteps9, _ = solve(n, st, K - 1)
mt = matching(st)
print(f"plan: {n} junctions, {len(st)} streets, budget k = {K} officers")
print(f"streets meeting junctions 0, 1, 20: {deg[0]}, {deg[1]}, {deg[20]}; largest elsewhere {max(deg[2:20])}")
print(f"road 1, tree, k = 10: {'yes' if yes10 else 'no'}, officers at {cover}; {c10[0]} nodes, {c10[1]} steps; bound 2^11 - 1 = {2**11 - 1}")
print(f"road 1, tree, k = 9:  {'yes' if yes9 else 'no'}; {c9[0]} nodes, {c9[1]} steps; bound 2^10 - 1 = {2**10 - 1}")
print(f"road 2, kernel, k = 10: forced {forced}; {len(st) - left} streets removed, {left} left for k = {k2}, limit {k2 * k2}")
print(f"road 2, kernel then tree, k = 10: {'yes' if ok else 'no'}, {kcov}; {knodes} nodes, {ksteps} steps;"
      f" ceiling (k+1)m + 2^(k+1) k^2 = {(K + 1) * len(st) + 2 ** (K + 1) * K * K}")
print(f"road 2, kernel, k = 9: forced {forced9}; {left9} streets left for k = {k29}: {'yes' if ok9 else 'no'}; {ksteps9} steps")
print(f"road 3, verifier: every street watched by {len(cover)} officers: {'yes' if watched else 'no'}")
print(f"road 3, {len(mt)} streets sharing no junction: {mt}")
print(f"other parameter: largest set of junctions with no street between any two = {n} - {len(cover)} = {n - len(cover)}")
sets = sum(comb(n, i) for i in range(K + 1))
print(f"brute force: sets of at most 10 junctions out of 60 = {sets}, times {len(st)} streets each")

M64 = (1 << 64) - 1
def splitmix(s):             # SplitMix64, written out, so Python and Rust draw the same plans
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
seed, agree, hist, worst = 2026, 0, [0] * 11, 0
for trial in range(300):     # ROAD 4: 300 random plans on 10 junctions, each pair a street 30% of the time
    sm = []
    for u in range(10):
        for v in range(u + 1, 10):
            seed, z = splitmix(seed)
            if z % 100 < 30: sm.append((u, v))
    brute = min(bin(m).count("1") for m in range(1024) if all(m >> u & 1 or m >> v & 1 for u, v in sm))
    t = 0
    while True:
        cnt = [0, 0]
        if tree(sm, t, [False] * 10, cnt): break
        worst = max(worst, cnt[0] / (2 ** (t + 1) - 1)); t += 1
    kk = next(t for t in range(11) if solve(10, sm, t)[0])
    agree += brute == t == kk; hist[brute] += 1
print(f"road 4, 300 random plans: brute force, tree and kernel agree on {agree}; covers of size 0-10: {hist}")
print(f"road 4, largest tree as a share of its bound 2^(k+1) - 1: {worst:.3f}")

print("growth at k = 10: before saying yes, every road must see that every street is watched")
print("     n     m  tree nodes  tree steps  kernel+tree steps  log10 brute-force sets")
rows = []
for size in (60, 120, 240, 480, 960):
    s2 = festival(size); c = [0, 0]
    tree(s2, K, [False] * size, c)
    r = solve(size, s2, K)
    lb = log10(sum(comb(size, i) for i in range(K + 1)))
    rows.append((size, len(s2), c[0], c[1], r[5], lb))
    print(f"{size:>6}{len(s2):>6}{c[0]:>12}{c[1]:>12}{r[5]:>19}{lb:>24.2f}")
print("chart, log10 tree steps: " + " ".join(f"{log10(r[3]):.2f}" for r in rows))
print("chart, log10 kernel+tree steps: " + " ".join(f"{log10(r[4]):.2f}" for r in rows))
print("chart, log10 brute-force sets: " + " ".join(f"{r[5]:.2f}" for r in rows))

wrong = solve(n, st, K, big=lambda d, k: d >= k)             # mistake: force a junction meeting exactly k streets
print(f"mistake, force at >= k streets: forced {wrong[2]}, answer {'yes' if wrong[0] else 'no'}")
print(f"mistake, both ends of {len(mt)} separate streets: {2 * len(mt)} officers")
print(f"mistake, branch on every junction in or out: 2^60 = {2 ** 60} leaves")
ring = [(i, (i + 1) % 200) for i in range(200)]               # hypothesis fails: k is not small
rm, evens = matching(ring), set(range(0, 200, 2))
fine = all(u in evens or v in evens for u, v in ring)
print(f"k not small: a ring of 200 needs {len(rm)}; tree bound 2^101 - 1 = {2 ** 101 - 1} nodes;"
      f" two-sided, so the matching settles it; the 100 even junctions watch all: {'yes' if fine else 'no'}")

assert yes10 and watched and len(cover) == K                 # tree's cover passes a separate check
assert len(mt) == K and len({w for s in mt for w in s}) == 2 * K and not yes9   # 10 separate streets: 9 cannot do
assert ok and not ok9 and sorted(kcov) == cover              # kernel road agrees with the tree road
assert agree == 300 and worst <= 1.0 and c9[0] <= 2 ** K - 1 # brute force agrees; trees stay under 2^(k+1) - 1
assert all(r[4] <= (K + 1) * r[1] + 2 ** (K + 1) * K * K for r in rows)   # within (k+1)m + 2^(k+1) k^2
assert not wrong[0] and len(rm) == 100 and fine              # the wrong rule says no; the ring needs 100
print("ALL CHECKS PASS")
