# Fine-grained complexity and SETH -- the check behind the card.  Standard
# library only.  Edit distance is computed two ways (the quadratic table and a
# diagonal search that never fills the table), and the first link of the SETH
# chain, CNF-SAT to orthogonal vectors by split and list, is built and checked
# against brute force over every assignment.  The second link's gadgets, from
# orthogonal vectors to edit distance, are built and measured on the same vectors.
import math

def ed_table(x, y):                      # road one: the quadratic table
    t = [[i + j if i == 0 or j == 0 else 0 for j in range(len(y) + 1)] for i in range(len(x) + 1)]
    for i in range(1, len(x) + 1):
        for j in range(1, len(y) + 1):
            t[i][j] = min(t[i - 1][j] + 1, t[i][j - 1] + 1, t[i - 1][j - 1] + (x[i - 1] != y[j - 1]))
    return t

def ed_diag(x, y):                       # road two: furthest reach per diagonal, cost 0, 1, 2, ...
    n, m, cells, d = len(x), len(y), 0, 0
    def slide(i, k):
        nonlocal cells
        cells += 1
        while i < n and i + k < m and x[i] == y[i + k]:
            i, cells = i + 1, cells + 1
        return i
    reach = {0: slide(0, 0)}
    while reach.get(m - n, -1) < n:
        d, new = d + 1, {}
        for k in range(-min(d, n), min(d, m) + 1):
            best = max(reach.get(k, -9) + 1, reach.get(k + 1, -9) + 1, reach.get(k - 1, -9))
            new[k] = slide(max(min(best, n, m - k), -k, 0), k)
        reach = new
    return d, cells

def splitmix(state):                     # SplitMix64, seed stated below
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

x, y = "GATTACA", "GCATGCA"
t = ed_table(x, y)
print(f"hand pair {x} against {y}, table rows (row i = first i letters of {x}):")
for row in t:
    print("  " + " ".join(str(v) for v in row))
dd, dcells = ed_diag(x, y)
print(f"edit distance: table {t[-1][-1]}, diagonal road {dd}; cells: table {len(x) * len(y)}, diagonal {dcells}")
words = [""] + [a + b + c for a in "ACGT" for b in "ACGT" for c in "ACGT"]
words += sorted({w[:k] for w in words[1:] for k in range(1, 3)})
agree = all(ed_table(u, v)[-1][-1] == ed_diag(u, v)[0] for u in words for v in words)
print(f"every pair of DNA strings up to 3 letters ({len(words)} strings, {len(words) ** 2} pairs): roads agree {'yes' if agree else 'no'}")
for name, n in [("virus genome", 30000), ("bacterial genome", 4600000), ("human genome", 3100000000), ("visitor log", 10000000)]:
    print(f"table cells for two {name}s, n = {n}: n^2 = {n * n}")

s, a = 2026, []                          # two 1,000-base strands from seed 2026
for _ in range(2000):
    s, r = splitmix(s)
    a.append("ACGT"[r % 4])
u, v = "".join(a[:1000]), list(a[:1000])
for _ in range(3):                       # three point mutations
    s, r = splitmix(s)
    p = r % 1000
    v[p] = "ACGT"[("ACGT".index(v[p]) + 1 + (r >> 8) % 3) % 4]
v, w = "".join(v), "".join(a[1000:])
near_t, (near_d, near_c) = ed_table(u, v)[-1][-1], ed_diag(u, v)
far_t, (far_d, far_c) = ed_table(u, w)[-1][-1], ed_diag(u, w)
print(f"3 mutations in 1000 bases: distance {near_t} (table) {near_d} (diagonal); cells 1000000 against {near_c}")
print(f"two unrelated 1000-base strands: distance {far_t} (table) {far_d} (diagonal); cells 1000000 against {far_c}")

F = [(1, 2, 4), (-1, 3, 5), (1, -2, 6), (1, 2, -4), (1, -2, -6), (-1, 2, -5), (-1, -2, -5), (-1, -2, 5)]
N, H = 6, 3
def true_lit(l, bits, first):            # is literal l true under this half's bits?
    v = abs(l) - first
    return 0 <= v < len(bits) and (bits[v] == 1) == (l > 0)
def vector(bits, first, flip=False):     # coordinate j is 1 when clause j is still open
    return [int(any(true_lit(l, bits, first) for l in c) == flip) for c in F]
halves = [[(b >> 2 & 1, b >> 1 & 1, b & 1) for b in range(8)]] * 2
A = [vector(h, 1) for h in halves[0]]
B = [vector(h, 4) for h in halves[1]]
def show(bits, vec): return "".join(map(str, bits)) + ":" + "".join(map(str, vec))
print("formula: " + " & ".join("(" + " | ".join(("x" if l > 0 else "~x") + str(abs(l)) for l in c) + ")" for c in F))
print("A vectors (x1 x2 x3): " + " ".join(show(h, A[i]) for i, h in enumerate(halves[0])))
print("B vectors (x4 x5 x6): " + " ".join(show(h, B[i]) for i, h in enumerate(halves[1])))
brute = [a + b for a in halves[0] for b in halves[1]
         if all(any(true_lit(l, a + b, 1) for l in c) for c in F)]
ortho = [halves[0][i] + halves[1][j] for i in range(8) for j in range(8)
         if sum(p * q for p, q in zip(A[i], B[j])) == 0]
print(f"brute force over {2 ** N} assignments: {len(brute)} satisfy; orthogonal pairs among {len(A) * len(B)}: {len(ortho)}")
print("satisfying assignments: " + " ".join("".join(map(str, z)) for z in brute))
Af = [vector(h, 1, True) for h in halves[0]]
Bf = [vector(h, 4, True) for h in halves[1]]
flipped = sum(sum(p * q for p, q in zip(Af[i], Bf[j])) == 0 for i in range(8) for j in range(8))
print(f"mistake 1, coordinate 1 when the clause is satisfied: {flipped} orthogonal pairs, not {len(brute)}")

G1, G2 = ["201112", "200012"], ["200112", "211112"]  # Backurs-Indyk coordinate gadgets for a 0 and a 1, runs of 2s cut to 1
cg = [ed_table(G1[p], G2[q])[-1][-1] for p in (0, 1) for q in (0, 1)]
def glue(g, vec): return "".join(g[c] for c in vec)
def vg1(a): return "4" * 20 + glue(G1, [0] + a) + "3" * 20 + glue(G1, [1] + [0] * 8) + "4" * 20
def vg2(b): return "3" * 20 + glue(G2, [1] + b) + "3" * 20
pairs = [(i, j, sum(p * q for p, q in zip(A[i], B[j]))) for i in range(8) for j in range(8)]
joined = {(i, j): ed_table(glue(G1, A[i]), glue(G2, B[j]))[-1][-1] for i, j, _ in pairs}
full = {(i, j): ed_table(vg1(A[i]), vg2(B[j]))[-1][-1] for i, j, _ in pairs}
e_s, l9 = 2 * 20 + 9 * len(G1[0]) + 9, 9 * len(G1[0])  # the paper's 2 l1 + l + d, with d = 9 places
print(f"coordinate gadgets: A 0 {G1[0]}, A 1 {G1[1]}, B 0 {G2[0]}, B 1 {G2[1]}; distances 0-0 0-1 1-0 1-1: {' '.join(map(str, cg))}")
def bits(vec): return "".join(map(str, vec))
print(f"joined gadgets: {bits(A[5])} against {bits(B[0])} (dot 0) {joined[5, 0]}, against {bits(B[2])} (dot 1) {joined[5, 2]};"
      f" all 64 pairs 8 + 2 x shared 1s, from {min(joined.values())} to {max(joined.values())}")
o0, o1 = [" ".join(map(str, sorted({full[i, j] for i, j, d in pairs if (d > 0) == k}))) for k in (False, True)]
print(f"vector gadgets, runs of 20, second set for {bits([1] + [0] * 8)}, {l9} letters per 9 places: distance {o0} on all {sum(d == 0 for _, _, d in pairs)} orthogonal pairs,"
      f" {o1} on all {sum(d > 0 for _, _, d in pairs)} others; formula 2 x 20 + {l9} + 9 = {e_s}")

eps, NN = 0.1, 60
print(f"N = {NN}: brute force 2^{NN} = {2 ** NN}; split gives n = 2^{NN // 2} = {2 ** (NN // 2)} vectors per side")
print(f"edit distance in n^{2 - eps:.1f} would give SAT in 2^{(1 - eps / 2) * NN:.1f} = {2 ** 57} times a polynomial, {2 ** NN // 2 ** 57} times fewer")
print(f"mistake 2, split 10 and 50: pad to n = 2^50, so n^{2 - eps:.1f} = 2^{50 * (2 - eps):.1f}, worse than 2^{NN}")
print(f"mistake 3, near-identical strands: diagonal road {near_c} cells, {1000000 // near_c} times fewer than the table")
ns = [10 ** e for e in range(3, 10)]
print("chart n: " + ", ".join(f"10^{e}" for e in range(3, 10)))
print("chart log10 n^2: " + ", ".join(f"{2 * math.log10(n):.2f}" for n in ns))
print("chart log10 n^2/log2 n: " + ", ".join(f"{2 * math.log10(n) - math.log10(math.log2(n)):.2f}" for n in ns))
print("chart log10 n^1.9: " + ", ".join(f"{1.9 * math.log10(n):.2f}" for n in ns))
lo, hi = 10.0, 200.0                     # n = 2^s with n^0.1 = log2 n, by bisection
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if 0.1 * mid < math.log2(mid) else (lo, mid)
print(f"n^1.9 drops below n^2/log2 n only past n = 2^{lo:.1f}")

assert t[-1][-1] == dd == 3 and agree                      # two roads, hand pair and all short pairs
assert near_t == near_d and far_t == far_d and near_t <= 3 # two roads on 1,000-base strands
assert sorted(brute) == sorted(ortho) and len(brute) == 4  # split and list matches brute force
assert flipped != len(brute) and near_c * 50 < 1000000     # the broken versions really break
assert cg == [1, 1, 1, 3] and all(joined[i, j] == 8 + 2 * d for i, j, d in pairs)  # coordinate and joined gadgets
assert all(full[i, j] == e_s + 2 * min(d, 1) for i, j, d in pairs)  # the paper's vector-gadget formula, every pair
assert 58 < lo < 60 and abs(0.1 * lo - math.log2(lo)) < 1e-6     # crossover sits where n^0.1 = log2 n
print("ALL CHECKS PASS")
