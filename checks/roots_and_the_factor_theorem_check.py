# Roots and the factor theorem -- the check behind the card.  Nothing imported.
# The tank: three edges adding to 6 m, pairwise products 11 m^2, volume 6 m^3.
# Its cubic is x^3 - 6x^2 + 11x - 6, written highest power first.
TANK, REPEAT, VOL12 = [1, -6, 11, -6], [1, -6, 9, -4], [1, -6, 11, -12]

def value(p, x):                          # p at x, by nested multiplication
    out = 0
    for c in p:
        out = out * x + c
    return out

def peel(p, r):                           # divide p by x - r: quotient, remainder
    out = [p[0]]
    for c in p[1:]:
        out.append(out[-1] * r + c)
    return out[:-1], out[-1]

def multiply(p, q):                       # road two: multiply two polynomials out
    out = [0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            out[i + j] += a * b
    return out

def whole_roots(p):                       # every whole number from -20 to 20 giving 0
    return [x for x in range(-20, 21) if value(p, x) == 0]

def show(p):                              # a list of numbers, as one line
    return " ".join(str(c) for c in p)

print("tank cubic, highest power first:", show(TANK))
print("p at 0, 1, 2, 3, 4:", show([value(TANK, x) for x in range(5)]))
left = TANK
for r in (1, 2, 3):
    q, rem = peel(left, r)
    print(f"peel x - {r}: quotient {show(q)}, remainder {rem}")
    assert rem == 0 and value(TANK, r) == 0
    left = q
rebuilt = multiply(multiply([1, -1], [1, -2]), [1, -3])
print("rebuilt (x - 1)(x - 2)(x - 3):", show(rebuilt))
a, b, c = 1, 2, 3
print(f"edges: sum {a + b + c}, pairwise products {a * b + a * c + b * c}, volume {a * b * c}")
cands = [d for d in range(-6, 7) if d != 0 and 6 % d == 0]
print("whole-number candidates, the divisors of 6:", show(cands))
print("p at those candidates:", show([value(TANK, d) for d in cands]))
print(f"whole roots of the tank cubic in -20..20: {show(whole_roots(TANK))}  (3 of them, degree 3)")
print(f"volume 12 instead, x^3 - 6x^2 + 11x - 12: {show(whole_roots(VOL12))}  (1 root, degree 3)")
print(f"repeated root, x^3 - 6x^2 + 9x - 4: {show(whole_roots(REPEAT))}  (2 distinct, degree 3)")
print("p at -1, the sign slip:", value(TANK, -1))
print("p at 4, a number that does not divide 6:", value(TANK, 4))
xs = [0.5 + 0.25 * i for i in range(13)]
print("chart x:", " ".join(f"{x:.2f}" for x in xs))
print("chart p:", " ".join(f"{value(TANK, x):.2f}" for x in xs))
assert rebuilt == TANK and multiply([1, -1], [1, -2]) == [1, -3, 2]
assert whole_roots(TANK) == [1, 2, 3] and whole_roots(REPEAT) == [1, 4] and whole_roots(VOL12) == [4]
assert value(TANK, -1) == -24 and value(TANK, 4) == 6 and left == [1]
print("ALL CHECKS PASS")
