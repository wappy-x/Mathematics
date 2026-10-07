# The Borel-Cantelli lemmas -- the check behind the card.  Standard library
# only.  A fair die rolled forever.  A_n: roll n is a six.  B_n: rolls n to
# 2n-1 are all sixes, so roll n starts a run of n sixes.  Each number is
# reached by two roads: exact listing or algebra, and a second formula or a
# seeded simulation.  Finite stages only; the infinite claims rest on proofs.
from fractions import Fraction as Q

SIX = Q(1, 6)

def prob(L, event):                     # exact P(event), listing every six/not-six
    total = Q(0)                        # pattern of rolls 1..L; bit i-1 set: roll i a six
    for mask in range(1 << L):
        if event(mask):
            k = bin(mask).count("1")
            total += SIX ** k * (1 - SIX) ** (L - k)
    return total

def B(mask, n):                         # rolls n to 2n-1 all sixes
    return all(mask >> (i - 1) & 1 for i in range(n, 2 * n))

def incl_excl(m):                       # P(B_1 or ... or B_m), inclusion-exclusion:
    total = Q(0)                        # an overlap of B's needs every roll they name
    for S in range(1, 1 << m):
        rolls = {i for n in range(1, m + 1) if S >> (n - 1) & 1 for i in range(n, 2 * n)}
        total += (-1) ** (bin(S).count("1") + 1) * SIX ** len(rolls)
    return total

def exp_series(x):                      # e^x by its Taylor series
    term, s, k = 1.0, 1.0, 0
    while term > 1e-18 * s:
        k += 1
        term *= x / k
        s += term
    return s

def exp_squaring(x):                    # e^x as (1 + x/2^20)^(2^20)
    y = 1.0 + x / 2 ** 20
    for _ in range(20):
        y *= y
    return y

print("lemma 1, B_n: n, P(B_n) listed, 6^-n, sum of P(B_k) to n, closed form (1 - 6^-n)/5")
partial = Q(0)
for n in range(1, 7):
    listed = prob(2 * n - 1, lambda mask: B(mask, n))
    partial += SIX ** n
    closed = (1 - SIX ** n) / 5
    assert listed == SIX ** n           # listing against the formula
    assert partial == closed            # term by term against the closed form
    print(f"n={n} {listed} {SIX ** n} {float(partial):.6f} {float(closed):.6f}")
print("sum over all n of P(B_n) = (1/6)/(1 - 1/6) =", SIX / (1 - SIX))
unions = [prob(2 * m - 1, lambda mask: any(B(mask, n) for n in range(1, m + 1))) for m in range(1, 7)]
ie = [incl_excl(m) for m in range(1, 7)]
assert unions == ie                     # two roads to every union
print("P(B_1 or ... or B_m), m=1..6, listed:  ", " ".join(f"{float(u):.6f}" for u in unions))
print("same, by inclusion-exclusion:          ", " ".join(f"{float(u):.6f}" for u in ie))
lo, hi = unions[5], unions[5] + SIX ** 6 / 5
print(f"m=2 exactly {unions[1]}; some B_n ever: between {float(lo):.6f} and {float(hi):.6f}")
tails = [SIX ** (N - 1) / 5 for N in range(1, 7)]
tails_f = [sum(6.0 ** -n for n in range(N, N + 60)) for N in range(1, 7)]
assert all(abs(float(t) - f) < 1e-12 for t, f in zip(tails, tails_f))
print("union bound on P(some B_n with n >= N), N=1..6:", " ".join(f"{float(t):.4f}" for t in tails))
print("chance of some A_n with n >= N, N=1..6, within 60 rolls:", " ".join(f"{1 - (5 / 6) ** 60:.4f}" for N in range(1, 7)))

print("lemma 2, no six in m rolls in a row: exact (5/6)^m <= bound e^(-m/6)")
for m in (6, 12, 30, 60):
    exact, bound = float((1 - SIX) ** m), 1 / exp_series(m / 6)
    assert exact < bound
    print(f"m={m:3d}: {exact:.8f} <= {bound:.8f}")
e10 = (1 / exp_series(10.0), 1 / exp_squaring(10.0))
assert abs(e10[0] / e10[1] - 1) < 1e-4
print(f"e^(-10) by series {e10[0]:.8f}, by squaring {e10[1]:.8f}")

MASK, state = (1 << 64) - 1, 20260929
def roll():                             # SplitMix64, then a face 1..6
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (z ^ (z >> 31)) % 6 + 1

M, R = 20000, 120
sixes = late = runs = any_run = late_run = glued = 0
for _ in range(M):
    r = [False] + [roll() == 6 for _ in range(R)]      # r[i]: roll i is a six
    sixes += sum(r)
    late += any(r[61:])
    starts = [n for n in range(1, 61) if all(r[n:2 * n])]
    runs += len(starts)
    any_run += bool(starts)
    late_run += any(n >= 3 for n in starts)
    glued += r[1]
print(f"simulation, {M} paths of {R} rolls, SplitMix64 seed 20260929:")
print(f"mean sixes per path {sixes / M:.4f}, exact 20")
print(f"share with a six in rolls 61 to 120 {late / M:.5f}, exact {1 - (5 / 6) ** 60:.5f}")
print(f"mean run-starts B_n per path, n <= 60: {runs / M:.4f}, exact {float(1 - SIX ** 60) / 5:.4f}")
print(f"share with at least one run-start {any_run / M:.4f}, exact {float(lo):.4f}")
print(f"share with a run-start at n >= 3 {late_run / M:.4f}, at most {float(tails[2]):.4f}")
print(f"share with roll 1 a six, the glued events happening infinitely often {glued / M:.4f}, exact {float(SIX):.4f}")
se = lambda p: 4 * (p * (1 - p) / M) ** 0.5
assert abs(sixes / M - 20) < 4 * (120 * 5 / 36 / M) ** 0.5
assert abs(any_run / M - float(lo)) < se(float(lo)) and abs(glued / M - 1 / 6) < se(1 / 6)
assert late_run / M < float(tails[2]) + se(float(tails[2]))

print("subsequence, X_n = share of sixes in the first n rolls, tolerance 0.05:")
for n in (100, 400, 900, 1600):
    pmf, tail = (5 / 6) ** n, 0.0
    for j in range(n + 1):
        if 20 * abs(6 * j - n) > 6 * n:
            tail += pmf
        pmf *= (n - j) / (j + 1) / 5
    assert tail <= 500 / (9 * n)        # exact binomial tail under Chebyshev
    print(f"n={n:4d}: Chebyshev bound 500/(9n) = {500 / (9 * n):.6f}, exact binomial {tail:.6f}")
all_n = sum(500 / (9 * n) for n in range(1, 10001))
squares = sum(500 / (9 * k * k) for k in range(1, 101))
print(f"sum of the bounds over all n <= 10000: {all_n:.4f}; over n = k^2, k <= 100: {squares:.4f}")
print(f"bound on the sum over k > K of 500/(9k^2), 500/(9K): K=100 {500 / 900:.4f}, K=1000 {500 / 9000:.4f}")
count, miss, xs = 0, [], {}
for k in range(1, 101):
    while count < k * k:
        count += 1
        xs[count] = xs.get(count - 1, 0) + (roll() == 6)
    if 20 * abs(6 * xs[k * k] - k * k) > 6 * k * k:
        miss.append(k)
print("one path of 10000 rolls: X_n at n = 100, 900, 2500, 10000:",
      " ".join(f"{xs[n] / n:.4f}" for n in (100, 900, 2500, 10000)))
print("k <= 100 with |X_(k^2) - 1/6| > 0.05:", " ".join(map(str, miss)), f"({len(miss)} of 100)")
print("ALL CHECKS PASS")
