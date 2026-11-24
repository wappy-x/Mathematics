# Measured Bode plot of the radiator room: Welch cross-spectrum over input spectrum, and coherence.
# Standard library only. Roads: (1) the plant's closed-form G; (2) a noise-free sine test simulated
# in time; (3) Welch's estimate from one noisy logged day; Monte Carlo checks the error-bar formula.
import math, cmath
M64 = (1 << 64) - 1
class Rng:  # SplitMix64, then Box-Muller for Gaussian noise
    def __init__(s, seed): s.s = seed
    def u64(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64; z = s.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def uni(s): return ((s.u64() >> 11) + 0.5) / 2.0**53
    def gauss(s): return math.sqrt(-2 * math.log(s.uni())) * math.cos(2 * math.pi * s.uni())

A, B, SIG = 0.9, 0.5, 0.1     # room: y_k = 0.9 y_(k-1) + 0.5 u_(k-1) + e_k, e_k noise 0.1 C
N, HOLD, L, ND = 1440, 5, 180, 8  # one day of minutes; valve held 5 min; 8 segments of 180 min
def day(seed, hold=HOLD, sig=SIG):
    r = Rng(seed); u = []; y = [0.0]
    for _ in range(N // hold): u += [1.0 if r.u64() >> 63 else -1.0] * hold
    for k in range(1, N): y.append(A * y[-1] + B * u[k - 1] + sig * r.gauss())
    mu, my = sum(u) / N, sum(y) / N
    return [v - mu for v in u], [v - my for v in y]
W = [0.5 - 0.5 * math.cos(2 * math.pi * n / L) for n in range(L)]  # Hann taper
CS = [math.cos(2 * math.pi * n / L) for n in range(L)]
SN = [math.sin(2 * math.pi * n / L) for n in range(L)]
def dft(x, k, win=W):
    re = im = 0.0
    for n in range(L):
        re += win[n] * x[n] * CS[k * n % L]; im -= win[n] * x[n] * SN[k * n % L]
    return complex(re, im)
def welch(u, y, k, nseg=ND, win=W):  # returns (G estimate, coherence, sqrt(Syy/Suu))
    suu = syy = 0.0; syu = 0j
    for m in range(nseg):
        U, Y = dft(u[m * L:(m + 1) * L], k, win), dft(y[m * L:(m + 1) * L], k, win)
        suu += U.real ** 2 + U.imag ** 2; syy += Y.real ** 2 + Y.imag ** 2
        syu += Y * U.conjugate()
    return syu / suu, (syu.real ** 2 + syu.imag ** 2) / (suu * syy), math.sqrt(syy / suu)
def G(k, a=A, b=B, d=1):
    z = cmath.exp(-2j * math.pi * k / L); return b * z ** d / (1 - a * z)
def true_coh(k):  # 1 / (1 + noise power / valve power through b): see Step 3
    w = 2 * math.pi * k / L; suu = (math.sin(HOLD * w / 2) / math.sin(w / 2)) ** 2 / HOLD
    return 1 / (1 + SIG ** 2 / (B ** 2 * suu))
db = lambda g: 20 * math.log10(abs(g))
f1 = lambda x: "0.0" if f"{x:.1f}" == "-0.0" else f"{x:.1f}"
deg = lambda g: math.degrees(cmath.phase(g))
f = lambda k: k / L  # cycles per minute

# ---- road 2: a sine test on the noise-free room, 0.05 cycles/min (period 20 min) ----
y, acc = 0.0, 0j
for n in range(1, 3000):  # valve u_n = sin(2 pi f n); keep the last 2000 min, 100 whole periods
    y = A * y + B * math.sin(2 * math.pi * 9 * (n - 1) / L)
    if n >= 1000: acc += y * cmath.exp(-2j * math.pi * 9 * n / L)
gs = 2j * acc / 2000  # the output's sine part, as a complex gain
print(f"sine test at {f(9):.3f} c/min: gain {abs(gs):.4f} C per kW, phase {deg(gs):.2f} deg")
print(f"formula   at {f(9):.3f} c/min: gain {abs(G(9)):.4f} C per kW, phase {deg(G(9)):.2f} deg")
assert abs(gs - G(9)) < 1e-6
w = 2 * math.pi * f(9); re, im = 1 - A * math.cos(w), A * math.sin(w)  # the hand table
print(f"hand: {f(9)} c/min = {1000 * f(9) / 60:.3f} mHz, w {w:.4f} rad/min, cos {math.cos(w):.4f}, sin {math.sin(w):.4f},"
      f" 1-0.9e^-jw = {re:.4f} + {im:.4f}j, size {math.hypot(re, im):.4f}, angle {math.degrees(math.atan2(im, re)):.2f} deg,"
      f" delay angle {math.degrees(w):.2f} deg")

# ---- road 3: Welch on the logged day ----
u, yd = day(2026)
est = {k: welch(u, yd, k) for k in range(1, 90)}  # bins 1..89: 0 is the mean, 90 is real-valued
print("  k  f c/min  period min  true gain  meas gain  true deg  meas deg  coherence  theory  err %")
for k in (2, 5, 9, 18, 27, 36, 54, 72, 89):
    g, c, _ = est[k]
    print(f"{k:3d}  {f(k):.4f}  {1 / f(k):9.1f}  {abs(G(k)):9.3f}  {abs(g):9.3f}  {deg(G(k)):8.1f}"
          f"  {deg(g):8.1f}  {c:9.3f}  {true_coh(k):6.3f}  {100 * abs(g - G(k)) / abs(G(k)):5.1f}")
trust, rest = [k for k in est if est[k][1] >= 0.9], [k for k in est if est[k][1] < 0.9]
def med(ks):  # median error: the middle value, or the mean of the two middle values
    e = sorted(abs(est[k][0] - G(k)) / abs(G(k)) for k in ks); return (e[(len(e) - 1) // 2] + e[len(e) // 2]) / 2
top = next(k for k in est if k not in trust) - 1
print(f"trusted bins (coherence >= 0.9): {len(trust)} of 89, unbroken from bin 1 to bin {top}"
      f" ({f(top):.3f} c/min); median error {100 * med(trust):.1f}%")
print(f"untrusted bins: {len(rest)}, median error {100 * med(rest):.1f}%")
assert med(trust) < 0.08 and med(rest) > 2 * med(trust)
assert all(0 <= est[k][1] <= 1 + 1e-12 for k in est)  # Cauchy-Schwarz
bar = lambda c: 100 * math.sqrt((1 - c) / (c * 2 * ND))
print(f"error bar at 0.05 c/min: sqrt(1-c)/(sqrt(c) sqrt(2*{ND})) = {bar(est[9][1]):.1f}%;"
      f" at 0.4 c/min, from its measured coherence {est[72][1]:.3f}: {bar(est[72][1]):.1f}%")

# ---- Monte Carlo: 300 more days; error bar and the coherence of unrelated records ----
mc = {9: [], 30: []}; null = []
for s in range(300):
    uu, yy = day(5000 + s)
    for k in mc: mc[k].append(welch(uu, yy, k)[0])
    _, yo = day(9000 + s); null.append(welch(uu, yo, 9)[1])
for k in mc:
    rel = [abs(g) / abs(G(k)) for g in mc[k]]; m = sum(rel) / len(rel)
    sd = math.sqrt(sum((r - m) ** 2 for r in rel) / (len(rel) - 1)); c = true_coh(k)
    pred = math.sqrt((1 - c) / (c * 2 * ND))
    print(f"bin {k:2d} ({f(k):.3f} c/min): true coherence {c:.3f}, error bar formula {100 * pred:.1f}%,"
          f" scatter over 300 days {100 * sd:.1f}%")
    assert 0.8 * pred < sd < 1.4 * pred
mn = sum(null) / len(null)
print(f"coherence of unrelated records: mean {mn:.3f}, theory 1/{ND} = {1 / ND:.3f}")
assert abs(mn - 1 / ND) < 0.03

# ---- fit a first-order-plus-delay model G = b z^-d / (1 - a z^-1) by linear least squares ----
def fit(ks, d, e=est):
    s11 = s12 = s22 = r1 = r2 = 0.0
    for k in ks:
        g = e[k][0]; z = cmath.exp(-2j * math.pi * k / L); c1, c2 = g * z, z ** d
        s11 += abs(c1) ** 2; s12 += (c1 * c2.conjugate()).real; s22 += abs(c2) ** 2
        r1 += (g * c1.conjugate()).real; r2 += (g * c2.conjugate()).real
    det = s11 * s22 - s12 ** 2; a = (r1 * s22 - r2 * s12) / det; b = (s11 * r2 - s12 * r1) / det
    res = sum(abs(e[k][0] - G(k, a, b, d)) ** 2 for k in ks)
    return a, b, res
for label, ks in (("trusted", trust), ("all 89 ", list(est))):
    for d in (0, 1, 2):
        a, b, res = fit(ks, d)
        print(f"fit {label} d={d}: a {a:.4f} b {b:.4f} gain {b / (1 - a):.2f} C/kW"
              f" lag {-1 / math.log(a):.2f} min residual {res:.4f}")
a, b, _, d = min((fit(trust, d) + (d,) for d in (0, 1, 2)), key=lambda t: t[2])
print(f"best delay d={d} min; true a {A} b {B} gain {B / (1 - A):.2f} C/kW lag {-1 / math.log(A):.2f} min")
assert d == 1 and abs(a - A) < 0.02 and abs(b - B) < 0.05 and fit(trust, 1)[2] < fit(trust, 0)[2]

# ---- what breaks ----
one = [welch(u, yd, k, 1)[1] for k in range(1, 90)]
print(f"one segment only: coherence min {min(one):.6f} max {max(one):.6f}")
assert abs(min(one) - 1) < 1e-9
print(f"at {f(33):.3f} c/min: true gain {abs(G(33)):.3f}, Syu/Suu {abs(est[33][0]):.3f},"
      f" sqrt(Syy/Suu) {est[33][2]:.3f}")

# ---- chart points ----
ks = list(range(3, 90, 3))
print("chart, f c/min", " ".join(f"{f(k):.3f}" for k in ks))
print("chart, true dB", " ".join(f1(db(G(k))) for k in ks))
print("chart, meas dB", " ".join(f1(db(est[k][0])) for k in ks))
print("chart, coherence", " ".join(f"{est[k][1]:.2f}" for k in ks))
# ---- the Try box, and the noise switched off: the same day re-made with one setting changed ----
for name, seed, hold, sig, win, bins in (("valve held 1 min", 2026, 1, SIG, W, (36,)), ("noise 0.3 C", 2026, HOLD, 0.3, W, ()),
        ("no taper", 2026, HOLD, SIG, [1.0] * L, (9,)), ("seed 7", 7, HOLD, SIG, W, ()), ("noise off", 2026, HOLD, 0.0, W, (2, 36, 72))):
    uu, yy = day(seed, hold, sig); e = {k: welch(uu, yy, k, ND, win) for k in range(1, 90)}; ks = [k for k in e if e[k][1] >= 0.9]
    a, b, _, d = min((fit(ks, d, e) + (d,) for d in (0, 1, 2)), key=lambda t: t[2])
    print(f"try {name}:" + "".join(f" bin {k} error {100 * abs(e[k][0] - G(k)) / abs(G(k)):.1f}%, coherence {e[k][1]:.3f};" for k in bins)
          + f" {len(ks)} trusted bins; fit {b / (1 - a):.2f} C/kW, {-1 / math.log(a):.2f} min")
print("ALL CHECKS PASS")
