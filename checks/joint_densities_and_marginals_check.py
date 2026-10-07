# Joint densities and marginals -- the check behind the card.  Only math is
# imported.  The surface is a tilted bell for adult height H (cm) and weight
# W (kg): centre 175 cm and 78 kg, spreads 7 cm and 12 kg, tilt rho = 0.5.
# The tail chance P(H > 185, W > 90) is reached three ways: a grid over the
# whole surface, slices with a closed inner area, and 200,000 simulated adults.
from math import exp, sqrt, pi, log, cos, sin

MH, SH, MW, SW, RHO = 175.0, 7.0, 78.0, 12.0, 0.5
C = sqrt(1 - RHO * RHO)                          # the tilt's squeeze factor

def f(h, w):                                     # the joint density, per cm per kg
    zh, zw = (h - MH) / SH, (w - MW) / SW
    q = (zh * zh - 2 * RHO * zh * zw + zw * zw) / (C * C)
    return exp(-q / 2) / (2 * pi * SH * SW * C)

def bell(x, m, s):                               # a one-variable normal density
    z = (x - m) / s
    return exp(-z * z / 2) / (s * sqrt(2 * pi))

def Phi(x):                                      # standard normal area left of x, by Taylor series
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= -x * x / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(g, a, b, n=400):                     # Simpson's rule, n even
    step = (b - a) / n
    s = g(a) + g(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * g(a + i * step)
    return s * step / 3

def grid(g, h0, h1, w0, w1):                     # road 1: the double integral, box by box
    return simpson(lambda h: simpson(lambda w: g(h, w), w0, w1), h0, h1)

HL, HR, WL, WR = MH - 10 * SH, MH + 10 * SH, MW - 10 * SW, MW + 10 * SW
total = grid(f, HL, HR, WL, WR)
cov = grid(lambda h, w: (h - MH) * (w - MW) * f(h, w), HL, HR, WL, WR)
tail_grid = grid(f, 185.0, HR, 90.0, WR)
z90 = (90.0 - MW) / SW                           # road 2: slices, inner area in closed form
tail_slices = simpson(lambda h: bell(h, MH, SH) * (1 - Phi((z90 - RHO * (h - MH) / SH) / C)), 185.0, HR)
marg_err = max(abs(simpson(lambda w: f(h, w), WL, WR) - bell(h, MH, SH)) for h in range(154, 197, 3))

MASK = (1 << 64) - 1
state = 20260928
def uniform():                                   # SplitMix64, a number strictly between 0 and 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0

N = 200000
R50 = sqrt(-2 * log(0.5))
n_tail = n_mid = n_heavy = n_ring = 0
bins = [0] * 15                                  # 3-cm bins centred on 154, 157, ..., 196
for _ in range(N):                               # road 3: simulated adults, by Box-Muller
    r, a = sqrt(-2 * log(uniform())), 2 * pi * uniform()
    z1, z2 = r * cos(a), r * sin(a)
    h, w = MH + SH * z1, MW + SW * (RHO * z1 + C * z2)
    n_tail += h > 185 and w > 90
    n_mid += 170 < h < 180
    n_heavy += w > 90
    n_ring += z1 * z1 + z2 * z2 < R50 * R50
    k = int((h - 152.5) // 3)
    if 0 <= k < 15:
        bins[k] += 1
p_sim = n_tail / N
se = sqrt(p_sim * (1 - p_sim) / N)
mid_exact = Phi(5 / 7) - Phi(-5 / 7)
mid_sim = n_mid / N
mid_se = sqrt(mid_sim * (1 - mid_sim) / N)
heavy_sim = n_heavy / N
heavy_se = sqrt(heavy_sim * (1 - heavy_sim) / N)

peak = f(MH, MW)
fh, fw = bell(MH, MH, SH), bell(MW, MW, SW)
box1 = grid(f, 174.5, 175.5, 77.5, 78.5)
box2 = grid(f, 174.95, 175.05, 77.95, 78.05)
pH, pW = 1 - Phi(10 / 7), 1 - Phi(1.0)
slice_area = simpson(lambda h: f(h, 78.0), HL, HR)
slice_sd = sqrt(simpson(lambda h: (h - MH) ** 2 * f(h, 78.0), HL, HR) / slice_area)
cut_total = grid(f, HL, HR, WL, 90.0)             # weight integral stopped at 90 kg

print(f"surface: centre {MH:.0f} cm, {MW:.0f} kg; spreads {SH:.0f} cm, {SW:.0f} kg; tilt {RHO}")
print(f"total volume under the surface, grid:        {total:.10f}")
print(f"covariance from the surface, grid:            {cov:.6f} cm kg (rho x 7 x 12 = {RHO * SH * SW:.1f})")
print(f"peak height f(175, 78):                       {peak:.6f} per cm per kg")
print(f"chance in the 1 cm x 1 kg box at the peak:   {box1:.6f}  (about 1 in {1 / box1:.0f})")
print(f"chance in the 1 mm x 100 g box at the peak:  {box2:.8f}")
print(f"marginal of height at 175, 1/(7 sqrt(2 pi)):  {fh:.6f} per cm")
print(f"marginal of weight at 78, 1/(12 sqrt(2 pi)):  {fw:.6f} per kg")
print(f"product of the two marginals at the peak:    {fh * fw:.6f}  (peak / product = {peak / (fh * fw):.4f})")
print(f"integrated-out marginal = normal bell, 154..196 cm, to 1e-12: {'yes' if marg_err < 1e-12 else 'no'}")
print(f"P(170 < H < 180), from the marginal:          {mid_exact:.4f}")
print(f"P(170 < H < 180), simulated:                  {mid_sim:.4f}  (se {mid_se:.4f})")
print(f"P(H > 185) = 1 - Phi(10/7):                   {pH:.4f}")
print(f"P(W > 90)  = 1 - Phi(1):                      {pW:.4f}")
print(f"P(W > 90), simulated:                         {heavy_sim:.4f}  (se {heavy_se:.4f})")
print(f"road 1, P(H > 185, W > 90), grid:             {tail_grid:.6f}")
print(f"road 2, P(H > 185, W > 90), slices:           {tail_slices:.6f}  (about 1 in {1 / tail_slices:.0f})")
print(f"hand steps: c = {C:.4f}, sqrt(2 pi) = {sqrt(2 * pi):.4f}, 2 pi x 7 x 12 x c = {2 * pi * SH * SW * C:.2f}, "
      f"z at 185 cm = {10 / 7:.4f}, z at 90 kg = {z90:.4f}, z at 170 and 180 cm = {-5 / 7:.4f}, {5 / 7:.4f}")
print(f"road 3, P(H > 185, W > 90), simulated:        {p_sim:.6f}  (se {se:.6f}, {n_tail} of {N})")
print(f"mistake 1, density read as a chance:          {peak:.6f}, but P(H = 175 and W = 78) = 0")
print(f"mistake 2, marginals multiplied:              {pH * pW:.6f}  vs {tail_slices:.6f}, true / product = {tail_slices / (pH * pW):.2f}")
print(f"mistake 3, slice at 78 kg read as a marginal: area {slice_area:.6f}, spread {slice_sd:.4f} cm")
print(f"weight integral stopped at 90 kg:            height marginal's total {cut_total:.4f}, Phi(1) = {Phi(1.0):.4f}")
print(f"simulated share inside the 50% ring:          {n_ring / N:.4f}")
print("chart, height (cm):     " + " ".join(f"{h:5d}" for h in range(154, 197, 3)))
print("chart, integrated, %/cm:" + " ".join(f"{100 * simpson(lambda w: f(h, w), WL, WR):5.2f}" for h in range(154, 197, 3)))
print("chart, simulated, %/cm: " + " ".join(f"{100 * b / (3 * N):5.2f}" for b in bins))
for p in (0.5, 0.9):                             # rings holding half and nine-tenths of adults
    r = sqrt(-2 * log(1 - p))
    pts = []
    for k in range(24):
        t = 2 * pi * k / 24
        h, w = MH + SH * r * cos(t), MW + SW * r * (RHO * cos(t) + C * sin(t))
        pts.append(f"{40 + 6 * (h - 150):.1f},{200 - 2.25 * (w - 40):.1f}")
    print(f"figure, ring {p:.0%}: " + " ".join(pts))
print(f"figure, tail corner (185 cm, 90 kg): {40 + 6 * 35:.1f},{200 - 2.25 * 50:.1f}")
assert abs(total - 1) < 1e-9 and abs(cov - RHO * SH * SW) < 1e-6   # grid vs the settings
assert marg_err < 1e-12                                             # integrating out gives the bell
assert abs(tail_grid - tail_slices) < 1e-7                          # road 1 vs road 2
assert abs(p_sim - tail_slices) < 4 * se                            # road 3 vs road 2
assert abs(mid_sim - mid_exact) < 4 * mid_se                        # ignoring W in data = marginal
assert abs(heavy_sim - pW) < 4 * heavy_se                           # ignoring H in data = marginal
assert abs(slice_area - fw) < 1e-9 and abs(slice_sd - SH * C) < 1e-6
assert abs(cut_total - Phi(1.0)) < 1e-7                           # the cut loses exactly P(W > 90)
print("ALL CHECKS PASS")
