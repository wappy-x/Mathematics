# Wavelets: Haar transform, the multiresolution ladder, and denoising one row of a scanned page.
# Standard library only.  Noise comes from SplitMix64 (seed 2026) and Box-Muller, written out.
from math import sqrt, log, cos, pi, exp, log10

M64 = (1 << 64) - 1
class Rng:
    def __init__(self, seed): self.x = seed
    def u64(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return ((self.u64() >> 11) + 0.5) / 2.0 ** 53
    def gauss(self): u1, u2 = self.unif(), self.unif(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
R2 = sqrt(2.0)
def forward(x, levels, norm=R2):           # Haar pyramid: pair sums and pair differences, divided by norm
    s, ds = list(x), []
    for _ in range(levels):
        ds.append([(s[2 * k] - s[2 * k + 1]) / norm for k in range(len(s) // 2)])
        s = [(s[2 * k] + s[2 * k + 1]) / norm for k in range(len(s) // 2)]
    return s, ds                            # coarse picture, then details from finest to coarsest
def inverse(s, ds, norm=R2):
    s = list(s)
    for d in reversed(ds):
        s = [v for a, b in zip(s, d) for v in ((a + b) * norm / 2, (a - b) * norm / 2)]
    return s
def rmse(a, b): return sqrt(sum((x - y) ** 2 for x, y in zip(a, b)) / len(a))
def median(v): v = sorted(v); return (v[len(v) // 2 - 1] + v[len(v) // 2]) / 2   # even length only
def hard(v, t): return v if abs(v) > t else 0.0
def soft(v, t): return (1.0 if v > 0 else -1.0) * max(abs(v) - t, 0.0)
def shrink(s, ds, t, rule): return inverse(s, [[rule(v, t) for v in d] for d in ds])
def tail(t, n=2000):                        # chance a standard bell-curve draw lands above t (Simpson)
    h, f = t / n, lambda z: exp(-z * z / 2) / sqrt(2 * pi)
    area = f(0) + f(t) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    return 0.5 - area * h / 3
def fmt(v): return " ".join(f"{x:.1f}" for x in v)
def flat(x):                                # every coefficient: details finest first, then the coarse picture
    s, ds = forward(x, J); return [c for d in ds for c in d] + s
def scan(seed): g = Rng(seed); return [min(255, max(0, round(c + SIGMA * g.gauss()))) for c in clean]
def denoise(row):                           # estimate sigma from the finest details, threshold at T, rebuild
    s, ds = forward(row, J); sh = median([abs(c) for c in ds[0]]) / 0.6745
    return shrink(s, ds, sh * ln, hard), sh

# ---- the page: one row of 512 pixels at 300 dpi through the word "minimum", plus a faint pencil line ----
N, J, PAPER, INK, PENCIL, SIGMA = 512, 3, 215, 50, 175, 16
ln, n_det = sqrt(2 * log(N)), N - N // 2 ** J   # the universal multiplier; how many details
stems, p = [], 30
for count in (3, 1, 2, 1, 3, 2, 3):        # stems of m, i, n, i, m, u, m; each stem 4 pixels wide
    for _ in range(count): stems.append(p); p += 11
    p += 2
clean = [PAPER] * N
for a in stems:
    for i in range(a, a + 4): clean[i] = INK
clean[400] = clean[401] = clean[402] = PENCIL
noisy = scan(2026)
print(f"row: {N} pixels at 300 dpi = {N * 25.4 / 300:.2f} mm; paper {PAPER}, ink {INK}, noise sigma {SIGMA} grey levels")

# ---- by hand: the 8 pixels 40 to 47, three levels ----
print("hand block, pixels 40-47, clean:", fmt(clean[40:48]), " noisy:", fmt(noisy[40:48]))
s = noisy[40:48]
for lev in (1, 2, 3):
    s, d = forward(s, 1)
    print(f"  level {lev}: coarse {fmt(s)}  detail {fmt(d[0])}")
# ---- road 1: fast pyramid against dot products with the explicit Haar basis vectors ----
basis = []
for j in range(1, J + 2):                   # wavelets at levels 1 to J, then the level-J boxes
    L = 2 ** min(j, J)
    for k in range(N // L):
        v = [0.0] * N
        for i in range(L): v[k * L + i] = (1 if i < L // 2 or j > J else -1) / sqrt(L)
        basis.append(v)
cs, cds = forward(noisy, J)
fast = flat(noisy)
slow = [sum(a * b for a, b in zip(v, noisy)) for v in basis]
gap = max(abs(a - b) for a, b in zip(fast, slow))
nz = [[i for i in range(N) if v[i] != 0] for v in basis]
ortho = max(abs(sum(basis[a][i] * basis[b][i] for i in nz[a]) - (a == b)) for a in range(N) for b in range(N))
back = max(abs(a - b) for a, b in zip(inverse(cs, cds), noisy))
e_pix, e_coef = sum(x * x for x in noisy), sum(c * c for c in fast)
yes = lambda ok: "yes" if ok else "NO"
print(f"fast transform equals basis dot products to 1e-9: {yes(gap < 1e-9)}; basis orthonormal to 1e-12: {yes(ortho < 1e-12)}")
print(f"rebuilt row equals scanned row to 1e-9: {yes(back < 1e-9)}; energy {e_pix:.1f} in pixels, {e_coef:.1f} in coefficients")
assert gap < 1e-9 and ortho < 1e-12 and back < 1e-9 and abs(e_pix - e_coef) < 1e-6 * e_pix
# ---- denoise: estimate sigma from the finest details, threshold, rebuild ----
den, sig_hat = denoise(noisy)
T = sig_hat * ln
print(f"sigma estimate {sig_hat:.2f} (true {SIGMA}); multiplier sqrt(2 ln {N}) = {ln:.4f}; threshold T = {T:.2f}")
print("hand block, denoised:", fmt(den[40:48]))
# ---- the ladder, and road 2: pure noise keeps its size at every level (2000 noise-only rows) ----
rows_mc, sq, sq_raw, over, mc = 2000, [0.0] * J, [0.0] * J, 0, Rng(7)
for _ in range(rows_mc):
    z = [mc.gauss() for _ in range(N)]
    zd, zr = forward(z, J)[1], forward(z, J, 2.0)[1]
    for j in range(J):
        sq[j] += sum(c * c for c in zd[j]); sq_raw[j] += sum(c * c for c in zr[j])
        over += sum(1 for c in zd[j] if abs(c) > ln)
print("level  dpi  pixel(mm)  coefficients  details kept  noise std  noise std, no root 2")
for j in range(J):
    cnt = N // 2 ** (j + 1)
    kept = sum(1 for c in cds[j] if abs(c) > T)
    sd, sdr = sqrt(sq[j] / (rows_mc * cnt)), sqrt(sq_raw[j] / (rows_mc * cnt))
    print(f"{j + 1:5d} {300 / 2 ** (j + 1):5.1f} {25.4 * 2 ** (j + 1) / 300:9.3f} {cnt:12d} {kept:12d} {sd:10.3f} {sdr:10.3f}")
    assert abs(sd - 1) < 0.02 and abs(sdr - 0.5 ** ((j + 1) / 2)) < 0.02
expect = rows_mc * n_det * 2 * tail(ln)
print(f"pure-noise details above the multiplier, {rows_mc} rows: {over} counted, {expect:.1f} expected")
assert abs(over - expect) < 4 * sqrt(expect)
# ---- the result, measured two ways: in pixels and in coefficients ----
e_den = rmse(den, clean)
coef_err = rmse(flat(den), flat(clean))
print(f"rms error, grey levels: noisy {rmse(noisy, clean):.2f}, denoised {e_den:.2f} (from coefficients {coef_err:.2f})")
assert abs(coef_err - e_den) < 1e-9 and e_den < 0.7 * rmse(noisy, clean)
bg = [i for i in range(N) if all(clean[k] == PAPER for k in range(max(0, i - 4), min(N, i + 5)))]
print(f"bare paper ({len(bg)} pixels): noisy {rmse([noisy[i] for i in bg], [PAPER] * len(bg)):.2f}, denoised {rmse([den[i] for i in bg], [PAPER] * len(bg)):.2f}")
psnr = lambda e: 20 * log10(255 / e)
print(f"peak signal to noise: noisy {psnr(rmse(noisy, clean)):.2f} dB, denoised {psnr(e_den):.2f} dB")
runs = [(rmse(r, clean), rmse(denoise(r)[0], clean)) for r in map(scan, range(1, 21))]
mean_n, mean_d = sum(a for a, _ in runs) / 20, sum(b for _, b in runs) / 20
print(f"20 other noise draws: noisy {mean_n:.2f}, denoised {mean_d:.2f} on average, {min(b for _, b in runs):.2f} to {max(b for _, b in runs):.2f}")
assert all(b < a for a, b in runs)
# ---- what breaks ----
sft = shrink(cs, cds, T, soft)
ink_px = [i for i in range(N) if clean[i] == INK]
rs, rr = forward(noisy, J, 2.0)
raw = inverse(rs, [[hard(v, T) for v in d] for d in rr], 2.0)
low = shrink(cs, cds, sig_hat, hard)
box = [sum(noisy[max(0, i - 1):i + 2]) / len(noisy[max(0, i - 1):i + 2]) for i in range(N)]
print(f"soft instead of hard: rms {rmse(sft, clean):.2f}; mean ink level {sum(sft[i] for i in ink_px) / len(ink_px):.1f} (true {INK})")
print(f"average and half-difference, same T: rms {rmse(raw, clean):.2f}")
print(f"threshold T = sigma only: rms {rmse(low, clean):.2f}")
print(f"3-pixel blur instead: rms {rmse(box, clean):.2f}")
assert min(rmse(sft, clean), rmse(raw, clean), rmse(low, clean), rmse(box, clean)) > e_den
pen = [PENCIL if 400 <= i < 403 else PAPER for i in range(N)]   # the pencil line alone
pen_max = max(abs(c) for c in flat(pen)[:n_det])
print(f"pencil line (true {PENCIL}): largest detail {pen_max:.1f}; noisy {fmt(noisy[400:403])}, denoised {fmt(den[400:403])}")
assert pen_max < T and min(den[400:403]) > 195
# ---- chart points: pixels 24 to 71 ----
for name, row in (("clean", clean), ("noisy", noisy), ("denoised", den)):
    print(f"chart, {name}: " + ", ".join(f"{v:.0f}" for v in row[24:72]))
print("ALL CHECKS PASS")
