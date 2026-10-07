# The Fourier transform -- the check behind the card.  Standard library only.
# f-hat(w) = integral of f(t) e^(-iwt) dt over all t, w in radians per second.
# Road 1: closed forms and a residue.  Road 2: the integral itself, summed on the
# real line.  Then the Gaussian's contour shift, and inversion, rebuilt numerically.
import math

def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def show(z):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def simpson(g, lo, hi, n=20000):               # Simpson's rule, n even
    h = (hi - lo) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * g(lo + j * h) for j in range(n + 1))
def pulse(w): return 2 * math.sin(w / 2) / w if w else 1.0
def gauss(w): return math.sqrt(2 * math.pi) * math.exp(-w * w / 2)
def cauchy(w): return math.pi * math.exp(-abs(w))
def pulse_n(w): return simpson(lambda t: cexp(-1j * w * t), -0.5, 0.5)
def gauss_n(w): return simpson(lambda t: cexp(complex(-t * t / 2, -w * t)), -12, 12)
def cauchy_n(w, L=400.0):                      # even: 2 x cosine integral to L, plus the tail by parts
    tail = -math.sin(w * L) / (w * (1 + L * L)) + 2 * L * math.cos(w * L) / (w * w * (1 + L * L) ** 2)
    return 2 * (simpson(lambda t: math.cos(w * t) / (1 + t * t), 0, L, 80000) + tail)

w = 1.0
print(f"pulse, w = 1: 2 sin(w/2)/w {pulse(w):.6f}; Simpson on the pulse {show(pulse_n(w))}; "
      f"w = pi: {pulse(math.pi):.6f}; w = 2 pi: {pulse(2 * math.pi):.6f}; w = 0: {pulse(0):.6f}")
print(f"Gaussian, w = 1: sqrt(2 pi) e^(-w^2/2) {gauss(w):.6f}; Simpson on the real line {show(gauss_n(w))}")
res = cexp(-1j * w * -1j) / (-2j)              # e^(-iwz)/(z - i), at z = -i
print(f"Cauchy, w = 1: residue at -i {show(res)}; clockwise, -2 pi i x residue {show(-2j * math.pi * res)}")
print(f"Cauchy, w = 1: pi e^(-|w|) {cauchy(w):.6f}; Simpson to 400 plus tail {cauchy_n(w):.6f}")
g = lambda z: cexp(-z * z / 2)                 # the Gaussian, holomorphic everywhere
edges = {}
for R in (3, 8):
    bot, top = simpson(g, -R, R), simpson(lambda t: g(complex(t, w)), -R, R)
    rt, lf = simpson(lambda y: 1j * g(complex(R, y)), 0, w), simpson(lambda y: 1j * g(complex(-R, y)), 0, w)
    edges[R] = (bot, top, bot + rt - top - lf)
    print(f"R = {R}: real line {show(bot)}; line Im z = 1 {show(top)}; right side {show(rt)}; loop {show(edges[R][2])}")
print(f"shifted: e^(-1/2) x (line Im z = 1, R = 8) = {show(math.exp(-0.5) * edges[8][1])}")
print("figure, 50 units per unit, origin (180, 180): -3 at (30, 180), 3 at (330, 180), 3 + i at (330, 130), -3 + i at (30, 130)")
ws = range(13)
for name, F in (("pulse", pulse), ("Gaussian", gauss), ("Cauchy", cauchy)):
    print(f"chart, {name} at w = 0 to 12: " + ", ".join(f"{F(k):.2f}" for k in ws))
back_g = simpson(lambda v: gauss(v) * math.cos(v), -12, 12) / (2 * math.pi)
back_c = [simpson(lambda v: cauchy(v) * math.cos(v * t), 0, 40) / math.pi for t in (0, 1)]
back_p = [simpson(lambda v: pulse(v) * math.cos(v * t), 0, 400, 40000) / math.pi for t in (0, 0.5, 1)]
print(f"inverse, Gaussian at t = 1: {back_g:.6f} against e^(-1/2) {math.exp(-0.5):.6f}")
print(f"inverse, Cauchy at t = 0: {back_c[0]:.6f}, at t = 1: {back_c[1]:.6f} against 1/(1 + t^2)")
print(f"inverse, pulse with w cut at 400, t = 0, 1/2, 1: " + ", ".join(f"{v:.6f}" for v in back_p))
lap = (1 - cexp(-1j * w)) / (1j * w)           # Laplace transform (1 - e^(-s))/s of the pulse on [0, 1], s = iw
print(f"Laplace cross-check, s = i: {show(lap)}, size {abs(lap):.6f}")
print(f"mistake, closed upward at w = 1: 2 pi i x residue at i {show(2j * math.pi * cexp(w) / 2j)}")
print(f"mistake, inverse without 1/(2 pi): Cauchy at t = 0 gives {2 * math.pi * back_c[0]:.6f}")
print(f"mistake, f = 1 on -L to L at w = 1: L = 8 {show(simpson(lambda t: cexp(-1j * t), -8, 8))}, "
      f"L = 16 {show(simpson(lambda t: cexp(-1j * t), -16, 16))}")
assert all(abs(pulse_n(k) - pulse(k)) < 1e-9 and abs(gauss_n(k) - gauss(k)) < 1e-9 for k in ws)
assert all(abs(cauchy_n(k) - cauchy(k)) < 1e-7 for k in range(1, 7)) and abs(-2j * math.pi * res - cauchy(w)) < 1e-12
assert abs(edges[8][2]) < 1e-9 and abs(math.exp(-0.5) * edges[8][1] - gauss_n(w)) < 1e-9
assert abs(back_g - math.exp(-0.5)) < 1e-9 and abs(back_c[1] - 0.5) < 1e-9 and abs(back_p[1] - 0.5) < 2e-3
print("ALL CHECKS PASS")
