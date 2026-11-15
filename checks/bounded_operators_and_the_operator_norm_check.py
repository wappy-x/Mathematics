# Bounded operators -- the check behind the card.  Standard library only.
# An audio blur: the RC smoother y[n] = (1 - a) x[n] + a y[n-1], starting from silence.
# At 8 kHz, a = 1/2: tau = 1/(8000 ln 2) s.  Sizes are peak sizes (sup norms), full scale 1.
# Code holds a truncation: clips of N samples.  Roads: closed form, max row sum of the
# matrix built from impulses, brute force over every sign pattern, and random clips.
import math

def blur(x, a):                        # the smoother, sample by sample
    y, prev = [], 0.0
    for v in x:
        prev = (1 - a) * v + a * prev
        y.append(prev)
    return y

def unblur(y, a):                      # undoes it exactly: x[n] = (y[n] - a y[n-1]) / (1 - a)
    return [(y[n] - a * (y[n - 1] if n else 0.0)) / (1 - a) for n in range(len(y))]

def matrix(op, n, a):                  # column j = the response to a click at sample j
    cols = [op([1.0 if i == j else 0.0 for i in range(n)], a) for j in range(n)]
    return [[cols[j][i] for j in range(n)] for i in range(n)]

def inverse_lower(m):                  # invert a lower-triangular matrix by forward substitution
    n = len(m)
    inv = [[0.0] * n for _ in range(n)]
    for j in range(n):
        for i in range(n):
            inv[i][j] = ((i == j) - sum(m[i][k] * inv[k][j] for k in range(i))) / m[i][i]
    return inv

def row_sum_norm(m):                   # peak-to-peak gain of a matrix: largest row of |entries|
    return max(sum(abs(v) for v in row) for row in m)

def brute(op, n, a):                   # worst sign pattern: a peak gain is reached at a corner
    best = 0.0
    for mask in range(2 ** n):
        x = [1.0 if mask >> i & 1 else -1.0 for i in range(n)]
        best = max(best, max(abs(v) for v in op(x, a)))
    return best

def peak(x):
    return max(abs(v) for v in x)

def show(x, d):
    return "(" + ", ".join(f"{v:.{d}f}" for v in x) + ")"

print("blur, a = 1/2: N, closed 1 - 2^-N, max row sum, brute force")
for n in [1, 2, 4, 8, 16, 32]:
    closed, rows = 1 - 2.0 ** -n, row_sum_norm(matrix(blur, n, 0.5))
    b = brute(blur, n, 0.5) if n <= 10 else rows
    assert abs(rows - closed) < 1e-12 and abs(b - closed) < 1e-12
    print(f"  {n:2d}  {closed:.10f}  {rows:.10f}  {b:.10f}")
x = [0.8, -0.5, 0.3, 0.6]
y = blur(x, 0.5)
print("clip", show(x, 1), "-> blurred", show(y, 4), f"peak {peak(y):.4f} <= 0.9375 x 0.8 = {0.9375 * 0.8:.4f}")
assert peak(y) <= 0.9375 * peak(x) + 1e-12
w = blur([0.8] * 4, 0.5)
print("worst clip 0.8 held ->", show(w, 4), f"peak {peak(w):.4f}")
assert abs(peak(w) - 0.75) < 1e-12

print("unblur, a = 1/2: N, closed (1+a)/(1-a), max row sum, brute force, max |entry|")
for n in [2, 4, 8]:
    m = matrix(unblur, n, 0.5)
    rows, b, ent = row_sum_norm(m), brute(unblur, n, 0.5), max(abs(v) for r in m for v in r)
    assert abs(rows - 3) < 1e-12 and abs(b - 3) < 1e-12
    print(f"  {n}  3.0000000000  {rows:.10f}  {b:.10f}  {ent:.1f}")
back = blur(unblur([0.3, -0.2, 0.5, 0.1], 0.5), 0.5)
assert max(abs(p - q) for p, q in zip(back, [0.3, -0.2, 0.5, 0.1])) < 1e-12
z = unblur([0.4, -0.4, 0.4, -0.4], 0.5)
print("blurred clip +-0.4 -> unblurred", show(z, 1), f"peak {peak(z):.1f}; headroom 20 log10 3 = {20 * math.log10(3):.2f} dB")
assert abs(peak(z) - 1.2) < 1e-12

print("same smoother, finer sampling: rate (Hz), a, blur gain on 1 s, unblur gain, N=64 inverse rows, 2 tau/h")
tau = 1 / (8000 * math.log(2))
pts = []
for fs in [8000, 16000, 48000, 96000, 192000]:
    a = math.exp(-1 / (fs * tau))
    g, rows = (1 + a) / (1 - a), row_sum_norm(inverse_lower(matrix(blur, 64, a)))
    assert abs(rows - g) < 1e-9 * g and 2 * tau * fs < g < 2 * tau * fs + 1
    pts.append((math.log10(fs), math.log10(g), math.log10(1 - a ** fs)))
    print(f"  {fs:6d}  {a:.6f}  {1 - a ** fs:.6f}  {g:.6f}  {rows:.6f}  {2 * tau * fs:.6f}")
print("chart log10 rate:", ", ".join(f"{p[0]:.3f}" for p in pts))
print("chart log10 unblur gain:", ", ".join(f"{p[1]:.3f}" for p in pts), "; log10 blur gain:", ", ".join(f"{abs(p[2]):.3f}" for p in pts))
print(f"tau = {tau * 1e6:.2f} us, analog corner 1/(2 pi tau) = {1 / (2 * math.pi * tau):.1f} Hz")

# continuous blur K: kernel k(t, s) = exp(-(t - s)/tau)/tau for s <= t; on C[0, T], ||K|| = int_0^T k(T, s) ds
T, M = 0.001, 100000
mid = sum(math.exp(-(T - (i + 0.5) * T / M) / tau) / tau for i in range(M)) * T / M
ns = T * 8000                                    # the same clip as samples at 8 kHz
print(f"K on a {T * 1000:.1f} ms clip: closed 1 - exp(-T/tau) = {1 - math.exp(-T / tau):.8f}, midpoint {mid:.8f}, sampled 1 - 2^-{ns:.0f} = {1 - 2 ** -ns:.8f}")
assert abs(mid - (1 - math.exp(-T / tau))) < 1e-8 and abs(mid - (1 - 2 ** -ns)) < 1e-8

# continuous unblur g + tau g': a tone of peak 0.001/n at n kHz
for n in [1, 4, 16]:
    out = 0.001 / n * math.sqrt(1 + (2 * math.pi * 1000 * n * tau) ** 2)
    print(f"tone 0.001/{n} at {n} kHz -> unblurred peak {out:.6f}")
    assert out > 0.001 * 2 * math.pi * 1000 * tau * 0.999
print(f"limit as n grows: 0.001 x 2 pi x 1000 x tau = {0.001 * 2 * math.pi * 1000 * tau:.6f}")

# completeness: FIR truncations R_m keep the first m taps 2^-(k+1)
print("m, ||R - R_m|| closed 2^-m, tail rows on a 60-sample clip, in dB")
for m in [1, 2, 5, 10, 20]:
    tail = row_sum_norm([[0.5 ** (i - j + 1) if i - j >= m else 0.0 for j in range(60)] for i in range(60)])
    assert abs(tail - (2.0 ** -m - 2.0 ** -60)) < 1e-15
    print(f"  {m:2d}  {2.0 ** -m:.9f}  {tail:.9f}  {20 * math.log10(2.0 ** -m):.1f}")
print(f"||R_5 - R_10|| = 2^-5 - 2^-10 = {2 ** -5 - 2 ** -10:.9f}")
click = [1.0] + [0.0] * 59
R10 = [[0.5 ** (i - j + 1) if 0 <= i - j < 10 else 0.0 for j in range(60)] for i in range(60)]  # the 10-tap FIR
r10 = [sum(R10[i][j] * click[j] for j in range(60)) for i in range(60)]
last = max(i for i, v in enumerate(r10) if v) + 1
assert last == 10 and max(abs(p - q) for p, q in zip(r10[:10], blur(click, 0.5))) < 1e-15 and all(blur(click, 0.5))
print(f"click through R_10: silent after sample {last}; through R: sample 60 is still {blur(click, 0.5)[59]:.3e}, never silent")

# drop linearity: squaring each sample is continuous but has no finite gain
for c in [1.0, 10.0, 100.0]:
    print(f"squarer on a clip of peak {c:.1f}: gain {c * c / c:.1f}")

# random clips never beat the gain (SplitMix64, seed 2026)
s, worst = 2026, [0.0, 0.0]
def rnd():
    global s
    s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53 * 2 - 1
for _ in range(2000):
    x = [rnd() for _ in range(16)]
    worst[0] = max(worst[0], peak(blur(x, 0.5)) / peak(x))
    worst[1] = max(worst[1], peak(unblur(x, 0.5)) / peak(x))
assert worst[0] <= 1 - 2 ** -16 + 1e-12 and worst[1] <= 3 + 1e-12 and worst[1] > 2.5
print(f"2000 random 16-sample clips: worst blur ratio {worst[0]:.6f} <= {1 - 2 ** -16:.6f}, worst unblur ratio {worst[1]:.6f} <= 3")
print("ALL CHECKS PASS")
