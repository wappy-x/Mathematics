# The functional equation of L(s, chi): the check behind the card.  Standard library only.
# Road 1: the twisted theta integral of Step 4, symmetric by construction, valid at every s.
# Road 2: L by the Hurwitz zeta function (Euler-Maclaurin) and Gamma by Stirling, both
#         written out, evaluated at s and at 1 - s separately.  It never uses the proof.
# Road 3: exact L(0), L(-1), ... from generalised Bernoulli numbers, as fractions.
import cmath, math
from fractions import Fraction

PI = math.pi
B = [Fraction(1)]                       # Bernoulli numbers B_0 .. B_24, with B_1 = -1/2
for n in range(1, 25):
    B.append(-sum(math.comb(n + 1, k) * B[k] for k in range(n)) / (n + 1))

CH = {"chi4": ([0, 1, 0, -1], 4, 1),    # name: (values over one period, modulus q, parity a)
      "chi5": ([0, 1, -1, -1, 1], 5, 0),
      "chi5i": ([0, 1, 1j, -1j, -1], 5, 1),
      "chi23": ([0] + [1 if pow(n, 11, 23) == 1 else -1 for n in range(1, 23)], 23, 1),   # Euler's criterion
      "chi12": ([0, 1, 0, 0, 0, 1, 0, -1, 0, 0, 0, -1], 12, 1)}   # chi4 with 3 removed: imprimitive
def bar(v): return [complex(z).conjugate() for z in v]
def gauss(v, q): return sum(v[n] * cmath.exp(2j * PI * n / q) for n in range(q))
def eps(name): return gauss(*CH[name][:2]) / (1j ** CH[name][2] * math.sqrt(CH[name][1]))
def theta(v, q, a, x):                  # sum over every whole n of n^a chi(n) e^(-pi n^2 x / q)
    return 2 * sum(n ** a * v[n % q] * math.exp(-PI * n * n * x / q) for n in range(1, 60))

TAB = {}                                # w on the grid, per character
def lam1(s, name, steps=6000, T=None):  # road 1: int_1^T (x^((s+a)/2) w + eps x^((1-s+a)/2) w-bar) dx/x
    v, q, a = CH[name]
    s, h = complex(s), math.log(T or 14 * q) / steps
    if (name, steps, T) not in TAB:     # w(x) = sum over n >= 1 of n^a chi(n) e^(-pi n^2 x / q), x = e^u
        TAB[name, steps, T] = [sum(n ** a * v[n % q] * math.exp(-PI * n * n * math.exp(k * h) / q)
                                   for n in range(1, int(4 * math.sqrt(q)) + 3)) for k in range(steps + 1)]
    e, tot = eps(name), 0
    for k, w in enumerate(TAB[name, steps, T]):
        f = cmath.exp((s + a) / 2 * k * h) * w + e * cmath.exp((1 - s + a) / 2 * k * h) * complex(w).conjugate()
        tot += f * (1 if k in (0, steps) else 4 if k % 2 else 2)
    return tot * h / 3
def gamma(z):                           # shift right to Re z >= 10, then Stirling's series
    z, p = complex(z), 1
    while z.real < 10: p, z = p * z, z + 1
    ln = (z - 0.5) * cmath.log(z) - z + 0.5 * math.log(2 * PI)
    ln += sum(float(B[2 * k]) / (2 * k * (2 * k - 1) * z ** (2 * k - 1)) for k in range(1, 8))
    return cmath.exp(ln) / p
def hurwitz(s, al):                     # sum over n >= 0 of (n + al)^-s, by Euler-Maclaurin
    N = 15 if s.real > 0 else 6
    t = sum((n + al) ** -s for n in range(N)) + (N + al) ** (1 - s) / (s - 1) + (N + al) ** -s / 2
    poch = s
    for k in range(1, 13):
        t += float(B[2 * k]) / math.factorial(2 * k) * poch * (N + al) ** (-s - 2 * k + 1)
        poch *= (s + 2 * k - 1) * (s + 2 * k)
    return t
def L2(s, name, conj=False):            # road 2: L(s, chi) = q^-s * sum of chi(b) zeta(s, b/q)
    v, q, a = CH[name]
    return q ** -complex(s) * sum((bar(v) if conj else v)[b] * hurwitz(complex(s), b / q) for b in range(1, q))
def gf(s, name):                        # the gamma factor (q/pi)^((s+a)/2) Gamma((s+a)/2)
    q, a = CH[name][1], CH[name][2]
    return (q / PI) ** ((complex(s) + a) / 2) * gamma((complex(s) + a) / 2)
def lam2(s, name, conj=False): return gf(s, name) * L2(s, name, conj)
def L1(s, name): return lam1(s, name) / gf(s, name)                 # L read back from road 1
def Lneg(m, name):                      # road 3: L(-m, chi) = -B_(m+1, chi) / (m + 1)
    v, q, a = CH[name]
    bp = lambda n, x: sum(math.comb(n, k) * B[k] * x ** (n - k) for k in range(n + 1))
    return -Fraction(q) ** m * sum(v[b] * bp(m + 1, Fraction(b, q)) for b in range(1, q)) / (m + 1)
def c(z, real=True):                    # print a value; near-zeros print as 0 in both languages
    f = lambda x: f"{0.0 if abs(x) < 5e-7 else x:.6f}"
    return f(z.real) if real else f"{f(z.real)}{'+' if z.imag > -5e-7 else '-'}{f(abs(z.imag))}i"

print("Gauss sums and signs: eps = g / (i^a sqrt q)")
for name in ("chi4", "chi5", "chi5i", "chi23"):
    v, q, a = CH[name]
    g, e = gauss(v, q), eps(name)
    print(f"  {name:5} q = {q:2}  a = {a}  g = {c(g, 0)}  eps = {c(e, 0)}  |eps| = {abs(e):.6f}")
    assert abs(abs(g) - math.sqrt(q)) < 1e-12
assert abs(eps("chi4") - 1) < 1e-12 and abs(eps("chi23") - 1) < 1e-12 and abs(eps("chi5") - 1) < 1e-12
print("twisted theta: W(1/x, chi) against eps x^(a+1/2) W(x, chi-bar)")
for name, x in (("chi4", 2.0), ("chi5i", 1.5)):
    v, q, a = CH[name]
    lhs, rhs = theta(v, q, a, 1 / x), eps(name) * x ** (a + 0.5) * theta(bar(v), q, a, x)
    print(f"  {name}, x = {x}:  {c(lhs, name == 'chi4')}  against  {c(rhs, name == 'chi4')}")
    assert abs(lhs - rhs) < 1e-12
print("the mirror: Lambda(s, chi) against eps Lambda(1 - s, chi-bar)")
for name, lab, s in (("chi4", "3", 3), ("chi4", "0.25", 0.25), ("chi4", "2+3i", 2 + 3j), ("chi5", "2", 2), ("chi5i", "3", 3), ("chi5i", "0.3+2i", 0.3 + 2j)):
    s, re = complex(s), name != "chi5i" and "i" not in lab
    r1, a2, b2 = lam1(s, name), lam2(s, name), eps(name) * lam2(1 - s, name, True)
    print(f"  {name:5} s = {lab:6}  road 1 {c(r1, re)}  road 2 at s {c(a2, re)}  at 1-s {c(b2, re)}")
    assert abs(r1 - a2) < 1e-9 and abs(a2 - b2) < 1e-9
print("worked numbers for chi4")
G = L2(2, "chi4").real
print(f"  L(2) = {G:.9f}  4 L(2)/pi = {4 * G / PI:.6f}  road 1: Lambda(2) = {c(lam1(2, 'chi4'))}  Lambda(-1) = {c(lam1(-1, 'chi4'))}")
print(f"  road 1: Lambda(1) = {c(lam1(1, 'chi4'))}  Lambda(0) = {c(lam1(0, 'chi4'))}  gamma factor at 0 = {c(gf(0, 'chi4'))}  so L(1) = {c(L1(1, 'chi4'))}  pi/4 = {PI / 4:.6f}")
assert abs(lam1(1, "chi4") - 1) < 1e-10 and abs(L1(1, "chi4") - PI / 4) < 1e-10 and abs(lam1(-1, "chi4") - 4 * G / PI) < 1e-9
print("exact values L(-m, chi) = -B_(m+1, chi) / (m + 1), road 2 in brackets")
for name in ("chi4", "chi5"):
    row = []
    for m in range(5):
        ex, r2 = Lneg(m, name), L2(-m, name).real
        assert abs(r2 - float(ex)) < 1e-9
        if (m + CH[name][2]) % 2 == 1:  # where the gamma factor is finite, road 1 too
            assert abs(L1(-m, name).real - float(ex)) < 1e-9
        row.append(f"L({-m}) = {str(ex):>4} ({c(r2)})")
    print(f"  {name}: " + "  ".join(row))
print("trivial zeros of chi4: Lambda finite, Gamma((s+1)/2) infinite, so L = 0")
for s in (-1, -3):
    up, dn = L1(s + 0.01, "chi4").real, L1(s - 0.01, "chi4").real
    print(f"  s = {s}  Lambda(s) = Lambda({1 - s}) = {c(lam1(s, 'chi4'))}  L(s+0.01) = {up:+.8f}  L(s-0.01) = {dn:+.8f}")
    assert up * dn < 0 and abs(up - L2(s + 0.01, "chi4").real) < 1e-9
print("what breaks")
wp = [(4 / PI) ** (s / 2) * gamma(s / 2).real * L2(s, "chi4").real for s in (2.0, -1.0)]
fq = [4 ** (-(s + 1) / 2) * lam1(s, "chi4").real for s in (2.0, -1.0)]
print(f"  parity a = 0 for chi4: {c(wp[0])} at 2, {c(wp[1])} at -1;  1/pi in place of q/pi: {c(fq[0])} at 2, {c(fq[1])} at -1")
pz = [lam2(3, "chi5i"), eps("chi5i") * lam2(-2, "chi5i", True), lam2(-2, "chi5i", True), lam2(-2, "chi5i")]
print(f"  chi5i: Lambda(3) = {c(pz[0], 0)}, eps Lambda(-2, bar) = {c(pz[1], 0)}, no eps {c(pz[2], 0)}, no bar {c(pz[3], 0)}")
im, g12 = [lam2(3, "chi12").real, lam2(-2, "chi12").real], abs(gauss(*CH["chi12"][:2]))
print(f"  imprimitive chi12: Lambda(3) = {c(im[0])}, Lambda(-2) = {c(im[1])}, |g| = {g12:.6f}, sqrt 12 = {math.sqrt(12):.6f}")
assert abs(wp[1]) < 1e-9 and abs(wp[0] - 4 * G / PI) < 1e-9 and abs(pz[2] - pz[0]) > 0.01 and abs(pz[3] - pz[0]) > 0.01
assert abs(im[0] - im[1]) > 1 and abs(g12 - 2) < 1e-12
def bisect(lo, hi):                     # Lambda is real on the line Re s = 1/2: a zero is a sign change
    f = lambda t: lam1(complex(0.5, t), "chi4").real
    assert f(lo) * f(hi) < 0
    for _ in range(30):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if f(lo) * f(mid) <= 0 else (mid, hi)
    return lo
t1 = bisect(5.5, 6.5)
assert abs(lam2(complex(0.5, t1), "chi4")) < 1e-8 and abs(lam1(complex(0.5, 6.0), "chi4").imag) < 1e-10
print(f"first zero of L(s, chi4) on the line, by bisection: 1/2 + {t1:.6f}i   road 2 there: |Lambda| < 1e-8")
l0 = L1(0, "chi23").real
print(f"class numbers: L(0, chi4) = {Lneg(0, 'chi4')} = 2h/w, w = 4, h = 1;  L(0, chi23) = {Lneg(0, 'chi23')}, road 1 {l0:.6f} = 2h/w, w = 2, h = 3")
assert abs(l0 - 3) < 1e-9 and Lneg(0, "chi23") == 3
print(f"try: Lambda(1/2) = {c(lam1(0.5, 'chi4'))}  cut at x = 4: Lambda(1) = {c(lam1(1, 'chi4', T=4))}  "
      f"second zero: {bisect(9.5, 10.5):.6f}  eps(chi5i-bar) = {c(gauss(bar(CH['chi5i'][0]), 5) / (1j * math.sqrt(5)), 0)}")
sv = bytearray([0, 0]) + bytearray([1]) * 999998   # the primes below a million, by a sieve, split mod 4
for i in (i for i in range(2, 1001) if sv[i]): sv[i * i::i] = bytes(len(range(i * i, 1000000, i)))
print(f"house example: primes below 1,000,000 leaving 1 mod 4 = {sum(sv[1::4]):,}, leaving 3 = {sum(sv[3::4]):,}")
pts = [-2.5 + 0.5 * k for k in range(13)]
vals = [lam1(p, "chi4").real for p in pts]
print("chart, sigma  " + " ".join(f"{p:5.1f}" for p in pts))
print("chart, Lambda " + " ".join(f"{v:5.3f}" for v in vals))
assert all(abs(vals[k] - lam2(1 - pts[k], "chi4").real) < 1e-9 for k in range(5))  # road 2 at the mirror
print("ALL CHECKS PASS")
