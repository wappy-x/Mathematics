# Gaussian and Poisson kernels -- the check behind the card.  Standard library only;
# math gives exp, sqrt, log, atan, tan, cos and pi.  The rail: steel, diffusivity about
# 0.13 cm^2/s, a weld band 2.5 cm wide left 500 K above the rest of the rail at t = 0.
from math import exp, sqrt, log, atan, tan, cos, pi

KAP, A, U0 = 0.13, 1.25, 500.0     # cm^2/s, band half-width in cm, band height in K
C = sqrt(2 * log(2))               # a bell's half-width at half-maximum, in standard deviations

def G(s, x): return exp(-x * x / (2 * s * s)) / (s * sqrt(2 * pi))   # bell, standard deviation s
def P(y, x): return y / (pi * (x * x + y * y))                       # Poisson kernel at height y

def gauss(g, a, b, M):             # 3-point Gauss-Legendre on each of M cells of (a, b)
    h, r = (b - a) / M, sqrt(0.6) / 2
    return h * sum(5 / 18 * (g(c - r * h) + g(c + r * h)) + 4 / 9 * g(c)
                   for c in (a + (j + 0.5) * h for j in range(M)))

def erf(z):                        # positive-term series: (2/sqrt pi) e^(-z^2) sum 2^n z^(2n+1)/(2n+1)!!
    w = abs(z); term = s = w; n = 0
    if w > 6: return 1.0 if z > 0 else -1.0   # 1 - erf 6 is below 3e-17
    while term > 1e-17 * s:
        n += 1; term *= 2 * w * w / (2 * n + 1); s += term
    return (1 if z >= 0 else -1) * 2 / sqrt(pi) * exp(-w * w) * s

def heat(x, s): return U0 / 2 * (erf((x + A) / (s * sqrt(2))) - erf((x - A) / (s * sqrt(2))))
def lap(x, y): return U0 / pi * (atan((x + A) / y) - atan((x - A) / y))
def conv(K, w, x): return gauss(lambda q: U0 * K(w, x - q), -A, A, 200)   # band smeared by K_w
def mills(s, c): return sqrt(2 / pi) * s / c * exp(-c * c / (2 * s * s))   # Mills bound: bell weight beyond |x| = c
def cutG(s, d): return d + 40 * s * min(1, s / d)                          # where tailG stops integrating
def tailG(s, d, M): return 2 * gauss(lambda x: G(s, x), d, cutG(s, d), M)  # beyond |x| = d
def tailP(y, d): return 2 * gauss(lambda u: y * d / (pi * (d * d + y * y * u * u)), 0, 1, 200)  # x = d/u

# ---- both kernels have area 1; the Poisson area arrives slowly ----
print(f"bell area, s = 1, over |x| < 12: {gauss(lambda x: G(1, x), -12, 12, 400):.12f};"
      f" Mills bound on the weight beyond 12: {sqrt(2 / pi) / 12 * exp(-72):.4e}")
for L in (10, 100, 1000):
    num = gauss(lambda x: P(1, x), -L, L, 40 * L)
    print(f"Poisson area, y = 1, over |x| < {L}: {num:.6f}; (2/pi) atan L {2 / pi * atan(L):.6f};"
          f" missing {1 - num:.6f}, about 2/(pi L) = {2 / (pi * L):.6f}")
    assert abs(num - 2 / pi * atan(L)) < 1e-9 and 1 - num < 2 / (pi * L)
assert abs(gauss(lambda x: G(1, x), -12, 12, 400) - 1) < 1e-12

# ---- the rail: the bell of width s = sqrt(2 kappa t) is the heat kernel ----
print(f"rail: kappa {KAP} cm^2/s, band half-width {A} cm, height {U0:.0f} K;"
      f" half-max half-width = {C:.4f} standard deviations")
for t in (10, 100):
    s = sqrt(2 * KAP * t); y = C * s
    assert abs(G(s, y) - G(s, 0) / 2) < 1e-12 and abs(P(y, y) - P(y, 0) / 2) < 1e-12   # half-maximum at y
    print(f"t = {t} s: s = {s:.4f} cm, half-width {y:.4f} cm; centre by erf {heat(0, s):.4f} K,"
          f" by convolution {conv(G, s, 0):.4f} K; Poisson at y = {y:.4f}: {lap(0, y):.4f} K,"
          f" by convolution {conv(P, y, 0):.4f} K")
    assert abs(heat(0, s) - conv(G, s, 0)) < 1e-9 and abs(lap(0, y) - conv(P, y, 0)) < 1e-9
s, y = sqrt(2.6), C * sqrt(2.6)
print(f"by hand, t = 10 s: a/(s sqrt 2) {A / (s * sqrt(2)):.4f}, erf {erf(A / (s * sqrt(2))):.4f};"
      f" a/y {A / y:.4f}, atan {atan(A / y):.4f} rad, x 2u0/pi {2 * U0 / pi:.4f} K")
s, y, h = sqrt(26.0), C * sqrt(26.0), 1e-3
ut = (heat(5, sqrt(2 * KAP * (100 + h))) - heat(5, sqrt(2 * KAP * (100 - h)))) / (2 * h)
uxx = (heat(5 + h, s) - 2 * heat(5, s) + heat(5 - h, s)) / h ** 2
vxx = (lap(5 + h, y) - 2 * lap(5, y) + lap(5 - h, y)) / h ** 2
vyy = (lap(5, y + h) - 2 * lap(5, y) + lap(5, y - h)) / h ** 2
print(f"at x = 5 cm, t = 100 s: u_t {ut:.6f}, kappa u_xx {KAP * uxx:.6f} K/s;"
      f" Poisson v_xx {vxx:.6f}, -v_yy {-vyy:.6f} K/cm^2")
assert abs(ut - KAP * uxx) < 1e-5 and abs(vxx + vyy) < 1e-5

# ---- approximate identity: weight beyond the band edge, and the centre's error ----
for t in (0.01, 0.1, 1):
    s = sqrt(2 * KAP * t); y = C * s; z = A / s
    g1, g2 = tailG(s, A, 400), tailG(s, A, 800); p = tailP(y, A)
    lo = 2 * exp(-z * z / 2) / sqrt(2 * pi) * (1 / z - 1 / z ** 3); up = 2 * exp(-z * z / 2) / sqrt(2 * pi) / z
    print(f"t = {t:>5} s, s {s:.4f}, y {y:.4f} cm: bell beyond {A} cm {g2:.4e}"
          f" (Mills {lo:.4e} to {up:.4e}); Poisson {p:.6f}, (2/pi) atan(y/a) {2 / pi * atan(y / A):.6f},"
          f" 2y/(pi a) {2 * y / (pi * A):.6f}")
    print(f"      centre error: bell {U0 * g2:.4e} K, Poisson {U0 * p:.4f} K;"
          f" at the edge x = a: bell {heat(A, s):.4f} K, Poisson {lap(A, y):.4f} K")
    print(f"      bell integral cut at {cutG(s, A):.4f} cm; Mills bound on the weight beyond the cut {mills(s, cutG(s, A)):.4e}")
    assert abs(g1 - g2) < 1e-6 * g2 and lo < g2 < up and g2 - lo < 3 * up / z ** 4   # next Mills term
    assert abs(p - 2 / pi * atan(y / A)) < 1e-12 and abs(heat(0, s) - U0 * (1 - g2)) < 1e-8

# ---- the far rail at t = 100 s: bell against Poisson of the same half-width ----
s, y = sqrt(26.0), C * sqrt(26.0)
for x in (0, 10, 20, 30, 50):
    print(f"x = {x:>2} cm: bell {conv(G, s, x):.4e} K, Poisson {lap(x, y):.4f} K"
          + (f", far-field 2a u0 y/(pi x^2) {2 * A * U0 * y / (pi * x * x):.4f} K" if x else ""))
assert abs(lap(50, y) - 2 * A * U0 * y / (pi * 2500)) < 0.02 * lap(50, y) and conv(G, s, 30) < 1e-5

# ---- widths add: bells by variance (3-4-5), Poisson kernels by height ----
gg = gauss(lambda q: G(3, q) * G(4, -q), -60, 60, 400)
pp = gauss(lambda th: P(3, 5 * tan(th)) * P(4, -5 * tan(th)) * 5 / cos(th) ** 2, -pi / 2, pi / 2, 400)
print(f"G_3 * G_4 at 0 over |q| < 60 (beyond: below G_3(0) x Mills(4, 60) = {G(3, 0) * mills(4, 60):.4e}): {gg:.9f};"
      f" G_5(0) {G(5, 0):.9f}.  P_3 * P_4 at 0: {pp:.9f}; P_7(0) {P(7, 0):.9f}")
assert abs(gg - G(5, 0)) < 1e-12 and abs(pp - P(7, 0)) < 1e-12
inv = 2 * gauss(lambda xi: exp(-2 * pi * xi) * cos(4 * pi * xi), 0, 10, 1000)  # y = 1, x = 2
print(f"inverse transform of e^(-2 pi |xi|) at x = 2 over |xi| < 10 (beyond: below e^(-20 pi)/pi = {exp(-20 * pi) / pi:.4e}):"
      f" {inv:.9f}; P_1(2) = {P(1, 2):.9f}")
assert abs(inv - P(1, 2)) < 1e-12
s, y = sqrt(2.6), C * sqrt(2.6)
print(f"t = 10 s, detail 0.5 cycles/cm kept: bell {exp(-2 * pi ** 2 * s * s * 0.25):.4e},"
      f" Poisson {exp(-2 * pi * y * 0.5):.4e}")

# ---- the disc: near the rim, (1/2pi) P_r is the half-plane kernel at height 1 - r ----
def Pr(r, th): return (1 - r * r) / (1 - 2 * r * cos(th) + r * r) / (2 * pi)
print("r = 0.99 at angle 0, 0.01, 0.03 rad: disc",
      " ".join(f"{Pr(0.99, th):.4f}" for th in (0, 0.01, 0.03)),
      "; half-plane", " ".join(f"{P(0.01, th):.4f}" for th in (0, 0.01, 0.03)))
for r in (0.9, 0.99, 0.999):
    far = 2 * gauss(lambda th: Pr(r, th), 0.5, pi, 400)
    print(f"r = {r}: disc weight beyond 0.5 rad {far:.6f}; half-plane (2/pi) atan((1-r)/0.5)"
          f" {2 / pi * atan((1 - r) / 0.5):.6f}")
    assert far < 3 * (1 - r) and abs(far / (2 / pi * atan((1 - r) / 0.5)) - 1) < 0.25

# ---- what breaks ----
s = sqrt(2.6)
print(f"break, width sqrt(kappa t) at t = 10 s: centre {heat(0, sqrt(1.3)):.4f} K, not {heat(0, s):.4f} K")
print(f"break, drop the 1/s: area {s:.4f}, centre {s * heat(0, s):.4f} K")
for L in (10, 100, 1000):
    pa = gauss(lambda x: abs(x) * P(1, x), -L, L, 40 * L)
    pv = gauss(lambda x: x * x * P(1, x), -L, L, 40 * L)
    print(f"break, Poisson of |x| over |x| < {L}: {pa:.4f}, ln(1+L^2)/pi {log(1 + L * L) / pi:.4f};"
          f" second moment {pv:.2f}")
    assert abs(pa - log(1 + L * L) / pi) < 1e-8 and abs(pv - 2 / pi * (L - atan(L))) < 1e-6
print(f"bell of s = 1 on |x|: {gauss(lambda x: abs(x) * G(1, x), 0, 12, 400) * 2:.4f}, sqrt(2/pi) {sqrt(2 / pi):.4f}")

# ---- chart points ----
s, y = sqrt(2.6), C * sqrt(2.6)
print("chart x:", " ".join(f"{x}" for x in range(11)))
print("chart bell t = 10 s:", " ".join(f"{heat(x, s):.1f}" for x in range(11)))
print(f"chart Poisson y = {y:.4f}:", " ".join(f"{lap(x, y):.1f}" for x in range(11)))
sg = 1 / C
print("chart log10 tail bell:", " ".join(f"{log(tailG(sg, d, 400), 10):.1f}" for d in range(1, 11)))
print("chart log10 tail Poisson:", " ".join(f"{log(tailP(1, d), 10):.2f}" for d in range(1, 11)))
print(f"chart bell tails cut at d + 40 s min(1, s/d): Mills share beyond the cut at most"
      f" {max(mills(sg, cutG(sg, d)) / tailG(sg, d, 400) for d in range(1, 11)):.4e}")
print("ALL CHECKS PASS")
