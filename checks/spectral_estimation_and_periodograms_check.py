# Spectral estimation: the plain periodogram, Welch's average and an AR fit, on a
# washing machine's cabinet vibration.  Standard library only: the random numbers,
# the FFT, the Levinson-Durbin recursion and the linear solve are all written out.
import math
FS, N, F0, R, SIG, A, FD = 1000.0, 8192, 150.0, 0.98, 0.05, 0.30, 20.0  # Hz, samples, Hz, -, m/s^2, m/s^2, Hz
A1, A2 = 2 * R * math.cos(2 * math.pi * F0 / FS), -R * R                 # the panel: an AR(2) resonance
st = [2026]
def unif():                                     # SplitMix64, seed 2026
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & (2**64 - 1); z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1); z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def gauss():                                    # Box-Muller, one normal draw per pair of uniforms
    u1 = unif(); u2 = unif(); return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)
def tot(v):                                     # plain left-to-right sum, the same order as the Rust
    s = 0.0
    for q in v: s += q
    return s
def fft(re, im):                                # radix-2, in place
    n = len(re); j = 0
    for i in range(1, n):
        b = n >> 1
        while j & b: j ^= b; b >>= 1
        j |= b
        if i < j: re[i], re[j], im[i], im[j] = re[j], re[i], im[j], im[i]
    L = 2
    while L <= n:
        for k in range(L // 2):
            c, s = math.cos(-2.0 * math.pi * k / L), math.sin(-2.0 * math.pi * k / L)
            for p in range(k, n, L):
                q = p + L // 2; tr = re[q] * c - im[q] * s; ti = re[q] * s + im[q] * c
                re[q] = re[p] - tr; im[q] = im[p] - ti; re[p] += tr; im[p] += ti
        L *= 2
def inv_gain2(a, f):                            # |1 - sum a_k e^{-j 2 pi f k / fs}|^2
    re, im = 1.0, 0.0
    for k in range(len(a)):
        w = 2.0 * math.pi * f * (k + 1) / FS; re -= a[k] * math.cos(w); im += a[k] * math.sin(w)
    return re * re + im * im
def s_true(f): return 2.0 * SIG * SIG / (FS * inv_gain2([A1, A2], f))     # one-sided, (m/s^2)^2/Hz
def ar_psd(a, e, f): return 2.0 * e / (FS * inv_gain2(a, f))
def hann(L, on=True): return [0.5 - 0.5 * math.cos(2.0 * math.pi * n / L) if on else 1.0 for n in range(L)]
def welch(x, L, on=True):                       # average of tapered periodograms, segments every L/2 samples
    w = hann(L, on); U = tot(v * v for v in w); acc = [0.0] * (L // 2 + 1); K = 0
    for s0 in range(0, len(x) - L + 1, max(L // 2, 1) if L < len(x) else L):
        re = [w[n] * x[s0 + n] for n in range(L)]; im = [0.0] * L; fft(re, im)
        for k in range(L // 2 + 1): acc[k] += 2.0 * (re[k] * re[k] + im[k] * im[k]) / (FS * U)
        K += 1
    return [v / K for v in acc], K
def acov(x, p):                                 # sample autocovariance, divided by n
    m = tot(x) / len(x); d = [v - m for v in x]
    return [tot(d[t] * d[t + h] for t in range(len(d) - h)) / len(d) for h in range(p + 1)]
def levinson(c, p):                             # Yule-Walker, grown one order at a time
    a, e = [], c[0]
    for k in range(1, p + 1):
        kk = (c[k] - tot(a[i] * c[k - 1 - i] for i in range(k - 1))) / e
        a = [a[i] - kk * a[k - 2 - i] for i in range(k - 1)] + [kk]; e *= 1.0 - kk * kk
    return a, e
def solve(M, b):                                # Gaussian elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(M)]
    for i in range(n):
        piv = max(range(i, n), key=lambda r: abs(M[r][i])); M[i], M[piv] = M[piv], M[i]
        for r in range(i + 1, n):
            f = M[r][i] / M[i][i]; M[r] = [M[r][c] - f * M[i][c] for c in range(n + 1)]
    out = [0.0] * n
    for i in range(n - 1, -1, -1): out[i] = (M[i][n] - tot(M[i][c] * out[c] for c in range(i + 1, n))) / M[i][i]
    return out
# ---- the record: 8.192 s of cabinet vibration on a 1200 rpm spin ----
y1 = y2 = 0.0; noise = []
for t in range(N + 1000):                       # 1000 samples of run-in are thrown away
    v = A1 * y1 + A2 * y2 + SIG * gauss(); y2, y1 = y1, v
    if t >= 1000: noise.append(v)
x = [noise[t] + A * math.sin(2.0 * math.pi * FD * t / FS) for t in range(N)]
g = [SIG * SIG * (1 - A2) / ((1 + A2) * ((1 - A2) * (1 - A2) - A1 * A1))]       # true autocovariance of the panel
g.append(A1 * g[0] / (1 - A2))
for h in range(2, N): g.append(A1 * g[h - 1] + A2 * g[h - 2])
gx = [g[h] + 0.5 * A * A * math.cos(2.0 * math.pi * FD * h / FS) for h in range(N)]   # plus the drum line
parseval = tot(s_true(k * 0.01) * 0.01 for k in range(1, 50000)) + 0.5 * 0.01 * (s_true(0.0) + s_true(500.0))
fpk = max((140 + 0.001 * i for i in range(20001)), key=s_true); half = [f for f in (140 + 0.001 * i for i in range(20001)) if s_true(f) >= s_true(fpk) / 2]
print(f"setup: fs {FS:.0f} Hz, N {N}, record {N / FS:.3f} s, drum {FD:.0f} Hz ({60 * FD:.0f} rpm) amplitude {A:.2f} m/s^2")
print(f"panel variance: formula {g[0]:.5f}, area under S {parseval:.5f}, sample {tot(v * v for v in noise) / N:.5f} (m/s^2)^2")
print(f"true peak {fpk:.2f} Hz, S {s_true(fpk):.6f} (m/s^2)^2/Hz, half-power width {half[-1] - half[0]:.2f} Hz")
seg = x[:512]; P1, _ = welch(seg, 512, False); c1 = [tot(seg[t] * seg[t + h] for t in range(512 - h)) / 512 for h in range(512)]
wk = max(abs(2.0 / FS * (c1[0] + 2 * tot(c1[h] * math.cos(2 * math.pi * k * h / 512) for h in range(1, 512))) - P1[k]) / P1[k] for k in range(1, 256))
print(f"Wiener-Khinchin: FFT periodogram vs transform of c(h), largest relative gap {wk * 1e9:.2f}e-9")
w = hann(512); ov, U5 = tot(w[n] * w[n + 256] for n in range(256)), tot(v * v for v in w); rho = (ov / U5) * (ov / U5)
print(f"overlap correlation of half-overlapped Hann segments: rho = ({ov:.4f} / {U5:.4f})^2 = {rho:.4f}")
print("   L    K  bin Hz  scatter  formula 1/sqrtK  S near 150  E[read]   read  highest 100-200 Hz")
res, pk = {}, {}
for L, on in ((N, False), (2048, True), (512, True), (128, True), (64, True)):
    P, K = welch(x, L, on); df = FS / L; res[L] = P
    r = [P[k] / s_true(k * df) for k in range(len(P)) if 200 <= k * df <= 480]
    m = tot(r) / len(r); sd = math.sqrt(tot((q - m) * (q - m) for q in r) / len(r))
    sdf = 1.0 if K == 1 else math.sqrt((1 + 2 * rho * (1 - 1 / K)) / K)
    wn = hann(L, on); U = tot(v * v for v in wn); k0 = round(150 / df)
    vh = (lambda h: tot(wn[n] * wn[n + h] for n in range(L - h))) if on else (lambda h: float(L - h))   # window overlap
    ev = 2.0 / (FS * U) * (gx[0] * U + 2.0 * tot(gx[h] * math.cos(2.0 * math.pi * k0 * h / L) * vh(h) for h in range(1, L)))
    kh = max((k for k in range(len(P)) if 100 <= k * df <= 200), key=lambda k: P[k])
    print(f"{L:>4} {K:>4} {df:7.3f} {sd:8.3f} {sdf:8.3f} {1 / math.sqrt(K):7.3f} {s_true(k0 * df):11.6f} {ev:8.6f} {P[k0]:8.6f} {P[kh]:9.6f} at {kh * df:6.2f}")
    assert abs(sd - sdf) < 3 * sdf * math.sqrt(2 / len(r)), "scatter must match the Welch variance formula"
    assert abs(P[k0] - ev) < 3 * sdf * ev, "reading near 150 Hz within 3 sd of its expected value"
    pk[L] = (P[kh], ev)
    if L == N: share = len([q for q in r if q > 3]) / len(r); nb = len(r)
print(f"plain periodogram: share of bins over 3x the truth {share:.4f}, exponential law e^-3 = {math.exp(-3):.4f}")
assert abs(share - math.exp(-3)) < 3 * math.sqrt(math.exp(-3) * (1 - math.exp(-3)) / nb), "periodogram bins follow the exponential law"
P2, _ = welch(x[:2048], 2048, False); r2 = [P2[k] / s_true(k * FS / 2048) for k in range(1025) if 200 <= k * FS / 2048 <= 480]
m2 = tot(r2) / len(r2); print(f"plain periodogram of the first 2.048 s: scatter {math.sqrt(tot((q - m2) * (q - m2) for q in r2) / len(r2)):.3f}")
Pr, _ = welch(x, 512, False); k30 = 15
print(f"Welch L=512 at {k30 * FS / 512:.2f} Hz: rectangular {Pr[k30] / s_true(k30 * FS / 512):.2f}x truth, Hann {res[512][k30] / s_true(k30 * FS / 512):.2f}x truth")
for L in (512, 2048):
    df = FS / L; tp = tot(res[L][k] * df for k in range(len(res[L])) if 15 <= k * df <= 25)
    print(f"drum line, L={L}: peak height {res[L][round(FD / df)]:.5f} (m/s^2)^2/Hz, summed power {tp:.5f} (m/s^2)^2, true {A * A / 2:.5f}")
    assert abs(tp - A * A / 2) < 0.02 * A * A / 2, "the line's power is the sum over its bins"
c = acov(x, 60); aic = min(range(1, 61), key=lambda p: N * math.log(levinson(c, p)[1]) + 2 * p); grid = [100 + 0.05 * i for i in range(2001)]
print(f"AR order  E_p       scatter  panel peak Hz  S at peak   top 5-60 Hz  top/5 Hz   (AIC picks order {aic})")
for p in (2, 4, 8, 20, aic):
    a, e = levinson(c, p); fp = max(grid, key=lambda f: ar_psd(a, e, f))
    fl = max((5 + 0.05 * i for i in range(1101)), key=lambda f: ar_psd(a, e, f))
    ra = [ar_psd(a, e, f) / s_true(f) for f in range(200, 481)]; ma = tot(ra) / len(ra)
    lo = f"{fl:12.2f} {ar_psd(a, e, fl) / ar_psd(a, e, 5.0):9.2f}" if 5 < fl < 60 else "        none"
    print(f"{p:>8} {e:.6f} {math.sqrt(tot((q - ma) * (q - ma) for q in ra) / len(ra)):8.3f} {fp:14.2f} {ar_psd(a, e, fp):10.6f} {lo}")
    if p == 20: a20, e20, ar20 = a, e, ar_psd(a, e, fp)
yw = solve([[c[abs(i - k)] for k in range(20)] for i in range(20)], c[1:21])
print(f"AR(20): Levinson vs direct Yule-Walker solve, largest gap {max(abs(u - v) for u, v in zip(a20, yw)) * 1e9:.2f}e-9")
assert max(abs(u - v) for u, v in zip(a20, yw)) < 1e-9, "two roads to the AR coefficients"
an, en = levinson(acov(noise, 2), 2); se = math.sqrt((1 - A2 * A2) / N)
print(f"AR(2) on the panel alone: a1 {an[0]:.4f} (true {A1:.4f}), a2 {an[1]:.4f} (true {A2:.4f}), E {en:.6f} (true {SIG * SIG:.6f}), se {se:.4f}")
assert abs(an[0] - A1) < 3 * se and abs(an[1] - A2) < 3 * se, "AR(2) fit recovers the panel"
assert abs(parseval - g[0]) < 1e-4 * g[0], "area under the true spectrum is the variance"
assert wk < 1e-7, "periodogram equals the transform of the sample autocovariance"
T = s_true(fpk); print(f"over the true peak: plain highest {pk[N][0] / T:.2f}, Welch512 highest {pk[512][0] / T:.2f}, AR(20) {ar20 / T:.2f}, "
                      f"L=128 expected {pk[128][1] / T:.2f}, L=64 highest {pk[64][0] / T:.2f}")
ks = range(67, 88)
print("chart Hz " + " ".join(f"{k * FS / 512:6.1f}" for k in ks))
print("true     " + " ".join(f"{1000 * s_true(k * FS / 512):6.2f}" for k in ks))
print("plain    " + " ".join(f"{1000 * res[N][16 * k]:6.2f}" for k in ks))
print("Welch512 " + " ".join(f"{1000 * res[512][k]:6.2f}" for k in ks))
print("AR(20)   " + " ".join(f"{1000 * ar_psd(a20, e20, k * FS / 512):6.2f}" for k in ks))
print("ALL CHECKS PASS")
