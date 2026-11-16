# Wavelet denoising: keep the big coefficients, throw the small ones away.
# A synthetic heart trace (illustrative), white noise, the D4 wavelet ladder, and the universal threshold.
# Standard library only.  Noise: SplitMix64 (seed 2026) and Box-Muller, written out.
from math import sqrt, log, exp, cos, pi, copysign
M64 = (1 << 64) - 1
class Rng:
    def __init__(s, seed): s.x = seed
    def unif(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64; z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
    def gauss(s):
        a = s.unif(); b = s.unif(); return sqrt(-2.0 * log(1.0 - a)) * cos(2.0 * pi * b)
FS, N, J, SIG = 360, 2048, 4, 0.1          # samples per second, samples, levels, noise sd in mV
WAVES = [(0.15, -0.2, 0.025), (-0.1, -0.025, 0.008), (1.2, 0.0, 0.010), (-0.25, 0.025, 0.008), (0.3, 0.3, 0.04)]
BEATS = [0.4 + 0.8 * b for b in range(7)]   # 75 beats a minute; P, Q, R, S, T bumps (mV, s from R, sd s)
PEAKS = [round(b * FS) for b in BEATS]
clean = [sum(a * exp(-(i / FS - b - c) ** 2 / (2 * w * w)) for b in BEATS for a, c, w in WAVES) for i in range(N)]
R3, R2 = sqrt(3.0), sqrt(2.0)
H = [(1 + R3) / (4 * R2), (3 + R3) / (4 * R2), (3 - R3) / (4 * R2), (1 - R3) / (4 * R2)]  # D4 lowpass
G = [H[3], -H[2], H[1], -H[0]]                                                          # D4 highpass
def forward(x):
    s, ds = list(x), []
    for _ in range(J):
        n = len(s)
        ds.append([sum(G[m] * s[(2 * k + m) % n] for m in range(4)) for k in range(n // 2)])
        s = [sum(H[m] * s[(2 * k + m) % n] for m in range(4)) for k in range(n // 2)]
    return s, ds
def inverse(s, ds):
    for d in reversed(ds):
        n = 2 * len(s); x = [0.0] * n
        for k in range(len(s)):
            for m in range(4): x[(2 * k + m) % n] += H[m] * s[k] + G[m] * d[k]
        s = x
    return s
def hard(v, t): return v if abs(v) > t else 0.0
def soft(v, t): return copysign(max(abs(v) - t, 0.0), v) + 0.0
def denoise(x, rule, t):
    s, ds = forward(x); return inverse(s, [[rule(v, t) for v in d] for d in ds])
def spun(x, rule, t, k=8):                    # average the denoised record over k circular shifts
    acc = [0.0] * N
    for c in range(k):
        y = denoise(x[c:] + x[:c], rule, t)
        for i in range(N): acc[(i + c) % N] += y[i] / k
    return acc
def moving_avg(x, w): return [sum(x[(i + k) % N] for k in range(-(w // 2), w // 2 + 1)) / w for i in range(N)]
def rms(a, b): return sqrt(sum((p - q) ** 2 for p, q in zip(a, b)) / len(a))
def r_height(y): return sum(y[p] for p in PEAKS) / len(PEAKS)
def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)
def Phi(x):                                   # normal CDF: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * abs(total) and k < 500:
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def risk_closed(lam, th):                     # E (soft(th + Z, lam) - th)^2 for Z standard normal
    return (1 + lam * lam + (th * th - lam * lam - 1) * (Phi(lam - th) - Phi(-lam - th))
            - (lam - th) * phi(lam + th) - (lam + th) * phi(lam - th))
def risk_simpson(lam, th):
    f = lambda z: (soft(th + z, lam) - th) ** 2 * phi(z)
    cuts = [-12.0, -lam - th, lam - th, 12.0]
    return sum(simpson(f, cuts[i], cuts[i + 1]) for i in range(3))
def close(a, b, tol): return abs(a - b) <= tol
mult = sqrt(2 * log(N)); LAM = SIG * mult
print(f"heart trace: {N} samples at {FS} Hz = {N / FS:.3f} s, {len(BEATS)} beats 0.8 s apart (75 a minute), clean R height {r_height(clean):.3f} mV, noise sd {SIG} mV")
s0, d0 = forward(clean)
e_t, e_c = sum(v * v for v in clean), sum(v * v for v in s0) + sum(v * v for d in d0 for v in d)
back = max(abs(a - b) for a, b in zip(inverse(s0, d0), clean))
print(f"D4 ladder, {J} levels: rebuild error below 1e-12 {'yes' if back < 1e-12 else 'no'}; energy by samples {e_t:.6f}, by coefficients {e_c:.6f} mV^2")
assert back < 1e-12 and close(e_t, e_c, 1e-9)
print(f"universal threshold: ln {N} = {log(N):.4f}, sqrt(2 ln {N}) = {mult:.4f}, lambda = {LAM:.4f} mV")
# road 1: the largest of N pure-noise coefficients, by formula, bound and simulation
p1 = 2 * (1 - Phi(mult)); p_any = 1 - (1 - p1) ** N; bound = 1 / sqrt(pi * log(N))
rng = Rng(2026); trials = 1000; nd = N - len(s0)   # nd: the details, the only coefficients thresholded
tops = [max(abs(rng.gauss()) for _ in range(N)) for _ in range(trials)]; hits = sum(t > mult for t in tops)
print(f"one noise coefficient above: {1e6 * p1:.2f} per million; expected count {N * p1:.4f}; P(any of {N}) {p_any:.4f}; bound {bound:.4f}"
      f"\nover the {nd} thresholded details: expected count {nd * p1:.4f}; P(any of {nd}) {1 - (1 - p1) ** nd:.4f}")
print(f"{trials} noise records: largest |coefficient| mean {sum(tops) / trials:.4f}, range {min(tops):.4f} to {max(tops):.4f}; share above {hits / trials:.3f}")
assert p_any < bound and abs(hits / trials - p_any) < 4 * sqrt(p_any * (1 - p_any) / trials) and close(N * sqrt(2 * pi) * phi(mult), 1.0, 1e-12)
for n in (64, 2048, 2 ** 20):
    m = sqrt(2 * log(n)); q = 2 * (1 - Phi(m)); print(f"  N {n:8d}: multiplier {m:.4f}, P(any above) {1 - (1 - q) ** n:.4f}, bound {1 / sqrt(pi * log(n)):.4f}")
for t in (1.0, 2.0, 3.0): print(f"  threshold {t:.0f} sigma: noise coefficients expected above {N * 2 * (1 - Phi(t)):.1f} of {N}, {nd * 2 * (1 - Phi(t)):.1f} of {nd} details")
# road 2: soft-threshold risk of one coefficient, closed form against Simpson, and the oracle inequality
r0 = risk_closed(mult, 0.0)
print(f"risk at theta 0, per million sigma^2: closed {1e6 * r0:.4f}, Simpson {1e6 * risk_simpson(mult, 0.0):.4f}, bound 4 phi/lam^3 {1e6 * 4 * phi(mult) / mult ** 3:.4f}")
worst_gap, worst_slack = 0.0, -1.0
for i in range(61):
    th = i / 10; rc = risk_closed(mult, th)
    worst_gap = max(worst_gap, abs(rc - risk_simpson(mult, th)))
    worst_slack = max(worst_slack, rc - r0 - min(th * th, 1 + mult * mult))
for th in (0.5, 1.0, mult, 6.0): print(f"  theta {th:.4f}: risk {risk_closed(mult, th):.6f}, oracle {min(th * th, 1.0):.4f}")
print(f"theta 0..6: closed and Simpson agree to 1e-8 {'yes' if worst_gap < 1e-8 else 'no'}; max of risk - r(0) - min(theta^2, 1 + lam^2) {worst_slack:.6f}")
assert worst_gap < 1e-8 and worst_slack <= 0 and r0 <= 4 * phi(mult) / mult ** 3
big = [sum(abs(v) > LAM for v in d) for d in d0]
oracle = sum(min(v * v, SIG * SIG) for d in d0 for v in d); coarse = len(s0) * SIG ** 2
soft_exp = sum(SIG ** 2 * risk_closed(mult, v / SIG) for d in d0 for v in d) + coarse
print(f"clean details above lambda, levels 1-{J}: {big} of {[len(d) for d in d0]}, {sum(big)} of {N - len(s0)}; coarse kept {len(s0)}")
print(f"2 ln N + 1 = {2 * log(N) + 1:.4f}; ideal (oracle) error: details {oracle:.4f} + coarse {coarse:.4f} = {oracle + coarse:.4f} mV^2")
print(f"soft, expected: details {soft_exp - coarse:.4f}, total {soft_exp:.4f}; bound on details {(2 * log(N) + 1) * (SIG ** 2 + oracle):.4f}, total {(2 * log(N) + 1) * (SIG ** 2 + oracle) + coarse:.4f}")
# road 3: the same expected errors by simulation, 100 noise draws, against two moving averages
draws, sums = 100, {"soft": 0.0, "hard": 0.0, "avg5": 0.0, "avg7": 0.0}; wins, nv, ma7 = 0, 0.0, moving_avg(clean, 7)  # nv: noise variance a 7-sample average leaves
for _ in range(draws):
    x = [c + SIG * rng.gauss() for c in clean]
    out = {"soft": denoise(x, soft, LAM), "hard": denoise(x, hard, LAM), "avg5": moving_avg(x, 5), "avg7": moving_avg(x, 7)}
    err = {k: sum((a - b) ** 2 for a, b in zip(y, clean)) for k, y in out.items()}
    for k in sums: sums[k] += err[k] / draws
    wins += err["hard"] < min(err["avg5"], err["avg7"]); nv += sum((a - b) ** 2 for a, b in zip(out["avg7"], ma7)) / (draws * N)
print(f"{draws} draws, average total squared error, mV^2: " + ", ".join(f"{k} {v:.4f}" for k, v in sums.items()) + f"; hard beats both averages {wins} times"
      f"\nmoving average 7 on the noise alone: variance {nv:.6f}, sigma^2/7 {SIG ** 2 / 7:.6f} mV^2")
assert abs(sums["soft"] - soft_exp) < 0.03 * soft_exp and sums["soft"] <= (2 * log(N) + 1) * (SIG ** 2 + oracle) + coarse and wins >= 95 and abs(nv * 7 / SIG ** 2 - 1) < 0.03
# the worked record: one draw, every method
rng = Rng(7); noisy = [c + SIG * rng.gauss() for c in clean]
sh = sorted(abs(v) for v in forward(noisy)[1][0]); sig_hat = (sh[511] + sh[512]) / 2 / 0.6745
sd_all = sqrt(sum(v * v for v in noisy) / N - (sum(noisy) / N) ** 2)
methods = [("noisy record", noisy), ("moving average 3", moving_avg(noisy, 3)), ("moving average 5", moving_avg(noisy, 5)),
           ("moving average 7", moving_avg(noisy, 7)), ("moving average 9", moving_avg(noisy, 9)),
           ("hard, universal", denoise(noisy, hard, LAM)), ("soft, universal", denoise(noisy, soft, LAM)),
           ("hard, 8 shifts", spun(noisy, hard, LAM)), ("hard, sigma from MAD", denoise(noisy, hard, sig_hat * mult)),
           ("hard, lambda = sigma", denoise(noisy, hard, SIG)), ("hard, sigma = record sd", denoise(noisy, hard, sd_all * mult))]
d3 = forward(noisy)[1][2][123:129]
print("level-3 coefficients near beat 4:", " ".join(f"{v:.4f}" for v in d3))
print("  hard:", " ".join(f"{hard(v, LAM):.4f}" for v in d3), "  soft:", " ".join(f"{soft(v, LAM):.4f}" for v in d3))
print(f"one record (seed 7): sigma from MAD {sig_hat:.4f}; record sd {sd_all:.4f}")
for name, y in methods: print(f"  {name:24s} rms error {rms(y, clean):.4f} mV  R height {r_height(y):.3f} mV")
err = dict((k, rms(y, clean)) for k, y in methods)
assert err["hard, universal"] < min(err[f"moving average {w}"] for w in (3, 5, 7, 9)) < err["noisy record"]
assert err["hard, 8 shifts"] < err["hard, universal"] < err["soft, universal"]
# a broken hypothesis: noise that is not white (each sample the sum of four white draws, halved)
w = [rng.gauss() for _ in range(N + 3)]; col = [SIG * (w[i] + w[i + 1] + w[i + 2] + w[i + 3]) / 2 for i in range(N)]
_, dc = forward(col)
print("coloured noise, sd per level in sigma units:", " ".join(f"{sqrt(sum(v * v for v in d) / len(d)) / SIG:.3f}" for d in dc),
      f"; noise coefficients above lambda {sum(abs(v) > LAM for d in dc for v in d)}")
print(f"coloured noise record: rms error noisy {rms([a + b for a, b in zip(clean, col)], clean):.4f}, hard {rms(denoise([a + b for a, b in zip(clean, col)], hard, LAM), clean):.4f} mV")
c4 = PEAKS[3]; idx = list(range(c4 - 18, c4 + 19, 2))
chart = [("clean", clean), ("noisy", noisy), ("hard", methods[5][1]), ("hard, 8 shifts", methods[7][1]), ("moving average 7", methods[3][1])]
print("chart ms:", " ".join(f"{1000 * (i - c4) / FS:.0f}" for i in idx))
for name, y in chart: print(f"chart {name}:", " ".join(f"{y[i]:.2f}" for i in idx))
print("ALL CHECKS PASS")
