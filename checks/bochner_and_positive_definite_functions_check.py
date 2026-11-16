# Bochner's theorem -- the check behind the card.  Standard library only: math gives
# sin, cos, exp and sqrt, none of which knows an answer.  Lags tau are in chips of the
# GPS C/A code (1.023 million chips a second); frequencies xi in cycles per chip.
import math
PI, RATE = math.pi, 1.023                          # chip rate in MHz
def tri(t): return max(0.0, 1.0 - abs(t))          # the triangle: the code's correlation shape
def gate(t): return 1.0 if abs(t) < 1 else 0.0     # the candidate that fails
def bowl(t): return 1.0 / (1.0 + abs(t))           # Polya's bowl shape
def sinc(u): return 1.0 if u == 0 else math.sin(PI * u) / (PI * u)
def z(x): return 0.0 if abs(x) < 5e-10 else x      # print a rounding-level number as 0
def simpson(f, a, b, n):                           # n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3
def eigs(A):                                       # Jacobi rotations: all eigenvalues of a symmetric matrix
    A, n = [row[:] for row in A], len(A)
    for _ in range(60):
        off = sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j)
        if off < 1e-22: break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if abs(A[p][q]) < 1e-300: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1 if th >= 0 else -1) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for k in range(n):
                    akp, akq = A[k][p], A[k][q]
                    A[k][p], A[k][q] = c * akp - s * akq, s * akp + c * akq
                for k in range(n):
                    apk, aqk = A[p][k], A[q][k]
                    A[p][k], A[q][k] = c * apk - s * aqk, s * apk + c * aqk
    return sorted(A[i][i] for i in range(n))
def gram(g, lags): return [[g(a - b) for b in lags] for a in lags]
print(f"1 chip = {1 / RATE:.6f} us = {299792458 / 1.023e6:.3f} m of light travel")
# Road one: the spectrum in closed form.  Road two: the transform integral of the triangle.
print("spectrum of the triangle, S(xi) = sinc(xi)^2")
print("  xi (per chip)  MHz     closed form  transform integral")
for xi in (0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0):
    closed = sinc(xi) ** 2
    num = 2 * simpson(lambda t: tri(t) * math.cos(2 * PI * xi * t), 0, 1, 2000)
    print(f"  {xi:5.2f}         {xi * RATE:6.4f}  {z(closed):9.6f}  {z(num):9.6f}")
    assert closed >= 0 and abs(closed - num) < 1e-9
L = 200.0                                          # inversion cut-off; the tail is at most 2/(pi^2 L)
for tau in (0.0, 0.5):
    back = 2 * simpson(lambda x: sinc(x) ** 2 * math.cos(2 * PI * x * tau), 0, L, 400000)
    print(f"inverse transform at tau = {tau:.1f}: {back:.6f} against g = {tri(tau):.6f}, tail bound {2 / (PI * PI * L):.6f}")
    assert abs(back - tri(tau)) < 2 / (PI * PI * L)
# The matrix test at lags 0, 0.8, 1.6 chips: [[1,a,b],[a,1,a],[b,a,1]].
lags = (0.0, 0.8, 1.6)
print("matrix test at lags 0, 0.8, 1.6: a = g(0.8), b = g(1.6), smallest eigenvalue closed / Jacobi")
for name, g in (("triangle", tri), ("gate", gate), ("bowl", bowl)):
    a, b = g(0.8), g(1.6)
    closed = min(1 - b, (2 + b - math.sqrt(b * b + 8 * a * a)) / 2)
    jac = eigs(gram(g, lags))[0]
    form = 4 - 4 * math.sqrt(2) * a + 2 * b          # weights (1, -sqrt 2, 1)
    print(f"  {name:9s}{a:9.6f}{b:9.6f}{closed:11.6f}{jac:11.6f}   weights (1,-r2,1) give {form:.6f}")
    assert abs(closed - jac) < 1e-9 and (jac < 0) == (name == "gate")
print(f"  1 - sqrt 2 = {1 - math.sqrt(2):.6f}")
gs = 2 * simpson(lambda t: math.cos(2 * PI * 0.75 * t), 0, 1, 2000)
print(f"gate spectrum at xi = 0.75: closed 2 sinc(1.5) = {2 * sinc(1.5):.6f}, integral {gs:.6f}")
assert gs < 0 and abs(gs - 2 * sinc(1.5)) < 1e-9
spike = eigs(gram(lambda t: 1.0 if t == 0 else 0.0, lags))
print(f"spike (1 at 0, else 0): eigenvalues {spike[0]:.6f} {spike[1]:.6f} {spike[2]:.6f}; positive definite, not continuous")
# Herglotz: samples every quarter chip, r[k] = 1 - |k|/4, spectrum F_4(theta) on the circle.
r = [tri(k / 4) for k in range(9)]
ev = eigs([[r[abs(j - k)] for k in range(9)] for j in range(9)])
print(f"9 lags 0, 0.25, ..., 2 chips: smallest eigenvalue {ev[0]:.6f}, largest {ev[-1]:.6f}; Herglotz range 0 to 4")
assert 0 < ev[0] and ev[-1] < 4
def f_sum(th): return sum(tri(k / 4) * math.cos(k * th) for k in range(-3, 4))
def fejer(th): return 4.0 if th == 0 else (math.sin(2 * th) / math.sin(th / 2)) ** 2 / 4
for th in (0.0, 1.0, PI / 2, PI):
    print(f"  theta = {th:.4f}: sum of r[k] e^(-ik theta) {z(f_sum(th)):.6f}, Fejer closed form {z(fejer(th)):.6f}")
    assert abs(f_sum(th) - fejer(th)) < 1e-12 and fejer(th) >= 0
coef = simpson(lambda th: fejer(th) * math.cos(2 * th), -PI, PI, 2000) / (2 * PI)
print(f"  coefficient back from the spectrum: r[2] = {coef:.6f}, against 1 - 2/4 = 0.5")
assert abs(coef - 0.5) < 1e-9
# Polya: the bowl 1/(1+|t|) is a mixture of triangles of half-width s, weight w(s) = s g''(s).
w = lambda s: 2 * s / (1 + s) ** 3
M = 2000.0
mass = simpson(w, 0, M, 400000)
print(f"Polya weights w(s) = 2s/(1+s)^3: mass on [0, {M:.0f}] {mass:.6f}, exact 1 - (2M+1)/(1+M)^2 = {1 - (2 * M + 1) / (1 + M) ** 2:.6f}")
assert abs(mass - (1 - (2 * M + 1) / (1 + M) ** 2)) < 1e-6
print("bowl spectrum: mixture of triangles  against  direct transform (cut-off 2000)  tail bound")
for xi in (0.5, 1.0):
    mix = simpson(lambda s: w(s) * s * sinc(s * xi) ** 2, 0, M, 400000)
    direct = 2 * simpson(lambda t: math.cos(2 * PI * xi * t) / (1 + t), 0, M, 400000)
    bound = 1 / (PI * xi * (1 + M))
    print(f"  xi = {xi:.1f}: {mix:.6f}  {direct:.6f}  {bound:.6f}")
    assert mix > 0 and abs(mix - direct) < bound + 1e-6
h = 1e-3
bell2 = (math.exp(-h * h / 2) - 2 + math.exp(-h * h / 2)) / (h * h)
bc, bs = math.sqrt(2 * PI) * math.exp(-PI * PI / 2), 2 * simpson(lambda t: math.exp(-t * t / 2) * math.cos(PI * t), 0, 12, 2000)   # tail past 12 below 1e-31
print(f"bell e^(-t^2/2): second derivative at 0 {bell2:.4f} (a dome, not a bowl), spectrum at xi = 0.5: closed form {bc:.6f}, integral on [-12, 12] {bs:.6f}")
assert bell2 < 0 and abs(bs - bc) < 1e-9
# The same triangle as a cone on a map: (1 - r)+ in two dimensions, r in km, rho in cycles per km.
def J0(x):                                         # the Bessel series, written out
    s, term, m = 0.0, 1.0, 0
    while abs(term) > 1e-17 or m < 5:
        s += term; m += 1; term *= -(x / 2) ** 2 / (m * m)
    return s
def cone(rho): return 2 * PI * simpson(lambda q: (1 - q) * q * J0(2 * PI * rho * q), 0, 1, 2000)
print(f"cone (1 - r)+ on a map: spectrum at rho = 0 {cone(0):.6f} (pi/3 = {PI / 3:.6f}), at rho = 1.1 {cone(1.1):.6f}")
assert abs(cone(0) - PI / 3) < 1e-9 and cone(1.1) < 0
# Road three: simulate the chip wave, 4 samples a chip, and measure its correlation.
MASK, state = (1 << 64) - 1, 20261115                # SplitMix64, seed 20261115
def bit():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    x = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & MASK
    return 1 if (x ^ (x >> 31)) >> 63 else -1
N = 50000
wave = [c for c in (bit() for _ in range(N)) for _ in range(4)]
print(f"simulated chip wave, {N} chips, 4 samples a chip: correlation at lag k quarter-chips / triangle")
for k in range(1, 5):
    est = sum(wave[i] * wave[i + k] for i in range(4 * N - k)) / (4 * N - k)
    se = k / (4 * math.sqrt(N))              # k equal products per chip boundary
    print(f"  k = {k}: {est:7.4f}  {tri(k / 4):7.4f}  standard error {se:.4f}")
    assert abs(est - tri(k / 4)) < 4 * se
# Try changing: samples every half chip; a gate half as wide; the cone further out.
r2 = [tri(k / 2) for k in range(9)]
ev2 = eigs([[r2[abs(j - k)] for k in range(9)] for j in range(9)])
print(f"try: half-chip samples, 9 lags: eigenvalues {ev2[0]:.6f} to {ev2[-1]:.6f}; Herglotz range 0 to 2")
narrow = eigs(gram(lambda t: 1.0 if abs(t) < 0.5 else 0.0, (0.0, 0.4, 0.8)))[0]
print(f"try: gate of half-width 0.5 at lags 0, 0.4, 0.8: smallest eigenvalue {narrow:.6f}; spectrum sinc(1.5) = {sinc(1.5):.6f}")
print(f"try: cone at rho = 2.1: {cone(2.1):.6f}")
assert 0 < ev2[0] and ev2[-1] < 2 and narrow < 0 and cone(2.1) < 0
for name, g in (("triangle", lambda x: sinc(x) ** 2), ("gate", lambda x: 2 * sinc(2 * x))):
    print(f"figure, {name:9s}" + " ".join(f"{z(g(k / 4)):.2f}" for k in range(13)))
print("ALL CHECKS PASS")
