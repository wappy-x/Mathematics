# Lebesgue measure -- the check behind the card.  Standard library only.
# The cycle path is the open stretch (0, 1) km with a pothole at every fraction
# p/q strictly between 0 and 1.  Its length is squeezed between an open set
# outside and a closed set inside.  Exact fractions throughout; the darts come
# from SplitMix64, written out below, so the Rust check prints the same bytes.
from fractions import Fraction as Fr

def dec(x, d):                           # exact decimal, rounded half up, for x >= 0
    n = (x.numerator * 10 ** d * 2 + x.denominator) // (2 * x.denominator)
    s = str(n).rjust(d + 1, "0")
    return s[:-d] + "." + s[-d:] if d else s

def potholes(qmax):                      # fractions p/q in (0, 1), lowest terms, by q then p
    return [Fr(p, q) for q in range(2, qmax + 1) for p in range(1, q) if Fr(p, q).denominator == q]

def cuts(eps, n, halving=True):          # open gap k is (eps/2) * 2^-k wide, or eps/2 flat
    ws = [eps / 2 / 2 ** k if halving else eps / 2 for k in range(1, n + 1)]
    return [(q - w / 2, q + w / 2) for q, w in zip(potholes(8)[:n], ws)]

def inner_by_merging(eps, n, halving=True):   # road 1: sort the gaps, merge, subtract
    a, b = eps / 4, 1 - eps / 4
    covered, end = Fr(0), a
    for lo, hi in sorted(cuts(eps, n, halving)):
        lo, hi = max(lo, end), min(hi, b)
        if hi > lo:
            covered += hi - lo
            end = hi
    return (b - a) - covered

def inner_by_formula(eps, n, halving=True):   # road 2: gaps never overlap, so add their widths
    return 1 - eps / 2 - (eps / 2 * (1 - Fr(1, 2 ** n)) if halving else n * eps / 2)

M64 = 2 ** 64 - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def inner_by_darts(eps, n, draws, seed):      # road 3: dart r / 2^64 in [0, 1); count hits on K_n
    fl = lambda x: x.numerator * 2 ** 64 // x.denominator
    ce = lambda x: -(-x.numerator * 2 ** 64 // x.denominator)
    lo_a, hi_b = ce(eps / 4), fl(1 - eps / 4)
    gaps = [(fl(lo), ce(hi)) for lo, hi in cuts(eps, n)]
    hits, s = 0, seed
    for _ in range(draws):
        s, r = splitmix(s)
        if lo_a <= r <= hi_b and not any(t < r < u for t, u in gaps):
            hits += 1
    return hits

EPS, N, DRAWS, SEED = Fr(1, 1000), 21, 200000, 20260929
Q = potholes(8)
print("Lebesgue measure: the cycle path (0, 1) km minus a pothole at every fraction")
print("potholes, first 8 in order:", " ".join(f"{q.numerator}/{q.denominator}" for q in Q[:8]))
print("potholes with denominator up to 8:", len(Q))
print("gap around pothole k, k = 1..4 (cm):", " ".join(dec(EPS / 2 / 2 ** k * 100000, 3) for k in range(1, 5)))
print(f"outer, G = (-{dec(EPS / 2, 4)}, {dec(1 + EPS / 2, 4)}) km: length {dec(1 + EPS, 3)} km; G minus path {dec(EPS, 3)} km")
print(f"inner, ends trimmed {dec(EPS / 4 * 1000, 2)} m each: [{dec(EPS / 4, 5)}, {dec(1 - EPS / 4, 5)}] = {dec(1 - EPS / 2, 4)} km")
print(f"inner, all gaps together: at most {dec(EPS / 2, 4)} km, so K has length at least {dec(1 - EPS, 3)} km")
print(f"squeeze, eps = {dec(EPS, 3)}: {dec(1 - EPS, 3)} km <= length of path <= {dec(1 + EPS, 3)} km; shrinking eps leaves {dec(Fr(1), 0)} km")
for n in (1, 2, 3, 5, 10, 21):
    m, f = inner_by_merging(EPS, n), inner_by_formula(EPS, n)
    assert m == f, (n, m, f)             # sorted-merge length equals the geometric sum: no gap overlaps
    assert m >= 1 - EPS                  # every stage stays above the proved floor
    print(f"stage n={n}: merging {dec(m, 13)} km, formula {dec(f, 13)} km")
hits = inner_by_darts(EPS, N, DRAWS, SEED)
exact = inner_by_merging(EPS, N)
se = (float(exact) * (1 - float(exact)) / DRAWS) ** 0.5
assert abs(hits / DRAWS - float(exact)) < 4 * se, hits
print(f"darts, {DRAWS} throws, seed {SEED}: {hits} hits, estimate {dec(Fr(hits, DRAWS), 5)} km, standard error {se:.6f}")
cut_mm = [dec((1 - inner_by_merging(EPS, n)) * 1000000, 2) for n in range(11)]
print("chart, mm cut away after n = 0..10 potholes:", " ".join(cut_mm))
px = lambda x: 20 + 320 * x               # the picture: 0 km at x = 20 px, 1 km at x = 340 px
print(f"figure, px: G {dec(px(-EPS / 2), 2)} to {dec(px(1 + EPS / 2), 2)}, K {dec(px(EPS / 4), 2)} to {dec(px(1 - EPS / 4), 2)}, potholes",
      " ".join(dec(px(q), 1) for q in Q))
q = 1
while not 10000 * ((3 * q) // 10 + 1) < 3001 * q:
    q += 1
p = (3 * q) // 10 + 1
inside = lambda a, b: 3 * b < 10 * a and 10000 * a < 3001 * b
assert inside(p, q) and not any(inside(a, b) for b in range(1, q) for a in range(b + 1))
print(f"breaks, intervals only: pothole {p}/{q} sits inside (0.3, 0.3001), so no interval fits and inside length is 0 km")
fm, ff = inner_by_merging(EPS, N, False), inner_by_formula(EPS, N, False)
assert fm == ff
print(f"breaks, flat {dec(EPS / 2 * 1000, 1)} m gaps: {N} potholes cut {dec(N * EPS / 2 * 1000, 1)} m, K is {dec(fm, 3)} km; gap every fraction and K is empty")
mu, nu = [1, 1, 1, 1], [2, 0, 0, 2]      # in quarters: mu 0.25 on each point, nu 0.5 on 1 and 4
size = lambda m, s: Fr(sum(m[i] for i in range(4) if s >> i & 1), 4)
C = [0b0011, 0b0101]                     # {1, 2} and {1, 3}
sig = {0, 15} | set(C)
while True:
    grow = {15 ^ s for s in sig} | {s | t for s in sig for t in sig}
    if grow <= sig:
        break
    sig |= grow
bad = [s for s in sig if size(mu, s) != size(nu, s)]
assert all(size(mu, c) == size(nu, c) for c in C)   # they agree on the class C
assert len(sig) == 16 and len(bad) == 16 - sum([1, 2, 1][a] ** 2 for a in range(3))
print(f"breaks, four points: sigma(C) has {len(sig)} sets; on {{1,2}} and {{1,3}} both give "
      f"{dec(size(mu, 3), 1)}; on {{1}} {dec(size(mu, 1), 2)} vs {dec(size(nu, 1), 1)}; disagree on {len(bad)}")
F = {0: 0, 3: 0, 12: 2, 15: 2}           # blocks {1,2} of size 0 and {3,4} of size 2
nulls = [s for s in F if F[s] == 0]
done, reps = {}, 0
for e in range(16):
    for b, m in F.items():
        if any((e ^ b) & (15 ^ z) == 0 for z in nulls):
            done.setdefault(e, set()).add(m)
            reps += 1
assert sorted(done) == [e for e in range(16) if e & 12 in (0, 12)] and reps == 16
assert all(len(v) == 1 for v in done.values())
print(f"completion, four points: {len(F)} old sets, {len(done)} completed, {reps} representatives, "
      f"{{3}} included: {4 in done}")
t = Fr(1, 100)
print(f"try, eps = {dec(t, 2)}: stage n=21 closed set {dec(inner_by_merging(t, N), 13)} km, floor {dec(1 - t, 2)} km")
print("All checks passed.")
