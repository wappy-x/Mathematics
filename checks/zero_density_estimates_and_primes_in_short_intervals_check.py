# Zero-density estimates and primes in short intervals -- the check behind the card.
# Standard library only.  Roads: exact exponent algebra in fractions; the density
# envelopes scanned on a grid; primes counted by a sieve and again by trial division.
import itertools
import math
from fractions import Fraction as F

X = 10 ** 6
LIM = X + 40000
BIG = 10 ** 8                                              # the cube-root windows are followed this far
ok = bytearray([0, 0]) + bytearray([1]) * (BIG - 1)       # Eratosthenes up to BIG
for i in range(2, int(BIG ** 0.5) + 1):
    if ok[i]:
        ok[i * i::i] = bytearray(len(range(i * i, BIG + 1, i)))
pi = [0] * (LIM + 1)                                       # pi[n] = primes up to n
for n in range(1, LIM + 1):
    pi[n] = pi[n - 1] + ok[n]

def is_prime_td(n):                                        # trial division, no sieve
    if n < 2:
        return False
    d = 2
    while d * d <= n:
        if n % d == 0:
            return False
        d += 1
    return True

def count(y, h):                                           # primes in (y, y + h]
    return pi[y + h] - pi[y]

print("house: primes below a million =", pi[X])
assert pi[X] == 78498                                      # the shelf's house count

# Road 1: the density envelopes, scanned on a grid of sigma, in exact fractions.
def huxley(s):
    return min(F(3) / (2 - s), F(3) / (3 * s - 1))
def guth_maynard(s):
    return min(F(3) / (2 - s), F(15) / (3 + 5 * s))
grid = [F(k, 1000) for k in range(500, 1001)]
for name, env, s_star in (("Huxley", huxley, F(3, 4)), ("Guth-Maynard", guth_maynard, F(7, 10))):
    best = max(grid, key=env)
    print(f"envelope {name}: max over sigma at {best} = {env(best)} (crossing solved: {s_star})")
    assert best == s_star
assert huxley(F(3, 4)) == F(12, 5) and guth_maynard(F(7, 10)) == F(30, 13)
cross = max(s for s in grid if F(3) / (2 - s) <= F(8, 3))  # Ingham 1940 against Ingham 1937's flat 8/3
print(f"envelope Ingham 1940: 3/(2 - sigma) is {F(3) / (2 - F(1))} at sigma = 1, at most 8/3 up to sigma = {cross} (solved: {2 - F(9, 8)})")
assert cross == 2 - F(9, 8)

# Road 2: theta = 1 - 1/A for every interval, 1 - 2/A for almost every interval.
rows = (("Carlson 1921", F(4)), ("Ingham 1937", F(8, 3)), ("Huxley 1972", F(12, 5)),
        ("Guth-Maynard", F(30, 13)), ("density hyp.", F(2)))
quoted_every = {F(8, 3): F(5, 8), F(12, 5): F(7, 12), F(30, 13): F(17, 30)}  # as stated by the papers
quoted_almost = {F(12, 5): F(1, 6), F(30, 13): F(2, 15)}
print(f"x = 10^6, log x = {math.log(X):.4f}")
r4 = math.log(X) ** 0.25
print(f"error shape exp(-(log x)^(1/4)) at 10^6 = exp(-{r4:.3f}) = {math.exp(-r4):.4f}")
print("name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h")
bars = []
for name, A in rows:
    th, aa = 1 - 1 / A, 1 - 2 / A
    if A in quoted_every:                                  # theta against the papers
        assert th == quoted_every[A]
    if A in quoted_almost:
        assert aa == quoted_almost[A]
    h = math.floor(X ** float(th))
    c = count(X, h)
    c_td = sum(1 for n in range(X + 1, X + h + 1) if is_prime_td(n))
    assert c == c_td                                       # sieve against trial division
    gain = sum(math.log(n) for n in range(X + 1, X + h + 1) if ok[n])
    pred = h / math.log(X)
    print(f"{name:13} {str(A):6} {str(th):6} {str(aa):10} {X ** float(th):9.2f} {h:6,}  {c:6}  {pred:7.1f}  {c - pred:6.1f}  {c / pred:.3f}  {gain / h:.4f}")
    bars.append((name, h))
for name, h in bars[1:]:                                   # one # per 200 integers
    print(f"bar {name:13} {'#' * round(h / 200):29} x^theta = {h:,}")

# Evidence across [10^5, 10^6]: every interval (y, y + y^theta] for two exponents.
for th, label in ((F(7, 12), "7/12"), (F(1, 3), "1/3")):
    lo, hi, arg_lo, empty = 9.0, 0.0, 0, 0
    for y in range(10 ** 5, X + 1):
        h = math.floor(y ** float(th))
        r = count(y, h) / (h / math.log(y))
        if r < lo:
            lo, arg_lo = r, y
        hi = max(hi, r)
        empty += count(y, h) == 0
    print(f"scan theta={label}: worst ratio {lo:.4f} at y={arg_lo:,}, best {hi:.4f}, empty intervals {empty:,}")
    if th == F(7, 12):
        assert empty == 0 and lo > 0.75
    else:
        assert empty > 0

# What breaks 1: the largest prime gap below a million, against theta = 1/3.
ps = [n for n in range(2, X + 1) if ok[n]]
g, p = max((ps[k + 1] - ps[k], ps[k]) for k in range(len(ps) - 1))
h = math.floor(p ** (1 / 3))
print(f"breaks: gap {g} after {p:,}; (p, p + {h}] holds {count(p, h)} primes, predicted {h / math.log(p):.2f}")
assert g == 114 and p == 492113 and count(p, h) == 0
last, prev = None, 2                                       # the last empty (p, p + p^(1/3)] below BIG
for p in itertools.compress(range(BIG + 1), ok):
    if p - prev > math.floor(prev ** (1 / 3)):
        last = (prev, p - prev, math.floor(prev ** (1 / 3)))
    prev = p
print(f"breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = {last[0]:,}: gap {last[1]} against a window of {last[2]}")
assert last[:2] == (2010733, 148)                          # a record gap in the maximal-gap tables

# What breaks 2: read the almost-all exponent 1/6 as 'every interval'. Count times size as a power of x,
# T = x^(1 - theta): one window (T^A/x)^(1-sigma), Step 0, k = 1; averaged over x (T^A/x^2)^(1-sigma), Step 7, k = 2.
A = F(12, 5)
def cs(th, k):
    return A * (1 - th) - k
print(f"breaks: count x size, A=12/5, as a power of x: one window x^{cs(1 - 1 / A, 1)} at theta=7/12, "
      f"x^{cs(F(1, 6), 1)} at theta=1/6; averaged over x, x^{cs(F(1, 6), 2)} at theta=1/6")
assert cs(F(1, 6), 1) > 0 >= cs(F(1, 6), 2)
bad, model, hs = 0, 0.0, set()                             # at a million: windows shorter than the mean gap
for y in range(10 ** 5, X + 1):
    h = math.floor(y ** (1 / 6))
    hs.add(h)
    bad += count(y, h) == 0
    model += (1 - 1 / math.log(y)) ** h                    # each integer prime with chance 1/log y
print(f"breaks: theta=1/6, widths {min(hs)} to {max(hs)}, mean gap log y {math.log(10 ** 5):.4f} to {math.log(X):.4f}; "
      f"empty {bad:,} of 900,001 = {bad / 900001:.4f}, random model {model / 900001:.4f}")
assert abs(bad - model) < 0.1 * 900001

# What breaks 3: no density bound. Up to T = x/h every zero may add up to 2h.
T = X / 3162
NT = T / (2 * math.pi) * math.log(T / (2 * math.pi)) - T / (2 * math.pi) + 7 / 8
print(f"breaks: no density bound, T = {T:.1f}, smooth N(T) = {NT:.1f}, error bound {2 * NT:.0f} times h")

# What breaks 4: classical zero-free region only, width 1/(5.558691 log T).
kappa = 1 - F(12, 5) * F(3, 8)                             # A = 12/5, theta = 5/8
saving = math.exp(-float(kappa) / 5.558691 / (3 / 8))
print(f"breaks: classical region, A=12/5, theta=5/8, kappa={kappa}, saving factor {saving:.4f} at every x")
assert kappa == F(1, 10) and 0.9 < saving < 1
print("quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;")
print("quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)")
print("quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)")
print("ALL CHECKS PASS")
