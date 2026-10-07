# The discrete Fourier transform -- the check behind the card.  Standard library only.  Eight
# three-hourly temperatures (deg C, midnight to 21:00).  Road one: the 8 by 8 matrix of powers of
# w = e^(-2 pi i/8).  Road two: the FFT.  Inverse twice: conjugate matrix / N, and a cosine rebuild.
import math
x, N = [11, 9, 10, 15, 20, 22, 19, 14], 8
count = {"matrix": 0, "fft": 0, "inverse": 0}

def fmt(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"
mod, f6 = (lambda z: math.sqrt(z.real ** 2 + z.imag ** 2)), (lambda v: f"{v:.6f}")
def row(zs, f=fmt): return ", ".join(f(z) for z in zs)

w = complex(math.cos(2 * math.pi / N), -math.sin(2 * math.pi / N))
pw = [1 + 0j]
for _ in range(N - 1): pw.append(pw[-1] * w)          # w^0 .. w^7 by repeated multiplication
F = [[pw[k * n % N] for n in range(N)] for k in range(N)]
Fbar = [[z.conjugate() for z in r] for r in F]
def apply(M, v, tag):                                  # road one: matrix times vector
    count[tag] += len(M) * len(v)
    return [sum((m * a for m, a in zip(r, v)), 0j) for r in M]
def fft(a):                                            # road two: halve, recurse, recombine
    n = len(a)
    if n == 1: return [complex(a[0])]
    ev, od, out = fft(a[0::2]), fft(a[1::2]), [0j] * n
    for k in range(n // 2):
        t = complex(math.cos(2 * math.pi * k / n), -math.sin(2 * math.pi * k / n)) * od[k]
        count["fft"] += 1
        out[k], out[k + n // 2] = ev[k] + t, ev[k] - t
    return out
X, Y = apply(F, x, "matrix"), fft(x)
back = [z / N for z in apply(Fbar, X, "inverse")]
amp, ph = [mod(z) for z in X], [math.atan2(z.imag, z.real) for z in X]
cyc = lambda n, k: 2 * amp[k] / N * math.cos(2 * math.pi * k * n / N + ph[k])
rebuild = [X[0].real / N + sum(cyc(n, k) for k in (1, 2, 3)) + X[4].real / N * (-1) ** n for n in range(N)]
curve, peak = [X[0].real / N + cyc(n, 1) for n in range(N)], (-ph[1] / (2 * math.pi) % 1) * 24
e_t, e_f = sum(v * v for v in x), sum(a * a for a in amp)
gap_u = max(mod(sum(Fbar[j][n] * F[k][n] for n in range(N)) / N - (j == k)) for j in range(N) for k in range(N))
walk, s = [], 0j
for n in range(N): s += x[n] * pw[n]; walk.append(f"({210 + 4.5 * s.real:.1f}, {100 - 4.5 * s.imag:.1f})")

print(f"samples, hours 0 to 21: {x}; w = {fmt(w)}; w^8 = {fmt(pw[7] * w)}")
print(f"X by matrix, k = 0..3: {row(X[:4])}\nX by matrix, k = 4..7: {row(X[4:])}")
print(f"FFT matches matrix: {'yes' if max(mod(a - b) for a, b in zip(X, Y)) < 1e-12 else 'no'}; multiplications: matrix {count['matrix']}, FFT {count['fft']}")
print(f"|X_k|, k = 0..7: {row(amp, f6)}")
print(f"daily cycle: mean {X[0].real / N:.6f}, amplitude 2|X_1|/N = {2 * amp[1] / N:.6f}, arg X_1 = {ph[1]:.6f} rad, peak at hour {peak:.6f}")
print(f"mean + daily cycle at the 8 hours: {row(curve, lambda v: f'{v:.2f}')}")
print(f"inverse, conjugate matrix / N: {row((z.real for z in back), f6)}")
print(f"rebuild from amplitudes and phases: {row(rebuild, f6)}")
print(f"Parseval: sum x^2 = {e_t:.6f}; sum |X|^2 = {e_f:.6f}; divided by N = {e_f / N:.6f}\nunitary: conj(F) F / N equals the identity to within 1e-12: {'yes' if gap_u < 1e-12 else 'no'}")
print(f"figure, walk for X_1, 4.5 px per degree, origin (210, 100): {' '.join(walk)}")
print(f"mistake 1, inverse without 1/N: {row((z.real * N for z in back[:3]), f6)}, ...")
print(f"mistake 2, inverse with F, not conj(F): {row((z.real / N for z in apply(F, X, 'inverse')), f6)}")
print(f"mistake 3, Parseval without 1/N: {e_f:.6f} against {e_t:.6f}\nmistake 4, amplitude as |X_1|/N, twin k = 7 forgotten: {amp[1] / N:.6f}, not {2 * amp[1] / N:.6f}")
assert max(mod(a - b) for a, b in zip(X, Y)) < 1e-12                  # matrix against FFT
assert max(abs(b.real - v) + abs(b.imag) for b, v in zip(back, x)) < 1e-12 and max(abs(r - v) for r, v in zip(rebuild, x)) < 1e-12
assert abs(e_t - e_f / N) < 1e-9                                        # Parseval, time side against frequency side
assert gap_u < 1e-12                                                    # the scaled matrix is unitary
print("ALL CHECKS PASS")
