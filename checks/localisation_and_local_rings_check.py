# Localisation and local rings -- the check behind the card.  Nothing is
# imported; every number is an exact integer.  The field is Q, the rational
# numbers.  R = Q[x], f = x^3 - x^2, and we invert every g with g(0) != 0.
# Roads: orders of vanishing by a binomial shift and by synthetic division;
# their sum against the degree; and finite copies over F_3 and in Z/12, where
# every fraction a/s is sorted into classes by brute force.
F = [0, 0, -1, 1]                        # x^3 - x^2, constant term first

def show(p):                             # leading term first, as on the card
    out = ""
    for k in range(len(p) - 1, -1, -1):
        c = p[k]
        if c == 0:
            continue
        sign = " - " if c < 0 else " + "
        body = ("" if abs(c) == 1 and k > 0 else str(abs(c))) + ("x" if k > 0 else "") + (f"^{k}" if k > 1 else "")
        out += (("-" if c < 0 else "") if out == "" else sign) + body
    return out or "0"

def mul(p, q):
    out = [0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            out[i + j] += a * b
    return out

def value(p, a):
    return sum(c * a ** k for k, c in enumerate(p))

def choose(n, k):
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def order_by_shift(p, a):                # road one: expand f(x + a), count the zero coefficients at the bottom
    shifted = [sum(p[j] * choose(j, k) * a ** (j - k) for j in range(k, len(p))) for k in range(len(p))]
    n = 0
    while shifted[n] == 0:
        n += 1
    return n

def order_by_division(p, a):             # road two: divide by (x - a) while the remainder is 0
    n, p = 0, p[:]
    while len(p) > 1:
        q, carry = [0] * (len(p) - 1), 0
        for k in range(len(p) - 1, 0, -1):
            carry = p[k] + a * carry
            q[k - 1] = carry
        if p[0] + a * carry != 0:
            break
        n, p = n + 1, q
    return n

def ring_classes(n, add, mul_t, neg, S):  # road three: sort every pair (a, s) by u(a t - b s) = 0
    def same(a, s, b, t):
        d = add[mul_t[a][t]][neg[mul_t[b][s]]]
        return any(mul_t[u][d] == 0 for u in S)
    reps = []
    for a in range(n):
        for s in S:
            if not any(same(a, s, b, t) for b, t in reps):
                reps.append((a, s))
    units = [a for a in range(n) if any(same(mul_t[a][b], 1, 1, 1) for b in range(n))]
    non = [a for a in range(n) if a not in units]
    unit_classes = sum(1 for b, t in reps if b in units)
    local = all(add[a][b] in non for a in non for b in non)
    return reps, unit_classes, local, same

def tables_z(m):
    return ([[(a + b) % m for b in range(m)] for a in range(m)],
            [[a * b % m for b in range(m)] for a in range(m)], [(-a) % m for a in range(m)])

def tables_f3():                         # F_3[x] / <x^3 - x^2>: index c0 + 3 c1 + 9 c2; x^3 = x^2 there
    co = [(i % 3, i // 3 % 3, i // 9) for i in range(27)]
    ix = lambda c: c[0] % 3 + 3 * (c[1] % 3) + 9 * (c[2] % 3)
    add = [[ix([co[a][k] + co[b][k] for k in range(3)]) for b in range(27)] for a in range(27)]
    def m(a, b):
        d = mul(list(co[a]), list(co[b]))
        return ix([d[0], d[1], d[2] + d[3] + d[4]])
    return co, add, [[m(a, b) for b in range(27)] for a in range(27)], [ix([-c for c in co[a]]) for a in range(27)]

ok = lambda claim: "yes" if claim else "no"
o0 = (order_by_shift(F, 0), order_by_division(F, 0))
o1 = (order_by_shift(F, 1), order_by_division(F, 1))
others = [order_by_division(F, a) for a in (-1, 2)]
print(f"field Q; R = Q[x]; f = {show(F)}; S = all g with g(0) != 0")
print(f"f = x^2 * ({show([-1, 1])}); the factor {show([-1, 1])} has value {value([-1, 1], 0)} at 0, so it is a unit")
print(f"order of f at 0: by shifting {o0[0]}, by dividing {o0[1]}")
print(f"order of f at 1: by shifting {o1[0]}, by dividing {o1[1]}")
print(f"order of f at -1 and at 2: {others[0]} and {others[1]}")
print(f"local orders {o0[0]} + {o1[0]} = {o0[0] + o1[0]}; degree of f = {len(F) - 1}")
print(f"f(x + 1) = {show([sum(F[j] * choose(j, k) for j in range(k, 4)) for k in range(4)])}; values at 0 of "
      f"x - 1, x^2 - 2, x^2 + 1: {value([-1, 1], 0)}, {value([-2, 0, 1], 0)}, {value([1, 0, 1], 0)}, so those points leave")
print(f"in Z_(2), 1/3 reads {[b for b in range(2) if 3 * b % 2 == 1][0]} mod 2; in Z[1/10], 4.95 = {495}/{10 ** 2}")
lhs, rhs = mul([0, -1, 1], [1, 1]), mul([0, 1], [-1, 0, 1])
print(f"(x^2 - x)/(x^2 - 1) against x/(x + 1): cross products {show(lhs)} and {show(rhs)}")
print(f"(x + 2)/(x - 1) has value {value([2, 1], 0) // value([-1, 1], 0)} at 0: a unit; times (x - 1)/(x + 2) gives "
      f"{show(mul([2, 1], [-1, 1]))} over {show(mul([-1, 1], [2, 1]))}")
print(f"x/(x + 1) has value {value([0, 1], 0)} at 0: in the maximal ideal, no inverse")
print(f"x^2 = f/(x - 1) in R_m, since x^2 * (x - 1) = {show(mul([0, 0, 1], [-1, 1]))}; x has order {order_by_division([0, 1], 0)} < 2, so x is not a multiple of f there")
co, add, mt, neg = tables_f3()
S0 = [a for a in range(27) if co[a][0] != 0]
S1 = [a for a in range(27) if sum(co[a]) % 3 != 0]
reps0, u0, loc0, _ = ring_classes(27, add, mt, neg, S0)
reps1, u1, loc1, _ = ring_classes(27, add, mt, neg, S1)
_, uR, locR, _ = ring_classes(27, add, mt, neg, [1])
print(f"finite copy F_3[x]/<f>: 27 elements; at 0: {len(S0)} denominators, {27 * len(S0)} pairs, {len(reps0)} classes")
print(f"at 1: {len(S1)} denominators, {len(reps1)} classes; {len(reps0)} x {len(reps1)} = {len(reps0) * len(reps1)}")
print(f"units: R {uR} of 27, at 0 {u0} of {len(reps0)}, at 1 {u1} of {len(reps1)}")
print(f"non-units closed under addition (local): R {ok(locR)}, at 0 {ok(loc0)}, at 1 {ok(loc1)}")
zadd, zmul, zneg = tables_z(12)
odd = [1, 3, 5, 7, 9, 11]
repz, uz, locz, samez = ring_classes(12, zadd, zmul, zneg, odd)
print(f"Z/12 with the odd numbers inverted: {len(repz)} classes, {uz} unit classes, local {ok(locz)}")
cross = lambda a, s, b, t: (a * t - b * s) % 12 == 0
bad = [(a, s, b, t) for a in range(12) for s in odd for b in range(12) for t in odd
       if cross(a, s, b, t) and cross(b, t, 0, 1) and not cross(a, s, 0, 1)]
print(f"mistake 1, cross-multiplying only: ({bad[0][0]}, {bad[0][1]}) ~ ({bad[0][2]}, {bad[0][3]}) ~ (0, 1) "
      f"but ({bad[0][0]}, {bad[0][1]}) is not ~ (0, 1); the u-test: {ok(samez(bad[0][0], bad[0][1], 0, 1))}")
print(f"mistake 2, inverting a set that holds 0: {len(ring_classes(12, zadd, zmul, zneg, [0, 1])[0])} class")
print(f"mistake 3, counting the whole ring: 27 elements = 3^3, against {len(reps0)} = 3^2 at the origin")
in_s = lambda p: value(p, 0) != 0 or value(p, 1) != 0   # outside <x(x - 1)>
print(f"mistake 4, complement of <x(x - 1)>: x in it {ok(in_s([0, 1]))}, x - 1 in it {ok(in_s([-1, 1]))}, "
      f"x(x - 1) in it {ok(in_s(mul([0, 1], [-1, 1])))}")
def at(p, q):                             # f(p/q) = (p^3 - p^2 q)/q^3, in lowest terms
    a, b = p ** 3 - p * p * q, q ** 3
    g, h = abs(a), b
    while h:
        g, h = h, g % h
    return f"({p}/{q}, {a // g}/{b // g})" if q > 1 else f"({p}, {a // g})"
print(f"figure, y = x^3 - x^2 from {at(-3, 4)} to {at(3, 2)}; touches {at(0, 1)}; crosses {at(1, 1)}; dips to {at(2, 3)}")
assert o0 == (2, 2) and o1 == (1, 1) and others == [0, 0]          # two roads to each order
assert o0[0] + o1[0] == len(F) - 1                                  # local orders add up to the degree
assert lhs == rhs and mul([0, 0, 1], [-1, 1]) == F
assert len(reps0) == 9 and len(reps1) == 3 and len(reps0) * len(reps1) == 27   # brute force against x^2 and x - 1
assert (uR, u0, u1, locR, loc0, loc1) == (12, 6, 2, False, True, True)
assert (len(repz), uz, locz) == (4, 2, True) and samez(4, 1, 0, 1) and bad[0] == (4, 1, 0, 3)
print("ALL CHECKS PASS")
