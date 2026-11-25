# Kloosterman sums: K(1,1;13) = 5.2595 sits under Weil's 2 sqrt 13 = 7.2111 -- the check behind the card.
# Road 1 adds the roots of unity directly.  Road 2 gets the fourth moment by counting solutions of
# x1 + x2 = x3 + x4, 1/x1 + 1/x2 = 1/x3 + 1/x4 by brute force.  Road 3 is the closed form
# 2p^3 - 3p^2 - 3p - 1.  Road 4 rebuilds the sums over GF(p^2) and counts points on the curves
# y^p - y = x + d/x, d = 1, 2, checking K_2 = 2p - K^2 behind Weil's bound, then puts the bound to work.
import math

def isprime(n): return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))
def inv(x, q):                                  # inverse mod q by Euclid's algorithm, or None
    r0, r1, s0, s1 = q, x % q, 0, 1
    while r1: k = r0 // r1; r0, r1, s0, s1 = r1, r0 - k * r1, s1, s0 - k * s1
    return s0 % q if r0 == 1 else None
def ks(a, b, q, imag=False):                    # K(a, b; q) = sum over units x of zeta_q^(a x + b/x)
    t, f = 0.0, math.sin if imag else math.cos
    for x in range(1, q):
        xi = inv(x, q)
        if xi is not None: t += f(2 * math.pi * ((a * x + b * xi) % q) / q)
    return t
def ktab(p):                                    # K(a, 1; p) for a = 0..p-1, from one cosine table
    c, iv = [math.cos(2 * math.pi * t / p) for t in range(p)], [0] + [inv(x, p) for x in range(1, p)]
    return [sum(c[(a * x + iv[x]) % p] for x in range(1, p)) for a in range(p)]
def closed(p): return 2 * p ** 3 - 3 * p ** 2 - 3 * p - 1
def f4(x): return f"{(x if abs(x) > 5e-5 else 0.0):.4f}"
def f6(x): return f"{(x if abs(x) > 5e-7 else 0.0):.6f}"

p = 13
iv = [inv(x, p) for x in range(1, p)]
print("x = 1..12, 1/x mod 13: " + " ".join(map(str, iv)))
t = [(x + iv[x - 1]) % p for x in range(1, p)]
print("t = x + 1/x mod 13:    " + " ".join(map(str, t)))
k = 0.0
for g in ((0,), (1, 12), (2, 11), (4, 9)):
    n = sum(t.count(u) for u in g); c = math.cos(2 * math.pi * g[0] / p); k += n * c
    print(f"  t in {str(list(g)):<8} {n} terms, cos(2 pi t/13) = {f6(c):>9}, adds {f6(n * c):>9}")
K13 = ks(1, 1, p)
print(f"K(1,1;13) grouped = {f6(k)};  direct = {f6(K13)};  imaginary part = {f6(ks(1, 1, p, True))}")
print(f"bounds at 13: Weil 2 sqrt p = {f6(2 * math.sqrt(p))};  Kloosterman 2^(1/4) p^(3/4) = {f6((2 * p ** 3) ** 0.25)};  trivial p - 1 = 12")
K101 = ks(1, 1, 101)
print(f"K(1,1;101) = {f6(K101)};  Weil {f6(2 * math.sqrt(101))};  Kloosterman {f6((2 * 101 ** 3) ** 0.25)};  trivial 100")
assert abs(k - K13) < 1e-12 and abs(ks(1, 1, p, True)) < 1e-12 and abs(K13 - 5.2595) < 1e-4 and abs(K101 - 1.5258) < 1e-4
T = ktab(p)
print("K(a,1;13), a = 1..12: " + " ".join(f4(v) for v in T[1:]))
print(f"K(a,1;13) = K(1,a;13) for every a: {'yes' if all(abs(ks(a, 1, p) - ks(1, a, p)) < 1e-12 for a in range(1, p)) else 'no'};  largest |K(a,1;13)| = {f4(max(abs(v) for v in T[1:]))}")
S4 = sum(v ** 4 for v in T[1:])
print(f"fourth moment p = 13: sum of K(a,1;13)^4 = {f6(S4)};  2p^3 - 3p^2 - 3p - 1 = {closed(13)};  fourth root {f4(S4 ** 0.25)}")
S7 = sum(v ** 4 for v in ktab(7)[1:])
print(f"fourth moment p = 7: {f6(S7)};  closed form {closed(7)};  K(1,1;7) = {f6(ks(1, 1, 7))}")
assert round(S4) == 3847 and abs(S4 - 3847) < 1e-6 and round(S7) == 517 and abs(S7 - 517) < 1e-6

def nsol(p):                                    # brute force: x1 + x2 = x3 + x4 and 1/x1 + 1/x2 = 1/x3 + 1/x4
    iv, n = [0] + [inv(x, p) for x in range(1, p)], [0, 0]
    for x1 in range(1, p):
        for x2 in range(1, p):
            for x3 in range(1, p):
                x4 = (x1 + x2 - x3) % p
                if x4 and (iv[x1] + iv[x2] - iv[x3] - iv[x4]) % p == 0: n[(x1 + x2) % p == 0] += 1
    return n                                    # [solutions with x1 + x2 != 0, solutions with x1 + x2 = 0]
for q in (7, 13):
    n0, n1 = nsol(q); n = n0 + n1; s = (q * q * n - (q - 1) ** 4 - 2 * (q - 1)) // (q - 1)
    print(f"p = {q}: solutions N = {n0} (sum s != 0) + {n1} (s = 0) = {n};  3(p-1)(p-2) = {3 * (q - 1) * (q - 2)}")
    print(f"  p^2 N = {q * q * n};  (p-1)^4 = {(q - 1) ** 4};  2(p-1) = {2 * (q - 1)};  (p^2 N - (p-1)^4 - 2(p-1))/(p-1) = {s}")
    assert n0 == (q - 1) * (2 * q - 5) and n1 == (q - 1) ** 2 and n == 3 * (q - 1) * (q - 2) and s == closed(q)
pr = [q for q in range(3, 60) if isprime(q)]
okn = all(sum(nsol(q)) == 3 * (q - 1) * (q - 2) for q in pr)
pr2 = [q for q in range(3, 200) if isprime(q)]
ok4 = all(abs(sum(v ** 4 for v in ktab(q)[1:]) - closed(q)) < 1e-6 for q in pr2)
print(f"brute-force N = 3(p-1)(p-2) for all {len(pr)} odd primes below 60: {'yes' if okn else 'no'}")
print(f"sum of K^4 = 2p^3 - 3p^2 - 3p - 1 for all {len(pr2)} odd primes below 200: {'yes' if ok4 else 'no'}")
assert okn and ok4

worst, wk, cnt = 0.0, None, 0                    # Weil and Kloosterman bounds on every K(a,1;p)
for q in range(3, 400):
    if isprime(q):
        for a, v in enumerate(ktab(q)[1:], 1):
            cnt += 1; r = abs(v) / (2 * math.sqrt(q))
            if r > worst: worst, wk = r, (a, q, v)
print(f"all {cnt} sums K(a,1;p), odd p below 400: largest |K|/(2 sqrt p) = {f6(worst)}, at a = {wk[0]}, p = {wk[1]}, K = {f6(wk[2])}")
assert worst < 1

def gf2(p):                                     # GF(p^2) = GF(p)[w], w^2 = d, d the least non-square
    d = next(d for d in range(2, p) if pow(d, (p - 1) // 2, p) == p - 1)
    mul = lambda u, v: ((u[0] * v[0] + d * u[1] * v[1]) % p, (u[0] * v[1] + u[1] * v[0]) % p)
    def pw(u, e):
        r = (1, 0)
        while e: r, u, e = (mul(r, u) if e & 1 else r), mul(u, u), e >> 1
        return r
    els = [(u, v) for u in range(p) for v in range(p)]
    return els, mul, pw, d
def k2(p, c):                                   # K_2(c, c) = sum over z in GF(p^2)* of zeta_p^(c Tr(z + 1/z))
    els, mul, pw, d = gf2(p); s = 0.0
    for z in els[1:]:
        zi = pw(z, p * p - 2); s += math.cos(2 * math.pi * c * (2 * (z[0] + zi[0])) / p)
    return s
v2 = k2(13, 1)
print(f"over GF(169): K_2(1,1) = {f6(v2)};  2p - K(1,1;13)^2 = {f6(26 - K13 ** 2)}")
okh = all(abs(k2(q, 1) - (2 * q - ks(1, 1, q) ** 2)) < 1e-9 for q in pr[:10])
print(f"K_2 = 2p - K^2 for all odd primes up to {pr[9]}: {'yes' if okh else 'no'}")
assert abs(v2 - (26 - K13 ** 2)) < 1e-9 and okh

def curve(p, e=1):                              # points (x, y), x != 0, on y^p - y = x + e/x over GF(p^2)
    els, mul, pw, d = gf2(p); m = {}
    for y in els:
        u = pw(y, p); key = ((u[0] - y[0]) % p, (u[1] - y[1]) % p); m[key] = m.get(key, 0) + 1
    tot = 0
    for x in els[1:]:
        xi = pw(x, p * p - 2); tot += m.get(((x[0] + e * xi[0]) % p, (x[1] + e * xi[1]) % p), 0)
    return tot
n1 = p * sum(1 for x in range(1, p) if (x + inv(x, p)) % p == 0)
print(f"curve over GF(13): points with x != 0: {n1};  p - 1 + sum of K(c,c;13) = {f6(p - 1 + sum(ks(c, c, p) for c in range(1, p)))}")
nc = curve(p, 1); r2 = p * p - 1 + sum(k2(p, c) for c in range(1, p)); r3 = p * p - 1 + sum(2 * p - ks(c, c, p) ** 2 for c in range(1, p))
print(f"curve over GF(169): brute count {nc};  p^2 - 1 + sum K_2(c,c) = {f6(r2)};  p^2 - 1 + sum (2p - K(c,c)^2) = {f6(r3)}")
print(f"  gap from p^2 - 1 = {nc - p * p + 1};  Weil allows 2(p-1)p = {2 * (p - 1) * p}")
assert abs(nc - r2) < 1e-6 and abs(nc - r3) < 1e-6 and abs(nc - p * p + 1) <= 2 * (p - 1) * p and abs(n1 - (p - 1 + sum(ks(c, c, p) for c in range(1, p)))) < 1e-9
nd = curve(p, 2); rd = p * p - 1 + sum(2 * p - ks(c, 2 * c, p) ** 2 for c in range(1, p))   # d = 2, a non-square
sq, ns = (sorted({f4(ks(c, e * c, p)) for c in range(1, p)}, key=float) for e in (1, 2))
print(f"K(c,c;13) takes {len(sq)} values: {' '.join(sq)};  K(c,2c;13) takes the other {len(ns)}: {' '.join(ns)}")
print(f"curve y^p - y = x + 2/x over GF(169): brute count {nd};  p^2 - 1 + sum (2p - K(c,2c)^2) = {f6(rd)}")
assert abs(nd - rd) < 1e-6 and set(sq) | set(ns) == {f4(v) for v in T[1:]} and not set(sq) & set(ns)
q = 100003; A = (q - 1) // 2; na = sum(1 for x in range(1, A + 1) if inv(x, q) <= A)   # a count the bound pins down
sa = (sum(abs(math.sin(math.pi * a * A / q) / math.sin(math.pi * a / q)) for a in range(1, q)) / q) ** 2
ew, ek = A * A / q ** 2 + 2 * math.sqrt(q) * sa, A * A / q ** 2 + (2 * q ** 3) ** 0.25 * sa
print(f"mod {q}: x = 1..{A} with 1/x also <= {A}: {na};  expected {A}^2/{q} = {f4(A * A / q)};  error cap from Weil {f4(ew)}, from Kloosterman {f4(ek)}")
assert abs(na - A * A / q) <= ew < A * A / q < A < ek

S2 = sum(v ** 2 for v in T[1:])                 # what breaks
print(f"second moment p = 13: {f6(S2)} = p^2 - p - 1 = {p * p - p - 1};  bound sqrt = {f4(math.sqrt(S2))}, worse than trivial 12")
print(f"p divides a and b: K(0,0;13) = {f4(ks(0, 0, p))};  p divides a only: K(0,1;13) = {f4(ks(0, 1, p))}")
cq = next(q for q in range(2, 400) if abs(ks(1, 1, q)) > 2 * math.sqrt(q))
print(f"smallest modulus with |K(1,1;q)| > 2 sqrt q: q = {cq} = 9 x 13, K = {f4(ks(1, 1, cq))} against {f4(2 * math.sqrt(cq))};  caps multiplied 2 sqrt 9 x 2 sqrt 13 = {f4(4 * math.sqrt(cq))}")
print(f"fourth moment with a = 0 kept: {f6(sum(v ** 4 for v in T))}")
assert abs(S2 - 155) < 1e-9 and cq == 117 and abs(ks(1, 1, cq)) < 4 * math.sqrt(cq) and abs(ks(0, 0, p) - 12) < 1e-12 and abs(sum(v ** 4 for v in T) - 3848) < 1e-6
print(f"try: q = 176: K = {f4(ks(1, 1, 176))} against {f4(2 * math.sqrt(176))};  sixth moment p = 13: {f6(sum(v ** 6 for v in T[1:]))}, (2 sqrt 13)^6 = {64 * 13 ** 3}")
for q in (11, 1009, 10007): print(f"try: K(1,1;{q}) = {f4(ks(1, 1, q))};  2 sqrt p = {f4(2 * math.sqrt(q))}")

cp = [q for q in range(3, 102) if isprime(q)]
print("chart, primes: " + ", ".join(map(str, cp)))
print("chart, K(1,1;p): " + ", ".join(f"{ks(1, 1, q):.2f}" for q in cp))
print("chart, 2 sqrt p: " + ", ".join(f"{2 * math.sqrt(q):.2f}" for q in cp))
print("chart, -2 sqrt p: " + ", ".join(f"{-2 * math.sqrt(q):.2f}" for q in cp))
print("ALL CHECKS PASS")
