# Rate and distortion -- the check behind the card.  Standard library only.
# A synthetic 128 x 128 grey photo is cut into 8 x 8 blocks, cosine-transformed,
# rounded with one step size and entropy-counted until it costs 0.8 bits a pixel.
# Roads: the bell-curve R(D) formula against Blahut-Arimoto; a simulated quantiser
# against the bound; pixel error against coefficient error (Parseval).
import math
M64 = 0xFFFFFFFFFFFFFFFF

class Rng:                                     # SplitMix64, written out
    def __init__(s, seed): s.s = seed
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64; z = s.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def gauss(s):                              # Box-Muller, cosine half
        a = 1.0 - s.u(); b = s.u()
        return math.sqrt(-2.0 * math.log(a)) * math.cos(2.0 * math.pi * b)

def entropy(xs):                               # bits per symbol, ideal code for xs's own table
    c, t = {}, 0.0
    for x in xs: c[x] = c.get(x, 0) + 1
    for k in sorted(c): t -= c[k] / len(xs) * math.log2(c[k] / len(xs))
    return t
def q(x, d): return math.floor(x / d + 0.5)    # uniform quantiser: index of the nearest step
def bisect(f, lo, hi, target):                 # f rises with its argument
    for _ in range(50):
        mid = (lo + hi) / 2
        if f(mid) < target: lo = mid
        else: hi = mid
    return (lo + hi) / 2
def show(label, x): print(f"{label:<44}{x:>12.6f}")
def row(label, xs, fmt): print(f"{label:<22}" + "".join(format(x, fmt) for x in xs))

# ---- one bell-curve number, sigma = 1: R(D) = 1/2 log2(1/D) ----
show("R(0.25) by the formula, bits", 0.5 * math.log2(1 / 0.25))
xs = [-5 + 0.1 * i for i in range(101)]        # Blahut-Arimoto on a gridded bell curve
p = [math.exp(-x * x / 2) for x in xs]; tot = sum(p); p = [a / tot for a in p]
var = sum(a * x * x for a, x in zip(p, xs))
A = [[math.exp(-2.0 * (x - y) ** 2) for y in xs] for x in xs]   # slope 2 aims at D = 0.25
r = [1 / 101] * 101
for _ in range(400):
    W = [[r[j] * A[i][j] for j in range(101)] for i in range(101)]
    W = [[w / t for w in wr] for wr in W for t in [sum(wr)]]
    r = [sum(p[i] * W[i][j] for i in range(101)) for j in range(101)]
D_ba = sum(p[i] * W[i][j] * (xs[i] - xs[j]) ** 2 for i in range(101) for j in range(101))
R_ba = sum(p[i] * W[i][j] * math.log2(W[i][j] / r[j]) for i in range(101) for j in range(101) if W[i][j] > 0)
show("Blahut-Arimoto: distortion", D_ba)
show("Blahut-Arimoto: rate, bits", R_ba)
show("formula at that distortion, bits", 0.5 * math.log2(var / D_ba))
assert abs(R_ba - 0.5 * math.log2(var / D_ba)) < 1e-5 and abs(D_ba - 0.25) < 0.01
show("weather: spread 4 C, error 1 C, bits a day", 0.5 * math.log2(4 ** 2 / 1 ** 2))

g = Rng(20261111); N = 40000
z = [g.gauss() for _ in range(N)]
m = sum(abs(x) for x in z) / N                 # best 1-bit quantiser: levels at +-mean|x|
D_lm = sum((abs(x) - m) ** 2 for x in z) / N
show("1 bit, one at a time: distortion, simulated", D_lm)
show("1 bit, one at a time: 1 - 2/pi", 1 - 2 / math.pi)
assert abs(D_lm - (1 - 2 / math.pi)) < 0.01
def mse(d): return sum((x - d * q(x, d)) ** 2 for x in z) / N
def H_at(D): d = bisect(mse, 0.01, 5.0, D); return entropy([q(x, d) for x in z])
Ds = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
H_sq = [H_at(D) for D in Ds]
row("chart, D", Ds, ">7.2f")
row("chart, R(D)", [0.5 * math.log2(1 / D) for D in Ds], ">7.3f")
row("chart, rounding", H_sq, ">7.3f")
assert all(h > 0.5 * math.log2(1 / D) for h, D in zip(H_sq, Ds))
show("rounding plus entropy code at D = 0.25", H_at(0.25))
gap = H_at(0.01) - 0.5 * math.log2(1 / 0.01)
show("gap above R(D) at D = 0.01, simulated", gap)
show("gap, high-rate theory 1/2 log2(pi e / 6)", 0.5 * math.log2(math.pi * math.e / 6))
assert abs(gap - 0.5 * math.log2(math.pi * math.e / 6)) < 0.03

# ---- the photo: synthetic 128 x 128, 8-bit grey: a lit ball on a shaded wall, plus grain ----
S = 128; g = Rng(7)
def base(x, y): return (100.5 + 25 * x / 127 + 45 * math.sin(x / 11) * math.cos(y / 17)
                        + (70 if (x - 80) ** 2 + (y - 52) ** 2 < 900 else 0))           # the photo before its grain
img = [[min(255, max(0, math.floor(base(x, y) + 2 * g.gauss()))) for x in range(S)] for y in range(S)]
C = [[(math.sqrt(1 / 8) if k == 0 else 0.5) * math.cos(math.pi * (2 * n + 1) * k / 16) for n in range(8)] for k in range(8)]
T = [list(c) for c in zip(*C)]
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(8)) for j in range(8)] for i in range(8)]
blocks = [[ln[bx:bx + 8] for ln in img[by:by + 8]] for by in range(0, S, 8) for bx in range(0, S, 8)]
coef = [mul(mul(C, b), T) for b in blocks]     # Y = C X C^T, orthonormal
UV = [(u, v) for u in range(8) for v in range(8)]
def rate(d):                                   # bits per pixel: one table for slot (0,0), one for the 63 others
    dc = [q(Y[0][0], d) for Y in coef]
    ac = [q(Y[u][v], d) for Y in coef for u, v in UV if u + v > 0]
    return (len(dc) * entropy(dc) + len(ac) * entropy(ac)) / (S * S)
step = math.ceil(bisect(lambda d: -rate(d), 1, 200, -0.8) * 1e6) / 1e6   # rounded up: no weight sits on a half step
show("step size for 0.8 bits a pixel", step)
show("bits per pixel", rate(step))
show("compression ratio, 8 bits / that", 8 / rate(step))
assert abs(rate(step) - 0.8) < 0.005
Yq = [[[step * q(Y[u][v], step) for v in range(8)] for u in range(8)] for Y in coef]
err_c = sum((Y[u][v] - Z[u][v]) ** 2 for Y, Z in zip(coef, Yq) for u, v in UV) / (S * S)
rec = [mul(mul(T, Z), C) for Z in Yq]          # X = C^T Y C
err_p = sum((b[i][j] - x[i][j]) ** 2 for b, x in zip(blocks, rec) for i, j in UV) / (S * S)
show("mean squared error, coefficients", err_c)
show("mean squared error, pixels", err_p)
show("PSNR, dB", 10 * math.log10(255 ** 2 / err_p))
assert abs(err_c - err_p) < 1e-9 * err_p
drop = [Y[u][v] ** 2 for Y, Z in zip(coef, Yq) for u, v in UV if u + v > 0 and Z[u][v] == 0]
kept = [(Y[u][v] - Z[u][v]) ** 2 for Y, Z in zip(coef, Yq) for u, v in UV if u + v > 0 and Z[u][v] != 0]
energy = sum(Y[u][v] ** 2 for Y in coef for u, v in UV if u + v > 0)
show("share of the 63 x 256 detail numbers dropped", len(drop) / (63 * len(coef)))
show("share of the detail energy they carried", sum(drop) / energy)
show("mean squared error of a dropped number", sum(drop) / len(drop))
show("mean squared error of a kept number", sum(kept) / len(kept))
show("step^2 / 12", step * step / 12)
Y0 = coef[6 * 16 + 6]; det = [(Y0[u][v], u, v) for u, v in UV if u + v > 0]     # a tile on the ball's left edge
pick = [(Y0[0][0], 0, 0), max(det, key=lambda t: abs(t[0])), max((t for t in det if q(t[0], step) == 0), key=lambda t: abs(t[0]))]
print("tile x 48-55, y 48-55: " + "; ".join(f"({u},{v}) {w:.2f} / step = {w / step:.2f} -> {q(w, step)}" for w, u, v in pick)
      + f"; details rounded to 0: {sum(q(w, step) == 0 for w, u, v in det)} of 63")
mean = [[sum(Y[u][v] for Y in coef) / len(coef) for v in range(8)] for u in range(8)]
vs = [sum((Y[u][v] - mean[u][v]) ** 2 for Y in coef) / len(coef) for u, v in UV]
th = bisect(lambda t: sum(min(t, s) for s in vs) / 64, 0, max(vs), err_p)
show("bell-curve model of the 64 slots, bits/pixel", sum(max(0, 0.5 * math.log2(s / th)) for s in vs) / 64)
db = lambda vals: [10 * math.log10(sum(x for x, (u, v) in zip(vals, UV) if u + v == b) / (min(b, 14 - b) + 1)) for b in range(15)]
row("chart, band u+v", range(15), ">6")
row("chart, variance dB", db(vs), ">6.1f")
row("chart, error dB", db([sum((Y[u][v] - Z[u][v]) ** 2 for Y, Z in zip(coef, Yq)) / len(coef) for u, v in UV]), ">6.1f")
show("chart, step^2/12 in dB", 10 * math.log10(step * step / 12))

# ---- what breaks ----
pix = [v for ln in img for v in ln]
pstep = bisect(lambda d: -entropy([q(v, d) for v in pix]), 1, 200, -0.8)
perr = sum((v - pstep * q(v, pstep)) ** 2 for v in pix) / len(pix)
show("wrong: no transform, error at 0.8 bits", perr)
show("wrong: no transform, PSNR dB", 10 * math.log10(255 ** 2 / perr))
assert perr > 10 * err_p
grain = entropy([v - math.floor(base(x, y)) for y, ln in enumerate(img) for x, v in enumerate(ln)])
show("lossless: grain alone, measured, bits/pixel", grain)
show("lossless: 1/2 log2(2 pi e 2^2), bits/pixel", 0.5 * math.log2(2 * math.pi * math.e * 4))
assert abs(grain - 0.5 * math.log2(2 * math.pi * math.e * 4)) < 0.05
lv = lambda xs: math.ceil(math.log2(len(set(xs))))
fixed = (lv([q(Y[0][0], step) for Y in coef]) + 63 * lv([q(Y[u][v], step) for Y in coef for u, v in UV if u + v > 0])) / 64
show("wrong: fixed-length indices, bits/pixel", fixed)
show("wrong: formula at D = 2 sigma^2, bits", 0.5 * math.log2(1 / 2))
print("ALL CHECKS PASS")
