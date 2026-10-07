# Bivariate normal and conditioning -- the check behind the card.  Standard library only.
# Adult height H (cm) and weight W (kg): centres 175 and 75, spreads 7 and 12,
# correlation 0.5.  The law of weight among adults 189 cm tall is reached three
# ways: the formula, a slice of the joint density integrated by Simpson's rule,
# and a seeded simulation.  Nothing imported holds the answer.
from math import exp, log, sqrt, pi, asin, cos, sin

MH, SH, MW, SW, RHO = 175.0, 7.0, 75.0, 12.0, 0.5
H0, W0 = 189.0, 90.0                         # the question: over 90 kg, at 189 cm tall

def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)   # standard normal density
def Phi(z):                                  # standard normal area, Taylor series term by term
    term, total = z, z
    for n in range(1, 200):
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(g, a, b, n=4000):                # Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def joint(h, w):                             # the bivariate normal density, per cm per kg
    x, y = (h - MH) / SH, (w - MW) / SW
    q = (x * x - 2 * RHO * x * y + y * y) / (1 - RHO * RHO)
    return exp(-q / 2) / (2 * pi * SH * SW * sqrt(1 - RHO * RHO))

def cond(h, rho=RHO):                        # road 1: the formula -> (mean, spread, P(W > W0))
    m, s = MW + rho * SW * (h - MH) / SH, SW * sqrt(1 - rho * rho)
    return m, s, 1 - Phi((W0 - m) / s)

MASK = (1 << 64) - 1
state = 20260928                             # road 3: SplitMix64, seed 20260928
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def uniform(): return ((splitmix() >> 11) + 0.5) / 2.0 ** 53   # strictly between 0 and 1
def normal_pair():                           # Marsaglia's polar method
    while True:
        u, v = 2 * uniform() - 1, 2 * uniform() - 1
        s = u * u + v * v
        if 0 < s < 1:
            k = sqrt(-2 * log(s) / s)
            return u * k, v * k

m1, s1, p1 = cond(H0)
print(f"model: height {MH:.1f} cm sd {SH:.1f}; weight {MW:.1f} kg sd {SW:.1f}; rho {RHO:.2f}")
print(f"covariance rho*sH*sW = {RHO * SH * SW:.3f} cm kg; height z at {H0:.0f} cm = {(H0 - MH) / SH:.3f}")
print(f"slope rho*sW/sH = {RHO * SW / SH:.6f} kg per cm; reverse slope rho*sH/sW = {RHO * SH / SW:.6f} cm per kg")
print(f"  inverting the first slope instead: {SH / (RHO * SW):.6f} cm per kg; mean height at 99 kg {MH + RHO * SH * (99 - MW) / SW:.1f} cm")
print(f"rho^2 = {RHO ** 2:.4f}; spread shrink sqrt(1 - rho^2) = {sqrt(1 - RHO ** 2):.6f}; variances sH^2 {SH ** 2:.0f}, "
      f"sW^2 {SW ** 2:.0f} = line {RHO ** 2 * SW ** 2:.0f} + leftover {(1 - RHO ** 2) * SW ** 2:.0f}")
lo, hi, g = MW - 12 * SW, MW + 12 * SW, lambda w: joint(H0, w)   # road 2: slice the joint density at 189 cm
fx = simpson(g, lo, hi)
m2 = simpson(lambda w: w * g(w), lo, hi) / fx
s2 = sqrt(simpson(lambda w: (w - m2) ** 2 * g(w), lo, hi) / fx)
p2 = simpson(g, W0, hi) / fx
print(f"at {H0:.0f} cm   formula: mean {m1:.6f} kg, sd {s1:.6f} kg, P(W > 90) {p1:.6f}, z of 90 kg {(W0 - m1) / s1:.4f}")
print(f"at {H0:.0f} cm   slice:   mean {m2:.6f} kg, sd {s2:.6f} kg, P(W > 90) {p2:.6f}")
print(f"height density at {H0:.0f} cm: slice area {fx:.8f}, phi(2)/7 {phi((H0 - MH) / SH) / SH:.8f}")
print(f"P(W > 90) ignoring height: z {(W0 - MW) / SW:.4f}, P {1 - Phi((W0 - MW) / SW):.6f}")
a, b = 0.0, 5.0         # flip pair: normal weight, correlation 0.5, not jointly normal; bisect for the cutoff
flip_corr = lambda c: 4 * simpson(lambda z: z * z * phi(z), 0.0, c, 400) - 1
for _ in range(60):
    c = (a + b) / 2
    a, b = (c, b) if flip_corr(c) < RHO else (a, c)
C = (a + b) / 2
flip_w = lambda z: MW + SW * (z if abs(z) < C else -z)
print(f"flip pair: cutoff c = {C:.6f}, correlation by integral {flip_corr(C):.6f}")
print(f"  weight at 189 cm: {flip_w(2.0):.1f} kg, P(W > 90) = 1; at 192.5 cm: {flip_w(2.5):.1f} kg vs line {cond(192.5)[0]:.1f}")
N = 400000                                   # road 3: simulation
sh = sw = shh = sww = shw = sf = sff = shf = 0.0
nwin = swin = swin2 = nover = both = inside = 0
for _ in range(N):
    z1, z2 = normal_pair()
    h, w = MH + SH * z1, MW + SW * (RHO * z1 + sqrt(1 - RHO * RHO) * z2)
    f = flip_w(z1)
    sh += h; sw += w; shh += h * h; sww += w * w; shw += h * w
    sf += f; sff += f * f; shf += h * f
    x, y = (h - MH) / SH, (w - MW) / SW
    both += x > 0 and y > 0
    inside += (x * x - 2 * RHO * x * y + y * y) / (1 - RHO * RHO) <= 4
    if 188.0 <= h <= 190.0:
        nwin += 1; swin += w; swin2 += w * w; nover += w > W0
vh, vw, vf = shh / N - (sh / N) ** 2, sww / N - (sw / N) ** 2, sff / N - (sf / N) ** 2
corr = (shw / N - sh * sw / N / N) / sqrt(vh * vw)
corr_f = (shf / N - sh * sf / N / N) / sqrt(vh * vf)
mw_win = swin / nwin; sd_win = sqrt(swin2 / nwin - mw_win ** 2)
se_m, p_win = sd_win / sqrt(nwin), nover / nwin
se_p = sqrt(p_win * (1 - p_win) / nwin)
p_both, p_in = both / N, inside / N
se_both, se_in = sqrt(p_both * (1 - p_both) / N), sqrt(p_in * (1 - p_in) / N)
print(f"simulation, {N} adults, seed 20260928:")
print(f"  correlation {corr:.4f} (se about {(1 - RHO ** 2) / sqrt(N):.4f}); slope {corr * sqrt(vw / vh):.4f} kg per cm")
print(f"  heights 188-190 cm: {nwin} adults, mean weight {mw_win:.3f} (se {se_m:.3f}), sd {sd_win:.3f}")
print(f"  share over 90 kg there: {p_win:.4f} (se {se_p:.4f})")
print(f"  flip pair: correlation {corr_f:.4f}, weight sd {sqrt(vf):.3f}")
p_or = 0.25 + asin(RHO) / (2 * pi)
p_or2 = simpson(lambda z: phi(z) * Phi(RHO * z / sqrt(1 - RHO * RHO)), 0.0, 12.0)
print(f"both above average: arcsin rule {p_or:.6f}, integral {p_or2:.6f}, simulation {p_both:.4f} (se {se_both:.4f})")
print(f"inside the Q = 4 ellipse: 1 - e^-2 = {1 - exp(-2):.6f}, simulation {p_in:.4f} (se {se_in:.4f})")
wm, full = MW + RHO * SH * (H0 - MH) / SW, MW + SW * (H0 - MH) / SH   # upside-down slope; slope sW/sH
print(f"wrong: slope upside down: mean {wm:.4f}, P(W > 90) {1 - Phi((W0 - wm) / s1):.6f}")
print(f"wrong: spread not shrunk: P(W > 90) {1 - Phi((W0 - m1) / SW):.6f}")
print(f"wrong: full step, no regression: mean {full:.1f}, P(W > 90) {1 - Phi((W0 - full) / s1):.6f}")
for r in (0.9, 0.0, -0.5):
    print(f"try: rho {r:+.1f} at 189 cm: mean %.3f, sd %.3f, P(W > 90) %.6f" % cond(H0, r))
print(f"try: rho +0.5 at 161 cm: mean %.3f, sd %.3f, P(W > 90) %.6f" % cond(161.0))
ws = [45 + 5 * i for i in range(13)]
print("chart, weight kg        " + " ".join(f"{w:5d}" for w in ws))
print("chart, at 189 cm %/kg   " + " ".join(f"{100 * phi((w - m1) / s1) / s1:5.2f}" for w in ws))
print("chart, all adults %/kg  " + " ".join(f"{100 * phi((w - MW) / SW) / SW:5.2f}" for w in ws))
px, py = lambda h: 40 + (h - 154) * 300 / 42, lambda w: 220 - (w - 39) * 192 / 72   # cm, kg -> pixels
pts = []
for k in range(36):
    t = 2 * pi * k / 36
    zx, zy = 2 * cos(t), 2 * (RHO * cos(t) + sqrt(1 - RHO * RHO) * sin(t))
    pts.append(f"{px(MH + SH * zx):.1f},{py(MW + SW * zy):.1f}")
print("figure, ellipse Q = 4: " + " ".join(pts))
print(f"figure, W on H line: {px(154):.1f},{py(cond(154)[0]):.1f} {px(196):.1f},{py(cond(196)[0]):.1f}"
      f"; H on W line: {px(MH + RHO * SH * (39 - MW) / SW):.1f},{py(39):.1f} {px(MH + RHO * SH * (111 - MW) / SW):.1f},{py(111):.1f}")
print(f"figure, point (189, 87): {px(H0):.1f},{py(m1):.1f}; ticks x {px(161):.1f} {px(175):.1f} {px(189):.1f}; y {py(51):.1f} {py(75):.1f} {py(99):.1f}")
print(f"figure, scale {px(155) - px(154):.2f} px per cm, {py(39) - py(40):.2f} px per kg; ellipse ends (cm, kg): "
      + " ".join(f"({MH + SH * a:.0f}, {MW + SW * b:.0f})" for a, b in ((2, 1), (-2, -1), (1, 2), (-1, -2))))
assert abs(m2 - m1) < 1e-9, "slice mean vs the formula's straight line"
assert abs(s2 - s1) < 1e-9, "slice spread vs sW sqrt(1 - rho^2)"
assert abs(p2 - p1) < 1e-9, "slice tail area vs the Phi series"
assert abs(fx - phi((H0 - MH) / SH) / SH) < 1e-12, "slice area vs height's own density"
assert abs(mw_win - m1) < 4 * se_m, "simulated mean weight at 188-190 cm vs formula"
assert abs(p_win - p1) < 4 * se_p, "simulated share over 90 kg vs formula"
assert abs(p_or - p_or2) < 1e-9, "arcsin rule vs integral"
assert abs(p_both - p_or) < 4 * se_both, "arcsin rule vs simulation"
assert abs(p_in - (1 - exp(-2))) < 4 * se_in, "ellipse share vs 1 - e^-2"
assert abs(corr_f - RHO) < 4 * (1 - RHO ** 2) / sqrt(N), "flip pair: simulated correlation vs the integral's 0.5"
print("ALL CHECKS PASS")
