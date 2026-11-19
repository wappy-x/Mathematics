# Rings of integers of the quadratic fields Q(sqrt d): the mod-4 rule against two other roads.
# A number (A + B*sqrt(d))/q is stored as three whole numbers (A, B, q) with q > 0.

def integral(d, A, B, q):  # the test: trace 2A/q and norm (A^2 - d B^2)/q^2 both whole
    return (2 * A) % q == 0 and (A * A - d * B * B) % (q * q) == 0

def squarefree(n):
    p = 2
    while p * p <= abs(n):
        if n % (p * p) == 0:
            return False
        p += 1
    return True

def rule(d):  # Road 1, the theorem: the second basis number; the first is always 1
    return (1, 1, 2) if d % 4 == 1 else (0, 1, 1)

def disc(d, e):  # determinant of the trace matrix of the basis 1, e
    A, B, q = e
    top = 2 * 2 * (A * A + d * B * B) - (2 * A) ** 2  # Tr(1)Tr(e^2) - Tr(e)^2, over q^2
    assert top % (q * q) == 0
    return top // (q * q)

def form_disc(d, e):  # N(x + y e) = x^2 + Tr(e) xy + N(e) y^2; discriminant Tr(e)^2 - 4 N(e)
    A, B, q = e
    tr, nq = 2 * A // q, A * A - d * B * B
    assert nq % (q * q) == 0
    return tr * tr - 4 * (nq // (q * q))

def p_test(d, e):  # Road 3: for each prime p with p^2 | disc, try every (c1 + c2 e)/p
    D, (A, B, q), found = disc(d, e), e, []
    for p in range(2, abs(D) + 1):
        if D % (p * p) or any(p % r == 0 for r in range(2, p)):
            continue
        for c1 in range(p):
            for c2 in range(p):
                if (c1, c2) != (0, 0) and integral(d, c1 * q + c2 * A, c2 * B, p * q):
                    found.append((p, c1, c2))
    return found

def in_ring(i, j, den, e):  # is i/den + (j/den) sqrt d equal to x + y e with x, y whole?
    A, B, q = e
    if (j * q) % (den * B):
        return False
    y = j * q // (den * B)
    return (i * q - y * A * den) % (den * q) == 0

def grid(d, e, den):  # Road 2: test every a + b sqrt d, a and b in steps of 1/den from -2 to 2
    hits = clash = 0
    for i in range(-2 * den, 2 * den + 1):
        for j in range(-2 * den, 2 * den + 1):
            t = integral(d, i, j, den)
            hits += t
            clash += t != in_ring(i, j, den, e)
    return hits, clash

print(f"grid: steps of 1/12 from -2 to 2, {(4 * 12 + 1) ** 2} points per field")
print(" d  d mod 4  integral basis      d_K  grid  rule=grid  p-test")
rows = 0
for d in range(-11, 14):
    if d in (0, 1) or not squarefree(d):
        continue
    e, plain, rows = rule(d), (0, 1, 1), rows + 1
    dK, (hits, clash) = disc(d, e), grid(d, e, 12)
    name = "1, (1+sqrt d)/2" if e != plain else "1, sqrt d"
    print(f"{d:>3}  {d % 4:>4}     {name:<16} {dK:>5}  {hits:>4}  {'yes' if clash == 0 else 'no':>9}  {len(p_test(d, e))}")
    assert clash == 0 and p_test(d, e) == [] and form_disc(d, e) == dK
    assert dK == (d if d % 4 == 1 else 4 * d) and hits == (41 if d % 4 == 1 else 25)
    k2, extra = disc(d, plain) // dK, p_test(d, plain)
    assert (k2 == 4) == (d % 4 == 1) == (extra == [(2, 1, 1)]) and k2 in (1, 4)

h = (1 + (-5) * 1 * (-1), 1 * (-1) + 1 * 1, 1)  # (1 + sqrt-5)(1 - sqrt-5)
print(f"fields checked: {rows}")
yn = lambda t: "yes" if t else "no"
print(f"house d=-5: (1+sqrt-5)(1-sqrt-5) = {h[0]}; (1+sqrt-5)/2 has norm {1 + 5}/4, integral {yn(integral(-5, 1, 1, 2))};"
      f" d_K = {disc(-5, rule(-5))}")
assert h[1:] == (0, 1)
PA, PB, Pq = rule(5)
k = next(k for k in range(1, 9) if k * k * disc(5, rule(5)) == disc(5, (0, 1, 1)))
print(f"d=5: disc of 1, sqrt5 = {disc(5, (0, 1, 1))}; disc of 1, phi = {disc(5, rule(5))}; index {k};"
      f" traces of 1, phi, phi^2: 2, {2 * PA // Pq}, {2 * (PA * PA + 5 * PB * PB) // (Pq * Pq)}; of 5: {2 * 5}")
for e, nm in [((1, 0, 2), "1/2"), ((0, 1, 2), "sqrt5/2"), ((1, 1, 2), "(1+sqrt5)/2")]:
    print(f"  candidate {nm}: trace {2 * e[0]}/2, norm {e[0] ** 2 - 5 * e[1] ** 2}/4, integral {yn(integral(5, *e))}")
print(f"  p-test on 1, sqrt5 finds (p, c1, c2): {p_test(5, (0, 1, 1))}; on 1, sqrt12: {p_test(12, (0, 1, 1))}")

def mul(u, v, c):  # (x1 + y1 w)(x2 + y2 w) with w^2 = w + c, c = (d - 1)/4
    return (u[0] * v[0] + c * u[1] * v[1], u[0] * v[1] + v[0] * u[1] + u[1] * v[1])

p10, fib = (1, 0), [0, 1]
for n in range(10):
    p10 = mul(p10, (0, 1), 1)
    fib.append(fib[-1] + fib[-2])
A10, B10 = 2 * p10[0] + p10[1], p10[1]  # x + y phi = (2x + y + y sqrt5)/2
print(f"phi^10 = {p10[0]} + {p10[1]} phi = ({A10} + {B10} sqrt5)/2; Fibonacci F0 to F11 = {fib};"
      f" norm {(A10 * A10 - 5 * B10 * B10) // 4}")
assert p10 == (fib[9], fib[10]) and integral(5, A10, B10, 2) and (A10, B10) == (123, 55)
inv1, inv2 = (-1, 1), (2, -1)
assert mul(inv1, (0, 1), 1) == (1, 0) and mul(mul(inv2, (0, 1), 1), (0, 1), 1) == (1, 0)
print(f"phi^-1 = {inv1[0]} + {inv1[1]} phi, phi^-2 = {inv2[0]} + ({inv2[1]}) phi: pentagram pieces")
print(f"norm form d=5: x^2 + xy - y^2, disc {form_disc(5, rule(5))}; d=-5: x^2 + 5y^2, disc {form_disc(-5, rule(-5))}")
fine = 30
g30 = [grid(d, rule(d), fine) for d in (5, -5)]
print(f"grid in steps of 1/{fine} ({(4 * fine + 1) ** 2} points): d=5 {g30[0][0]}, d=-5 {g30[1][0]}")
assert g30 == [(41, 0), (25, 0)]

roots = lambda f: [x for x in (0, 1) if f(x) % 2 == 0]
z5, half_in = grid(5, (0, 1, 1), 12), grid(-5, (1, 1, 2), 12)
print(f"break: 1, sqrt5 as basis: ring has {z5[0] - z5[1]} grid points, true {z5[0]};"
      f" roots mod 2 of x^2-5: {roots(lambda x: x * x - 5)}, of x^2-x-1: {roots(lambda x: x * x - x - 1)}")
print(f"break: halves let in at d=-5: ring has {half_in[0] + half_in[1]} grid points, true {half_in[0]}")
assert z5 == (41, 16) and half_in == (25, 16)
print(f"break: d=45 not squarefree: rule disc {disc(45, rule(45))}; p-test finds {p_test(45, rule(45))};"
      f" true d_K {disc(5, rule(5))}")
assert p_test(45, rule(45)) == [(3, 1, 1), (3, 2, 2)] and disc(45, rule(45)) == 9 * disc(5, rule(5))
units = lambda nf: sum(nf(x, y) == 1 for x in range(-3, 4) for y in range(-3, 4))
u_omega, u_plain = units(lambda x, y: x * x + x * y + y * y), units(lambda x, y: x * x + 3 * y * y)
print(f"break: d=-3 as 1, sqrt-3: disc {disc(-3, (0, 1, 1))}, units {u_plain};"
      f" true 1, omega: disc {disc(-3, rule(-3))}, units {u_omega}")
assert (u_omega, u_plain) == (6, 2)
print("ALL CHECKS PASS")
