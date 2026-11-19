# The functional equation, proved: the check behind the card.  Standard library only.
# Road 1: the theta integral of Step 4, which works for every s.
# Road 2: zeta by Euler-Maclaurin and gamma by Stirling, both written out, used at s and at 1 - s.
# Road 3: exact zeta values at 0, -1, -2, ... from Bernoulli numbers, as fractions.
import cmath, math
from fractions import Fraction

PI = math.pi
B = [Fraction(1)]                       # Bernoulli numbers B_0 .. B_24, with B_1 = -1/2
for n in range(1, 25):
    B.append(-sum(math.comb(n + 1, k) * B[k] for k in range(n)) / (n + 1))

def W(x):                               # the Gaussian sum over every whole number n
    return 1 + 2 * sum(math.exp(-PI * n * n * x) for n in range(1, 60))

def xi_theta(s, T=20.0, steps=8000):    # road 1: xi(s) = 1/2 + s(s-1)/2 * integral, x = e^u
    h, total = math.log(T) / steps, 0
    for k in range(steps + 1):
        u = k * h
        wt = sum(math.exp(-PI * n * n * math.exp(u)) for n in range(1, 8))
        f = (cmath.exp(s / 2 * u) + cmath.exp((1 - s) / 2 * u)) * wt
        total += f * (1 if k in (0, steps) else 4 if k % 2 else 2)
    return 0.5 + s * (s - 1) / 2 * total * h / 3

def gamma(z):                           # shift right to Re z >= 10, then Stirling's series
    z, p = complex(z), 1
    while z.real < 10:
        p, z = p * z, z + 1
    ln = (z - 0.5) * cmath.log(z) - z + 0.5 * math.log(2 * PI)
    for k in range(1, 8):
        ln += float(B[2 * k]) / (2 * k * (2 * k - 1) * z ** (2 * k - 1))
    return cmath.exp(ln) / p

def zeta_em(s, K=12):                   # road 2: Euler-Maclaurin, any s except 1
    s = complex(s)
    N = 15 if s.real > 0 else 6         # fewer plain terms left of 0, where they cancel
    total = sum(n ** -s for n in range(1, N)) + N ** (1 - s) / (s - 1) + N ** -s / 2
    poch = s
    for k in range(1, K + 1):
        total += float(B[2 * k]) / math.factorial(2 * k) * poch * N ** (-s - 2 * k + 1)
        poch *= (s + 2 * k - 1) * (s + 2 * k)
    return total

def G(s):                               # the gamma factor pi^(-s/2) Gamma(s/2)
    return PI ** (-complex(s) / 2) * gamma(complex(s) / 2)

def xi_em(s):
    return s * (s - 1) / 2 * G(s) * zeta_em(s)

def zeta_from_xi(s):                    # zeta read back from road 1 by dividing out the factors
    return 2 * xi_theta(s) / (s * (s - 1) * G(s))

def c(z, real):                         # print a value; near-zeros print as 0 in both languages
    f = lambda x: f"{0.0 if abs(x) < 5e-7 else x:.6f}"
    return f(z.real) if real else f"{f(z.real)}{'+' if z.imag >= 0 else '-'}{f(abs(z.imag))}i"

print("Poisson: W(1/x) against sqrt(x) W(x)")
for x in (2.0, 10.0):
    print(f"  x = {x:4.1f}   W(1/x) = {W(1 / x):.9f}   sqrt(x) W(x) = {math.sqrt(x) * W(x):.9f}")
    assert abs(W(1 / x) - math.sqrt(x) * W(x)) < 1e-12
print(f"  no sqrt: W(0.5) = {W(0.5):.6f} against W(2) = {W(2.0):.6f}")

print("the mirror: xi at s and at 1 - s")
for name, mirror, s in (("2", "-1", 2), ("4", "-3", 4), ("0.25", "0.75", 0.25), ("2+3i", "-1-3i", 2 + 3j)):
    r1, a, b = xi_theta(complex(s)), xi_em(complex(s)), xi_em(1 - complex(s))
    re = name != "2+3i"
    print(f"  s = {name:>4}, 1-s = {mirror:>5}:  road 1 {c(r1, re)}  road 2 at s {c(a, re)}  at 1-s {c(b, re)}")
    assert abs(r1 - a) < 1e-9 and abs(a - b) < 1e-9
assert abs(xi_theta(2) - PI / 6) < 1e-10 and abs(xi_theta(4) - PI ** 2 / 15) < 1e-10
print(f"  pi/6 = {PI / 6:.6f}   pi^2/15 = {PI ** 2 / 15:.6f}")

print("worked numbers: s = 2 and its mirror s = -1")
z2 = zeta_em(2).real
print(f"  zeta(2) = {z2:.6f}   G(2) = {G(2).real:.6f}   xi(2) = {xi_em(2).real:.6f}")
print(f"  G(-1) = {G(-1).real:.6f}   zeta(-1) = xi(-1) / G(-1) = {zeta_from_xi(-1.0).real:.6f}")

print("exact values from Bernoulli numbers, zeta(-n) = (-1)^n B_(n+1) / (n+1)")
for n in range(0, 7):
    exact = (-1) ** n * B[n + 1] / (n + 1)
    road1 = zeta_from_xi(-float(n)).real if n % 2 else None
    tail = f"   road 1 {road1:9.6f}" if road1 is not None else ""
    print(f"  zeta({-n}) = {str(exact):>6}   road 2 {c(zeta_em(-n), 1):>9}{tail}")
    assert abs(zeta_em(-n).real - float(exact)) < 1e-8
    if road1 is not None:
        assert abs(road1 - float(exact)) < 1e-9
print(f"  xi(0) = {xi_theta(0.0).real:.6f}   xi(1) = {xi_theta(1.0).real:.6f}")

print("trivial zeros: xi stays finite, G has a pole, so zeta is 0")
for k in (1, 2, 3, 4):
    s = -2.0 * k
    print(f"  s = {s:4.0f}   xi(s) = xi({1 - s:.0f}) = {xi_theta(s).real:.6f}   "
          f"zeta(s+0.01) = {zeta_from_xi(s + 0.01).real:+.8f}   zeta(s-0.01) = {zeta_from_xi(s - 0.01).real:+.8f}")
    assert zeta_from_xi(s + 0.01).real * zeta_from_xi(s - 0.01).real < 0
    assert abs(zeta_from_xi(s + 0.01) - zeta_em(s + 0.01)) < 1e-8 and xi_theta(s).real > 0.4

print("what breaks")
drop = [s * (s - 1) / 2 * PI ** (-s / 2) * zeta_em(s).real for s in (2.0, -1.0)]
print(f"  no gamma factor:   {drop[0]:.6f} at 2, {drop[1]:.6f} at -1")
wrong = [s * (s - 1) / 2 * PI ** (-s / 2) * gamma(s).real * zeta_em(s).real for s in (2.5, -1.5)]
print(f"  Gamma(s) for Gamma(s/2): {wrong[0]:.6f} at 2.5, {wrong[1]:.6f} at -1.5 (true xi: {xi_theta(2.5).real:.6f})")
eta = [s * (s - 1) / 2 * G(s).real * (1 - 2 ** (1 - s)) * zeta_em(s).real for s in (2.0, -1.0)]
print(f"  alternating sum eta: {eta[0]:.6f} at 2, {eta[1]:.6f} at -1")
assert abs(drop[1] + math.sqrt(PI) / 12) < 1e-9 and abs(eta[0] - PI / 12) < 1e-9 and abs(eta[1] + PI / 2) < 1e-9
assert abs(wrong[0] - xi_theta(2.5).real) > 0.1

def bisect(lo, hi):                     # xi is real on the line Re s = 1/2: a zero is a sign change
    assert xi_theta(complex(0.5, lo)).real * xi_theta(complex(0.5, hi)).real < 0
    for _ in range(30):
        mid = (lo + hi) / 2
        if xi_theta(complex(0.5, lo)).real * xi_theta(complex(0.5, mid)).real <= 0:
            hi = mid
        else:
            lo = mid
    return lo
lo = bisect(14.0, 14.5)
z = xi_em(complex(0.5, lo))
assert abs(z) < 1e-8 and abs(xi_theta(complex(0.5, 14.0)).imag) < 1e-10
print(f"first zero on the line, by bisection: 1/2 + {lo:.6f}i   road 2 there: |xi| < 1e-8")

print(f"try: xi(1/2) = {xi_theta(0.5).real:.6f}   cut at x = 2: xi(2) = {xi_theta(2.0, T=2.0).real:.6f}   "
      f"20 steps: xi(2) = {xi_theta(2.0, steps=20).real:.6f}   zero in [20, 22]: {bisect(20.0, 22.0):.6f}")
sieve = bytearray([1]) * 1000001       # the house example, by a sieve of Eratosthenes
sieve[0] = sieve[1] = 0
for i in range(2, 1001):
    if sieve[i]:
        sieve[i * i::i] = bytes(len(range(i * i, 1000001, i)))
print(f"house example: primes below 1,000,000 = {sum(sieve):,}")
print(f"explicit formula, trivial zeros' term at x = 1,000,000: {-0.5 * math.log1p(-1e-12) * 1e13:.6f} x 10^-13")
pts = [-2.5 + 0.5 * k for k in range(13)]
print("chart, sigma " + " ".join(f"{p:5.1f}" for p in pts))
vals = [xi_theta(p).real for p in pts]
print("chart, xi    " + " ".join(f"{v:5.3f}" for v in vals))
assert all(abs(vals[k] - xi_em(1 - pts[k]).real) < 1e-9 for k in range(5))  # road 2 at the mirror
x0, y0, u = 210, 330, 20
print(f"figure, origin ({x0}, {y0}), {u} px per unit, first zero at ({x0 + u / 2:.1f}, {y0 - u * lo:.1f}), "
      f"trivial zeros at x = {', '.join(str(x0 - u * 2 * k) for k in range(1, 5))}, "
      f"2+3i at ({x0 + 2 * u}, {y0 - 3 * u}), -1-3i at ({x0 - u}, {y0 + 3 * u})")
print("ALL CHECKS PASS")
