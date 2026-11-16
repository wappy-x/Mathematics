# The uncertainty principle -- the check behind the card.  Standard library only.
# A drum hit 10 ms wide (standard deviation of its energy in time): how narrow
# can its band be?  Floor 1/(4 pi dt).  Every transform and integral is written out.
from math import exp, sin, cos, pi, sqrt, log, atan

def simpson(fn, a, b, n):                       # n even: slices weighted 1, 4, 2, 4, ..., 1
    h = (b - a) / n
    s = fn(a) + fn(b) + sum((4 if i % 2 else 2) * fn(a + i * h) for i in range(1, n))
    return s * h / 3

def transform(f, xi, a, b, n):                  # f^(xi) = integral f(t) e^(-2 pi i xi t) dt
    return simpson(lambda t: f(t) * complex(cos(2 * pi * xi * t), -sin(2 * pi * xi * t)), a, b, n)

def spread_time(f, a, b, n):                    # (energy, mean time, dt) from |f|^2
    e = simpson(lambda t: abs(f(t)) ** 2, a, b, n)
    m = simpson(lambda t: t * abs(f(t)) ** 2, a, b, n) / e
    v = simpson(lambda t: (t - m) ** 2 * abs(f(t)) ** 2, a, b, n) / e
    return e, m, sqrt(v)

def moments(f, ta, tb, nt, xa, xb, nx):         # integrals of |f^|^2 times 1, xi, xi^2 over [xa, xb]
    h = (xb - xa) / nx
    xs = [xa + k * h for k in range(nx + 1)]
    w = [(1 if k in (0, nx) else (4 if k % 2 else 2)) * h / 3 for k in range(nx + 1)]
    p = [wk * abs(transform(f, x, ta, tb, nt)) ** 2 for wk, x in zip(w, xs)]
    return sum(p), sum(x * q for x, q in zip(xs, p)), sum(x * x * q for x, q in zip(xs, p))

def spread_freq(*args):                         # (energy, mean freq, dxi) from |f^|^2
    e, m1, m2 = moments(*args)
    return e, m1 / e, sqrt(m2 / e - (m1 / e) ** 2)

def spread_slope(f, a, b, n):                   # road 3: dxi = ||f'|| / (2 pi ||f||), f' by central difference
    d = 1e-7
    e = simpson(lambda t: f(t) ** 2, a, b, n)
    return sqrt(simpson(lambda t: ((f(t + d) - f(t - d)) / (2 * d)) ** 2, a, b, n) / e) / (2 * pi)

out = []
def show(label, x): out.append(f"{label:<46}{x:>14.6f}")

DT = 0.010                                      # the hit's spread in time, seconds
hit = lambda t: exp(-t * t / (4 * DT * DT))     # |hit|^2 is a bell curve of standard deviation DT
floor = 1 / (4 * pi * DT)
e_t, m_t, dt_num = spread_time(hit, -0.1, 0.1, 2000)
e_x, m_x, dx_400 = spread_freq(hit, -0.1, 0.1, 2000, -80.0, 80.0, 400)
dx_200 = spread_freq(hit, -0.1, 0.1, 2000, -80.0, 80.0, 200)[2]
dx_slope = spread_slope(hit, -0.1, 0.1, 2000)
tone = lambda t: hit(t) * complex(cos(2 * pi * 100 * t), sin(2 * pi * 100 * t))
_, m_tone, dx_tone = spread_freq(tone, -0.1, 0.1, 2000, 20.0, 180.0, 400)
real_hit = lambda t: hit(t) * cos(2 * pi * 100 * t)
_, m_real, dx_real = spread_freq(real_hit, -0.1, 0.1, 2000, -180.0, 180.0, 900)
# the proof's two lines, on the hit: ||f||^2 = -2 Re int t f f' dt, and Cauchy-Schwarz
d = 1e-7
slope = lambda t: (hit(t + d) - hit(t - d)) / (2 * d)
pairing = -2 * simpson(lambda t: t * hit(t) * slope(t), -0.1, 0.1, 2000)
cs = 2 * sqrt(simpson(lambda t: (t * hit(t)) ** 2, -0.1, 0.1, 2000)) * sqrt(simpson(lambda t: slope(t) ** 2, -0.1, 0.1, 2000))

show("closed form: floor 1/(4 pi dt), Hz", floor)
show("dt from |f|^2 sums, ms", 1000 * dt_num)
show("energy in time (closed form sqrt(2pi) dt)", e_t)
show("energy in frequency, transform by sums", e_x)
show("dxi, transform by sums, 400 steps, Hz", dx_400)
show("dxi, transform by sums, 200 steps, Hz", dx_200)
show("dxi from the slope, ||f'||/(2pi||f||), Hz", dx_slope)
show("product dt dxi", dt_num * dx_400)
show("  1/(4 pi)", 1 / (4 * pi))
show("proof: ||f||^2", e_t)
show("proof: -2 Re int t f f' dt", pairing)
show("proof: 2 ||t f|| ||f'||", cs)
show("100 Hz complex hit: mean frequency, Hz", m_tone)
show("100 Hz complex hit: dxi, Hz", dx_tone)
show("5 Hz needs dt at least, ms", 1000 / (4 * pi * 5))
show("5 Hz as a fraction of the floor", 5 / floor)
fw = 2 * sqrt(2 * log(2))
show("half-maximum width / standard deviation", fw)
show("half-maximum width in time, ms", 1000 * fw * DT)
show("half-maximum width in frequency, Hz", fw * floor)
show("half-maximum product, 2 ln2 / pi", fw * DT * fw * floor)
# other shapes, all scaled to dt = 10 ms: closed form against the transform by sums
L = DT / sqrt(1 / 12 - 5 / (8 * pi * pi))       # raised cosine cos^2(pi t / L), |t| < L/2
hann = lambda t: cos(pi * t / L) ** 2 if abs(t) < L / 2 else 0.0
dxh = spread_freq(hann, -L / 2, L / 2, 2000, -120.0, 120.0, 400)[2]
dxh2 = spread_freq(hann, -L / 2, L / 2, 2000, -240.0, 240.0, 800)[2]
dth = spread_time(hann, -L / 2, L / 2, 2000)[2]
show("raised cosine: length L, ms", 1000 * L)
show("raised cosine: dt by sums, ms", 1000 * dth)
show("raised cosine: dxi closed 1/(sqrt3 L), Hz", 1 / (sqrt(3) * L))
show("raised cosine: dxi by sums to 120 Hz", dxh)
show("raised cosine: dxi by sums to 240 Hz", dxh2)
show("raised cosine: product / floor", DT / (sqrt(3) * L) * 4 * pi)
tau = DT * sqrt(2)                              # two-sided decay e^(-|t|/tau), energy tau
dec = lambda t: exp(-abs(t) / tau)
a, X = 2 * pi * tau, 400.0                      # |f^|^2 = 4 tau^2 / (1 + a^2 xi^2)^2; tail beyond X in closed form
tail = 4 * tau * tau / a ** 3 * (pi / 2 - atan(a * X) + a * X / (1 + a * a * X * X))
m2 = moments(dec, -40 * tau, 40 * tau, 8000, -X, X, 800)[2]
dxd = sqrt((m2 + tail) / tau)
dtd = spread_time(dec, -40 * tau, 40 * tau, 8000)[2]
show("two-sided decay: tau = sqrt2 dt, ms", 1000 * tau)
show("two-sided decay: dt by sums, ms", 1000 * dtd)
show("two-sided decay: dxi closed 1/(2 pi tau), Hz", 1 / (2 * pi * tau))
show("two-sided decay: dxi by sums to 400 Hz", sqrt(m2 / tau))
show("  plus the closed-form tail beyond 400 Hz", dxd)
show("two-sided decay: product / floor", DT / (2 * pi * tau) * 4 * pi)
# the shutter: open 1 ms; its frequency spread has no finite value
T = 0.001
show("shutter: dt = T/sqrt12, ms", 1000 * T / sqrt(12))
for X in (1000.0, 10000.0, 100000.0):
    closed = sqrt((X - sin(2 * pi * T * X) / (2 * pi * T)) / (pi * pi * T))
    summed = sqrt(simpson(lambda x: sin(pi * T * x) ** 2 / (pi * pi), -X, X, int(X / 5)) / T)
    show(f"shutter: dxi cut at {X:>6.0f} Hz, closed", closed)
    show(f"shutter: dxi cut at {X:>6.0f} Hz, sums", summed)
    sinc2 = lambda x: T * T if x == 0 else (sin(pi * T * x) / (pi * x)) ** 2
    show(f"shutter: energy share beyond {X:>6.0f} Hz", 1 - simpson(sinc2, -X, X, int(X / 5)) / T)
show("mistake: rad/s floor 1/(2 dt) read as Hz", 1 / (2 * DT))
show("  over the true floor", 1 / (2 * DT) / floor)
show("mistake: half-max width 23.55 ms in sd bound", 1 / (4 * pi * fw * DT))
show("mistake: real 100 Hz hit, spread about 0", dx_real)
show("try: dt = 20 ms, floor Hz", 1 / (4 * pi * 0.020))
show("try: dt = 2 ms, floor Hz", 1 / (4 * pi * 0.002))
pts = list(range(-24, 25, 4))
out.append("chart, frequency (Hz)  " + " ".join(f"{x:>5d}" for x in pts))
out.append("chart, 10 ms hit       " + " ".join(f"{exp(-x * x / (2 * floor ** 2)):>5.3f}" for x in pts))
out.append("chart, 5 Hz wish       " + " ".join(f"{exp(-x * x / 50):>5.3f}" for x in pts))
print("\n".join(out))

assert abs(dx_400 - floor) < 1e-6 and abs(dx_200 - floor) < 1e-6      # transform by sums meets the closed form
assert abs(dx_slope - floor) < 1e-4                                     # derivative road meets it too
assert abs(dt_num - DT) < 1e-9 and abs(e_t - sqrt(2 * pi) * DT) < 1e-12
assert abs(e_x - e_t) < 1e-9                                            # Plancherel: same energy both sides
assert abs(pairing - e_t) < 1e-8 and cs >= pairing - 1e-12             # the proof's identity and Cauchy-Schwarz
assert abs(m_tone - 100) < 1e-6 and abs(dx_tone - floor) < 1e-6        # modulation slides, does not widen
assert abs(dxh2 - 1 / (sqrt(3) * L)) < 1e-4 and abs(dth - DT) < 1e-9          # raised cosine: band and length
assert abs(dxd - 1 / (2 * pi * tau)) < 1e-4 and abs(dtd - DT) < 1e-6          # two-sided decay: band and length
assert dth * dxh2 > 1 / (4 * pi) and dtd * dxd > 1 / (4 * pi)                # both sit above the floor
assert abs(dx_real - sqrt(100 ** 2 + floor ** 2)) < 1e-4
print("ALL CHECKS PASS")
