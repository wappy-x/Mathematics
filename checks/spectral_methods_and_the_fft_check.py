# Spectral methods on a heated steel ring: slope by FFT, heat solved in Fourier space, and what smoothness buys.
import math
L, ALPHA, T = 1.0, 1.2e-5, 600.0  # ring 1 m round (m); steel diffusivity (m^2/s, illustrative); ten minutes (s)
MULS = [0]

def mul(a, b):
    MULS[0] += 1
    return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])

def fft(a):  # radix-2 fast Fourier transform, written out; len(a) is a power of two
    n = len(a)
    if n == 1: return [a[0]]
    ev, od = fft(a[0::2]), fft(a[1::2])
    out = [None] * n
    for k in range(n // 2):
        ang = -2.0 * math.pi * k / n
        w = mul((math.cos(ang), math.sin(ang)), od[k])
        out[k] = (ev[k][0] + w[0], ev[k][1] + w[1])
        out[k + n // 2] = (ev[k][0] - w[0], ev[k][1] - w[1])
    return out

def ifft(a):  # inverse transform by conjugating, then dividing by n
    n = len(a)
    b = fft([(z[0], -z[1]) for z in a])
    return [(z[0] / n, -z[1] / n) for z in b]

def dft(a):  # the O(N^2) definition, a second road to the same coefficients
    n, out = len(a), []
    for k in range(n):
        re, im = 0.0, 0.0
        for j in range(n):
            ang = -2.0 * math.pi * j * k / n
            re, im = re + a[j][0] * math.cos(ang), im + a[j][0] * math.sin(ang)
        out.append((re, im))
    return out

def spectral(f, n, kind, wrap=True, nyq0=True, twopi=True):
    c = fft([(f(j * L / n), 0.0) for j in range(n)])
    out = []
    for k in range(n):
        m = (k if k <= n // 2 else k - n) if wrap else k  # slot k holds wavenumber k, or k - n past the middle
        q = (2.0 * math.pi if twopi else 1.0) * m / L  # radians per metre
        if kind == "slope":  # multiply by i q; the Nyquist slot has no slope
            z = (0.0, 0.0) if (nyq0 and 2 * k == n) else mul((0.0, q), c[k])
        elif kind == "shift":  # move half a cell: multiply by e^(i q h / 2)
            z = (0.0, 0.0) if 2 * k == n else mul((math.cos(q * L / n / 2), math.sin(q * L / n / 2)), c[k])
        else:  # heat: each mode fades by e^(-alpha q^2 T), exactly
            z = (c[k][0] * math.exp(-ALPHA * q * q * T), c[k][1] * math.exp(-ALPHA * q * q * T))
        out.append(z)
    return ifft(out)

def bessel_i(k):  # I_k(1) by its power series, term by term
    t, s = 1.0, 0.0
    for i in range(1, k + 1): t = t * 0.5 / i
    for m in range(30):
        s += t
        t = t * 0.25 / ((m + 1) * (m + 1 + k))
    return s

CK = [30.0 * bessel_i(k) for k in range(40)]  # Fourier coefficients of 30 e^cos(2 pi x)
def u0(x): return 20.0 + 30.0 * math.exp(math.cos(2 * math.pi * x / L))
def du0(x): return -60.0 * math.pi / L * math.sin(2 * math.pi * x / L) * math.exp(math.cos(2 * math.pi * x / L))
def u_exact(x, t):  # the exact heat solution, from the series with known coefficients
    s = 20.0 + CK[0]
    for k in range(1, 40):
        q = 2 * math.pi * k / L
        s += 2 * CK[k] * math.exp(-ALPHA * q * q * t) * math.cos(q * x)
    return s
def maxerr(v, exact, n): return max(math.sqrt((v[j][0] - exact(j * L / n)) ** 2 + v[j][1] ** 2) for j in range(n))
def tail(n, slope):  # 2 x the sum of |c_k| (times q for a slope) over |k| >= N/2: truncation plus aliasing
    s = 0.0
    for k in range(n // 2, 40):
        s += 2 * CK[k] * (2 * math.pi * k / L if slope else 1.0)
    return 2 * s
def e(x): return f"{x:.3e}"

cs = (math.sqrt(5.0) - 1) / 2
print(f"start: weld {u0(0):.6f} C, far side {u0(0.5):.6f} C; series vs closed form at the weld {e(abs(u_exact(0, 0) - u0(0)))}")
print(f"steepest slope {60 * math.pi * math.sqrt(1 - cs * cs) * math.exp(cs):.6f} C/m at x = {math.acos(cs) / (2 * math.pi):.6f} m")
print("coefficients c_k, k = 0, 1, 2, 4, 8, 16: " + ", ".join(e(CK[k]) for k in (0, 1, 2, 4, 8, 16)) + "; fade factors at 600 s, k = 1, 2, 4, 8, 16: " + ", ".join(e(math.exp(-ALPHA * (2 * math.pi * k / L) ** 2 * T)) for k in (1, 2, 4, 8, 16)))
NS, sd, fd = [4, 8, 16, 32, 64], [], []
for n in NS:
    h, s = L / n, maxerr(spectral(u0, n, "slope"), du0, n)
    f = max(abs((u0((j + 1) * h) - u0((j - 1) * h)) / (2 * h) - du0(j * h)) for j in range(n))
    sd.append(s); fd.append(f)
    print(f"slope N = {n:2d}: spectral {e(s)}, bound {e(tail(n, True))}, bound/true {tail(n, True) / s:.3g}; centred difference {e(f)}")
print("centred difference orders: " + ", ".join(f"{math.log2(fd[i] / fd[i + 1]):.2f}" for i in range(1, 4)))
print("chart x, N: " + ", ".join(str(n) for n in NS))
print("chart, log10 spectral slope error: " + ", ".join(f"{math.log10(v):.2f}" for v in sd))
print("chart, log10 centred difference error: " + ", ".join(f"{math.log10(v):.2f}" for v in fd))
heat = {}
for n in (8, 16, 32, 64):
    uh = spectral(u0, n, "heat")
    heat[n] = maxerr(uh, lambda x: u_exact(x, T), n)
    print(f"heat N = {n:2d}: weld at 600 s {uh[0][0]:.12f} C, largest error {e(heat[n])}, bound {e(tail(n, False))}, bound/true {tail(n, False) / heat[n]:.3g}")
w = u_exact(0, T); ulp = 2.0 ** (math.floor(math.log2(w)) - 52)
print(f"exact: weld at 600 s {w:.12f} C, far side {u_exact(0.5, T):.6f} C; N = 32 error in units of the last place {heat[32] / ulp:.2f}")
a, MULS[0] = [(u0(j / 32), 0.0) for j in range(32)], 0
fftd = max(math.sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) for p, q in zip(fft(a), dft(a)))
print(f"FFT vs direct DFT, N = 32: largest difference {e(fftd)}; complex multiplies {MULS[0]} vs {32 * 32}")
n, dt = 32, 24.0
r, v = ALPHA * dt / (L / n) ** 2, [u0(j / n) for j in range(n)]
for _ in range(25):
    v = [v[j] + r * (v[(j + n - 1) % n] - 2 * v[j] + v[(j + 1) % n]) for j in range(n)]
fdh = max(abs(v[j] - u_exact(j / n, T)) for j in range(n))
print(f"finite differences N = 32, r = {r:.6f}, 25 steps of 24 s: weld {v[0]:.6f} C, largest error {e(fdh)}")
gfd = [(1 - 4 * r * math.sin(math.pi * k / n) ** 2) ** 25 for k in range(n)]  # von Neumann: mode k shrinks by this in 25 steps
vm = ifft([(z[0] * g, z[1] * g) for z, g in zip(fft([(u0(j / n), 0.0) for j in range(n)]), gfd)])  # the same steps, mode by mode
uh = spectral(u0, 32, "heat")
print("ring chart x: " + ", ".join(f"{j / 8:.3f}" for j in range(9)))
print("ring chart, start: " + ", ".join(f"{u0(j / 8):.2f}" for j in range(9)))
print("ring chart, 600 s: " + ", ".join(f"{uh[(4 * j) % 32][0]:.2f}" for j in range(9)))
orders = []
for name, f in (("smooth ring", u0), ("third derivative jumps", lambda x: 100 * abs(math.sin(math.pi * x)) ** 3),
                ("bar, kink at the weld", lambda x: 100 * abs(math.sin(math.pi * x)))):
    errs = [maxerr(spectral(f, n, "shift"), lambda x, f=f, n=n: f(x + L / n / 2), n) for n in (8, 16, 32, 64)]
    orders.append([math.log2(errs[i] / errs[i + 1]) for i in range(3)])
    print(f"midpoint error, {name}, N = 8, 16, 32, 64: " + ", ".join(e(x) for x in errs) + "; orders " + ", ".join(f"{x:.2f}" for x in orders[-1]))
barerr = [abs(spectral(lambda x: 100 * math.sin(math.pi * x), n, "slope")[1][0] - 100 * math.pi * math.cos(math.pi / n)) for n in (16, 32, 64)]
print("mistake, bar treated as periodic: slope error next to the weld, N = 16, 32, 64: " + ", ".join(f"{x:.3f}" for x in barerr) + " C/m")
unw, nyq = maxerr(spectral(u0, 32, "slope", wrap=False), du0, 32), max(abs(z[1]) for z in spectral(u0, 8, "slope", nyq0=False))
no2pi, no2pih = maxerr(spectral(u0, 32, "slope", twopi=False), du0, 32), spectral(u0, 32, "heat", twopi=False)[0][0]
print(f"mistake, slots not wrapped to negative wavenumbers, N = 32: slope error {unw:.3f} C/m")
print(f"mistake, Nyquist slot kept, N = 8: imaginary part up to {nyq:.6f} C/m")
print(f"mistake, 2 pi dropped, N = 32: slope error {no2pi:.6f} C/m; weld at 600 s {no2pih:.6f} C")

assert abs(u_exact(0, 0) - u0(0)) < 1e-12, "series coefficients rebuild the closed-form start"
assert fftd < 1e-10, "FFT agrees with the direct DFT"
assert sd[3] < 1e-10, "32 points: spectral slope down at rounding level"
assert fd[3] > 1.0, "32 points: centred difference still off by over 1 C/m"
assert all(sd[i] <= tail(NS[i], True) for i in range(3)), "slope error inside the aliasing bound until rounding takes over"
assert heat[32] < 1e-12, "heat solve at machine accuracy against the exact series"
assert heat[16] <= tail(16, False), "heat error inside its aliasing bound"
assert fdh > 1e-2, "finite differences on the same 32 points miss by centidegrees"
assert max(abs(vm[j][0] - v[j]) for j in range(n)) < 1e-10, "finite-difference loop = its mode-by-mode solution"
assert abs(orders[1][2] - 3) < 0.05, "order 3 when the third derivative jumps"
assert abs(orders[2][2] - 1) < 0.05, "order 1 for the kinked bar"
assert min(barerr) > 100, "the kinked bar's slope error does not shrink"
assert min(unw / 1000, nyq, no2pi / 100) > 1, "each coding mistake really breaks the answer"
print("ALL CHECKS PASS")
