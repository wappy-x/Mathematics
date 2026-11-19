# The L-function of y^2 = x^3 - 2 -- the check behind the card.  Standard
# library only.  Every a_p comes from counting points mod p.  Road 1: the local
# factor predicts the counts over F_p, F_p^2, F_p^3, checked by enumeration.
# Road 2: the Euler product against the series sum of a_n / n^s.  Road 3: the
# symmetry a modular form must have picks the conductor 1728 out of 54 tries.
import math
from fractions import Fraction
from itertools import product

B, X = -2, 10000                               # the curve y^2 = x^3 + B; primes below X
sieve = [False, False] + [True] * (X - 2)
for i in range(2, 100):
    if sieve[i]:
        sieve[i * i::i] = [False] * len(sieve[i * i::i])
ps = [i for i in range(X) if sieve[i]]

def count_mod_p(p):                            # points over F_p, with O
    squares = [0] * p
    for y in range(p):
        squares[y * y % p] += 1
    return 1 + sum(squares[(x * x * x + B) % p] for x in range(p))

def count_over_field(p, k):                    # points over F_(p^k), enumerated
    rule = [0] * k                             # x^k = rule[0] + rule[1] x + ...
    if k > 1:                                  # degree 2 or 3: irreducible = no root
        rule = next(r for r in product(range(p), repeat=k) if all(
            (pow(z, k, p) - sum(c * z ** i for i, c in enumerate(r))) % p for z in range(p)))
    def mul(u, v):
        w = [0] * (2 * k - 1)
        for i, j in product(range(k), repeat=2):
            w[i + j] += u[i] * v[j]
        for d in range(2 * k - 2, k - 1, -1):  # replace x^d using the rule
            for i, c in enumerate(rule):
                w[d - k + i] += w[d] * c
        return tuple(c % p for c in w[:k])
    elems = list(product(range(p), repeat=k))
    squares = {}
    for y in elems:
        squares[mul(y, y)] = squares.get(mul(y, y), 0) + 1
    shift = lambda u: ((u[0] + B) % p,) + u[1:]
    return 1 + sum(squares.get(shift(mul(mul(x, x), x)), 0) for x in elems)

def predicted(p, c, d, k):                     # p^k + 1 - (alpha^k + beta^k)
    s = [2, c]                                 # power sums of the roots of 1 - cT + dT^2
    for _ in range(k - 1):
        s.append(c * s[-1] - d * s[-2])
    return p ** k + 1 - s[k]

def poly(c, d):
    terms = ["1"] + ([f"{'-' if c > 0 else '+'} {abs(c) if abs(c) != 1 else ''}T"] if c else [])
    return " ".join(terms + ([f"+ {d}T^2"] if d else []))

disc = -16 * 27 * B * B
bad = [p for p in ps if p < 50 and disc % p == 0]
a = {p: (0 if p in bad else p + 1 - count_mod_p(p)) for p in ps}
v = [max(j for j in range(20) if disc % p ** j == 0) for p in bad]
print(f"curve y^2 = x^3 - 2; discriminant -16(4a^3 + 27b^2) = {disc} = -2^{v[0]} * 3^{v[1]}; bad primes {bad}; "
      f"house point (3, 5) on it: {'yes' if 5 * 5 == 3 ** 3 + B else 'no'}")
at2 = []
for p in [2, 3, 5, 7]:
    sing = [(x, y) for x in range(p) for y in range(p) if (y * y - x ** 3 - B) % p == 0
            and 2 * y % p == 0 and 3 * x * x % p == 0]
    c, d = (0, 0) if sing else (p + 1 - count_mod_p(p), p)
    kind = (f"singular at {sing[0]}, " + ("a cusp" if 3 * sing[0][0] % p == 0 else "a node")
            if sing else "smooth")
    print(f"p = {p}: {count_mod_p(p)} points over F_{p}; {kind}; a_{p} = {c}; local factor "
          f"{f'1/({poly(c, d)})' if c or d else '1'}")
    got = [count_over_field(p, k) for k in (1, 2, 3)]
    want = [predicted(p, c, d, k) for k in (1, 2, 3)]
    s = [p ** k + 1 - got[k - 1] for k in (1, 2, 3)]   # Newton's identities: counts -> factor
    e1, e2 = s[0], Fraction(s[0] * s[0] - s[1], 2)
    e3 = (e2 * s[0] - e1 * s[1] + s[2]) / 3
    print(f"   counted over F_{p}, F_{p}^2, F_{p}^3: {got}; from the factor: {want}; "
          f"rebuilt from counts: {poly(e1, e2)}, T^3 coefficient {e3}")
    assert got == want and (e1, e2, e3) == (c, d, 0)
    at2.append(Fraction(p ** 4, p ** 4 - c * p * p + d))   # T = 1/p^2
three, four = at2[0] * at2[1] * at2[2], at2[0] * at2[1] * at2[2] * at2[3]
print(f"factors at s = 2 for p = 2, 3, 5, 7: {', '.join(str(v) for v in at2)}")
print(f"first three multiply to {three} = {float(three):.6f}; first four to {four} = {float(four):.6f}")
an = [0, 1] + [0] * (X - 2)                    # a_n, multiplicative, built prime by prime
for n in range(2, X):
    p = next(q for q in ps if n % q == 0)
    m, k = n, 0
    while m % p == 0:
        m, k = m // p, k + 1
    prev, cur = 1, a[p]                        # a_(p^k) = a_p a_(p^(k-1)) - p a_(p^(k-2))
    for _ in range(k - 1):
        prev, cur = cur, a[p] * cur - (0 if p in bad else p) * prev
    an[n] = an[m] * cur
print(f"a_1 to a_25: {an[1:26]}")
worst = max(abs(a[p]) / (2 * math.sqrt(p)) for p in ps)
print(f"Hasse a_p^2 <= 4p for all {len(ps)} primes below {X}: "
      f"{'yes' if all(a[p] ** 2 <= 4 * p for p in ps) else 'no'}; largest |a_p|/(2 sqrt p) = {worst:.6f}")
cp = [p for p in ps if p <= 61]
print(f"chart primes {cp}")
print(f"chart a_p {[a[p] for p in cp]}")
print(f"chart 2 sqrt p {[f'{2 * math.sqrt(p):.2f}' for p in cp]}".replace("'", ""))
for s in (2, 3):
    prods, sums = [], []
    for cut in (100, 1000, 10000):
        pr = 1.0
        for p in (q for q in ps if q < cut and q not in bad):
            pr /= 1 - a[p] * p ** -s + p ** (1 - 2 * s)
        prods.append(pr)
        sums.append(sum(an[n] * n ** -s for n in range(1, cut)))
    print(f"s = {s}: product over p < 100, 1000, 10000: {', '.join(f'{v:.9f}' for v in prods)}")
    print(f"s = {s}: series over n < 100, 1000, 10000:  {', '.join(f'{v:.9f}' for v in sums)}")
    assert abs(prods[2] - sums[2]) < (1e-4 if s == 2 else 1e-8)
for sigma in (1.25, 2):
    part = [sum(abs(a[p]) * p ** -sigma for p in ps if p < cut) for cut in (100, 1000, 10000)]
    print(f"sum of |a_p| p^-sigma, sigma = {sigma}, p < 100, 1000, 10000: {', '.join(f'{v:.4f}' for v in part)}")

def ratios(coef, N):                           # F(1/(N y)) / (N y^2 F(y)) at two y's
    F = lambda y: sum(coef[n] * math.exp(-2 * math.pi * n * y) for n in range(1, 4000))
    return [F(math.sqrt(N) / (N * t)) / (t * t * F(t / math.sqrt(N))) for t in (1.1, 1.3)]

def scan(coef):                                # every 2^i 3^j, i <= 8, j <= 5
    return [2 ** i * 3 ** j for i in range(9) for j in range(6)
            if all(abs(abs(r) - 1) < 1e-9 for r in ratios(coef, 2 ** i * 3 ** j))]

passed, w = scan(an), ratios(an, 1728)
print(f"conductor scan, N = 2^i 3^j with i <= 8, j <= 5 (54 tries): symmetry holds only at {passed}; "
      f"sign w = {w[0]:.9f}, {w[1]:.9f}")
assert passed == [1728] and abs(w[0] + 1) < 1e-9
assert all(a[p] ** 2 <= 4 * p for p in ps) and a[7] == 1 and a[13] == -5
wrong = an[:]                                  # mistake 3: 1 + pT^2 at 2 and 3
for n in range(2, X):
    for p in bad:
        k = next(j for j in range(20) if n % p ** (j + 1))
        if k:
            wrong[n] = 0 if k % 2 else wrong[n // p ** k] * (-p) ** (k // 2)
            break
print(f"mistake 1, factor 1 + pT^2 at a bad prime: F_p^2 counts {predicted(2, 0, 2, 2)} at p = 2 "
      f"(true {count_over_field(2, 2)}) and {predicted(3, 0, 3, 2)} at p = 3 (true {count_over_field(3, 2)}); s = 2 "
      f"factors {' and '.join(str(Fraction(p ** 4, p ** 4 + p)) for p in bad)}, not {at2[0]}")
print(f"mistake 2, dropping pT^2 at p = 5: F_25 count {predicted(5, 0, 0, 2)} (true {count_over_field(5, 2)}); "
      f"s = 2 factor {Fraction(5 ** 2, 5 ** 2 - a[5])}, not {at2[2]}")
print(f"mistake 3, those bad factors in the scan: ratio at N = 1728 is {ratios(wrong, 1728)[0]:.6f}, "
      f"not -1; scan passes {scan(wrong)}")
print("ALL CHECKS PASS")
