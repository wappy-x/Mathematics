# Plancherel -- the check behind the card.  Standard library only; the DFT,
# Simpson's rule and the sine integral Si are written out here.  The signal is a
# radar pulse: 1 V RMS for |t| < 1 microsecond into 1 ohm, so energies are in uJ.
# Its transform is F(w) = 2 sin(w)/w, with w in radians per microsecond.
import math
PI = math.pi

def simpson(f, a, b, n):                       # Simpson's rule, n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def sinc(u):
    return 1.0 if u == 0 else math.sin(u) / u

def si(x):                                     # sine integral Si(x), step at most 0.01
    return simpson(sinc, 0, x, 2 * max(50, int(abs(x) * 50)))

def F(w, a=1.0):                               # transform of the pulse 1 on |t| < a
    return 2 * a * sinc(a * w)

def dft(x):                                    # sum x_n e^(-2 pi i k n / N)
    N = len(x)
    return [sum(x[n] * complex(math.cos(2 * PI * k * n / N), -math.sin(2 * PI * k * n / N))
                for n in range(N)) for k in range(N)]

def inside(W, a=1.0):                          # energy (1/2 pi) * integral of |F|^2 over |w| < W
    return 2 * simpson(lambda w: F(w, a) ** 2, 0, W, 2 * max(50, int(W * 50))) / (2 * PI)

def tail(W):                                   # energy beyond |w| = W, closed form
    return 4 / PI * (math.sin(W) ** 2 / W + PI / 2 - si(2 * W))

# ---- finite rehearsal: the DFT divided by sqrt(N) is a rigid rotation ----
N = 8
U = [[complex(math.cos(2 * PI * k * n / N), -math.sin(2 * PI * k * n / N)) / math.sqrt(N)
      for n in range(N)] for k in range(N)]
e1 = max(abs(sum(U[j][k].conjugate() * U[j][m] for j in range(N)) - (k == m))
         for k in range(N) for m in range(N))
e2 = max(abs(sum(U[k][j] * U[j][m] for j in range(N)) - ((k + m) % N == 0))
         for k in range(N) for m in range(N))
print(f"N=8: U*U = I to within 1e-12: {'yes' if e1 < 1e-12 else 'no'}; "
      f"U^2 reverses the list, so U^4 = I: {'yes' if e2 < 1e-12 else 'no'}")
assert e1 < 1e-12
assert e2 < 1e-12
errs = []
for N in (8, 32, 128):                          # the pulse sampled on a window of 8 us
    dt = 8 / N
    x = [1.0 if abs(-4 + (n + 0.5) * dt) < 1 else 0.0 for n in range(N)]
    X = dft(x)
    et, ef = dt * sum(v * v for v in x), dt * sum(abs(c) ** 2 for c in X) / N
    print(f"N={N:3d}, dt={dt:.4f} us: time energy {et:.6f} uJ, frequency energy {ef:.6f} uJ, "
          f"|dt X_1| {dt * abs(X[1]):.6f} against F(pi/4) {F(PI / 4):.6f}")
    assert abs(et - ef) < 1e-12 and abs(et - 2) < 1e-12
    errs.append(abs(dt * abs(X[1]) - F(PI / 4)))
assert all(b < a / 10 for a, b in zip(errs, errs[1:]))   # the sampled spectrum closes on F
x = [1 / (1 + n) for n in range(8)]             # the blur (1/4, 1/2, 1/4) on 8 samples
bx = [x[n - 1] / 4 + x[n] / 2 + x[(n + 1) % 8] / 4 for n in range(8)]
gain = [math.cos(PI * k / 8) ** 2 for k in range(8)]
gap = max(abs(b - g * c) for b, g, c in zip(dft(bx), gain, dft(x)))
print("blur gains by frequency:", " ".join(f"{g:.3f}" for g in gain), f"| worst case {max(gain):.3f}")
assert gap < 1e-12

# ---- Plancherel for the pulse: 2 uJ in time, 2 uJ in frequency ----
for W in (PI / 2, PI, 2 * PI, 4 * PI):
    print(f"share of the energy in |w| < {W / PI:g} pi: {inside(W):.6f} uJ = {50 * inside(W):.4f} %")
for W in (10, 100, 1000):
    i, t = inside(W), tail(W)
    print(f"|w| < {W:4d}: inside {i:.6f}, tail (closed form) {t:.6f}, total {i + t:.6f} uJ")
    assert abs(i + t - 2) < 1e-7
print(f"without the 1/sqrt(2 pi): integral of |F|^2 = {2 * PI * 2:.6f}, not 2")
for w in (1.0, 2.5):                            # the triangle 2 - |s| transforms to |F|^2
    tri = 2 * simpson(lambda s: (2 - s) * math.cos(w * s), 0, 2, 2000)
    print(f"autocorrelation triangle at w = {w}: transform {tri:.6f}, |F|^2 {F(w) ** 2:.6f}")
    assert abs(tri - F(w) ** 2) < 1e-10
for d in (1.0, 0.5):                            # the pulse and its echo d us later
    Wc = 128 * PI
    ip = 2 * simpson(lambda w: F(w) ** 2 * math.cos(w * d), 0, Wc, 80000) / (2 * PI)
    ang = math.degrees(math.acos(ip / 2))
    print(f"echo after {d} us: overlap in time {2 - d:.6f}, in frequency {ip:.6f}, angle {ang:.4f} degrees")
    assert abs(ip - (2 - d)) < 1e-6

# ---- the extension by density: cut the spectrum at W, invert, let W grow ----
for M in (10, 100, 1000):                       # area under |F| has no limit
    area = 2 * sum(simpson(lambda w: abs(F(w)), j * PI, (j + 1) * PI, 400) for j in range(M))
    print(f"area under |F| for |w| < {M} pi: {area:.6f}")
    if M == 1000:
        print(f"last tenfold step adds {area - prev:.6f}; (8/pi) ln 10 = {8 / PI * math.log(10):.6f}")
        assert abs(area - prev - 8 / PI * math.log(10)) < 0.01
    prev = area
fW = lambda t, W: (si(W * (1 + t)) + si(W * (1 - t))) / PI
direct = simpson(lambda w: F(w) * math.cos(0.5 * w), 0, 10, 2000) / PI
print(f"rebuilt pulse W = 10 at t = 0.5: Si formula {fW(0.5, 10):.6f}, inverse integral {direct:.6f}")
assert abs(direct - fW(0.5, 10)) < 1e-8
d, R = 0.005, 100                               # Si table, step 0.005, by Simpson per step
S = [0.0]
for j in range(int(40 * (R + 1) / d) + 1):
    S.append(S[-1] + d / 6 * (sinc(j * d) + 4 * sinc((j + 0.5) * d) + sinc((j + 1) * d)))
Si = lambda j: S[j] if j >= 0 else -S[-j]
for W in (10, 20, 40):                           # error energy in time, grid 0.005 us
    g = [(Si(m * W + 200 * W) - Si(m * W - 200 * W)) / PI for m in range(200 * R + 1)]
    sv = lambda v: d / 3 * (v[0] + v[-1] + sum((4 if k % 2 else 2) * v[k] for k in range(1, len(v) - 1)))
    Et = 2 * (sv([(1 - y) ** 2 for y in g[:201]]) + sv([y * y for y in g[200:]]))
    print(f"W = {W}: error energy in time {Et:.6f}, in frequency {tail(W):.6f}, W x error {W * tail(W):.6f}")
    assert abs(Et - tail(W)) < 5e-5
for W in (10, 20, 40, 80):
    print(f"W = {W}: rebuild at t = 1 - pi/W, just inside the edge: {fW(1 - PI / W, W):.6f}")
    assert abs(fW(1 - PI / W, W) - (0.5 + si(PI) / PI)) < 0.02
print(f"its limit: 1/2 + Si(pi)/pi = {0.5 + si(PI) / PI:.6f}; 2/pi = {2 / PI:.6f}")
print("chart W=10:", ", ".join(f"{fW(k / 10, 10):.3f}" for k in range(21)))
print("chart W=40:", ", ".join(f"{fW(k / 10, 40):.3f}" for k in range(21)))
print("fixed times, W = 10, 100, 1000: t = 0.9 ->", " ".join(f"{fW(0.9, W):.6f}" for W in (10, 100, 1000)),
      "; edge t = 1 ->", " ".join(f"{fW(1.0, W):.6f}" for W in (10, 100, 1000)))
assert abs(fW(0.9, 1000) - 1) < abs(fW(0.9, 100) - 1) < abs(fW(0.9, 10) - 1) and abs(fW(1.0, 1000) - 0.5) < 1e-3

# ---- try changing ----
x = [1.0 if abs(-4 + (n + 0.5) * 8 / 512) < 1 else 0.0 for n in range(512)]
print(f"N=512: |dt X_1| {8 / 512 * abs(dft(x)[1]):.6f} against F(pi/4) {F(PI / 4):.6f}")
print(f"pulse 4 us long: main lobe |w| < pi/2 holds {inside(PI / 2, 2.0):.6f} of 4 uJ, "
      f"share {inside(PI / 2, 2.0) / 4:.6f}; W = 160: error energy {tail(160):.6f} uJ")
print("ALL CHECKS PASS")
