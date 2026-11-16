# Compression by wavelets -- the check behind the card.  Standard library only.
# A synthetic 128 x 128 grey photo (the rule and seed of the Rate and distortion card) is
# rewritten three ways: Daubechies D4 wavelets, Haar wavelets, and 8 x 8 cosine blocks.
# Each keeps its N largest coefficients.  Roads: the error as the sum of the dropped squares
# (Parseval) against the error measured on the rebuilt pixels; the 1/k decay bound against
# the true error; pure grain against the bell-curve formula for its kept share.
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

S, LEV = 128, 5; g = Rng(7)
def inball(x, y): return (x - 80) ** 2 + (y - 52) ** 2 < 900
def base(x, y, ball=70): return (100.5 + 25 * x / 127 + 45 * math.sin(x / 11) * math.cos(y / 17) + (ball if inball(x, y) else 0))
photo = [[min(255, max(0, math.floor(base(x, y) + 2 * g.gauss()))) for x in range(S)] for y in range(S)]
clean = [[min(255, max(0, math.floor(base(x, y)))) for x in range(S)] for y in range(S)]
r3, r2 = math.sqrt(3), math.sqrt(2)
D4 = [(1 + r3) / (4 * r2), (3 + r3) / (4 * r2), (3 - r3) / (4 * r2), (1 - r3) / (4 * r2)]
HAAR = [1 / r2, 1 / r2]
def hi(h): return [(-1) ** k * h[len(h) - 1 - k] for k in range(len(h))]   # g from h: reverse, alternate sign
def split(v, h):                               # one Mallat step on a periodic row: averages, then details
    n, gg = len(v), hi(h)
    return ([sum(h[k] * v[(2 * i + k) % n] for k in range(len(h))) for i in range(n // 2)] +
            [sum(gg[k] * v[(2 * i + k) % n] for k in range(len(h))) for i in range(n // 2)])
def merge(c, h):                               # its inverse: the transpose of split
    n, gg = len(c), hi(h); v = [0.0] * n
    for i in range(n // 2):
        for k in range(len(h)): v[(2 * i + k) % n] += h[k] * c[i] + gg[k] * c[n // 2 + i]
    return v
def rows_cols(X, n, f):                        # apply f to rows, then columns, of the top-left n x n corner
    for i in range(n): X[i][:n] = f(X[i][:n])
    for j in range(n):
        col = f([X[i][j] for i in range(n)])
        for i in range(n): X[i][j] = col[i]
def wav(X, h):
    X = [list(map(float, r)) for r in X]
    for L in range(LEV): rows_cols(X, S >> L, lambda v: split(v, h))
    return X
def iwav(X, h):
    X = [r[:] for r in X]
    for L in reversed(range(LEV)): rows_cols(X, S >> L, lambda v: merge(v, h))
    return X
C8 = [[(math.sqrt(1 / 8) if k == 0 else 0.5) * math.cos(math.pi * (2 * n + 1) * k / 16) for n in range(8)] for k in range(8)]
def dct(X, back=False):                        # 8 x 8 orthonormal cosine blocks, forward or back
    Y = [[0.0] * S for _ in range(S)]
    for by in range(0, S, 8):
        for bx in range(0, S, 8):
            for u in range(8):
                for v in range(8):
                    Y[by + u][bx + v] = sum((C8[i][u] * C8[j][v] if back else C8[u][i] * C8[v][j]) * X[by + i][bx + j]
                                            for i in range(8) for j in range(8))
    return Y
def keep(Y, N):                                # the N largest in size; the rest set to zero
    t = sorted((abs(c) for r in Y for c in r), reverse=True)[N - 1]
    return [[c if abs(c) >= t else 0.0 for c in r] for r in Y]
def tail(Y, N): return sum(sorted((c * c for r in Y for c in r), reverse=True)[N:]) / (S * S)
def mse(A, B): return sum((a - b) ** 2 for ra, rb in zip(A, B) for a, b in zip(ra, rb)) / (S * S)
def psnr(e): return 10 * math.log10(255 ** 2 / e)
def show(label, x, f=".3f"): print(f"{label:<46}{format(x, f):>12}")

N = S * S // 20
show("pixels in the photo", S * S, "d"); show("numbers kept, one twentieth", N, "d")
T = {"D4": wav(photo, D4), "Haar": wav(photo, HAAR), "cosine 8x8": dct(photo)}
assert mse(iwav(T["D4"], D4), photo) < 1e-18 and mse(dct(T["cosine 8x8"], True), photo) < 1e-18   # nothing lost
for name, Y in T.items():
    e, cut = tail(Y, N), sorted((abs(c) for r in Y for c in r), reverse=True)[N - 1]
    show(f"{name}: error, sum of dropped squares", e); show(f"{name}: PSNR, dB", psnr(e), ".2f"); show(f"{name}: size of the {N}th largest", cut, ".2f")
    if name != "Haar":
        R = iwav(keep(Y, N), D4) if name == "D4" else dct(keep(Y, N), True)
        show(f"{name}: error, measured on rebuilt pixels", mse(R, photo)); assert abs(mse(R, photo) - e) < 1e-9 * e
show("D4 error / cosine error", tail(T["D4"], N) / tail(T["cosine 8x8"], N), ".2f")
assert tail(T["D4"], N) < 0.6 * tail(T["cosine 8x8"], N)
Ns = [N // 8, N // 4, N // 2, N, 2 * N, 4 * N]
print("chart, N kept      " + "".join(f"{n:>7}" for n in Ns))
for name, Y in T.items(): print(f"chart, log10 error {name:<11}" + "".join(f"{math.log10(tail(Y, n)):>7.2f}" for n in Ns))

Y = T["D4"]; K = keep(Y, N)                    # where the kept D4 numbers sit
def lev(i, j): return next((L for L in range(1, LEV + 1) if max(i, j) >= S >> L), LEV + 1)
cnt = [sum(K[i][j] != 0 and lev(i, j) == L for i in range(S) for j in range(S)) for L in range(LEV + 1, 0, -1)]
for L, c in zip(range(LEV + 1, 0, -1), cnt):
    print(f"bars, D4 kept {'coarse 4x4' if L > LEV else f'level {L}':<11}{c:>4} of {3 * (S >> L) ** 2 if L <= LEV else 16:>5}  " + "#" * (c // 8))
assert sum(cnt) == N
Q = keep(T["cosine 8x8"], N); edge = lambda by, bx: len({inball(bx + j, by + i) for i in range(8) for j in range(8)}) == 2
eb = [(by, bx) for by in range(0, S, 8) for bx in range(0, S, 8) if edge(by, bx)]
show("cosine: blocks cut by the ball's edge", len(eb), "d")
show("cosine: averages kept, of 256", sum(Q[by][bx] != 0 for by in range(0, S, 8) for bx in range(0, S, 8)), "d")
ed = sum(Q[by + u][bx + v] != 0 for by, bx in eb for u in range(8) for v in range(8) if u + v)
show("cosine: details kept in edge blocks", ed, "d"); show(f"cosine: details kept in the other {256 - len(eb)} blocks", N - 256 - ed, "d")

# ---- why: vanishing moments, and the 1/k decay with its error bound ----
ramp = [25 * x / 127 for x in range(S)]
show("ramp of 25 levels: level-1 Haar detail, size", abs(split(ramp, HAAR)[S // 2]), ".6f")
show("ramp of 25 levels: level-1 D4 detail, size", abs(split(ramp, D4)[S // 2]), ".6f")
assert abs(split(ramp, D4)[S // 2]) < 1e-12 < abs(split(ramp, HAAR)[S // 2])
show("shading: steepest slope, grey levels a pixel", 45 / 11, ".3f")
W = [[min(255, max(0, math.floor(base(x, y, 0)))) for x in range(S)] for y in range(S)]; WH, WD = wav(W, HAAR), wav(W, D4)   # the wall alone
show("wall alone, no ball or grain: Haar error", tail(WH, N)); show("wall alone, no ball or grain: D4 error", tail(WD, N)); assert tail(WD, N) < 0.1 * tail(WH, N)
Z = wav(clean, D4); a = sorted((abs(c) for r in Z for c in r), reverse=True)
B = [[math.floor(100.5 + (70 if inball(x, y) else 0)) for x in range(S)] for y in range(S)]   # the ball alone, on a flat wall
for nm, X in (("clean", Z), ("wall alone", WD), ("ball alone", wav(B, D4))):
    b = sorted((abs(c) for r in X for c in r), reverse=True); print(f"k x size of k-th largest, {nm:<11}" + "".join(f"{k * b[k - 1]:>8.0f}" for k in (64, 128, 256, 512, 1024, 2048)))
show("edge length of the ball, 2 pi 30, pixels", 2 * math.pi * 30, ".1f")
show("jump x edge length, 70 x 2 pi 30", 70 * 2 * math.pi * 30, ".0f")
Cn = max(k * a[k - 1] for k in range(N + 1, S * S + 1))
show("clean: largest k x size beyond N, C", Cn, ".0f")
bound = Cn * Cn / (N * S * S)                  # the tail of C^2 / k^2 beyond N is below C^2 / N
show("clean: D4 error at N", tail(Z, N)); show("clean: bound C^2 / (N x pixels)", bound)
show("clean: bound / true error", bound / tail(Z, N), ".2f")
assert tail(Z, N) <= bound
show("clean: cosine error at N", tail(dct(clean), N))

# ---- what breaks ----
show("wrong: Haar, one vanishing moment", tail(T["Haar"], N))
Hy = T["Haar"]; raw = [[c / 2 ** min(lev(i, j), LEV) for j, c in enumerate(r)] for i, r in enumerate(Hy)]   # averages, half-differences
Kr = keep(raw, N); show("wrong: Haar picked by unscaled size", sum(Hy[i][j] ** 2 for i in range(S) for j in range(S) if Kr[i][j] == 0) / (S * S))
show("wrong: D4 32x32 corner by place, 1024 numbers", sum(Y[i][j] ** 2 for i in range(S) for j in range(S) if max(i, j) >= 32) / (S * S))
gr = Rng(11); G = [[2 * gr.gauss() for x in range(S)] for y in range(S)]; GY = wav(G, D4)
sq = sorted((c * c for r in GY for c in r), reverse=True); share = sum(sq[:N]) / sum(sq)
def erf(x): return 2 / math.sqrt(math.pi) * sum((-1) ** n * x ** (2 * n + 1) / (math.factorial(n) * (2 * n + 1)) for n in range(60))
lo, hi_ = 0.0, 5.0
for _ in range(60):
    mid = (lo + hi_) / 2
    if 1 - erf(mid / r2) > 0.05: lo = mid
    else: hi_ = mid
z = (lo + hi_) / 2
show("bell curve: z with 5% of values beyond +-z", z, ".4f")
show("wrong: pure grain, energy kept by top 1/20", share, ".4f")
show("bell curve: 0.05 + 2 z phi(z), z for 5% tails", 0.05 + 2 * z * math.exp(-z * z / 2) / math.sqrt(2 * math.pi), ".4f")
assert abs(share - (0.05 + 2 * z * math.exp(-z * z / 2) / math.sqrt(2 * math.pi))) < 0.01
show("wrong: cosine with N/8 numbers, error", tail(T["cosine 8x8"], N // 8), ".1f")
show("map of kept places, bits per pixel, ideal code", -(0.05 * math.log2(0.05) + 0.95 * math.log2(0.95)), ".3f")
print("ALL CHECKS PASS")
