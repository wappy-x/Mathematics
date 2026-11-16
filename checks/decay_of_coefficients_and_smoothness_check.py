# Decay of Fourier coefficients and smoothness -- the check behind the card.
# Standard library only.  Three +-1 V waves on the phase circle -pi <= x < pi:
# square (jumps), triangle (kinks), parabola wave (its slope kinks).
# Coefficients are integrated by a midpoint rule; term counts are found by
# brute force on a grid and by tail sums, then set beside the theorem's bound.
from math import pi, sin, cos, sqrt, log10, ceil
def fact(m): return 1 if m < 2 else m * fact(m - 1)

def sq(x):   return 1.0 if x > 0 else (-1.0 if x < 0 else 0.0)
def tri(x):  return 1.0 - 2.0 * abs(x) / pi
def par(x):  return 4.0 / pi ** 2 * (pi * x - x * abs(x))
def dtri(x): return -2.0 / pi * sq(x)                  # slope of tri, by hand
def dpar(x): return 4.0 / pi ** 2 * (pi - 2.0 * abs(x))  # slope of par, by hand

M = 20000                                              # midpoint slices on the circle
def coef(f, n):                                        # |f^(n)|, f^(n) = (1/2pi) int f e^(-inx) dx
    h = 2 * pi / M; a = b = 0.0
    for j in range(M):
        x = -pi + (j + 0.5) * h; v = f(x)
        a += v * cos(n * x); b += v * sin(n * x)
    return sqrt(a * a + b * b) * h / (2 * pi)

def travel(f, k, L=200, d=0.01):       # travel of the k-th slope round the loop, sampled from f
    xs = [-pi + 2 * pi * (j + 0.5) / L for j in range(L)]   # no sample within d of a kink
    g = [f(x) if k == 0 else (f(x + d) - f(x - d)) / (2 * d) if k == 1
         else (f(x + d) - 2 * f(x) + f(x - d)) / (d * d) for x in xs]
    return sum(abs(g[j] - g[j - 1]) for j in range(L))      # j = 0 closes the loop at the seam

K = {"square": 0, "triangle": 1, "parabola": 2}                       # slopes before a jump
EXACT = {"square": 2 / pi, "triangle": 4 / pi ** 2, "parabola": 16 / pi ** 3}  # n^(k+1)|f^(n)|, odd n
FUN = {"square": sq, "triangle": tri, "parabola": par}
V = {w: travel(FUN[w], K[w]) for w in FUN}                            # travel of the k-th slope

print("1. decay: n^(k+1) |f^(n)| at odd n, integrated; bound V/2pi")
ns = (1, 3, 9, 27, 81)
for w in FUN:
    k = K[w]; vals = [n ** (k + 1) * coef(FUN[w], n) for n in ns]
    print(f"  {w:<9} k={k}  " + " ".join(f"{v:.5f}" for v in vals) + f"   bound {V[w] / (2 * pi):.5f}")
    assert max(abs(v - EXACT[w]) for v in vals) < 1e-3 * EXACT[w]   # closed form, two roads
    assert abs(V[w] / (2 * pi) - vals[0]) < 1e-4 * vals[0]          # measured travel: bound is sharp
print("  even n=2:", " ".join(f"{coef(FUN[w], 2):.6f}" for w in FUN))

print("2. derivative rule: |slope^(n)| against n |f^(n)|")
for name, f, df in (("triangle", tri, dtri), ("parabola", par, dpar)):
    for n in (3, 9):
        lhs, rhs = coef(df, n), n * coef(f, n)
        print(f"  {name:<9} n={n}  {lhs:.6f}  {rhs:.6f}")
        assert abs(lhs - rhs) < 1e-4
print("  sawtooth x/pi, smooth inside, n|f^(n)| at n=1,9,99:",
      " ".join(f"{n * coef(lambda x: x / pi, n):.4f}" for n in (1, 9, 99)))

def tail(p, N, c, top=10 ** 6):        # c * sum over odd n > N of 1/n^p, plus integral tail
    s = sum(1.0 / n ** p for n in range(N + 1 + (N % 2 == 1), top, 2))
    return c * (s + 1.0 / (2 * (p - 1) * top ** (p - 1)))

G = 2001
grid = [-pi + 2 * pi * i / (G - 1) for i in range(G)]
def brute(w, eps, nmax=120):           # smallest N whose worst grid error <= eps
    f = FUN[w]; S = [0.0] * G; hist = {}
    for N in range(1, nmax + 1):
        if N % 2 == 1:
            for i, x in enumerate(grid):
                S[i] += (8 / pi ** 2 * cos(N * x) / N ** 2 if w == "triangle"
                         else 32 / pi ** 3 * sin(N * x) / N ** 3)
        hist[N] = max(abs(f(x) - S[i]) for i, x in enumerate(grid))
        if hist[N] <= eps: return N, hist
    return None, hist

def predict(w, eps): k = K[w]; return ceil((V[w] / (pi * k * eps)) ** (1.0 / k))
print("3. uniform accuracy 0.01 V: terms needed")
for w, p, c in (("triangle", 2, 8 / pi ** 2), ("parabola", 3, 32 / pi ** 3)):
    N, hist = brute(w, 0.01)
    Nt = next(m for m in range(1, 200) if tail(p, m, c) <= 0.01)
    print(f"  {w:<9} brute force N={N} (error {hist[N]:.5f} V, at N-2 {hist[N - 2]:.5f} V)"
          f"  tail sum N={Nt}  theorem N={predict(w, 0.01)}  top {N * 220} Hz")
    assert N <= Nt <= predict(w, 0.01)                  # each count is safe
    if w == "triangle": assert abs(hist[N] - tail(p, N, c)) < 1e-6   # grid vs tail sum
    if w == "triangle": Ntri = N
Vt = V["triangle"]; th = Vt / (pi * 0.01)
print(f"  triangle: V1 {Vt:.5f}, n=3 coefficient {coef(tri, 3):.6f}, bound {Vt / (2 * pi * 9):.6f},"
      f" theorem N {th:.2f}, half {th / 2:.2f}, nonzero tones {(Ntri + 1) // 2}")
tri_err = {N: tail(2, N, 8 / pi ** 2) for N in (1, 9, 41, 81)}
print("  triangle worst error at N=1,9,41,81:", " ".join(f"{tri_err[N]:.5f}" for N in tri_err))
assert abs(tri_err[1] - (1 - 8 / pi ** 2)) < 1e-6         # x=0: 1 - 8/pi^2 exactly
last = next(n for n in range(1, 99, 2) if 8 / pi ** 2 / (n + 2) ** 2 < 0.01)  # next term small
print(f"  mistake, stop when the next amplitude < 0.01 V: N={last}, worst error {tail(2, last, 8 / pi ** 2):.5f} V,"
      f" {tail(2, last, 8 / pi ** 2) / 0.01:.2f} x target")
for eps in (0.1, 0.01, 0.001):
    print(f"  eps {eps:<5}  theorem N: triangle {predict('triangle', eps)}"
          f"  parabola {predict('parabola', eps)}  square rms {ceil(16 / (2 * pi ** 2 * eps * eps))}")

print("4. square wave: no uniform accuracy; energy only")
def overshoot(N):                       # peak of S_N on (0, 3pi/(N+1)), 400 points
    best = 0.0
    for i in range(1, 401):
        x = 3 * pi / (N + 1) * i / 400
        best = max(best, 4 / pi * sum(sin(n * x) / n for n in range(1, N + 1, 2)))
    return best - 1.0
print("  overshoot above 1 V at N=41, 401, 4053:", " ".join(f"{overshoot(N):.4f}" for N in (41, 401, 4053)))
head, N = 0.0, 0
while True:
    N += 1
    if N % 2 == 1: head += 8 / pi ** 2 / N ** 2       # energy kept; total energy is 1 V^2
    if 1.0 - head <= 1e-4: break
print(f"  rms 0.01 V by Parseval: N={N}  rms {sqrt(1 - head):.6f} V  theorem N={ceil(16 / (2 * pi ** 2 * 1e-4))}  top {N * 220} Hz")
L = 40000; h = 2 * pi / L; e2 = 0.0                    # direct integral of (s - S_41)^2
for j in range(L):
    x = -pi + (j + 0.5) * h
    e2 += (sq(x) - 4 / pi * sum(sin(n * x) / n for n in range(1, 42, 2))) ** 2 * h / (2 * pi)
print(f"  N=41 mean-square error: integrated {e2:.6f}  Parseval tail {tail(2, 41, 8 / pi ** 2):.6f}")
assert abs(e2 - tail(2, 41, 8 / pi ** 2)) < 1e-5     # integral against coefficients
si = sum((-1) ** j * pi ** (2 * j + 1) / ((2 * j + 1) * fact(2 * j + 1)) for j in range(30))
print(f"  Gibbs limit (2/pi) Si(pi) - 1 = {2 / pi * si - 1:.4f}")
assert all(abs(overshoot(N) - (2 / pi * si - 1)) < 1e-3 for N in (401, 4053))

print("5. converse: sum of |n| |f^(n)| over 0<|n|<=N, N = 10^2, 10^4, 10^6")
for w, p, c in (("triangle", 1, 8 / pi ** 2), ("parabola", 2, 32 / pi ** 3)):
    print(f"  {w:<9}", " ".join(f"{c * sum(1.0 / n ** p for n in range(1, 10 ** e, 2)):.5f}" for e in (2, 4, 6)))
print(f"  parabola limit 4/pi = {4 / pi:.5f}")
d0 = 0.0 - 8 / pi ** 2 * sum(sin(n * 0.0) / n for n in range(1, 10 ** 4, 2))
print(f"  triangle slope at x=0: left {dtri(-1e-9):+.5f}, right {dtri(1e-9):+.5f}, differentiated series {d0:.5f}")

print("chart, log10 n:", " ".join(f"{log10(n):.3f}" for n in ns))
for w in FUN:
    print(f"chart, {w}:", " ".join(f"{log10(EXACT[w] / n ** (K[w] + 1)):.3f}" for n in ns))
print("ALL CHECKS PASS")
