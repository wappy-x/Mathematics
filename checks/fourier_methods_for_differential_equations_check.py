# Fourier methods for differential equations: transform, divide by the symbol, transform back.
# Standard library only: every transform, integral, series and step is written out here.
import math
PI = math.pi
KAPPA, T = 1.25e-5, 6 * 3600.0      # steel rail diffusivity, m^2/s; dawn (06:00) to noon, s
A, HALF = 40.0, 0.5                 # weld excess at the joint, C; tent half-width, m
C = 4 * PI * PI * KAPPA * T         # each frequency xi (per m) fades by exp(-C xi^2)
SIG = math.sqrt(2 * KAPPA * T)      # spread of the heat kernel by noon, m

def simpson(g, lo, hi, n):
    h = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if k % 2 else 2) * g(lo + k * h) for k in range(1, n))
    return s * h / 3

def tent(x): return max(0.0, A * (1 - abs(x) / HALF))
def sinc(u): return 1.0 if u == 0 else math.sin(PI * u) / (PI * u)
def fhat(xi): return A * HALF * sinc(HALF * xi) ** 2       # transform of the tent, C*m

def Phi(z):                                                  # normal CDF: Simpson on the bell
    return 0.5 + simpson(lambda s: math.exp(-s * s / 2) / math.sqrt(2 * PI), 0, z, 400)

def sci(v, d):                                               # scientific notation, same in Rust
    if v == 0: return "0"
    e = math.floor(math.log10(abs(v))); m = f"{v / 10.0 ** e:.{d}f}"
    if m.lstrip("-").startswith("10"): e += 1; m = f"{v / 10.0 ** e:.{d}f}"
    return f"{m}e{e}"

def closed(x, half=HALF, sig=SIG):  # tent * bell = (A/a)[R(x+a) - 2R(x) + R(x-a)]
    R = lambda z: z * Phi(z / sig) + sig * math.exp(-z * z / (2 * sig * sig)) / math.sqrt(2 * PI)
    return A / half * (R(x + half) - 2 * R(x) + R(x - half))

def by_transform(x, c=C, cut=3.0, n=600):   # invert exp(-c xi^2) fhat(xi); the integrand is even
    return 2 * simpson(lambda xi: fhat(xi) * math.exp(-c * xi * xi) * math.cos(2 * PI * xi * x), 0, cut, n)

def by_kernel(x):                   # road two: the tent convolved with the heat kernel
    g = lambda y: tent(y) * math.exp(-(x - y) ** 2 / (4 * KAPPA * T)) / math.sqrt(4 * PI * KAPPA * T)
    return simpson(g, -HALF, 0, 200) + simpson(g, 0, HALF, 200)

def by_dft(L=16.0, N=128):          # road three: the finite twin, a length-N DFT on a 16 m loop
    dx = L / N
    f = [tent(-L / 2 + j * dx) for j in range(N)]
    F = [sum(f[j] * complex(math.cos(2 * PI * k * j / N), -math.sin(2 * PI * k * j / N)) for j in range(N)) for k in range(N)]
    xi = lambda k: (k if k < N // 2 else k - N) / L
    G = [F[k] * math.exp(-C * xi(k) ** 2) for k in range(N)]
    j0 = N // 2                     # the sample at x = 0
    return sum(G[k] * complex(math.cos(2 * PI * k * j0 / N), math.sin(2 * PI * k * j0 / N)) for k in range(N)).real / N

print(f"rail: kappa {sci(KAPPA, 2)} m^2/s, t {T:.0f} s, kappa t {KAPPA * T:.6f} m^2, C = 4 pi^2 kappa t {C:.6f}, kernel spread {SIG:.6f} m")
u_tr, u_k, u_c, u_d, u_d2 = by_transform(0), by_kernel(0), closed(0), by_dft(), by_dft(N=256)
tail = 2 * 20 * math.exp(-C * 9) / (2 * C * 3)
print(f"noon at the joint: transform {u_tr:.6f}  kernel {u_k:.6f}  closed {u_c:.6f}  dft {u_d:.6f} C")
print(f"  cut-off 3 per m, tail bound {sci(tail, 1)}; cut-off 2 per m gives {by_transform(0, cut=2.0, n=400):.6f}")
print(f"  dft gap, 128 points {u_d - u_c:.6f}, 256 points {u_d2 - u_c:.6f}, ratio {(u_d - u_c) / (u_d2 - u_c):.4f}")
var = HALF ** 2 / 6 + SIG ** 2
bell = 20 / math.sqrt(2 * PI * var)
print(f"by hand, spreads add: tent variance {HALF**2/6:.6f} + 2 kappa t {SIG**2:.6f} = {var:.6f} m^2; bell peak {bell:.6f} C")
heat = simpson(lambda x: closed(x), -6, 6, 600)
print(f"heat content dawn {fhat(0):.6f}  noon {heat:.6f} C*m")
print("per frequency: xi per m | dawn fhat C*m | fade exp(-C xi^2) | noon C*m")
for xi in (0, 0.25, 0.5, 1, 1.5):
    print(f"  {xi:.2f} | {fhat(xi):.6f} | {sci(math.exp(-C * xi * xi), 6)} | {sci(fhat(xi) * math.exp(-C * xi * xi), 6)}")
xs = [-2 + 0.25 * j for j in range(17)]
print("chart x m: " + " ".join(f"{x:.2f}" for x in xs))
print("chart dawn: " + " ".join(f"{tent(x):.2f}" for x in xs))
print("chart noon: " + " ".join(f"{closed(x):.2f}" for x in xs))
# half line: the joint d = 0.6 m from the rail end; sine transform (end held) and cosine transform (end insulated)
D = 0.6
def half_line(trig, x):
    Fs = lambda xi: 2 * (simpson(lambda y: tent(y - D) * trig(2 * PI * xi * y), D - HALF, D, 60)
                         + simpson(lambda y: tent(y - D) * trig(2 * PI * xi * y), D, D + HALF, 60))
    return 2 * simpson(lambda xi: Fs(xi) * math.exp(-C * xi * xi) * trig(2 * PI * xi * x), 0, 3, 300)
held, ins = half_line(math.sin, D), half_line(math.cos, D)
print(f"mirror image 1.2 m away: u(1.2) {closed(2 * D):.6f} C; bell estimate minus exact {bell - u_c:.6f} C")
print(f"end held at base: sine transform {held:.6f}  image u(0) - u(1.2) {closed(0) - closed(2 * D):.6f} C")
print(f"end insulated: cosine transform {ins:.6f}  image u(0) + u(1.2) {closed(0) + closed(2 * D):.6f} C")
# the forced oscillator y'' + 2y' + 5y = 10 cos(2 pi 0.3 t): divide by the symbol P(xi)
B, K, F0, XI0 = 2.0, 5.0, 10.0, 0.3
P = lambda xi, b=B: complex(K - (2 * PI * xi) ** 2, b * 2 * PI * xi)
amp = F0 / P(XI0)
yss = lambda t: (amp * complex(math.cos(2 * PI * XI0 * t), math.sin(2 * PI * XI0 * t))).real
dyss = lambda t: (amp * 2j * PI * XI0 * complex(math.cos(2 * PI * XI0 * t), math.sin(2 * PI * XI0 * t))).real
print(f"symbol P(0.3 Hz) = {P(XI0).real:.6f} + {P(XI0).imag:.6f}i, size {abs(P(XI0)):.6f}; amplitude {abs(amp):.6f} m, lag {-math.degrees(math.atan2(amp.imag, amp.real)):.4f} deg")
c1 = -yss(0); c2 = (c1 - dyss(0)) / 2      # Laplace road: steady state plus a fading transient
full = lambda t: yss(t) + math.exp(-t) * (c1 * math.cos(2 * t) + c2 * math.sin(2 * t))

def rk4(force, b, t0, t1, h=0.001):          # from rest at t0; returns {rounded t: y}
    y, v, t, out = 0.0, 0.0, t0, {}
    acc = lambda t, y, v: force(t) - b * v - K * y
    for _ in range(round((t1 - t0) / h)):
        k1 = (v, acc(t, y, v)); k2 = (v + h / 2 * k1[1], acc(t + h / 2, y + h / 2 * k1[0], v + h / 2 * k1[1]))
        k3 = (v + h / 2 * k2[1], acc(t + h / 2, y + h / 2 * k2[0], v + h / 2 * k2[1]))
        k4 = (v + h * k3[1], acc(t + h, y + h * k3[0], v + h * k3[1]))
        y += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); v += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]); t += h
        out[round(t, 3)] = y
    return out
push = lambda t: F0 * math.cos(2 * PI * XI0 * t)
run = rk4(push, B, 0, 10)
for t in (1, 3, 10):
    print(f"  t {t:2} s: from rest, Laplace {full(t):.6f}  steps {run[t]:.6f} | Fourier steady {yss(t):.6f} | gap {full(t) - yss(t):.6f} m")
# a pulse push 10 exp(-t^2/(2 * 0.25^2)): transform, divide by P, invert; against stepping from rest at -3 s
fp = lambda xi: F0 * math.sqrt(2 * PI) * 0.25 * math.exp(-2 * PI * PI * 0.0625 * xi * xi)
inv = lambda t, cut=6: simpson(lambda xi: (fp(xi) / P(xi) * complex(math.cos(2 * PI * xi * t), math.sin(2 * PI * xi * t))).real, -cut, cut, 400 * cut)
pr = rk4(lambda t: F0 * math.exp(-t * t / 0.125), B, -3, 2)
print("pulse: t s | transform-divide-invert | steps from rest at -3 s")
print(f"  frequency cut-off 6 Hz, pulse transform there {sci(fp(6), 1)}; cut-off 4 Hz gives {inv(1, 4):.6f} at 1 s")
print(f"  roots of s^2 + 2s + 5, s Laplace's variable: {-B / 2:.6f} +- {math.sqrt(K - B * B / 4):.6f}i")
for t in (-1, 0, 1, 2):
    print(f"  {t:2} | {inv(t):.6f} | {pr[t]:.6f}")
# what breaks
xr = math.sqrt(K) / (2 * PI)
res = rk4(lambda t: F0 * math.cos(2 * PI * xr * t), 0.0, 0, 20)
KW = KAPPA * T                      # the wrong fade exp(-KW xi^2) is slow, so its cut-off is 20 per m, not 3
wrong, wrong12, wbell = by_transform(0, c=KW, cut=20.0, n=4000), by_transform(0, c=KW, cut=12.0, n=2400), closed(0, sig=math.sqrt(KW / (2 * PI * PI)))
print("what breaks")
print(f"  omega form with xi per metre, exp(-kappa t xi^2): joint at noon {wrong:.6f} C")
print(f"    cut-off 20 per m; 12 per m gives {wrong12:.6f}; closed form, a bell of variance kappa t/(2 pi^2), {wbell:.6f}")
print(f"  time run backwards: the 1 per m ripple grows by exp(+C) = {math.exp(C):.1f}")
print(f"  held end ignored: {closed(0):.6f} C instead of {held:.6f}")
print(f"  steady state read as the from-rest answer at 1 s: {yss(1):.6f} m instead of {full(1):.6f}")
print(f"  no damping at resonance {xr:.6f} Hz: |P| = {abs(P(xr, 0.0)):.6f}; from rest |y| reaches {max(abs(v) for v in res.values()):.4f} m by 20 s")
print("try changing")
print(f"  09:00 instead of noon: joint {closed(0, sig=math.sqrt(2 * KAPPA * T / 2)):.6f} C")
print(f"  narrower weld, half-width 0.25 m: noon joint {closed(0, half=0.25):.6f} C")
print(f"  air loss rate 2e-5 per s: every frequency times exp(-0.432), joint {closed(0) * math.exp(-2e-5 * T):.6f} C")
print(f"  push at 0.5 Hz: amplitude {F0 / abs(P(0.5)):.6f} m")
assert abs(u_tr - u_c) < 1e-9 and abs(u_k - u_c) < 1e-6, "transform and kernel must give the closed form"
assert abs(u_d - u_c) < 0.05 and 3.5 < (u_d - u_c) / (u_d2 - u_c) < 4.5, "DFT twin: gap shrinks like step^2"
assert abs(by_transform(1.0) - closed(1.0)) < 1e-9, "transform road away from the joint"
assert abs(heat - 20) < 1e-6, "heat content is the transform at zero frequency, and it is kept"
assert abs(held - (closed(0) - closed(2 * D))) < 1e-6 and abs(ins - (closed(0) + closed(2 * D))) < 1e-6, "images"
assert abs(full(10) - run[10]) < 1e-8 and abs(full(1) - run[1]) < 1e-8, "Laplace road against stepping"
assert abs(full(10) - yss(10)) < 1e-3 < abs(full(1) - yss(1)), "the transient fades; Fourier keeps only the steady state"
assert all(abs(inv(t) - pr[t]) < 1e-6 for t in (-1, 0, 1, 2)), "transform-divide-invert against stepping"
assert abs(bell - u_c) < 0.1, "spreads add: the bell estimate is close"
assert abs(wrong - wbell) < 1e-9, "the wrong fade blurs by a narrower bell"
print("ALL CHECKS PASS")
