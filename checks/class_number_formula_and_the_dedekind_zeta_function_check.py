# The class number formula -- the check behind the card.  Standard library only.
# Field K = Q(sqrt-5): discriminant d = -20, w = 2 units (+1 and -1), regulator 1.
# Road 1 counts reduced quadratic forms of discriminant d: one per ideal class.
# Road 2 reads h off the L-value: partial sums of chi(n)/n, then h = w sqrt|d| L / (2 pi).
# Road 3 is the finite sum h = -(w / 2|d|) * (sum of chi(a) a for a = 1 to |d|).
# Road 4 counts ideals of norm <= X two ways (divisor sums of chi; lattice points of
# the forms) and sets the count beside residue times X.  chi comes from Euler's criterion.
from fractions import Fraction as F
from math import isqrt, pi, sqrt, log

def kronecker(d, n):                   # (d/n), d a field discriminant, n >= 1, by factoring n
    out, p = 1, 2
    while n > 1:
        if p * p > n:
            p = n
        while n % p == 0:
            n //= p
            if p == 2:
                out *= 0 if d % 2 == 0 else (1 if d % 8 in (1, 7) else -1)
            else:
                r = pow(d % p, (p - 1) // 2, p)      # Euler's criterion
                out *= -1 if r == p - 1 else r
        p += 1
    return out

def reduced_forms(d):                  # (a, b, c), b^2 - 4ac = d, |b| <= a <= c, b >= 0 on the edges
    out = []
    for a in range(1, isqrt(-d // 3) + 1):
        for b in range(-a + 1, a + 1):
            if (b * b - d) % (4 * a) == 0:
                c = (b * b - d) // (4 * a)
                if c >= a and not (a == c and b < 0):
                    out.append((a, b, c))
    return out

def finite_h(d, w):                    # road 3
    return -F(w, 2 * abs(d)) * sum(kronecker(d, a) * a for a in range(1, abs(d) + 1))

def L1(d, N):                          # road 2: chi(1)/1 + ... + chi(N)/N, chi from one period
    per = [kronecker(d, a) for a in range(1, abs(d) + 1)]
    return sum(per[(n - 1) % abs(d)] / n for n in range(1, N + 1))

def points(form, X):                   # (x, y) with a x^2 + b x y + c y^2 <= X, origin included
    a, b, c = form
    D, tot, y = 4 * a * c - b * b, 0, 0
    while D * y * y <= 4 * a * X:      # 4a Q = (2ax + by)^2 + D y^2
        m, r = isqrt(4 * a * X - D * y * y), (b * y) % (2 * a)
        k = (m - r) // (2 * a) - (-m - 1 - r) // (2 * a)
        tot, y = tot + (k if y == 0 else 2 * k), y + 1
    return tot

d, w = -20, 2
chi = [kronecker(d, a) for a in range(1, 21)]
periodic = all(kronecker(d, n) == chi[(n - 1) % 20] for n in range(21, 4001))
print(f"field Q(sqrt-5): d = {d}, w = {w}; chi(a) for a = 1..20: {chi}")
print(f"chi repeats with period 20 for n up to 4000: {'yes' if periodic else 'no'}")
kind = {1: "split", -1: "inert", 0: "ramified"}
print("primes: " + ", ".join(f"{p} {kind[kronecker(d, p)]}" for p in (2, 3, 5, 7, 11, 13, 23, 29)))
forms = reduced_forms(d)
an = [sum(kronecker(d, e) for e in range(1, n + 1) if n % e == 0) for n in range(1, 21)]
def reps(f, n): return points(f, n) - points(f, n - 1)
prin, nonp = [reps(forms[0], n) // w for n in range(1, 21)], [reps(forms[1], n) // w for n in range(1, 21)]
print(f"ideals of norm n, n = 1..20: {an}")
print(f"  principal (x^2 + 5y^2):    {prin}")
print(f"  other class (2x^2+2xy+3y^2): {nonp}")
six = [(x, y) for x in range(-3, 4) for y in range(-2, 3) if x * x + 5 * y * y == 6]
print(f"elements of norm 6: {six}; ideals {len(six) // w}")
h1 = len(forms)
print(f"road 1, reduced forms of discriminant -20: {forms}; h = {h1}")
for N in (100, 10 ** 4, 10 ** 6):
    print(f"road 2, L(1, chi) summed to N = {N:>7}: {L1(d, N):.6f}")
L, exact = L1(d, 10 ** 6), 2 * pi / sqrt(20)
h2 = w * sqrt(20) * L / (2 * pi)
h3 = finite_h(d, w)
print(f"        2 pi / sqrt 20 = {exact:.6f}; h = w sqrt|d| L / (2 pi) = {h2:.5f}")
print(f"road 3, -(2/40) * sum chi(a) a = -(1/20) * {sum(c * a for a, c in enumerate(chi, 1))} = {h3}")
kappa = 2 * pi * h1 / (w * sqrt(20))
print(f"residue of zeta_K at 1: 2 pi h / (w sqrt 20) = {kappa:.6f}")
print(f"lattice cell area sqrt20 / 2 = {sqrt(20) / 2:.5f}; share of one class 2 pi / (w sqrt 20) = {kappa / h1:.5f}")
print("road 4, ideals of norm <= X: X, by divisor sums, by lattice points, count/X, count - kappa X, principal/X")
ratios, prat = [], []
for X in (10, 100, 1000, 10 ** 4, 10 ** 5, 10 ** 6):
    S = sum(chi[(e - 1) % 20] * (X // e) for e in range(1, X + 1))
    lat = sum(points(f, X) - 1 for f in forms) // w
    P = (points(forms[0], X) - 1) // w
    ratios.append(S / X); prat.append(P / X)
    print(f"  {X:>7} {S:>8} {lat:>8} {S / X:.5f} {S - kappa * X:>9.2f} {P / X:.5f}")
    assert S == lat, "the two ideal counts must agree exactly"
NZ = 10 ** 5
a_sieve = [0] * (NZ + 1)
for e in range(1, NZ + 1):
    for m in range(e, NZ + 1, e):
        a_sieve[m] += chi[(e - 1) % 20]
series = sum(a_sieve[n] / n ** 2 for n in range(1, NZ + 1))
sieve = [True] * (NZ + 1)
prod = 1.0
for p in range(2, NZ + 1):
    if sieve[p]:
        for m in range(p * p, NZ + 1, p): sieve[m] = False
        c = kronecker(d, p)
        prod *= 1 / (1 - p ** -2) if c == 0 else (1 / (1 - p ** -2) ** 2 if c == 1 else 1 / (1 - p ** -4))
zL = pi ** 2 / 6 * sum(chi[(n - 1) % 20] / n ** 2 for n in range(1, NZ + 1))
print(f"zeta_K(2): sum a_n/n^2 {series:.5f}; Euler product {prod:.5f}; zeta(2) L(2, chi) {zL:.5f}")
table = [(D, len(reduced_forms(D)), finite_h(D, 6 if D == -3 else 4 if D == -4 else 2))
         for D in (-3, -4, -7, -8, -15, -20, -23, -24, -47, -71, -163)]
print("other fields, d: forms h / finite-sum h: " + ", ".join(f"{D}: {a}/{b}" for D, a, b in table))
L5, R5 = L1(5, 10 ** 6), log((1 + sqrt(5)) / 2)
print(f"mistake, w left out: sqrt 20 L / (2 pi) = {sqrt(20) * L / (2 * pi):.5f}")
print(f"mistake, principal ideals only at X = 10^6: {prat[-1]:.5f} per unit of X; h read as {prat[-1] / kappa * h1:.5f}")
print(f"mistake, Z[sqrt-3] with d = -12 in the finite sum: {finite_h(-12, 2)}; true d = -3, w = 6: {finite_h(-3, 6)}")
print(f"mistake, Q(sqrt5) without the regulator: L(1) = {L5:.5f}, sqrt5 L / 2 = {sqrt(5) * L5 / 2:.5f}; "
      f"R = {R5:.5f}; with R: {sqrt(5) * L5 / (2 * R5):.5f}")
L100 = L1(d, 100)
print(f"mistake, L(1, chi) cut at 100 terms: {L100:.5f}; h read as {w * sqrt(20) * L100 / (2 * pi):.5f}")
print("chart, X: 10^1 .. 10^6; ideals/X " + " ".join(f"{r:.3f}" for r in ratios)
      + "; principal/X " + " ".join(f"{r:.3f}" for r in prat) + f"; kappa {kappa:.3f}")
assert h1 == 2 and h3 == 2 and abs(h2 - 2) < 1e-5, "three roads to h = 2"
assert abs(L - exact) < 5e-6, "partial sums of chi(n)/n must approach 2 pi / sqrt 20"
assert periodic and an[5] == 2 and len(six) == 4
assert [p + q for p, q in zip(prin, nonp)] == an, "ideal counts by class must add to the divisor sums"
assert abs(ratios[-1] - kappa) < 1e-3 and abs(prat[-1] - kappa / 2) < 1e-3
assert abs(series - zL) < 1e-4 and abs(prod - zL) < 1e-4
assert all(a == b for _, a, b in table) and finite_h(-12, 2) == F(2, 3)
assert abs(sqrt(5) * L5 / (2 * R5) - 1) < 1e-5
print("ALL CHECKS PASS")
