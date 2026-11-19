# Quadratic reciprocity via Gauss sums: is 43 a square mod 97?
P, Q = 97, 43

def odd_primes_below(n):
    s = bytearray([1]) * n
    s[0:2] = b"\x00\x00"
    for i in range(2, int(n ** 0.5) + 1):
        if s[i]:
            s[i * i::i] = bytearray(len(range(i * i, n, i)))
    return [i for i in range(3, n) if s[i]]

def euler(a, p):  # Euler's criterion: a^((p-1)/2) mod p is 1 or p - 1
    r = pow(a % p, (p - 1) // 2, p)
    return 0 if r == 0 else (1 if r == 1 else -1)

def by_squares(a, p):  # list every square mod p
    return 1 if a % p in {x * x % p for x in range(1, p)} else -1

def recip(a, p, log):  # the flip rule, the rule for -1 and the rule for 2
    a %= p
    if a == 1:
        return 1
    if a == p - 1:
        log.append(f"({a}/{p}) = (-1/{p}) = {1 if p % 4 == 1 else -1}")
        return 1 if p % 4 == 1 else -1
    f = next(d for d in range(2, a + 1) if a % d == 0)
    if f < a:
        return recip(f, p, log) * recip(a // f, p, log)
    if a == 2:
        return 1 if p % 8 in (1, 7) else -1
    sign = -1 if a % 4 == 3 and p % 4 == 3 else 1
    log.append(f"({a}/{p}) = {'+' if sign > 0 else '-'}({p}/{a}) = "
               f"{'+' if sign > 0 else '-'}({p % a}/{a})")
    return sign * recip(p, a, log)

def mul(u, v, p, q):  # multiply in (Z mod q)[x] with x^p = 1
    w = [0] * p
    for i, ui in enumerate(u):
        if ui:
            for j, vj in enumerate(v):
                w[(i + j) % p] = (w[(i + j) % p] + ui * vj) % q
    return w

def power(u, k, p, q):
    r, b = [1] + [0] * (p - 1), u
    while k:
        if k & 1:
            r = mul(r, b, p, q)
        b, k = mul(b, b, p, q), k >> 1
    return r

def gauss(p, q):  # g = sum of (a/p) x^a, coefficients mod q
    return [euler(a, p) % q for a in range(p)]

def gauss_sign(p, q):  # g^q = +g or -g in characteristic q
    g, h = gauss(p, q), power(gauss(p, q), q, p, q)
    return 1 if h == g else (-1 if h == [(-c) % q for c in g] else 0)

def show(u, q):
    c = [x if x <= q // 2 else x - q for x in u]
    t = [(f"{v}" if i == 0 else f"{v}x^{i}".replace("1x", "x")) for i, v in enumerate(c) if v]
    return " + ".join(t).replace("+ -", "- ").replace("x^1 ", "x ")

# Road 1: brute force. Road 2: Euler's criterion. Road 3: reciprocity.
wit = [x for x in range(P) if x * x % P == Q]
print(f"square roots of {Q} mod {P}: {wit}")
for w in wit[:1]:
    print(f"check: {w}^2 = {w * w} = {w * w // P} x {P} + {w * w % P}")
print(f"by listing all {P // 2} squares mod {P}: {by_squares(Q, P):+d}")
print(f"Euler: {Q}^{(P - 1) // 2} mod {P} = {pow(Q, (P - 1) // 2, P)}, so {euler(Q, P):+d}")
log = []
r = recip(Q, P, log)
for line in log:
    print("flip:", line)
print(f"reciprocity: ({Q}/{P}) = {r:+d}; rules applied: {len(log)}")
assert r == euler(Q, P) == by_squares(Q, P) and (len(wit) == 2) == (r == 1)
# Road 4: the Gauss sum itself
g3 = power(gauss(3, 10 ** 9), 2, 3, 10 ** 9)
print(f"p = 3: g = x - x^2, g^2 = {show(g3, 10 ** 9)}, which is -3 once 1 + x + x^2 = 0")
g5 = power(gauss(3, 5), 5, 3, 5)
print(f"p = 3, q = 5: g^5 = {show(g5, 5)} = -g; (5/3) = {euler(5, 3):+d}, (-3/5) = {euler(-3, 5):+d}")
assert g5 == [(-c) % 5 for c in gauss(3, 5)] and euler(5, 3) == euler(-3, 5) == -1
for p in (P, Q):
    g2, e = power(gauss(p, 10 ** 9), 2, p, 10 ** 9), euler(-1, p)
    assert g2 == [e * (p - 1) % 10 ** 9] + [-e % 10 ** 9] * (p - 1)
    print(f"p = {p}: g^2 = {e * (p - 1)} on x^0 and {-e} on every other power, "
          f"so g^2 = p* = {e * p}")
for p, q in ((P, Q), (Q, P)):
    s = gauss_sign(p, q)
    print(f"in characteristic {q}, g^{q} = {s:+d} g for p = {p}: ({q}/{p}) = {s:+d}, "
          f"Euler says {euler(q, p):+d}, (p*/q) = {euler(euler(-1, p) * p, q):+d}")
    assert s == euler(q, p) == euler(euler(-1, p) * p, q)
small = odd_primes_below(40)
ok = sum(gauss_sign(p, q) == euler(q, p) == euler(euler(-1, p) * p, q)
         for p in small for q in small if p != q)
print(f"Gauss-sum road against Euler, all ordered pairs of odd primes below 40: "
      f"{ok} of {len(small) * (len(small) - 1)}")
assert ok == len(small) * (len(small) - 1)
pr = odd_primes_below(200)
pairs = [(p, q) for p in pr for q in pr if p < q]
law = sum(euler(p, q) * euler(q, p) == (-1) ** ((p - 1) // 2 * (q - 1) // 2) for p, q in pairs)
neg = sum(euler(p, q) * euler(q, p) == -1 for p, q in pairs)
both3 = sum(p % 4 == 3 and q % 4 == 3 for p, q in pairs)
print(f"pairs of odd primes below 200: {len(pairs)}; law holds for {law}; "
      f"(p/q)(q/p) = -1 for {neg}; both 3 mod 4: {both3}")
assert law == len(pairs) and neg == both3
agree, tests = sum(recip(a, p, []) == euler(a, p) for p in pr for a in range(1, p)), sum(p - 1 for p in pr)
print(f"reciprocity road against Euler, every a from 1 to p - 1, odd primes p below 200: {agree} of {tests}")
assert agree == tests
# The house example: 5 is a square mod p exactly when p ends in 1 or 9
big = [p for p in odd_primes_below(10 ** 6) if p != 5]
sq5 = [p for p in big if euler(5, p) == 1]
end19 = [p for p in big if p % 10 in (1, 9)]
print(f"primes below a million other than 2 and 5: {len(big)}; 5 is a square mod "
      f"{len(sq5)}; end in 1 or 9: {len(end19)}; not a square: {len(big) - len(sq5)}")
assert sq5 == end19
print("bars, square:", len(sq5), "not square:", len(big) - len(sq5))
# What breaks
bad1 = recip(43, 11, [])
print(f"mistake 1, no sign on the flip of (11/43): (43/97) = {bad1:+d}, yet 25^2 mod 97 = {25 * 25 % 97}")
bad2 = -1 * recip(97, 43, [])
print(f"mistake 2, sign from 43 alone on the first flip: (43/97) = {bad2:+d}")
print(f"mistake 3, g^2 = p, not p*, so (q/p) = (p/q) always: (3/7) = {euler(3, 7):+d}, "
      f"(7/3) = {euler(7, 3):+d}; the rule fails for {both3} of {len(pairs)} pairs")
z = power(gauss(P, P), P, P, P)
print(f"mistake 4, q = p = {P}: g^{P} has {sum(1 for c in z if c)} nonzero coefficients, "
      f"so g^{P} = 0 and g cannot be cancelled")
sq15 = sorted({x * x % 15 for x in range(15)})
print(f"mistake 5, 15 is not prime: (2/3)(2/5) = {euler(2, 3) * euler(2, 5):+d}, yet the squares mod 15 are {sq15}")
assert 2 not in sq15 and euler(2, 3) * euler(2, 5) == 1
assert bad1 == bad2 == -1 and euler(3, 7) == -euler(7, 3) and not any(z)
print("ALL CHECKS PASS")
