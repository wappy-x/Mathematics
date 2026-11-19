# Morphisms and fibre products -- the check behind the card.  Nothing is
# imported.  The family is y^2 = x^3 + t over the t-line: the ring map
# t -> y^2 - x^3 read backwards as the map (x, y) -> t.  A polynomial in x, y
# is a dict {(i, j): coeff} for x^i y^j.  Roads: expand polynomials exactly;
# put points back in; count over F_7 by brute force against a character sum;
# build a fibre product from joined equations against a sum over fibres.
def mul(a, b):
    out = {}
    for (i, j), c in a.items():
        for (k, l), d in b.items():
            out[(i + k, j + l)] = out.get((i + k, j + l), 0) + c * d
    return {m: c for m, c in out.items() if c}

def add(a, b, s=1):
    out = dict(a)
    for m, c in b.items():
        out[m] = out.get(m, 0) + s * c
    return {m: c for m, c in out.items() if c}

def ev(g, x, y):
    return sum(c * x ** i * y ** j for (i, j), c in g.items())

def gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)

def yn(claim):
    return "yes" if claim else "no"

pi = lambda x, y: y * y - x ** 3              # the map to the t-line, (x, y) -> t
phi_t = {(0, 2): 1, (3, 0): -1}               # phi*(t) = y^2 - x^3, as a polynomial
print("ring map phi*: Q[t] -> Q[x, y], t -> y^2 - x^3; field Q, counts over F_7")
print(f"(3, 5) lies over t = 25 - 27 = {pi(3, 5)}; (2, 3) lies over t = 9 - 8 = {pi(2, 3)}")
pull = add(mul(phi_t, phi_t), {(0, 0): 4}, -1)            # phi*(t^2 - 4), expanded
grid = [(x, y) for x in range(-5, 6) for y in range(-5, 6)]
rule = all(ev(pull, x, y) == pi(x, y) ** 2 - 4 for x, y in grid)
print(f"phi*(t^2 - 4) = y^4 - 2x^3y^2 + x^6 - 4: {yn(pull == {(0, 4): 1, (3, 2): -2, (6, 0): 1, (0, 0): -4})}")
print(f"(phi* f)(P) = f(pi(P)) at all {len(grid)} points of the grid -5..5: {yn(rule)}; at (3, 5): {ev(pull, 3, 5)}")
lhs = add(mul({(0, 1): 1, (0, 0): 5}, {(0, 1): 1, (0, 0): -5}),
          mul({(2, 0): 1, (1, 0): 3, (0, 0): 9}, {(1, 0): 1, (0, 0): -3}), -1)
target = {(0, 2): 1, (3, 0): -1, (0, 0): 2}               # y^2 - x^3 + 2, typed in
print(f"(y + 5)(y - 5) - (x^2 + 3x + 9)(x - 3) = y^2 - x^3 + 2: {yn(lhs == target)}")
print(f"so phi*(t + 2) lies in <x - 3, y - 5>, and the point contracts to <t + 2>")
print(f"on the line x = 3, phi*(t + 2) = y^2 - 25, not 0: the line contracts to <0>")
num, den = 1 * 2, 2 * 1                       # (1/2) x 2 as a fraction, then in lowest terms
g = gcd(num, den); num, den = num // g, den // g
print(f"forward along Z -> Q: 2 is in 2Z, (1/2) x 2 = {num} is not: {yn(2 % 2 == 0 and den == 1 and num % 2 != 0)}, no ideal")

p = 7
brute = [sum(1 for x in range(p) for y in range(p) if (y * y - x ** 3 - t) % p == 0) for t in range(p)]
def chi(a):                                   # Euler's criterion: square, non-square, zero
    r = pow(a % p, (p - 1) // 2, p)
    return -1 if r == p - 1 else r
charsum = [sum(1 + chi(x ** 3 + t) for x in range(p)) for t in range(p)]
print(f"fibre sizes over F_{p}, t = 0..{p - 1}, brute force: {brute}")
print(f"the same by the character sum over x: {charsum}; total {sum(brute)} = {p}^2")
proj = [n + 1 for n in brute]
print(f"with the point at infinity: {proj}; Hasse window for t != 0: {p + 1} +- {2 * p ** 0.5:.2f}")
in_window = all((n - p - 1) ** 2 <= 4 * p for n in proj[1:])
print(f"every smooth fibre inside the window: {yn(in_window)}; six different counts: {yn(len(set(proj[1:])) == 6)}")

def singular(q, F, grads, slots):             # points where F and every listed slope vanish
    return sum(1 for pt in slots if F(*pt) % q == 0 and all(g(*pt) % q == 0 for g in grads))
for q in (7, 3, 2):
    sing = [singular(q, lambda x, y, t=t: y * y - x ** 3 - t, [lambda x, y: -3 * x * x, lambda x, y: 2 * y],
                     [(x, y) for x in range(q) for y in range(q)]) for t in range(q)]
    disc = [(-432 * t * t) % q for t in range(q)]
    print(f"over F_{q}: singular points per fibre {sing}; Delta = -432t^2 mod {q}: {disc}")
    assert [s > 0 for s in sing] == [d == 0 for d in disc]  # brute force against Delta
total = singular(7, lambda x, y, t: y * y - x ** 3 - t,
                 [lambda x, y, t: -3 * x * x, lambda x, y, t: 2 * y, lambda x, y, t: -1],
                 [(x, y, t) for x in range(7) for y in range(7) for t in range(7)])
print(f"total space y^2 - x^3 - t over F_7: {total} singular points; fibre over 0: 1")

roots = [sum(1 for u in range(p) if pow(u, 6, p) == t) for t in range(p)]
joined = sum(1 for x in range(p) for y in range(p) for t in range(p) for u in range(p)
             if (y * y - x ** 3 - t) % p == 0 and (t - u ** 6) % p == 0)
by_fibre = sum(brute[t] * roots[t] for t in range(p))
no_t = sum(1 for x in range(p) for y in range(p) for u in range(p) if (y * y - x ** 3 - u ** 6) % p == 0)
print(f"base change t = u^6: solutions u per t {roots}")
print(f"X x_S Y over F_{p}: joined equations {joined}; sum over fibres {by_fibre}; t eliminated {no_t}")
print(f"u != 0 fibres all copy t = 1: 7 + 6 x {brute[1]} = {7 + 6 * brute[1]}")
plain = sum(1 for x in range(p) for y in range(p) for t in range(p) for u in range(p) if (y * y - x ** 3 - t) % p == 0)
print(f"mistake 1, plain product X x Y: {sum(brute)} x {p} = {plain}, not {joined}")
print(f"mistake 2, fibre over 0 without t = 0: {p * p} points of X, not {brute[0]}")
print(f"mistake 3, smoothness of the total space: {total} singular points, fibre over 0 has 1")

print("degeneration over R: t, leftmost real point x = -t^(1/3), Delta = -432t^2")
for k in range(4):
    num, den = -432, 10 ** (2 * k)
    g = gcd(num, den)
    d = f"{num // g}" if den == g else f"{num // g}/{den // g}"
    print(f"  t = {1 if k == 0 else f'1/{10 ** k}'}: x = {-(10.0 ** -k) ** (1 / 3):.4f}, Delta = {d}")
print(f"figure, t=1 from (-1, 0) through (2, 3); t=0 cusp (0, 0) through (1, 1); "
      f"t=-2 from ({2 ** (1 / 3):.4f}, 0) through (3, 5); box x -1.2..3.2, y -5.6..5.6")
assert pull == {(0, 4): 1, (3, 2): -2, (6, 0): 1, (0, 0): -4} and rule  # expansion vs evaluation
assert lhs == target and pi(3, 5) == -2                    # cofactors certify the contraction
assert brute == charsum and sum(brute) == p * p and in_window   # two counts of each fibre
assert joined == by_fibre == no_t == 7 + 6 * brute[1]      # three roads to X x_S Y
assert total == 0 and brute[0] == p                        # smooth total space, cusp fibre
print("ALL CHECKS PASS")
