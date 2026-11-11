# Compressed sensing -- the check behind the card.  Standard library only: the random draws, the
# spectrum, both recovery methods, the proof certificate and the small solves are written out below.
# 1000 samples of a guitar chord at 44.1 kHz hold three tones: 3 of 501 frequencies are switched on.
# Keep 40 samples at random times, throw the rest away, and rebuild the whole spectrum from the 40.
from math import sqrt, cos, sin, pi, log, atan2, comb; from operator import mul
N, M, FS, SEED = 1000, 40, 44100.0, 2026  # samples, samples kept, sampling rate in Hz, random seed
TONES = ((5, 100.0, 0.3), (15, 60.0, 1.1), (80, 40.0, 2.0))  # (frequency bin, amplitude mV, phase rad)
TAU, TOL, CAP, MASK = 100.0, 1e-6, 20000, (1 << 64) - 1      # shrink per pass, stop, most passes, mask
GROUPS = [(0,)] + [(2 * k - 1, 2 * k) for k in range(1, N // 2)] + [(N - 1,)]  # bin k's slots
SCALE = sqrt(N / 2)                       # a coefficient is the tone's amplitude times this, 22.36

def splitmix(seed):                       # SplitMix64: the same random integers in both languages
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK; z = s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield z ^ (z >> 31)

def pick(seed, m):                        # m distinct sample times, by a partial shuffle
    g, idx = splitmix(seed), list(range(N))
    for i in range(m):
        r = i + next(g) % (N - i); idx[i], idx[r] = idx[r], idx[i]
    return sorted(idx[:m])
def wave(j, n):                           # basis wave j at time n, scaled to length 1 over all N samples
    if j == 0: return 1 / sqrt(N)
    if j == N - 1: return 1 / sqrt(N) if n % 2 == 0 else -1 / sqrt(N)
    ph = 2 * pi * ((j + 1) // 2) * n / N
    return sqrt(2 / N) * (cos(ph) if j % 2 == 1 else sin(ph))
def chord(n, tones): return sum(a * cos(2 * pi * f * n / N + p) for f, a, p in tones)  # mV at sample n
def dot(a, b): return sum(map(mul, a, b))
def amp(z, k): return sqrt(sum(z[j] * z[j] for j in GROUPS[k])) / (SCALE if 0 < k < N // 2 else sqrt(N))
def cost(z): return sum(sqrt(sum(z[j] * z[j] for j in g)) for g in GROUPS)   # what road 2 minimises

def solve(G, b):                          # Gaussian elimination with partial pivoting; also the smallest pivot
    n = len(b); A = [row[:] + [b[i]] for i, row in enumerate(G)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(A[r][c])); A[c], A[p] = A[p], A[c]
        for r in range(c + 1, n):
            f = A[r][c] / A[c][c]; A[r] = [x - f * y for x, y in zip(A[r], A[c])]
    x = [0.0] * n
    for r in range(n - 1, -1, -1): x[r] = (A[r][n] - dot(A[r][r + 1:n], x[r + 1:])) / A[r][r]
    return x, min(abs(A[c][c]) for c in range(n))
def shrink(w):                            # pull each bin's size toward zero by TAU, stop at zero
    z = [0.0] * N
    for g in GROUPS:
        size = sqrt(sum(w[j] * w[j] for j in g))
        if size > TAU:
            for j in g: z[j] = w[j] * (1 - TAU / size)
    return z

def sum_of_sizes(cols, y, judge=None):    # road 2: the exact fit with the smallest summed size
    rows, z, u, gap, step, passes = [list(r) for r in zip(*cols)], [0.0] * N, [0.0] * N, 1.0, 1.0, 0
    while (judge or gap > TOL or step > TOL) and passes < CAP:   # until z fits and stops moving
        v = [a - b for a, b in zip(z, u)]
        miss = [dot(row, v) - yi for row, yi in zip(rows, y)]
        x = [vj - dot(c, miss) for vj, c in zip(v, cols)]       # snap onto 'fits the samples'
        zn = shrink([a + b for a, b in zip(x, u)])              # shrink every bin
        gap, step = max(abs(a - b) for a, b in zip(x, zn)), max(abs(a - b) for a, b in zip(z, zn))
        z, u, passes = zn, [a + b - c for a, b, c in zip(u, x, zn)], passes + 1
        if judge and passes % 25 == 0:    # the sweep: stop once a proof settles it, either way
            if cost(x) < cost(judge) - 1e-6: return False         # an exact fit smaller than the chord
            if certificate(cols, judge, [dot(row, u) / TAU for row in rows]) < 1: return True
    assert passes < CAP and max(abs(dot(row, z) - yi) for row, yi in zip(rows, y)) < 1e-5, "z fits every sample"
    return z, [dot(row, u) / TAU for row in rows], passes      # the answer, its dual vector, passes

def greedy(cols, y, tones):               # road 3: take the best-matching bin, refit, repeat
    chosen, r, z = [], y[:], [0.0] * N
    for _ in range(tones):
        score = [dot(cols[2 * k - 1], r) ** 2 + dot(cols[2 * k], r) ** 2 for k in range(1, N // 2)]
        chosen.append(1 + max(range(len(score)), key=lambda i: score[i]))
        js = [j for k in chosen for j in GROUPS[k]]                          # least squares on them
        c, _ = solve([[dot(cols[a], cols[b]) for b in js] for a in js], [dot(cols[a], y) for a in js])
        r = [yi - sum(cj * cols[j][i] for cj, j in zip(c, js)) for i, yi in enumerate(y)]
    for cj, j in zip(c, js): z[j] = cj
    return z

def certificate(cols, z, v):              # road 4: a value below 1 proves z is the unique smallest summed size
    on = [k for k in range(1, N // 2) if amp(z, k) > 1e-3]
    js, unit = [j for k in on for j in GROUPS[k]], [z[j] / (amp(z, k) * SCALE) for k in on for j in GROUPS[k]]
    c, pivot = solve([[dot(cols[a], cols[b]) for b in js] for a in js], [e - dot(cols[j], v) for e, j in zip(unit, js)])
    v = [vi + sum(cj * cols[j][i] for cj, j in zip(c, js)) for i, vi in enumerate(v)]   # make the chord's slots exact
    g = [dot(col, v) for col in cols]
    assert max(abs(g[j] - e) for e, j in zip(unit, js)) < 1e-9 and pivot > 1e-6, "exact on independent chord columns"
    return max(sqrt(sum(g[j] ** 2 for j in GROUPS[k])) for k in range(len(GROUPS)) if k not in on)
def setup(times, tones, noise=0.0):       # the kept columns and samples, with optional uniform noise
    cols, g = [[wave(j, n) for n in times] for j in range(N)], splitmix(99)
    return cols, [chord(n, tones) + noise * sqrt(3) * ((next(g) >> 11) / 2 ** 52 - 1) for n in times]
def report(label, z, tones):              # the three bins, the largest false peak, the waveform error
    a = [amp(z, k) for k in range(len(GROUPS))]
    false = max((a[k], k) for k in range(len(GROUPS)) if k not in (5, 15, 80))
    err = sqrt(sum((sum(z[j] * wave(j, n) for j in range(N) if z[j]) - chord(n, tones)) ** 2 for n in range(N)) / N)
    print(f"{label}: {a[5]:7.2f} {a[15]:6.2f} {a[80]:6.2f} mV  false peak {false[0]:6.2f} mV at {false[1] * FS / N:7.1f} Hz"
          f"  bins on {sum(1 for v in a if v > 0.01):3d}  rms error {err:7.2f} mV  summed size {sum(a):6.2f} mV")
    print(f"  peak in each 220.5 Hz band up to 4410 Hz (mV): {' '.join(f'{max(a[5 * b + 1:5 * b + 6]):.1f}' for b in range(20))}")
    return a, false[0], err

truth = [0.0] * N
for f, a, p in TONES: truth[2 * f - 1], truth[2 * f] = a * cos(p) * SCALE, -a * sin(p) * SCALE
full = [chord(n, TONES) for n in range(N)]
dft = [2 / N * sqrt(sum(x * cos(2 * pi * k * n / N) for n, x in enumerate(full)) ** 2
                    + sum(x * sin(2 * pi * k * n / N) for n, x in enumerate(full)) ** 2) for k in range(N // 2)]
times = pick(SEED, M)
print(f"setup: {N} samples at {FS / 1000:.1f} kHz = {1000 * N / FS:.2f} ms, bin spacing {FS / N:.1f} Hz, keep {M} at random times")
print(f"tones: {', '.join(f'{f * FS / N:.1f} Hz {a:.0f} mV' for f, a, p in TONES)}   coefficient scale {SCALE:.2f}")
print(f"even sampling for {TONES[-1][0] * FS / N:.1f} Hz: more than {2 * TONES[-1][0] * FS / N:.0f} per second, more than {2 * TONES[-1][0]} samples in the window")
print(f"kept times (first 8 of {M}): {times[:8]}   that is {100 * M // N}%   chance they see 3 given clicks {M * (M - 1) * (M - 2) / (N * (N - 1) * (N - 2)):.1e}")
print(f"road 1 full 1000-sample DFT: {dft[5]:.4f} {dft[15]:.4f} {dft[80]:.4f} mV  largest elsewhere {max(dft[k] for k in range(N // 2) if k not in (5, 15, 80)):.1e} mV")
print(f"counting search: 3 of 500 bins {comb(500, 3)}   10 of 500 {comb(500, 10)}   2s = 12   s ln N = 6 ln 1000 = {6 * log(N):.1f}")
print(f"by hand, one sample a + 2b = 2: least energy a, b = {2 * 1 / 5:.1f}, {2 * 2 / 5:.1f} (summed size {2 * 3 / 5:.1f}); least summed size 0, {2 / 2:.1f} (summed size {2 / 2:.1f})")
cols, y = setup(times, TONES)
z1, v1, n1 = sum_of_sizes(cols, y)
a1, _, e1 = report("road 2 sum of sizes      ", z1, TONES)
print(f"  phases {', '.join(f'{atan2(-z1[2 * f], z1[2 * f - 1]):.4f}' for f, _, _ in TONES)} rad   largest amplitude error {max(abs(a1[f] - a) for f, a, _ in TONES):.1e} mV after {n1} passes")
a2, _, e2 = report("road 3 greedy matching   ", greedy(cols, y, 3), TONES)
cert = certificate(cols, truth, v1)
print(f"road 4 certificate: largest match off the chord {cert:.4f}  (below 1 proves no other fit is smaller)")
size, rss = lambda z: sum(amp(z, k) for k in range(len(GROUPS))), lambda z: sqrt(sum(v * v for v in z)) / SCALE
z0 = [dot(c, y) for c in cols]            # the fit of least energy: fill the missing samples with zeros
print(f"summed size (mV):     truth {size(truth):.2f}  road 2 {size(z1):.2f}  least-energy fit {size(z0):.2f}")
print(f"root-sum-square (mV): truth {rss(truth):.2f}  road 2 {rss(z1):.2f}  least-energy fit {rss(z0):.2f}")
a0, f0, _ = report("wrong: zero-fill x 25    ", [v * N / M for v in z0], TONES)
report("wrong: every 25th, 1764 Hz", sum_of_sizes(*setup(list(range(0, N, N // M)), TONES))[0], TONES)
_, _, e4 = report("wrong: 20 random samples ", sum_of_sizes(*setup(pick(SEED, 20), TONES))[0], TONES)
tuned = ((220.0 * N / FS, 100.0, 0.3), (659.26 * N / FS, 60.0, 1.1), (3520.0 * N / FS, 40.0, 2.0))
_, _, e5 = report("tuned 220, 659.26, 3520 Hz", sum_of_sizes(*setup(times, tuned))[0], tuned)
half = ((5.5, 100.0, 0.3), (15, 60.0, 1.1), (80, 40.0, 2.0))
_, _, e6 = report("wrong: 242.6 Hz, half-bin", sum_of_sizes(*setup(times, half))[0], half)
a7, f7, e7 = report("noise 1 mV rms on samples", sum_of_sizes(*setup(times, TONES, 1.0))[0], TONES)
sweep = {m: [sum_of_sizes(*setup(pick(s, m), TONES), judge=truth) for s in range(1, 6)] for m in (10, 20, 25, 30, 35, 40)}
print(f"proved exact, of 5 random draws: {', '.join(f'{m} samples {sum(r is True for r in rs)}' for m, rs in sweep.items())}")
assert max(abs(dft[f] - a) for f, a, _ in TONES) < 1e-9, "the full DFT finds the chord"
assert max(abs(a1[f] - a) for f, a, _ in TONES) < 1e-4 and e1 < 1e-4, "40 samples rebuild the chord by summed size"
assert max(abs(a2[f] - a) for f, a, _ in TONES) < 1e-9 and e2 < 1e-9, "the greedy road agrees"
assert cert < 1, "the certificate proves the chord is the smallest summed size"
assert rss(z0) < rss(truth) and size(z0) > size(truth), "zero-fill wins on energy, loses on summed size"
assert f0 > 10 and e4 > 1 and e6 > 1, "zero-fill, too few samples and an off-grid tone must fail"
assert all(type(r) is bool for rs in sweep.values() for r in rs) and sum(sweep[10]) == 0 and sum(sweep[40]) == 5, \
    "a proof settles every draw; 10 samples never suffice, 40 always do here"
print("ALL CHECKS PASS")
