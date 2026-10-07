# Lp spaces -- the check behind the card.  Standard library only; nothing
# imported knows a norm.  The week's wind (3, 5, 8, 2, 6, 4, 7) m/s is sized
# under counting measure and under the uniform probability 1/7, each size by
# two roads; a one-hour gust is sized by an exact formula and by a midpoint
# sum; a three-point space is listed in full to show the a.e. classes.
from fractions import Fraction as Fr

V = [3, 5, 8, 2, 6, 4, 7]

def power_sum(f, p):                     # road one: add up |f|^p, point by point
    return sum(abs(x) ** p for x in f)

def layer_cake(f, p):                    # road two: slice by height, never touch a point
    total, below = 0, 0                  # (t^p - s^p) times the count of points above s
    for t in sorted(set(abs(x) for x in f)):
        total += (t ** p - below ** p) * sum(1 for x in f if abs(x) >= t)
        below = t
    return total

def norm(f, p, w=1.0):                   # p-norm with every point weighing w
    return (w * power_sum(f, p)) ** (1 / p)

def midpoint(g, a, b, n):                # our own integrator: n equal cells
    h = (b - a) / n
    return h * sum(g(a + (k + 0.5) * h) for k in range(n))

print("1. the week under counting measure (each day weighs 1)")
for p in (1, 2, 3):
    print(f"   p = {p}: sum of |v|^p = {power_sum(V, p)}, by layers {layer_cake(V, p)}, norm {norm(V, p):.4f}")
print(f"   sup-norm = {max(V)}: every day weighs 1, so no day can be ignored")
print("2. the week under the uniform probability (each day weighs 1/7)")
for p in (1, 2, 3):
    exact = Fr(power_sum(V, p), 7)
    print(f"   p = {p}: mean of |v|^p = {exact}, norm {norm(V, p, 1 / 7):.4f}, "
          f"= 7^(-1/{p}) x counting norm {7 ** (-1 / p) * norm(V, p):.4f}")
dev = [x - 5 for x in V]
print(f"   deviation from the mean {dev}: squares sum to {power_sum(dev, 2)}, 2-norm "
      f"{norm(dev, 2, 1 / 7):.4f} m/s, and {Fr(power_sum(V, 2), 7)} = 5^2 + {Fr(power_sum(dev, 2), 7)}")
print("3. the p-norm as p grows (chart)")
PS = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
cnt = [norm(V, p) for p in PS]
uni = [norm(V, p, 1 / 7) for p in PS]
print("   p        " + " ".join(f"{p:>5}" for p in PS))
print("   counting " + " ".join(f"{x:5.2f}" for x in cnt))
print("   uniform  " + " ".join(f"{x:5.2f}" for x in uni))
print(f"   squeeze at p = 32: {8 * 7 ** (-1 / 32):.4f} <= uniform <= 8 <= counting <= {8 * 7 ** (1 / 32):.4f}")
print("4. a one-hour gust u(t) = 8t on [0, 1], length as the measure")
for p in (1, 2, 3):
    exact = 8 / (p + 1) ** (1 / p)
    mid = midpoint(lambda t: (8 * t) ** p, 0.0, 1.0, 100000) ** (1 / p)
    print(f"   p = {p}: exact 8/(p+1)^(1/p) = {exact:.4f}, midpoint sum {mid:.4f}")
# the logger's glitch: 40 m/s at the single instant t = 0.5.  The glitched record as pieces
# (a, b, c0, c1), speed c0 + c1 t from a to b; the glitch is the piece of length 0
rec = [(0.0, 0.5, 0, 8), (0.5, 0.5, 40, 0), (0.5, 1.0, 0, 8)]
plain = max(c0 + c1 * t for a, b, c0, c1 in rec for t in (a, b))     # largest value; a straight piece peaks at an end
above = lambda M: sum(midpoint(lambda t: float(c0 + c1 * t > M), a, b, 1000) for a, b, c0, c1 in rec)  # length above M
ess = next(M for M in range(0, 41) if above(M) == 0)                 # least ceiling broken only on length 0
print(f"   with a 40 m/s glitch at t = 0.5: plain sup {plain:.0f}, ess sup {ess} "
      f"(length above 7 is {above(7):.4f}, above 8 is {above(8):.4f})")
print(f"   p-norms climb to the ess sup, not the glitch: p = 100 gives {8 / 101 ** (1 / 100):.4f}, "
      f"p = 1000 gives {8 / 1001 ** (1 / 1000):.4f}")
print("5. the spike s(t) = 1/sqrt(t) on (0, 1]: in L^1, not in L^2")
one = sum(midpoint(lambda t: t ** -0.5, 2.0 ** -(j + 1), 2.0 ** -j, 2000) for j in range(60))
piece = midpoint(lambda t: 1 / t, 0.5, 1.0, 2000)
print(f"   1-norm by 60 halvings {one:.4f}; exact 2")
print(f"   integral of s^2 = 1/t over each halving [2^-(j+1), 2^-j]: {piece:.4f} every time")
print(f"   down to 2^-10, 2^-20, 2^-40: {10 * piece:.2f}, {20 * piece:.2f}, {40 * piece:.2f}: no finite 2-norm")
print("6. a.e. classes, listed in full: Mon and Tue weigh 1, the glitch instant weighs 0")
W3 = [1, 1, 0]
funcs = [(a, b, c) for a in (0, 1) for b in (0, 1) for c in (0, 1)]
same = lambda f, g: sum(w for x, y, w in zip(f, g, W3) if x != y) == 0   # differ on a null set only
n2 = lambda f: Fr(sum(w * x * x for x, w in zip(f, W3)))                  # squared 2-norm, exact
classes = []
for f in funcs:
    for cl in classes:
        if same(f, cl[0]):
            cl.append(f)
            break
    else:
        classes.append([f])
for cl in classes:
    print(f"   class {cl}: squared 2-norm {sorted(set(int(n2(f)) for f in cl))}")
zero = [f for f in funcs if n2(f) == 0]
add = lambda f, g: tuple(x + y for x, y in zip(f, g))
checks = [(f1, f2, g1, g2) for c1 in classes for c2 in classes
          for f1 in c1 for f2 in c1 for g1 in c2 for g2 in c2]
good = sum(1 for f1, f2, g1, g2 in checks if same(add(f1, g1), add(f2, g2)))
print(f"   {len(funcs)} functions, {len(classes)} classes; norm zero on {zero}")
print(f"   sums of representatives landing in one class: {good} of {len(checks)}")
print("7. conjugate exponents and why 1/p + 1/q = 1")
for p, q in ((Fr(1), "infinity"), (Fr(3, 2), 3), (Fr(2), 2), (Fr(3), Fr(3, 2))):
    print(f"   p = {p}: q = {q}" + ("" if p == 1 else f", 1/p + 1/q = {1 / p + 1 / Fr(q)}"))
def ratio(p, q, c):                      # integral of v times 1, over ||v||_p ||1||_q, weight c
    return c * sum(V) / (norm(V, p, c) * norm([1] * 7, q, c))
for p, q in ((2, 2), (3, 1.5), (2, 3)):
    print(f"   p = {p}, q = {q}: ratio at weight 1/7, 1, 7, 49 = "
          + ", ".join(f"{ratio(p, q, c):.4f}" for c in (1 / 7, 1, 7, 49)))
print("8. what breaks")
a, b = [1, 0, 0, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0, 0]
half = lambda f: sum(abs(x) ** 0.5 for x in f) ** 2
print(f"   p = 1/2 on Mon and Tue alone: size of the sum {half(add(a, b)):.0f} > {half(a) + half(b):.0f}")
print(f"   no root: sum of |2v|^2 = {power_sum([2 * x for x in V], 2)} = 4 x 203; "
      f"with the root {norm([2 * x for x in V], 2):.4f} = 2 x {norm(V, 2):.4f}")
print("figure, bars 3 5 8 2 6 4 7; levels 5.00 5.70 8.00")

for p in (1, 2, 3, 4):                   # two roads to each counting power sum
    assert power_sum(V, p) == layer_cake(V, p)
assert Fr(power_sum(V, 2), 7) == Fr(sum(V), 7) ** 2 + Fr(power_sum(dev, 2), 7)   # 29 = 25 + 4
for p in (1, 2, 3):                      # exact gust norm against the midpoint sum
    assert abs(8 / (p + 1) ** (1 / p) - midpoint(lambda t: (8 * t) ** p, 0, 1, 100000) ** (1 / p)) < 1e-6
assert abs(one - 2) < 1e-4 and abs(piece - 0.6931471805599453) < 1e-6
assert len(classes) == 4 and all(len(c) == 2 for c in classes) and good == len(checks)
assert all(8 * 7 ** (-1 / p) <= u <= 8 <= c <= 8 * 7 ** (1 / p) for p, u, c in zip(PS, uni, cnt))
for p in (1, 2, 3):                      # uniform norm, directly and through 7^(-1/p)
    assert abs(norm(V, p, 1 / 7) - 7 ** (-1 / p) * norm(V, p)) < 1e-12
assert plain == 40 and ess == 8 and zero in classes and half(add(a, b)) > half(a) + half(b)
for p, q in ((2, 2), (3, 1.5)):          # conjugate pairs: the ratio ignores the weight
    assert all(abs(ratio(p, q, c) - ratio(p, q, 1)) < 1e-12 for c in (1 / 7, 7, 49))
assert abs(ratio(2, 3, 49) / ratio(2, 3, 1) - 49 ** (1 - 1 / 2 - 1 / 3)) < 1e-9   # scales as c^(1/6)
print("ALL CHECKS PASS")
