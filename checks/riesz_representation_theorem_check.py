# Riesz representation -- the check behind the card.  Standard library only.
# A one-second audio clip is a list of N pressure samples (Pa), dt = 1/N s
# apart, with overlap <y, x> = dt * sum(conj(y_k) * x_k).  A smoothing meter
# with half-life 0.25 s turns the clip into one reading.  The card's claim:
# that reading is the overlap with one fixed shape y, and |reading| <= |y| |x|.
import math

H = 0.25                                  # the meter's half-life, in seconds

def meter(x, n):                          # road 1: run the meter sample by sample
    a, m = 2.0 ** (-(1.0 / n) / H), 0.0
    for xk in x:
        m = a * m + (1 - a) * xk
    return m

def dot(y, x, n):                         # the overlap, real samples
    return sum(yk * xk for yk, xk in zip(y, x)) / n

def length(y, n):
    return math.sqrt(dot(y, y, n))

def probe(rule, n):                       # road 2: the rule on each lone sample
    return [rule([1.0 if j == k else 0.0 for j in range(n)], n) * n for k in range(n)]

def by_kernel(rule, n):                   # road 3: the proof's construction
    last = [1.0 if j == n - 1 else 0.0 for j in range(n)]
    r_last = rule(last, n)
    basis = []                            # silent clips, made perpendicular
    for k in range(n - 1):
        v = [1.0 if j == k else 0.0 for j in range(n)]
        c = rule(v, n) / r_last
        v = [vj - c * lj for vj, lj in zip(v, last)]
        for b in basis:
            p = dot(b, v, n)
            v = [vj - p * bj for vj, bj in zip(v, b)]
        s = length(v, n)
        basis.append([vj / s for vj in v])
    z = last[:]                           # drop the last sample onto the kernel
    for b in basis:
        p = dot(b, last, n)
        z = [zj - p * bj for zj, bj in zip(z, b)]
    return z, [rule(z, n) / dot(z, z, n) * zj for zj in z]

state = 20261115                          # SplitMix64, written out
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53 * 2 - 1

def f(v):
    return "[" + ", ".join(f"{t:.4f}" for t in v) + "]"

clip, n = [2.0, -1.0, 3.0, 1.0], 4
y_probe, (z, y_kernel) = probe(meter, n), by_kernel(meter, n)
reading = meter(clip, n)
norm = length(y_probe, n)
best = max(abs(meter(x, n)) / length(x, n) for x in ([rand() for _ in range(n)] for _ in range(2000)))
print(f"clip {f(clip)} Pa, N = {n}, dt = {1 / n:.4f} s")
trail = [meter(clip[:k + 1], n) for k in range(n)]
print(f"road 1, meter run: {f(trail)}, reading = {reading:.4f} Pa")
print(f"lone-sample readings: {f([t / n for t in y_probe])}")
print(f"road 2, probe each sample: y = {f(y_probe)}")
print(f"road 3, miss z = {f(z)}, meter(z) = {meter(z, n):.4f}, |z|^2 = {dot(z, z, n):.4f}")
print(f"road 3, drop onto the silent clips: y = {f(y_kernel)}")
print(f"overlap <y, clip> = {dot(y_probe, clip, n):.4f} Pa")
print(f"meter size |y| = sqrt(85/64) = {norm:.6f}; best of 2000 random clips {best:.6f}; at x = y {meter(y_probe, n) / norm:.6f}")
plain = sum(a * b for a, b in zip(y_probe, clip))
print(f"mistake, plain sum without dt: {plain:.4f} Pa, not {reading:.4f}")
# Let N grow: the shape tends to (ln2/H) 2^(-(1-t)/H), length below.
limit = math.sqrt(math.log(2) / (2 * H) * (1 - 2.0 ** (-2 / H)))
print(f"closed-form length of the limit shape: {limit:.6f}")
errs = []
for n in (4, 16, 64, 256, 1024, 4096):
    yn = probe(meter, n) if n <= 256 else [(1 - 2.0 ** (-1 / (n * H))) * 2.0 ** (-(n - 1 - k) / (n * H)) * n for k in range(n)]
    errs.append(abs(length(yn, n) - limit))
    print(f"N = {n:4d}: |y| = {length(yn, n):.6f}, error {errs[-1]:.9f}")
y8 = probe(meter, 8)
print("chart, N = 8 shape: " + ", ".join(f"{t:.3f}" for t in y8))
print("chart, limit shape at each cell's middle: " + ", ".join(f"{math.log(2) / H * 2.0 ** (-(1 - (k + 0.5) / 8) / H):.3f}" for k in range(8)))
point = []                                # pressure at the last instant alone
for n in (4, 16, 64, 256, 1024):
    point.append(length(probe(lambda x, m: x[-1], n), n))
print("mistake, reading one instant: |y| at N = 4, 16, 64, 256, 1024: " + ", ".join(f"{t:.1f}" for t in point))
# Finite mixtures of tones sqrt(2) sin(2 pi n t), reading sum b_n / n.
saw = math.sqrt(2) * math.pi * (0.5 - 0.25)
for n in (10, 100, 1000):
    tone_len = math.sqrt(sum(1 / k ** 2 for k in range(1, n + 1)))
    s = sum(math.sqrt(2) * math.sin(2 * math.pi * k * 0.25) / k for k in range(1, n + 1))
    print(f"tones up to {n:4d}: |y| = {tone_len:.6f}, y(0.25 s) = {s:.6f}")
print(f"limit: |y| = pi/sqrt(6) = {math.pi / math.sqrt(6):.6f}, sawtooth y(0.25 s) = {saw:.6f}, no finite mixture")
# Complex scalars: the 1 Hz Fourier coefficient c1(x) = <f1, x>, f1 = e^(2 pi i t).
f1 = [complex(math.cos(2 * math.pi * k / 4), math.sin(2 * math.pi * k / 4)) for k in range(4)]
def cdot(y, x):
    return sum(yk.conjugate() * xk for yk, xk in zip(y, x)) / 4
c1 = cdot(f1, clip)
right = cdot([-1j * e for e in f1], clip)
wrong = cdot([1j * e for e in f1], clip)
def cf(z):
    return f"{z.real:.4f} {'+' if z.imag >= 0 else '-'} {abs(z.imag):.4f}i"
print(f"c1(clip) = {cf(c1)}; the rule i*c1 gives {cf(1j * c1)}")
print(f"shape -i*f1 gives {cf(right)}; mistake, shape i*f1 gives {cf(wrong)}")
assert all(abs(p - q) < 1e-12 for p, q in zip(y_probe, y_kernel))      # roads 2 and 3
assert abs(dot(y_probe, clip, 4) - reading) < 1e-12                    # road 1 = overlap
assert best <= norm + 1e-12 and abs(norm - math.sqrt(85 / 64)) < 1e-12  # Cauchy-Schwarz
assert all(errs[i + 1] < errs[i] / 3 for i in range(len(errs) - 1))     # truncation closes
assert 1 / 1001 < math.pi ** 2 / 6 - tone_len ** 2 < 1 / 1000       # tail of 1/n^2: 1/(N+1) to 1/N
assert abs(s - saw) < math.sqrt(2) / 1001                              # alternating tail < first term
assert abs(point[-1] - 32) < 1e-9 and abs(right - 1j * c1) < 1e-12 and abs(wrong - 1j * c1) > 0.5
print("ALL CHECKS PASS")
