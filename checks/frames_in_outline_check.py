# Frames in outline: a Gabor frame with half-overlapping windows on a ten-second bird call.
# Standard library only.  Roads: frame bounds from the window-energy sum M*G(k), against the
# frame operator built atom by atom as a matrix, against the energy of FFT coefficients.
from math import sin, cos, pi, sqrt
FS, SEC, L, M = 6400, 10, 256, 256        # samples per second, seconds, window, channels
N = FS * SEC                              # 64,000 samples
def fft(x):                               # radix-2, recursive: X[m] = sum x[k] e^(-2 pi i m k/n)
    n = len(x)
    if n == 1: return list(x)
    e, o = fft(x[0::2]), fft(x[1::2])
    out = [0j] * n
    for k in range(n // 2):
        w = complex(cos(2 * pi * k / n), -sin(2 * pi * k / n)) * o[k]
        out[k], out[k + n // 2] = e[k] + w, e[k] - w
    return out
def ifft_sum(c): return [z.conjugate() for z in fft([z.conjugate() for z in c])]  # sum c e^(+...)
def window(kind, n):                      # unit-energy windows sampled at k + 1/2
    if kind == "rect": return [1 / sqrt(n)] * n
    if kind == "sine": return [sqrt(2 / n) * sin(pi * (k + 0.5) / n) for k in range(n)]
    return [sqrt(8 / (3 * n)) * sin(pi * (k + 0.5) / n) ** 2 for k in range(n)]   # Hann
def G(g, a): return [sum(g[k + j * a] ** 2 for j in range(len(g) // a)) for k in range(a)]
def bounds(g, a, m): s = [m * v for v in G(g, a)]; return min(s), max(s)
def analyse(f, g, a, m=None):             # c[n][m] = <f, g_(m,n)>, phase measured from n*a
    n_ = len(f); return [fft([f[(n * a + k) % n_] * g[k] for k in range(len(g))])[:m]
                         for n in range(n_ // a)]
def synth(c, gam, a, n_):                 # sum over m, n of c[n][m] * gam_(m,n)
    out = [0j] * n_
    for n, row in enumerate(c):
        s = ifft_sum(row)
        for k in range(len(gam)): out[(n * a + k) % n_] += gam[k] * s[k]
    return out
def energy(v): return sum(abs(z) ** 2 for z in v)
def cenergy(c): return sum(energy(r) for r in c)
def close(x, y, tol): return abs(x - y) <= tol
def yn(b): return "yes" if b else "no"
print("Mercedes frame: three unit vectors at 90, 210, 330 degrees in the plane")
V = [(cos(d * pi / 180), sin(d * pi / 180)) for d in (90, 210, 330)]
def frame_op(vs): return [[sum(v[i] * v[j] for v in vs) for j in range(2)] for i in range(2)]
def eig2(S):
    t, d = S[0][0] + S[1][1], S[0][0] * S[1][1] - S[0][1] * S[1][0]
    r = sqrt(t * t / 4 - d); return t / 2 - r, t / 2 + r
for name, vs in (("three vectors", V), ("first two only", V[:2])):
    A_, B_ = eig2(frame_op(vs)); print(f"  {name}: A = {A_:.6f}, B = {B_:.6f}")
for f2 in ((1.0, 0.0), (0.0, 1.0), (0.6, 0.8)):
    s = sum((f2[0] * v[0] + f2[1] * v[1]) ** 2 for v in V)
    print(f"  f = {f2}: sum of squared coefficients {s:.6f}")
    assert close(s, 1.5, 1e-12)
z = [sum(v[i] for v in V) for i in range(2)]
print(f"  coefficients (1, 1, 1) build ({abs(z[0]):.6f}, {abs(z[1]):.6f}): not unique")
assert close(eig2(frame_op(V[:2]))[0], 0.5, 1e-12)
print("\nsmall instance N = 16, L = 8, hop 4, M = 8: frame operator built atom by atom")
n0, l0, a0 = 16, 8, 4
for kind in ("sine", "hann"):
    g = window(kind, l0); S = [[0j] * n0 for _ in range(n0)]
    for n in range(n0 // a0):
        for m in range(l0):
            at = [0j] * n0
            for k in range(l0):
                th = 2 * pi * m * k / l0; at[(n * a0 + k) % n0] = g[k] * complex(cos(th), sin(th))
            for i in range(n0):
                for j in range(n0): S[i][j] += at[i] * at[j].conjugate()
    off = max(abs(S[i][j]) for i in range(n0) for j in range(n0) if i != j)
    d = [S[i][i].real for i in range(n0)]; A_, B_ = bounds(g, a0, l0)
    print(f"  {kind}: off-diagonal below 1e-12 {yn(off < 1e-12)}; diagonal {min(d):.6f} to {max(d):.6f};"
          f" M*G {A_:.6f} to {B_:.6f}")
    assert off < 1e-12 and close(min(d), A_, 1e-12) and close(max(d), B_, 1e-12)
print(f"\nbird call: {SEC} s at {FS} Hz, N = {N}, {N // 128} slices; window {L} samples = {1000 * L / FS:.0f} ms,"
      f" {M} channels {FS / M:.0f} Hz apart")
f = [0.5 * sin(2 * pi * (1000 * t / FS + 75 * (t / FS) ** 2)) for t in range(N)]
Ef = energy(f); print(f"pitch 1000 Hz at 0 s rising to {1000 + 150 * SEC} Hz at {SEC} s; energy {Ef:.4f}")
res = {}
for kind, a in (("rect", 256), ("sine", 128), ("hann", 128), ("hann", 64), ("sine", 256)):
    g = window(kind, L); A_, B_ = bounds(g, a, M); res[kind, a] = (A_, B_)
    print(f"  {kind:4} hop {a} ({1000 * a / FS:.0f} ms): a*b = {a / M:.2f}, atoms {N // a * M} = {N // a * M / N:.0f} N,"
          f" A = {A_:.6f}, B = {B_:.6f}, B/A = {B_ / A_:.2f}")
mg = {kind: [M * v for v in G(window(kind, L), a)] for kind, a in (("sine", 128), ("hann", 128))}
mg["sine256"] = [M * v for v in G(window("sine", L), 256)]
print("figure, M*G at 0,5,...,40 ms: hann", " ".join(f"{mg['hann'][k % 128]:.3f}" for k in range(0, 257, 32)))
print("figure, sine half", " ".join(f"{mg['sine'][k % 128]:.3f}" for k in range(0, 257, 32)),
      "| sine no overlap", " ".join(f"{mg['sine256'][k % 256]:.3f}" for k in range(0, 257, 32)))
print(f"hann by hand: H^2 = 8/(3L) = {8 / (3 * L):.6f}, M H^2 = {M * 8 / (3 * L):.6f};"
      f" sin^4 + cos^4 from {min(mg['hann']) / (M * 8 / (3 * L)):.6f} to {max(mg['hann']) / (M * 8 / (3 * L)):.6f};"
      f" 4/3 = {4 / 3:.6f}, 8/3 = {8 / 3:.6f}; mean of M*G {sum(mg['hann']) / 128:.6f}")
assert close(res["rect", 256][0], 1, 1e-12) and close(res["sine", 128][1], 2, 1e-12)
assert close(res["hann", 128][0], 4 / 3, 5e-4) and close(res["hann", 128][1], 8 / 3, 5e-4)
for kind in ("sine", "hann"):            # road 3: FFT energy against the weighted-energy formula
    g = window(kind, L); c = analyse(f, g, 128)
    Ec = cenergy(c); Gk = G(g, 128); Ew = M * sum(f[t] ** 2 * Gk[t % 128] for t in range(N))
    print(f"  {kind}: sum |c|^2 = {Ec:.4f}; M * sum f^2 G = {Ew:.4f}; ratio to energy {Ec / Ef:.6f}")
    assert close(Ec, Ew, 1e-6 * Ew) and res[kind, 128][0] - 1e-9 <= Ec / Ef <= res[kind, 128][1] + 1e-9
    if kind == "hann": ch = c
gh = window("hann", L); Gh = G(gh, 128)
dual = [gh[k] / (M * Gh[k % 128]) for k in range(L)]
err = sqrt(energy([x - y for x, y in zip(synth(ch, dual, 128, N), f)]) / Ef)
wrong = sqrt(energy([x - y for x, y in zip(synth(ch, [v / 2 for v in gh], 128, N), f)]) / Ef)
print(f"hann rebuild with dual window: relative error below 1e-12 {yn(err < 1e-12)}; with g/2: {wrong:.6f}")
assert err < 1e-12 and wrong > 0.1
spike = [0.0] * 1024; spike[64] = 1.0
r = cenergy(analyse(spike, gh, 128)); print(f"spike at sample 64: sum |c|^2 = {r:.6f} = M*G(64)")
assert close(r, M * Gh[64], 1e-9)
print("critical sine window, hop = L: A = 2 sin^2(pi/(2L))")
for ln in (64, 256, 1024):
    A_ = bounds(window("sine", ln), ln, ln)[0]
    print(f"  L = {ln:4}: A = {A_:.9f}, formula {2 * sin(pi / (2 * ln)) ** 2:.9f}, 1/sqrt(A) = {A_ ** -0.5:.1f}")
    assert close(A_, 2 * sin(pi / (2 * ln)) ** 2, 1e-15)
tone = [sin(2 * pi * 49 * t / 256) for t in range(N)]
Et = cenergy(analyse(tone, window("rect", L), 256, None))
half = [row[0::2] for row in analyse(tone, window("rect", L), 256)]
print(f"half the channels (even only), rect hop 256: atoms {N // 256 * 128}; {49 * FS / 256:.2f} Hz tone,"
      f" energy {energy(tone):.1f}, all channels {Et:.1f}, even channels below 1e-12 {yn(cenergy(half) < 1e-12)}")
assert cenergy(half) < 1e-12 * Et and close(Et, energy(tone), 1e-6 * Et)
state = 2026
def rnd():                                # SplitMix64, uniform on [-1, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 52 - 1
h = 0.001 * sqrt(3)                       # noise of standard deviation 0.001 per real number
out = {}
for kind, a, scale in (("rect", 256, 1.0), ("sine", 128, 0.5)):
    g = window(kind, L); c = analyse(f, g, a)
    c = [[z + complex(h * rnd(), h * rnd()) for z in row] for row in c]
    out[kind] = energy([x - y for x, y in zip(synth(c, [scale * v for v in g], a, N), f)])
    print(f"  noise on every {kind} coefficient: rebuild error energy {out[kind]:.6f}")
q = out["sine"] / out["rect"]; ex = N * 2 * 0.001 ** 2
print(f"frame / basis error energy {q:.4f}; expected {ex:.3f} and {ex / 2:.3f}, ratio 0.5")
assert close(out["rect"], ex, 0.0013) and close(q, 0.5, 0.008)   # about 4 standard errors each
print("ALL CHECKS PASS")
