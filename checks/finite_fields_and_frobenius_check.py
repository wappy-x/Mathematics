# Finite fields and Frobenius -- the check behind the card.  Nothing is imported.
# A byte is a polynomial over GF(2): bit i is the coefficient of x^i, so hex 1b is
# x^4 + x^3 + x + 1.  The field is every byte, wrapped by MOD = 11b, the polynomial
# x^8 + x^4 + x^3 + x + 1.  Frobenius squares.  Subfields are found by Frobenius and
# again by spanning each byte's powers; automorphisms are found by root search; and
# a second field, wrapped by OTHER = 11d, is renamed onto the first.
DEG, MOD, OTHER = 8, 0x11B, 0x11D
SIZE = 1 << DEG
DIVS = [d for d in range(1, DEG + 1) if DEG % d == 0]

def mul(u, v, mod=MOD):              # multiply two bytes: shift and XOR, fold at mod
    out = 0
    while v:
        if v & 1:
            out ^= u
        v, u = v >> 1, u << 1
        if u >> DEG & 1:
            u ^= mod
    return out

T = [mul(a, b) for a in range(SIZE) for b in range(SIZE)]   # multiplication table
def m(a, b): return T[a * SIZE + b]
def frob(a, k=1):                     # Frobenius applied k times: square k times
    for _ in range(k):
        a = m(a, a)
    return a
def inv(a):                           # a^(2 + 4 + ... + 128) = a^254, by squarings and products
    out = 1
    for k in range(1, DEG):
        out = m(out, frob(a, k))
    return out
def pmod(a, b):                       # remainder of polynomial a by b, over GF(2)
    while a and a.bit_length() >= b.bit_length():
        a ^= b << (a.bit_length() - b.bit_length())
    return a
def irreducible(f):                   # trial division by every g of degree 1 .. deg f / 2
    return all(pmod(f, g) for g in range(2, 1 << ((f.bit_length() - 1) // 2 + 1)))
def at(f, r, mul_=m):                 # f evaluated at the byte r, by Horner's rule
    out = 0
    for i in range(f.bit_length() - 1, -1, -1):
        out = mul_(out, r) ^ (f >> i & 1)
    return out
def rename(src, r):                   # send x to r: the byte sum of a_i r^i
    pw, out = [1], []
    for _ in range(DEG - 1):
        pw.append(m(pw[-1], r))
    for a in range(SIZE):
        s = 0
        for i in range(DEG):
            if a >> i & 1:
                s ^= pw[i]
        out.append(s)
    ok = len(set(out)) == SIZE and all(out[mul(a, b, src)] == m(out[a], out[b])
                                       for a in range(SIZE) for b in range(SIZE))
    return out, ok
def span(a):                          # GF(2)-span of the powers of a: closed under + and x
    s, p = {0}, 1
    for _ in range(SIZE):
        if p not in s:
            s |= {x ^ p for x in s}
        p = m(p, a)
        if p == 1:
            break
    return frozenset(s)
def hx(xs): return " ".join(f"{x:02x}" for x in xs)
def yn(c): return "yes" if c else "no"
def poly(v): return " + ".join("1" if i == 0 else "x" if i == 1 else f"x^{i}" for i in range(v.bit_length() - 1, -1, -1) if v >> i & 1)

recip = all(any(m(a, b) == 1 for b in range(SIZE)) for a in range(1, SIZE))
recip254 = all(m(inv(a), a) == 1 for a in range(1, SIZE))
additive = all(frob(a ^ b) == frob(a) ^ frob(b) for a in range(SIZE) for b in range(SIZE))
order = next((k for k in range(1, SIZE) if all(frob(a, k) == a for a in range(SIZE))), 0)
orb = [2]
while frob(orb[-1]) != 2 and len(orb) < SIZE:
    orb.append(frob(orb[-1]))
roots = [r for r in range(SIZE) if at(MOD, r) == 0]
autos = [rename(MOD, r) for r in roots]
as_frob = sorted(next((k for k in range(DEG) if all(t[a] == frob(a, k) for a in range(SIZE))), -1)
                 for t, ok in autos if ok)
fixed = {d: frozenset(a for a in range(SIZE) if frob(a, d) == a) for d in range(1, DEG + 1)}
by_span = sorted({span(a) for a in range(1, SIZE)}, key=len)
def powers(a):                        # 1, a, a^2, ... until the return to 1
    out = [1]
    while m(out[-1], a) != 1 and len(out) < SIZE:
        out.append(m(out[-1], a))
    return out
g = next((a for a in range(2, SIZE) if len(powers(a)) == SIZE - 1), 1)
gpow = powers(g)
gf4 = sorted({0} | {gpow[k] for k in range(0, SIZE - 1, (SIZE - 1) // 3)})
orbits = {frozenset(frob(a, k) for k in range(DEG)) for a in range(SIZE)}
n_orb = [sum(len(o) == d for o in orbits) for d in DIVS]
n_irr = [sum(irreducible(f) for f in range(1 << d, 2 << d)) for d in DIVS]
oroots = [r for r in range(SIZE) if at(OTHER, r) == 0]
renamings = [rename(OTHER, r)[1] for r in oroots]
bad = (1 << DEG) | 1                  # x^8 + 1 = (x + 1)^8: reducible
no_recip = sum(not any(mul(a, b, bad) == 1 for b in range(SIZE)) for a in range(1, SIZE))
even = sum(bin(a).count("1") % 2 == 0 for a in range(1, SIZE))
clock = sum(not any(a * b % SIZE == 1 for b in range(SIZE)) for a in range(SIZE))
cube = lambda a: m(m(a, a), a)
quart = [(b, c, d, e) for b in range(5) for c in range(5) for d in range(5) for e in range(5)
         if ((b + d) % 5, (c + e + b * d) % 5, (b * e + c * d) % 5, c * e % 5) == (0, 0, 0, 3)]
lin = [a for a in range(5) if (a ** 4 - 2) % 5 == 0]

print(f"field: bytes wrapped by {MOD:x}; irreducible by trial division: {yn(irreducible(MOD))}; {SIZE} elements")
print(f"every nonzero byte has a reciprocal: {yn(recip)}; a^{SIZE - 2} = a^2 a^4 ... a^{SIZE // 2} is it, for all {SIZE - 1}: {yn(recip254)}")
print(f"Frob(02) = {frob(2):02x}, Frob(03) = {frob(3):02x}, 02^8 = {frob(2, 3):02x}; Frob({frob(2, 3):02x}) = {poly(mul(frob(2, 3), frob(2, 3), 0))} before the wrap, {frob(2, 4):02x} after")
print(f"Frob(a + b) = Frob(a) + Frob(b) for all {SIZE * SIZE:,} pairs: {yn(additive)}")
print(f"smallest k with Frob^k = identity: {order}; so a^{SIZE} = a for every byte")
print(f"orbit of 02 under Frob: {hx(orb)}")
print(f"roots of {MOD:x} found by trying all {SIZE} bytes: {hx(roots)}")
print(f"symmetries made by sending 02 to a root: {sum(ok for _, ok in autos)} of {len(roots)}; "
      f"each is Frob^k for k = {as_frob}")
print(f"bytes fixed by Frob^d, d = 1..{DEG}: {[len(fixed[d]) for d in range(1, DEG + 1)]}")
print(f"subfields found by spanning powers: sizes {[len(s) for s in by_span]}")
print(f"the same sets Frob^d fixes for d = {DIVS}: {yn(by_span == [fixed[d] for d in DIVS])}")
print(f"generator g = {g:02x}, of order {SIZE - 1}")
print(f"GF(4) inside: {hx(sorted(fixed[2]))}; as 0, 1, g^85, g^170: {hx(gf4)}; its two new bytes add to {gf4[2] ^ gf4[3]:02x}")
print(f"GF(16) inside: {hx(sorted(fixed[4]))}")
print(f"Frobenius orbits of size {DIVS}: {n_orb}; {len(orbits)} orbits in all")
print(f"irreducible polynomials of degree {DIVS}, by trial division: {n_irr}")
print(f"sum of degree x count: {' + '.join(f'{d}*{n}' for d, n in zip(DIVS, n_irr))} = "
      f"{sum(d * n for d, n in zip(DIVS, n_irr))}")
print(f"second field {OTHER:x} irreducible: {yn(irreducible(OTHER))}; its roots in the first: {hx(oroots)}")
print(f"renamings x -> root that respect + and x on all pairs: {sum(renamings)} of {len(oroots)}")
print(f"mistake 1, wrap by {bad:x} = (x + 1)^8: {no_recip} nonzero bytes have no reciprocal "
      f"(nonzero bytes with an even count of 1 bits: {even})")
print(f"mistake 2, the clock mod {SIZE}: {clock} numbers have no reciprocal; "
      f"(1 + 1)^2 = {(1 + 1) ** 2 % SIZE}, 1^2 + 1^2 = {2 % SIZE}")
print(f"mistake 3, an 8-element subfield: a^8 = a holds for {len(fixed[3])} bytes: {hx(sorted(fixed[3]))}")
print(f"mistake 4, cubing for squaring: (02 + 01)^3 = {cube(3):02x}, 02^3 + 01^3 = {cube(2) ^ cube(1):02x}")
print(f"house: x^4 - 2 over GF(5): {len(lin)} roots, {len(quart)} splittings into two quadratics: irreducible")
assert irreducible(MOD) and recip and recip254 and additive and order == DEG
assert sorted(orb) == roots and len(roots) == DEG and as_frob == list(range(DEG))
assert by_span == [fixed[d] for d in DIVS] and [len(s) for s in by_span] == [2 ** d for d in DIVS]
assert gf4 == sorted(fixed[2]) and gf4[2] ^ gf4[3] == 1 and n_orb == n_irr and sum(d * n for d, n in zip(DIVS, n_irr)) == SIZE
assert irreducible(OTHER) and all(renamings) and len(oroots) == DEG
assert no_recip == even and clock == SIZE // 2 and len(fixed[3]) == 2 ** (3 if DEG % 3 == 0 else 1)
assert cube(3) != cube(2) ^ cube(1) and not lin and not quart
print("ALL CHECKS PASS")
