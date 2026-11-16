# The Fourier transform on L1 and Riemann-Lebesgue -- the check behind the card.
# Standard library only.  Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt,
# t in seconds, xi in hertz, so fhat is in seconds; it is printed in milliseconds.
# The shutter is open (f = 1) for one millisecond, -T/2 < t < T/2.
from math import pi, sin, cos, sqrt

T = 0.001                                    # shutter open time, seconds

def ms(x):                                   # seconds to milliseconds, tiny values zeroed
    v = 1000 * x
    return 0.0 if abs(v) < 5e-10 else v

def gate_hat(xi, a, b):                      # transform of 1 on [a, b), closed form
    if xi == 0:
        return (b - a, 0.0)
    w = 2 * pi * xi                          # (e^(-iwa) - e^(-iwb)) / (iw)
    return ((sin(w * b) - sin(w * a)) / w, (cos(w * b) - cos(w * a)) / w)

def by_integral(f, a, b, xi, n):             # the defining integral, midpoint rule, n cells
    h, re, im = (b - a) / n, 0.0, 0.0
    for k in range(n):
        t = a + (k + 0.5) * h
        re += f(t) * cos(2 * pi * xi * t) * h
        im -= f(t) * sin(2 * pi * xi * t) * h
    return (re, im)

def size(z):
    return sqrt(z[0] ** 2 + z[1] ** 2)

gate = lambda t: 1.0 if -T / 2 <= t < T / 2 else 0.0
print("shutter: open 1 ms; area of |f| = %.6f ms" % ms(T))
print("xi Hz | closed form ms | integral n=8000 ms | gap n=4000 vs 8000 | share of xi = 0")
worst = 0.0
for xi in [0, 120, 500, 1000, 1500, 2500, 20500]:
    c = gate_hat(xi, -T / 2, T / 2)[0]
    n1, n2 = by_integral(gate, -T / 2, T / 2, xi, 4000), by_integral(gate, -T / 2, T / 2, xi, 8000)
    worst = max(worst, abs(c - n2[0]), abs(n2[1]))
    print("%5d | %.6f | %.6f | %.9f | %.6f" % (xi, ms(c), ms(n2[0]), ms(abs(n1[0] - n2[0])), ms(c) / ms(T)))
print("largest gap, closed form vs integral: %.9f ms" % ms(worst))
assert worst < 1e-9                                       # road 1 = road 2

# Third road: a light flickering 100% at 120 Hz, exposure for two shutter start times.
xi = 120.0
expo = lambda t0: by_integral(lambda t: 1 + cos(2 * pi * xi * (t - t0)), -T / 2, T / 2, 0, 4000)[0]
e_hi, e_lo = expo(0.0), expo(1 / (2 * xi))
print("120 Hz flicker: exposure %.6f ms to %.6f ms; half the swing %.6f ms = fhat(120)"
      % (ms(e_hi), ms(e_lo), ms((e_hi - e_lo) / 2)))
assert abs((e_hi - e_lo) / 2 - gate_hat(120, -T / 2, T / 2)[0]) < 1e-11
print("by hand at 120 Hz: pi xi T = %.6f, sin of it = %.6f, pi xi = %.3f per second"
      % (pi * 120 * T, sin(pi * 120 * T), pi * 120))

# Bounded: |fhat| <= area of |f|.  Continuous: one roof 2|f| for every frequency.
grid = [50 * k for k in range(-400, 401)]
top = max(size(gate_hat(x, -T / 2, T / 2)) for x in grid)
print("largest |fhat| on -20 to 20 kHz: %.6f ms, bound %.6f ms" % (ms(top), ms(T)))
h = 10.0
jump = max(abs(gate_hat(x + h, -T / 2, T / 2)[0] - gate_hat(x, -T / 2, T / 2)[0]) for x in range(0, 5001))
roof = 4 / (pi * h) * (1 - cos(pi * h * T / 2))          # integral of |f| |e^(-2 pi i h t) - 1|
roof_n = by_integral(lambda t: size((cos(2 * pi * h * t) - 1, sin(2 * pi * h * t))), -T / 2, T / 2, 0, 4000)[0]
print("step h = %g Hz: largest change %.6f ms; bound %.6f ms (integral %.6f); ratio %.3f"
      % (h, ms(jump), ms(roof), ms(roof_n), jump / roof))
assert top <= T + 1e-15 and jump <= roof and abs(roof - roof_n) < 1e-12

print("chart xi Hz: [" + ", ".join(str(250 * k) for k in range(21)) + "]")
print("chart fhat ms: [" + ", ".join("%.3f" % ms(gate_hat(250 * k, -T / 2, T / 2)[0]) for k in range(21)) + "]")
print("chart bound ms: [" + ", ".join("%.3f" % min(1.0, ms(1 / (pi * 250 * k))) if k else "1.000" for k in range(21)) + "]")
print("gate at 20500 Hz: |fhat| %.6f ms, fade bound 1/(pi xi) %.6f ms"
      % (ms(abs(gate_hat(20500, -T / 2, T / 2)[0])), ms(1 / (pi * 20500))))

# Riemann-Lebesgue by approximation: a leaf shutter with 0.2 ms ramps, matched by staircases.
def leaf(t):
    return max(0.0, min(1.0, (T / 2 - abs(t)) / 0.0002))
def leaf_hat(xi):                            # gate of 0.8 ms smoothed by a 0.2 ms ramp
    return T * 0.8 if xi == 0 else sin(pi * xi * 0.0008) / (pi * xi) * sin(pi * xi * 0.0002) / (pi * xi * 0.0002)
lh = by_integral(leaf, -T / 2, T / 2, 3000, 8000)
print("leaf shutter at 3000 Hz: closed form %.6f ms, integral %.6f ms (gap %.9f ms)" % (ms(leaf_hat(3000)), ms(lh[0]), ms(abs(leaf_hat(3000) - lh[0]))))
assert abs(leaf_hat(3000) - lh[0]) < 1e-10
def staircase(n):                            # n equal cells, each at the leaf's middle value
    w = T / n
    return [(-T / 2 + k * w, -T / 2 + (k + 1) * w, leaf(-T / 2 + (k + 0.5) * w)) for k in range(n)]
def stair_hat(st, xi):
    zs = [gate_hat(xi, a, b) for a, b, _ in st]
    return (sum(c * z[0] for (_, _, c), z in zip(st, zs)), sum(c * z[1] for (_, _, c), z in zip(st, zs)))
def l1_gap(st, n):                           # area of |leaf - staircase|, midpoint rule
    return by_integral(lambda t: abs(leaf(t) - st[min(n - 1, int((t + T / 2) / (T / n)))][2]), -T / 2, T / 2, 0, 40000)[0]
for n in [5, 10, 20, 40]:
    st = staircase(n)
    l1 = l1_gap(st, n)
    gap = max(size((leaf_hat(x) - stair_hat(st, x)[0], stair_hat(st, x)[1])) for x in range(0, 50001, 5))
    print("staircase %2d steps: area of |leaf - stair| %.6f ms; largest spectrum gap, 5 Hz grid %.6f ms" % (n, ms(l1), ms(gap)))
    assert gap <= l1 + 1e-12 and abs(l1 - 0.0005 / n) < 1e-9
steps = 200                                  # the staircase used in the epsilon argument
st = staircase(steps)
jumps = sum(abs(st[k][2] - (st[k - 1][2] if k else 0.0)) for k in range(steps)) + st[-1][2]
eps, l1 = 0.00001, l1_gap(st, steps)
xi0 = jumps / (2 * pi * (eps - l1))          # staircase fades like jumps / (2 pi xi)
print("target %.3f ms: %d steps, gap %.4f ms, left for the staircase %.4f ms, total jump %.6f; beyond %.1f Hz"
      % (ms(eps), steps, ms(l1), ms(eps - l1), jumps, xi0))
print("leaf |fhat| at that frequency: %.8f ms" % ms(abs(leaf_hat(xi0))))
assert abs(leaf_hat(xi0)) < eps and size(stair_hat(st, xi0)) <= jumps / (2 * pi * xi0)

# An unbounded signal, sqrt(T/t) for 0 < t < T: no piecewise-smooth proof applies, yet it fades.
def spike_hat(x, n):                         # t = T u^2: integral of 2T e^(-2 pi i x u^2), Simpson
    re = im = 0.0
    for k in range(n + 1):
        u, wt = k / n, (1 if k in (0, n) else 4 if k % 2 else 2)
        re += wt * cos(2 * pi * x * u * u)
        im -= wt * sin(2 * pi * x * u * u)
    return (2 * T * re / (3 * n), 2 * T * im / (3 * n))
print("spike: area of |f| = %.6f ms" % ms(2 * T))
for x in [1, 10, 100]:                       # x = xi T, a whole number
    a, b = spike_hat(x, 20000), spike_hat(x, 40000)
    far = (T / (2 * sqrt(x)), -T / (2 * sqrt(x)) + T / (2 * pi * x))   # Fresnel, less the tail past u = 1
    print("spike at %6d Hz: |fhat| %.6f ms, step gap %.9f, Fresnel %.6f ms; xi |fhat| %.4f"
          % (1000 * x, ms(size(b)), ms(size((a[0] - b[0], a[1] - b[1]))), ms(size(far)), 1000 * x * size(b)))
    assert size(b) <= 2 * T and abs(size(a) - size(b)) < 1e-12
    assert x == 1 or abs(size(b) - size(far)) < T / x ** 2

for L in [1.0, 1 + 1 / 480, 1 + 3 / 480]:              # constant light: no finite area
    print("mistake 1, constant light, integral over -L to L = %.5f s at 120 Hz: %.6f ms"
          % (L, ms(sin(2 * pi * 120 * L) / (pi * 120))))
print("mistake 2, omega form fed hertz: 2 sin(500 T/2)/500 = %.6f ms, true %.6f ms"
      % (ms(2 * sin(500 * T / 2) / 500), ms(gate_hat(500, -T / 2, T / 2)[0])))
pulse = lambda t: 1.0 if t < 0 else -1.0                   # +1 then -1: not even, so it pins the sign
pm = (gate_hat(1000, -T / 2, 0)[0] - gate_hat(1000, 0, T / 2)[0], gate_hat(1000, -T / 2, 0)[1] - gate_hat(1000, 0, T / 2)[1])
pn = by_integral(pulse, -T / 2, T / 2, 1000, 8000)
print("mistake 3, +1 then -1 pulse: net area %.3f ms, but fhat(1000) = %.6fi ms (integral %.6fi ms), size %.6f ms"
      % (ms(by_integral(pulse, -T / 2, T / 2, 0, 8000)[0]), ms(pm[1]), ms(pn[1]), ms(size(pm))))
assert abs(pm[0] - pn[0]) < 1e-10 and abs(pm[1] - pn[1]) < 1e-10   # the sign of the exponent
print("ALL CHECKS PASS")
