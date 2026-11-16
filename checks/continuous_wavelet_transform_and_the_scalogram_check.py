# Continuous wavelet transform -- the check behind the card.  Standard library only.
# A synthetic, illustrative earthquake record (ground velocity, mm/s): a P wave at
# 8 Hz near 4 s, an S wave at 2 Hz near 10 s, a surface wave at 0.5 Hz near 16 s.
# Morlet wavelet; scale a in seconds matches frequency 1/a in hertz.
# Every transform and integral is written out; cmath only supplies exp.
from math import exp, sqrt, pi, log, cos
import cmath

K = pi ** -0.25 * sqrt(2 * pi)               # peak height of the Morlet spectrum, at 1 Hz
KAP = exp(-2 * pi * pi)                      # the correction that makes the mean zero
WAVES = [(0.5, 8.0, 4.0, 0.2), (1.0, 2.0, 10.0, 0.8), (0.8, 0.5, 16.0, 3.2)]  # A, nu, c, s

def record(t):                               # sum of A e^(-(t-c)^2 / 2s^2) cos(2 pi nu t)
    return sum(A * exp(-(t - c) ** 2 / (2 * s * s)) * cos(2 * pi * nu * t) for A, nu, c, s in WAVES)

def psi(t):                                  # Morlet mother wavelet (complex)
    return pi ** -0.25 * (cmath.exp(2j * pi * t) - KAP) * exp(-t * t / 2)

def psi_hat(xi):                             # its transform, xi in hertz
    return K * (exp(-2 * pi * pi * (xi - 1) ** 2) - KAP * exp(-2 * pi * pi * xi * xi))

def bump_hat(xi):                            # a plain bell-curve bump: mean not zero
    return K * exp(-2 * pi * pi * xi * xi)

def W(a, b):                                 # road 1: closed form, Gaussian integrals in u = t - b
    tot = 0j
    for A, nu, c, s in WAVES:
        d, al = c - b, 1 / (2 * s * s) + 1 / (2 * a * a)
        for sg in (1, -1):                   # cos = (e^(+i..) + e^(-i..)) / 2
            for m, wt in ((1, 1.0), (0, -KAP)):   # conjugate wavelet = e^(-2 pi i u/a) - KAP
                be = d / (s * s) + 2j * pi * (sg * nu - m / a)
                ga = -d * d / (2 * s * s) + 2j * pi * sg * nu * b
                tot += A / 2 * wt * sqrt(pi / al) * cmath.exp(be * be / (4 * al) + ga)
    return tot * pi ** -0.25 / sqrt(a)

def W_sum(a, b, fs=50.0, T=30.0):            # road 2: the defining integral as a sum of samples
    return sum(record(k / fs) * psi((k / fs - b) / a).conjugate()
               for k in range(int(T * fs) + 1)) / (fs * sqrt(a))

def simpson(g, lo, hi, n):
    h = (hi - lo) / n
    return h / 3 * (g(lo) + g(hi) + sum((4 if i % 2 else 2) * g(lo + i * h) for i in range(1, n)))

def C_psi(hat, eps, n):                      # 1/2 integral over eps < |xi| < 4 of |hat|^2/|xi|, xi = e^u
    g = lambda u: 0.5 * (hat(exp(u)) ** 2 + hat(-exp(u)) ** 2)
    return simpson(g, log(eps), log(4.0), n)

def double(dv, r, ts, lo=40.0, hi=10.0):     # integral of |W|^2 db da/a^2, and the rebuild at times ts
    vlo, vhi, blo, bhi = log(1 / lo), log(hi), -10.0, 40.0   # lo Hz to 1/hi Hz; b step r * a
    E, R = 0.0, [0j] * len(ts)
    for i in range(round((vhi - vlo) / dv) + 1):
        a = exp(vlo + i * dv)                # da / a^2 = dv / a
        db = r * a
        for j in range(round((bhi - blo) / db) + 1):
            b = blo + j * db
            w = W(a, b)
            E += abs(w) ** 2 / a * dv * db
            for k, t in enumerate(ts):
                R[k] += w * psi((t - b) / a) * dv * db / (a * sqrt(a))
    return E, R

def show(name, *vs, d=6):
    print(f"{name:<42}" + "".join(f" {v:>12.{d}f}" for v in vs))

# ---- the admissibility constant, and the bump that fails it ----
C1, C2 = C_psi(psi_hat, 1e-6, 2000), C_psi(psi_hat, 1e-6, 4000)
show("C_psi Morlet, 2000 and 4000 steps", C1, C2, d=9)
for e in (1e-2, 1e-4, 1e-6):
    show(f"cut-off {e:.6f} Hz: C Morlet, C bump", C_psi(psi_hat, e, 4000), C_psi(bump_hat, e, 4000))
show("psi_hat(0): Morlet, uncorrected, bump", psi_hat(0.0), K * KAP, bump_hat(0.0), d=12)
assert abs(C1 - C2) < 1e-9 and abs(psi_hat(0.0)) < 1e-15 and abs(C2 - 0.5 * simpson(
    lambda x: psi_hat(x) ** 2 / x if x > 0 else 0.0, 0.0, 4.0, 40000)) < 1e-8
assert C_psi(bump_hat, 1e-6, 4000) - C_psi(bump_hat, 1e-4, 4000) > 16   # grows like ln(1/eps)
Cp, Cm = (simpson(lambda u: psi_hat(sg * exp(u)) ** 2, log(1e-6), log(4.0), 4000) for sg in (1, -1))
show("C_+, C_-: scale totals, xi > 0 and xi < 0", Cp, Cm)
assert Cm < 1e-12                            # the complex Morlet passes positive frequencies only

# ---- energy and rebuild: the transform loses nothing ----
E1 = simpson(lambda t: record(t) ** 2, -10, 40, 10000)
E2 = simpson(lambda t: record(t) ** 2, -10, 40, 20000)
show("energy of the record, 10000 and 20000 steps", E1, E2)
ts = (4.05, 10.1, 16.3)
Ec, Rc = double(0.04, 0.5, ts)
Ef, Rf = double(0.02, 0.25, ts)
show("scalogram energy: coarse, fine grid", Ec, Ef)
Ew = double(0.04, 0.5, (), 80.0, 20.0)[0]    # second cut-off: 80 Hz to 0.05 Hz
show("coarse, widened to 80 to 0.05 Hz; change", Ew, abs(Ew - Ec), d=9)
assert abs(Ew - Ec) < 1e-9
show("C_psi x energy", C2 * E2)
show("scalogram energy / energy; same, no 1/2", Ef / E2, Ef / E2 / (2 * C2))
for t, r in zip(ts, Rf):
    show(f"record at {t:.2f} s: true, rebuilt", record(t), r.real / C2)
    assert abs(r.real / C2 - record(t)) < 1e-5
assert abs(Ef - C2 * E2) < 1e-5 * E2 and abs(E1 - E2) < 1e-9

# ---- the scalogram, and reading it ----
freqs = [8 * 2 ** (-k / 2) for k in range(9)]
grid = [[abs(W(1 / f, b)) ** 2 * f for b in range(31)] for f in freqs]   # |W|^2 / a
top = max(max(r) for r in grid)
print("normalised scalogram |W|^2/a, percent of its peak; time 0 to 30 s across")
for f, r in zip(freqs, grid):
    print(f"{f:5.2f} Hz " + "".join(f"{int(v / top * 100 + 0.5):4d}" for v in r))
raw, nrm = [], []
for A, nu, c, s in WAVES:
    a = 1 / nu
    w, ws = W(a, c), W_sum(a, c)
    raw.append(abs(w) ** 2); nrm.append(abs(w) ** 2 / a)
    print(f"{nu:.1f} Hz wave at {c:.0f} s, scale a = {a:.3f} s")
    show("  |W|: closed form, sum of samples, gap", abs(w), abs(ws), abs(w - ws), d=9)
    assert abs(w - ws) < 1e-6
    se = (1 / s ** 2 + 1 / a ** 2) ** -0.5   # combined envelope width
    hand = A / 2 * K * se / sqrt(a)          # one-burst formula: the other bursts left out
    show("  by hand: sqrt a, envelope width, |W|", sqrt(a), se, hand, d=4)
    show("  s/a; one-burst |W|, gap to full |W|", s / a, hand, abs(abs(w) - hand), d=9)
    show("  amplitude read 2|W|/(K sqrt a), by hand", 2 * abs(w) / (K * sqrt(a)), A * se / a, d=4)
    assert abs(2 * abs(w) / (K * sqrt(a)) - A * se / a) < 1e-6
    show("  time spread a/sqrt2 s, band 1/(2 sqrt2 pi a) Hz", a / sqrt(2), 1 / (2 * sqrt(2) * pi * a), d=4)
show("raw |W|^2, percent of largest: P, S, surface", *[100 * x / max(raw) for x in raw], d=1)
show("|W|^2/a, percent of largest: P, S, surface", *[100 * x / max(nrm) for x in nrm], d=1)
show("K = pi^(-1/4) sqrt(2 pi); envelope factor", K, (1 + 1 / 1.6 ** 2) ** -0.5)
show("S - P time s; distance km at 6.0, 3.5 km/s", 6.0, 6.0 * 6.0 * 3.5 / 2.5, d=1)
fine = [[abs(W(1 / (8 * 2 ** (-k / 4)), j / 4)) ** 2 * 8 * 2 ** (-k / 4) for j in range(121)] for k in range(17)]
fmax = max(max(r) for r in fine)
pk = [(16, 0), (40, 8), (64, 16)]              # (time index, row index) of the three peaks
print("figure, 121 x 17 cells, 0 to 30 s by 8 to 0.5 Hz; peak shades "
      + ", ".join(f"{fine[k][j] / fmax * 100:.1f}% at ({j / 4:.2f} s, {8 * 2 ** (-k / 4):.2f} Hz)" for j, k in pk))
print("ALL CHECKS PASS")
