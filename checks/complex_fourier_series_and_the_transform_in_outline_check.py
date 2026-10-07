# Complex Fourier series and the transform in outline -- the check behind the card.
# Standard library only (sin, cos, exp, sqrt, pi); every integral, erf included, is a sum written here.
from math import sin, cos, exp, sqrt, pi

def simpson(f, a, b, n=2000):              # n even; error shrinks like step^4
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3
z = lambda v: 0.0 if abs(v) < 5e-7 else v  # prints a rounding speck as 0, not -0

# 1. Square wave, +1 on (0, pi), -1 on (-pi, 0).  Road one: c_n as the average
#    of f times e^(-inx).  Road two: (a_n - i b_n)/2 from the real series, b_n = 4/(n pi).
for n in (1, -1, 2, 3, 5):
    re_ = (simpson(lambda x: cos(n * x), 0, pi) - simpson(lambda x: cos(n * x), -pi, 0)) / (2 * pi)
    im_ = -(simpson(lambda x: sin(n * x), 0, pi) - simpson(lambda x: sin(n * x), -pi, 0)) / (2 * pi)
    b = 4 / (abs(n) * pi) if n % 2 else 0.0
    conv = -b / 2 if n > 0 else b / 2      # c_n = -i b_n/2, c_(-n) = +i b_n/2
    assert max(abs(re_), abs(im_ - conv)) < 1e-9
    print(f"square n={n:2d}: c_n by integral {z(re_):.6f} {z(im_):+.6f}i | (a_n - i b_n)/2 {z(conv):+.6f}i")
par = [sum(2 * (2 / (n * pi)) ** 2 for n in range(1, N + 1, 2)) for N in (1, 9, 99)]
print("Parseval, sum of |c_n|^2 for |n| <= 1, 9, 99:", " ".join(f"{p:.6f}" for p in par))

# 2. The radio pulse, 1 for |t| < 1 microsecond: F(w) by integral, against 2 sin(w)/w.
F = lambda w: 2 * sin(w) / w if w else 2.0
ws = (0.0, 1.0, pi / 2, pi)
num = [simpson(lambda t: cos(w * t), -1, 1) for w in ws]
odd = max(abs(simpson(lambda t: sin(w * t), -1, 1)) for w in ws)
assert max(abs(a - F(w)) for a, w in zip(num, ws)) < 1e-9
print("pulse F(w), w = 0, 1, pi/2, pi: integral", " ".join(f"{z(v):.6f}" for v in num), f"| imag {z(odd):.6f}")
print("pulse F(w), same w: 2 sin(w)/w       ", " ".join(f"{z(F(w)):.6f}" for w in ws))

# 3. Repeat the pulse every T; T c_k by a midpoint sum over one period lands on F(2 pi k/T).
def Tc(T, k, M=40000):
    h = T / M
    return sum(h * cos(2 * pi * k / T * t) for t in (-T / 2 + (j + 0.5) * h for j in range(M)) if abs(t) < 1)
for k in (1, 2, 3):
    assert max(abs(Tc(4, k) - F(k * pi / 2)), abs(Tc(8, 2 * k) - F(k * pi / 2))) < 1e-6
    print(f"w = {k * pi / 2:.6f}: T c_k at T=4 {z(Tc(4, k)):.6f}, T=8 {z(Tc(8, 2 * k)):.6f}; F {z(F(k * pi / 2)):.6f}")
print("spectrum 2 sin(w)/w, w = k pi/4, k = 0..12:", ", ".join(f"{z(F(k * pi / 4)):.2f}" for k in range(13)))
print("carrier cos t, F(0) = integral over (-L, L), L = 10, 20:",
      " ".join(f"{simpson(cos, -L, L, 4000):.6f}" for L in (10, 20)))

# 4. Heat on an endless rod, kappa = 0.1 cm^2/s, 100 C above ambient on |x| < 1 cm.
#    Road one: invert the transform, each frequency damped by exp(-kappa w^2 t).
#    Road two: the heat-kernel answer 50 [erf((1 - x)/s) + erf((1 + x)/s)], s = 2 sqrt(kappa t).
kap = 0.1
def u_transform(x, t):
    return simpson(lambda w: 100 * F(w) * exp(-kap * w * w * t) * cos(w * x), 0, 16) / pi
def erf(y):                                # error function, by its defining integral
    return simpson(lambda s: 2 / sqrt(pi) * exp(-s * s), 0, y, 400)
def u_kernel(x, t):
    s = 2 * sqrt(kap * t)
    return 50 * (erf((1 - x) / s) + erf((1 + x) / s))
ts, xs = (2.5, 10, 40), [j / 2 for j in range(9)]
assert max(abs(u_transform(x, t) - u_kernel(x, t)) for t in ts for x in xs) < 1e-6
print("rod centre, t = 2.5, 10, 40 s: transform", " ".join(f"{u_transform(0, t):.4f}" for t in ts),
      "| kernel", " ".join(f"{u_kernel(0, t):.4f}" for t in ts))
for t in ts:
    print(f"profile t = {t} s, x = 0..4 cm by 0.5:", ", ".join(f"{u_transform(x, t):.2f}" for x in xs))
print(f"breaks: c_1 without the 1/2 {-4 / pi:+.6f}i; centre at 10 s without 1/(2 pi) {2 * pi * u_kernel(0, 10):.2f} C")
