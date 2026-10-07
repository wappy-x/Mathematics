# Densities and CDFs -- the check behind the card.  Nothing is imported but
# the math primitives.  A share's daily return, in percent, is modelled by a
# bell-shaped density centred at 0 with spread 1.2.  The chance of a fall of
# more than 2 percent is reached three ways: strips under the density, the
# CDF's own power series, and seeded random draws.  Every number is printed.
from math import exp, log, sqrt, cos, pi

SIGMA, CUT, DAYS = 1.2, -2.0, 252

def f(x):                                  # the density: chance per percentage point
    return exp(-x * x / (2 * SIGMA * SIGMA)) / (SIGMA * sqrt(2 * pi))

def simpson(g, a, b, n):                   # area under g from a to b, n even strips
    h = (b - a) / n
    s = g(a) + g(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * g(a + i * h)
    return s * h / 3

def F(x):                                  # the CDF by its power series, no integrator
    z, term, total, n = x / SIGMA, x / SIGMA, 0.0, 0
    while abs(term) > 1e-17:               # term n is (-1)^n z^(2n+1) / (2^n n! (2n+1))
        total += term / (2 * n + 1)
        n += 1
        term *= -z * z / (2 * n)
    return 0.5 + total / sqrt(2 * pi)

MASK = (1 << 64) - 1
state = 20260928                           # SplitMix64, seed stated, same in Rust
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 2.0 ** 53   # strictly between 0 and 1

road1 = simpson(f, -12.0, CUT, 20000)
road2 = F(CUT)
draws, below, in_bin = 400000, 0, 0
for _ in range(draws // 2):                # Box-Muller: two uniforms make two bell draws
    r, t = sqrt(-2 * log(uniform())), 2 * pi * uniform()
    for x in (SIGMA * r * cos(t), SIGMA * r * cos(t - pi / 2)):
        below += x < CUT
        in_bin += -2.25 <= x < -1.75
p3 = below / draws
se3 = sqrt(p3 * (1 - p3) / draws)
hb = in_bin / draws / 0.5
binx = (F(-1.75) - F(-2.25)) / 0.5
seb = sqrt(in_bin / draws * (1 - in_bin / draws) / draws) / 0.5
slope = (F(-1.999) - F(-2.001)) / 0.002

def row(label, value, digits=6):
    print(f"{label:<52} {value:.{digits}f}")

print(f"daily return: bell-shaped density, centre 0%, spread {SIGMA}%")
row("z = -2 / 1.2, the cut in units of spread", CUT / SIGMA)
row("road 1, 20000 strips under f from -12% to -2%", road1)
row("road 2, F(-2) by power series at z = -2/1.2", road2)
row("road 3, share of 400000 seeded draws below -2%", p3)
row("  its standard error", se3)
print(f"  draws below -2%: {below} of {draws}")
row("fall of more than 2% on 252 days, expected count", DAYS * road2, 2)
row("one day in N, N = 1 / F(-2)", 1 / road2, 1)
row("f(-2), density height at -2%, per point", f(CUT))
row("slope of F at -2%, (F(-1.999) - F(-2.001)) / 0.002", slope)
row("draws in -2.25% to -1.75%, per point of width", hb)
row("  its standard error", seb)
row("  exact, (F(-1.75) - F(-2.25)) / 0.5", binx)
row("f(0), density height at the centre, per point", f(0.0))
row("F(0), chance of a return at or below 0%", F(0.0))
row("total area under f, -12% to 12%", simpson(f, -12.0, 12.0, 20000))
row("F(1) - F(-1), a day between -1% and +1%", F(1.0) - F(-1.0))
for w in (0.1, 0.01, 0.001):
    row(f"chance within a strip of width {w} at -2%", F(CUT + w / 2) - F(CUT - w / 2))
row("wrong: height f(-2) read as the chance", f(CUT))
row("wrong: returns as decimals, height at centre", f(0.0) * 100, 3)
row("wrong: either way, below -2% or above +2%", F(CUT) + 1 - F(-CUT))
row("wrong: F(-2) plus f(-2) for the point itself", F(CUT) + f(CUT))
print("by hand: strips 0.5 wide from -5% to -2%, centre, height, area")
hand = 0.0
for c in (-2.25, -2.75, -3.25, -3.75, -4.25, -4.75):
    hand += 0.5 * f(c)
    print(f"  {c:6.2f}  {f(c):.4f}  {0.5 * f(c):.4f}")
row("  sum of the six strip areas", hand, 4)
row("  area left of -5%, left out by hand", F(-5.0))
row("  gap, road 2 minus the hand sum", road2 - hand, 4)
row("try: spread 1.5% instead of 1.2%, chance below -2%", F(CUT * SIGMA / 1.5))
row("try: cut at -3% instead of -2%, chance below it", F(-3.0))
xs = [-4.0 + 0.5 * i for i in range(17)]
print("chart, x   " + " ".join(f"{x:.1f}" for x in xs))
print("chart, F   " + " ".join(f"{F(x):.2f}" for x in xs))
px = lambda x: 180 + 30 * x                # figure: 30 px per point, baseline at y = 200
py = lambda x: 200 - 500 * f(x)
pts = [-5.0 + 0.5 * i for i in range(21)]
for k in range(3):
    print("figure, " + " ".join(f"{px(x):.0f},{py(x):.1f}" for x in pts[7 * k:7 * k + 7]))
print(f"figure, tail from x = {px(-5.0):.0f} to {px(CUT):.0f}, baseline y = 200")

assert abs(road1 - road2) < 1e-9                    # strips against series
assert abs(p3 - road2) < 4 * se3                    # draws against series
assert abs(slope - f(CUT)) < 1e-6                   # CDF's slope is the density
assert abs(hb - binx) < 4 * seb                     # bin share per width vs CDF
assert abs(simpson(f, -12.0, 12.0, 20000) - 1.0) < 1e-9
print("ALL CHECKS PASS")
