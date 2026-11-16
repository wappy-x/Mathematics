# Densities add by convolution -- the check behind the card.  Standard library only.
# Packing delay X uniform on [0, 2] h, courier delay Y uniform on [0, 3] h, independent.
# Roads to the total S = X + Y: the trapezoid by hand, the convolution integral,
# step laws convolved on a grid, the transform product inverted, and simulation.
import math
from fractions import Fraction as Fr

A, B, D = 2.0, 3.0, 4.0     # widths of the two delays and the promise, hours: whole, A <= B <= D <= A + B
M = (A + B) / 2             # centre of the total
def f(x): return 1 / A if 0 <= x < A else 0.0
def g(y): return 1 / B if 0 <= y < B else 0.0
def trap(s): return max(0.0, min(A, s) - max(0.0, s - B)) / (A * B)   # overlap length / (A B)
def conv(s, n=6000):                          # midpoint sum of the integral of f(x) g(s - x) dx
    dx = A / n
    return sum(f((k + 0.5) * dx) * g(s - (k + 0.5) * dx) for k in range(n)) * dx
def simpson(fn, a, b, n):
    hh = (b - a) / n
    return hh / 3 * sum((1 if k in (0, n) else 4 if k % 2 else 2) * fn(a + k * hh) for k in range(n + 1))
def sinc(u): return 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
def Phi(z):                                   # standard bell's area left of z, by its power series
    t, s, n = z, z, 0
    while abs(t) > 1e-17:
        n += 1
        t *= -z * z / (2 * n)
        s += t / (2 * n + 1)
    return 0.5 + s / math.sqrt(2 * math.pi)
M64 = (1 << 64) - 1
state = 2026
def unif():                                   # SplitMix64, seed 2026, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

print(f"X uniform on [0, {A:.1f}] h, Y uniform on [0, {B:.1f}] h, independent; S = X + Y; promise D = {D:.1f} h")
for s in (1.0, M, 4.0):
    print(f"h({s:.1f}) trapezoid {trap(s):.6f}  convolution integral {conv(s):.6f}")
    assert abs(trap(s) - conv(s)) < 1e-9
exact = 1 - Fr(int(A + B - D)) ** 2 / (2 * int(A * B))   # late corner: a triangle of side A + B - D
area = simpson(trap, 0, A, 200) + simpson(trap, A, B, 100) + simpson(trap, B, D, 100)
print(f"P(S <= D): exact {exact} = {float(exact):.6f}  late {1 - exact} = {float(1 - exact):.6f}  area under trapezoid {area:.6f}")
assert abs(area - float(exact)) < 1e-12
for step in (60, 360):                        # step laws: minutes, then 10-second steps
    nx, ny = int(A * step), int(B * step)
    pmf = [0] * (nx + ny - 1)
    for i in range(nx):
        for j in range(ny):
            pmf[i + j] += 1                   # X = (i + 1/2)/step, Y = (j + 1/2)/step
    on = Fr(sum(pmf[: int(D * step) - 1]), nx * ny)   # atoms below D; the atom at S = D is left out
    print(f"grid of 1/{step} h: P(S < D) {float(on):.6f}  gap {float(on - exact):.6f}  peak h {max(pmf) * step / (nx * ny):.6f}")
assert abs(float(on - exact)) < 1e-3
N, hit, tied, cs, sn = 200000, 0, 0, 0.0, 0.0
for _ in range(N):
    x, y = A * unif(), B * unif()
    hit += x + y <= D
    tied += x + B / A * x <= D                # what breaks: Y = (B/A) X, the same storm hits both
    cs += math.cos(2 * math.pi * 0.25 * (x + y)); sn -= math.sin(2 * math.pi * 0.25 * (x + y))
se = math.sqrt(float(exact) * (1 - float(exact)) / N)
print(f"simulated {N} orders: P(S <= D) {hit / N:.4f}  standard error {se:.4f}")
assert abs(hit / N - float(exact)) <= 4 * se
print("frequency: hat f(xi) = e^(-i pi A xi) sinc(A xi), xi in cycles per hour")
xi = 0.25
mag = sinc(A * xi) * sinc(B * xi)
pr, pi_ = mag * math.cos(math.pi * (A + B) * xi), -mag * math.sin(math.pi * (A + B) * xi)
dr = simpson(lambda s: trap(s) * math.cos(2 * math.pi * xi * s), 0, A + B, 3000)
di = simpson(lambda s: -trap(s) * math.sin(2 * math.pi * xi * s), 0, A + B, 3000)
print(f"xi = 0.25: sinc(A xi) {sinc(A * xi):.6f}  sinc(B xi) {sinc(B * xi):.6f}  |product| {mag:.6f}"
      f"  phase {math.cos(math.pi * (A + B) * xi):.6f} {-math.sin(math.pi * (A + B) * xi):+.6f}i")
print(f"  product {pr:.6f} {pi_:+.6f}i  transform of h {dr:.6f} {di:+.6f}i  simulated {cs / N:.4f} {sn / N:+.4f}i")
assert abs(pr - dr) < 1e-9 and abs(pi_ - di) < 1e-9
assert abs(cs / N - pr) < 4 * math.sqrt(0.5 / N) and abs(sn / N - pi_) < 4 * math.sqrt(0.5 / N)
for z in (1 / B, 1 / A, 2 / B):
    dz = abs(complex(simpson(lambda s: trap(s) * math.cos(2 * math.pi * z * s), 0, A + B, 3000),
                     simpson(lambda s: trap(s) * math.sin(2 * math.pi * z * s), 0, A + B, 3000)))
    print(f"  zero of a factor at xi = {z:.6f}: |transform of h| {dz:.6f}")
    assert dz < 1e-9
for cut in (25, 100):                         # invert at the centre: h(M) = integral of sinc(A xi) sinc(B xi)
    inv = 2 * simpson(lambda u: sinc(A * u) * sinc(B * u), 0, cut, 400 * cut)
    tail = 2 / (math.pi ** 2 * A * B * cut)
    print(f"inverse at s = {M:.1f}, cut-off {cut}/h: {inv:.9f}  gap {abs(inv - trap(M)):.9f}  tail bound {tail:.6f}")
    assert abs(inv - trap(M)) <= tail
v1, v2 = A * A / 12, B * B / 12               # the same delays as bell curves, same centres and spreads
sd = math.sqrt(v1 + v2)
bell = lambda s, m, v: math.exp(-(s - m) ** 2 / (2 * v)) / math.sqrt(2 * math.pi * v)
for s in (M, 4.0):
    num = simpson(lambda x: bell(x, A / 2, v1) * bell(s - x, B / 2, v2), -9, 11, 4000)
    print(f"bells: h({s:.1f}) convolution integral {num:.6f}  one bell, variances added {bell(s, M, v1 + v2):.6f}")
    assert abs(num - bell(s, M, v1 + v2)) < 1e-9
pb = Phi((D - M) / sd)
print(f"bells: sd {sd:.6f} h  P(S <= D) {pb:.6f}  P(S < 0) {Phi(-M / sd):.6f}  peak {bell(M, M, v1 + v2):.6f}")
print(f"centres {A / 2:.6f} + {B / 2:.6f} = {M:.6f} h; spreads added {math.sqrt(v1):.6f} + {math.sqrt(v2):.6f}"
      f" = {math.sqrt(v1) + math.sqrt(v2):.6f} h, true spread {sd:.6f} h")
vt = sum(simpson(lambda s: (s - M) ** 2 * trap(s), a, b, 300) for a, b in ((0, A), (A, B), (B, A + B)))
print(f"bells: variances {v1:.6f} + {v2:.6f} = {v1 + v2:.6f} h^2; the trapezoid's own variance {vt:.6f} h^2")
assert abs(vt - (v1 + v2)) < 1e-12                       # the bells get the true total's spread
assert abs(pb - 0.5 - simpson(lambda z: bell(z, 0, 1), 0, (D - M) / sd, 2000)) < 1e-12   # series against area
l2 = math.sqrt(sum(simpson(lambda s: trap(s) ** 2, a, b, 300) for a, b in ((0, A), (A, B), (B, A + B))))
peak = max(trap(k / 100) for k in range(int(100 * (A + B)) + 1))
print(f"Young: peak h {peak:.6f} <= |f|_1 |g|_inf {1 / B:.6f} and |f|_inf |g|_1 {1 / A:.6f}")
print(f"Young: |h|_2 {l2:.6f} (exact {math.sqrt((B - A / 3) / B ** 2):.6f}) <= |g|_2 {math.sqrt(1 / B):.6f}  ratio {l2 / math.sqrt(1 / B):.6f}")
assert abs(l2 - math.sqrt((B - A / 3) / B ** 2)) < 1e-12 and l2 <= math.sqrt(1 / B) and peak <= 1 / B
slope = max(abs(trap(k / 100 + 0.01) - trap(k / 100)) / 0.01 for k in range(-100, 600))
print(f"smoothing: steepest slope of h {slope:.6f} per h^2, bound |f|_inf * 2/B {2 / (A * B):.6f}")
assert abs(slope - 1 / (A * B)) < 1e-9
mids = [(k + 0.5) / 100 for k in range(int(100 * D))]   # midpoint sums up to the promise
mix = sum(0.5 * (f(x) + g(x)) for x in mids) / 100
prod = sum(f(x) * g(x) for x in mids) / 100
print(f"what breaks: mixture P {mix:.6f}  product area {prod:.6f}"
      f"  tied delays exact {D / (A + B):.6f} simulated {tied / N:.4f}")
assert abs(tied / N - D / (A + B)) <= 4 * math.sqrt(0.25 / N)
print("chart s: " + " ".join(f"{k / 4:.2f}" for k in range(21)))
print("chart f: " + " ".join(f"{f(k / 4):.3f}" for k in range(21)))
print("chart g: " + " ".join(f"{g(k / 4):.3f}" for k in range(21)))
print("chart h: " + " ".join(f"{trap(k / 4):.3f}" for k in range(21)))
print("chart bell: " + " ".join(f"{bell(k / 4, M, v1 + v2):.3f}" for k in range(21)))
print("ALL CHECKS PASS")
