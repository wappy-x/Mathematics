# Perron's formula: psi(x), the weighted prime count, recovered from -zeta'/zeta by a line integral cut at height T.
# Roads: (1) psi(x) by a sieve; (2) the cut line integral, zeta by Euler-Maclaurin, must sit within the proved bound;
# (3) the switch integral of y^s/s two ways: straight up the line, and by residues plus the two horizontal sides.
import cmath
from math import log, pi, cos, sin, atan, exp

BERN = [1 / 6, -1 / 30, 1 / 42, -1 / 30, 5 / 66, -691 / 2730, 7 / 6, -3617 / 510]   # B_2 .. B_16

def zeta_pair(s, N):
    """zeta(s) and zeta'(s) by Euler-Maclaurin: N - 1 terms, the tail integral, eight Bernoulli corrections."""
    z, d = 0j, 0j
    for n in range(1, N):
        t = cmath.exp(-s * log(n))
        z += t
        d -= log(n) * t
    LN = log(N)
    a = cmath.exp(-s * LN)
    z += N * a / (s - 1) + a / 2
    d += -LN * N * a / (s - 1) - N * a / (s - 1) ** 2 - LN * a / 2
    P, dP, pw, fac = s, 1, a / N, 2.0           # P = s(s+1)...(s+2k-2), pw = N^(-s-2k+1), fac = (2k)!
    for k in range(1, 9):
        z += BERN[k - 1] / fac * P * pw
        d += BERN[k - 1] / fac * (dP - LN * P) * pw
        for j in (2 * k - 1, 2 * k):
            dP, P = dP * (s + j) + P, P * (s + j)
        pw /= N * N
        fac *= (2 * k + 1) * (2 * k + 2)
    return z, d

def simpson(g, a, b, m):
    h = (b - a) / m
    tot = g(a) + g(b)
    for i in range(1, m):
        tot += (4 if i % 2 else 2) * g(a + i * h)
    return tot * h / 3

def switch_line(y, T, c, m=20000):
    """(1/2 pi i) * integral of y^s/s from c-iT to c+iT; the imaginary parts cancel in pairs t, -t."""
    L = log(y)
    return y ** c / pi * simpson(lambda t: (c * cos(L * t) + t * sin(L * t)) / (c * c + t * t), 0.0, T, m)

def switch_residue(y, T, c, m=20000):
    """Same number by the rectangle: residue 1 at s = 0 if y > 1, then the top and bottom sides, far side -> 0."""
    L = log(y)
    side = lambda u: exp(L * u) * (u * sin(T * L) - T * cos(T * L)) / (u * u + T * T)
    if y > 1:
        return 1 + simpson(side, c - 50 / L, c, m) / pi
    return -simpson(side, c, c - 50 / L, m) / pi

NMAX = 1_000_000
sieve = bytearray([1]) * (NMAX + 1); sieve[0] = sieve[1] = 0
for i in range(2, int(NMAX ** 0.5) + 1):
    if sieve[i]:
        sieve[i * i :: i] = bytearray(len(range(i * i, NMAX + 1, i)))
LAM = {}                                         # n -> Lambda(n) = log p for n = p^k
for p in range(2, NMAX + 1):
    if sieve[p]:
        q = p
        while q <= NMAX:
            LAM[q] = log(p)
            q *= p
PP = sorted(LAM)

def psi(x):
    return sum(LAM[n] for n in PP if n <= x)

def perron_cut(x, c, Ts, h=0.02):
    """(1/pi) * integral from 0 to T of Re(-zeta'/zeta(s) x^s/s), s = c + it, for each T in Ts (one pass)."""
    L, out, total, t0 = log(x), [], 0.0, 0.0
    def f(t):
        s = complex(c, t)
        z, d = zeta_pair(s, 30 + int(t / 3))
        return (-d / z * cmath.exp(s * L) / s).real
    for T in Ts:
        m = 2 * int(round((T - t0) / (2 * h)))
        total += simpson(f, t0, T, m)
        out.append(total / pi)
        t0 = T
    return out

def bound(x, T, c, capped=True):
    """sum of Lambda(n) (x/n)^c min(1, 1/(pi T |log(x/n)|)) to NMAX, plus a proved upper bound for the rest."""
    main = part = 0.0
    for n in PP:
        y = x / n
        w = 1 / (pi * T * abs(log(y)))
        main += LAM[n] * y ** c * (min(1.0, w) if capped else w)
        part += LAM[n] * n ** -c
    z, d = zeta_pair(complex(c, 0), 60)
    return main + x ** c / (pi * T * log(NMAX / x)) * ((-d / z).real - part)

X = 100.5
C = 1 + 1 / log(X)
TS = [10, 25, 50, 100, 200, 400, 1000]
z2, d2 = zeta_pair(complex(2, 0), 60)
print(f"engine zeta(2) {z2.real:.12f}  pi^2/6 {pi * pi / 6:.12f}")
lam2 = sum(LAM[n] / n ** 2 for n in PP)
print(f"engine -zeta'/zeta(2) {(-d2 / z2).real:.6f}  sum Lambda(n)/n^2 to 10^6 {lam2:.6f}")
assert abs(z2.real - pi * pi / 6) < 1e-12, "zeta engine off at 2"
assert 0 < (-d2 / z2).real - lam2 < 2e-6, "log derivative off: the tail past 10^6 is about 1e-6"
P = psi(X)
small = sum(LAM[n] for n in PP if n <= X and not sieve[n])   # 4, 8, 9, 16, 25, ...
print(f"x {X}  c = 1 + 1/log x {C:.6f}  x^c {X ** C:.4f}  e*x {exp(1) * X:.4f}")
print(f"psi(x) by sieve {P:.6f}  theta(100) {P - small:.6f}  prime powers {small:.6f}  primes {sum(sieve[:101])}, to 10^6 {sum(sieve)}")
print("switch    y     T    up the line   by residues  |I - step|      bound")
for y in (2.0, 1.0, 0.5):
    for T in (10, 100):
        a = switch_line(y, T, C)
        b = switch_residue(y, T, C) if y != 1 else atan(T / C) / pi
        step = 1.0 if y > 1 else (0.5 if y == 1 else 0.0)
        bd = C / (pi * T) if y == 1 else y ** C * min(1, 1 / (pi * T * abs(log(y))))
        print(f"switch {y:5.1f} {T:5d}  {a:12.6f}  {b:12.6f}  {abs(a - step):10.6f} {bd:10.6f}")
        assert abs(a - b) < 1e-7, "line and residue roads disagree"
        assert abs(a - step) <= bd, "switch error above its bound"
J = perron_cut(X, C, TS)
print("   T     J(T) cut integral   psi - J      bound B(T)   from n = 101")
for T, j in zip(TS, J):
    B = bound(X, T, C)
    n101 = -LAM[101] * switch_line(X / 101, T, C)
    print(f"{T:5d}  {j:16.6f}  {P - j:10.6f}  {B:12.6f}  {n101:10.6f}")
    assert abs(P - j) <= B, "Perron error above the proved bound"
y97, y101 = X / 97, X / 101
for n, y in ((97, y97), (101, y101)):
    w = pi * 100 * abs(log(y))
    print(f"bound piece n={n}: Lambda {LAM[n]:.4f} y {y:.6f} log y {log(y):.6f} pi T|log y| {w:.4f}"
          f" min {min(1, 1 / w):.4f} y^c {y ** C:.5f} piece {LAM[n] * y ** C * min(1, 1 / w):.4f}")
print(f"switch at y = 1, T = 100: arctan(T/c)/pi {atan(100 / C) / pi:.6f}  c/(pi T) {C / (pi * 100):.6f}")
J101 = perron_cut(101.0, 1 + 1 / log(101.0), [1000])[0]
print(f"wrong: x = 101, T = 1000 gives {J101:.4f}; psi(101) {psi(101):.4f}; midpoint {psi(101) - LAM[101] / 2:.4f}")
print(f"wrong: no min, T = 10: bound {bound(X, 10, C, False):.4f}  T = 25: {bound(X, 25, C, False):.4f}")
J2 = perron_cut(X, 2.0, [100])[0]
print(f"wrong: c = 2, T = 100: bound {bound(X, 100, 2.0):.4f}  error {P - J2:.6f}")
assert abs(J101 - (psi(101) - LAM[101] / 2)) < abs(J101 - psi(101)), "a jump gives the midpoint"
X9, C9 = 100.9, 1 + 1 / log(100.9)                    # try: x nearer the prime 101
print(f"try: x = 100.9, T = 100: error {psi(X9) - perron_cut(X9, C9, [100])[0]:.6f}  bound {bound(X9, 100, C9):.6f}")
print("chart y      " + " ".join(f"{0.5 + 0.1 * i:5.1f}" for i in range(16)))
for T in (10, 50):
    vals = [f"{switch_line(0.5 + 0.1 * i, T, C, 4000):5.2f}".replace("-0.00", " 0.00") for i in range(16)]
    print(f"chart T={T:<4d} " + " ".join(vals))
print("ALL CHECKS PASS")
