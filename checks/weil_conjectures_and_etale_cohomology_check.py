# The Weil conjectures -- the check behind the card.  The curve y^2 = x^3 - x
# over F_5, a genus-2 curve, the projective plane and a singular cubic.  Point
# counts over F_(5^n) are made by brute force in fields built here; the zeta
# function Z(t) = exp(sum N_n t^n / n) is expanded in exact fractions and set
# against the rational function the Weil conjectures predict.
from fractions import Fraction as Fr
from itertools import product
from math import atan2, cos

def pmod(a, m, p):                           # remainder of a by the monic m, mod p
    a = a[:]
    for i in range(len(a) - 1, len(m) - 2, -1):
        c = a[i] % p
        for j in range(len(m)):
            a[i - len(m) + 1 + j] -= c * m[j]
    return [x % p for x in a[:len(m) - 1]]

def monics(p, d):                            # every monic polynomial of degree d
    return [[(n // p ** i) % p for i in range(d)] + [1] for n in range(p ** d)]

def modulus(p, k):                           # a monic of degree k with no factor of degree <= k/2
    return next(m for m in monics(p, k) if all(any(pmod(m, g, p))
                for d in range(1, k // 2 + 1) for g in monics(p, d)))

def mul(a, b, m, p):                         # multiply two elements of F_(p^k)
    c = [0] * (2 * len(a) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            c[i + j] += x * y
    return pmod(c, m, p)

def power(a, e, m, p):
    out = [1] + [0] * (len(a) - 1)
    while e:
        if e & 1:
            out = mul(out, a, m, p)
        a, e = mul(a, a, m, p), e >> 1
    return out

def count(f, p, k):                          # points of y^2 = f(x) over F_(p^k), one at infinity
    m, Q = modulus(p, k), p ** k
    one, total = [1] + [0] * (k - 1), 1
    for n in range(Q):
        x, v = [(n // p ** i) % p for i in range(k)], [0] * k
        for c in f:                          # Horner, coefficients leading term first
            v = mul(v, x, m, p)
            v[0] = (v[0] + c) % p
        total += 1 if not any(v) else (2 if power(v, (Q - 1) // 2, m, p) == one else 0)
    return total

def zeta_from_counts(N):                     # n z_n = sum_k N_k z_(n-k), from Z' = Z (log Z)'
    z = [Fr(1)]
    for n in range(1, len(N) + 1):
        z.append(sum(N[k - 1] * z[n - k] for k in range(1, n + 1)) / n)
    return z

def counts_from_zeta(z):                     # the same identity, solved for N_n
    N = []
    for n in range(1, len(z)):
        N.append(n * z[n] - sum(N[k - 1] * z[n - k] for k in range(1, n)))
    return N

def expand(num, roots, n):                   # num(t) / prod (1 - r t), terms t^0 .. t^n
    s = [Fr(c) for c in (num + [0] * (n + 1))[:n + 1]]
    for r in roots:
        for i in range(1, n + 1):
            s[i] += r * s[i - 1]
    return s

def numerator(z, q, g):                      # P(t) = Z(t)(1 - t)(1 - qt): g terms, then symmetry
    w = [z[i] - (1 + q) * (z[i - 1] if i else 0) + q * (z[i - 2] if i > 1 else 0) for i in range(g + 1)]
    return w + [q ** (g - i) * w[i] for i in range(g - 1, -1, -1)]          # exact fractions, no rounding

def Z(num, roots, t):                        # the rational function at a fraction t
    out = sum(c * t ** i for i, c in enumerate(num))
    for r in roots:
        out /= 1 - r * t
    return out

poly = lambda c: " + ".join(f"{x}t^{i}" if i else str(x) for i, x in enumerate(c) if x).replace("t^1 ", "t ")
bet = lambda num, roots, d: [max(i for i, c in enumerate(num) if c) if i % 2 else roots.count(q ** (i // 2)) for i in range(2 * d + 1)]

q, K = 5, 4
NE = [count([1, 0, -1, 0], q, k) for k in range(1, K + 1)]         # y^2 = x^3 - x, by brute force
a = q + 1 - NE[0]
PE = numerator(zeta_from_counts(NE[:1]), q, 1)                    # P(t) from the one count over F_5
FE = numerator(zeta_from_counts(NE[:2]), q, 2)[:3]                # P(t) read from two counts, no symmetry imposed
predE = [int(c) for c in counts_from_zeta(expand(PE, [1, q], K))]
im = next(s for s in range(q) if 4 * s * s == 4 * q - a * a)      # alpha = a/2 +- i s
print(f"y^2 = x^3 - x, counted over F_5, F_25, F_125, F_625: {NE}")
print(f"over F_5, x^3 - x for x = 0..4: {[(x ** 3 - x) % q for x in range(q)]}; squares mod 5: {sorted({y * y % q for y in range(q)})}")
print(f"a = 5 + 1 - {NE[0]} = {a}; P(t) = {poly(PE)}; Z(t) = P(t) / ((1 - t)(1 - 5t))")
print(f"counts predicted from F_5 alone: {predE}")
print(f"F_25 by hand: 25 + 1 - (a^2 - 2q) = 26 - ({a * a} - 10) = {26 - (a * a - 10)}")
print(f"reciprocal roots {a // 2} +- {im}i, size^2 {(a // 2) ** 2 + im * im}; roots of P: t = ({a // 2} -+ {im}i)/{q}, size {q ** -0.5:.6f}")
s = [2, a]                                                        # s_n = alpha^n + beta^n
for n in range(2, 13):
    s.append(a * s[-1] - q * s[-2])
e = [-s[n] / (2 * q ** (n / 2)) for n in range(1, 13)]           # error over its allowance
th = atan2(im, a / 2)
print("chart, (N_n - 5^n - 1)/(2 * 5^(n/2)), n = 1..12: " + ", ".join(f"{x:.4f}" for x in e))
print(f"N_12 = {q ** 12 + 1 - s[12]}; largest |error/allowance| {max(abs(x) for x in e):.4f}; angle of alpha {th * 57.29577951308232:.4f} degrees")
for t in (Fr(2), Fr(1, 3)):
    print(f"functional equation, t = {t}: Z(t) = {Z(FE, [1, q], t)}, Z(1/(5t)) = {Z(FE, [1, q], 1 / (q * t))}")
N2 = [count([1, 0, 0, 0, 1, 1], q, k) for k in range(1, K + 1)]  # y^2 = x^5 + x + 1, genus 2
P2 = numerator(zeta_from_counts(N2[:2]), q, 2)
pred2 = [int(c) for c in counts_from_zeta(expand(P2, [1, q], K))]
sq = [sum([1, 0, 5][j] * [1, 0, 5][i - j] for j in range(3) if 0 <= i - j < 3) for i in range(5)]
print(f"genus 2, y^2 = x^5 + x + 1: counted {N2}; P(t) = {poly(P2)}; (1 + 5t^2)^2 = {poly(sq)}")
print(f"genus 2 counts predicted from F_5 and F_25: {pred2}")
t0, F2 = Fr(1, 2), numerator(zeta_from_counts(N2), q, 4)[:5]   # P(t) from four counts, no symmetry imposed
r2 = Z(F2, [1, q], 1 / (q * t0)) / Z(F2, [1, q], t0)
print(f"genus 2 functional equation at t = 1/2: Z(1/(5t)) / Z(t) = {r2}; 1/(5t^2) = {1 / (q * t0 * t0)}")
NP = [1 + q ** n + q ** (2 * n) for n in range(1, K + 1)]
cls = len({min(tuple(l * c % q for c in v) for l in range(1, q))
           for v in product(range(q), repeat=3) if any(v)})          # lines through 0 in F_5^3
zP, eP = zeta_from_counts(NP), expand([1], [1, q, q * q], K)
print(f"P^2 over F_5: {cls} classes of nonzero triples; 1 + q^n + q^2n = {NP}")
print(f"P^2 zeta from counts {[int(c) for c in zP]}; 1/((1-t)(1-5t)(1-25t)) {[int(c) for c in eP]}")
lP, rP = Z([1], [1, q, q * q], Fr(1, 50)), -125 * 8 * Z([1], [1, q, q * q], Fr(2))
print(f"P^2 functional equation at t = 2: Z(1/(25t)) = {lP}, -125 t^3 Z(t) = {rP}")
print(f"deg P_i = b_i: genus 1 {bet(FE, [1, q], 1)}; genus 2 {bet(F2, [1, q], 1)}; P^2 {bet([1], [1, q, q * q], 2)}")
NS = [count([1, 1, 0, 0], q, k) for k in (1, 2)]                 # y^2 = x^3 + x^2, a node at (0, 0)
wS = int(counts_from_zeta(expand(numerator(zeta_from_counts(NS[:1]), q, 1), [1, q], 2))[1])   # the genus-1 rule
print(f"mistake, singular y^2 = x^3 + x^2: counted {NS}; smooth-curve rule predicts {wS} over F_25")
print(f"  its zeta is 1/(1 - 5t): Z(2) = {Z([1], [q], Fr(2))}, Z(1/10) = {Z([1], [q], Fr(1, 10))}")
NO = NE[0] - 1                                                    # forgetting O
print(f"mistake, O left out: a = 5 + 1 - {NO} = {q + 1 - NO}, F_25 predicted {26 - ((q + 1 - NO) ** 2 - 2 * q)}")
print(f"mistake, alpha^2 + beta^2 read as a^2: F_25 predicted {26 - a * a}")
z25 = 1 + sum(1 for x in range(25) for y in range(25) if (y * y - x ** 3 + x) % 25 == 0)
print(f"mistake, integers mod 25 for F_25: {z25} points")
assert NE == predE == [8, 32, 104, 640]                          # rationality: one count fixes all
assert N2 == pred2 and P2 == sq                                  # genus 2: two counts fix all
assert a * a < 4 * q and FE[2] == q                              # Riemann hypothesis, genus 1: alpha beta = q
assert all(abs(x + cos((n + 1) * th)) < 1e-12 for n, x in enumerate(e)) and max(map(abs, e)) <= 1
assert all(Z(FE, [1, q], t) == Z(FE, [1, q], 1 / (q * t)) for t in (Fr(2), Fr(1, 3)))
assert r2 == 1 / (q * t0 * t0) and lP == rP                      # functional equations
assert cls == NP[0] and zP == eP                                 # P^2: brute count, and the product
assert NS[1] != wS and z25 != NE[1]                              # the singular curve and Z/25 fail
print("ALL CHECKS PASS")
