# Poles on the path -- the check behind the card.  Standard library only.
# Road one: dent the path round the pole at 0.  The dent keeps -i pi times the
# residue, so PV of e^(ix)/x is i pi and the area under sin x/x is pi.
# Road two: add the humps of sin x/x between multiples of pi, then average the
# partial sums until they settle.  Second example: 1/(x(1+x^2)), PV 0.
import math

def show(w):                                     # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def simpson(g, a, b, n=2000):                    # Simpson's rule on n (even) panels
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if j % 2 else 2) * g(a + j * h) for j in range(1, n)))
def arc(f, r, start, end):                       # z = r e^(it), dz = i z dt, t from start to end
    return simpson(lambda t: f(r * complex(math.cos(t), math.sin(t))) * 1j * r * complex(math.cos(t), math.sin(t)), start, end)
def wave(z): return complex(math.cos(z.real), math.sin(z.real)) * math.exp(-z.imag) / z   # e^(iz)/z
def rat(z): return 1 / (z * (1 + z * z))         # 1/(z(1+z^2))
def r6(x): return f"{round(x, 6) + 0.0:.6f}"      # six decimals, no -0.000000
def sinc(x): return math.sin(x) / x if x else 1.0
def F(x): return math.log(abs(x)) - 0.5 * math.log(1 + x * x)   # antiderivative of 1/(x(1+x^2)), x not 0

def res(f, a, d=1e-5):                           # residue by its limit (z - a) f(z), from both sides
    return (d * f(a + d) - d * f(a - d)) / 2
c_wave, c_rat, c_i = res(wave, 0j), res(rat, 0j), res(rat, 1j)
print(f"residues by limit: e^(iz)/z at 0 {show(c_wave)}; 1/(z(1+z^2)) at 0 {show(c_rat)}, at i {show(c_i)}")
for eps, R in ((0.5, 5), (0.1, 10), (0.01, 20)):
    dent, big = arc(wave, eps, math.pi, 0), arc(wave, R, 0, math.pi)
    off, bound = abs(dent + 1j * math.pi * c_wave), math.pi * (math.exp(eps) - 1)
    print(f"dent eps = {eps}: {show(dent)}, off -pi i by {off:.6f} (bound {bound:.6f}); big arc R = {R}: size {abs(big):.6f} (Jordan bound {math.pi / R:.6f})")
    assert off <= bound and abs(big) <= math.pi / R
seg = 2j * simpson(sinc, 0.1, 10)                # the two real pieces of e^(ix)/x, eps = 0.1, R = 10
dent, big = arc(wave, 0.1, math.pi, 0), arc(wave, 10, 0, math.pi)
print(f"closed at eps = 0.1, R = 10: segments {show(seg)} + dent {show(dent)} + arc {show(big)} = {show(seg + dent + big)}")
assert abs(seg + dent + big) < 1e-8              # Cauchy: no pole inside, so the loop is 0
road1 = math.pi * c_wave.real                    # PV of e^(ix)/x = -(dent limit) = i pi c
print(f"road 1, dent: PV of e^(ix)/x = {show(1j * road1)}, so area under sin x/x = {road1:.6f}")
sums = [0.0]                                     # road 2: the humps, then repeated averaging
for k in range(40):
    sums.append(sums[-1] + simpson(sinc, k * math.pi, (k + 1) * math.pi, 400))
sums = sums[1:]
for _ in range(20):
    sums = [(p + q) / 2 for p, q in zip(sums, sums[1:])]
road2 = 2 * sums[-1]
print(f"road 2, 40 humps summed and averaged 20 times: {road2:.6f}")
assert abs(road1 - road2) < 1e-9
print("chart, area from -X to X, X = 2, 4, ..., 20:", ", ".join(f"{2 * simpson(sinc, 0, X):.2f}" for X in range(2, 21, 2)), f"(pi {math.pi:.2f})")
for eps in (0.01, 0.0001):
    print(f"1/(x(1+x^2)), gap eps = {eps}: right piece {F(1) - F(eps):.6f}, left piece {F(-eps) - F(-1):.6f}, sum {r6(F(1) - F(eps) + F(-eps) - F(-1))}")
real = F(-0.01) - F(-10) + F(10) - F(0.01)        # both real pieces, eps = 0.01, R = 10
dent, big, loop = arc(rat, 0.01, math.pi, 0), arc(rat, 10, 0, math.pi), 2j * math.pi * c_i
print(f"closed at eps = 0.01, R = 10: real {r6(real)} + dent {show(dent)} + arc {show(big)} (bound {math.pi / 99:.6f}) = {show(real + dent + big)}; 2 pi i x Res at i = {show(loop)}")
assert abs(big) <= math.pi / 99 and abs(real + dent + big - loop) < 1e-8   # arc bound pi/(R^2 - 1)
print(f"PV of 1/(x(1+x^2)) = loop - dent limit = {show(loop + 1j * math.pi * c_rat)}")
print(f"mistake, full residue at 0: {2 * math.pi * c_wave.real:.6f}; dent run anticlockwise: {-road1:.6f}; left gap 2 eps = 0.001: {F(0.002) - F(0.001):.6f} (ln 2 = {math.log(2):.6f})")
print(f"mistake, double pole 1/z^2, dent eps = 0.01: {show(arc(lambda z: 1 / (z * z), 0.01, math.pi, 0))}, though its residue is 0")
o, s = (180, 170), 60                            # figure: 0 at (180, 170), 60 units per 1, R = 2, eps = 0.25
print(f"figure, segments ({o[0] - 2 * s:.2f}, {o[1]:.2f})-({o[0] - s / 4:.2f}, {o[1]:.2f}) and ({o[0] + s / 4:.2f}, {o[1]:.2f})-({o[0] + 2 * s:.2f}, {o[1]:.2f}); dent top ({o[0]:.2f}, {o[1] - s / 4:.2f}); arc top ({o[0]:.2f}, {o[1] - 2 * s:.2f}); i at ({o[0]:.2f}, {o[1] - s:.2f})")
print("ALL CHECKS PASS")
