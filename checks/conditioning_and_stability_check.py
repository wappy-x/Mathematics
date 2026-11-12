# Conditioning and stability -- the check behind the card.  Standard library only.
# Two straight roads, y = m1*x + c1 and y = m2*x + c2, cross where x = (c2 - c1)/(m1 - m2).
# Road 1: the condition number kappa from its formula.  Road 2: kappa measured by
# nudging each datum, in exact fractions.  Road 3: exact answers in fractions against
# the floating-point methods, so every error printed is a true error.
import math
from fractions import Fraction as F

U = 2.0 ** -53  # unit roundoff: the largest relative error of one rounding

def e(v, p=2):  # e-notation as Rust prints it: 1.11e-16, never 1.11e-016 or e+02
    m, x = f"{v:.{p}e}".split("e")
    return m + "e" + str(int(x))

def cross(m1, c1, m2, c2):  # where the roads cross; works on floats and on fractions
    return (c2 - c1) / (m1 - m2)

def kappa(m1, c1, m2, c2):  # worst case when every datum is off by the same small fraction
    return (abs(m1) + abs(m2)) / abs(m1 - m2) + (abs(c1) + abs(c2)) / abs(c2 - c1)

def kappa_nudged(d, fn=cross, h=F(1, 10**6)):  # each datum nudged up and down by h, in exact fractions
    x0, total = fn(*d), F(0)
    for i in range(len(d)):
        up, dn = list(d), list(d)
        up[i] *= 1 + h
        dn[i] *= 1 - h
        total += abs(fn(*up) - fn(*dn)) / (2 * h * abs(x0))
    return total

def cramer(a1, b1, s1, a2, b2, s2):  # x from the six stored coefficients of two rows
    return (s1 * b2 - s2 * b1) / (a1 * b2 - a2 * b1)

def solve(r1, r2, swap):  # rows (a, b, r) of a*x + b*y = r; eliminate x, then back-substitute
    if swap and abs(r2[0]) > abs(r1[0]):
        r1, r2 = r2, r1
    (a1, b1, s1), (a2, b2, s2) = r1, r2
    l = a2 / a1  # the multiplier: how many copies of row 1 to take from row 2
    y = (s2 - l * s1) / (b2 - l * b1)
    return (s1 - b1 * y) / a1, y

# ---- case 1: a fork.  Road A: y = 0.1x.  Road B: y = 0.101x - 2.  Metres. ----
D1 = (0.100, 0.0, 0.101, -2.0)
E1 = (F("0.100"), F(0), F("0.101"), F(-2))
x1 = cross(*E1)
k1, k1n = kappa(*D1), kappa_nudged(E1)
k_m1, k_m2 = (abs(m) / abs(D1[0] - D1[2]) for m in (D1[0], D1[2]))
k_c1, k_c2 = (abs(c) / abs(D1[3] - D1[1]) for c in (D1[1], D1[3]))
x1h = cross(*D1)
err1 = abs(F(x1h) - x1) / x1
print("case 1, fork: roads y = 0.1x and y = 0.101x - 2, metres")
print(f"exact crossing x                  {float(x1):.2f} m")
print(f"kappa by formula                  {k1:.4f}   (m1 {k_m1:.4f}, m2 {k_m2:.4f}, c1 {k_c1:.4f}, c2 {k_c2:.4f})")
print(f"kappa by nudging each datum      {float(k1n):.4f}")
print(f"angle between roads {math.degrees(math.atan(0.101) - math.atan(0.1)):.4f} degrees, digits at risk log10 kappa {math.log10(k1):.2f}")
print(f"unit roundoff u {e(U)}, 3u {e(3 * U)}")
print(f"float formula: true rel error     {e(float(err1))}   bound kappa*3u {e(k1 * 3 * U)}, ratio {k1 * 3 * U / float(err1):.1f}")
d = F(1, 1000)
xs = cross(E1[0], E1[1], E1[2] * (1 + d), E1[3])
lo = cross(E1[0] * (1 - d), E1[1], E1[2] * (1 + d), E1[3] * (1 - d))
hi = cross(E1[0] * (1 + d), E1[1], E1[2] * (1 - d), E1[3] * (1 + d))
x1pc = cross(E1[0], E1[1], E1[2] * F(99, 100), E1[3])
print(f"m2 read 0.1% high: crossing       {float(xs):.2f} m, moved {float(xs - x1):.2f} m = {float(100 * (xs - x1) / x1):.2f} %")
print(f"  first-order: kappa_m2 x 0.1%    {100 * k_m2 * 0.001:.2f} % = {2000 * k_m2 * 0.001:.2f} m")
print(f"all data 0.1% off, worst case     {float(lo):.2f} m to {float(hi):.2f} m")
print(f"  first-order: x(1 -+ kappa*0.1%) {2000 * (1 - k1 * 0.001):.2f} m to {2000 * (1 + k1 * 0.001):.2f} m")
print(f"m2 read 1% low: crossing          {float(x1pc):.2f} m")
print(f"  first-order predicts            {2000 * (1 + k_m2 * 0.01):.2f} m")
dxdm2 = abs(D1[3] - D1[1]) / (D1[0] - D1[2]) ** 2
print(f"absolute slope |dx/dm2|           {dxdm2:.0f} m per unit slope")
for k in range(13):  # chart: road B's offset north of road A, gap = (m2 - m1) x + c2
    xg = 200 * k
    print(f"chart, x {xg}, B {0.001 * xg - 2:.3f}, B 0.1% steep {0.001101 * xg - 2:.3f}, B 1% shallow {-0.00001 * xg - 2:.3f}")

# ---- case 2: a 45-degree crossing stored as a*x + y = 1 and x + y = 2 ----
a = 6.123233995736766e-17  # leftover of a rotation: what cos(90 degrees) returns in doubles
D2 = (-a, 1.0, -1.0, 2.0)  # the same roads in slope form: y = -a x + 1, y = -x + 2
x2 = 1 / (1 - F(a))  # exact
k2 = kappa(*D2)
k6 = kappa_nudged(tuple(F(v) for v in (a, 1.0, 1.0, 1.0, 1.0, 2.0)), cramer)  # stored form
xn, yn = solve((a, 1.0, 1.0), (1.0, 1.0, 2.0), swap=False)
xp, yp = solve((a, 1.0, 1.0), (1.0, 1.0, 2.0), swap=True)
xf = cross(*D2)
en, ep, ef = (abs(F(v) - x2) / x2 for v in (xn, xp, xf))
print("case 2, 45-degree crossing: a*x + y = 1 and x + y = 2")
print(f"a {e(a, 3)}   cos(pi/2) library {e(math.cos(math.pi / 2), 3)}")
print(f"angle between roads {math.degrees(math.atan(-a) - math.atan(-1.0)):.4f} degrees")
print(f"kappa by formula                  {k2:.4f}   kappa by nudging {float(kappa_nudged(tuple(F(v) for v in D2))):.4f}")
print(f"kappa on the six stored coefficients, by nudging {float(k6):.4f}")
print(f"no swap: x-hat {xn:.4f}  y-hat {yn:.4f}   true rel error {e(float(en))}")
print(f"  multiplier 1/a {e(1.0 / a, 3)}; road B becomes {1 - 1 / a:.0f} y = {2 - 1 / a:.0f}")
print(f"  road B's 2 would have to be {xn + yn:.4f}")
print(f"swap:    x-hat {xp:.4f}  y-hat {yp:.4f}   true rel error {e(float(ep))}")
print(f"formula: x-hat {xf:.4f}               true rel error {e(float(ef))}")
print(f"bound for a stable method, kappa*3u {e(k2 * 3 * U)}, ratio to swap {k2 * 3 * U / float(ep):.1f}, to formula {k2 * 3 * U / float(ef):.1f}")

# ---- house example: a tracker adds 0.1 ten million times ----
s = 0.0
for _ in range(10_000_000):
    s += 0.1
st = 10_000_000 * F(0.1)  # exact sum of the stored 0.1s
print(f"tracker: total {s:.5f}, true {float(st):.5f}, error {float(st - F(s)):.5f}, kappa of a sum of positives 1")

# ---- try changing ----
xw, xw2 = cross(0.1, 0.0, 0.2, -2.0), cross(0.1, 0.0, 0.2 * 1.001, -2.0)
print(f"try: m2 0.2: kappa {kappa(0.1, 0.0, 0.2, -2.0):.4f}, x {xw:.2f} m, 0.1% steeper {xw2:.2f} m")
print(f"try: m2 0.1001: kappa {kappa(0.1, 0.0, 0.1001, -2.0):.4f}, x {cross(0.1, 0.0, 0.1001, -2.0):.2f} m")
print(f"try: m2 0.01% high: x {float(cross(E1[0], E1[1], E1[2] * F(10001, 10000), E1[3])):.2f} m")
for t in (1e-3, 1e-8):
    tn, _ = solve((t, 1.0, 1.0), (1.0, 1.0, 2.0), swap=False)
    print(f"try: a {e(t, 0)}: no-swap rel error {e(float(abs(F(tn) - 1 / (1 - F(t))) * (1 - F(t))))}")

# ---- asserts: each compares against an independently computed value ----
assert x1 == 2000, "exact crossing is 2 m closed at 1 m per 1000 m"
assert abs(k1 - float(k1n)) < 1e-4, "formula and nudged kappa must agree"
assert float(err1) <= k1 * 3 * U, "a backward-stable formula stays inside kappa*3u"
assert abs(float((xs - x1) / x1) + k_m2 * 0.001) < 0.1 * k_m2 * 0.001, "first order within 10 % at 0.1 %"
assert float(x1pc) < 0, "a 1 % slope error sends the crossing behind the start"
assert abs(k2 - float(kappa_nudged(tuple(F(v) for v in D2)))) < 1e-4, "case 2 kappa, two roads"
assert float(en) > 1e10 * k2 * 3 * U, "well-conditioned problem, unstable method"
assert float(ep) <= k2 * 3 * U and float(ef) <= k2 * 3 * U, "swap and formula are stable"
assert abs(float(st - F(s)) - 1.6e-4) < 1e-5, "tracker total is off by about 0.00016"
print("ALL CHECKS PASS")
