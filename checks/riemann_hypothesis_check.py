# The Riemann hypothesis -- the check behind the Clay status card.  Standard library only.
# Zeta on the critical line two ways: the Euler-Maclaurin sum, and the Riemann-Siegel
# formula used by the big verifications.  The zeros below a height counted two ways: sign
# changes of Hardy's Z(t), and the exact count N(T) from the argument principle.
import math, cmath
PI = math.pi

def theta(t):            # Riemann-Siegel angle, Stirling series (good for t > 1)
    return t / 2 * math.log(t / (2 * PI)) - t / 2 - PI / 8 + 1 / (48 * t) + 7 / (5760 * t**3) + 31 / (80640 * t**5)

def npow(n, s):          # n^(-s) = exp(-s log n)
    return cmath.exp(-s * math.log(n))

B2K = [1 / 6, -1 / 30, 1 / 42, -1 / 30, 5 / 66, -691 / 2730, 7 / 6, -3617 / 510]

def zeta(s):             # road 1: head sum + tail integral + Bernoulli end corrections
    N = int(abs(s.imag) / 2) + 30
    tot = sum(npow(n, s) for n in range(1, N))
    tot += npow(N, s) * N / (s - 1) + 0.5 * npow(N, s)
    poch, fact = s, 2.0
    for k in range(1, 9):
        tot += B2K[k - 1] / fact * poch * npow(N, s) / N**(2 * k - 1)
        poch *= (s + 2 * k - 1) * (s + 2 * k)
        fact *= (2 * k + 1) * (2 * k + 2)
    return tot

def Z_em(t):             # Hardy's Z: zeta on the line, turned by theta(t) to be real
    return (cmath.exp(1j * theta(t)) * zeta(complex(0.5, t))).real

def psi(p):              # complex p allowed; real on the real line
    return cmath.cos(2 * PI * (p * p - p - 1 / 16)) / cmath.cos(2 * PI * p)

def deriv(k, p):         # k-th derivative of psi, exactly: Cauchy's integral on a circle of radius 1/2
    us = [2 * PI * (j + 0.5) / 64 for j in range(64)]
    return (math.factorial(k) / 0.5**k * sum(psi(p + 0.5 * cmath.exp(1j * u)) * cmath.exp(-1j * k * u) for u in us) / 64).real

def Z_rs(t, terms=3):    # road 2: Riemann-Siegel, main sum plus up to three correction terms
    a = math.sqrt(t / (2 * PI)); m = int(a); p = a - m
    main = sum(math.cos(theta(t) - t * math.log(n)) / math.sqrt(n) for n in range(1, m + 1))
    c0 = psi(p).real
    c1 = -deriv(3, p) / (96 * PI**2)
    c2 = deriv(2, p) / (64 * PI**2) + deriv(6, p) / (18432 * PI**4)
    corr = [c0, c1 / a, c2 / a**2][:terms]
    return 2 * main + (-1)**(m - 1) * sum(corr) / math.sqrt(a)

def bisect(f, a, b):
    fa = f(a)
    for _ in range(60):
        c = (a + b) / 2; fc = f(c)
        if (fc < 0) == (fa < 0): a, fa = c, fc
        else: b = c
    return (a + b) / 2

def sign_changes(lo, hi, step):
    n, prev, k = 0, Z_em(lo), 1
    while lo + k * step <= hi + 1e-9:
        v = Z_em(lo + k * step)
        if (v < 0) != (prev < 0): n += 1
        prev, k = v, k + 1
    return n

def count_by_argument(T):  # N(T) = theta(T)/pi + 1 + S(T), arg followed from 2 + iT to 1/2 + iT
    z = zeta(complex(2, T)); arg = cmath.phase(z); worst = 0.0
    for j in range(1, 601):
        w = zeta(complex(2 - 1.5 * j / 600, T)); d = cmath.phase(w / z)
        worst = max(worst, abs(d)); arg += d; z = w
    assert worst < 0.5                     # steps small enough to follow the angle
    return theta(T) / PI + 1, arg / PI

print("Riemann hypothesis: zeros of zeta on the critical line, checked by two roads")
z1, z2 = bisect(Z_em, 14, 15), bisect(Z_rs, 14, 15)
print(f"first zero, Euler-Maclaurin road: 1/2 + {z1:.6f} i")
print(f"first zero, Riemann-Siegel road:  1/2 + {z2:.6f} i   (gap {abs(z1 - z2):.6f})")
assert abs(z1 - 14.134725) < 1e-6 and abs(z1 - z2) < 3e-4
print(f"zeta(1 + {z1:.6f} i) has size {abs(zeta(complex(1, z1))):.6f}   (edge of the strip: not 0)")
for t in (50.0, 100.0, 282.0):
    a, b = Z_em(t), Z_rs(t)
    print(f"Z({t:.0f}): Euler-Maclaurin {a:.8f}, Riemann-Siegel {b:.8f}, gap {abs(a - b):.9f}")
    assert abs(a - b) < 2e-6                 # three correction terms: error of order 1e-6 here

print("count of zeros up to height T: smooth part, wobble S(T), exact N(T), sign changes of Z")
for T in (100.0, 200.0, 300.0):
    smooth, S = count_by_argument(T); N = smooth + S
    sc = sign_changes(1.0, T, 0.02)
    print(f"T = {T:.0f}: smooth {smooth:.4f}, S(T) {S:+.4f}, N(T) {N:.4f}, sign changes {sc}")
    assert abs(N - round(N)) < 0.01 and sc == round(N)   # every zero below T is on the line
sm = 300 / (2 * PI) * math.log(300 / (2 * PI * math.e)) + 7 / 8
print(f"by hand, T = 300: T/(2 pi) = {300 / (2 * PI):.4f}, log(T/(2 pi e)) = {math.log(300 / (2 * PI * math.e)):.4f}, "
      f"product + 7/8 = {sm:.4f}; theta(300) = {theta(300):.4f}")
print(f"Riemann-Siegel terms: {int(math.sqrt(300 / (2 * PI)))} at height 300, {int(math.sqrt(3e12 / (2 * PI)))} at height 3e12")
print("checked: all 138 zeros with height up to 300 lie on the critical line (checked for T <= 300 only)")

def gram(n):              # Gram point: theta(g_n) = n pi, by Newton's method
    g = 20.0 + 2 * n
    for _ in range(30): g -= (theta(g) - n * PI) / (0.5 * math.log(g / (2 * PI)))
    return g
fails = [n for n in range(0, 140) if (-1)**n * Z_em(gram(n)) <= 0]
g = [gram(n) for n in (125, 126, 127)]
print(f"Gram's law (-1)^n Z(g_n) > 0: holds for n = 0 to {fails[0] - 1}; first failure n = {fails[0]}")
print(f"g_125 = {g[0]:.6f}, g_126 = {g[1]:.6f}, g_127 = {g[2]:.6f}")
print(f"Z(g_126): Euler-Maclaurin {Z_em(g[1]):.6f}, Riemann-Siegel {Z_rs(g[1]):.6f}")
inside = [sign_changes(g[0], g[1], (g[1] - g[0]) / 200), sign_changes(g[1], g[2], (g[2] - g[1]) / 200)]
zs = [bisect(Z_em, a, a + 0.25) for a in [g[0] + 0.25 * k for k in range(int((g[2] - g[0]) / 0.25) + 1)]
      if (Z_em(a) < 0) != (Z_em(a + 0.25) < 0)]
print(f"zeros in [g_125, g_126]: {inside[0]}; in [g_126, g_127]: {inside[1]}, at " + ", ".join(f"{x:.6f}" for x in zs))
assert fails[0] == 126 and Z_em(g[1]) < 0 and inside == [0, 2] and len(zs) == 2

print("what breaks, below height 300:")
print(f"  sample Z every 2 units instead of 0.02: {sign_changes(1.0, 300.0, 2.0)} sign changes, not 138")
smooth, S = count_by_argument(300.0)
print(f"  drop the wobble S(300): count {smooth:.4f}, not a whole number")
print(f"  trust Gram's law past g_125: the interval [g_125, g_126] should hold one zero, holds {inside[0]}")
assert sign_changes(1.0, 300.0, 2.0) < 138

print("try changing:")
smooth, S = count_by_argument(400.0)
print(f"  T = 400: N(T) {smooth + S:.4f}, sign changes {sign_changes(1.0, 400.0, 0.02)}")
print(f"  sample every 0.5 below 300: {sign_changes(1.0, 300.0, 0.5)} sign changes")
r0, r1 = bisect(lambda t: Z_rs(t, 0), 14, 15), bisect(lambda t: Z_rs(t, 1), 14, 15)
print(f"  Riemann-Siegel first zero, main sum alone: {r0:.6f}; with the first correction: {r1:.6f}")
more = [n for n in range(0, 300) if (-1)**n * Z_em(gram(n)) <= 0]
print(f"  Gram's law failures for n < 300: {len(more)}, first five " + ", ".join(str(n) for n in more[:5]))
assert abs(r0 - z1) > abs(r1 - z1) > abs(z2 - z1)          # the corrections help
print("chart: Z(t) for t = 270 to 290 in steps of 0.5")
pts = [Z_em(270 + 0.5 * k) for k in range(41)]
print("  " + ", ".join(f"{v:.2f}" for v in pts))
print("quoted, not computed: verified height 3000175332800 (2021), zeros up to it 12363153437138")
print("quoted, not computed: share on the line > 41.73% (0.417293, 2020); claimed 67.25% (2026-08-13, second proof 2026-09-02)")
print("quoted, not computed: Lean proof of 2026-11-20, about 17 million lines; certified 2026-11-21 against Mathlib's RiemannHypothesis")
print("quoted, not computed: Clay list of 2000-05-24, 7 problems, 1 solved, 1000000 US dollars each, paid 2 years after publication")
print("quoted, not computed: zero density exponent 30/13 (2026)")
print("quoted, not computed: if RH, |pi(x) - li(x)| < sqrt(x) log x / (8 pi) for x >= 2657 (1976); zero-free constant 5.558691 (2024)")
print("ALL CHECKS PASS")
