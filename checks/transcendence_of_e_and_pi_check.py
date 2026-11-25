# Transcendence of e and pi -- the check behind the card.  Standard library only;
# math gives exp, log10, cos, sin, sqrt and pi as tools.  Every number on the card
# is printed here.  Test relation: a e^2 + b e + c = 0 with (a, b, c) = (1, -7, 12).
# Hermite's polynomial: f(x) = x^(p-1) (x - 1)^p (x - 2)^p, p a prime.
# Roads: (1) the sum of all derivatives F(k) by a recurrence on f's coefficients,
# (2) the same F(k) by shifting f to k (Taylor coefficients times j!),
# (3) Hermite's integral by Simpson's rule against the integration-by-parts identity.
import math, fractions
A, B, C = 1, -7, 12
E = math.exp(1)

def mul(f, g):                      # product of two coefficient lists, lowest power first
    out = [0] * (len(f) + len(g) - 1)
    for i, x in enumerate(f):
        for j, y in enumerate(g):
            out[i + j] += x * y
    return out

def power(f, n):
    out = [1]
    for _ in range(n):
        out = mul(out, f)
    return out

def hermite(p, shift=0):            # coefficients of f(x + shift)
    f = power([shift, 1], p - 1)
    for k in (1, 2):
        f = mul(f, power([shift - k, 1], p))
    return f

def big_f_road1(p, k):              # F(k) = sum_i c_i S_i, S_i = k^i + i S_(i-1)
    s, total = 0, 0
    for i, c in enumerate(hermite(p)):
        s = k ** i + i * s
        total += c * s
    return total

def big_f_road2(p, k):              # F(k) = sum_j j! t_j, t_j the coefficients of f(k + y)
    total, fact = 0, 1
    for j, t in enumerate(hermite(p, k)):
        total += fact * t
        fact *= j + 1
    return total

def fact(n):
    out = 1
    for m in range(2, n + 1):
        out *= m
    return out

def f_value(u, p):
    out = 1.0
    for _ in range(p - 1):
        out *= u
    for _ in range(p):
        out *= (u - 1) * (u - 2)
    return out

def hermite_integral(k, p, n=4000):  # I(k) = integral from 0 to k of e^(k - u) f(u) du
    h, s = k / n, 0.0
    for i in range(n + 1):
        w = 1 if i in (0, n) else (4 if i % 2 else 2)
        s += w * math.exp(k - i * h) * f_value(i * h, p)
    return s * h / 3

def sci(x):                          # 4 significant digits, the same in both languages
    if x == 0:
        return "0"
    ex = math.floor(math.log10(abs(x)))
    m = x / 10 ** ex
    if abs(m) >= 9.9995:
        m, ex = m / 10, ex + 1
    return f"{m:.3f}e{ex}"

def big_n(p, a, b, c):               # N = c F(0) + b F(1) + a F(2), by both roads
    n1 = c * big_f_road1(p, 0) + b * big_f_road1(p, 1) + a * big_f_road1(p, 2)
    n2 = c * big_f_road2(p, 0) + b * big_f_road2(p, 1) + a * big_f_road2(p, 2)
    assert n1 == n2                  # road 1 against road 2, exact integers
    return n1

print(f"e = {E:.12f}; e^2 - 7e + 12 = {E * E - 7 * E + 12:.6f}")
for h in (2, 12):
    best = min((abs(a * E * E + b * E + c), a, b, c) for a in range(-h, h + 1)
               for b in range(-h, h + 1) for c in range(-h, h + 1) if (a, b, c) != (0, 0, 0))
    print(f"closest triple with every |coefficient| <= {h}: ({best[1]}, {best[2]}, {best[3]}) gives {best[0]:.6f}")
f3 = hermite(3)
print(f"p = 3: f = {f3} (lowest power first); F(0), F(1), F(2) = "
      f"{big_f_road1(3, 0)}, {big_f_road1(3, 1)}, {big_f_road1(3, 2)}")
for k in (1, 2):
    lhs, rhs = hermite_integral(k, 3), E ** k * big_f_road1(3, 0) - big_f_road1(3, k)
    print(f"p = 3, k = {k}: Simpson integral {lhs:.9f}; e^k F(0) - F(k) = {rhs:.9f}")
    assert abs(lhs - rhs) < 1e-9     # integration by parts against numerical integration
n13 = big_n(13, A, B, C)
print(f"p = 13: N = {n13} ({len(str(n13))} digits); 2^13 = {2 ** 13}")
print(f"N / 12! = {n13 // fact(12)}, remainder {n13 % fact(12)}; (N / 12!) mod 13 = {n13 // fact(12) % 13}")
assert n13 % fact(12) == 0 and n13 // fact(12) % 13 != 0      # divisible by 12!, not by 13!
j13 = B * hermite_integral(1, 13) + A * hermite_integral(2, 13)
print(f"p = 13: J = c I(0) + b I(1) + a I(2) = {sci(j13)}; 12! = {fact(12):,}")
assert 0 < abs(j13) < 1                                        # far below 12!
def exact_i(k): return float(sum(fractions.Fraction(k ** j, fact(j)) for j in range(71)) * big_f_road1(13, 0) - big_f_road1(13, k))
for v, x in ((hermite_integral(1, 13), exact_i(1)), (hermite_integral(2, 13), exact_i(2)), (j13, C * exact_i(0) + B * exact_i(1) + A * exact_i(2))):
    assert abs(v - x) < 1e-9 * abs(x)   # Simpson at p = 13 against e^k F(0) - F(k), e^k summed exactly to 70 terms
print(f"F(1)/F(0) - e = {sci(-hermite_integral(1, 13) / big_f_road1(13, 0))}; "
      f"F(2)/F(0) - e^2 = {sci(-hermite_integral(2, 13) / big_f_road1(13, 0))}")
print(f"crude constant |b| e + 2|a| e^2 = {abs(B) * E + 2 * abs(A) * E * E:.2f}, half of it {(abs(B) * E + 2 * abs(A) * E * E) / 2:.2f}; "
      f"largest |x(x-1)(x-2)| on [0, 2] = 2/(3 sqrt 3) = {2 / (3 * math.sqrt(3)):.3f}")
print("p, N divisible by (p-1)!, (N/(p-1)!) mod p, log10 (p-1)!, log10 crude bound, log10 |J|")
chart = []
for p in (3, 5, 7, 11, 13, 17, 19, 23):
    n = big_n(p, A, B, C)
    crude = (abs(B) * E + 2 * abs(A) * E * E) * 2 ** (2 * p - 1)
    j = B * hermite_integral(1, p) + A * hermite_integral(2, p)
    row = (math.log10(fact(p - 1)), math.log10(crude), math.log10(abs(j)))
    chart.append(row)
    print(f"{p}, {'yes' if n % fact(p - 1) == 0 else 'no'}, {n // fact(p - 1) % p}, "
          f"{row[0]:.2f}, {row[1]:.2f}, {row[2]:.2f}")
print(f"first prime past 12 where the crude bound is below (p-1)!: "
      f"{[p for p, r in zip((3, 5, 7, 11, 13, 17, 19, 23), chart) if p > 12 and r[1] < r[0]][0]}")
assert chart[4][1] > chart[4][0] and chart[5][1] < chart[5][0]  # crude bound crosses at 17
n0 = big_n(13, 1, -7, 0)
print(f"mistake, c = 0: (N/12!) mod 13 = {n0 // fact(12) % 13}; p = 3 dividing c = 12: "
      f"(N/2!) mod 3 = {big_n(3, A, B, C) // 2 % 3}")
print(f"sqrt(pi) = {math.sqrt(math.pi):.6f}; |1 + e^(i pi)| below 1e-15: "
      f"{'yes' if abs(1 + complex(math.cos(math.pi), math.sin(math.pi))) < 1e-15 else 'no'}")
print(f"stand-in i sqrt10 for i pi, sqrt 10 = {math.sqrt(10):.6f}: (1 + e^(i r))(1 + e^(-i r)) = 2 + 2 cos(sqrt 10) = {2 + 2 * math.cos(math.sqrt(10)):.6f}")
r, w = 2 ** (1 / 3), complex(math.cos(2 * math.pi / 3), math.sin(2 * math.pi / 3))
roots = [r, r * w, r * w * w]
sums = [sum(t for i, t in enumerate(roots) if m >> i & 1) for m in range(8)]
nonzero = [s for s in sums if abs(s) > 1e-9]
poly = [complex(1)]
for s in nonzero:
    poly = mul(poly, [-s, 1])
rounded = [round(z.real) for z in poly]
print(f"roots of x^3 - 2: 8 subset sums, {8 - len(nonzero)} of them 0; the other {len(nonzero)} "
      f"solve {rounded} (lowest power first)")
assert rounded == mul([-2, 0, 0, 1], [2, 0, 0, 1])             # equals (x^3 - 2)(x^3 + 2)
assert max(abs(z - k) for z, k in zip(poly, rounded)) < 1e-9
print("ALL CHECKS PASS")
