# Correlation and the matched filter -- the check behind the card. Standard library only.
# A 13-chip radar pulse (the Barker code, 1 microsecond per chip) buried in static, found by sliding.
# Roads: sliding sums, a written-out DFT, convolution with the flipped pulse, and 1,000 seeded records.
import math
S = [1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1]   # the template s_k: chips of +1 and -1
RECT = [1] * 13                                    # a plain pulse with the same energy, 13
NREC, D, A, SIG = 200, 100, 1.0, 1.0               # record length (1 us samples), true delay, echo, noise sd (uV)
TRIALS, SEED, M64, NFFT = 1000, 20261115, 0xFFFFFFFFFFFFFFFF, 256
E = sum(x * x for x in S)

def corr(f, g, m):                                 # R_fg[m] = sum over k of f[k + m] g[k]
    return sum(f[k + m] * g[k] for k in range(len(g)) if 0 <= k + m < len(f))
def slide(r, s): return [corr(r, s, m) for m in range(len(r) - len(s) + 1)]
def conv(a, b):                                    # (a * b)[n] = sum over j of a[n - j] b[j]
    out = [0.0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b): out[i + j] += x * y
    return out
TW = [(math.cos(2 * math.pi * k / NFFT), math.sin(2 * math.pi * k / NFFT)) for k in range(NFFT)]
def dft(x, sign):                                  # sum_n x[n] e^(sign 2 pi i k n / N), x complex pairs
    out = []
    for k in range(NFFT):
        re = im = 0.0
        for n, (a, b) in enumerate(x):
            c, s = TW[(k * n) % NFFT]; s *= sign
            re += a * c - b * s; im += a * s + b * c
        out.append((re, im))
    return out
def padded(x): return [(float(v), 0.0) for v in x] + [(0.0, 0.0)] * (NFFT - len(x))

state = [SEED]
def gauss():                                       # SplitMix64, then Box-Muller (cosine half)
    u = []
    for _ in range(2):
        state[0] = (state[0] + 0x9E3779B97F4A7C15) & M64
        z = state[0]
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        u.append(((z ^ (z >> 31)) >> 11) / 2.0 ** 53)
    return math.sqrt(-2 * math.log(1 - u[0])) * math.cos(2 * math.pi * u[1])
def record(pulse, delays, noise):
    r = list(noise)
    for d in delays:
        for k, c in enumerate(pulse): r[d + k] += A * c
    return r
def line(label, vals, f="{:.2f}"): print(label, " ".join(f.format(v) for v in vals))

print(f"pulse: 13 chips of 1 us ({3.0e8 * 1e-6 / 2:.0f} m of range each), energy E = {E}; echo {A:.1f} uV in static of sd {SIG:.1f} uV")
print(f"echo delay {D} us = range {3.0e8 * D * 1e-6 / 2:.0f} m; record of {NREC} samples")
# ---- autocorrelation: the pulse slid against itself ----
acb = [corr(S, S, h) for h in range(-12, 13)]
acr = [corr(RECT, RECT, h) for h in range(-12, 13)]
line("chart, autocorrelation, Barker, lags -12..12:", acb, "{:.0f}")
line("chart, autocorrelation, plain pulse, lags -12..12:", acr, "{:.0f}")
assert max(abs(v) for i, v in enumerate(acb) if i != 12) == 1 and acb == acb[::-1]
SH = dft(padded(S), -1)                            # energy spectrum |S^|^2 and its inverse transform
spec = [a * a + b * b for a, b in SH]
back = dft([(v, 0.0) for v in spec], 1)
assert all(abs(back[h % NFFT][0] / NFFT - acb[h + 12]) < 1e-9 for h in range(-12, 13))
print(f"Parseval: R_ss(0) = {acb[12]:.0f}, mean of |S^|^2 over {NFFT} frequencies = {sum(spec) / NFFT:.4f}")
assert abs(sum(spec) / NFFT - E) < 1e-9

# ---- one record: 200 samples of static with the echo at sample 100 ----
noise = [SIG * gauss() for _ in range(NREC)]
r = record(S, [D], noise)
print(f"record: sample sd {math.sqrt(sum(v * v for v in r) / NREC - (sum(r) / NREC) ** 2):.2f} uV, "
      f"largest |sample| {max(abs(v) for v in r):.2f} uV at k = {max(range(NREC), key=lambda k: abs(r[k]))}")
y = slide(r, S)
peak = max(range(len(y)), key=lambda m: y[m])
far = max(y[m] for m in range(len(y)) if abs(m - D) > 12)
print(f"matched output: peak {y[peak]:.2f} uV at lag {peak} us; largest away from the echo {far:.2f} uV")
line("chart, record r_k, k = 80..120:", r[80:121])
line("chart, matched output y_m, m = 80..120:", y[80:121])
assert peak == D
# three roads to the same output: sliding sums, the DFT, convolution with the flipped pulse
Y = [(a * c + b * d, b * c - a * d) for (a, b), (c, d) in zip(dft(padded(r), -1), SH)]
yd = [v[0] / NFFT for v in dft(Y, 1)]
yc = conv(r, S[::-1])
assert max(abs(yd[m] - y[m]) for m in range(len(y))) < 1e-9 and max(abs(yc[m + 12] - y[m]) for m in range(len(y))) < 1e-9
print("roads agree to 1e-9: sliding sums, DFT of length 256, convolution with the flipped pulse")
rsr = {m: corr(S, r, m) for m in range(-(NREC - 1), 13)}
msr = max(rsr, key=lambda m: rsr[m])
print(f"order matters: R_rs peaks at lag +{peak}, R_sr at lag {msr}, both {rsr[msr]:.2f} uV")
assert msr == -D and abs(rsr[msr] - y[peak]) < 1e-12

# ---- the mistake: convolve with the pulse instead of correlating ----
clean = slide(record(S, [D], [0.0] * NREC), S[::-1])
bad = max(abs(v) for v in clean)
print(f"convolve without flipping, no noise: peak {bad:.0f} (not {E}) at lags "
      f"{' and '.join(str(m) for m in range(len(clean)) if abs(clean[m]) == bad)}; at lag {D}: {clean[D]:.0f}")
assert bad == max(abs(v) for v in conv(S, S))
# ---- signal-to-noise ratio of a weighting w: A^2 (w . s)^2 / (sigma^2 w . w) ----
def snr(w, s=S, cov=None):
    cov = cov or [[float(i == j) for j in range(13)] for i in range(13)]
    return A * A * sum(a * b for a, b in zip(w, s)) ** 2 / (SIG ** 2 * sum(w[i] * cov[i][j] * w[j] for i in range(13) for j in range(13)))
best_random = max(snr([gauss() for _ in range(13)]) for _ in range(2000))
print(f"SNR: matched {snr(S):.4f} = A^2 E / sigma^2; convolution, at its own peak {A * A * bad * bad / (SIG ** 2 * E):.4f}; "
      f"best of 2000 random weightings {best_random:.4f}")
assert abs(snr(S) - E) < 1e-9 and best_random < E
# colored noise: each sample carries 0.9 of the previous kick, n_k = (e_k + 0.9 e_(k-1)) / sqrt(1.81)
rho = 0.9 / 1.81
cov = [[1.0 if i == j else (rho if abs(i - j) == 1 else 0.0) for j in range(13)] for i in range(13)]
def best(lo, hi):                                  # solve cov h = s on samples D-lo .. D+12+hi (tridiagonal sweep)
    s = [0.0] * lo + [float(v) for v in S] + [0.0] * hi
    c, h = [0.0] * len(s), [0.0] * len(s)
    for i in range(len(s)):
        m = 1 - rho * c[i - 1] * (i > 0); c[i] = rho / m; h[i] = (s[i] - rho * h[i - 1] * (i > 0)) / m
    for i in range(len(s) - 2, -1, -1): h[i] -= c[i] * h[i + 1]
    return h[lo:lo + 13], sum(a * b for a, b in zip(s, h))  # weights under the echo; best SNR = s . h
(h, b13), brec = best(0, 0), best(D, NREC - D - 13)[1]
bfreq = sum(v / (1 + 2 * rho * TW[k][0]) for k, v in enumerate(spec)) / NFFT  # mean of |S^|^2 / noise power
print(f"colored noise, 0.9 of the previous kick: plain matched SNR {snr(S, cov=cov):.4f}; best on the 13 echo samples {snr(h, cov=cov):.4f} = s . h {b13:.4f}")
print(f"  best on the whole record (whiten, then match) {brec:.4f}; frequency road, mean of |S^|^2 / noise power {bfreq:.4f}")
assert abs(snr(h, cov=cov) - b13) < 1e-9 and snr(h, cov=cov) > snr(S, cov=cov) and abs(brec - bfreq) < 1e-6 * bfreq

# ---- 1,000 records: does the peak land on the echo? ----
hits, at_d = {"Barker, matched": 0, "Barker, convolved": 0, "plain pulse, matched": 0}, []
for _ in range(TRIALS):
    nz = [SIG * gauss() for _ in range(NREC)]
    rb, rp = record(S, [D], nz), record(RECT, [D], nz)
    for name, out in (("Barker, matched", slide(rb, S)), ("Barker, convolved", slide(rb, S[::-1])), ("plain pulse, matched", slide(rp, RECT))):
        hits[name] += max(range(len(out)), key=lambda m: out[m]) == D
        if name == "Barker, matched": at_d.append(out[D])
mu = sum(at_d) / TRIALS
var = sum((v - mu) ** 2 for v in at_d) / (TRIALS - 1)
print(f"simulated output at lag {D}: mean {mu:.3f} (theory {A * E:.0f}, se {math.sqrt(var / TRIALS):.3f}), "
      f"variance {var:.3f} (theory {SIG ** 2 * E:.0f}, se {var * math.sqrt(2 / (TRIALS - 1)):.3f}), SNR {mu * mu / var:.3f}")
assert abs(mu - A * E) < 4 * math.sqrt(var / TRIALS) and abs(var - E) < 4 * var * math.sqrt(2 / (TRIALS - 1))
line("peak on the true lag, out of 1000:", [hits[k] for k in hits], "{:.0f}")
print("  (" + "; ".join(hits) + ")")
assert hits["Barker, matched"] > hits["plain pulse, matched"] > hits["Barker, convolved"]
# ---- two targets 4 us (600 m) apart, no noise ----
for name, p in (("Barker", S), ("plain pulse", RECT)):
    line(f"two echoes at 100 and 104 us ({3.0e8 * 4e-6 / 2:.0f} m apart), {name}, lags 96..108:", slide(record(p, [100, 104], [0.0] * NREC), p)[96:109], "{:.0f}")
print("ALL CHECKS PASS")
