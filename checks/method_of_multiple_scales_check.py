# Multiple scales -- the check behind the card.  Standard library only.
# A 2 kg instrument on a stiffening rubber mount, x'' + x + eps x^3 = 0 (Duffing),
# then the oscillator x'' - eps (1 - x^2) x' + x = 0 (van der Pol).  Roads: the
# two-timing formulas, RK4 stepping, an exact period by Gauss's AGM, and the
# solvability averages done again by numerical quadrature.
from math import pi, sin, cos, sqrt, exp, log

MASS, K, K3, A = 2.0, 800.0, 8.0e5, 0.010   # kg, N/m, N/m^3, release in m
W0 = sqrt(K / MASS)                          # natural frequency, rad/s
EPS = K3 * A * A / K                         # the small number: cubic over linear force
H = 0.001                                    # RK4 step, in time units 1/W0

def duffing(e):
    return lambda x, v: (v, -x - e * x ** 3)

def vdp(e):
    return lambda x, v: (v, e * (1.0 - x * x) * v - x)

def rk4(f, x, v, h):                         # one RK4 step of x' = v, v' = g(x, v)
    a1, b1 = f(x, v)
    a2, b2 = f(x + 0.5 * h * a1, v + 0.5 * h * b1)
    a3, b3 = f(x + 0.5 * h * a2, v + 0.5 * h * b2)
    a4, b4 = f(x + h * a3, v + h * b3)
    return x + h * (a1 + 2 * a2 + 2 * a3 + a4) / 6.0, v + h * (b1 + 2 * b2 + 2 * b3 + b4) / 6.0

def peaks(f, x, v, tmax):                    # (time, height) of every maximum of x
    out, n = [], 0
    while n * H < tmax:
        x2, v2 = rk4(f, x, v, H)
        if v > 0.0 >= v2:                    # bisect the step to land on v = 0
            lo, hi = 0.0, H
            for _ in range(50):
                mid = 0.5 * (lo + hi)
                if rk4(f, x, v, mid)[1] > 0.0:
                    lo = mid
                else:
                    hi = mid
            out.append((n * H + lo, rk4(f, x, v, lo)[0]))
        x, v, n = x2, v2, n + 1
    return out

def agm(p, q):
    for _ in range(30):
        p, q = 0.5 * (p + q), sqrt(p * q)
    return p

def exact_period(e):                         # Duffing from x = 1 at rest, by elliptic K and AGM
    m = e / (2.0 * (1.0 + e))
    return 4.0 * (pi / (2.0 * agm(1.0, sqrt(1.0 - m)))) / sqrt(1.0 + e)

def tt_period(e):                            # two-timing: omega = 1 + 3 eps / 8
    return 2.0 * pi / (1.0 + 3.0 * e / 8.0)

def average(h, a, part):                     # (1/2pi) integral of h(a cos th, -a sin th) times sin or cos
    n, s = 64, 0.0
    for k in range(n):
        th = 2.0 * pi * (k + 0.5) / n
        s += h(a * cos(th), -a * sin(th)) * (sin(th) if part == "sin" else cos(th))
    return s / n

def plain(t, e):                             # regular expansion, two terms: grows like t sin t
    return cos(t) + e * ((cos(3 * t) - cos(t)) / 32.0 - 3.0 * t * sin(t) / 8.0)

def amp(t, a0, e):                           # van der Pol slow amplitude, solved exactly
    return 2.0 / sqrt(1.0 + (4.0 / (a0 * a0) - 1.0) * exp(-e * t))

T0 = 1.0 / W0
print(f"mount: m = {MASS:.1f} kg, k = {K:.0f} N/m, k3 = {K3:.0f} N/m^3, release A = {A * 1000:.1f} mm")
print(f"w0 = sqrt(k/m) = {W0:.4f} rad/s = {W0 / (2 * pi):.4f} Hz; time unit 1/w0 = {T0:.4f} s")
print(f"eps = k3 A^2 / k = {EPS:.4f}")
w = 1.0 + 3.0 * EPS / 8.0
pk = peaks(duffing(EPS), 1.0, 0.0, 61.0)
t_rk, t_ex, t_tt = pk[9][0] / 10.0, exact_period(EPS), tt_period(EPS)
print(f"two-timing: 3 eps/8 = {3 * EPS / 8:.6f}; omega = {w:.6f}, times w0 = {w * W0:.4f} rad/s")
print(f"two-timing: period {t_tt:.4f} units = {t_tt * T0:.5f} s; f = {w * W0 / (2 * pi):.4f} Hz")
print(f"exact, by AGM: period {t_ex:.4f} units = {t_ex * T0:.5f} s")
print(f"RK4, 10 peaks: period {t_rk:.4f} units; lowest peak {min(p[1] for p in pk):.6f}, highest {max(p[1] for p in pk):.6f}")
err1, err2 = (t_ex - tt_period(EPS)) / t_ex, (exact_period(EPS / 2) - tt_period(EPS / 2)) / exact_period(EPS / 2)
print(f"two-timing period short by {err1 * 100:.4f}% at eps = 0.1, {err2 * 100:.4f}% at eps = 0.05; ratio {err1 / err2:.2f}")
c38 = -average(lambda x, v: -x ** 3, 1.0, "cos")
print(f"quadrature: Duffing phase drift per unit slow time at a = 1: {c38:.6f} (3/8 = {3 / 8:.6f})")
g = lambda a: average(lambda x, v: (1.0 - x * x) * v, a, "sin") * -1.0
print(f"quadrature: van der Pol growth at a = 1: {g(1.0):.6f} (a/2 - a^3/8 = {0.5 - 1 / 8:.6f})")
lo, hi = 1.0, 3.0
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if g(mid) > 0.0 else (lo, mid)
print(f"quadrature + bisection: growth is zero at a = {lo:.6f}")

f, x, v, gaps = duffing(EPS), 1.0, 0.0, []
for blk in range(8):                         # worst gap from RK4 in each 10-unit window
    worst = [0.0, 0.0, 0.0]
    for k in range(10000):
        x, v = rk4(f, x, v, H)
        t = blk * 10.0 + (k + 1) * H
        for j, y in enumerate((cos(t), plain(t, EPS), cos(w * t))):
            worst[j] = max(worst[j], abs(y - x))
    gaps.append(worst)
print("chart, window ends at t   " + " ".join(f"{10 * (i + 1):5d}" for i in range(8)))
for j, lab in enumerate(("fixed frequency 1  ", "plain expansion    ", "two-timing         ")):
    print("chart, gap " + lab + " " + " ".join(f"{gp[j]:5.2f}" for gp in gaps))
print(f"plain expansion reaches {max(abs(plain(70 + k * 0.001, EPS)) for k in range(10001)):.4f} in t = 70..80; true peak stays 1")

up, down = peaks(vdp(EPS), 1.0, 0.0, 76.0)[:12], peaks(vdp(EPS), 3.0, 0.0, 76.0)[:12]
print("chart, peak number        " + " ".join(f"{i + 1:5d}" for i in range(12)))
print("chart, peak time from 1   " + " ".join(f"{p[0]:5.1f}" for p in up))
for lab, ps, a0 in (("RK4 from 1    ", up, 1.0), ("formula from 1", up, 1.0), ("RK4 from 3    ", down, 3.0), ("formula from 3", down, 3.0)):
    print("chart, " + lab + "     " + " ".join(f"{(p[1] if 'RK4' in lab else amp(p[0], a0, EPS)):5.2f}" for p in ps))
vgap = max(abs(p[1] - amp(p[0], a0, EPS)) for ps, a0 in ((up, 1.0), (down, 3.0)) for p in ps)
print(f"worst gap, RK4 peak vs slow amplitude, both starts: {vgap:.4f}")
t19 = log(3.0 / (4.0 / 1.9 ** 2 - 1.0)) / EPS
print(f"from a = 1, the amplitude reaches 1.9 at t = {t19:.2f} units")
late = peaks(vdp(EPS), 1.0, 0.0, 300.0)
lp = (late[-1][0] - late[-11][0]) / 10.0
print(f"settled: peak {late[-1][1]:.4f}; period {lp:.4f} (2 pi = {2 * pi:.4f}, 2 pi (1 + eps^2/16) = {2 * pi * (1 + EPS * EPS / 16):.4f})")

for e in (1.0, 3.0):
    print(f"beyond: eps = {e:.0f} (release {sqrt(e * K / K3) * 1000:.1f} mm): two-timing period {tt_period(e):.4f}, exact {exact_period(e):.4f}, short by {(1 - tt_period(e) / exact_period(e)) * 100:.2f}%")
print(f"wrong: 3/4 for 3/8        period {2 * pi / (1 + 3 * EPS / 4):.4f} units = {2 * pi / (1 + 3 * EPS / 4) * T0:.5f} s")
print(f"wrong: frequency kept 1   period {2 * pi:.4f} units = {2 * pi * T0:.5f} s, {(2 * pi / t_ex - 1) * 100:.2f}% long")

assert abs(t_rk - t_ex) < 1e-6, "RK4 period must match the AGM period"
assert abs(c38 - 3.0 / 8.0) < 1e-12, "quadrature must give the 3/8 drift coefficient"
assert abs(lo - 2.0) < 1e-9, "van der Pol growth must vanish at amplitude 2"
assert 3.5 < err1 / err2 < 4.5, "two-timing period error must shrink like eps^2"
assert gaps[-1][2] < 0.1 and gaps[-1][1] > 2.0, "two-timing must hold where the plain expansion fails"
assert vgap < 0.05, "slow amplitude must track the RK4 peaks of van der Pol"
assert abs(late[-1][1] - 2.0) < 0.01, "van der Pol must settle at amplitude 2"
print("ALL CHECKS PASS")
