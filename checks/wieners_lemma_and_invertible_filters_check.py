# Wiener's lemma: invert a three-tap audio filter and check that the inverse's
# taps are absolutely summable. Standard library only. Three roads to the
# inverse: a closed form from the filter's zeros, Gaussian elimination on the
# looped-clip (circulant) matrix, and the convolution h * g = delta as a check.
import math

FS = 48000.0                         # samples per second (illustrative)
H = (0.2, 0.6, 0.2)                  # taps at samples -1, 0, +1: the treble cut
BLUR = (0.25, 0.5, 0.25)             # a stronger blur that silences 24 kHz

def gain(h, f):                      # response at f Hz; real, as the taps are symmetric
    return h[1] + 2 * h[0] * math.cos(2 * math.pi * f / FS)

def zero_inside(h):                  # root r of b z^2 + a z + b with |r| < 1
    a, b = h[1], h[0]
    return (-a + math.sqrt(a * a - 4 * b * b)) / (2 * b)

def inverse_tap(h, n):               # closed form g_n = C r^|n|, C = 1 / (b (r - 1/r))
    r = zero_inside(h)
    return r ** abs(n) / (h[0] * (r - 1 / r))

def convolve(h, g):                  # g as {n: g_n}; returns h * g as {n: value}
    out = {}
    for n, c in g.items():
        for k in (-1, 0, 1):
            out[n + k] = out.get(n + k, 0.0) + h[k + 1] * c
    return out

def circulant_inverse(h, N):         # solve A x = e_0 for the looped clip of N samples
    A = [[0.0] * N + [1.0 if i == 0 else 0.0] for i in range(N)]
    for i in range(N):
        for k in (-1, 0, 1):
            A[i][(i - k) % N] += h[k + 1]
    for c in range(N):               # Gaussian elimination, partial pivoting
        p = max(range(c, N), key=lambda i: abs(A[i][c]))
        if abs(A[p][c]) < 1e-9:
            return None              # a zero pivot: the matrix is singular
        A[c], A[p] = A[p], A[c]
        for i in range(c + 1, N):
            m = A[i][c] / A[c][c]
            for j in range(c, N + 1):
                A[i][j] -= m * A[c][j]
    x = [0.0] * N
    for i in range(N - 1, -1, -1):
        x[i] = (A[i][N] - sum(A[i][j] * x[j] for j in range(i + 1, N))) / A[i][i]
    return x

r = zero_inside(H)
print("1. the treble cut, taps 0.2 0.6 0.2 at 48 kHz")
for f in (0, 1000, 10000, 24000):
    print(f"   {f:5d} Hz: gain {gain(H, f):.6f}  inverse gain {1 / gain(H, f):.6f}")
print(f"   zeros of 0.2 z^2 + 0.6 z + 0.2: {r:.6f} inside, {1 / r:.6f} outside the circle")
assert abs(r - (-3 + math.sqrt(5)) / 2) < 1e-12 and abs(H[0] / r ** 2 + H[1] / r + H[2]) < 1e-12

print("2. closed-form inverse g_n = C r^|n|")
g = {n: inverse_tap(H, n) for n in range(-60, 61)}
print("   g_0..g_6 " + " ".join(f"{g[n]:.6f}" for n in range(7)))
s, s1 = sum(g.values()), sum(abs(c) for c in g.values())
print(f"   C = {g[0]:.6f} (sqrt 5 = {math.sqrt(5):.6f}); sum g {s:.6f}; sum |g| {s1:.6f}")
assert abs(g[0] - math.sqrt(5)) < 1e-12
print(f"   by hand: 0.6 g_0 {H[1] * g[0]:.6f}, 0.4 g_1 {2 * H[0] * g[1]:.6f}; 0.2 g_0, 0.6 g_1, 0.2 g_2: "
      f"{H[0] * g[0]:.6f} {H[1] * g[1]:.6f} {H[2] * g[2]:.6f}")
q = (1 + abs(r)) / (1 - abs(r))
print(f"   (1+|r|)/(1-|r|) {q:.6f}; C (1+|r|)/(1-|r|) {g[0] * q:.6f}; boost at 24 kHz {20 * math.log10(1 / gain(H, 24000)):.2f} dB")
assert abs(g[0] * q - s1) < 1e-9
assert abs(s - 1 / gain(H, 0)) < 1e-9 and abs(s1 - 1 / gain(H, FS / 2)) < 1e-9
hg = convolve(H, g)
res = max(abs(hg[n] - (1.0 if n == 0 else 0.0)) for n in range(-59, 60))
print(f"   (h * g)[0], [1], [2]: {abs(hg[0]):.6f} {abs(hg[1]):.6f} {abs(hg[2]):.6f}; largest residual {res:.1e}")
assert res < 1e-12

print("3. looped clip of N samples: circulant matrix, inverted by elimination")
print("   N   g_0       |g_0 - C|  2C|r|^N/|1-r^N|  worst gain: treble cut  blur     (N^2+1)/2")
chart = []
for N in (9, 17, 33, 65):
    x, xb = circulant_inverse(H, N), circulant_inverse(BLUR, N)
    period = g[0] * sum(r ** abs(m * N) for m in range(-6, 7))     # the clip wraps: g_0 + g_N + g_-N + ...
    w, wb = sum(abs(v) for v in x), sum(abs(v) for v in xb)
    print(f"   {N:<3d} {x[0]:.6f}  {abs(x[0] - g[0]):.2e}   {abs(2 * g[0] * r ** N / (1 - r ** N)):.2e}         "
          f"{w:.6f}  {wb:8.2f}  {(N * N + 1) / 2:8.2f}")
    assert abs(x[0] - period) < 1e-12                              # elimination = wrapped closed form
    lo = min(gain(BLUR, FS * k / N) for k in range(N))             # sup |g-hat| <= sum |g|
    assert w <= 5 + 1e-9 and wb >= 1 / lo - 1e-6 and abs(wb - (N * N + 1) / 2) < 1e-6 * N * N
    chart.append((N, w, wb))
print(f"   blur, N = 8: {'singular (zero pivot)' if circulant_inverse(BLUR, 8) is None else 'invertible'}")
assert circulant_inverse(BLUR, 8) is None

print("4. keep taps -K..K: l1 residual of h * g_K - delta, and the closed form 2bC(1+|r|)|r|^K")
for K in (2, 4, 6, 8, 10):
    gk = {n: g[n] for n in range(-K, K + 1)}
    e = convolve(H, gk)
    l1 = sum(abs(v - (1.0 if n == 0 else 0.0)) for n, v in e.items())
    worst = max(abs(1 - gain(H, f) * sum(c * math.cos(2 * math.pi * f * n / FS) for n, c in gk.items()))
                for f in range(0, 24001, 100))
    cf = 2 * H[0] * g[0] * (1 + abs(r)) * abs(r) ** K
    print(f"   K = {K:2d}, {2 * K + 1:2d} taps: residual {l1:.6f}  closed form {cf:.6f}  worst gain error {worst:.6f}")
    assert abs(l1 - cf) < 1e-12 and worst <= l1 + 1e-12
print(f"   2bC(1+|r|) {2 * H[0] * g[0] * (1 + abs(r)):.6f}; |r|^8 {abs(r) ** 8:.6f}; 5 taps leave {20 * math.log10(2 * H[0] * g[0] * (1 + abs(r)) * abs(r) ** 2):.2f} dB")
K60 = next(K for K in range(1, 99) if 2 * H[0] * g[0] * (1 + abs(r)) * abs(r) ** K <= 1e-3)
print(f"   -60 dB (residual <= 0.001) first at K = {K60}: {2 * K60 + 1} taps")

print("5. undoing the filter one sample at a time, from the left (a causal recursion)")
e = [0.0, 1e-6]                      # a rounding error of one millionth at sample 0
for n in range(40):
    e.append(-(H[1] * e[-1] + H[0] * e[-2]) / H[2])
print(f"   error after 5, 10, 20 samples: {abs(e[6]):.3e} {abs(e[11]):.3e} {abs(e[21]):.3e}; growth per sample {abs(e[41] / e[40]):.6f}")
assert abs(abs(e[41] / e[40]) - 1 / abs(r)) < 1e-9

print("6. try changing")
K96 = next(K for K in range(1, 99) if 2 * H[0] * g[0] * (1 + abs(r)) * abs(r) ** K <= 10 ** (-96 / 20))
print(f"   16-bit audio, -96 dB: K = {K96}, {2 * K96 + 1} taps")
for h in ((0.1, 0.8, 0.1), (0.3, 0.4, 0.3)):
    if h[1] > 2 * h[0]:
        rr = zero_inside(h); K = next(K for K in range(1, 99) if 2 * h[0] * inverse_tap(h, 0) * (1 + abs(rr)) * abs(rr) ** K <= 1e-3)
        print(f"   taps {h}: r {rr:.6f}, sum |g| {1 / (h[1] - 2 * h[0]):.6f}, -60 dB at {2 * K + 1} taps")
    else:
        print(f"   taps {h}: gain 0 at {FS * math.acos(-h[1] / (2 * h[0])) / (2 * math.pi):.0f} Hz: no inverse in l1")
print("chart, kHz 0..24 step 2: gain " + " ".join(f"{gain(H, 1000 * k):.4f}" for k in range(0, 25, 2)))
print("chart, kHz 0..24 step 2: inverse gain " + " ".join(f"{1 / gain(H, 1000 * k):.4f}" for k in range(0, 25, 2)))
print("chart, log10 worst-case gain at N = 9 17 33 65: treble cut " + " ".join(f"{math.log10(w):.4f}" for _, w, _ in chart)
      + "; blur " + " ".join(f"{math.log10(wb):.4f}" for _, _, wb in chart))
print(f"figure, z-plane: centre (300, 130), 80 px per unit, unit circle r 80; zeros at x = {300 + 80 * r:.2f} and {300 + 80 / r:.2f}")
print("ALL CHECKS PASS")
