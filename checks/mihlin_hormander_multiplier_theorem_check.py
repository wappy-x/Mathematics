# Mihlin-Hormander multiplier theorem -- the check behind the card.  Standard library only.
# Units: frequency xi in kHz, time x in ms.  Every number quoted on the card is printed here.
from math import pi, log, log2, log10, sqrt, cos, sin, exp, tanh, floor

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def eq(xi):   return 1 + 0.5 * cos(2 * pi * log2(abs(xi)))    # equaliser: one wobble per octave
def echo(xi): return 1 + 0.5 * cos(pi * xi)                   # echoes at -0.5 and +0.5 ms, a quarter each
G = 2 * pi / log(2)                                           # cos(2 pi log2 xi) = cos(G ln xi)

# ---- the gain curve and the house example ----
print("chart, frequency in Hz   " + " ".join(f"{1000 * 2 ** (k / 8):6.0f}" for k in range(-16, 17)))
print("chart, equaliser gain    " + " ".join(f"{eq(2 ** (k / 8)):6.3f}" for k in range(-16, 17)))
print("chart, echo gain         " + " ".join(f"{echo(2 ** (k / 8)):6.3f}" for k in range(-16, 17)))
centres = [2.0 ** k for k in range(-5, 5)]                    # 31.25 Hz ... 16 kHz
print("gain at the ten band centres", " ".join(f"{eq(c):.3f}" for c in centres))
print(f"gain halfway, at 707 Hz      {eq(2 ** -0.5):.6f}")
print(f"in decibels: peak {20 * log10(1.5):.6f} dB, dip {20 * log10(0.5):.6f} dB")

# ---- 1. Mihlin constants: closed form against a finite-difference scan ----
def scan_1d(m, u0, u1, n, h=1e-5):           # largest |m| and |xi m'| over log2 xi in [u0, u1]
    b0 = b1 = 0.0
    for k in range(n + 1):
        xi = 2 ** (u0 + (u1 - u0) * k / n)
        b0 = max(b0, abs(m(xi)))
        b1 = max(b1, abs(m(xi * exp(h)) - m(xi * exp(-h))) / (2 * h))   # d m / d(ln xi) = xi m'
    return b0, b1
e0, e1 = scan_1d(eq, -5, 5, 10240)
print(f"equaliser sup|m|            closed 1.500000   scan {e0:.6f}")
print(f"equaliser sup|xi m'|        closed {pi / log(2):.6f}   scan {e1:.6f}")
print(f"equaliser Mihlin constant A {max(1.5, pi / log(2)):.6f}")
def echo_peak(X):                             # top of the last hump of (pi/2) xi |sin(pi xi)| below X, by Newton
    xi = X - 0.5
    for _ in range(20): xi -= (sin(pi * xi) + pi * xi * cos(pi * xi)) / (2 * pi * cos(pi * xi) - pi * pi * xi * sin(pi * xi))
    return pi / 2 * xi * abs(sin(pi * xi))
echo_scan = [(X, scan_1d(echo, -5, log2(X), 4096 * int(X))[1], echo_peak(X)) for X in (4, 8, 16)]
for X, v, pk in echo_scan:
    print(f"echo sup|xi m'| up to {X:>2} kHz {pk:10.6f}   scan {v:.6f}   (pi/2)(X - 1/2) = {pi / 2 * (X - 0.5):.6f}")

def riesz(a, b): return a * a / (a * a + b * b)              # xi1^2/|xi|^2 = -R1^2
def partials(a, b, h=1e-4):
    f = riesz
    d1 = (f(a + h, b) - f(a - h, b)) / (2 * h)
    d2 = (f(a, b + h) - f(a, b - h)) / (2 * h)
    d11 = (f(a + h, b) - 2 * f(a, b) + f(a - h, b)) / (h * h)
    d22 = (f(a, b + h) - 2 * f(a, b) + f(a, b - h)) / (h * h)
    d12 = (f(a + h, b + h) - f(a + h, b - h) - f(a - h, b + h) + f(a - h, b - h)) / (4 * h * h)
    return [abs(f(a, b)), abs(d1), abs(d2), abs(d11), abs(d22), abs(d12)]
closed2 = [1.0, 4 / (3 * sqrt(3)), 4 / (3 * sqrt(3)), 2.0, 2.0, 1.0]
scans = {}
for r in (1.0, 7.0):
    best = [0.0] * 6
    for k in range(2880):
        th = pi * k / 1440
        p = partials(r * cos(th), r * sin(th), 1e-4 * r)
        w = [1, r, r, r * r, r * r, r * r]                    # |xi|^|beta| times the derivative
        best = [max(best[i], p[i] * w[i]) for i in range(6)]
    scans[r] = best
names = ["|m|", "|xi| |d1 m|", "|xi| |d2 m|", "|xi|^2 |d11 m|", "|xi|^2 |d22 m|", "|xi|^2 |d12 m|"]
for i in range(6):
    print(f"Riesz {names[i]:<15} closed {closed2[i]:.6f}  scan r=1 {scans[1.0][i]:.6f}  r=7 {scans[7.0][i]:.6f}")
print(f"Riesz Mihlin constant A     {max(closed2):.6f}; kernel size constant 1/(2 pi) = {1 / (2 * pi):.6f}")

# ---- 2. the proof on the equaliser: one octave piece, bounded from the frequency side ----
def F(xi):                                    # m times the octave bump psi, for 1/2 <= xi <= 2
    u = log2(xi)
    return eq(xi) * cos(pi * u / 2) ** 2
def dF(xi):                                   # dF/dxi, by the chain rule through u = log2 xi
    u = log2(xi)
    du = -pi * sin(2 * pi * u) * cos(pi * u / 2) ** 2 - eq(xi) * (pi / 2) * sin(pi * u)
    return du / (xi * log(2))
n = 4000
I2 = 2 * simpson(lambda s: dF(s) ** 2, 0.5, 2, n) / (4 * pi * pi)            # int x^2 K0^2
J0 = 2 * simpson(lambda s: 4 * pi * pi * s * s * F(s) ** 2, 0.5, 2, n)       # int K0'^2
J2 = 2 * simpson(lambda s: (F(s) + s * dF(s)) ** 2, 0.5, 2, n)               # int x^2 K0'^2
D1 = sqrt(2 * J0) + sqrt(2 * J2)                                             # bound on int |K0'|
def lp_sum(y):
    return sum(min(2.0 ** j * y * D1, 2 * sqrt(2 * I2 / (2.0 ** j * y))) for j in range(-60, 61))
B_grid = max(lp_sum(1 + k / 256) for k in range(257))
r_sw = (2 * sqrt(2 * I2) / D1) ** (2 / 3)                  # the piece whose two bounds are equal
B_lp = (3 + sqrt(2)) * D1 * r_sw                            # both lists are geometric series from there
y_sw = r_sw * 2 ** -floor(log2(r_sw))                       # that shift, moved into [1, 2) ms
print(f"piece: int x^2 K0^2 from the frequency side  {I2:.6f}")
Fj = sum(abs(dF(s + 1e-6) - dF(s - 1e-6)) / 2e-6 for s in (0.5 + 1e-6, 2 - 1e-6))   # jumps of F'' at the ends
g3 = [(dF(s + 1e-5) - 2 * dF(s) + dF(s - 1e-5)) / 1e-10 for s in (0.5 + 1e-5 + (1.5 - 2e-5) * k / 30000 for k in range(30001))]
V3 = abs(g3[0]) + abs(g3[-1]) + sum(abs(u - v) for u, v in zip(g3, g3[1:]))       # total change of F'''
def K0(x): return 2 * simpson(lambda s: F(s) * cos(2 * pi * x * s), 0.5, 2, 600)
X = 30.0
I2t = 2 * simpson(lambda x: x * x * K0(x) ** 2, 0, X, 3000)
a3, a4 = 2 * Fj / (2 * pi) ** 3, 2 * V3 / (2 * pi) ** 4    # |K0(x)| <= a3/|x|^3 + a4/|x|^4, by parts four times
tail = 2 * (a3 ** 2 / (3 * X ** 3) + a3 * a4 / (2 * X ** 4) + a4 ** 2 / (5 * X ** 5))
print(f"piece: int x^2 K0^2 from the kernel, |x| < 30 ms  {I2t:.6f}  (tail at most {tail:.6f})")
print(f"piece: int K0'^2 {J0:.6f}   int x^2 K0'^2 {J2:.6f}   so int |K0'| <= {D1:.6f}")
print(f"Hormander constant B, octave-piece bound      {B_lp:.6f}  (largest at the shift {y_sw:.6f} ms)")
print(f"  the same by direct sum at that shift        {lp_sum(y_sw):.6f};  on a 257-shift grid {B_grid:.6f}")

# ---- 3. the same constant from the exact kernel  |x|^(-1-iG) / C ----
Cabs = sqrt(2 * pi / (G * tanh(pi * G / 2)))
def cpow(z): return (cos(G * log(z)) / z, -sin(G * log(z)) / z)            # z^(-1-iG), z > 0
def dabs(p, q): return sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)
def hint(u):
    x = exp(u)
    return x * (dabs(cpow(x - 1), cpow(x)) + dabs(cpow(x + 1), cpow(x)))
IH = simpson(hint, log(2), log(1e6), 40000)
tailH = 2 * sqrt(1 + G * G) / (1e6 - 1)
print(f"|C| = {Cabs:.6f}  (sqrt(ln 2) = {sqrt(log(2)):.6f});  size: |K(x)| <= {0.5 / Cabs:.6f} / |x|")
B_ex = 0.5 * (IH + tailH) / Cabs                            # the integral to 10^6 ms, plus its tail
print(f"Hormander constant B, exact-kernel bound      {B_ex:.6f}  (tail beyond 10^6 ms included: {0.5 * tailH / Cabs:.6f})")

# ---- 4. what breaks: a dispersion filter exp(-i pi a xi^2), gain 1 everywhere ----
def ratio_closed(a, s=1.0): return (sqrt(s ** 4 + a * a) / (s * s)) ** 0.25    # L^(4/3) stretch
def Tg_abs(t, a, s=1.0):
    re = simpson(lambda x: s * exp(-pi * s * s * x * x) * cos(pi * a * x * x) * cos(2 * pi * x * t), 0, 4, 4000)
    im = simpson(lambda x: s * exp(-pi * s * s * x * x) * sin(pi * a * x * x) * cos(2 * pi * x * t), 0, 4, 4000)
    return 2 * sqrt(re * re + im * im)
q = 4 / 3
out = (2 * simpson(lambda t: Tg_abs(t, 10.0) ** q, 0, 40, 400)) ** (1 / q)
inn = (2 * simpson(lambda t: exp(-pi * t * t) ** q, 0, 10, 400)) ** (1 / q)
for a in (10.0, 100.0, 1000.0):
    print(f"dispersion a = {a:6.0f} ms^2: L^(4/3) ratio {ratio_closed(a):.6f}, L^4 ratio {1 / ratio_closed(a):.6f}")
print(f"dispersion a = 10 by numerical transform: L^(4/3) ratio {out / inn:.6f}")
print(f"brick wall: ||T||_4 <= ||H||_4 = cot(pi/8) = {cos(pi / 8) / sin(pi / 8):.6f}")
print(f"try: 2 wobbles per octave A = {2 * pi / log(2):.6f};  depth 0.1: sup|xi m'| = {0.1 * G:.6f}, A = 1.100000")

assert abs(e1 - pi / log(2)) < 1e-6, "scan must find the closed-form derivative bound"
assert all(abs(scans[r][i] - closed2[i]) < 1e-5 for r in (1.0, 7.0) for i in range(6)), "Riesz constants"
assert all(pi / 2 * (X - 0.5) < pk < pi / 2 * X for X, v, pk in echo_scan), "echo grows like pi X / 2"
assert all(0 <= pk - v < 1e-4 for X, v, pk in echo_scan), "echo: the scan sits just below the Newton peak"
assert 0 < I2 - I2t < tail, "Plancherel on the piece: the kernel side falls short by less than the tail"
assert abs(out / inn - ratio_closed(10.0)) < 1e-4, "dispersion ratio: closed form vs numerical"
assert abs(lp_sum(y_sw) - B_lp) < 1e-6, "octave bound: geometric series against the direct sum"
assert 0 <= B_lp - B_grid < 1e-3, "octave bound: no shift on the grid beats the switch"
assert abs(Cabs - sqrt(log(2))) < 1e-9, "|C|: the coth formula is sqrt(ln 2) to 1e-12"
assert B_ex < B_lp, "the exact kernel must sit inside the proof's bound"
print("ALL CHECKS PASS")
