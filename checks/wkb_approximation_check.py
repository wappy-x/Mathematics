# WKB approximation -- the check behind the card.  Standard library only.
# A string whose mass per length grows as (1 + x)^2 obeys y'' + lam^2 (1 + x)^2 y = 0
# on [0, 1] with y(0) = y(1) = 0.  Its eigenvalues lam_n are found three ways: the WKB
# rule lam * S = n pi, RK4 shooting, and the exact Bessel-function solution.  Then two
# places where WKB fails: a sudden jump in mass, and a turning point (Airy).
from math import pi, sqrt, sin, log2, atan

def q_str(x): return (1.0 + x) ** 2                 # mass per length over its light-end value

def simpson(f, a, b, n=1000):                        # phase integral S = integral of sqrt(q)
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))

def shoot(lam, q, n=2000, every=0):                  # RK4 on y'' = -lam^2 q y, y(0) = 0, y'(0) = lam
    h, y, v, out = 1.0 / n, 0.0, lam, [0.0]
    def f(x, y, v): return v, -lam * lam * q(x) * y
    for i in range(n):
        x = i * h
        k1 = f(x, y, v)
        k2 = f(x + h / 2, y + h / 2 * k1[0], v + h / 2 * k1[1])
        k3 = f(x + h / 2, y + h / 2 * k2[0], v + h / 2 * k2[1])
        k4 = f(x + h, y + h * k3[0], v + h * k3[1])
        y += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        if every and (i + 1) % every == 0: out.append(y)
    return out if every else y

def bisect(g, a, b):                                 # one sign change inside [a, b]
    ga = g(a)
    for _ in range(60):
        m = 0.5 * (a + b)
        gm = g(m)
        if (gm < 0) == (ga < 0): a, ga = m, gm
        else: b = m
    return 0.5 * (a + b)

def J(nu, z):                                        # Bessel series, without its constant factor
    t, s = (z / 2) ** nu, 0.0
    for m in range(80):
        s += t
        t *= -(z / 2) ** 2 / ((m + 1) * (m + 1 + nu))
    return s

def bessel(lam):                                     # y = sqrt(t) [A J(1/4, lam t^2/2) + B J(-1/4, .)], t = 1 + x
    return J(0.25, lam / 2) * J(-0.25, 2 * lam) - J(-0.25, lam / 2) * J(0.25, 2 * lam)

def peaks(ys):                                       # largest |y| in each lobe
    out, cur = [], 0.0
    for a, b in zip(ys, ys[1:]):
        if a != 0 and (a < 0) != (b < 0): out.append(cur); cur = 0.0
        cur = max(cur, abs(b))
    return out + [cur]

S = simpson(lambda x: sqrt(q_str(x)), 0.0, 1.0)
L, c0 = 0.65, 2 * 0.65 * 110.0                       # metres; light-end wave speed, m/s
hz = c0 / (2 * pi * L)                               # f = lam c0 / (2 pi L)
print("string: y'' + lam^2 (1 + x)^2 y = 0 on [0, 1], y(0) = y(1) = 0")
print(f"phase integral S by Simpson {S:.6f}   L {L:.2f} m   c0 {c0:.1f} m/s   f = lam x {hz:.4f} Hz")
print(" n   WKB nπ/S  shooting    Bessel  corrected  WKB err  n x err  WKB ¢  corr ¢  slowness")
rows = []
for n in range(1, 6):
    w = n * pi / S
    ex = bisect(lambda l: shoot(l, q_str), w - 1, w + 1)
    bs = bisect(bessel, w - 1, w + 1)
    co = sqrt(w * w - 3 / 16)                        # first correction: lam^2 = (n pi/S)^2 + mean of Q
    rows.append((w, ex, bs, co))
    print(f"{n:2d} {w:10.6f} {ex:9.6f} {bs:9.6f} {co:10.6f} {w - ex:8.6f} {n * (w - ex):8.6f} "
          f"{1200 * log2(w / ex):+6.2f} {1200 * log2(co / ex):+7.2f} {2 / ex:9.3f}")
print(f"limit of n x err, 9/(64 pi) = {9 / (64 * pi):.6f}")
print("frequency, Hz: " + "   ".join(f"n={n} WKB {r[0] * hz:.2f} exact {r[1] * hz:.2f}" for n, r in enumerate(rows[:3], 1)))
grid = [i / 2000 for i in range(2001)]
pe = peaks(shoot(rows[4][1], q_str, every=1)[:-1])
pw = peaks([q_str(x) ** -0.25 * sin(rows[4][0] * (x + x * x / 2)) for x in grid][:-1])
pn = peaks([sin(rows[4][0] * (x + x * x / 2)) for x in grid][:-1])
print(f"mode 5, last lobe peak / first lobe peak: exact {pe[-1] / pe[0]:.4f}   WKB {pw[-1] / pw[0]:.4f}   "
      f"no q^(-1/4) {pn[-1] / pn[0]:.4f}")
print(f"mistake, light-end speed only, lam_1 = pi {pi:.4f} ({pi * hz:.2f} Hz); heavy end only pi/2 {pi / 2:.4f} ({pi / 2 * hz:.2f} Hz)")

def g_step(l): return 2 * sin(l / 2) * (1 - 2 * sin(l / 2) ** 2) + (1 - 2 * sin(l / 4) ** 2) * sin(l)
def q_step(x): return 1.0 if x < 0.5 else 4.0        # two uniform halves, mass ratio 4
print("jump: two uniform halves, mass ratio 4 (2 tan(lam/2) + tan(lam) = 0); WKB still n pi/1.5")
print(" n     exact  shooting       WKB   WKB err")
step = []
for n in range(1, 6):
    w = n * pi / 1.5
    ex, sh = bisect(g_step, w - 1, w + 1), bisect(lambda l: shoot(l, q_step), w - 1, w + 1)
    step.append((ex, sh, w))
    print(f"{n:2d} {ex:9.6f} {sh:9.6f} {w:9.6f} {w - ex:+9.6f}")
print(f"first jump eigenvalue 2 atan(sqrt 2) = {2 * atan(sqrt(2)):.6f}")

h, z, u, v, zeros, big, slope = 1e-4, 8.0, 1e-6, -sqrt(8.0) * 1e-6, [], 0.0, 0.0
def fa(z, u, v): return v, z * u                     # Airy: u'' = z u, integrated from z = 8 down
for i in range(round(14 / h)):
    k1 = fa(z, u, v)
    k2 = fa(z - h / 2, u - h / 2 * k1[0], v - h / 2 * k1[1])
    k3 = fa(z - h / 2, u - h / 2 * k2[0], v - h / 2 * k2[1])
    k4 = fa(z - h, u - h * k3[0], v - h * k3[1])
    un = u - h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
    v -= h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    if not zeros: big = max(big, abs(un))
    if (un < 0) != (u < 0):
        zeros.append(-(z - h * u / (u - un)))
        if len(zeros) == 1: slope = v
    u, z = un, z - h
print("turning point: y'' + lam^2 (1 - x) y = 0, y(0) = 0, y decays past x = 1; exact lam = a^(3/2)")
print(" n  Airy zero a  exact lam  (n - 1/4) rule  error   naive n rule  error")
tp = []
for n, a in enumerate(zeros[:3], 1):
    ex, co, nv = a ** 1.5, 1.5 * pi * (n - 0.25), 1.5 * pi * n
    tp.append((a, ex, co, nv))
    print(f"{n:2d} {a:12.9f} {ex:10.6f} {co:15.6f} {co - ex:+.4f} {nv:14.6f} {nv - ex:+.4f}")
lam1, co1 = tp[0][1], tp[0][2]
wk = [(1 - x) ** -0.25 * sin(co1 * 2 / 3 * (1 - (1 - x) ** 1.5)) for x in (0.99, 0.9999)]
print(f"mode 1, both with slope lam at x = 0: exact largest |y| {lam1 ** (1 / 3) * big / abs(slope):.4f}   "
      f"WKB at x = 0.99 {wk[0]:.4f}, at x = 0.9999 {wk[1]:.4f}")
xs = [0.05 * k for k in range(21)]
ce = shoot(rows[2][1], q_str, every=100)
cw = [q_str(x) ** -0.25 * sin(rows[2][0] * (x + x * x / 2)) for x in xs]
print("chart, x          " + " ".join(f"{x:5.2f}" for x in xs))
print("chart, exact n=3  " + " ".join(f"{y:5.2f}" for y in ce))
print("chart, WKB n=3    " + " ".join(f"{y:5.2f}" for y in cw))

assert abs(S - 1.5) < 1e-9, "Simpson must land on the integral of (1 + x), 1.5"
assert all(abs(r[1] - r[2]) < 1e-7 for r in rows), "shooting and the Bessel solution must agree"
assert rows[4][0] - rows[4][1] < (rows[0][0] - rows[0][1]) / 3, "WKB error must fall as n grows"
assert abs(5 * (rows[4][0] - rows[4][1]) - 9 / (64 * pi)) < 0.002, "n x error must approach 9/(64 pi)"
assert all(abs(r[3] - r[1]) < (r[0] - r[1]) / 4 for r in rows[2:]), "the correction must beat plain WKB from n = 3"
assert abs(pe[-1] / pe[0] - pw[-1] / pw[0]) < 0.01, "q^(-1/4) must predict the lobe heights"
assert max(abs(a - b) for a, b in zip(ce, cw)) < 0.02, "WKB mode 3 must trace the exact mode"
assert all(abs(s[0] - s[1]) < 1e-3 for s in step) and abs(step[0][0] - 2 * atan(sqrt(2))) < 1e-9, "jump: two roads"
assert min(abs(s[2] - s[0]) for s in step if abs(s[2] - s[0]) > 1e-6) > 0.18, "jump: WKB error does not fall"
assert abs(tp[0][0] - 2.338107410) < 1e-6, "first Airy zero, DLMF table 9.9.1"
assert all(abs(t[3] - t[1]) > 1.1 and abs(t[2] - t[1]) < 0.05 for t in tp), "turning point needs the 1/4"
print("ALL CHECKS PASS")
