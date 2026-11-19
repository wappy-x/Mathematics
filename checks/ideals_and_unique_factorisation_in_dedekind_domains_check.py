# Ideals factor uniquely even where numbers do not -- the check behind the card.
# Nothing is imported.  A number x + y*sqrt(d) is the pair (x, y).  An ideal is
# stored by its lattice basis (a, 0), (b, c), with 0 <= b < a, so equal ideals
# have equal triples (a, b, c), and its norm (the count of classes) is a * c.
D, B = -5, 100                             # the ring Z[sqrt(-5)]; ideals up to norm 100

def mul(u, v, d=D):
    return (u[0] * v[0] + d * u[1] * v[1], u[0] * v[1] + u[1] * v[0])

def egcd(p, q):                            # Euclid, extended: p*s + q*t = g
    if q == 0:
        return (p, 1, 0)
    g, s, t = egcd(q, p % q)
    return (g, t, s - (p // q) * t)

def lattice(vecs):                         # road 1: reduce generators to (a, b, c)
    w = (0, 0)
    for v in vecs:
        g, s, t = egcd(w[1], v[1])
        w = (s * w[0] + t * v[0], g)
    if w[1] < 0:
        w = (-w[0], -w[1])
    a = 0
    for v in vecs:
        x = v[0] - (v[1] // w[1]) * w[0]
        a = egcd(a, x)[0]
    a = abs(a)
    return (a, w[0] % a, w[1])

def ideal(gens, d=D):                      # the multiples of the generators
    return lattice(list(gens) + [mul(g, (0, 1), d) for g in gens])

def basis(I):
    return [(I[0], 0), (I[1], I[2])]

def times(I, J, d=D):                      # every product of a member of I and of J
    return ideal([mul(u, v, d) for u in basis(I) for v in basis(J)], d)

def inside(I, v):
    return v[1] % I[2] == 0 and (v[0] - (v[1] // I[2]) * I[1]) % I[0] == 0

def norm(I):
    return I[0] * I[2]

def is_prime(I):                           # no two nonzero classes multiply to 0
    reps = [(x, y) for x in range(I[0]) for y in range(I[2])][1:]
    return norm(I) > 1 and all(not inside(I, mul(r, s)) for r in reps for s in reps)

def divides(d_, g):                        # road 2: is g a multiple of d_ in the ring?
    n = d_[0] ** 2 - D * d_[1] ** 2
    x, y = mul(g, (d_[0], -d_[1]))
    return x % n == 0 and y % n == 0

def witness(gens, target):                 # road 2: target as a small sum of generators
    k = len(gens)
    for code in range(3 ** k):
        cs = [(code // 3 ** i) % 3 - 1 for i in range(k)]
        if (sum(c * g[0] for c, g in zip(cs, gens)), sum(c * g[1] for c, g in zip(cs, gens))) == target:
            return cs
    return None

def factor_count(I, primes, start=0):      # lists of prime ideals multiplying to I
    if norm(I) == 1:
        return 1
    total = 0
    for i in range(start, len(primes)):
        P = primes[i]
        if norm(I) % norm(P) == 0 and inside(P, basis(I)[0]) and inside(P, basis(I)[1]):
            rest = [J for J in ideals if norm(J) == norm(I) // norm(P) and times(P, J) == I]
            total += sum(factor_count(J, primes, i) for J in rest)
    return total

def yn(claim):
    return "yes" if claim else "no"

def show(I):
    return f"(a, b, c) = {I}, norm {norm(I)}"

def fmt(v):                                # (4, -1) prints as 4 - r
    y = "" if v[1] == 0 else ("+ " if v[1] > 0 else "- ") + ("" if abs(v[1]) == 1 else str(abs(v[1]))) + "r"
    return f"{v[0]} {y}".strip()

p2, p3, q3 = ideal([(2, 0), (1, 1)]), ideal([(3, 0), (1, 1)]), ideal([(3, 0), (1, -1)])
six = ideal([(6, 0)])
print(f"6 = 2 x 3 = (1 + r)(1 - r), r = sqrt(-5): {fmt(mul((1, 1), (1, -1)))}; norms 4, 9, 6, 6")
print(f"numbers of norm 2 or 3: {[(x, y) for x in range(-2, 3) for y in range(-1, 2) if x * x + 5 * y * y in (2, 3)]}")
print(f"P2 = (2, 1 + r):  {show(p2)}; prime: {yn(is_prime(p2))}")
print(f"P3 = (3, 1 + r):  {show(p3)}; prime: {yn(is_prime(p3))}")
print(f"Q3 = (3, 1 - r):  {show(q3)}; prime: {yn(is_prime(q3))}")
pairs = [("P2 x P2", times(p2, p2), (2, 0)), ("P3 x Q3", times(p3, q3), (3, 0)),
         ("P2 x P3", times(p2, p3), (1, 1)), ("P2 x Q3", times(p2, q3), (1, -1))]
for name, I, num in pairs:
    print(f"road 1: {name} = {show(I)} = ({fmt(num)}): {yn(I == ideal([num]))}")
road2 = []
for name, gens, num in [("P2 x P2", [(4, 0), (2, 2), (-4, 2)], (2, 0)),
                        ("P3 x Q3", [(9, 0), (3, -3), (3, 3), (6, 0)], (3, 0)),
                        ("P2 x P3", [(6, 0), (2, 2), (3, 3), (-4, 2)], (1, 1))]:
    cs, ok = witness(gens, num), all(divides(num, g) for g in gens)
    road2.append(ok and cs is not None)
    print(f"road 2: {name}: generators {gens}, all multiples of {fmt(num)}: {yn(ok)}; {fmt(num)} = {cs} . generators")
whole = times(times(p2, p2), times(p3, q3))
other = times(times(p2, p3), times(p2, q3))
print(f"(6) = {show(six)}; (2)(3) grouping {yn(whole == six)}; (1 + r)(1 - r) grouping {yn(other == six)}")
print(f"norm check: N(6) = 6 x 6 = 36, ideal norms 2 x 2 x 3 x 3 = {norm(p2) ** 2 * norm(p3) * norm(q3)}")
ideals = [(a, b, c) for c in range(1, B + 1) for a in range(c, B // c + 1, c) for b in range(0, a, c)
          if inside((a, b, c), mul((a, 0), (0, 1))) and inside((a, b, c), mul((b, c), (0, 1)))]
primes = [I for I in ideals if is_prime(I)]
principal = [I for I in ideals if any(x * x - D * y * y == norm(I) and inside(I, (x, y))
                                      for x in range(11) for y in range(-10, 11))]
conj = [I for I in ideals if times(I, ideal([(I[1], -I[2])] + [(I[0], 0)])) == ideal([(norm(I), 0)])]
counts = [factor_count(I, primes) for I in ideals if norm(I) > 1]
print(f"ideals of norm 1 to {B}: {len(ideals)}; prime ideals among them: {len(primes)}; "
      f"principal (one number's multiples): {len(principal)}")
print(f"prime ideal norms: {sorted(norm(P) for P in primes)}")
print(f"ideal times its mirror = (its norm), all {len(ideals)} ideals: {yn(len(conj) == len(ideals))}")
print(f"factorisations into prime ideals, ideals of norm 2 to {B}: {len(counts)} ideals, "
      f"each with exactly one: {yn(set(counts) == {1})}")
r7, s7 = ideal([(7, 0), (3, 1)]), ideal([(7, 0), (3, -1)])
named = {"P3": p3, "Q3": q3, "R7": r7, "S7": s7}
split21 = {fmt(v): [m + " x " + n for m in ("P3", "Q3") for n in ("R7", "S7")
                    if times(named[m], named[n]) == ideal([v])] for v in [(1, 2), (1, -2), (4, 1), (4, -1)]}
print(f"21 = 3 x 7 = (1 + 2r)(1 - 2r) = (4 + r)(4 - r); R7 = (7, 3 + r) and S7 = (7, 3 - r) "
      f"prime: {yn(is_prime(r7) and is_prime(s7))}; (7) = R7 x S7: {yn(times(r7, s7) == ideal([(7, 0)]))}")
print("the other four factors: " + "; ".join(f"{k} = {' '.join(v)}" for k, v in split21.items()))
wrong = ideal([(6, 0), mul((1, 1), (1, 1))])
print(f"mistake 1, matching pairs only: P2 x P3 taken as (6, (1 + r)^2) has norm {norm(wrong)}, not {norm(times(p2, p3))}")
print(f"mistake 2, (2) taken as a prime ideal: prime? {yn(is_prime(ideal([(2, 0)])))}; 2 divides (1 + r)(1 - r) = 6, "
      f"divides 1 + r? {yn(divides((2, 0), (1, 1)))}")
p = ideal([(2, 0), (1, 1)], -3)
pp = times(p, p, -3)
print(f"mistake 3, Z[s], s = sqrt(-3): P = (2, 1 + s) norm {norm(p)}; P x P norm {norm(pp)}, not 4; "
      f"P x P = (2) x P: {yn(pp == times(ideal([(2, 0)], -3), p, -3))}; P = (2): {yn(p == ideal([(2, 0)], -3))}")
assert [norm(p2), norm(p3), norm(q3)] == [2, 3, 3] and all(map(is_prime, (p2, p3, q3)))
assert all(I == ideal([num]) for _, I, num in pairs) and all(road2)    # two roads agree
assert whole == six == other and norm(six) == 6 * 6                     # (6), and N(6) = 36
assert set(counts) == {1} and len(conj) == len(ideals)                  # Dedekind, to norm 100
assert len(principal) * 2 == len(ideals) and not is_prime(ideal([(2, 0)]))
assert all(len(v) == 1 for v in split21.values()) and norm(wrong) == 12
assert norm(pp) == 8 and p != ideal([(2, 0)], -3)                       # the failure case
print("ALL CHECKS PASS")
