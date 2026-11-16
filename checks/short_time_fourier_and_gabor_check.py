# Short-time Fourier transform and the Gabor transform -- the check behind the card.
# Standard library only.  An illustrative bird call, drawn from a formula: pitch
# 2000 + 200 t Hz for 10 s, sampled 16000 times a second.  Gaussian windows.
# The FFT, every sum and the Poisson series are written out; nothing imported knows the answer.
from math import cos, sin, pi, sqrt, exp, ceil

FS, F0, C = 16000, 2000.0, 200.0                 # samples per second, start pitch Hz, climb Hz/s
N = 10 * FS                                      # ten seconds
X = [cos(2 * pi * (F0 * n / FS + 0.5 * C * (n / FS) ** 2)) for n in range(N)]

def tot(vs):                                     # plain running sum, the same in both languages
    s = 0.0
    for v in vs:
        s += v
    return s

def fft(a, sign=-1):                             # radix-2 FFT; sign=+1 runs it backwards (no 1/M)
    a = list(a); n = len(a); j = 0
    for i in range(1, n):
        b = n >> 1
        while j & b:
            j ^= b; b >>= 1
        j |= b
        if i < j:
            a[i], a[j] = a[j], a[i]
    size = 2
    while size <= n:
        h = size // 2
        tw = [complex(cos(2 * pi * k / size), sign * sin(2 * pi * k / size)) for k in range(h)]
        for s in range(0, n, size):
            for k in range(h):
                u, v = a[s + k], a[s + k + h] * tw[k]
                a[s + k], a[s + k + h] = u + v, u - v
        size *= 2
    return a

def window(sig, cut=6.0):                        # Gaussian: |w|^2 has standard deviation sig s
    h = ceil(cut * sig * FS)                     # cut where w = e^-9 = 0.00012
    return h, [exp(-(k / FS) ** 2 / (4 * sig * sig)) for k in range(-h, h + 1)]

def column(n0, w, h, M):                         # one column: samples around n0, windowed, FFT
    buf = [0j] * M
    for k in range(-h, h + 1):
        buf[k % M] = X[(n0 + k) % N] * w[k + h]
    return fft(buf)

def ridge(sig, M=16384, t0=5.0):                 # road 1: centre and spread of one column's power
    h, w = window(sig)
    P = [v.real ** 2 + v.imag ** 2 for v in column(round(t0 * FS), w, h, M)[:M // 2]]
    f = [k * FS / M for k in range(M // 2)]
    pw = tot(P); mu = tot(p * x for p, x in zip(P, f)) / pw
    return mu, sqrt(tot(p * (x - mu) ** 2 for p, x in zip(P, f)) / pw)

def spreads(sig, w, h):                          # road 2: the window's two spreads, in time only
    e = tot(v * v for v in w)
    dt = sqrt(tot((k / FS) ** 2 * w[k + h] ** 2 for k in range(-h, h + 1)) / e)
    slope = [-(k / FS) / (2 * sig * sig) * w[k + h] for k in range(-h, h + 1)]  # w' for a bell
    return dt, sqrt(tot(s * s for s in slope) / e) / (2 * pi)

def G_range(w, h, a):                            # sum of the shifted |w|^2: lowest and highest
    g = [0.0] * a
    for k in range(-h, h + 1):
        g[k % a] += w[k + h] ** 2
    return min(g), max(g), g.count(0.0)

def poisson_ratio(s, a):                         # road 2 for B/A: Poisson summation of the bells
    q = [exp(-2 * pi * pi * k * k * (s / a) ** 2) for k in range(1, 30)]
    return (1 + 2 * tot(q)) / (1 + 2 * tot(x * (-1) ** k for k, x in enumerate(q, 1)))

def show(name, *vs, d=4):
    print(f"{name:<44}" + "".join(f" {v:>12.{d}f}" for v in vs))

# ---- choosing the window: the ridge at 5 s, where the call is at 3000 Hz ----
SST = 1 / sqrt(4 * pi * C)                       # best spread, 1/sqrt(4 pi c)
floor = sqrt(C / (2 * pi))
show("best window spread sigma* (ms)", 1000 * SST)
show("floor sqrt(c / 2 pi) (Hz)", floor)
print("sigma (ms) | dt_w (ms) | dxi_w (Hz) | c dt_w (Hz) | ridge: formula, measured | centre (Hz)")
R = {}
for sig in (0.0025, 0.005, 0.010, SST, 0.040, 0.080):
    h, w = window(sig)
    dt, dx = spreads(sig, w, h)
    mu, R[sig] = ridge(sig)
    form = sqrt(dx * dx + (C * dt) ** 2)
    print(f"chart, {1000 * sig:6.2f} {1000 * dt:9.4f} {dx:9.4f} {C * dt:9.4f} {form:9.4f} {R[sig]:9.4f} {mu:10.2f}")
    assert abs(dt - sig) < 1e-6 * sig and abs(dx - 1 / (4 * pi * sig)) < 1e-6 * dx   # closed form
    assert abs(R[sig] - form) < 1e-3 * form and abs(mu - 3000) < 0.01                # FFT vs time
assert min(R.values()) == R[SST] and abs(R[SST] - floor) < 1e-3 * floor
show("Gaussian at sigma*: dt_w * dxi_w", SST * (1 / (4 * pi * SST)), 1 / (4 * pi), d=6)
for name, s in (("too short, 2.5 ms", 0.0025), ("too long, 80 ms", 0.080)):
    show(f"breaks: {name}: ridge Hz, x best", R[s], R[s] / R[SST])
s2 = SST / sqrt(2)                               # mistake: e^(-t^2/2 sig^2) puts sig on w, not |w|^2
show("breaks: sigma put on w, not |w|^2 (Hz)", sqrt((1 / (4 * pi * s2)) ** 2 + (C * s2) ** 2))
show("try: climb x4: sigma* ms; ridge, pitch Hz", 1000 / sqrt(16 * pi * C), sqrt(4 * C / (2 * pi)), F0 + 4 * C * 5)

# ---- the energy identity, by brute force over every column of the call ----
H, W = window(SST)
M, A = 4096, 320                                 # FFT length (b = 3.90625 Hz), hop 20 ms
assert 2 * H + 1 <= M and N % A == 0             # the window fits: the painless case
gmin, gmax, _ = G_range(W, H, A)
E = tot(v * v for v in X)
total, target, rebuilt = 0.0, list(range(80000, 80320)), {}
for m in range(N // A):
    col = column(m * A, W, H, M)
    total += tot(v.real ** 2 + v.imag ** 2 for v in col)
    if abs(m * A - 80160) <= H + 160:            # rebuild 20 ms around 5 s from these columns
        back = fft(col, +1)
        for n in target:
            if abs(n - m * A) <= H:
                rebuilt[n] = rebuilt.get(n, 0) + W[n - m * A + H] * back[(n - m * A) % M].real / M
G = [0.0] * A
for k in range(-H, H + 1):
    G[k % A] += W[k + H] ** 2
law = M * tot(X[n] ** 2 * G[n % A] for n in range(N))
show("double sum of |X|^2 over 500 x 4096", total, d=0)
show("M * sum x^2 G (painless law)", law, d=0)
assert abs(total - law) < 1e-9 * law
err = max(abs(rebuilt[n] / G[n % A] - X[n]) for n in target)
show("rebuild error, 320 samples near 5 s", err, d=12)
assert err < 1e-9
fE, wE = E / FS, sqrt(2 * pi) * SST
show("||f||^2 (V^2 s), ||w||^2 (s), product", fE, wE, fE * wE, d=6)
show("double sum as an integral (V^2 s^2); gap", total * A / (FS * FS * M), total * A / (FS * FS * M) - fE * wE, d=10)
assert abs(total * A / (FS * FS * M) - fE * wE) < 1e-6
show("G: lowest, highest; b (Hz); ab", gmin, gmax, FS / M, A / M, d=6)
show("frame sum (V^2 s^2); A = B = G / b (s)", total / (FS * FS), gmin * M / FS, d=6)

# ---- frame bounds as the hop grows: direct sum against Poisson summation ----
print("hop (ms) | redundancy M/a | B/A direct | B/A Poisson | samples never seen per hop")
for hop in (160, 320, 640, 960, 1280, 4000):
    lo, hi, zeros = G_range(W, H, hop)
    if lo == 0:                                  # the window's support is shorter than the hop
        print(f"bars, {1000 * hop / FS:5.0f} {M / hop:8.3f} {'none':>12} {'-':>12} {zeros:6d}")
        continue
    pr = poisson_ratio(SST * FS, hop)
    print(f"bars, {1000 * hop / FS:5.0f} {M / hop:8.3f} {hi / lo:12.6f} {pr:12.6f} {zeros:6d}")
    assert abs(hi / lo - pr) < 1e-6 * pr
show("cut window: support (ms), samples; 1/b (ms)", 1000 * (2 * H + 1) / FS, 2 * H + 1, 1000 * M / FS, d=1)
show("cut window: height at the cut, e^-9", W[0], exp(-9), d=6)
show("breaks: M 128, hop 160: numbers, samples, ab", 128 * N // 160, N, 160 / 128, d=2); print("ALL CHECKS PASS")
