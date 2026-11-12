# Data structures -- the check behind the card.  Nothing is imported.  A synthetic festival:
# 60,000 tickets T000001..T060000 at the gate in a hash table; 480 sets, one every 12 minutes,
# booked in a SplitMix64 shuffle (seed 2026) and called by a heap.  Costs are counts, not time.
M64 = (1 << 64) - 1
def mix(z):                                    # SplitMix64's scrambler: every bit stirs every bit
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def fnv1a(code):                               # FNV-1a 64-bit over the bytes (RFC 9923)
    h = 0xCBF29CE484222325
    for b in code.encode(): h = ((h ^ b) * 0x100000001B3) & M64
    return h
def good_hash(code): return mix(fnv1a(code))   # FNV-1a, then mixed
def byte_sum(code): return sum(code.encode())  # the bad hash: add the characters up
def floor_log2(x): return x.bit_length() - 1
def out(label, *values): print(f"{label:<41}" + " ".join(str(v) for v in values))

# ---- road 1 for tickets: build the chains, count what a search would compare --
def gate(n, m, hashf):
    chains = [[] for _ in range(m)]
    for k in range(1, n + 1):
        chains[hashf(f"T{k:06d}") % m].append(f"T{k:06d}")    # new code joins the end
    assert all(f"T{k:06d}" in chains[hashf(f"T{k:06d}") % m] for k in range(1, n + 1))
    hits = sum(len(c) * (len(c) + 1) // 2 for c in chains)    # the p-th in a chain costs p
    misses = sum(len(chains[hashf(f"T{k:06d}") % m]) for k in range(n + 1, 2 * n + 1))
    return hits / n, misses / n, max(len(c) for c in chains)  # a fake costs its whole chain
N_T, M_B = 60000, 80000
hit, miss, longest = gate(N_T, M_B, good_hash)
hit_f, miss_f = 1 + (N_T - 1) / (2 * M_B), N_T / M_B   # road 2: the expected values
bad_hit, bad_miss, bad_longest = gate(N_T, M_B, byte_sum)
full_hit, full_miss, _ = gate(N_T, 8000, good_hash)          # never resized: alpha 7.5
probes, lo, hi = 0, 0, N_T                                   # sorted list, binary search:
while lo < hi: probes += 1; hi = (lo + hi) // 2              # worst case halvings
out("gate: n, m, alpha = n/m", N_T, M_B, f"{N_T / M_B:.2f}")
out("hash, real ticket: run, formula", f"{hit:.4f}", f"{hit_f:.4f}")
out("hash, fake ticket: run, formula", f"{miss:.4f}", f"{miss_f:.4f}")
out("hash, longest chain", longest)
out("FNV-1a test vectors 'a', 'foobar'", f"{fnv1a('a'):016x}", f"{fnv1a('foobar'):016x}")
out("scan a list: real ticket avg, fake", f"{(N_T + 1) / 2:.1f}", N_T)
out("binary search, worst", probes)
out("bad hash (byte sum): real, fake, longest", f"{bad_hit:.1f}", f"{bad_miss:.1f}", bad_longest)
out("m = 8000: real, fake, formula", f"{full_hit:.4f}", f"{full_miss:.4f}", f"{1 + (N_T - 1) / 16000:.4f}")

# ---- the stage: 480 start minutes, booked in a shuffled order ------------------
state = 2026
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    return mix(state)
N_S = 480
booked = [12 * k for k in range(N_S)]
for i in range(N_S - 1, 0, -1):                              # Fisher-Yates shuffle
    j = splitmix() % (i + 1); booked[i], booked[j] = booked[j], booked[i]
heap, cmp_up, cmp_down = [], 0, 0
for t in booked:                                             # insert: sift up
    heap.append(t); i = len(heap) - 1
    while i > 0:
        cmp_up += 1; p = (i - 1) // 2
        if heap[p] <= heap[i]: break
        heap[p], heap[i] = heap[i], heap[p]; i = p
top7, called = heap[:7], []
while heap:                                                  # extract-min: sift down
    called.append(heap[0]); last = heap.pop()
    if not heap: break
    heap[0], i = last, 0
    while 2 * i + 1 < len(heap):
        c = 2 * i + 1
        if c + 1 < len(heap):
            cmp_down += 1
            if heap[c + 1] < heap[c]: c += 1
        cmp_down += 1
        if heap[i] <= heap[c]: break
        heap[i], heap[c] = heap[c], heap[i]; i = c
pool, brute, scan_cmp, sorted_moves = list(booked), [], 0, 0 # road 2: scan for the smallest
for _ in range(N_S):
    b = 0
    for j in range(1, len(pool)): scan_cmp += 1; b = j if pool[j] < pool[b] else b
    brute.append(pool.pop(b))
for k, t in enumerate(booked):                               # sorted array: moves on insert
    sorted_moves += sum(1 for s in booked[:k] if s > t)
bound_up = sum(floor_log2(k) for k in range(1, N_S + 1))
bound_down = 2 * sum(floor_log2(k) for k in range(1, N_S))
scan_total = N_S * (N_S - 1) // 2
out("heap height, floor(log2 480)", floor_log2(N_S))
out("heap inserts: comparisons, bound", cmp_up, bound_up)
out("heap extracts: comparisons, bound", cmp_down, bound_down)
out("heap, whole weekend", cmp_up + cmp_down)
out("unsorted list: comparisons, n(n-1)/2", scan_cmp, scan_total)
out("sorted array: moves, n(n-1)/4", sorted_moves, N_S * (N_S - 1) // 4)
out("first five sets called, minutes", f"{called[:5]}")
# ---- search trees: plain against AVL (heights differ by at most one) ----------
def build(keys, balance):
    K, L, R, H = [], [], [], []
    def ht(t): return H[t] if t >= 0 else -1
    def fix(t): H[t] = 1 + max(ht(L[t]), ht(R[t]))
    def rot(t, left):                                        # left: lift the right child
        s = R[t] if left else L[t]
        if left: R[t], L[s] = L[s], t
        else: L[t], R[s] = R[s], t
        fix(t); fix(s); return s
    def ins(t, key):
        if t < 0: K.append(key); L.append(-1); R.append(-1); H.append(0); return len(K) - 1
        if key < K[t]: L[t] = ins(L[t], key)
        else: R[t] = ins(R[t], key)
        fix(t); b = ht(L[t]) - ht(R[t])
        if balance and b > 1:
            if key > K[L[t]]: L[t] = rot(L[t], True)
            return rot(t, False)
        if balance and b < -1:
            if key < K[R[t]]: R[t] = rot(R[t], False)
            return rot(t, True)
        return t
    def cost(t, d): return 0 if t < 0 else d + 1 + cost(L[t], d + 1) + cost(R[t], d + 1)
    def tall(t): return -1 if t < 0 else 1 + max(tall(L[t]), tall(R[t]))   # recounted, not stored
    root = -1
    for key in keys: root = ins(root, key)
    return H[root], cost(root, 0) / len(keys), all(abs(tall(L[t]) - tall(R[t])) <= 1 for t in range(len(K)))
in_order = [12 * k for k in range(N_S)]
plain_sorted, plain_shuf, avl_sorted = build(in_order, False), build(booked, False), build(in_order, True)
avl_shuf = build(booked, True)
mins, fib = [1, 2], [0, 1]                                   # fewest keys an AVL tree of height h holds
while len(mins) < 30: mins.append(mins[-1] + mins[-2] + 1)
while len(fib) < 34: fib.append(fib[-1] + fib[-2])
avl_bound, avl_bound_t = (max(h for h in range(30) if mins[h] <= n) for n in (N_S, N_T))
out("plain tree, time order: height, avg", plain_sorted[0], f"{plain_sorted[1]:.2f}")
out("plain tree, booking order: height, avg", plain_shuf[0], f"{plain_shuf[1]:.2f}")
out("AVL tree, time order: height, avg", avl_sorted[0], f"{avl_sorted[1]:.2f}")
out("AVL tree, booking order: height, avg", avl_shuf[0], f"{avl_shuf[1]:.2f}")
out("fewest keys, AVL height 0..11", f"{mins[:12]}")
out("AVL height cap, 480 and 60000 keys", avl_bound, avl_bound_t)
print("figure," + ";".join(f"{v}@{360 * (2 * (i + 1 - 2 ** floor_log2(i + 1)) + 1) / 2 ** (floor_log2(i + 1) + 1):.0f},"
                          f"{30 + 55 * floor_log2(i + 1)}" for i, v in enumerate(top7)))
assert abs(hit - hit_f) < 0.015 and abs(miss - miss_f) < 0.015      # run meets expectation
assert called == brute == in_order                                 # heap order = brute force
assert cmp_up <= bound_up and cmp_down <= bound_down and probes == floor_log2(N_T) + 1
assert scan_cmp == scan_total and plain_sorted[0] == N_S - 1 and avl_sorted[0] <= avl_bound
assert all(mins[h] == fib[h + 3] - 1 for h in range(30)) and bad_hit > 100 * hit
assert fnv1a("a") == 0xAF63DC4C8601EC8C and fnv1a("foobar") == 0x85944171F73967E8  # the standard's vectors
assert avl_sorted[2] and avl_shuf[2] and avl_shuf[0] <= avl_bound   # every item balanced, both orders
print("ALL CHECKS PASS")
