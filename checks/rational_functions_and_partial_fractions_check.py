# Rational functions and partial fractions: the check behind the card.  Python
# standard library only; complex numbers are the built-in 1j type.  G is the
# string's response 1/((s^2 + 1)(s^2 + 4)); F = 1/(s^2 + 1)^2 is the second case.
import math
G = lambda s: 1 / ((s * s + 1) * (s * s + 4))
F = lambda s: 1 / (s * s + 1) ** 2
Q = lambda s: s ** 4 + 5 * s * s + 4             # the bottom of G, multiplied out
dQ = lambda s: 4 * s ** 3 + 10 * s               # its derivative
f6 = lambda x: f"{round(x, 6) + 0.0:.6f}"         # six decimals, never -0.000000
def c(z):                                        # a complex number as 'a + bi'
    return f"{f6(z.real)} {'-' if round(z.imag, 6) < 0 else '+'} {f6(abs(z.imag))}i"
def newton(s):                                   # road to the poles: Newton on Q
    for _ in range(60):
        s = s - Q(s) / dQ(s)
    return s
def order(f, p):                                 # how fast |f| grows as the gap to p shrinks 10x
    return round(math.log(abs(f(p + 1e-4)) / abs(f(p + 1e-3))) / math.log(10))
def loop(f, p, k, n=64, r=0.4):                  # (1/2 pi i) x loop integral of f (s - p)^(k - 1)
    tot = 0
    for j in range(n):
        w = r * complex(math.cos(2 * math.pi * j / n), math.sin(2 * math.pi * j / n))
        tot += f(p + w) * w ** k
    return tot / n
poles = [newton(s) for s in (0.3 + 1.3j, 0.3 - 1.3j, 0.3 + 2.4j, 0.3 - 2.4j)]
cover, ring = [1 / dQ(p) for p in poles], [loop(G, p, 1) for p in poles]   # roads one and two
print("G(s) = 1/((s^2 + 1)(s^2 + 4)): top degree 0, bottom degree 4")
for p, a, b in zip(poles, cover, ring):
    print(f"pole {c(p)}: order {order(G, p)}, zero of 1/G of order {-order(lambda s: 1 / G(s), p)};"
          f" Q'(p) {c(dQ(p))}, cover-up {c(a)}, loop {c(b)}")
assert all(abs(a - b) < 1e-12 and order(G, p) == 1 == -order(lambda s: 1 / G(s), p)
           for p, a, b in zip(poles, cover, ring))
pair = [(2 * cover[k].real, -2 * (cover[k] * poles[k].conjugate()).real) for k in (0, 2)]
print(f"pairs: i, -i give s-term {f6(pair[0][0])} and constant {f6(pair[0][1])} over s^2 + 1; "
      f"2i, -2i give {f6(pair[1][0])} and {f6(pair[1][1])} over s^2 + 4")
parts = lambda s: sum(a / (s - p) for p, a in zip(poles, cover))
for s in (3, 1 + 0.5j):
    print(f"at s = {c(s)}: G {c(G(s))}, sum of principal parts {c(parts(s))},"
          f" (1/3)(1/(s^2+1) - 1/(s^2+4)) {c((1 / (s * s + 1) - 1 / (s * s + 4)) / 3)}")
    assert abs(G(s) - parts(s)) < 1e-14 and abs(G(s) - (1 / (s * s + 1) - 1 / (s * s + 4)) / 3) < 1e-14
err = [abs(loop(G, 1j, 1, n) - cover[0]) for n in (4, 8, 16, 24)]
print("loop-sum error at i, 4, 8, 16, 24 points: " + ", ".join(f"{e:.12f}" for e in err))
fd = [(p, 1 / (2 * p) ** 2, -2 / (2 * p) ** 3) for p in (1j, -1j)]   # derivative road: g(p), g'(p)
for p, m2, m1 in fd:
    print(f"F = 1/(s^2 + 1)^2, pole {c(p)}: order {order(F, p)}; c(-2) {c(m2)} (loop {c(loop(F, p, 2))}),"
          f" c(-1) {c(m1)} (loop {c(loop(F, p, 1))})")
    assert order(F, p) == 2 and abs(m2 - loop(F, p, 2)) < 1e-12 and abs(m1 - loop(F, p, 1)) < 1e-12
full = sum(m2 / (3 - p) ** 2 + m1 / (3 - p) for p, m2, m1 in fd)
simple = sum(m1 / (3 - p) for p, m2, m1 in fd)
print(f"F at s = 3: {f6(F(3))}; all principal parts {f6(full.real)}; the 1/(s - p) terms alone {f6(simple.real)}")
top = sum(p ** 4 / dQ(p) / (3 - p) for p in poles)
print(f"mistake, s^4/Q at s = 3: {f6(81 / Q(3))}; principal parts alone {f6(top.real)};"
      f" gap {f6(81 / Q(3) - top.real)}, the quotient of s^4 by Q")
assert abs(top - (-5 * 9 - 4) / Q(3)) < 1e-14   # division: s^4 = 1 x Q + (-5s^2 - 4)
H = lambda s: (s * s + 1) / ((s * s + 1) * (s * s + 4))
print(f"mistake, (s^2 + 1)/Q near i: order {order(H, 1j)}, value at i + 0.000001 {c(H(1j + 1e-6))}")
ws = (0, 0.5, 0.9, 0.95, 1.05, 1.1, 1.5, 1.9, 1.95, 2.05, 2.1, 2.5, 2.8)
print("chart, |G(iw)| at w = 0 ... 2.8: " + ", ".join(f"{abs(G(1j * w)):.2f}" for w in ws))
print("figure, 40 px per unit, origin (180, 120): poles at " + ", ".join(
    f"({180 + 40 * p.real:.0f}, {120 - 40 * p.imag:.0f})" for p in poles) + "; loops of radius 0.4 = 16 px")
print("ALL CHECKS PASS")
