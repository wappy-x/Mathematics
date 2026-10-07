# Polynomials behave like integers -- the check behind the card.  Nothing is
# imported.  A polynomial is a list of whole-number coefficients, constant term
# first: [-6, 11, -6, 1] is x^3 - 6x^2 + 11x - 6 and [] is the zero polynomial.
# Every divisor here has leading coefficient 1, so whole numbers do; in general a field's fractions are needed.
def trim(p):                                   # drop zero top coefficients
    while p and p[-1] == 0: p.pop()
    return p
def show(p):                                   # write a polynomial the way the card does
    out = "" if p else "0"
    for k in range(len(p) - 1, -1, -1):
        c, a = p[k], abs(p[k])
        if c == 0: continue
        out += (" - " if c < 0 else " + ") if out else ("-" if c < 0 else "")
        out += ("" if a == 1 and k else str(a)) + ("" if k == 0 else "x" if k == 1 else f"x^{k}")
    return out
def value(p, t):                               # what the polynomial comes to at x = t
    return sum(c * t ** k for k, c in enumerate(p))
def divide(f, g):                              # long division, one top term cancelled at a time
    assert g and g[-1] == 1                    # the step needs 1 over the top coefficient
    q, r = [0] * max(0, len(f) - len(g) + 1), f[:]
    while r and len(r) >= len(g):
        k, c = len(r) - len(g), r[-1]
        q[k] = c
        for j, t in enumerate(g): r[k + j] -= c * t
        trim(r)
    return trim(q), r
def gcd(a, b):                                 # Euclid on whole numbers, the copied pattern
    while b: a, b = b, a % b
    return abs(a)
def primitive(p):                              # strip the shared whole-number constant
    d, s = 0, -1 if p[-1] < 0 else 1
    for c in p: d = gcd(d, c)
    return [s * c // d for c in p]
def euclid(f, g):                              # road one: divide, keep the remainder, repeat
    steps = []
    while g:
        q, r = divide(f, g)
        steps.append(f"{show(f)} = ({show(q)})({show(g)}) + {show(r)}")
        f, g = g, primitive(r) if r else []
    return f, steps
f, g, twog, root2 = [-6, 11, -6, 1], [-1, 0, 1], [-2, 0, 2], [-2, 0, 1]
q1, r1 = divide(f, g); h, steps = euclid(f, g)
rf = [t for t in range(-9, 10) if value(f, t) == 0]        # road two: hunt whole-number roots
rg, rh = [t for t in range(-9, 10) if value(g, t) == 0], [t for t in range(-9, 10) if value(h, t) == 0]
shared = [t for t in rf if t in rg]
print(f"f = {show(f)}, degree {len(f) - 1}; g = {show(g)}, degree {len(g) - 1}")
for i, s in enumerate(steps, 1): print(f"Euclid step {i}: {s}")
print(f"last nonzero remainder, made monic: {show(h)}, degree {len(h) - 1}")
print(f"whole-number roots -- f: {rf}, g: {rg}, shared: {shared}, gcd: {rh}")
print(f"f divided by {show(h)}: {show(divide(f, h)[0])}, remainder {show(divide(f, h)[1])}; g divided by {show(h)}: {show(divide(g, h)[0])}, remainder {show(divide(g, h)[1])}")
print(f"the same loop on whole numbers: 84 = {84 // 36} x 36 + {84 % 36}, 36 = {36 // 12} x 12 + {36 % 12}, gcd {gcd(84, 36)}")
print(f"stopping at the first quotient {show(q1)}: remainder {show(r1)}, not 0")
print(f"x + 1 divides g, so try it on f: remainder {show(divide(f, [1, 1])[1])}, and f(-1) = {value(f, -1)}")
print(f"constants are units: {show(twog)} strips to {show(primitive(twog))}, {show(r1)} strips to {show(primitive(r1))}")
print(f"{show(root2)} at x = -2, -1, 1, 2: {[value(root2, t) for t in (-2, -1, 1, 2)]}, no whole-number root")
assert all(value(f, t) == value(q1, t) * value(g, t) + value(r1, t) for t in range(-4, 5))
assert all(value(f, t) == (t - 1) * (t - 2) * (t - 3) for t in range(-4, 5))
assert rh == shared and len(h) - 1 == len(shared) and h[-1] == 1 and primitive(r1) == h
assert divide(f, [1, 1])[1] == [value(f, -1)] and value(f, -1) != 0
print("ALL CHECKS PASS")
