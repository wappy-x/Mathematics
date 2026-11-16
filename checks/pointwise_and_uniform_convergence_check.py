# Dirichlet's theorem on a sawtooth: where the series equals the signal, where it averages the jump.
# Standard library only. Only sin, cos, pi, sqrt and log are imported; every sum, kernel and
# integral (Simpson's rule) is written out here.
from math import sin, cos, pi, sqrt, log

def fmt(v):
    return f"{0.0 if abs(v) < 5e-13 else v:.6f}"

def saw(u):                      # the sawtooth, in volts: u/pi on (-pi, pi)
    return u / pi

def saw_sum(N, x):               # S_N f(x) = (2/pi) * sum of (-1)^(n+1) sin(n x)/n, n = 1..N
    s = 0.0
    for n in range(1, N + 1):
        s += (1.0 if n % 2 else -1.0) * sin(n * x) / n
    return 2.0 * s / pi

def ramp_sum(N, x):              # half ramp g: u/pi on (0, pi), 0 on (-pi, 0); its S_N g(x)
    s = 0.25
    for n in range(1, N + 1):
        sg = 1.0 if n % 2 else -1.0
        s += -(1.0 + sg) / (pi * pi * n * n) * cos(n * x) + sg / (pi * n) * sin(n * x)
    return s

def tri(x):                      # triangle wave, in volts: 1 - 2|x|/pi
    return 1.0 - 2.0 * abs(x) / pi

def tri_sum(N, x):               # S_N T(x) = (8/pi^2) * sum over odd n <= N of cos(n x)/n^2
    s = 0.0
    for n in range(1, N + 1, 2):
        s += cos(n * x) / (n * n)
    return 8.0 * s / (pi * pi)

def simpson(g, a, b, m):
    h = (b - a) / m
    s = g(a) + g(b)
    for k in range(1, m):
        s += (4 if k % 2 else 2) * g(a + k * h)
    return s * h / 3

def dirichlet(N, t):             # D_N(t) = sin((N + 1/2) t) / sin(t/2); 2N + 1 at t = 0
    d = sin(t / 2)
    return 2 * N + 1.0 if abs(d) < 1e-12 else sin((N + 0.5) * t) / d

def kernel(sig, a, b, N, x):     # (1/2pi) * integral over (a, b) of sig(u) D_N(x - u) du
    return simpson(lambda u: sig(u) * dirichlet(N, x - u), a, b, 20000) / (2 * pi)

NS = (10, 90, 1000)
print("sawtooth f(x) = x/pi volts on (-pi, pi), snapping from +1 V to -1 V at x = pi")
print(f"at 220 Hz the harmonics below 20000 Hz are n = 1..{20000 // 220}, top {220 * 90} Hz")
print(f"one cycle = {1000 / 220:.6f} ms; x = pi/2 is {0.75 * 1000 / 220:.6f} ms after the ramp starts; "
      f"x = 0.99 pi and 0.999 pi are {0.005e6 / 220:.3f} and {0.0005e6 / 220:.3f} microseconds before the snap")
row = []
for n in (1, 2, 90):             # road 1: Simpson on the coefficient integral; road 2: 1/(pi n)
    num = simpson(lambda u: saw(u) * sin(n * u), -pi, pi, 40000) / (2 * pi)
    assert abs(abs(num) - 1 / (pi * n)) < 1e-9
    row.append(f"n = {n}: {fmt(abs(num))} by Simpson, {fmt(1 / (pi * n))} = 1/(pi n)")
print("coefficient size |f^(n)|: " + "; ".join(row))
snap = [saw_sum(N, pi) for N in NS]
assert all(abs(v) < 1e-9 for v in snap)                # the midpoint of +1 and -1
print("at the snap x = pi: " + ", ".join(f"S_{N} = {fmt(v)}" for N, v in zip(NS, snap)) + "; midpoint (1 + (-1))/2 = 0")
print("at x = pi/2 by hand: " + ", ".join(f"S_{N} = {fmt(saw_sum(N, pi / 2))}" for N in (1, 3, 5)))
err = [saw_sum(N, pi / 2) - 0.5 for N in NS]
assert abs(err[0]) > abs(err[1]) > abs(err[2]) and abs(err[2]) < 1e-3
print("at x = pi/2, f = 0.5 V, error S_N - f: " + ", ".join(f"N = {N}: {fmt(e)}" for N, e in zip(NS, err)))
k90 = kernel(saw, -pi, pi, 90, pi / 2)                 # road 2: the signal smeared by D_90
assert abs(k90 - saw_sum(90, pi / 2)) < 1e-9
print(f"at x = pi/2, N = 90: by the terms {fmt(saw_sum(90, pi / 2))}, by the kernel integral {fmt(k90)}")
row = []
for c in (0.5, 0.9, 0.99, 0.999):
    row.append(f"x = {c:g} pi: {fmt(saw_sum(90, c * pi) - c)}")
assert abs(saw_sum(5000, 0.9 * pi) - 0.9) < 1e-3       # far from the snap the ramp is reached
print("error at N = 90, f = x/pi: " + ", ".join(row))
gap = [saw(pi - 1e-6) - saw_sum(N, pi - 1e-6) for N in NS]
assert all(g > 0.99 for g in gap)                     # worst gap never shrinks: not uniform
print("just left of the snap, x = pi - 0.000001, gap f - S_N: " + ", ".join(f"N = {N}: {fmt(g)}" for N, g in zip(NS, gap)))
row = []
for N in NS:                     # sum of |f^(n)| over |n| <= N, n != 0, against the log road
    tot = 2 * sum(1 / (pi * n) for n in range(1, N + 1))
    lg = (2 / pi) * (log(N) + 0.5772156649015329 + 1 / (2 * N) - 1 / (12 * N * N))
    assert abs(tot - lg) < 1e-6
    row.append(f"N = {N}: {fmt(tot)}")
print("sizes added, sum of |f^(n)| for 0 < |n| <= N: " + ", ".join(row) + "; grows like (2/pi) log N")
print(f"half ramp g: equals f on (0, pi), is 0 on (-pi, 0); S_1 g(pi/2) = {fmt(ramp_sum(1, pi / 2))}, S_1 f(pi/2) = {fmt(saw_sum(1, pi / 2))}, "
      f"difference {fmt(saw_sum(1, pi / 2) - ramp_sum(1, pi / 2))}")
dif = [saw_sum(N, pi / 2) - ramp_sum(N, pi / 2) for N in NS]
kd = kernel(saw, -pi, 0.0, 90, pi / 2)                # road 2: only the part where f and g differ
assert abs(kd - dif[1]) < 1e-9 and abs(dif[2]) < 1e-3 < abs(dif[0])
print("at x = pi/2, S_N f - S_N g: " + ", ".join(f"N = {N}: {fmt(d)}" for N, d in zip(NS, dif)) + f"; by the kernel at N = 90: {fmt(kd)}")
row = []
for N in NS:
    xs = [pi * (k - 1000) / 1000 for k in range(2001)]
    worst = max(abs(tri(x) - tri_sum(N, x)) for x in xs)   # road 1: brute force over the cycle
    cap = sum(8 / (pi * pi * n * n) for n in range(N + 1 + N % 2, 2000001, 2)) + 4 / (pi * pi * 2000001)
    assert abs(worst - cap) < 1e-6                        # road 2: the M-test tail of the caps
    row.append(f"N = {N}: worst {fmt(worst)}, tail {fmt(cap)}")
print("triangle T(x) = 1 - 2|x|/pi volts, worst error over the cycle against the M-test tail:")
print("  " + "; ".join(row))
tot = 2 * sum(4 / (pi * pi * n * n) for n in range(1, 2000001, 2)) + 4 / (pi * pi * 2000001)
assert abs(tot - 1.0) < 1e-6                              # sum of |T^(n)| = T(0) = 1
d2 = simpson(lambda u: (2 / pi) ** 2, -pi, pi, 2) / (2 * pi)  # ||T'||^2, T' = -+2/pi
p2 = 2 * sum(16 / (pi ** 4 * n * n) for n in range(1, 2000001, 2)) + 8 / (pi ** 4 * 2000001)
assert abs(d2 - p2) < 1e-6                                # Parseval for T' agrees with the integral
bound = pi / sqrt(3) * sqrt(d2)
assert bound > tot                                        # the bound sits above the true total
print(f"sum of |T^(n)| = {fmt(tot)}; ||T'|| = {fmt(sqrt(d2))} (by coefficients {fmt(sqrt(p2))}); bound (pi/sqrt 3) ||T'|| = {fmt(bound)}; ratio {fmt(tot / bound)}")
first = 8 / (pi * pi * 91 * 91)
true90 = 1.0 - tri_sum(90, 0.0)
assert true90 > 40 * first
print(f"what breaks: first omitted cap at N = 90 is {fmt(first)}; true worst error {fmt(true90)}, {true90 / first:.1f} times larger")
xs = [k * pi / 20 for k in range(21)]
print("figure, x: " + ", ".join(f"{x:.2f}" for x in xs))
print("figure, f: " + ", ".join(f"{saw(x):.2f}" for x in xs))
for N in (5, 90):
    print(f"figure, S_{N}: " + ", ".join(f"{0.0 if abs(v) < 5e-3 else v:.2f}" for v in (saw_sum(N, x) for x in xs)))
print("ALL CHECKS PASS")
