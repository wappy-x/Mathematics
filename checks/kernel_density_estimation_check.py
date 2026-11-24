# Kernel density estimation -- the check behind the card.  Standard library only.
# Shop A's 8 waits, a bell-shaped kernel, Silverman's bandwidth, bias and variance, cross-validation.
from math import sqrt, exp, pi, log, cos, floor
A = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0]
B = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0]

def phi(z): return exp(-0.5 * z * z) / sqrt(2 * pi)            # standard bell height
def Phi(z): return 0.5 + simpson(phi, 0, z)                    # standard bell area to the left, by Simpson slices
def npdf(x, sd): return phi(x / sd) / sd                       # bell of spread sd, centred at 0
def kde(x, data, h): return sum(phi((x - xi) / h) for xi in data) / (len(data) * h)
def mean(d): return sum(d) / len(d)
def sd(d, div): m = mean(d); return sqrt(sum((v - m) ** 2 for v in d) / div)
def hinges(d):                                                 # quartiles = medians of the two halves
    d = sorted(d); k = len(d) // 2
    med = lambda v: (v[(len(v) - 1) // 2] + v[len(v) // 2]) / 2
    return med(d[:k]), med(d[len(d) - k:])
def silverman(d, spread_iqr=None):
    q1, q3 = hinges(d); iqr = q3 - q1 if spread_iqr is None else spread_iqr
    return 0.9 * min(sd(d, len(d) - 1), iqr / 1.34) * len(d) ** -0.2
def simpson(f, a, b, m=4000):
    w = (b - a) / m
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * w) for i in range(1, m))) * w / 3
def cv_closed(d, h, leave_out=True):                           # integral of fhat^2 by the bell identity
    n = len(d)
    i2 = sum(npdf(a - b, sqrt(2) * h) for a in d for b in d) / n ** 2
    if leave_out:
        fit = sum(sum(npdf(a - b, h) for j, b in enumerate(d) if j != i) / (n - 1) for i, a in enumerate(d))
    else:
        fit = sum(kde(a, d, h) for a in d)                      # each point helps predict itself
    return i2 - 2 * fit / n
def cv_simpson(d, h):                                          # same score, integral done by brute force
    i2 = simpson(lambda x: kde(x, d, h) ** 2, -10, 16, 2000)
    return i2 - 2 * sum(kde(a, d[:i] + d[i + 1:], h) for i, a in enumerate(d)) / len(d)

n, x0 = len(A), 3.0
m, s = mean(A), sd(A, n - 1)
q1, q3 = hinges(A)
h = silverman(A)
print(f"mean {m:.4f}  s {s:.4f}  Q1 {q1:.2f}  Q3 {q3:.2f}  IQR {q3 - q1:.2f}  IQR/1.34 {(q3 - q1) / 1.34:.4f}")
print(f"min(s, IQR/1.34) {min(s, (q3 - q1) / 1.34):.4f}  8^(-1/5) {n ** -0.2:.4f}  h = 0.9 x {min(s, (q3 - q1) / 1.34):.4f} x {n ** -0.2:.4f} = {h:.4f}")
lo, hi = 0.0, 2.0
for _ in range(60): mid = (lo + hi) / 2; lo, hi = (mid, hi) if Phi(mid) < 0.75 else (lo, mid)
print(f"standard bell: IQR {2 * lo:.4f}  R(K) = 1/(2 sqrt(pi)) {1 / (2 * sqrt(pi)):.4f}  (4/3)^(1/5) {(4 / 3) ** 0.2:.4f}")
print("wait   z = (3 - wait)/h   bell height phi(z)")
for xi in A:
    print(f"{xi:4.1f}   {(x0 - xi) / h:+8.4f}            {phi((x0 - xi) / h):.4f}")
tot = sum(phi((x0 - xi) / h) for xi in A)
f1 = kde(x0, A, h)
d = 1e-4
f2 = (sum(Phi((x0 + d - xi) / h) - Phi((x0 - d - xi) / h) for xi in A) / n) / (2 * d)
area = simpson(lambda x: kde(x, A, h), -10, 16)
below0 = sum(Phi(-xi / h) for xi in A) / n
print(f"sum of heights {tot:.4f}   divide by n h = {n * h:.4f}")
print(f"road 1  average of 8 bells   fhat(3) = {f1:.6f}")
print(f"road 2  slope of smooth CDF  fhat(3) = {f2:.6f}")
print(f"area under fhat {area:.6f}   area below 0 minutes {below0:.4f}")
for a0 in (1.0, 0.5):
    cnt = [sum(1 for v in A if a0 + k <= v < a0 + k + 1) for k in range(6)]
    print(f"histogram, bins of 1 min from {a0}: counts {cnt}   density at 3 = {cnt[floor(x0 - a0)] / n:.3f}")
xs = [0.5 * k for k in range(15)]
print("chart x      " + " ".join(f"{x:5.1f}" for x in xs))
for hh in (0.25, h, 1.5):
    print(f"chart h={hh:.2f} " + " ".join(f"{kde(x, A, hh):5.3f}" for x in xs))

# ---- bias and variance at 3 minutes, if the waits were truly bell-shaped (centre m, spread s) ----
u = x0 - m
f_true, f2nd = npdf(u, s), npdf(u, s) * (u * u / s ** 4 - 1 / s ** 2)
def exact(hh):
    ef = npdf(u, sqrt(s * s + hh * hh))                         # E fhat = true bell convolved with kernel
    ek2 = npdf(u, sqrt(s * s + hh * hh / 2)) / (2 * sqrt(pi) * hh)
    return ef - f_true, (ek2 - ef * ef) / n
print(f"true f(3) {f_true:.4f}   f''(3) {f2nd:.4f}")
print("h      bias exact  h^2 f''/2   var exact  f/(2 sqrt(pi) n h)  MSE")
for hh in (0.25, 0.5, h, 1.0, 1.5):
    b, v = exact(hh)
    print(f"{hh:.4f} {b:+.5f}   {hh * hh * f2nd / 2:+.5f}    {v:.5f}    {f_true / (2 * sqrt(pi) * n * hh):.5f}          {b * b + v:.5f}")
state = 20261123
def unif():
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7; state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 2.0 ** 53
reps, acc, acc2 = 20000, 0.0, 0.0
for _ in range(reps):
    smp = [m + s * sqrt(-2 * log(unif())) * cos(2 * pi * unif()) for _ in range(n)]
    v = kde(x0, smp, h); acc += v; acc2 += v * v
sim_mean = acc / reps; sim_var = acc2 / reps - sim_mean ** 2
b_ex, v_ex = exact(h)
print(f"simulation, {reps} samples of 8: mean fhat(3) {sim_mean:.5f} (exact {f_true + b_ex:.5f})  var {sim_var:.5f} (exact {v_ex:.5f})")
h_amise = (4 / 3) ** 0.2 * s * n ** -0.2
def mise(hh):
    t = sqrt(s * s + hh * hh)
    return (1 / hh - 1 / t) / (2 * sqrt(pi) * n) + 1 / (2 * sqrt(pi) * t) - 2 * npdf(0, sqrt(t * t + s * s)) + 1 / (2 * sqrt(pi) * s)
grid = [k / 1000 for k in range(100, 3001)]
h_mise = min(grid, key=mise)
print(f"optimal-rate h = (4/3)^(1/5) s n^(-1/5) = {h_amise:.4f}   exact MISE minimum at h = {h_mise:.3f}")

# ---- cross-validation ----
cgrid = [k / 100 for k in range(10, 301)]
h_cv = min(cgrid, key=lambda hh: cv_closed(A, hh))
print(f"CV score at h: 0.30 {cv_closed(A, 0.3):+.4f}  0.73 {cv_closed(A, h):+.4f}  1.43 {cv_closed(A, 1.43):+.4f}  2.00 {cv_closed(A, 2.0):+.4f}")
print(f"CV picks h = {h_cv:.2f}   brute-force integral at 1.43: {cv_simpson(A, 1.43):+.4f}   fhat(3) there {kde(x0, A, h_cv):.4f}")
h_nlo = min(cgrid, key=lambda hh: cv_closed(A, hh, False))
print(f"wrong: CV without leaving out picks h = {h_nlo:.2f} (the smallest allowed)")

# ---- what breaks ----
q1i, q3i = A[1] + 0.75 * (A[2] - A[1]), A[5] + 0.25 * (A[6] - A[5])   # interpolated quartiles, R's default
h_i, h_r, h_p = silverman(A, q3i - q1i), 0.9 * s * n ** -0.5, 0.9 * sd(A, n) * n ** -0.2
print(f"wrong: forget 1/h            fhat(3) = {tot / n:.4f}")
print(f"other rule: interpolated IQR {q3i - q1i:.2f}  h = {h_i:.4f}  fhat(3) = {kde(x0, A, h_i):.4f}")
print(f"wrong: n^(-1/2)              h = {h_r:.4f}  fhat(3) = {kde(x0, A, h_r):.4f}")
print(f"wrong: s divided by n        h = {h_p:.4f}  fhat(3) = {kde(x0, A, h_p):.4f}")
hb, A9 = silverman(B), A + [12.0]
print(f"try: shop B h = {hb:.4f}  fhatB(3) = {kde(x0, B, hb):.4f}  fhatB(5) = {kde(5.0, B, hb):.4f}")
print(f"try: add a 12-min wait  s = {sd(A9, 8):.4f}  IQR/1.34 = {(hinges(A9)[1] - hinges(A9)[0]) / 1.34:.4f}  h = {silverman(A9):.4f}")
print(f"try: 80 waits, same spread  h = {0.9 * s * 80 ** -0.2:.4f}  MISE shrinks by 10^(-4/5) = {10 ** -0.8:.4f}")

assert abs(h - 0.9 * 1.2275847 * 2 ** -0.6) < 1e-6, "Silverman's h by hand"
assert abs(f1 - f2) < 1e-6, "average of bells = slope of smoothed CDF"
assert abs(area - 1) < 1e-9, "a kernel estimate is a density"
assert abs(sim_mean - (f_true + b_ex)) < 4 * sqrt(sim_var / reps), "simulated mean vs exact E fhat"
assert abs(sim_var - v_ex) / v_ex < 0.05, "simulated variance vs exact"
assert abs(exact(0.05)[0] / (0.05 ** 2 * f2nd / 2) - 1) < 0.01, "bias is h^2 f''/2 for small h"
assert abs(cv_closed(A, 1.43) - cv_simpson(A, 1.43)) < 1e-8, "CV integral: identity vs brute force"
assert h_nlo == 0.10, "without leaving out, CV runs to the smallest h"
assert abs(2 * lo - 1.349) < 1e-3, "IQR of the standard bell"
print("ALL CHECKS PASS")
