# Dirichlet and Fejer kernels -- the check behind the card.  Standard library only;
# math gives sin, cos, log and pi.  Nine coefficients, k = -4..4: the partial sum S_4
# smears with D_4, its running average sigma_5 = (S_0 + ... + S_4)/5 smears with F_5.
from math import sin, cos, log, pi, sqrt

def D_sum(N, t): return 1 + 2 * sum(cos(k * t) for k in range(1, N + 1))
def D(N, t): return 2 * N + 1 if t % (2 * pi) == 0 else sin((N + 0.5) * t) / sin(t / 2)
def F_avg(N, t): return sum(D_sum(k, t) for k in range(N)) / N    # mean of D_0..D_(N-1)
def F_taper(N, t): return 1 + 2 * sum((1 - k / N) * cos(k * t) for k in range(1, N))  # tapered
def F(N, t): return N if t % (2 * pi) == 0 else (sin(N * t / 2) / sin(t / 2)) ** 2 / N

def gauss(g, a, b, M):              # 3-point Gauss-Legendre on each of M cells of (a, b)
    h, r = (b - a) / M, sqrt(0.6) / 2
    return h * sum(5 / 18 * (g(c - r * h) + g(c + r * h)) + 4 / 9 * g(c)
                   for c in (a + (j + 0.5) * h for j in range(M)))

# ---- the kernels: closed form against the sum of tones ----
for t in (0.3, 1.0, 2.5):
    assert abs(D(4, t) - D_sum(4, t)) < 1e-12
    assert abs(F(5, t) - F_avg(5, t)) < 1e-12 and abs(F(5, t) - F_taper(5, t)) < 1e-12
print("weights on the nine tones, |k| = 0..4: Dirichlet 1 1 1 1 1; Fejer",
      " ".join(f"{1 - k / 5:.1f}" for k in range(5)))
print(f"peak at t = 0: D_4 = {D(4, 0.0):.0f}, F_5 = {F(5, 0.0):.0f}")
print(f"first zero: D_4 at 2pi/9 = {2 * pi / 9:.4f} rad, F_5 at 2pi/5 = {2 * pi / 5:.4f} rad")
print(f"siren, 220 cycles a second: {1000 / (9 * 220):.3f} ms and {1000 / (5 * 220):.3f} ms")
dmin, tmin = min((D(4, 0.8 + j * 1e-5), 0.8 + j * 1e-5) for j in range(50001))
print(f"lowest value: D_4 = {dmin:.4f} at t = {tmin:.4f} rad; F_5 = 0 at its zeros")
assert -2.1 < dmin < D(4, pi / 3) < -1.99           # dips below -2, its value at pi/3
for M in (360, 720):
    a = gauss(lambda t: D(4, t), -pi, pi, M) / (2 * pi)
    b = gauss(lambda t: F(5, t), -pi, pi, M) / (2 * pi)
    print(f"signed area / 2pi, M = {M}: D_4 {a:.10f}, F_5 {b:.10f}")
    assert abs(a - 1) < 1e-12 and abs(b - 1) < 1e-12

# ---- total size: L_N = (1/2pi) * area of |D_N|; cells end on the zeros 2 pi j/(2N+1) ----
def L(N, m): return gauss(lambda t: abs(D(N, t)), 0, pi, (2 * N + 1) * m) / pi
for N in (4, 16, 64, 256):
    l1, l2 = L(N, 40), L(N, 80)
    low = 4 / pi ** 2 * sum(1 / k for k in range(1, N + 1)); up = 1 + log(2 * N + 1)
    print(f"L_{N}: {l1:.6f} ({40 * (2 * N + 1)} cells), {l2:.6f} ({80 * (2 * N + 1)});"
          f" lower {low:.4f} ratio {l2 / low:.3f}; upper {up:.4f}")
    assert abs(l1 - l2) < 1e-6 and low < l2 < up
L4 = L(4, 80)
neg = (L4 - 1) / 2                                  # |D| area minus signed area = 2 x negative part
print(f"D_4: positive part {1 + neg:.5f}, negative part {neg:.5f}; F_5: 1 and 0")

# ---- the worst +-1 V signal for nine terms: f(y) = sign of D_4(y), switching at 2 pi j/9 ----
cuts = [0] + [2 * pi * j / 9 for j in range(1, 5)] + [pi]
def fhat(k):            # exact coefficient of the even +-1 signal, (1/pi) * integral over (0, pi)
    s = 0.0
    for j in range(5):
        a, b = cuts[j], cuts[j + 1]
        s += (-1) ** j * ((b - a) if k == 0 else (sin(k * b) - sin(k * a)) / k)
    return s / pi
worst = fhat(0) + 2 * sum(fhat(k) for k in range(1, 5))
print(f"worst signal: S_4 at x = 0 by its coefficients {worst:.6f} V; by L_4 {L4:.6f} V")
assert abs(worst - L4) < 1e-9

# ---- the siren: +-1 V square wave, b_k = 4/(pi k) for odd k ----
def S_sq(N, x): return 4 / pi * sum(sin(k * x) / k for k in range(1, N + 1, 2))
def sig_sq(N, x): return 4 / pi * sum((1 - k / N) * sin(k * x) / k for k in range(1, N, 2))
def sq(x): return 1.0 if (x % (2 * pi)) < pi else -1.0
x0 = pi / 4
print(f"siren at x = pi/4: sin x = sin 3x = {sin(x0):.4f}")
for M in (3600, 7200):                             # the jumps fall on cell edges
    c1 = gauss(lambda t: sq(x0 - t) * D(4, t), -pi, pi, M) / (2 * pi)
    c2 = gauss(lambda t: sq(x0 - t) * F(5, t), -pi, pi, M) / (2 * pi)
    print(f"at x = pi/4, by convolution, M = {M}: S_4 {c1:.6f} V, sigma_5 {c2:.6f} V")
print(f"at x = pi/4, by coefficients: S_4 {S_sq(4, x0):.6f} V, sigma_5 {sig_sq(5, x0):.6f} V")
assert abs(c1 - S_sq(4, x0)) < 1e-6 and abs(c2 - sig_sq(5, x0)) < 1e-6
assert abs(S_sq(4, x0) - 8 * sqrt(2) / (3 * pi)) < 1e-12           # peak by calculus
grid = [pi * j / 4000 for j in range(1, 4000)]
for N in (4, 16, 64):
    K = (N + 1) // 2                                # odd harmonics kept; first peak pi/(2K)
    pS = S_sq(N, pi / (2 * K)); pF = max(sig_sq(N + 1, x) for x in grid)
    print(f"square wave, tones up to {N}: S peak {pS:.4f} V at x = {pi / (2 * K):.4f};"
          f" sigma_{N + 1} highest {pF:.4f} V")
    assert pS > 1.17 and pF < 1
assert abs(S_sq(64, pi / 64) - 1.178980) < 1e-3      # Gibbs limit (2/pi) Si(pi)

# ---- far weight: share of each kernel's size beyond |t| = pi/2 ----
lim = 4 / pi ** 2 * -log(sqrt(2) - 1)          # (1/pi) int (2/pi)/sin(t/2), pi/2..pi; tan(pi/8)
for N in (5, 50, 500):
    fF = gauss(lambda t: F(N, t), pi / 2, pi, 200 * N) / pi
    fD = gauss(lambda t: abs(D(N, t)), pi / 2, pi, 200 * N) / pi
    print(f"beyond pi/2, N = {N}: F_N {fF:.6f}, bound 1/N {1 / N:.4f}, ratio {fF * N:.3f};"
          f" |D_N| {fD:.4f}")
    assert fF <= 1 / N
print(f"|D_N| beyond pi/2 tends to (4/pi^2) ln(1/tan(pi/8)) = {lim:.4f}")
assert abs(fD - lim) < 1e-3                         # Dirichlet's far weight never dies

# ---- what breaks ----
print(f"break, drop 1/2pi: S_4 at pi/4 = {2 * pi * S_sq(4, x0):.4f} V")
print(f"break, drop 1/N in F_5: peak {5 * F(5, 0.0):.0f}, area {5 * b:.0f},"
      f" sigma_5 at pi/4 = {5 * sig_sq(5, x0):.4f} V")

# ---- chart points, t = 0 .. pi in steps of pi/18 ----
def two(v): return f"{0.0 if abs(v) < 0.005 else v:.2f}"   # no "-0.00" at the zeros
ts = [pi * j / 18 for j in range(19)]
print("chart t:", " ".join(two(t) for t in ts))
print("chart D_4:", " ".join(two(D(4, t)) for t in ts))
print("chart F_5:", " ".join(two(F(5, t)) for t in ts))
print("ALL CHECKS PASS")
