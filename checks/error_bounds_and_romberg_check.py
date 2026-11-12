# Error bounds and Romberg -- the check behind the card.  Only math is imported.
# Wind model (illustrative): v(t) = 8 + 16 sin(pi t / 24) km/h over a 24-hour day,
# logged every 10 minutes (145 readings).  Wind run I = area under v, in km.
# Road 1: the closed form.  Road 2: Romberg's table.  Road 3: the Euler-Maclaurin
# series predicting each trapezoid error from the slopes at the two ends alone.
import math
W = math.pi / 24
def v(t): return 8 + 16 * math.sin(W * t)
I = 8 * 24 + 16 * 2 / W                                  # antiderivative 8t - (16/W) cos(Wt)
log = [v(10 * k / 60) for k in range(145)]               # the station's 145 readings
def add(xs):                                             # left to right; Python's sum() compensates
    s = 0.0
    for x in xs: s += x
    return s
def trap_log(n):                                         # n slices, every (144/n)-th reading
    s = 144 // n
    return 24 / n * ((log[0] + log[144]) / 2 + add(log[s * i] for i in range(1, n)))
def trap(g, a, b, n):                                    # same rule on any curve
    h = (b - a) / n
    return h * ((g(a) + g(b)) / 2 + add(g(a + i * h) for i in range(1, n)))
def romberg(T):                                          # T[k] has twice the slices of T[k-1]
    R = [[t] for t in T]
    for k in range(1, len(T)):
        for j in range(1, k + 1):
            R[k].append(R[k][j - 1] + (R[k][j - 1] - R[k - 1][j - 1]) / (4 ** j - 1))
    return R
e = lambda x, ref=I: f"{x - ref:+.2e}"
print(f"readings in the log: {len(log)}; v(0) = {log[0]:.6f}, v(12) = {log[72]:.6f}, v(24) = {log[144]:.6f} km/h")
print(f"exact wind run I = 192 + 768/pi = {I:.6f} km")
ns = [3, 6, 12, 24, 48]
T = [trap_log(n) for n in ns]
R = romberg(T)
print("Romberg table on the log (stride: use every stride-th reading); entry (error in km):")
for k, n in enumerate(ns):
    print(f"  n = {n:2d}, h = {24 / n:3.1f} h, stride {144 // n:2d}: " + "; ".join(f"{x:.6f} ({e(x)})" for x in R[k]))
for j in range(3):
    rat = [(R[k - 1][j] - I) / (R[k][j] - I) for k in range(j + 1, 5)]
    print(f"column {j}: error ratio per halving " + ", ".join(f"{r:.2f}" for r in rat) + f"; theory {4 ** (j + 1)}")
    assert abs(rat[-1] - 4 ** (j + 1)) < 0.02 * 4 ** (j + 1)              # h^2, h^4, h^6 observed
t24, r24, t144 = T[3], R[3][1], trap_log(144)
print(f"headline: T(24) = {t24:.6f}, off {t24 - I:+.4f} km, relative {(t24 - I) / I:+.1e}")
print(f"headline: R(24,1) from 25 readings = {r24:.6f}, off {r24 - I:+.2e} km, relative {(r24 - I) / I:+.1e}")
print(f"plain T(144), all 145 readings = {t144:.6f}, off {t144 - I:+.2e} km, relative {(t144 - I) / I:+.1e}")
nneed = 24 * math.sqrt(abs((t24 - I) / (r24 - I)))
print(f"plain trapezoid slices needed to match R(24,1): about {nneed:.0f}")
assert abs((t24 - I) / I) < 1e-3 and abs((r24 - I) / I) < 1e-6 < abs((t144 - I) / I)
# Road 3: Euler-Maclaurin, T - I = h^2/12 D1 - h^4/720 D3 + h^6/30240 D5, Dk = f^(k)(24) - f^(k)(0)
D = {k: 16 * W ** k * (math.sin(W * 24 + k * math.pi / 2) - math.sin(k * math.pi / 2)) for k in (1, 3, 5)}
for n, t in zip(ns[2:], T[2:]):
    h = 24 / n
    p = [h ** 2 / 12 * D[1], -h ** 4 / 720 * D[3], h ** 6 / 30240 * D[5]]
    print(f"Euler-Maclaurin n = {n}: one term {p[0]:+.10f}, three terms {add(p):+.10f}, measured {t - I:+.10f}")
    assert abs(add(p) - (t - I)) < 1e-9 * I                               # road 3 against road 1
K2, K4 = 16 * W ** 2, 16 * W ** 4                                        # largest |v''|, |v''''|, at noon
bt, bs = K2 * 24 / 12, K4 * 24 / 180                                   # h = 1 hour
simp = 1 / 3 * (log[0] + log[144] + add((4 if i % 2 else 2) * log[6 * i] for i in range(1, 24)))
print(f"bounds at h = 1 h: trapezoid {bt:.4f} vs true {abs(t24 - I):.4f}, ratio {bt / abs(t24 - I):.2f}")
print(f"bounds at h = 1 h: Simpson {bs:.2e} vs true {abs(r24 - I):.2e}, ratio {bs / abs(r24 - I):.2f}")
print(f"R(24,1) {r24:.9f} vs Simpson on the same 25 readings {simp:.9f}")
assert abs(t24 - I) <= bt and abs(r24 - I) <= bs and abs(simp - r24) < 1e-12 * I
est, est1 = (T[2] - t24) / 3, r24 - R[3][2]                            # T(h) - I and R(24,1) - I, guessed
print(f"free estimate of T(24)'s error, (T(12) - T(24))/3: {est:+.6f} vs true {t24 - I:+.6f}, ratio {est / (t24 - I):.5f}")
print(f"free estimate of R(24,1)'s error, R(24,1) - R(24,2): {est1:+.3e} vs true {r24 - I:+.3e}, ratio {est1 / (r24 - I):.5f}")
assert abs(est / (t24 - I) - 1) < 2e-3 and abs(est1 / (r24 - I) - 1) < 1e-2
print("diagonal R(n,k) on the model curve, down to rounding (relative error):")
TT = [trap(v, 0, 24, 3 * 2 ** k) for k in range(8)]
RR = romberg(TT)
print("  " + ", ".join(f"n = {3 * 2 ** k}: {(RR[k][k] - I) / I:+.1e}" for k in range(8)))
assert abs(RR[7][7] - I) < 1e-13 * I
# What breaks: a speed rising from calm like sqrt(t) after a front at hour 0, over 1 hour
sq = romberg([trap(math.sqrt, 0, 1, 2 ** k) for k in range(1, 8)])
for j in range(3):
    rat = (sq[5][j] - 2 / 3) / (sq[6][j] - 2 / 3)
    print(f"sqrt(t) on [0, 1], column {j}: error at n = 128 {sq[6][j] - 2 / 3:+.2e}, ratio per halving {rat:.2f}")
    assert abs(rat - 2 ** 1.5) < 0.05                                   # stuck near h^1.5
per = trap(lambda t: 16 - 8 * math.cos(2 * W * t), 0, 24, 6)
print(f"periodic day 16 - 8 cos(pi t / 12): T(6) = {per:.12f} vs exact {16 * 24:.12f}")
assert abs(per - 384) < 1e-12 * 384
sm = [trap(lambda t: 30 / (2 + math.cos(2 * W * t)), 0, 24, n) - 720 / math.sqrt(3) for n in (6, 12, 24)]
print(f"smooth periodic day 30/(2 + cos(pi t / 12)), exact 720/sqrt3 = {720 / math.sqrt(3):.6f}: T(6), T(12), T(24) off " + ", ".join(f"{x:+.2e}" for x in sm))
assert abs(sm[0]) > 1e-2 and abs(sm[1]) < abs(sm[0]) / 2 ** 10 and abs(sm[2]) < abs(sm[1]) / 2 ** 20   # not exact; faster than any fixed power
wrong = [2 * t24 - T[2], (2.25 * t24 - trap_log(16)) / 1.25, (4 * t24 - trap_log(16)) / 3,
         R[3][1] + (R[3][1] - R[2][1]) / 3, t24 - T[2]]
print(f"mistake, error taken as h not h^2, 2T(24) - T(12): {wrong[0]:.6f}, off {wrong[0] - I:+.4f}")
print(f"right, steps 1.5 h and 1 h, (2.25T(24) - T(16))/1.25: {wrong[1]:.6f}, off {wrong[1] - I:+.2e}")
print(f"mistake, factor 4 on steps 1.5 h and 1 h: {wrong[2]:.6f}, off {wrong[2] - I:+.4f}")
print(f"mistake, second column with 3 not 15: {wrong[3]:.6f}, off {wrong[3] - I:+.2e}")
print(f"mistake, T(24) - T(12) taken as the error: {wrong[4]:+.6f}, true {t24 - I:+.6f}")
print("chart, model curve, n = 12, 24, 48, 96, 192; log10 h: " + ", ".join(f"{math.log10(24 / (3 * 2 ** k)):.2f}" for k in range(2, 7)))
for j in range(3):
    print(f"chart, column {j} log10 |relative error|: " + ", ".join(f"{math.log10(abs((RR[k][j] - I) / I)):.2f}" for k in range(2, 7)))
print("ALL CHECKS PASS")
