# Littlewood-Paley: a test click split into the ten octave bands of a graphic equaliser.
# Standard library only.  The click: every harmonic n of 31.25 Hz up to 724 (22.6 kHz),
# amplitude A/sqrt(n) (pink: equal energy per octave), all in phase at t = 0, period 32 ms,
# 4096 samples per period.  Norms are time averages over one period.  Roads: band pieces
# built from the formula against pieces cut from the samples by an FFT written out here;
# energy against the coefficients; the average over all 1024 slider sign patterns against
# Khintchine's closed form; a Haar square function against Burkholder's constants.
from math import cos, sin, pi, sqrt, log2
F0, N, H, A, K = 31.25, 4096, 724, 0.01, 10
def band(n):                    # octave band k: centre F0 2^k, edges centre/sqrt2 and centre*sqrt2
    for k in range(K + 1):
        if 2 * n * n >= 4 ** k and n * n < 2 * 4 ** k: return k
amp = [0.0] + [A / sqrt(n) for n in range(1, H + 1)]
CT = [cos(2 * pi * s / N) for s in range(N)]
def synth(terms): return [sum(c * CT[n * s % N] for n, c in terms) for s in range(N)]
def fft(x, sg):                 # radix 2; sg = -1 forward, +1 inverse (unscaled)
    x = list(x); n = len(x); j = 0
    for i in range(1, n):
        b = n >> 1
        while j & b: j ^= b; b >>= 1
        j |= b
        if i < j: x[i], x[j] = x[j], x[i]
    m = 2
    while m <= n:
        w = complex(cos(2 * pi / m), sg * sin(2 * pi / m))
        for s in range(0, n, m):
            z = complex(1, 0)
            for t in range(m // 2):
                u, v = x[s + t], x[s + t + m // 2] * z
                x[s + t], x[s + t + m // 2] = u + v, u - v; z = z * w
        m *= 2
    return x
def mult(X, g):                 # apply a gain g(n) to bins n and N - n, back to samples
    Y = [complex(0, 0)] * N
    for n in range(1, N // 2):
        Y[n], Y[N - n] = X[n] * g(n), X[N - n] * g(n)
    return [y.real / N for y in fft(Y, 1)]
def nrm(x, p):
    if p == 2: return sqrt(sum(v * v for v in x) / N)
    return sqrt(sqrt(sum(v * v * v * v for v in x) / N))
def sq(pieces): return [sqrt(sum(P[s] * P[s] for P in pieces)) for s in range(N)]
f = synth([(n, amp[n]) for n in range(1, H + 1)])
P = [synth([(n, amp[n]) for n in range(1, H + 1) if band(n) == k]) for k in range(K)]
X = fft(f, -1)
Q = [mult(X, lambda n, k=k: 1.0 if band(n) == k else 0.0) for k in range(K)]
assert max(abs(P[k][s] - Q[k][s]) for k in range(K) for s in range(N)) < 1e-12
print(f"click: amplitude 0.01/sqrt(n) V at harmonics n = 1 to 724 of 31.25 Hz (top {H * F0:.0f} Hz); f(0) = {f[0]:.6f} V")
print(f"sampling: {N} samples per 32 ms period ({N * 1000 / 32:.0f} per second); 4th powers reach harmonic {4 * H} < {N}, so means are exact")
print("band pieces: built from the formula and cut from the samples by FFT agree to 1e-12")
e2 = sum(amp[n] ** 2 for n in range(1, H + 1)) / 2
for k in range(K):
    ns = [n for n in range(1, H + 1) if band(n) == k]
    print(f"band {F0 * 2 ** k:8.2f} Hz: harmonics {ns[0]:3d}-{ns[-1]:3d}, mean power {nrm(P[k], 2) ** 2 * 1e6:7.4f} mV^2"
          f" ({100 * nrm(P[k], 2) ** 2 / e2:5.2f} %), ||D_k f||_4 {nrm(P[k], 4) * 1000:.4f} mV")
S = sq(P); f2, f4, S2, S4 = nrm(f, 2), nrm(f, 4), nrm(S, 2), nrm(S, 4)
bandsum = sum(nrm(Pk, 2) ** 2 for Pk in P)
print(f"p = 2: ||f||^2 {f2 * f2 * 1e6:.6f}; coefficients {e2 * 1e6:.6f}; band sum {bandsum * 1e6:.6f}; ||Sf||^2 {S2 * S2 * 1e6:.6f} (mV^2)")
assert abs(f2 * f2 - e2) < 1e-15 and abs(S2 * S2 - e2) < 1e-15 and abs(bandsum - e2) < 1e-15
print(f"p = 4: ||f||_4 {f4 * 1000:.4f} mV; ||Sf||_4 {S4 * 1000:.4f} mV; ratio {S4 / f4:.6f}")
print("chart, |f| mV:", " ".join(f"{abs(f[s]) * 1000:.1f}" for s in range(0, 33, 2)))
print("chart, Sf mV: ", " ".join(f"{S[s] * 1000:.1f}" for s in range(0, 33, 2)))
kh = sum((e1 * 3 + e2 * 4) ** 4 for e1 in (1, -1) for e2 in (1, -1)) / 4
print(f"Khintchine by hand, a = 3, 4: mean of (+-3 +-4)^4 over the 4 sign pairs {kh:.0f}; 3 x 25^2 - 2 x (81 + 256) = {3 * 25 ** 2 - 2 * (81 + 256)}")
acc, form = [0.0] * 512, 0.0    # all 1024 sign patterns, by Gray code; -e gives the same size as e
for s in range(N):
    d = [Pk[s] for Pk in P]; x = sum(d); sgn = [1] * K
    acc[0] += x * x * x * x
    for i in range(1, 512):
        b = (i & -i).bit_length(); x -= 2 * sgn[b] * d[b]; sgn[b] = -sgn[b]
        acc[i ^ (i >> 1)] += x * x * x * x
    q2 = sum(v * v for v in d); form += 3 * q2 * q2 - 2 * sum(v * v * v * v for v in d)
E4, form = sum(acc) / 512 / N, form / N
sizes = [sqrt(sqrt(a / N)) for a in acc]
print(f"Khintchine: mean ||T_e f||_4^4 over 1024 sign patterns {E4 * 1e12:.3f}; 3||Sf||^4 - 2 sum ||D_k f||^4 {form * 1e12:.3f} (mV^4)")
assert abs(E4 - form) < 1e-9 * form and abs(sizes[0] - f4) < 1e-15
print(f"sandwich: ||Sf||_4 {S4 * 1000:.4f} <= (mean)^(1/4) {E4 ** 0.25 * 1000:.4f} <= 3^(1/4) ||Sf||_4 {3 ** 0.25 * S4 * 1000:.4f} (mV)")
assert S4 <= E4 ** 0.25 <= 3 ** 0.25 * S4
print(f"sign patterns: smallest ||T_e f||_4 {min(sizes) * 1000:.4f} mV (over 3^(1/4): {3 ** -0.25 * min(sizes) * 1000:.4f}), largest {max(sizes) * 1000:.4f} mV = f itself, all plus")
assert 3 ** -0.25 * min(sizes) <= S4 <= max(sizes) == sizes[0]
def w(n, k):                    # smooth crossfade in octaves; the end bands are shelves
    x = log2(n) - k
    if (k == 0 and x <= 0) or (k == K - 1 and x >= 0): return 1.0
    return cos(pi * x / 2) ** 2 if abs(x) < 1 else 0.0
R = [mult(X, lambda n, k=k: w(n, k)) for k in range(K)]
assert max(abs(sum(Rk[s] for Rk in R) - f[s]) for s in range(N)) < 1e-12
Rs = sq(R)
print(f"smooth pieces: sum rebuilds f to 1e-12; energy kept {sum(nrm(Rk, 2) ** 2 for Rk in R) / e2:.6f} of f's; ||S f||_4 / ||f||_4 {nrm(Rs, 4) / f4:.6f}")
H2 = [(sum(f) / N) ** 2] * N; prev = [sum(f) / N] * N
for j in range(1, 13):
    blk = N >> j
    cur = [sum(f[(s // blk) * blk:(s // blk + 1) * blk]) / blk for s in range(N)]
    H2 = [H2[s] + (cur[s] - prev[s]) ** 2 for s in range(N)]; prev = cur
hr = nrm([sqrt(v) for v in H2], 4) / f4
print(f"Haar twin, 12 levels: ||S_H f||_4 / ||f||_4 {hr:.6f}; Burkholder: between 1/3 and 3")
assert 1 / 3 <= hr <= 3 and abs(nrm([sqrt(v) for v in H2], 2) - f2) < 1e-12
gains = [6, 4, 2, 0, -2, -2, 0, 2, 4, 6]   # slider settings, dB
def m(l): l = min(max(l, 0), K - 1); k = min(int(l), K - 2); return 10 ** ((gains[k] + (l - k) * (gains[k + 1] - gains[k])) / 20)
var = max(abs(m(k) - m(k - 0.5)) + abs(m(k + 0.5) - m(k)) for k in range(K))
Y = mult(X, lambda n: m(log2(n)))
print(f"equaliser: largest gain {max(m(k) for k in range(K)):.6f}, largest variation in a band {var:.6f}; ||Tf||_2/||f||_2 {nrm(Y, 2) / f2:.6f}, ||Tf||_4/||f||_4 {nrm(Y, 4) / f4:.6f}")
lac = synth([(2 ** k, 1.0) for k in range(K)]); Sl = [sqrt(sum(CT[2 ** k * s % N] ** 2 for k in range(K))) for s in range(N)]
l4 = ((K * K / 4 + K / 8) / (3 * K / 8 + 3 * K * (K - 1) / 4 + 1.5 * (K - 2))) ** 0.25   # pairings, and 8 carries 2^a + 2^a + 2^(a+1) = 2^(a+2)
print(f"breaks, p = infinity: one tone per band: max Sf / max f {max(Sl) / max(lac):.6f}, 1/sqrt(10) {1 / sqrt(10):.6f}; at p = 4: {nrm(Sl, 4) / nrm(lac, 4):.6f}, closed form {l4:.6f}")
assert abs(max(Sl) / max(lac) - 1 / sqrt(10)) < 1e-12 and abs(nrm(Sl, 4) / nrm(lac, 4) - l4) < 1e-12
eq = []
for top in (181, 362, 724):
    fc = synth([(n, amp[n]) for n in range(1, top + 1)])
    Se = [sqrt(sum(amp[n] ** 2 for n in range(1, top + 1)) / 2 + v) for v in synth([(2 * n, amp[n] ** 2 / 2) for n in range(1, top + 1)])]
    eq.append(nrm(Se, 4) / nrm(fc, 4))
print(f"breaks, equal 31.25 Hz bands: ||Sf||_4/||f||_4 with top harmonic 181, 362, 724: {eq[0]:.6f} {eq[1]:.6f} {eq[2]:.6f}")
assert eq[0] > eq[1] > eq[2]
st = 2026
def rnd():                      # SplitMix64
    global st
    st = (st + 0x9E3779B97F4A7C15) % 2 ** 64; z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return z ^ (z >> 31)
def lratio(h, nn, sg):          # click of h harmonics on nn samples, by inverse FFT: ||f||_4 / ||T_sg f||_4
    c = [A / sqrt(min(n, nn - n)) * nn / 2 if 0 < min(n, nn - n) <= h else 0.0 for n in range(nn)]
    fl, gl = fft(c, 1), fft([v * sg[min(n, nn - n)] if v else 0.0 for n, v in enumerate(c)], 1)
    return sqrt(sqrt(sum(z.real ** 4 for z in fl) / sum(z.real ** 4 for z in gl)))
sig = [0] + [1 if rnd() >> 63 else -1 for n in range(1, N // 2)]
flips = sum(1 for n in range(363, 724) if sig[n] != sig[n + 1])
st, keep = 2026, st; sgl = [0] + [1 if rnd() >> 63 else -1 for n in range(1, 11585)]; st = keep   # the same signs, continued
gr = [lratio(h, 4096 * h // 724, sgl) for h in (724, 2896, 11584)]
print(f"breaks, random sign per harmonic: variation in the 16 kHz band {2 * flips}; ||T g||_4/||g||_4 = ||f||_4/||g||_4 {gr[0]:.6f}")
print(f"breaks, the same signs on clicks of 2896 and 11584 harmonics: ||f||_4/||g||_4 {gr[1]:.6f} {gr[2]:.6f}")
assert abs(gr[0] - f4 / nrm(mult(X, lambda n: sgl[n]), 4)) < 1e-12 and gr[0] < gr[1] < gr[2]
out = sqrt(sum(nrm(Pk, 4) ** 2 for Pk in P))
print(f"breaks, norms before squares: (sum ||D_k f||_4^2)^(1/2) {out * 1000:.4f} mV against ||Sf||_4 {S4 * 1000:.4f} mV")
assert out > S4
ph = [2 * pi * (rnd() >> 11) / 2 ** 53 for n in range(H + 1)]
Z = [complex(0, 0)] * N
for n in range(1, H + 1): Z[n] = complex(cos(ph[n]), sin(ph[n])) * amp[n] * N / 2; Z[N - n] = Z[n].conjugate()
pn = [z.real / N for z in fft(Z, 1)]; Xp = fft(pn, -1)
Sp = sq([mult(Xp, lambda n, k=k: 1.0 if band(n) == k else 0.0) for k in range(K)])
print(f"try: random phases (pink noise): ||Sf||_4/||f||_4 {nrm(Sp, 4) / nrm(pn, 4):.6f}; double A: ratio {nrm(sq([[2 * v for v in Pk] for Pk in P]), 4) / nrm([2 * v for v in f], 4):.6f}")
gains = [12, 9, 6, 3, 0, 0, 0, 0, 0, 0]; Yb = mult(X, lambda n: m(log2(n)))
print(f"try: bass boost 12 9 6 3 0 dB: ||Tf||_2/||f||_2 {nrm(Yb, 2) / f2:.6f}, ||Tf||_4/||f||_4 {nrm(Yb, 4) / f4:.6f}")
print("ALL CHECKS PASS")
