# Strong law of large numbers -- the check behind the card.  Standard library only.
# A fair die, mean 3.5, tolerance 0.1.  Roads: exact fractions for the moments and
# closed forms beside them; the fourth moment of the sum by formula and by counting
# all 6^n sequences; exact tail probabilities by convolution against the two bounds
# and against simulation (SplitMix64, seed 20260929); the +-n sequence by partial
# sums against the integral test.  Code checks finite stages; the limits need proofs.
from fractions import Fraction as Q
from math import log, sqrt

K, EPS = 6, Q(1, 10)
ys = [Q(2 * f - 7, 2) for f in range(1, K + 1)]             # centred faces -2.5 .. 2.5
m2, m4 = sum(y ** 2 for y in ys) / K, sum(y ** 4 for y in ys) / K
m2c, m4c = Q(K * K - 1, 12), Q((K * K - 1) * (3 * K * K - 7), 240)
C = (m4 + 3 * m2 ** 2) / EPS ** 4
print(f"centred die: E[Y^2] = {m2} = {float(m2):.6f}, E[Y^4] = {m4} = {float(m4):.6f}")
print(f"closed forms (k^2-1)/12 = {m2c}, (k^2-1)(3k^2-7)/240 = {m4c}")
print(f"E[Y^4] + 3 E[Y^2]^2 = {float(m4 + 3 * m2 ** 2):.2f}; C = that / 0.1^4 = {C}")

print("E[(S_n - 3.5n)^4]: formula n m4 + 3n(n-1) m2^2, and a count over all 6^n sequences")
counts, fourth_ok = {0: 1}, []
for n in range(1, 9):
    new = {}
    for s, c in counts.items():
        for f in range(1, K + 1):
            new[s + f] = new.get(s + f, 0) + c
    counts = new
    counted = Q(sum(c * (2 * s - 7 * n) ** 4 for s, c in counts.items()), 16 * K ** n)
    formula = n * m4 + 3 * n * (n - 1) * m2 ** 2
    fourth_ok.append(counted == formula)
    if n in (1, 2, 3, 4, 8):
        print(f"n={n}: formula {float(formula):.6f}, count {float(counted):.6f}")

M2, M4 = float(m2), float(m4)
def cheb(n): return 100.0 * M2 / n                           # E[Y^2] / (n eps^2)
def fourth(n):                                              # E[S_n^4] / (n^4 eps^4)
    x = float(n)
    return 10000.0 * (x * M4 + 3.0 * x * (x - 1.0) * M2 * M2) / (x * x * (x * x))

print("P(|average - 3.5| > 0.1): Chebyshev 35/12/(n 0.01), fourth-moment bound, C/n^2, exact")
dist, exact = [1.0], {}                                     # dist[s - n] = P(S_n = s)
for n in range(1, 1001):
    old = dist
    dist = [sum(old[j - f] for f in range(K) if 0 <= j - f < len(old)) / K
            for j in range(len(old) + K - 1)]
    if n in (10, 100, 200, 500, 1000):
        exact[n] = sum(p for j, p in enumerate(dist) if 5 * abs(2 * (j + n) - 7 * n) > n)
        print(f"n={n:4d}: {cheb(n):9.4f} {fourth(n):11.4f} {float(C) / n ** 2:11.4f} {exact[n]:.4f}")
print(f"n=10000: {cheb(10000):9.4f} {fourth(10000):11.4f} {float(C) / 10000 ** 2:11.4f} (no exact)")
edge = sum(p for j, p in enumerate(dist) if 5 * abs(2 * (j + 1000) - 7000) >= 1000)  # dist is n = 1000
print(f"n=1000, the edge totals 3400 and 3600 counted too: P(|average - 3.5| >= 0.1) = {edge:.4f}")
print("Borel-Cantelli tail: sum over n >= N of C/n^2 <= C/(N-1) =",
      "; ".join(f"{float(C) / (N - 1):.6f} at N={N}" for N in (402501, 402502, 40250002)))
sc, sf = 0.0, 0.0
for n in range(1000, 1000001):
    sc += cheb(n)
    sf += fourth(n)
    if n in (10000, 100000, 1000000):
        print(f"sum of bounds for n = 1000..{n}: Chebyshev {sc:.2f}, fourth-moment {sf:.2f}")

M64 = (1 << 64) - 1
state = 20260929
def roll():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (z ^ (z >> 31)) % 6 + 1

CHECK = (10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000)
GRID = (100, 200, 500, 1000, 2000, 5000)
RUNS, LEN = 200, 10000
out_at, again = {n: 0 for n in GRID}, {n: 0 for n in GRID}
for r in range(RUNS):
    s, last, avgs = 0, 0, {}
    for n in range(1, LEN + 1):
        s += roll()
        if 5 * abs(2 * s - 7 * n) > n:
            last = n
            if n in out_at:
                out_at[n] += 1
        if n in CHECK:
            avgs[n] = s / n
        if n == 200:
            s200 = s
    for n in GRID:
        again[n] += last >= n
    if r == 0:
        print("run 1, running average:", ", ".join(f"{n}: {avgs[n]:.4f}" for n in CHECK))
        print(f"run 1: last n <= 10000 outside the band 3.40 to 3.60 is n = {last}")
        print(f"run 1: rolls 201 to 10000 average (S_10000 - S_200) / 9800 = {(s - s200) / (LEN - 200):.4f}")
        print("figure, run 1 averages to 2 decimals:", ", ".join(f"{avgs[n]:.2f}" for n in CHECK))
        first_avg = avgs[LEN]
print(f"{RUNS} runs of {LEN}: n, runs outside the band at n, runs outside at some m in [n, 10000]")
for n in GRID:
    print(f"n={n:4d}: {out_at[n]:3d} {again[n]:3d}")

print("+-n sequence: Z_n = +n or -n, each with chance 1/(2 n ln n), else 0 (n >= 3)")
v, h, rows = 0.0, 0.0, []
for n in range(3, 1000001):
    v += n / log(n)
    h += 1.0 / (n * log(n))
    if n in (10, 100, 1000, 10000, 100000, 1000000):
        lo, hi = log(log(n + 1)) - log(log(3)), log(log(n)) - log(log(3)) + 1 / (3 * log(3))
        rows.append((lo, h, hi))
        print(f"n={n:7d}: Var(S_n/n) {v / n ** 2:.6f}, 2 ln n Var {2 * log(n) * v / n ** 2:.4f}, "
              f"sum P(|Z_k| = k) {h:.4f} in [{lo:.4f}, {hi:.4f}]")
copied = Q(sum(1 for f in range(1, K + 1) if 5 * abs(2 * f - 7) > 1), K)  # average = first face
print(f"copied die (every roll equals the first): P(|average - 3.5| > 0.1) = {copied} at every n")

assert m2 == m2c and m4 == m4c and C == 402500                  # moments: listing vs closed form
assert all(fourth_ok)                                           # fourth moment: count vs formula
assert all(exact[n] <= min(1.0, cheb(n), fourth(n)) for n in exact)  # bounds hold on exact values
se = sqrt(exact[1000] * (1 - exact[1000]) / RUNS)
assert abs(out_at[1000] / RUNS - exact[1000]) < 4 * se          # simulation vs convolution
assert abs(first_avg - 3.5) < 4 * sqrt(float(m2) / LEN)         # one run's average vs mean
assert all(lo <= s <= hi for lo, s, hi in rows)                 # divergent sum vs integral test
