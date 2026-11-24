# Picard's theorems -- the check behind the card.  Standard library only.
# e^(1/z) near its essential singularity at 0 hits -1 infinitely often and 0 never.
# Road one solves exactly with the logarithm; road two finds the same points by
# Newton's method; road three counts them with the argument principle.
import math

def cexp(z):                                     # e^z from exp, cos and sin
    return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))

def turns(F, r, N=20000):                        # how often F(z) winds round 0 as z runs once round |z| = r
    pts = [F(r * cexp(2j * math.pi * j / N)) for j in range(N + 1)]
    return round(sum(math.atan2((b / a).imag, (b / a).real) for a, b in zip(pts, pts[1:])) / (2 * math.pi))

def newton(z, steps=60):                         # root of e^(1/z) + 1, slope -e^(1/z)/z^2
    for _ in range(steps):
        z -= (cexp(1 / z) + 1) / (-cexp(1 / z) / z ** 2)
    return z

zk = {k: 1 / complex(0, math.pi * (2 * k + 1)) for k in range(-3, 6)}
print("e^(1/z) = -1 at z_k = -i/(pi(2k + 1)); |z_k| for k = 0 to 5: " + ", ".join(f"{abs(zk[k]):.6f}" for k in range(6)))
res = max(abs(cexp(1 / z) + 1) for z in zk.values())
print(f"largest |e^(1/z_k) + 1|, k = -3 to 5: {res:.9f}")
nw = [newton(complex(0, s)) for s in (-0.3, -0.1)]
print(f"Newton from -0.3i and -0.1i lands on: {nw[0].imag:.6f}i, {nw[1].imag:.6f}i")
one = lambda z: cexp(1 / z) + 1
out_t, in_t = turns(one, 0.5), turns(one, 0.05)
count = sum(1 for k in range(-50, 50) if 0.05 < 1 / (math.pi * abs(2 * k + 1)) < 0.5)
print(f"e^(1/z) + 1: turns on |z| = 0.5: {out_t}; on |z| = 0.05: {in_t}; zeros between: {out_t - in_t}; by the formula: {count}")
zero = lambda z: cexp(1 / z)
print(f"e^(1/z): turns on |z| = 0.5: {turns(zero, 0.5)}; on |z| = 0.05: {turns(zero, 0.05)}; zeros between: {turns(zero, 0.5) - turns(zero, 0.05)}")
far = sum(1 for k in range(-100, 100) if math.pi * abs(2 * k + 1) <= 100)
print(f"solutions of e^(1/z) = -1 with |z| >= 0.01: {far}; every other one lies inside |z| < 0.01")
print(f"e^z = -1 at z = {math.pi:.6f}i (k = 0), spaced {2 * math.pi:.6f}i apart; |e^z| at z = -20: {abs(cexp(-20)):.9f}, never 0")
sq = [cexp(1j * (math.pi + 2 * math.pi * k) / 2) for k in (0, 1)]          # square roots of -1 = e^(i pi)
print(f"z^2 = -1 at z = {sq[0].imag:.6f}i and {sq[1].imag:.6f}i; z^2 = w has a root for every w: z^2 misses nothing")
for n in range(3):
    s = [abs(cexp(2 ** n / (0.5 * cexp(2j * math.pi * j / 720)))) for j in range(720)]
    print(f"f_{n}(z) = e^(2^{n}/z) on |z| = 1/2: largest {max(s):.6f}, smallest {min(s):.6f}")
    assert abs(max(s) / math.exp(2 ** (n + 1)) - 1) < 1e-9 and abs(min(s) * math.exp(2 ** (n + 1)) - 1) < 1e-9
y = math.log(2 + math.sqrt(3))
s2 = (cexp(1j * complex(math.pi / 2, -y)) - cexp(-1j * complex(math.pi / 2, -y))) / 2j
print(f"mistake, real line only: sin x never reaches 2, but sin z = 2 at z = {math.pi / 2:.6f} - {y:.6f}i (check: {s2.real:.6f})")
t5 = (cexp(-5) - cexp(5)) / (1j * (cexp(-5) + cexp(5)))
print(f"mistake, poles allowed: tan z misses i and -i; tan(5i) = {t5.imag:.6f}i, still {abs(t5 - 1j):.6f} short of i")
print(f"mistake, a pole is not essential: 1/z = 0.5 needs z = {1 / 0.5:.6f}, outside 0 < |z| < 1; 1/z misses every |w| <= 1 there")
assert res < 1e-12 and abs(nw[0].imag + 1 / math.pi) < 1e-12 and abs(nw[1].imag + 1 / (3 * math.pi)) < 1e-12
assert out_t - in_t == count == 6 and turns(zero, 0.5) == turns(zero, 0.05)
assert far == 32 and max(abs(z * z + 1) for z in sq) < 1e-12 and abs(s2 - 2) < 1e-12 and abs(abs(t5 - 1j) - 2 * math.exp(-10) / (1 + math.exp(-10))) < 1e-15
print("ALL CHECKS PASS")
