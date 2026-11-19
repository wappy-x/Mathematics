# Cyclotomic fields -- the check behind the card.  Standard library only.
# The twelfth roots of unity.  Polynomials are integer lists, lowest power
# first.  Phi_12 is built two ways (exact division, and a product over the
# primitive roots in floating point); the symmetries are found two ways (which
# substitutions x -> x^k keep Phi_12 at zero, and which k share no factor with 12).
import cmath
import math

def trim(p):
    while len(p) > 1 and p[-1] == 0:
        p = p[:-1]
    return p

def mul(p, q, m=0):
    out = [0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            out[i + j] += a * b
    return trim([c % m for c in out] if m else out)

def divmod_monic(p, d, m=0):                   # long division by a monic d
    p, q = p[:], [0] * max(1, len(p) - len(d) + 1)
    for s in range(len(p) - len(d), -1, -1):
        c = p[s + len(d) - 1]
        q[s] = c
        for j, b in enumerate(d):
            p[s + j] -= c * b
    p = [c % m for c in p] if m else p
    return trim(q), trim(p[:len(d) - 1] or [0])

def cyclo(n):                                  # road one: x^n - 1 over Phi_d, d | n, d < n
    p = [-1] + [0] * (n - 1) + [1]
    for d in range(1, n):
        if n % d == 0:
            p, r = divmod_monic(p, cyclo(d))
            assert r == [0]
    return p

def by_roots(n):                               # road two: product of (x - zeta^k), k coprime to n
    p = [1 + 0j]
    for k in [k for k in range(1, n + 1) if math.gcd(k, n) == 1]:
        z = cmath.exp(2j * math.pi * k / n)
        p = [(p[i - 1] if i else 0) - z * (p[i] if i < len(p) else 0) for i in range(len(p) + 1)]
    return [round(c.real) for c in p]

def units(n): return [k for k in range(1, n) if math.gcd(k, n) == 1]
def order(a, n): return next(e for e in range(1, n + 1) if pow(a, e, n) == 1)
def show(p):
    terms = [(c, ("" if abs(c) == 1 and i else str(abs(c))) + ("x" if i else "") + (f"^{i}" if i > 1 else ""))
             for i, c in reversed(list(enumerate(p))) if c]
    return " ".join((("- " if c < 0 else "+ ") if j else "-" if c < 0 else "") + t for j, (c, t) in enumerate(terms))
def num(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

N, PHI = 12, cyclo(12)
red = lambda p: divmod_monic(p, PHI)[1]                  # reduce modulo Phi_12: work in Q(zeta)
xp = lambda k: red([0] * k + [1])                        # zeta^k, as a polynomial of degree < 4
def sub(p, k):                                 # apply the substitution x -> x^k, then reduce
    out = [0]
    for i, c in enumerate(p):
        t = mul([c], xp(k * i))
        out = [a + b for a, b in zip(out + [0] * len(t), t + [0] * len(out))]
    return red(trim(out))
zeta = cmath.exp(2j * math.pi / N)
val = lambda p: sum(c * zeta ** i for i, c in enumerate(p))

print(f"zeta = e^(2 pi i/12) = {num(zeta)}; exponents sharing no factor with 12: {units(N)}; phi(12) = {len(units(N))}")
for d in (1, 2, 3, 4, 6, 12):
    print(f"  hours of order {d:>2}: {[k for k in range(N) if N // math.gcd(k, N) == d]}; Phi_{d} = {show(cyclo(d))}")
print(f"Phi_12 by dividing x^12 - 1 by Phi_1 Phi_2 Phi_3 Phi_4 Phi_6: {show(PHI)}")
print(f"Phi_12 by multiplying out (x - zeta^k), k = 1, 5, 7, 11: {show(by_roots(N))}")
print(f"(x^6 + 1) / (x^2 + 1) = {show(divmod_monic([1, 0, 0, 0, 0, 0, 1], [1, 0, 1])[0])}")
print(f"zeta^2 = {num(zeta ** 2)}, zeta^4 = {num(zeta ** 4)}; Phi_12(zeta) = {num(val(PHI))}; Phi_12(1) = {sum(PHI)}, Phi_12(-1) = {sum(c * (-1) ** i for i, c in enumerate(PHI))}")
quads = [(a, b, c, d) for a in range(-5, 6) for c in range(-5, 6) for b in (1, -1) for d in (1, -1)
         if mul([b, a, 1], [d, c, 1]) == PHI]
print(f"factorisations into two integer quadratics (a, c from -5 to 5): {len(quads)}; b = e = 1 or -1 forces a^2 = {' or '.join(str(b + b - PHI[2]) for b in (1, -1))}; so degree [Q(zeta):Q] = {len(PHI) - 1}")
degs = [len(cyclo(n)) - 1 for n in range(1, 13)]
print(f"n = 1..12, degree of Phi_n: {degs}; phi(n): {[len(units(n)) if n > 1 else 1 for n in range(1, 13)]}; phi(17) = {len(units(17))}")
keeps = [k for k in range(N) if sub(PHI, k) == [0]]
print(f"substitutions x -> x^k that keep Phi_12 at zero: k = {keeps}")
print(f"mistake 2, x -> x^2: Phi_12(zeta^2) reduces to {show(sub(PHI, 2))}, value {num(val(sub(PHI, 2)))}")
compose_ok = all(sub(xp(a), b) == xp(a * b % N) for a in keeps for b in keeps)
print(f"applying k = a then k = b equals k = ab mod 12, for all 16 pairs: {'yes' if compose_ok else 'no'}; squares {[a * a for a in keeps]}")
for a in keeps:
    print(f"  {a:>2} x {keeps} mod 12 = {[a * b % N for b in keeps]}; order {order(a, N)}")
alpha = {11: ([0, 1] + [0] * 9 + [1], "zeta + zeta^11"), 5: ([0, 0, 0, 1], "zeta^3"), 7: ([-1, 0, 2], "2 zeta^2 - 1")}
for k, (p, name) in alpha.items():
    p = red(p)
    signs = ["fixed" if sub(p, j) == p else "negated" if sub(p, j) == [-c for c in p] else "moved" for j in keeps]
    print(f"fixed by k = {k:>2}: {name} = {num(val(p))}; square = {show(red(mul(p, p)))}; under k = {keeps}: {', '.join(signs)}")
subgroups = [s for r in range(1, 5) for s in __import__("itertools").combinations(keeps, r)
             if 1 in s and all(a * b % N in s for a in s for b in s)]
print(f"subgroups of (Z mod 12)^x: {[list(s) for s in subgroups]}; count {len(subgroups)}")
for n in (5, 8, 12):
    print(f"n = {n:>2}: Phi_n = {show(cyclo(n))}; largest order {max(order(a, n) for a in units(n))}; "
          f"elements of order 2 (quadratic subfields) {sum(order(a, n) == 2 for a in units(n))}")
P = [p for p in range(5, 101) if all(p % q for q in range(2, p))]
def powmod_x(e, p):                           # x^e modulo (Phi_12, p), by repeated squaring
    out, b = [1], [0, 1]
    while e:
        out, b, e = (divmod_monic(mul(out, b, p), PHI, p)[1] if e & 1 else out), divmod_monic(mul(b, b, p), PHI, p)[1], e >> 1
    return out
roots = {p: sum(sum(c * pow(t, i, p) for i, c in enumerate(PHI)) % p == 0 for t in range(p)) for p in P}
print(f"primes 5 to 100 where Phi_12 has 4 roots mod p: {[p for p in P if roots[p] == 4]}; residues mod 12: {sorted({p % 12 for p in P if roots[p] == 4})}")
print(f"primes with 0 roots: {sum(roots[p] == 0 for p in P)}; other root counts: {sum(roots[p] not in (0, 4) for p in P)}; "
      f"largest order of p mod 12: {max(order(p % 12, 12) for p in P)}")
print(f"x^(p^2) = x modulo (Phi_12, p) for every one of the {len(P)} primes: {'yes' if all(powmod_x(p * p, p) == [0, 1] for p in P) else 'no'}")
f5 = [(a, b) for a in range(5) for b in range(5) if divmod_monic(PHI, [b, a, 1], 5)[1] == [0]]
print(f"mod 5 the monic quadratic factors x^2 + ax + b are (a, b) = {f5}; degree over GF(5) = {order(5, 12)}")
print(f"mistake 1, 12 treated as prime: (x^12 - 1)/(x - 1) has degree {len(divmod_monic([-1] + [0] * 11 + [1], [-1, 1])[0]) - 1}, "
      f"= Phi_2 Phi_3 Phi_4 Phi_6 Phi_12, degrees {[degs[d - 1] for d in (2, 3, 4, 6, 12)]}")
print(f"mistake 3, group taken as cyclic like n = 5: {sum(order(a, 5) == 2 for a in units(5))} quadratic subfield predicted; "
      f"true count {sum(order(a, N) == 2 for a in keeps)}")
assert PHI == by_roots(N) == [1, 0, -1, 0, 1]                    # two roads to Phi_12
assert quads == [] and abs(val(PHI)) < 1e-12                       # zeta is a root; no factorisation
assert keeps == units(N) and compose_ok                            # two roads to the symmetries
assert degs == [1] + [len(units(n)) for n in range(2, 13)]         # degree = phi(n), division vs gcd count
assert all(red(mul(red(p), red(p))) == [s] for (p, _), s in zip(alpha.values(), (3, -1, -3)))
assert [p for p in P if roots[p] == 4] == [p for p in P if p % 12 == 1] and f5 == [(2, 4), (3, 4)]
assert all(powmod_x(p * p, p) == [0, 1] for p in P)                # every factor mod p has degree 1 or 2
print("ALL CHECKS PASS")
