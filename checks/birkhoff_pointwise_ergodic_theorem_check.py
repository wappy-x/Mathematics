# Birkhoff's pointwise ergodic theorem -- the check behind the card.  Standard
# library only.  The doubling map T x = 2x mod 1 shifts binary digits, so with
# f = first digit, f(T^k x) is digit k + 1 and the time average is a share of 1s.
from math import log10, sqrt, pi

MASK = (1 << 64) - 1
def splitmix(seed):               # SplitMix64 written out: the digits of a typical start
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & MASK
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield z ^ (z >> 31)

def fraction_digits(p, q, n):     # binary digits of p/q by long division
    out = []
    for _ in range(n):
        p *= 2
        out.append(1 if p >= q else 0)
        p %= q
    return out

def typical_digits(n, seed=2026):
    gen, out = splitmix(seed), []
    while len(out) < n:
        w = next(gen)
        out.extend((w >> (63 - i)) & 1 for i in range(64))
    return out[:n]

BIG = 1000000
third, seventh, typ = fraction_digits(1, 3, 1000), fraction_digits(1, 7, 1000), typical_digits(BIG)
print("-- doubling map, f = first binary digit: share of 1s in the first n digits")
print("n, start 1/3, start 1/7, typical start")
for n in [10, 20, 50, 100, 200, 500, 1000]:
    print(f"{n}, {sum(third[:n]) / n:.4f}, {sum(seventh[:n]) / n:.4f}, {sum(typ[:n]) / n:.4f}")
ones = sum(typ)
print(f"typical start, n = {BIG}: {ones} ones, share {ones / BIG:.6f}")
assert sum(third) == 500 and sum(seventh) == 1000 // 3     # 01 01 ... and 001 001 ...
assert abs(ones / BIG - 0.5) < 4 * 0.5 / sqrt(BIG)           # within 4 binomial sd
blocks = {b: 0 for b in ["00", "01", "10", "11"]}
for i in range(BIG - 1):
    blocks[f"{typ[i]}{typ[i + 1]}"] += 1
tb = {b: 0 for b in blocks}
for i in range(999):
    tb[f"{third[i]}{third[i + 1]}"] += 1
print("pairs of digits 00 01 10 11, typical: " + " ".join(f"{blocks[b] / (BIG - 1):.4f}" for b in blocks)
      + "; start 1/3: " + " ".join(f"{tb[b] / 999:.4f}" for b in tb))
assert all(abs(blocks[b] / (BIG - 1) - 0.25) < 0.003 for b in blocks)

print("-- convergence in L1: distance E|share - 1/2| over all starts")
def l1_binomial(n):               # road 1: digits are fair coins; p_k by the ratio rule
    p, tot = 0.5 ** n, 0.0
    for k in range(n + 1):
        tot += p * abs(k / n - 0.5)
        p = p * (n - k) / (k + 1)
    return tot
def l1_enumerate(n):              # road 2: count the 1s in every n-digit string
    tot = 0
    for j in range(2 ** n):
        tot += abs(2 * bin(j).count("1") - n)
    return tot / (2 * n * 2 ** n)
for n in [10, 100, 1000]:
    print(f"n = {n}: exact {l1_binomial(n):.6f}, bell-curve estimate 1/sqrt(2 pi n) {1 / sqrt(2 * pi * n):.6f}")
print(f"n = 10 by enumerating 1024 starts: {l1_enumerate(10):.6f}")
assert abs(l1_enumerate(10) - l1_binomial(10)) < 1e-12
assert abs(l1_binomial(1000) * sqrt(2 * pi * 1000) - 1) < 0.01

print("-- maximal ergodic theorem: E_N = {share of 1s exceeds 3/5 at some n <= N}")
def maximal_dp(N):                # road 1: count digit strings by (first digit, ones, flag)
    st = {(0, 0, False): 1}
    for n in range(1, N + 1):
        new = {}
        for (f1, o, fl), c in st.items():
            for d in (0, 1):
                key = (d if n == 1 else f1, o + d, fl or 5 * (o + d) > 3 * n)
                new[key] = new.get(key, 0) + c
        st = new
    inE = sum(c for (f1, o, fl), c in st.items() if fl)
    fE = sum(c for (f1, o, fl), c in st.items() if fl and f1 == 1)
    return inE, fE, 2 ** N
def maximal_enumerate(N):         # road 2: every string of N + 1 digits, and Garsia's step
    inE, fE, worst = 0, 0, -10 ** 9
    for j in range(2 ** (N + 1)):
        d = [(j >> (N - i)) & 1 for i in range(N + 1)]
        def M(start):             # M_N = max(0, S_1, ..., S_N) for g = 5 f - 3, from digit start
            s, m = 0, 0
            for i in range(start, start + N):
                s += 5 * d[i] - 3
                m = max(m, s)
            return m
        if M(0) > 0:
            inE, fE = inE + 1, fE + d[0]
            worst = max(worst, M(0) - (5 * d[0] - 3) - M(1))   # Garsia: must be <= 0
    return inE, fE, 2 ** (N + 1), worst
for N in [10, 30, 100]:
    e, fe, tot = maximal_dp(N)
    print(f"N = {N}: m(E_N) = {e / tot:.4f}, integral of f over E_N = {fe / tot:.4f}, "
          f"integral of f - 3/5 over E_N = {(5 * fe - 3 * e) / (5 * tot):.4f}")
    assert 5 * fe - 3 * e >= 0                                # Garsia's inequality
e12, fe12, t12, worst = maximal_enumerate(12)
print(f"N = 12: m(E_N) by counting {e12 / t12:.6f}, by digit strings {maximal_dp(12)[0] / 2 ** 12:.6f}; "
      f"largest M_N - g - M_N(T) on E_N: {worst}")
assert e12 * 2 ** 12 == maximal_dp(12)[0] * t12 and worst <= 0
print(f"maximal inequality bound (1/2)/(3/5) = {0.5 / 0.6:.4f}")

alpha = log10(2)
print(f"-- rotation by alpha = log10 2 = {alpha:.5f}, start 0: leading digit of 2^k for k < n")
p, lead = 1, [0] * 10
for n in range(1000):
    lead[int(str(p)[0])] += 1     # road 1: exact whole numbers
    p *= 2
    if n + 1 in (10, 100, 1000):
        hits = sum(1 for k in range(n + 1) if (k * alpha) % 1.0 < alpha)   # road 2: the orbit
        print(f"n = {n + 1}: leading digit 1 by exact powers {lead[1]}, by orbit in [0, alpha) {hits}, "
              f"alpha n = {alpha * (n + 1):.2f}")
        assert hits == lead[1]
print("digit, count of 1000, Benford 1000 log10(1 + 1/d)")
for dgt in range(1, 10):
    print(f"{dgt}, {lead[dgt]}, {1000 * log10(1 + 1 / dgt):.1f}")
assert all(abs(lead[d] - 1000 * log10(1 + 1 / d)) < 12 for d in range(1, 10))

print("-- what breaks")
q = [sum(1 for k in range(1000) if 4 * ((s + 5 * k) % 10) < 10) / 1000 for s in (1, 3)]
print(f"rotation by 1/2, f = 1 on [0, 1/4): start 0.1 -> {q[0]:.4f}, start 0.3 -> {q[1]:.4f}, space average 0.2500")
x, h = 0.75, 0
for _ in range(1000):
    h, x = h + (x >= 0.5), x / 2
print(f"T x = x/2 keeps no length: start 0.75, share at n = 1000: {h / 1000:.4f}")
print(f"start 1/7: share at n = 1000: {sum(seventh) / 1000:.4f}")
x, h, dead = 0.1, 0, 0
for k in range(1000):
    h, x = h + (x >= 0.5), 2 * x % 1.0
    dead = dead or (k + 1 if x == 0 else 0)
num, den = (0.1).as_integer_ratio()
print(f"doubling 0.1 in floating point: {h} ones in 1000 steps, share {h / 1000:.4f}, zero from step {dead}; "
      f"0.1 is stored as {num}/2^{den.bit_length() - 1}, whose numerator has {bin(num).count('1')} ones")
assert h == bin(num).count("1") and dead == den.bit_length() - 1 and q == [0.5, 0.0]
print("ALL CHECKS PASS")
