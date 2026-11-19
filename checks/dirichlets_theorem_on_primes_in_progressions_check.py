# Dirichlet's theorem for primes 3 mod 4 -- the check behind the card.  Standard library only.
# Road 1 counts primes with a sieve, and again by trial division.  Road 2 computes the two
# L-functions mod 4 from their series over all whole numbers, using no primes, and tests the
# identity that ties them to the primes 3 mod 4.  Road 3 is the Euler product of L(1, chi4).
import math
X = 10 ** 6

def sieve(m):                                    # Eratosthenes: flag[n] is True when n is prime
    flag = [True] * (m + 1); flag[0] = flag[1] = False
    for p in range(2, math.isqrt(m) + 1):
        if flag[p]: flag[p * p::p] = [False] * len(flag[p * p::p])
    return flag
def is_prime(n):                                 # trial division, the second road to primality
    return n > 1 and all(n % d for d in range(2, math.isqrt(n) + 1))
def factor(n):                                   # prime factors by trial division
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def alt(term, s, n=2000, m=20):                  # alternating series: partial sums, then average
    sums, tot = [], 0.0                          # neighbours m times (Euler's smoothing)
    for k in range(n):
        tot += (-1) ** k * term(k, s); sums.append(tot)
    w = sums[-(m + 1):]
    for _ in range(m): w = [(w[i] + w[i + 1]) / 2 for i in range(len(w) - 1)]
    return w[0]
def L4(s):                                       # L(s, chi4) = 1 - 1/3^s + 1/5^s - 1/7^s + ...
    return alt(lambda k, s: (2 * k + 1) ** -s, s)
def L0(s):                                       # L(s, chi0) = sum over odd n = (1 - 2^-s) zeta(s),
    eta = alt(lambda k, s: (k + 1) ** -s, s)     # with zeta from the alternating eta series
    return (1 - 2 ** -s) * eta / (1 - 2 ** (1 - s))
def f6(v): return f"{v:.6f}"

flag = sieve(X)
primes = [p for p in range(2, X + 1) if flag[p]]
three = [p for p in primes if p % 4 == 3]
print("first primes 3 mod 4:", three[:10])
e, f = 4 * 3 * 7 * 11 - 1, 4 * 5 * 13 * 17 - 1
print(f"Euclid's trick: 4 x 3 x 7 x 11 - 1 = {e} = {factor(e)}; new prime 3 mod 4: {factor(e)[-1]}")
print(f"same trick for 1 mod 4: 4 x 5 x 13 x 17 - 1 = {f} = {factor(f)}; each is 3 mod 4: "
      f"{'yes' if all(p % 4 == 3 for p in factor(f)) else 'no'}")
cnt, tot, rows, lead, marks = {1: 0, 3: 0}, {1: 0.0, 3: 0.0}, [], None, [10 ** k for k in range(1, 7)]
for p in primes + [X + 1]:                       # one pass; X + 1 only closes the last row
    while marks and p > marks[0]:
        rows.append((marks.pop(0), cnt[1], cnt[3], tot[1], tot[3]))
    if p % 2 and p <= X:
        cnt[p % 4] += 1; tot[p % 4] += 1 / p
        if lead is None and cnt[1] > cnt[3]: lead = (p, cnt[1], cnt[3])
print("x | primes 1 mod 4 | primes 3 mod 4 | share 3 mod 4 | sum 1/p, 1 mod 4 | sum 1/p, 3 mod 4 "
      "| difference = sum chi4(p)/p | (1/2) log log x")
for x, a, b, t1, t3 in rows:
    print(f"10^{len(str(x)) - 1} | {a} | {b} | {b / (a + b):.4f} | {f6(t1)} | {f6(t3)} | {f6(t1 - t3)} "
          f"| {f6(0.5 * math.log(math.log(x)))}")
chart = lambda i: "[" + ", ".join(f"{r[i]:.2f}" for r in rows) + "]"
print("chart, sum 1/p over p 3 mod 4:", chart(4))
print("chart, sum 1/p over p 1 mod 4:", chart(3))
print("chart, sum chi4(p)/p:", "[" + ", ".join(f"{r[3] - r[4]:.2f}" for r in rows) + "]")
trial = sum(1 for n in range(3, 10 ** 4, 4) if is_prime(n))
print(f"primes 3 mod 4 below 10^4: sieve {rows[3][2]}, trial division {trial}")
print(f"first prime where 1 mod 4 leads: {lead[0]} (counts {lead[1]} to {lead[2]})")
digits = {d: sum(1 for p in primes if p % 10 == d) for d in (1, 3, 7, 9)}
print(f"primes below 10^6: {len(primes)}; by last digit (2 and 5 aside): "
      + ", ".join(f"{d}: {v} ({v / (len(primes) - 2):.4f})" for d, v in digits.items()))
euler = 1.0
for p in primes:
    if p % 2: euler /= 1 - (1 if p % 4 == 1 else -1) / p
print(f"L(1, chi4): series {L4(1.0):.12f}; Euler product to 10^6 {euler:.12f}; "
      f"pi/4 cross-check {math.pi / 4:.12f}; floor 1 - 1/3 = {f6(2 / 3)}")
print("s | L(s, chi0) | L(s, chi4) | (1/2) log(L0/L4) | (1/2) log(L0 L4) | log(1/(s-1)) | 3 mod 4 share")
table = []
for label in ("2", "1.1", "1.01", "1.001"):
    s = float(label); a, b = L0(s), L4(s)
    g3, g1, big = 0.5 * math.log(a / b), 0.5 * math.log(a * b), math.log(1 / (s - 1))
    table.append((s, a, b, g3, g1, big))
    share = "-" if big == 0 else f"{g3 / big:.4f}"
    print(f"{label} | {f6(a)} | {f6(b)} | {f6(g3)} | {f6(g1)} | {f6(big)} | {share}")
side = sum(math.atanh(p ** -2.0) for p in three)
print(f"s = 2: (1/2) log(L0/L4) = {table[0][3]:.9f}; sum of artanh(p^-2) over p 3 mod 4 to 10^6 = "
      f"{side:.9f}; gap {table[0][3] - side:.9f}")
fake = 0.5 * (math.log(table[3][1]) + math.log((1.001 - 1) * table[3][2]))
print(f"mistake 1, class 2 mod 4 (shares 2 with the step): {sum(1 for p in primes if p % 4 == 2)} prime; "
      f"class 0 mod 4: {sum(1 for p in primes if p % 4 == 0)} primes")
print(f"mistake 2, sharing over all 4 classes: 78498 / 4 = {len(primes) / 4:.1f}, true count {rows[5][2]}")
print(f"mistake 3, equal share read as equal counts: 3 mod 4 leads by {rows[5][2] - rows[5][1]} at 10^6")
print(f"mistake 4, a zero at s = 1: (1/2) log(L0 x (s-1) L4) at s = 1.001 is {f6(fake)}, no longer growing")
assert trial == rows[3][2]                                      # sieve against trial division
assert abs(euler - L4(1.0)) < 1e-3 and abs(L4(1.0) - math.pi / 4) < 1e-10   # three roads to L(1, chi4)
assert abs(table[0][3] - side) < 2e-6                           # primes against whole-number series
assert all(r[2] >= 2 / 3 for r in table) and [r[3] for r in table] == sorted(r[3] for r in table)
assert max(abs(r[3] - r[4]) for r in rows) < 0.5 and lead[0] == 26861   # bounded; Leech 1957
assert factor(e) == [13, 71] and factor(e)[-1] % 4 == 3 and len(primes) == 78498   # pi(10^6) table
print("ALL CHECKS PASS")
