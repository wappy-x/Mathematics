# Blurring and unblurring -- the check behind the card.  Standard library only.
# One 64-pixel row of a shaken photo: sky 200, lamp post 40, power wire 60.  The
# shake spreads each point into a bell of standard deviation 2 pixels.  The photo
# is stored as whole grey levels.  Road 1 divides frequency by frequency, with
# and without damping; road 2 solves the same equations pixel by pixel.
import math
N, SIG = 64, 2.0
f = [200.0] * N                                  # the true row, illustrative
for k in range(28, 36): f[k] = 40.0              # lamp post, 8 pixels wide
for k in (44, 45): f[k] = 60.0                   # power wire, 2 pixels wide
def tot(xs):                                     # plain left-to-right sum, as in Rust
    s = 0.0
    for v in xs: s += v
    return s
w = [math.exp(-min(n, N - n) ** 2 / (2 * SIG * SIG)) for n in range(N)]
h = [v / tot(w) for v in w]                      # bell-shaped kernel, area 1
C = [math.cos(2 * math.pi * m / N) for m in range(N)]
S = [math.sin(2 * math.pi * m / N) for m in range(N)]
def dft(x):                                      # written out: X[k] = sum x[n] e^(-2 pi i k n / N)
    return [complex(tot(x[n].real * C[k * n % N] + x[n].imag * S[k * n % N] for n in range(N)),
                    tot(x[n].imag * C[k * n % N] - x[n].real * S[k * n % N] for n in range(N))) for k in range(N)]
def idft(X): return [v.real / N for v in dft([z.conjugate() for z in X])]
def conv(a, b): return [tot(a[m] * b[(k - m) % N] for m in range(N)) for k in range(N)]
def rms(a): return math.sqrt(tot((a[i] - f[i]) ** 2 for i in range(N)) / N)
def under(x, b): return f"under {b}" if x < float(b) else sci(x)
def fx(x): return f"{x + 0.0:.2f}" if abs(x) >= 0.005 else "0.00"
def sci(x):
    e = math.floor(math.log10(abs(x))); m = f"{x / 10.0 ** e:.3f}"
    return m + f"e{e}" if abs(float(m)) < 10 else f"{x / 10.0 ** (e + 1):.3f}e{e + 1}"
blur = conv(f, h)                                # the lens and the shake
y = [float(round(v)) for v in blur]              # the photo: whole grey levels
H, Y = dft([complex(v) for v in h]), dft([complex(v) for v in y])
def damped(Yk, Hk, lam):                         # f-tilde = conj(h-hat) y-hat / (|h-hat|^2 + lam)
    d = [Hk[k].real * Hk[k].real + Hk[k].imag * Hk[k].imag + lam for k in range(N)]
    return idft([complex((Hk[k].real * Yk[k].real + Hk[k].imag * Yk[k].imag) / d[k],
                         (Hk[k].real * Yk[k].imag - Hk[k].imag * Yk[k].real) / d[k]) for k in range(N)])
print(f"kernel: area {tot(h):.6f}, sd {SIG} px, full width at half maximum {2 * math.sqrt(2 * math.log(2)):.3f} sd = {2 * math.sqrt(2 * math.log(2)) * SIG:.2f} px")
ks = list(range(0, 33, 4))
print("chart, xi = k/64 at k = 0, 4, ..., 32:", ", ".join(f"{k / N:.4f}" for k in ks))
print("h-hat by the DFT:", ", ".join(sci(H[k].real) for k in ks))
gauss = lambda xi: math.exp(-2.0 * math.pi * math.pi * SIG * SIG * xi * xi)
print("h-hat closed form exp(-2 pi^2 sd^2 xi^2):", ", ".join(sci(gauss(k / N)) for k in ks))
gq, gn = abs(H[16].real - gauss(0.25)), abs(H[32].real - gauss(0.5) - gauss(-0.5))
print(f"gap at xi = 1/4: {under(gq, '1e-15')}; at xi = 1/2 the DFT is {sci(H[32].real)}, twice the closed form:"
      f" the alias at -1/2 adds {sci(gauss(-0.5))}, gap {under(gn, '1e-15')}")
noise = [y[i] - blur[i] for i in range(N)]
print(f"photo: rounding error, largest {max(abs(v) for v in noise):.3f}, rms {math.sqrt(tot(v * v for v in noise) / N):.3f} grey levels")
print("chart, pixels 20 to 52, true:", ", ".join(f"{v:.0f}" for v in f[20:53]))
print("chart, the photo:", ", ".join(f"{v:.0f}" for v in y[20:53]))
B = dft([complex(v) for v in blur])
exact = damped(B, H, 0.0)
naive = damped(Y, H, 0.0)
print(f"plain division, unrounded blur: rms error {under(rms(exact), '0.0001')} grey levels")
print(f"plain division, the photo: rms error {rms(naive):.0f}, pixels from {min(naive):.0f} to {max(naive):.0f}")
E = dft([complex(v) for v in noise])
sq = lambda z: z.real * z.real + z.imag * z.imag
pars = math.sqrt(tot(sq(E[k]) / sq(H[k]) for k in range(N)) / N / N)
top = max(range(N // 2 + 1), key=lambda k: sq(E[k]) / sq(H[k]))
print(f"Parseval: rms of noise / h-hat over all 64 frequencies {pars:.0f}; largest term k = {top}, where noise {math.sqrt(sq(E[top])) / N:.4f} / h-hat {sci(H[top].real)}")
print(f"{'damping lam':>12}{'rms error':>11}{'darkest':>9}{'brightest':>10}{'mean':>8}")
print(f"{'no repair':>12}{rms(y):>11.2f}{min(y):>9.1f}{max(y):>10.1f}{tot(y) / N:>8.2f}")
sweep = {}
for e in range(1, 11):
    est = damped(Y, H, 10.0 ** -e); sweep[e] = rms(est)
    print(f"{'1e-' + str(e):>12}{sweep[e]:>11.2f}{min(est):>9.1f}{max(est):>10.1f}{tot(est) / N:>8.2f}")
best = min(sweep, key=sweep.get)
sharp, over = damped(Y, H, 1e-4), damped(Y, H, 1e-8)
print(f"best of the ten: lam = 1e-{best}; wire pixel 44 at {sharp[44]:.1f} (photo {y[44]:.0f}, true 60)")
print("chart, sharpened at lam = 1e-4:", ", ".join(f"{v:.0f}" for v in sharp[20:53]))
print("chart, log10 gain, plain division:", ", ".join(fx(-math.log10(H[k].real)) for k in ks))
gd = lambda k, lam: H[k].real / (H[k].real ** 2 + lam)
print("chart, log10 gain, lam = 1e-4:", ", ".join(fx(math.log10(gd(k, 1e-4))) for k in ks))
print(f"gain at xi = 1/4: plain {1 / H[16].real:.1f}, damped {gd(16, 1e-4):.2f}; at xi = 1/2: plain {sci(1 / H[32].real)}, damped {sci(gd(32, 1e-4))}")
for lam in (1e-4, 1e-8):
    print(f"lam = {sci(lam)}: largest gain over all 64 frequencies {max(gd(k, lam) for k in range(N)):.2f}, bound 1/(2 sqrt(lam)) {1 / (2 * math.sqrt(lam)):.2f}")
def solve(A, b):                                  # Gaussian elimination, partial pivoting
    A = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(N):
        p = max(range(c, N), key=lambda r: abs(A[r][c])); A[c], A[p] = A[p], A[c]
        for r in range(c + 1, N):
            q = A[r][c] / A[c][c]
            A[r] = [A[r][j] - q * A[c][j] for j in range(N + 1)]
    x = [0.0] * N
    for r in range(N - 1, -1, -1):
        x[r] = (A[r][N] - tot(A[r][j] * x[j] for j in range(r + 1, N))) / A[r][r]
    return x
G = [[h[(i - j) % N] for j in range(N)] for i in range(N)]       # the blur as a matrix
GG = [[tot(G[k][i] * G[k][j] for k in range(N)) for j in range(N)] for i in range(N)]
Gy = [tot(G[k][i] * y[k] for k in range(N)) for i in range(N)]
xs = solve([[GG[i][j] + (1e-4 if i == j else 0.0) for j in range(N)] for i in range(N)], Gy)
gap = max(abs(xs[i] - sharp[i]) for i in range(N))
print(f"road 2, (G^T G + lam I) x = G^T y by elimination at lam = 1e-4: largest gap to road 1 {under(gap, '1e-6')}")
res = max(abs(v) for v in [conv(naive, h)[i] - y[i] for i in range(N)])
print(f"plain-division row blurred again: largest gap to the photo {under(res, '1e-6')} grey levels")
h25 = [math.exp(-min(n, N - n) ** 2 / (2 * 2.5 ** 2)) for n in range(N)]
wrong = damped(Y, dft([complex(v / tot(h25)) for v in h25]), 1e-4)
print(f"mistake, shake guessed as sd 2.5 px: rms {rms(wrong):.2f}, pixels from {min(wrong):.0f} to {max(wrong):.0f}")
print(f"heat: sd 2 px is heat flow for kappa t = sd^2 / 2 = {SIG ** 2 / 2:.0f} px^2")
assert abs(H[16].real - gauss(0.25)) < 1e-12 and abs(H[32].real - 2 * gauss(0.5)) < 1e-15
assert rms(exact) < 1e-3 and rms(naive) > 1e6 and abs(pars - rms(naive)) < 1e-6 * pars
assert best == 4 and sweep[4] < rms(y) < sweep[1] and sweep[8] > 5 * sweep[4]
assert all(gd(k, lam) <= 1 / (2 * math.sqrt(lam)) for lam in (1e-4, 1e-8) for k in range(N))
assert gap < 1e-6 and res < 1e-3 and rms(wrong) > sweep[4]
print("ALL CHECKS PASS")
