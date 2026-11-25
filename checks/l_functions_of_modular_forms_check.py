# L-functions of modular forms -- the check behind the card.  Standard library only.
# f = q prod (1 - q^n)^2 (1 - q^(11n))^2, weight 2, level 11; q = e^(2 pi i z), not a modulus.
# Lambda(s) = (sqrt 11 / 2 pi)^s Gamma(s) L(f, s) is the completed L-function, not von Mangoldt.
from math import pi, exp, sqrt, gcd, cos, sin
from fractions import Fraction
M, K = 2000, 600                      # coefficients to q^M; K terms for numerical series
c = [1] + [0] * M                     # road 1 to a_n: multiply out the product
for m in range(1, M + 1):
    for step in ([m, m, 11 * m, 11 * m] if 11 * m <= M else [m, m]):
        for i in range(M, step - 1, -1):
            c[i] -= c[i - step]
a = [0] + c[:M]                       # f = q * c, so a_n = c[n - 1]
primes = [p for p in range(2, M + 1) if all(p % d for d in range(2, int(p ** 0.5) + 1))]
def count(p):                         # points of y^2 + y = x^3 - x^2 over F_p, O included
    ways = [0] * p
    for y in range(p): ways[(y * y + y) % p] += 1
    return 1 + sum(ways[(x ** 3 - x * x) % p] for x in range(p))
def fmt(v): return f"{v:.9f}"
print("a_1..a_13 from the product:", a[1:14])
print("#E(F_p) for p = 2, 3, 5, 7, 11, 13:", [count(p) for p in (2, 3, 5, 7, 11, 13)])
ap = {p: p + 1 - count(p) for p in primes}          # road 2 to a_p: count points
assert [ap[p] for p in (2, 3, 5, 7, 13)] == [-2, -1, 1, -2, 4] == [a[p] for p in (2, 3, 5, 7, 13)]
assert all(ap[p] == a[p] for p in primes)
worst = max(abs(a[p]) / (2 * sqrt(p)) for p in primes if p != 11)
print(f"a_p = p + 1 - #E(F_p) for all {len(primes)} primes below {M}: yes; max |a_p|/(2 sqrt p) = {worst:.6f}")
assert worst <= 1
pairs = sum(1 for m in range(2, M + 1) for n in range(m + 1, M // m + 1) if gcd(m, n) == 1)
assert all(a[m * n] == a[m] * a[n] for m in range(2, M + 1) for n in range(m + 1, M // m + 1) if gcd(m, n) == 1)
steps = 0
for p in primes:
    q, r = p, p * p
    while r <= M:
        want = a[p] * a[q] - (0 if p == 11 else p) * a[q // p]
        assert a[r] == want; steps += 1; q, r = r, r * p
print(f"Hecke rules to {M}: {pairs} coprime pairs, {steps} prime-power steps, all hold; a_121 = {a[121]}, a_1331 = {a[1331]}")
e = [1, -2]                           # 1/(1 + 2X + 2X^2) as a series in X = 2^(-s)
while len(e) < 11: e.append(-2 * e[-1] - 2 * e[-2])
print("Euler factor at 2, series:", e, "; a_(2^k):", [a[2 ** k] for k in range(11)])
assert e == [a[2 ** k] for k in range(11)]
print("Euler factor at 2, s = 2:", 1 / (1 + Fraction(2, 4) + Fraction(2, 16)))
print("mistake, good-prime factor at 11: predicts a_121 =", a[11] ** 2 - 11, "but a_121 =", a[121])
b = [0] + [a[n] + (a[n // 2] if n % 2 == 0 else 0) for n in range(1, 9)]   # f(z) + f(2z), level 22
print(f"mistake, oldform f(z) + f(2z) at level 22: b_2 = {b[2]}, b_4 = {b[4]}; an Euler factor needs {b[2] ** 2} or {b[2] ** 2 - 2}")
def genus(N):                         # dim S_2(Gamma_0(N)) = genus of X_0(N)
    ps = [p for p in primes if N % p == 0]
    mu = N
    for p in ps: mu = mu * (p + 1) // p
    v2 = 0 if N % 4 == 0 else sum(1 for x in range(N) if (x * x + 1) % N == 0)
    v3 = 0 if N % 9 == 0 else sum(1 for x in range(N) if (x * x + x + 1) % N == 0)
    vc = sum(sum(1 for k in range(1, g + 1) if gcd(k, g) == 1) for d in range(1, N + 1) if N % d == 0 for g in [gcd(d, N // d)])
    return 1 + Fraction(mu, 12) - Fraction(v2, 4) - Fraction(v3, 3) - Fraction(vc, 2)
print("dim S_2(Gamma_0(N)) by the genus formula: N = 11:", genus(11), "; N = 22:", genus(22))
assert genus(11) == 1 and genus(22) == 2
def fz(z):                            # f(z) = sum a_n q^n at a point of the upper half plane
    q = complex(exp(-2 * pi * z.imag) * cos(2 * pi * z.real), exp(-2 * pi * z.imag) * sin(2 * pi * z.real))
    s, w = 0j, 1 + 0j
    for n in range(1, K + 1): w *= q; s += a[n] * w
    return s
def cs(w): return f"{w.real:.9f} {'+' if w.imag >= 0 else '-'} {abs(w.imag):.9f}i"
z = complex(0.1, 0.4)
L, R = fz(-1 / (11 * z)), -11 * z * z * fz(z)
print("z = 0.1 + 0.4i: f(-1/(11z)) =", cs(L), "; -11 z^2 f(z) =", cs(R))
assert abs(L - R) < 1e-10
print("mistake, level-1 flip: f(-1/z) =", cs(fz(-1 / z)), "; z^2 f(z) =", cs(z * z * fz(z)))
def g(y):                             # f on the imaginary axis, a real number
    x, w, s = exp(-2 * pi * y), 1.0, 0.0
    for n in range(1, K + 1): w *= x; s += a[n] * w
    return s
h, us = 0.05, [-4.2 + 0.05 * j for j in range(133)]   # road A: the whole Mellin integral, u = log y
gs = [g(exp(u)) for u in us]
def lam_direct(s): return 11 ** (s / 2) * h * sum(v * exp(s * u) for v, u in zip(gs, us))
def gam_inc(s, x):                    # Gamma(s, x) by its continued fraction
    bb = x + 1 - s; cc = 1e300; d = 1 / bb; hh = d
    for i in range(1, 300):
        an = -i * (i - s); bb += 2; d = 1 / (an * d + bb); cc = bb + an / cc; hh *= d * cc
    return exp(-x) * x ** s * hh
def lam_split(s):                     # road B: the proof's formula, only y above 1/sqrt 11
    tot = 0.0
    for n in range(1, 41):
        cn = 2 * pi * n / sqrt(11)
        tot += a[n] * (cn ** -s * gam_inc(s, cn) + cn ** (s - 2) * gam_inc(2 - s, cn))
    return tot
sq = sqrt(pi)
rg = {-1: 0, -0.5: -0.5 / sq, 0: 0, 0.5: 1 / sq, 1: 1, 1.5: 2 / sq, 2: 1, 2.5: 4 / (3 * sq), 3: 0.5}   # 1/Gamma(s)
print("s, Lambda by the whole integral, by the split formula, L(f, s):")
for s in sorted(rg):
    A, B = lam_direct(s), lam_split(s)
    print(f"{s:5.1f}: {fmt(A)} {fmt(B)} {fmt(A * (2 * pi / sqrt(11)) ** s * rg[s])}")
    assert abs(A - B) < 1e-9 and abs(A - lam_direct(2 - s)) < 1e-9
dir3 = (sqrt(11) / (2 * pi)) ** 3 * 2 * sum(a[n] / n ** 3 for n in range(1, M + 1))
eul = 1.0
for p in primes: eul /= (1 - a[p] * p ** -3 + (0 if p == 11 else p * p ** -6))
eul3 = (sqrt(11) / (2 * pi)) ** 3 * 2 * eul
print(f"Lambda(3) by the Dirichlet series to {M}: {dir3:.7f}; by the Euler product to {M}: {eul3:.7f}")
assert abs(dir3 - lam_direct(3)) < 1e-6 and abs(eul3 - lam_direct(3)) < 1e-6
L1 = 2 * sum(a[n] / n * exp(-2 * pi * n / sqrt(11)) for n in range(1, 41))
print("L(f, 1) = 2 sum (a_n/n) e^(-2 pi n/sqrt 11) =", fmt(L1))
assert abs(L1 - lam_direct(1) * 2 * pi / sqrt(11)) < 1e-9
print("mistake, no sqrt 11 in Lambda: s = 0.5 gives", fmt(11 ** -0.25 * lam_direct(0.5)), "; s = 1.5 gives", fmt(11 ** -0.75 * lam_direct(1.5)))
true5 = lam_direct(0.5) * (2 * pi / sqrt(11)) ** 0.5 / sq
part = [sum(a[n] / sqrt(n) for n in range(1, N + 1)) for N in (500, 1000, 2000)]
print("mistake, the series at s = 0.5, partial sums to 500, 1000, 2000:", ", ".join(f"{v:.3f}" for v in part), "; L(f, 0.5) =", fmt(true5))
print("ALL CHECKS PASS")
