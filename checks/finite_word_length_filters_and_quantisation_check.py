# Finite word length -- the check behind the card.  Standard library only.
# The 5th-order Butterworth hum filter (fs 500 Hz, cutoff 20 Hz) built two ways:
# one direct form (one 5th-degree denominator) and a cascade of sections (two biquads + one 1st-order).
# Part 1: round the feedback coefficients to a step 2^-F and see where the poles go.
# Part 2: round each stored sum to 16 bits (q = 2^-15) and size the noise that adds.
# Roads: exact roots against the first-order sensitivity formula; A(1) as a sum and as a product;
# noise gain as a sum of squared impulse response and as a frequency-domain average; a bit-true run.
import math, cmath
FS, FC, N, Q, MV = 500.0, 20.0, 5, 2.0 ** -15, 5.0      # MV: full scale 1.0 = 5 mV
def rnd(v, q): return math.floor(v / q + 0.5) * q        # round to the nearest step, halves up
def polymul(p, r): return [sum(p[i] * r[k - i] for i in range(len(p)) if 0 <= k - i < len(r)) for k in range(len(p) + len(r) - 1)]
Wc = math.tan(math.pi * FC / FS)
sp = [Wc * cmath.exp(1j * math.pi * (2 * k + N + 1) / (2 * N)) for k in range(N)]
poles = [(1 + p) / (1 - p) for p in sp]                  # bilinear map of the analogue poles
a = [1 + 0j]
for p in poles: a = [u - p * v for u, v in zip(a + [0], [0] + a)]
a = [c.real for c in a]
b = [math.comb(N, k) * sum(a) / 2 ** N for k in range(N + 1)]
pr = [p for p in poles if abs(p.imag) < 1e-9][0]
pp = sorted([p for p in poles if p.imag > 1e-9], key=abs)
dens = [[1.0, -pr.real]] + [[1.0, -2 * p.real, abs(p) ** 2] for p in pp]
secs = [([c * sum(A) / 2 ** (len(A) - 1) for c in ([1, 1] if len(A) == 2 else [1, 2, 1])], A) for A in dens]
def roots(c, it=600):                                    # Durand-Kerner: all roots at once
    n = len(c) - 1; z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(it):
        nz = []
        for i in range(n):
            num = 0j
            for ck in c: num = num * z[i] + ck
            den = 1 + 0j
            for j in range(n):
                if j != i: den *= z[i] - z[j]
            nz.append(z[i] - num / den)
        z = nz
    return z
def sec_poles(A):                                        # quadratic formula, section by section
    if len(A) == 2: return [complex(-A[1])]
    d = A[1] ** 2 - 4 * A[2]; r = cmath.sqrt(d)
    return [(-A[1] + r) / 2, (-A[1] - r) / 2]
def move(new): return max(min(abs(p - q) for q in new) for p in poles)
def casc_poles(F): return [p for A in dens for p in sec_poles([rnd(c, 2.0 ** -F) for c in A])]
def dir_poles(F): return roots([rnd(c, 2.0 ** -F) for c in a])
print("a =", " ".join(f"{c:.6f}" for c in a))
print("sections: " + "; ".join(" ".join(f"{c:.6f}" for c in A[1:]) for A in dens))
print("pole radii " + " ".join(f"{abs(p):.4f}" for p in poles) + "; angles deg " + " ".join(f"{math.degrees(cmath.phase(p)):.2f}" for p in poles))
A1, A1p = sum(a), math.prod(abs(1 - p) for p in poles)  # A(1) two ways
print(f"A(1): sum of a {A1:.6f}, product of (1 - p) {A1p:.6f}; sections {' '.join(f'{sum(A):.4f}' for A in dens)}")
assert abs(A1 - A1p) < 1e-12
def dA(p, ps): return math.prod(abs(p - r) for r in ps if abs(r - p) > 1e-12)
p0 = pp[1]                                               # the pole nearest the unit circle
print(f"sensitivity of the 0.9259 pole, 1/|A'(p)|: direct {1 / dA(p0, poles):.1f}, biquad {1 / dA(p0, [p0, p0.conjugate()]):.3f}, "
      f"1/(2 rho sin theta) {1 / (2 * abs(p0) * math.sin(cmath.phase(p0))):.3f}")
def pred_move(F):                                        # road 2: first-order prediction of the move
    da = [rnd(c, 2.0 ** -F) - c for c in a]
    pred = -sum(da[k] * p0 ** (N - k) for k in range(1, N + 1)) / math.prod(p0 - r for r in poles if abs(r - p0) > 1e-12)
    return pred, min((r for r in dir_poles(F)), key=lambda r: abs(r - p0)) - p0
for F in (16, 10): print(f"F = {F}, move of the 0.9259 pole: predicted {abs(pred_move(F)[0]):.6f}, exact root {abs(pred_move(F)[1]):.6f}")
assert abs(pred_move(16)[0] - pred_move(16)[1]) < 0.05 * abs(pred_move(16)[1])
print("bits F | direct: largest radius, largest move | cascade: largest radius, largest move")
chart = []
for F in range(8, 17):
    d, c = dir_poles(F), casc_poles(F)
    chart.append((max(abs(r) for r in d), max(abs(r) for r in c)))
    print(f"  {F:2d}   |      {chart[-1][0]:.4f}  {move(d):.4f}          |       {chart[-1][1]:.4f}  {move(c):.6f}")
dmin = next(F for F in range(2, 30) if all(max(abs(r) for r in dir_poles(G)) < 1 - 1e-9 for G in range(F, 30)))
cmin = next(F for F in range(2, 30) if all(max(abs(r) for r in casc_poles(G)) < 1 - 1e-9 for G in range(F, 30)))
print(f"fewest fraction bits for stability at every F above: direct {dmin}, cascade {cmin}")
ar10 = [rnd(c, 2.0 ** -10) for c in a]
print(f"F = 10: step {2.0 ** -10:.6f}, worst shift of A(1) 5 x step/2 = {5 * 2.0 ** -11:.6f}; rounded a =", " ".join(f"{c:.6f}" for c in ar10), f"; A(1) = {sum(ar10):.6f}")
assert abs(sum(ar10)) < 1e-12 and cmin < dmin
for F in (12, 16):
    arF = [rnd(c, 2.0 ** -F) for c in a]
    print(f"F = {F}: gain at 0 Hz, direct {sum(b) / sum(arF):.4f}, cascade {math.prod(sum(B) / sum(rnd(c, 2.0 ** -F) for c in A) for B, A in secs):.4f}")
# ---- Part 2: roundoff noise ----
s2 = Q * Q / 12
def impulse(B, A, n=3000):
    y = []
    for i in range(n):
        y.append((B[i] if i < len(B) else 0) - sum(A[k] * y[i - k] for k in range(1, len(A)) if i >= k))
    return y
def gain_sum(B, A): return sum(v * v for v in impulse(B, A))
def freq(B, A, w): return abs(sum(v * cmath.exp(-1j * w * k) for k, v in enumerate(B)) / sum(v * cmath.exp(-1j * w * k) for k, v in enumerate(A)))
def gain_freq(B, A, M=4096): return sum(freq(B, A, 2 * math.pi * m / M) ** 2 for m in range(M)) / M  # road 3
def shaping(order):                                      # noise path from each section's rounding
    out = []
    for k, (B, A) in enumerate(order):
        num, den = [1.0], A
        for B2, A2 in order[k + 1:]: num, den = polymul(num, B2), polymul(den, A2)
        out.append((num, den))
    return out
Gd, Gdf = gain_sum([1.0], a), gain_freq([1.0], a)
vd = s2 * Gd
vc = sum(s2 * gain_sum(nu, de) for nu, de in shaping(secs))
vr = sum(s2 * gain_sum(nu, de) for nu, de in shaping(secs[::-1]))
print(f"q = 2^-15 = {Q:.4e} = {Q * MV * 1000:.4f} uV; one rounding: variance q^2/12 = {s2:.3e}, rms {math.sqrt(s2) / Q:.4f} q")
print(f"noise gain of 1/A(z): squared impulse response {Gd:.1f}, frequency average {Gdf:.1f}")
assert abs(Gd - Gdf) < 1e-6 * Gd
for k, (nu, de) in enumerate(shaping(secs)):
    print(f"  noise path from section {k + 1}: {gain_sum(nu, de):.3f} by impulse, {gain_freq(nu, de):.3f} by frequency")
def splitmix(seed):
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = seed; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        yield (z ^ (z >> 31)) >> 11
g = splitmix(2026); L = 40000
x = [((next(g) % 16384) - 8192) * Q for _ in range(L)]  # white input on the 16-bit grid, +-0.25
def run(B, A, xs, q, errs=None):                         # direct form I, wide accumulator; q = 0: exact
    y = []
    for n in range(len(xs)):
        acc = sum(B[k] * xs[n - k] for k in range(len(B)) if n >= k) - sum(A[k] * y[n - k] for k in range(1, len(A)) if n >= k)
        y.append(rnd(acc, q) if q else acc)              # one rounding, when the output is stored
        if errs is not None: errs.append(y[-1] - acc)
    return y
def var(e): m = sum(e) / len(e); return sum((v - m) ** 2 for v in e) / len(e)
ed = [u - v for u, v in zip(run(b, a, x, Q), run(b, a, x, 0))]
errs, yq, yf = [], x, x
for B, A in secs: yq, yf = run(B, A, yq, Q, errs), run(B, A, yf, 0)
ec = [u - v for u, v in zip(yq, yf)]
print(f"rounding errors seen: {len(errs)}, mean {sum(errs) / len(errs) / Q:+.4f} q, variance / (q^2/12) {var(errs) / s2:.4f}")
print(f"direct form, 1 rounding:   predicted rms {math.sqrt(vd) / Q:.1f} q, simulated {math.sqrt(var(ed)) / Q:.1f} q")
print(f"cascade, 3 roundings:      predicted rms {math.sqrt(vc) / Q:.2f} q, simulated {math.sqrt(var(ec)) / Q:.2f} q")
assert abs(var(ed) / vd - 1) < 0.1 and abs(var(ec) / vc - 1) < 0.1 and abs(var(errs) / s2 - 1) < 0.02 and abs(sum(errs) / len(errs)) < 0.01 * Q
print(f"in the ECG (1.0 = {MV:.0f} mV): direct {math.sqrt(vd) * MV * 1000:.1f} uV rms, cascade {math.sqrt(vc) * MV * 1000:.2f} uV rms; "
      f"ratio {math.sqrt(vd / vc):.1f}, {10 * math.log10(vd / vc):.1f} dB")
hum = 500 / math.sqrt(1 + (math.tan(math.pi * 50.2 / FS) / Wc) ** 10)  # uV of 0.5 mV hum left at 50.2 Hz
print(f"hum left by the exact filter {hum:.2f} uV; direct-form noise / hum {math.sqrt(vd) * MV * 1000 / hum:.1f}")
def peak(B, A): return max(freq(B, A, math.pi * i / 2000) for i in range(2001))
print("peak gain of each section: " + " ".join(f"{peak(B, A):.3f}" for B, A in secs) + f"; sections in reverse order {math.sqrt(vr) / Q:.2f} q")
print(f"breaks: direct form at F = 9: largest radius {max(abs(r) for r in dir_poles(9)):.4f}")
print(f"try: 24-bit words: direct {math.sqrt(vd) * MV * 1000 / 256:.3f} uV, cascade {math.sqrt(vc) * MV * 1000 / 256:.4f} uV; "
      f"direct form II inner gain at 0 Hz 1/A(1) = {1 / A1:.1f}, {math.ceil(math.log2(1 / A1))} bits of headroom")
A3 = dens[2]; y1, y2 = 1000, 0                           # zero input into the 0.9259 biquad, integers in q
for n in range(3000): y1, y2 = -math.floor(A3[1] * y1 + A3[2] * y2 + 0.5), y1
print(f"zero-input biquad from 1000 q: stuck at {y1} q after 3000 steps ({y1 * Q * MV * 1000:.2f} uV); bound 0.5/A3(1) = {0.5 / sum(A3):.2f} q")
assert y1 != 0 and y1 == y2 and abs(y1) <= 0.5 / sum(A3)
for k, name in enumerate(("direct ", "cascade")): print(f"chart, {name} " + " ".join(f"{r[k]:.4f}" for r in chart))
print("ALL CHECKS PASS")
