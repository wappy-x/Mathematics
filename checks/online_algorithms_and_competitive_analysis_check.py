# Online algorithms and competitive analysis -- the check behind the card.
# Standard library only, no imports.  Costs count days of rent and page faults
# (a requested track that is not in the phone's cache), never time.
B, RENT, K = 10, 25, 4              # skis: 25 pounds a day, or buy for 250; 4 tracks cached
L = "ABCDEF"
def ski(t, d):                      # buy on the morning of day t (0 = never), ski d days
    return d if t == 0 or d < t else (t - 1) + B
def worst(t, dmax=400):             # brute force: every season length from 1 to dmax days
    return max(ski(t, d) / min(d, B) for d in range(1, dmax + 1))
print(f"ski rental: rent {RENT} a day, buy {B * RENT} = {B} days of rent")
w = [worst(t) for t in range(1, 41)]
for t in range(1, 41):              # formula: the adversary stops skiing on day t
    assert abs(w[t - 1] - (t - 1 + B) / min(t, B)) < 1e-12
best = min(range(1, 41), key=lambda t: w[t - 1])
assert best == B and abs(w[best - 1] - (2 - 1 / B)) < 1e-12
print("chart, worst ratio of 'buy on day t', t = 1..20:", " ".join(f"{x:.3f}" for x in w[:20]))
print(f"best day {best}: worst ratio {w[best-1]:.2f} = 2 - 1/{B}; every other day is worse")
print(f"skis exactly {B} days: {(B-1)*RENT} + {B*RENT} = {(2*B-1)*RENT} pounds against hindsight {B*RENT}")
for d in (3, 25): print(f"  season of {d} days: rule pays {ski(B, d)*RENT}, hindsight {min(d, B)*RENT}")
print(f"mistake, buy on day 1, ski 1 day: {B*RENT} against {RENT}, ratio {w[0]:.2f}")
print(f"mistake, never buy: 100 days {100*RENT} against {B*RENT}, ratio {ski(0,100)/B:.0f};"
      f" 1000 days, ratio {ski(0,1000)/B:.0f}: no bound")

def nxt(seq, i, p):                 # next time after i that track p is requested
    return next((j for j in range(i + 1, len(seq)) if seq[j] == p), len(seq))
def bits(m): return [p for p in range(8) if m >> p & 1]
def rng(seed):                      # SplitMix64, written out
    s = seed
    def f():
        nonlocal s
        s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1); z = s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
        return z ^ (z >> 31)
    return f
def run(seq, rule, coin=None, adv=False, k=K):  # adv: build the sequence against the rule
    cache = marked = faults = 0; last = [-1] * 8; born = [-1] * 8; seq = list(seq); log = []
    for i in range(len(seq)):
        if adv: seq[i] = next(p for p in range(k + 1) if not cache >> p & 1)
        p = seq[i]
        log.append(".")
        if not cache >> p & 1:
            faults += 1; log[-1] = "F"
            if len(bits(cache)) == k:
                c = bits(cache)
                if rule == "LRU": v = min(c, key=lambda q: last[q])
                if rule == "FIFO": v = min(c, key=lambda q: born[q])
                if rule == "MRU": v = max(c, key=lambda q: last[q])
                if rule == "OPT": v = max(c, key=lambda q: nxt(seq, i, q))
                if rule == "MARK":
                    if marked == cache: marked = 0           # all marked: a new phase
                    u = bits(cache & ~marked); v = u[coin() % len(u)]
                cache &= ~(1 << v); log[-1] = L[v].lower()
            cache |= 1 << p; born[p] = i
        last[p] = i; marked |= 1 << p
    return faults, seq, "".join(log)
def brute_opt(seq, k=K):            # every eviction choice, merged by cache contents
    best = {0: 0}
    for p in seq:
        new = {}
        for m, f in best.items():
            if m >> p & 1: outs = [(m, f)]
            elif len(bits(m)) < k: outs = [(m | 1 << p, f + 1)]
            else: outs = [((m & ~(1 << v)) | 1 << p, f + 1) for v in bits(m)]
            for m2, f2 in outs:
                if m2 not in new or f2 < new[m2]: new[m2] = f2
        best = new
    return min(best.values())
def mark_exact(seq):                # expected marking faults: every coin, with its chance
    dist, ef = {(0, 0): 1.0}, 0.0
    for p in seq:
        new = {}
        for (m, mk), pr in dist.items():
            if m >> p & 1: outs = [(m, mk, 1.0)]
            else:
                ef += pr
                if len(bits(m)) < K: outs = [(m, mk, 1.0)]
                else:
                    if mk == m: mk = 0
                    u = bits(m & ~mk); outs = [(m & ~(1 << v), mk, 1 / len(u)) for v in u]
            for m2, mk2, q in outs:
                key = (m2 | 1 << p, mk2 | 1 << p); new[key] = new.get(key, 0.0) + pr * q
        dist = new
    return ef
def phases(seq):                    # split into phases of K distinct tracks; fresh counts
    ph = [[]]
    for p in seq:
        if p not in ph[-1] and len(ph[-1]) == K: ph.append([])
        if p not in ph[-1]: ph[-1].append(p)
    return len(ph), [len([p for p in ph[i] if i == 0 or p not in ph[i-1]]) for i in range(len(ph))]
H = lambda n: sum(1 / j for j in range(1, n + 1))

print(f"paging: cache of k = {K} tracks; H_4 = {H(4):.4f}; 2 H_4 = {2*H(4):.4f}")
cyc = [i % 5 for i in range(20)]
(f_lru, _, t_lru), (f_opt, _, t_opt) = run(cyc, "LRU"), run(cyc, "OPT")
assert f_opt == brute_opt(cyc) == 8 and f_lru == 20
print("cycle ABCDE repeated, 20 requests:", "".join(L[p] for p in cyc))
print(f"  LRU {t_lru} {f_lru} faults (F: fill an empty slot, letter: track evicted, dot: hit)")
print(f"  OPT {t_opt} {f_opt} faults (evict the track wanted latest); brute force agrees")
for n in (20, 200, 2000):            # any deterministic rule: ask for the track it lacks
    row, cap = [], K + -(-(n - K) // K)
    for rule in ("LRU", "FIFO"):
        fa, sq, _ = run([0] * n, rule, adv=True); fo = run(sq, "OPT")[0]
        assert fo <= cap and fo == brute_opt(sq)
        row.append(f"{rule} {fa} against OPT {fo}, ratio {fa / fo:.3f}")
    print(f"adversary, n = {n}: " + "; ".join(row) + f"; OPT cap k + (n - k)/k = {cap}")
fa, sq, _ = run([0] * 2000, "MRU", adv=True); fo = run(sq, "OPT")[0]; assert fo == brute_opt(sq)
print(f"mistake, evict the most recent (MRU): adversary gets {fa} faults against OPT {fo}:",
      "".join(L[p] for p in sq[:12]) + "...")
seq = [i % 5 for i in range(2000)]
fl, fo = run(seq, "LRU")[0], run(seq, "OPT")[0]
np_, cl = phases(seq)
assert fl <= K * np_ and fo >= np_ - 1 and fo == brute_opt(seq)
print(f"phases on the 2000-request cycle: {np_}; LRU {fl} <= k x phases = {K*np_}; OPT {fo} >= phases - 1 = {np_-1}")
em = mark_exact(seq)
sims = [run(seq, "MARK", coin=rng(s))[0] for s in range(200)]
mean = sum(sims) / 200; sd = (sum((x - mean) ** 2 for x in sims) / 199) ** 0.5
bound = sum(c * (H(K) - H(c) + 1) for c in cl)
assert abs(mean - em) < 4 * sd / 200 ** 0.5 and em <= bound + 1e-9 and sum(cl) <= 2 * fo
assert abs((em - K) / (np_ - 1) - H(K)) < 1e-9    # H_4 per phase after the first, as the fold says
print(f"marking, exact over every coin: {em:.2f} expected faults; 200 seeded runs: mean {mean:.2f}, sd {sd:.2f}")
print(f"  fresh tracks per phase sum to {sum(cl)} <= 2 OPT = {2*fo}; bound sum f(H_k - H_f + 1) = {bound:.2f}"
      f" <= 2 H_4 OPT = {2*H(K)*fo:.2f}")
print(f"  per phase after the first: marking {(em - K) / (np_ - 1):.4f} = H_4, LRU {(fl - K) // (np_ - 1)};"
      f" ratio to OPT: marking {em/fo:.3f}, LRU {fl/fo:.3f}")
g, lis = rng(2026), []
for _ in range(40):                 # synthetic listener: A 6, B 5, C 3, D 3, E 2, F 1 in 20
    r = g() % 20
    lis.append(0 if r < 6 else 1 if r < 11 else 2 if r < 14 else 3 if r < 17 else 4 if r < 19 else 5)
res = {r: run(lis, r)[0] for r in ("LRU", "FIFO", "OPT")}
assert res["OPT"] == brute_opt(lis)
# LRU again, by another road: a request faults when K other tracks came since its last use
assert res["LRU"] == sum(p not in lis[:i] or len(set(lis[i - lis[i - 1::-1].index(p):i])) >= K for i, p in enumerate(lis))
print("listener, 40 requests, seed 2026:", "".join(L[p] for p in lis))
print("  " + ", ".join(f"{r} {f}" for r, f in res.items()) + f", marking expected {mark_exact(lis):.2f}")
fa, sq, _ = run([0] * 2000, "MARK", coin=rng(7), adv=True, k=5); fo = run(sq, "OPT", k=5)[0]
assert fo == brute_opt(sq, 5) <= 5 + -(-(2000 - 5) // 5) and fa > 2 * H(5) * fo
print(f"mistake, adversary sees the coins (k = 5): marking {fa} of 2000, OPT {fo}, ratio {fa/fo:.3f} > 2 H_5 = {2*H(5):.3f}")
for k in (4, 5, 100, 1000): print(f"guarantee at k = {k}: LRU {k}, marking 2 H_k = {2*H(k):.2f}")
print("ALL CHECKS PASS")
