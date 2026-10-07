# Conditional densities -- the check behind the card.  Standard library only.
# Height H (cm) and weight W (kg): the tilted bell, centres 175 cm and 78 kg,
# spreads 7 cm and 12 kg, correlation 0.5.  Weight at 180 cm three ways: slice
# and divide by the slice's area (Simpson), complete the square, and simulated
# adults within 1 cm of 180.  Phi is a series; draws come from SplitMix64.
from math import exp, sqrt, pi, cos, sin

MH, SH, MW, SW, RHO = 175.0, 7.0, 78.0, 12.0, 0.5

def joint(h, w, rho=RHO):                        # the tilted bell, per cm per kg
    a, b = (h - MH) / SH, (w - MW) / SW
    q = (a * a - 2 * rho * a * b + b * b) / (1 - rho * rho)
    return exp(-q / 2) / (2 * pi * SH * SW * sqrt(1 - rho * rho))

def simpson(g, lo, hi, n=800):                   # Simpson's rule, n even
    step = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if i % 2 else 2) * g(lo + i * step) for i in range(1, n))
    return s * step / 3

WLO, WHI, HLO, HHI = MW - 8 * SW, MW + 8 * SW, MH - 8 * SH, MH + 8 * SH
def slice_area(h, rho=RHO): return simpson(lambda w: joint(h, w, rho), WLO, WHI)
def cond(w, h): return joint(h, w) / slice_area(h)
def cond_mean(h, rho=RHO):
    return simpson(lambda w: w * joint(h, w, rho), WLO, WHI) / slice_area(h, rho)
def cond_sd(h, rho=RHO):
    m = cond_mean(h, rho)
    return sqrt(simpson(lambda w: (w - m) ** 2 * joint(h, w, rho), WLO, WHI) / slice_area(h, rho))
def cond_tail(t, h): return simpson(lambda w: joint(h, w), t, WHI) / slice_area(h)

def Phi(z):                                      # standard normal area left of z, by series
    term, total = z, z
    for n in range(1, 200):
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

MASK = (1 << 64) - 1
state = 20260928                                 # SplitMix64, seed 20260928
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53

H0, T90 = 180.0, 90.0
print("road 1: slice the joint density at 180 cm, divide by the slice's area")
area = slice_area(H0)
m1, s1, p1 = cond_mean(H0), cond_sd(H0), cond_tail(T90, H0)
print(f"slice area f_H(180)            {area:.6f} per cm")
print(f"conditional mean, sd            {m1:.4f} kg  {s1:.4f} kg")
print(f"P(W > 90 | H = 180)             {p1:.4f}")
print("road 2: complete the square at a = 5/7 (180 cm is 5/7 of a spread up)")
a0 = (H0 - MH) / SH
m2, s2 = MW + SW * RHO * a0, SW * sqrt(1 - RHO * RHO)
area2 = exp(-a0 * a0 / 2) / (sqrt(2 * pi) * SH)
p2 = 1 - Phi((T90 - m2) / s2)
print(f"slice area exp(-a^2/2)/(7 sqrt(2 pi)) {area2:.6f} per cm")
print(f"centre 78 + 12(0.5)(5/7), spread 12 sqrt(0.75) {m2:.4f} kg  {s2:.4f} kg")
print(f"P(W > 90 | H = 180) = 1 - Phi(z)  {p2:.4f}  (z = {(T90 - m2) / s2:.4f})")
print(f"all adults: P(W > 90) = 1 - Phi(1)  {1 - Phi((T90 - MW) / SW):.4f}")

print("road 3: rejection sampling from the joint density, then keep a band")
N = 3_000_000
acc = sw = sw2 = 0.0
band = [0, 0.0, 0.0, 0]                          # |H - 180| < 1: count, sum w, sum w^2, w > 90
rev = [0, 0.0, 0.0]                              # |W - 90| < 1.2: count, sum h, sum h^2
odd = [0, 0.0, 0.0]                              # |(H - 180)/W| < 0.01: count, sum w, sum w^2
for _ in range(N):
    a, b = -4.5 + 9 * uniform(), -4.5 + 9 * uniform()
    q = (a * a - 2 * RHO * a * b + b * b) / (1 - RHO * RHO)
    if uniform() >= exp(-q / 2):
        continue
    h, w = MH + SH * a, MW + SW * b
    acc += 1; sw += w; sw2 += w * w
    if abs(h - H0) < 1:
        band[0] += 1; band[1] += w; band[2] += w * w; band[3] += w > T90
    if abs(w - T90) < 1.2:
        rev[0] += 1; rev[1] += h; rev[2] += h * h
    if abs((h - H0) / w) < 0.01:
        odd[0] += 1; odd[1] += w; odd[2] += w * w
def mean_se(n, s, s2):
    m = s / n
    return m, sqrt((s2 / n - m * m) / n)
m3, se3 = mean_se(band[0], band[1], band[2])
p3 = band[3] / band[0]
mall, seall = mean_se(acc, sw, sw2)
m5, se5 = mean_se(rev[0], rev[1], rev[2])
print(f"accepted {int(acc)} of {N}; mean weight {mall:.3f} kg, se {seall:.3f}")
print(f"band 179-181 cm: {band[0]} adults, mean {m3:.3f} kg, se {se3:.3f}")
print(f"band 179-181 cm: share over 90 kg {p3:.4f}, se {sqrt(p3 * (1 - p3) / band[0]):.4f}")

print("regression toward the mean: E[W | H = h] by slicing, and the sd line")
for h in (161.0, 168.0, 175.0, 180.0, 182.0, 189.0):
    print(f"h = {h:.0f}: slice mean {cond_mean(h):.3f} kg; line 78+(6/7)(h-175) {MW + 6 / 7 * (h - MH):.3f}; sd line {MW + 12 / 7 * (h - MH):.3f}")
rev_int = simpson(lambda h: h * joint(h, T90), HLO, HHI) / simpson(lambda h: joint(h, T90), HLO, HHI)
print(f"reverse: E[H | W = 90] by slicing {rev_int:.3f} cm; band 88.8-91.2 kg {m5:.3f} cm, se {se5:.3f}, n {rev[0]}")
tower = simpson(lambda h: cond_mean(h) * slice_area(h), HLO, HHI, 200)
back90 = simpson(lambda h: cond(T90, h) * slice_area(h), HLO, HHI, 200)
print(f"average of slice means, weighted by f_H: {tower:.4f} kg (overall 78)")
print(f"f_W(90) rebuilt from slices {back90:.6f}; bell exp(-1/2)/(12 sqrt(2 pi)) {exp(-0.5) / (12 * sqrt(2 * pi)):.6f}")

print("what breaks")
print(f"slice not divided: P(W > 90) read as {simpson(lambda w: joint(H0, w), T90, WHI):.4f}")
print(f"sd line at 180 cm: {MW + 12 / 7 * (H0 - MH):.3f} kg; line inverted at 90 kg: {MH + (T90 - MW) * 7 / 6:.1f} cm")
odd_int = simpson(lambda w: w * w * joint(H0, w), WLO, WHI) / simpson(lambda w: w * joint(H0, w), WLO, WHI)
m4, se4 = mean_se(odd[0], odd[1], odd[2])
print(f"band in (H-180)/W: mean {odd_int:.3f} kg by integral; simulated {m4:.3f}, se {se4:.3f}, n {odd[0]}")
print("try changing")
print(f"rho = 0: mean {cond_mean(H0, 0.0):.3f}, sd {cond_sd(H0, 0.0):.3f}; rho = 0.9: mean {cond_mean(H0, 0.9):.3f}, sd {cond_sd(H0, 0.9):.3f}")

print("chart, weight kg          " + " ".join(f"{w:5.0f}" for w in range(40, 121, 5)))
print("chart, at 180 cm, %/kg    " + " ".join(f"{100 * cond(w, H0):5.2f}" for w in range(40, 121, 5)))
print("chart, all adults, %/kg   " + " ".join(f"{100 * simpson(lambda h: joint(h, w), HLO, HHI):5.2f}" for w in range(40, 121, 5)))
X = lambda h: 40 + 6 * (h - 150)                 # screen x: 150-200 cm -> 40-340
Y = lambda w: 210 - 2 * (w - 30)                 # screen y: 30-120 kg -> 210-30
ell = []
for k in range(24):
    t = 2 * pi * k / 24
    c, s = 2 * cos(t), 2 * sin(t)
    ell.append(f"{X(MH + SH * c):.1f},{Y(MW + SW * (RHO * c + sqrt(1 - RHO * RHO) * s)):.1f}")
print("figure, scale 6 per cm across, 2 per kg up")
print("figure, 2-sd contour " + " ".join(ell))
L1, L2 = lambda h: MW + 6 / 7 * (h - MH), lambda h: MW + 12 / 7 * (h - MH)
print(f"figure, mean line {X(150):.0f},{Y(L1(150)):.1f} {X(200):.0f},{Y(L1(200)):.1f}; sd line {X(154):.0f},{Y(L2(154)):.1f} {X(196):.0f},{Y(L2(196)):.1f}; slice x {X(H0):.0f}; dot y {Y(m1):.1f}")

assert abs(m1 - m2) < 1e-6, "slice mean vs completing the square"
assert abs(s1 - s2) < 1e-6, "slice spread vs completing the square"
assert abs(area - area2) < 1e-9, "slice area vs the height bell"
assert abs(p1 - p2) < 1e-6, "tail by integration vs by the Phi series"
assert abs(m3 - m1) < 4 * se3, "simulated band mean within 4 se"
assert abs(tower - MW) < 1e-6, "averaging slice means gives back 78"
assert abs(back90 - exp(-0.5) / (12 * sqrt(2 * pi))) < 1e-9, "slices rebuild f_W(90)"
assert all(abs(cond_mean(h) - MW - 6 / 7 * (h - MH)) < 1e-6 for h in (161.0, 189.0)), "line of averages"
assert abs(m5 - rev_int) < 4 * se5, "reverse band within 4 se"
assert abs(p3 - p1) < 4 * sqrt(p1 * (1 - p1) / band[0]), "band share over 90 kg within 4 se"
assert abs(m4 - odd_int) < 4 * se4, "the other band: simulation vs integral"
assert odd_int - m1 > 1, "the other band really moves the answer"
print("ALL CHECKS PASS")
