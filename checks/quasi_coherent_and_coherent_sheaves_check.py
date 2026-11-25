# Quasi-coherent and coherent sheaves -- the check behind the card.  Nothing is
# imported; every number is an exact integer.  Part 1: the module M = Z/6 over
# R = Z, spread over Spec Z as the sheaf M~.  Part 2: O(d) on the projective
# line P^1 over Q, built from the shifted graded module S(d), S = Q[x, y].
# Part 3: the ideal sheaf of the point P = (1 : 2) is O(-1).
# Roads: fractions m/s sorted into classes by brute force, against a count of
# what the denominators kill and the Chinese remainder gluing; d + 1 monomials
# against the rank of the gluing map and a count of glued pairs over F_3; the
# ideal's dimensions against S(-1), and forms vanishing at P counted over F_3.
N, PRIMES = 6, [2, 3, 5, 7, 11, 13]
NAME = lambda c: "0" if c == 1 else f"Z/{c}"   # the stalks here are cyclic

def classes(S):            # road one: sort pairs (m, s) by u (m t - m' s) = 0 in Z/6
    reps = []
    for m in range(N):
        for s in S:
            if not any(any(u * (m * t - m2 * s) % N == 0 for u in S) for m2, t in reps):
                reps.append((m, s))
    return len(reps)

def kept(S):               # road two: M_S = M / (what some s kills); count that kernel
    killed = sum(1 for m in range(N) if any(s * m % N == 0 for s in S))
    return N // killed

def p_part(p):             # road three: p to the number of times p divides N
    n, out = N, 1
    while n % p == 0:
        n, out = n // p, out * p
    return out

away = lambda p: sorted({n % N for n in range(1, N * p + 1) if n % p})   # denominators outside (p), mod 6
powers = lambda f: sorted({f ** k % N for k in range(N)})                # powers of f, mod 6
everything = sorted({n % N for n in range(1, N + 1)})                    # all nonzero n: the generic point
stalk = {p: (classes(away(p)), kept(away(p)), p_part(p)) for p in PRIMES}
gen = (classes(everything), kept(everything))
print(f"R = Z, M = Z/{N}; the stalk of M~ at a prime (p) is M_(p): fractions m/s with p not dividing s")
for p in PRIMES:
    c, k, q = stalk[p]
    print(f"stalk at ({p}): classes {c}, M/kernel {k}, p-part {q}: {NAME(c)}")
print(f"stalk at (0), the generic point: classes {gen[0]}, M/kernel {gen[1]}: 0, since {N} is inverted there")
for label, S in [("D(2)", powers(2)), ("D(3)", powers(3)), ("D(6)", powers(6)), ("(2)", away(2)), ("(3)", away(3)),
                 ("(5)", away(5)), ("(0)", everything)]:
    print(f"{label}: bottoms mod {N} {S}, killed {[m for m in range(N) if any(s * m % N == 0 for s in S)]}")
sec = {f: classes(powers(f)) for f in (1, 2, 3, 6)}
print(f"sections over D(2), D(3), D(6), Spec Z: {NAME(sec[2])}, {NAME(sec[3])}, {NAME(sec[6])}, {NAME(sec[1])}")
a, b = next((a, b) for a in range(-3, 4) for b in range(-3, 4) if 2 * a + 3 * b == 1)
glue = {(m % 3, m % 2) for m in range(N)}
print(f"D(2) and D(3) cover Spec Z, since 1 = {a}*2 + ({b})*3; Z/6 -> Z/3 x Z/2 hits {len(glue)} of 6 pairs")
m5 = (2 * (a * 2) + 1 * (b * 3)) % N
print(f"glue 2 in Z/3 with 1 in Z/2: m = 2*({a * 2}) + 1*{b * 3} = {m5} mod 6; {m5} mod 3 = {m5 % 3}, {m5} mod 2 = {m5 % 2}")

def laurent(f, g, d):      # f(t) - t^d g(1/t), as a map from powers to coefficients
    out = {}
    for i, c in enumerate(f):
        out[i] = out.get(i, 0) + c
    for j, c in enumerate(g):
        out[d - j] = out.get(d - j, 0) - c
    return {k: v for k, v in out.items() if v}

def rank(rows):            # exact elimination over Q, kept in whole numbers
    rows, r = [row[:] for row in rows], 0
    for col in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if rows[i][col]), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(len(rows)):
            if i != r and rows[i][col]:
                rows[i] = [rows[r][col] * x - rows[i][col] * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r

fib = [len({m % N for m in range(N)}) // len({p * m % N for m in range(N)}) for p in PRIMES]
dims = [next(e for e in range(6) if p ** e == s) for p, s in zip(PRIMES, fib)]
gdim = 1 - rank([[N]])     # at (0): M = Z/6 has one generator and one relation, 6; over Q that relation has rank 1
print(f"M/pM has {', '.join(map(str, fib))} elements, so the fibre dimension of M ⊗ k(p) at (2), (3), (5), (7), (11), (13)"
      f" is {', '.join(map(str, dims))}; at (0): {gdim}")

def glued_rank(d, deg=6):  # road two: kernel of (f, g) -> f(t) - t^d g(1/t), degrees at most 6
    powers_seen = range(d - deg, deg + 1)
    cols = [laurent([int(i == k) for i in range(deg + 1)], [], d) for k in range(deg + 1)] + \
           [laurent([], [int(j == k) for j in range(deg + 1)], d) for k in range(deg + 1)]
    return 2 * (deg + 1) - rank([[c.get(e, 0) for c in cols] for e in powers_seen])

def glued_f3(d):           # road three: every pair (f, g) over F_3 of degree at most 2
    vecs = [(i % 3, i // 3 % 3, i // 9) for i in range(27)]
    return sum(1 for f in vecs for g in vecs if all(v % 3 == 0 for v in laurent(f, g, d).values()))

monomials = lambda d: sum(1 for i in range(d + 1) for j in range(d + 1) if i + j == d)
print("P^1 = Proj Q[x, y]; O(d) = S(d)~ with S(d)_n = S_(d+n); charts t = y/x and s = x/y")
counts = {d: (monomials(d), glued_rank(d), glued_f3(d)) for d in range(-2, 3)}
for d, (m, r, c) in counts.items():
    print(f"d = {d}: monomials of degree d {m}, kernel of the gluing map {r}, glued pairs over F_3 (of 729) {c}")
form = [1, 4, 1]                         # x^2 + 4xy + y^2, coefficient of x^(2-i) y^i
f, g = form, form[::-1]
print(f"x^2 + 4xy + y^2 over x^2 is 1 + 4t + t^2, over y^2 is s^2 + 4s + 1; f - t^2 g(1/t) = {laurent(f, g, 2) or 0}")
print(f"wrong shift S(d)_n = S_(n-d): degree-0 part of S(-2) has {monomials(-2)} monomials, not {monomials(2)}")
PT, L = (1, 2), [2, -1]                  # the point P = (1 : 2), and the line 2x - y through it: coefficients of x and y
at_P = lambda c: sum(a * PT[0] ** (len(c) - 1 - i) * PT[1] ** i for i, a in enumerate(c))   # form, x^(n-i) y^i, at P
mult = lambda n: [[sum(L[k] for k in range(2) if i + k == j) for j in range(n + 1)] for i in range(n)]
ideal_dims = [rank(mult(n)) if n else 0 for n in range(6)]
vanish = [n + 1 - rank([[PT[0] ** (n - i) * PT[1] ** i for i in range(n + 1)]]) for n in range(6)]
on_P = all(at_P(row) == 0 for n in range(1, 6) for row in mult(n))     # put P back into every multiple of the line
print(f"2x - y at P: {at_P(L)}; its multiples in degrees 1 to 5 vanish at P: {'yes' if on_P else 'no'}")
print(f"dimension of (2x - y) in degrees 0 to 5: {ideal_dims}; of S(-1): {[monomials(n - 1) for n in range(6)]}")
print(f"degree-n forms vanishing at P, n = 0 to 5: {vanish}")
f3 = [sum(1 for i in range(3 ** (n + 1)) if at_P([i // 3 ** k % 3 for k in range(n + 1)]) % 3 == 0) for n in range(4)]
print(f"over F_3, forms of degree 0 to 3 vanishing at (1 : 2): {f3}")
local = laurent(L, L[::-1], 1) == {}     # the line over x is 2 - t, over y is 2s - 1; they differ by the factor t
print(f"local generators: 2 - t on t-chart, 2s - 1 on s-chart; 2 - t = t * (2/t - 1): "
      f"{'yes' if local else 'no'}, so a(t) = t^-1 b(1/t), the rule for d = -1")
print(f"global sections: ideal sheaf {vanish[0]}, O(-1) {counts[-1][0]}, O(1) {counts[1][0]}")
print(f"mistake, generic stalk read as M: {N} elements, against {gen[0]}")
print(f"figure, schematic Spec Z: dots at x = {', '.join(str(70 + 90 * i) for i in range(6))}; "
      f"stalk sizes {', '.join(str(stalk[p][0]) for p in PRIMES)}; generic {gen[0]}")
assert all(c == k == q for c, k, q in stalk.values()) and gen == (1, 1)   # three roads to every stalk
assert (sec[2], sec[3], sec[6], sec[1]) == (3, 2, 1, 6) and len(glue) == 6 and sec[2] * sec[3] == N and (m5 % 3, m5 % 2) == (2, 1)
assert dims == [1, 1, 0, 0, 0, 0] and gdim == 0                           # fibre dimension jumps
assert all(m == r and c == 3 ** r for m, r, c in counts.values())          # monomials = rank = F_3 count
assert [m for m, _, _ in counts.values()] == [0, 0, 1, 2, 3] and laurent(f, g, 2) == {}
assert at_P(L) == 0 and on_P and local                                    # P lies on the line; its local generators glue
assert ideal_dims == vanish == [monomials(n - 1) for n in range(6)] and f3 == [3 ** n for n in range(4)]
print("ALL CHECKS PASS")
