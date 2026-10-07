# Adding continuous variables -- the check behind the card.  Standard library only.
# A commute: bus leg X ~ N(20, 3^2) minutes, train leg Y ~ N(35, 4^2), independent.
# Roads to the total S = X + Y: the closed form N(55, 5^2), the convolution
# integral done numerically, moment generating functions, and a seeded simulation.
from math import exp, log, sqrt, cos, sin, pi

def npdf(x, m, sd):                     # the normal density, written out
    z = (x - m) / sd
    return exp(-z * z / 2) / (sd * sqrt(2 * pi))

def Phi(z):                             # standard normal area left of z, by its Taylor series
    term, total, n = z, z, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(fn, a, b, n):               # Simpson's rule on n strips, n even
    h, s = (b - a) / n, fn(a) + fn(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * fn(a + i * h)
    return s * h / 3

def bus(x): return npdf(x, 20.0, 3.0)
def train(y): return npdf(y, 35.0, 4.0)
def h(s):                               # the convolution integral: slide the train across the bus
    return simpson(lambda x: bus(x) * train(s - x), -10.0, 50.0, 600)

h60_form, h60_conv = npdf(60.0, 55.0, 5.0), h(60.0)
p_form = Phi((60.0 - 55.0) / 5.0)
p_conv = simpson(h, 0.0, 60.0, 600)     # area under the convolved density, no normal CDF used
print("bus N(20, 3^2), train N(35, 4^2), independent; total S = bus + train")
print(f"road 1, closed form N(55, 5^2):  h(60) {h60_form:.6f}   P(S <= 60) {p_form:.6f}")
print(f"road 2, convolution integral:    h(60) {h60_conv:.6f}   P(S <= 60) {p_conv:.6f}")
grid = [h(s) - npdf(s, 55.0, 5.0) for s in range(30, 81)]
print(f"road 2 against road 1 at every whole minute 30..80, largest gap {max(abs(g) for g in grid):.1e}")
assert abs(h60_conv - h60_form) < 1e-9
assert abs(p_conv - p_form) < 1e-8
assert max(abs(g) for g in grid) < 1e-9

t = 0.1                                 # road 3: moment generating functions, integrated numerically
mx = simpson(lambda x: exp(t * x) * bus(x), -10.0, 50.0, 600)
my = simpson(lambda y: exp(t * y) * train(y), -10.0, 80.0, 900)
ms = simpson(lambda s: exp(t * s) * h(s), 10.0, 110.0, 400)
mf = exp(55.0 * t + 25.0 * t * t / 2)
print(f"road 3, MGF at t = 0.1: M_X M_Y {mx * my:.4f}   M_S from h {ms:.4f}   formula {mf:.4f}")
assert abs(mx * my / mf - 1) < 1e-9
assert abs(ms / mf - 1) < 1e-9

xs = [i / 100 for i in range(1000, 3401)]    # where along the slide the product peaks
peak = max(xs, key=lambda x: bus(x) * train(60.0 - x))
m_s = (16.0 * 20.0 + 9.0 * (60.0 - 35.0)) / 25.0
print(f"slide at s = 60: product peaks at bus {peak:.2f}, train {60 - peak:.2f}; formula {m_s:.2f}")
print(f"  peak height {bus(peak) * train(60.0 - peak):.6f}")
assert abs(peak - m_s) < 0.006

M64, state = (1 << 64) - 1, 20260928
def u01():                              # SplitMix64, top 53 bits as a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

N = 250000                              # road 4: simulate N days, two normals per day by Box-Muller
ok = okd = 0
tot = sq = yd_sq = 0.0
for _ in range(N):
    r, th = sqrt(-2 * log(1 - u01())), 2 * pi * u01()
    z1, z2 = r * cos(th), r * sin(th)
    s = (20 + 3 * z1) + (35 + 4 * z2)
    yd = 4 * (0.5 * z1 + sqrt(0.75) * z2)        # same weather: train leg correlated 0.5 with bus
    ok += s <= 60; okd += 55 + 3 * z1 + yd <= 60
    tot += s; sq += s * s; yd_sq += yd * yd
pe, pd = ok / N, okd / N
se, sed = sqrt(pe * (1 - pe) / N), sqrt(pd * (1 - pd) / N)
mean = tot / N
var = sq / N - mean * mean
print(f"road 4, simulation, seed 20260928, {N} days")
print(f"  P(S <= 60) {pe:.6f} +- {se:.6f}   mean {mean:.4f} +- {sqrt(var / N):.4f}   variance {var:.4f} +- {var * sqrt(2.0 / N):.4f}")
assert abs(pe - p_form) < 4 * se
assert abs(mean - 55.0) < 4 * sqrt(var / N)
assert abs(var - 25.0) < 4 * 25.0 * sqrt(2.0 / N)

print("what breaks")
p_sd = Phi(5.0 / 7.0)
print(f"  add the spreads, 3 + 4 = 7:       P(S <= 60) {p_sd:.6f}   true {p_form:.6f}")
p_dep = Phi(5.0 / sqrt(37.0))
print(f"  same weather, correlation 0.5:    formula for independent {p_form:.6f}")
print(f"    true Phi(5 / sqrt 37) {p_dep:.6f}   simulated {pd:.6f} +- {sed:.6f}")
sd_y = sqrt(yd_sq / N)
print(f"    train leg alone still spread 4: simulated {sd_y:.4f} +- {sd_y / sqrt(2.0 * N):.4f}")
assert abs(pd - p_dep) < 4 * sed
assert abs(pd - p_form) > 20 * sed
assert abs(sd_y - 4.0) < 4 * sd_y / sqrt(2.0 * N)
wait_conv = simpson(lambda w: bus(25.0 - w) / 10.0, 0.0, 10.0, 200)
wait_form = (Phi(5.0 / 3.0) - Phi(-5.0 / 3.0)) / 10.0
sdw = sqrt(9.0 + 100.0 / 12.0)
tail_conv = simpson(lambda w: (1 - Phi((18.0 - w) / 3.0)) / 10.0, 0.0, 10.0, 200)
tail_norm = 1 - Phi(13.0 / sdw)
print(f"  bus + platform wait uniform 0..10 (mean 25, spread {sdw:.4f}):")
print(f"    density at 25: convolution {wait_conv:.6f}   closed form {wait_form:.6f}   matched normal {npdf(25.0, 25.0, sdw):.6f}")
print(f"    P(bus + wait > 38): convolution {tail_conv:.6f}   matched normal {tail_norm:.6f}")
assert abs(wait_conv - wait_form) < 1e-9
assert tail_norm > 2 * tail_conv

print("try changing")
print(f"  bus spread 6 instead of 3: P(S <= 60) {Phi(5.0 / sqrt(52.0)):.6f}")
print(f"  allowance 65 minutes:      P(S <= 65) {Phi(2.0):.6f}")
ts = [10 + 2.5 * i for i in range(27)]           # chart 1: minutes 10, 12.5, ..., 75
print("chart 1, percent per minute, bus:   " + " ".join(f"{100 * bus(v):.2f}" for v in ts))
print("chart 1, percent per minute, train: " + " ".join(f"{100 * train(v):.2f}" for v in ts))
print("chart 1, percent per minute, total: " + " ".join(f"{100 * h(v):.2f}" for v in ts))
print("chart 2, x = 12..32, 1000 bus(x) train(60 - x): "
      + " ".join(f"{1000 * bus(v) * train(60.0 - v):.2f}" for v in range(12, 33)))
print("ALL CHECKS PASS")
