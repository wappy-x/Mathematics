# Newton-Cotes and composite rules -- the check behind the card.  Standard library only.
# A day's wind energy (illustrative): wind v(t) = 3 + t(24 - t)/24 m/s at t hours,
# turbine power P = c v^3 kW with c = 0.02, readings every 10 minutes, energy in kWh.
# Road 1: the exact energy from moments of s(1 - s).  Road 2: the 7-point Newton-Cotes
# rule in exact fractions, exact by its degree.  Road 3: five composite rules at four
# spacings, with observed orders.  Every weight is the integral of a Lagrange basis.
from fractions import Fraction as Fr
import math

def v(t): return 3 + t * (24 - t) / 24
def P(t): return v(t) * v(t) * v(t) / 50                  # kW; works on floats and fractions

def weights(nodes, length):                                 # integral of each Lagrange basis over
    ws = []                                                 # [0, length], per unit of width
    for j in nodes:
        poly, den = [Fr(1)], Fr(1)                          # coefficients, constant term first
        for k in nodes:
            if k != j:
                poly = [Fr(0)] + poly                       # multiply by (t - k)
                for r in range(len(poly) - 1):
                    poly[r] -= k * poly[r + 1]
                den *= j - k
        ws.append(sum(c * Fr(length) ** (r + 1) / (r + 1) for r, c in enumerate(poly)) / den / length)
    return ws
def closed(m): return [Fr(j, m) for j in range(m + 1)], weights(range(m + 1), m)
def opened(p): return [Fr(j, p + 1) for j in range(1, p + 1)], weights(range(1, p + 1), p + 1)
def total(terms):                                           # plain left-to-right sum, as in Rust
    s = 0.0                                                 # (Python's sum() compensates floats)
    for t in terms:
        s += t
    return s
def apply(rule, f, a, b, panels):                           # the rule on each panel, added up
    xs, ws = rule
    H = (b - a) / panels
    return total(float(w) * H * f(a + (p + float(x)) * H) for p in range(panels) for x, w in zip(xs, ws))
def fr(q): return f"{q.numerator}/{q.denominator}" if q.denominator > 1 else f"{q.numerator}"

# Road 1: t = 24s, v = 3 + 24u with u = s(1 - s), and the integral of u^j over [0, 1] is j!^2/(2j+1)!
E = Fr(24, 50) * sum(math.comb(3, j) * 3 ** (3 - j) * 24 ** j * Fr(math.factorial(j) ** 2, math.factorial(2 * j + 1)) for j in range(4))
Ef = float(E)
print(f"exact energy, road 1: {fr(E)} kWh = {Ef:.9f} kWh; P at 0 h {P(0.0):.4f} kW, at 12 h {P(12.0):.4f} kW")
print(f"chart, P in kW at t = 0, 2, ..., 24 h: {', '.join(f'{P(2.0 * i):.2f}' for i in range(13))}")
rules = {"midpoint": opened(1), "trapezoid": closed(1), "Simpson": closed(2), "three-eighths": closed(3),
         "Boole": closed(4), "open 2-point": opened(2), "Milne": opened(3), "7-point": closed(6)}
degree = {}
for name, (xs, ws) in rules.items():
    p = 0
    while sum(w * x ** p for x, w in zip(xs, ws)) == Fr(1, p + 1):    # exact fractions, so == is the test
        p += 1
    degree[name] = p - 1
    print(f"{name:>13}: nodes {', '.join(fr(x) for x in xs)}; weights {', '.join(fr(w) for w in ws)}; degree {p - 1}")
assert [degree[k] for k in rules] == [1, 1, 3, 3, 5, 1, 3, 7]          # odd degree from symmetry, every time
assert rules["Simpson"][1] == [Fr(1, 6), Fr(2, 3), Fr(1, 6)] and rules["Boole"][1] == [Fr(7, 90), Fr(16, 45), Fr(2, 15), Fr(16, 45), Fr(7, 90)]

xs7, ws7 = rules["7-point"]                                 # Road 2: one panel, readings every 4 hours
E7 = sum(w * 24 * P(24 * x) for x, w in zip(xs7, ws7))
E7f = apply(rules["7-point"], P, 0.0, 24.0, 1)
print(f"road 2, 7-point rule on 7 readings, fractions: {fr(E7)} kWh; in floats {E7f:.9f}, off by {abs(E7f - Ef):.1e}")
assert E7 == E and abs(E7f - Ef) < 1e-12                    # degree 7 >= 6: exact, up to rounding

print("road 3: errors in kWh (true error) at spacing 40, 20, 10, 5 minutes; observed order")
errs = {}
for name in ("midpoint", "trapezoid", "Simpson", "three-eighths", "Boole"):
    m = len(rules[name][0]) - 1 if name != "midpoint" else 1
    errs[name] = [apply(rules[name], P, 0.0, 24.0, n // m) - Ef for n in (36, 72, 144, 288)]
    orders = [math.log2(abs(errs[name][i] / errs[name][i + 1])) for i in range(3)]
    print(f"{name:>13}: {', '.join(f'{e:.3e}' for e in errs[name])}; order {', '.join(f'{o:.2f}' for o in orders)}")
    assert abs(orders[-1] - (degree[name] + 1)) < 0.05      # order = degree of exactness + 1
Bx = float(sum(w * Fr(1, 3) * P(Fr(p, 3) + x / 3) for p in range(72) for x, w in zip(*rules["Boole"])) - E)
print(f"Boole at 5 minutes in exact fractions: error {Bx:.3e}; in floats {errs['Boole'][3]:.3e}")
assert abs(Bx - errs["Boole"][3]) < 1e-13 and abs(Bx) > 1e-11   # rounding moves only the 4th digit
floor = [apply(rules["Boole"], P, 0.0, 24.0, n // 4) - Ef for n in (576, 1152, 2304)]
print(f"rounding floor: Boole at 2.5, 1.25, 0.625 minutes: {', '.join(f'{e:.3e}' for e in floor)}")
h2 = [P(2.0 * i) for i in range(13)]                       # by hand: 13 readings, 2 hours apart
ends, odd, even = h2[0] + h2[12], total(h2[1:12:2]), total(h2[2:11:2])
S12, T12 = 2 / 3 * (ends + 4 * odd + 2 * even), 2 * (ends / 2 + odd + even)
print(f"by hand, 2-hour readings: ends {ends:.4f}, odd sum {odd:.4f}, even inner sum {even:.4f}; Simpson {S12:.4f}, error {S12 - Ef:.4f}; trapezoid {T12:.4f}, error {T12 - Ef:.4f}")
assert abs(S12 - apply(rules["Simpson"], P, 0.0, 24.0, 6)) < 1e-12 and abs(S12 - Ef) < abs(T12 - Ef) / 50
T10, S10, B10 = (apply(rules[k], P, 0.0, 24.0, 144 // m) for k, m in (("trapezoid", 1), ("Simpson", 2), ("Boole", 4)))
print(f"10-minute readings, 145 of them: trapezoid {T10:.6f}, Simpson {S10:.6f}, Boole {B10:.9f} kWh")
assert abs(errs["midpoint"][2] / errs["trapezoid"][2] + 0.5) < 0.01   # midpoint error: half, opposite sign
print(f"midpoint over trapezoid error at 10 minutes: {errs['midpoint'][2] / errs['trapezoid'][2]:.4f}")
for name in ("trapezoid", "Simpson", "Boole"):
    print(f"chart, {name} log10 |error| at log10 h = -0.18, -0.48, -0.78, -1.08: {', '.join(f'{math.log10(abs(e)):.2f}' for e in errs[name])}")

print("closed rules: m slices per panel, sum of |weights| per unit width, smallest weight")
grow = []
for m in range(1, 13):
    ws = closed(m)[1]
    grow.append(sum(abs(w) for w in ws))
    if m in (1, 2, 4, 6, 7, 8, 9, 10, 11, 12):
        print(f"m = {m:2}: sum |w| {float(grow[-1]):.4f}, smallest {float(min(ws)):.4f}")
assert all(g == 1 for g in grow[:7]) and grow[7] > 1 and all(grow[i] < grow[i + 2] for i in range(7, 10))
print(f"noise: readings off by up to 0.05 kW move the answer at most 0.05 x 24 x sum |w|: composite {0.05 * 24:.2f} kWh, one 13-point rule {0.05 * 24 * float(grow[11]):.2f} kWh")

def runge(x): return 1 / (1 + 25 * x * x)
R = 0.4 * math.atan(5.0)
print(f"bell 1/(1 + 25x^2) on [-1, 1], exact {R:.10f}; m + 1 equally spaced points")
bad = []
for m in (2, 4, 6, 8, 10, 12):
    one, comp = apply(closed(m), runge, -1.0, 1.0, 1), apply(closed(2), runge, -1.0, 1.0, m // 2)
    bad.append((abs(one - R), abs(comp - R)))
    print(f"m = {m:2}: one degree-{m} rule error {abs(one - R):.2e}; composite Simpson on the same points {abs(comp - R):.2e}")
assert bad[-1][0] > bad[2][0] and bad[-1][1] < bad[2][1] < bad[0][1]   # the one rule worsens, the composite improves

T143 = 143 / 6                                              # one reading lost: 143 slices to 23:50
E143 = sum(w * Fr(143, 6) * P(Fr(143, 6) * x) for x, w in zip(xs7, ws7))   # exact by the 7-point rule
h = 1 / 6
s143 = h / 3 * (P(0.0) + P(T143) + total((4 if i % 2 else 2) * P(i * h) for i in range(1, 143)))
s142 = apply(rules["Simpson"], P, 0.0, 142 / 6, 71) + apply(rules["trapezoid"], P, 142 / 6, T143, 1)
plain = total(P(i * h) for i in range(145)) * h
print(f"mistake, Simpson weights on 143 slices: {s143:.4f} kWh against {float(E143):.4f}, error {s143 - float(E143):.4f}")
print(f"repair: Simpson on 142 slices plus one trapezoid slice: {s142:.4f} kWh, error {s142 - float(E143):.2e}")
print(f"mistake, h in minutes (10, not 1/6 hour): {apply(rules['trapezoid'], lambda t: P(t / 60), 0.0, 1440.0, 144):.2f} 'kWh'")
print(f"mistake, every reading times h, no halved ends: {plain:.4f} kWh, error {plain - Ef:.4f}")
assert abs(s143 - float(E143)) > 100 * abs(s142 - float(E143)) and abs(plain - T10 - h * P(0.0)) < 1e-9
assert abs(s143 - (s142 - h / 6 * (P(142 * h) + P(T143)))) < 1e-12   # last slice weighted h/3, h/3, not h/2, h/2
print("ALL CHECKS PASS")
