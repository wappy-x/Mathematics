# Transforms in two dimensions and the projection-slice theorem -- the check
# behind the card.  Standard library only.  Units: lengths in cm, frequencies in
# cycles per cm, attenuation mu in 1/cm, so shadows are pure numbers and 2-D
# transforms come out in cm.  Illustrative phantom: a water disc of radius 10 cm
# (mu 0.2) holding a bone rod of radius 2 cm centred 5 cm right (mu 0.5 in all).
import math

DISCS = [(0.0, 0.0, 10.0, 0.2), (5.0, 0.0, 2.0, 0.3)]  # centre x, y; radius; mu added
WATER = DISCS[:1]
TH, SIG = math.radians(30), 0.1  # the worked shadow: angle 30 degrees, 0.1 cycles/cm
def arrow(x): return complex(math.cos(x), math.sin(x))  # e^(ix), written out
def mu(x, y, discs=DISCS): return sum(m for a, b, r, m in discs if (x - a) ** 2 + (y - b) ** 2 < r * r)
def bessel(n, x, M=400):  # J_n(x) = (1/pi) int_0^pi cos(n t - x sin t) dt, trapezoid
    tot = 0.5 * (1 + math.cos(n * math.pi))
    tot += sum(math.cos(n * k * math.pi / M - x * math.sin(k * math.pi / M)) for k in range(1, M))
    return tot / M
def series(n, x, K=40):  # J_n(x) as its power series, a second road
    return sum((-1) ** k * (x / 2) ** (2 * k + n) / (math.factorial(k) * math.factorial(k + n)) for k in range(K))
def disc_hat(r, m, rho):  # radial transform of a disc: mu R J1(2 pi R rho) / rho
    return m * math.pi * r * r if rho == 0 else m * r * bessel(1, 2 * math.pi * r * rho) / rho
def fhat(x1, x2, discs=DISCS):  # each disc's radial transform, shifted to its centre
    rho = math.hypot(x1, x2)
    return sum(disc_hat(r, m, rho) * arrow(-2 * math.pi * (x1 * a + x2 * b)) for a, b, r, m in discs)
def shadow(th, s):  # line integral of mu along x cos th + y sin th = s: chord lengths
    tot = 0.0
    for a, b, r, m in DISCS:
        d = s - (a * math.cos(th) + b * math.sin(th))
        tot += 2 * m * math.sqrt(r * r - d * d) if abs(d) < r else 0.0
    return tot
def simpson(f, a, b, n):  # n even
    w = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * w) for k in range(1, n))) * w / 3
def ft1(th, sig, n, lo=-10.0, hi=10.0):  # 1-D transform of the shadow, Simpson
    return simpson(lambda s: shadow(th, s) * arrow(-2 * math.pi * sig * s), lo, hi, n)
def pixels(x1, x2, h, discs=DISCS):  # 2-D transform of the image: sum over square pixels
    N, tot = round(20 / h), 0j
    for i in range(N):
        for j in range(N):
            x, y = -10 + (i + 0.5) * h, -10 + (j + 0.5) * h
            m = mu(x, y, discs)
            if m: tot += m * arrow(-2 * math.pi * (x1 * x + x2 * y))
    return tot * h * h
def recon(px, py, Sig, ramp=True, nth=180, ns=1200):  # filtered back-projection at (px, py), slices from the formula
    w = Sig / ns
    sig = [k * w for k in range(ns + 1)]
    wt = [(1 if k in (0, ns) else 4 if k % 2 else 2) * w / 3 * (sig[k] if ramp else 1) for k in range(ns + 1)]
    tab = [[disc_hat(r, m, s) for s in sig] for a, b, r, m in DISCS]  # radial parts, once
    tot = 0.0
    for j in range(nth):  # angles 0, 1, ..., 179 degrees
        ct, st = math.cos(j * math.pi / nth), math.sin(j * math.pi / nth)
        for d, (a, b, r, m) in enumerate(DISCS):  # slice j (= shadow j's transform) times the wave back
            off = (px - a) * ct + (py - b) * st
            tot += sum(wt[k] * tab[d][k] * math.cos(2 * math.pi * sig[k] * off) for k in range(ns + 1))
    return 2 * tot * math.pi / nth  # 2 for negative sigma; d theta = pi / nth
def hankel_recon(px, py, Sig, ns):  # the same picture, disc by disc: mu (1 - J0(2 pi R Sig)) if centred on the point
    return sum(m * (1 - bessel(0, 2 * math.pi * r * Sig)) if (px, py) == (a, b) else 2 * math.pi * simpson(
        lambda q: disc_hat(r, m, q) * bessel(0, 2 * math.pi * q * math.hypot(px - a, py - b)) * q, 0, Sig, ns) for a, b, r, m in DISCS)
def snap(x): return 0.0 if abs(x) < 5e-7 else x
def c(z): return f"{snap(z.real):.6f} {'-' if snap(z.imag) < 0 else '+'} {abs(z.imag):.6f}i"

print("Bessel functions: trapezoid integral | power series")
for x in (2 * math.pi * 0.2, 2 * math.pi):
    print(f"x = {x:.6f}: J0 {bessel(0, x):.9f} | {series(0, x):.9f}, J1 {bessel(1, x):.9f} | {series(1, x):.9f}")
    assert abs(bessel(0, x) - series(0, x)) < 1e-12 and abs(bessel(1, x) - series(1, x)) < 1e-12
for th, s in ((0, 0.0), (0, 5.0), (90, 0.0)):
    p = shadow(math.radians(th), s)
    print(f"shadow at {th} deg, s = {s:.0f} cm: {p:.6f}, share of X-rays through {math.exp(-p):.6f}")
# separability: a 4 cm by 2 cm block, mu 1: transform = 4 sinc(4 xi1) x 2 sinc(2 xi2)
sinc = lambda u: 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
sep = 4 * sinc(4 * 0.1) * 2 * sinc(2 * 0.2)
blk = simpson(lambda x: simpson(lambda y: arrow(-2 * math.pi * (0.1 * x + 0.2 * y)), -1, 1, 80), -2, 2, 80)
print(f"block at (0.1, 0.2): {4 * sinc(0.4):.6f} x {2 * sinc(0.4):.6f} = {sep:.6f}, 2-D Simpson {c(blk)}")
assert abs(blk - sep) < 1e-6
# rotation invariance and the Hankel transform: the water disc alone
hank = 2 * math.pi * simpson(lambda r: 0.2 * bessel(0, 2 * math.pi * 0.1 * r) * r, 0, 10, 200)
print(f"water disc, |xi| = 0.1: mu R J1(2 pi R rho)/rho {disc_hat(10, 0.2, 0.1):.6f}, Hankel integral {hank:.6f}")
assert abs(hank - disc_hat(10, 0.2, 0.1)) < 1e-7
for deg in (0, 30, 90):
    p = pixels(0.1 * math.cos(math.radians(deg)), 0.1 * math.sin(math.radians(deg)), 0.05, WATER)
    print(f"  pixel sum, 0.05 cm pixels, direction {deg} deg: {c(p)}, gap {abs(p - hank):.6f}")
    assert abs(p - hank) < 0.01
# the projection-slice theorem at 30 degrees and 0.1 cycles/cm: three roads
U = (SIG * math.cos(TH), SIG * math.sin(TH))
two = fhat(*U)
print(f"water part {disc_hat(10, 0.2, SIG):.6f}, bone part {disc_hat(2, 0.3, SIG):.6f}, "
      f"bone centre along u {5 * math.cos(TH):.6f} cm, angle {2 * math.pi * SIG * 5 * math.cos(TH):.6f} rad, "
      f"turn {c(arrow(-2 * math.pi * SIG * 5 * math.cos(TH)))}, bone turned {c(disc_hat(2, 0.3, SIG) * arrow(-2 * math.pi * SIG * 5 * math.cos(TH)))}")
print(f"slice: 2-D transform at ({U[0]:.6f}, {U[1]:.6f}) by formula {c(two)}")
for n in (2000, 8000):
    one = ft1(TH, SIG, n)
    print(f"  1-D transform of the 30 deg shadow, Simpson n = {n}: {c(one)}, gap {abs(one - two):.6f}")
    assert abs(one - two) < 1e-3
for h in (0.1, 0.05):
    p = pixels(*U, h)
    print(f"  2-D pixel sum, {h} cm pixels: {c(p)}, gap {abs(p - two):.6f}")
assert abs(p - two) < 0.01
# rebuilding the picture: filtered back-projection against the Hankel road
for p, name in (((5.0, 0.0), "bone centre"), ((0.0, 0.0), "water centre")):
    for S in (2.0, 4.0, 8.0):
        a, b = recon(*p, S, ns=1000 * round(S)), hankel_recon(*p, S, ns=600 * round(S))  # sigma steps 1/1000 and 1/600
        print(f"{name}, cut-off {S:.0f} cycles/cm: back-projection {a:.6f}, closed form + Hankel {b:.6f}, true {mu(*p):.6f}, gap {mu(*p) - a:.6f}")
        assert abs(a - b) < 2e-7 and abs(a - mu(*p)) < 0.05
# what breaks, at 30 degrees and 0.1 cycles/cm unless stated
print("what breaks: right answer", c(two))
print("slice along the rays, not the detector |", c(fhat(-U[1], U[0])))
lost = simpson(lambda p: 80 * math.cos(p) * math.cos(p) * math.cos(20 * math.pi * SIG * math.sin(p)), math.asin(0.8), math.pi / 2, 400)
cut = ft1(TH, SIG, 8000, -8.0, 8.0)  # above: the water's chord beyond |s| = 8, exactly, with s = 10 sin p
print("detector 16 cm wide, shadow cut at |s| = 8 |", c(two - lost), "| Simpson on the cut shadow", c(cut))
assert abs(cut - (two - lost)) < 1e-4
print(f"water disc's profile given a 1-D transform | {snap(2 * 0.2 * 10 * sinc(2 * 10 * 0.1)):.6f} against {disc_hat(10, 0.2, 0.1):.6f}")
print(f"back-projection without the ramp, bone centre, cut-off 4 | {recon(5.0, 0.0, 4.0, False):.6f} against 0.500000")
print("chart, s cm      ", " ".join(f"{s:6d}" for s in range(-10, 11)))
for th in (0, 90):
    print(f"chart, shadow {th:2d} ", " ".join(f"{shadow(math.radians(th), s):6.3f}" for s in range(-10, 11)))
print(f"figure, 10 px per cm, water centre (190, 200) r 100, bone centre (240, 200) r 20, "
      f"30 deg rod centre at s = {5 * math.cos(TH):.3f} cm, height {shadow(TH, 5 * math.cos(TH)):.3f}")
print("ALL CHECKS PASS")
