# BPP card check: the rota product check (one-sided), all coin strings, a seeded simulation,
# and the majority vote that amplifies a two-sided test. Standard library only.
from fractions import Fraction
from math import comb, log, ceil, exp

MASK = (1 << 64) - 1
class SplitMix64:  # small seeded generator, explained on wing 09's simulation cards
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def unit(self): return (self.next() >> 11) / 9007199254740992.0

def mat_mul(X, Y): return [[sum(X[i][t] * Y[t][j] for t in range(3)) for j in range(3)] for i in range(3)]
def mat_vec(X, v): return [sum(X[i][t] * v[t] for t in range(3)) for i in range(3)]
def passes(C, x): return mat_vec(A, mat_vec(B, x)) == mat_vec(C, x)
def lists(values):  # every possible random list of length 3
    out = [[]]
    for _ in range(3): out = [l + [v] for l in out for v in values]
    return out
def sci(x):  # same digits in both languages: scale by tens, then 2 decimals
    m, e = x, 0
    while m >= 10.0: m, e = m / 10.0, e + 1
    while m < 1.0: m, e = m * 10.0, e - 1
    return f"{m:.2f}e{e}"
def vote_error(p, k):  # chance a majority of k runs is wrong, built one run at a time
    dist = [1.0]
    for _ in range(k):
        dist = [(dist[j] * p if j < len(dist) else 0.0) + (dist[j - 1] * (1 - p) if j > 0 else 0.0) for j in range(len(dist) + 1)]
    total = 0.0
    for v in dist[(k + 1) // 2:]: total += v  # plain left-to-right sum, as in the Rust
    return total

A = [[4, 3, 2], [2, 2, 1], [5, 4, 3]]     # staff on wards W1..W3 per early, late, night shift
B = [[8, 6, 6], [8, 8, 6], [10, 10, 12]]  # hours of each shift on Mon, Sat, Sun
C = mat_mul(A, B)                          # staff-hours per ward per day: the true table
wrong = [r[:] for r in C]; wrong[1][1] = 36                    # one entry mistyped: W2 Sat
swap = [r[:] for r in C]; swap[1][0] += 2; swap[1][1] -= 2      # two errors, row total unchanged
print("true table C = AB, staff-hours, columns Mon Sat Sun")
for w in range(3): print(f"W{w + 1} " + " ".join(str(v) for v in C[w]))
for x in ([1, 0, 1], [0, 1, 1]):
    bx = mat_vec(B, x)
    left, right = mat_vec(A, bx), mat_vec(wrong, x)
    print(f"run x={x}: Bx={bx} A(Bx)={left} claimed Cx={right} {'pass' if left == right else 'caught'}")
L01, L10 = lists([0, 1]), lists(list(range(10)))
right_pass = sum(passes(C, x) for x in L01)
miss01, miss10 = sum(passes(wrong, x) for x in L01), sum(passes(wrong, x) for x in L10)
swap01, swap10 = sum(passes(swap, x) for x in L01), sum(passes(swap, x) for x in L10)
two_runs = sum(passes(wrong, x) and passes(wrong, y) for x in L01 for y in L01)
reused = sum(passes(wrong, x) and passes(wrong, x) for x in L01)
print(f"all 0/1 lists, true table: passes {right_pass} of 8")
print(f"all 0/1 lists, one wrong entry: misses {miss01} of 8 = {miss01 / 8:.6f}")
print(f"all 0-9 lists, one wrong entry: misses {miss10} of 1000 = {miss10 / 1000:.6f}")
print(f"all 0/1 lists, two errors: misses {swap01} of 8; all 0-9 lists: misses {swap10} of 1000")
print(f"fixed list [1, 1, 1], two errors: {'missed every time' if passes(swap, [1, 1, 1]) else 'caught'}")
print(f"two runs, all 64 coin strings: misses {two_runs} = {two_runs / 64:.6f}")
print(f"one list reused for both runs: misses {reused} of 8 = {reused / 8:.6f}")
print(f"20 fresh 0/1 runs: miss chance at most {sci(0.5 ** 20)}")
rng, T = SplitMix64(20261119), 100000
draw = lambda vals: [vals[rng.next() % len(vals)] for _ in range(3)]
sim01 = sum(passes(wrong, draw([0, 1])) for _ in range(T)) / T
sim10 = sum(passes(wrong, draw(list(range(10)))) for _ in range(T)) / T
sim2 = sum(passes(wrong, draw([0, 1])) and passes(wrong, draw([0, 1])) for _ in range(T)) / T
print(f"simulated {T} runs: miss 0/1 {sim01:.5f}, 0-9 {sim10:.5f}, two 0/1 runs {sim2:.5f}")
for m in (100, 1000, 10000):
    print(f"side m={m}: one check {3 * m * m}, redo {m ** 3}, 20 checks = {20 * 3 * m * m / m ** 3 * 100:.2f}% of a redo")
p, eps, delta = 2 / 3, 1 / 6, 1e-6
D = 0.5 * log(0.5 / (1 - p)) + 0.5 * log(0.5 / p)
print(f"two-sided test right with chance 2/3: Chernoff rate D = {D:.6f}")
print("runs k, exact vote error, Chernoff bound, Hoeffding bound")
exact_rows = {}
for k in (1, 3, 11, 21, 51, 101, 201):
    e = vote_error(p, k)
    exact_rows[k] = e
    print(f"k={k}: {sci(e)} {sci(exp(-k * D))} {sci(exp(-2 * k * eps * eps))}")
k_exact = next(k for k in range(1, 400, 2) if vote_error(p, k) <= delta)
k_chern, k_hoef = ceil(log(1 / delta) / D), ceil(log(1 / delta) / (2 * eps * eps))
print(f"runs for 1 in a million: exact {k_exact}, Chernoff {k_chern}, Hoeffding {k_hoef}")
votes = sum(sum(rng.unit() < p for _ in range(21)) < 11 for _ in range(T)) / T
print(f"simulated {T} votes of 21 runs: wrong {votes:.5f}, exact {exact_rows[21]:.5f}")
for name, g in (("1/6", 1 / 6), ("1/10", 0.1), ("1/100", 0.01), ("2^-20", 2.0 ** -20), ("2^-40", 2.0 ** -40)):
    runs = ceil(log(1 / delta) / (2 * g * g))
    print(f"gap {name}: Hoeffding runs for 1 in a million {runs if runs < 10 ** 7 else sci(runs)}")
pp = vote_error(0.5 + 2.0 ** -20, 101)
print(f"gap 2^-20, majority of 101 runs: wrong {pp:.6f}")
chart_k = [1, 51, 101, 151, 201, 251, 301]
print("chart, runs " + " ".join(str(k) for k in chart_k))
for name, q in (("2/3", 2 / 3), ("0.6", 0.6), ("0.55", 0.55)):
    print(f"chart, digits p={name} " + " ".join(f"{-log(vote_error(q, k)) / log(10):.2f}" for k in chart_k))

assert C == [[76, 68, 66], [42, 38, 36], [102, 92, 90]], "table by hand, row by row"
assert right_pass == 8 and miss01 * 2 <= 8 and miss10 * 10 <= 1000, "one-sided: never rejects, misses at most 1/|S|"
assert swap01 * 2 <= 8 and swap10 * 10 <= 1000, "bound holds for an error spread over two entries"
assert two_runs == miss01 * miss01, "fresh lists: two-run misses multiply"
assert abs(sim01 - miss01 / 8) < 4 * (0.25 / T) ** 0.5 and abs(sim10 - miss10 / 1000) < 4 * (0.09 / T) ** 0.5
assert abs(sim2 - two_runs / 64) < 4 * (0.1875 / T) ** 0.5, "simulated pairs against all 64 coin strings"
for k, e in exact_rows.items():
    fr = sum(Fraction(comb(k, j) * 2 ** (k - j), 3 ** k) for j in range((k + 1) // 2, k + 1))
    assert abs(e - float(fr)) <= 1e-12 * float(fr), "run-by-run table against the exact binomial sum"
    assert e <= exp(-k * D) * (1 + 1e-12) and exp(-k * D) <= exp(-2 * k * eps * eps), "truth under both bounds"
assert k_exact <= k_chern <= k_hoef
assert abs(votes - exact_rows[21]) < 4 * (exact_rows[21] * (1 - exact_rows[21]) / T) ** 0.5
assert 0.49 < pp < 0.5, "a margin of 2^-n, at n = 20, is not amplified by 101 runs"
print("ALL CHECKS PASS")
