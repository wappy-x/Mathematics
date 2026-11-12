# Elliptic-curve cryptography -- the check behind the card.  Standard library only.
# The toy curves are INSECURE: sized so every step can be followed and checked.
# The real curve, Curve25519, is run on the test vectors printed in RFC 7748.
from math import isqrt, log2, pi

def inv(x, m):  # reciprocal mod m, by the extended Euclid method
    r0, r1, s0, s1 = x % m, m, 1, 0
    while r1:
        q = r0 // r1
        r0, r1, s0, s1 = r1, r0 - q * r1, s1, s0 - q * s1
    assert r0 == 1
    return s0 % m

def slope(P, Q, p, a):
    if P == Q: return (3 * P[0] * P[0] + a) * inv(2 * P[1], p) % p
    return (Q[1] - P[1]) * inv(Q[0] - P[0], p) % p

def add(P, Q, p, a):  # chord and tangent; None is the zero point O
    if P is None: return Q
    if Q is None: return P
    if P[0] == Q[0] and (P[1] + Q[1]) % p == 0: return None
    m = slope(P, Q, p, a)
    x = (m * m - P[0] - Q[0]) % p
    return (x, (m * (P[0] - x) - P[1]) % p)

def mul(k, P, p, a, trace=None):  # double-and-add, top bit first
    R, ops = (P if k else None), [0, 0]
    for bit in bin(k)[3:]:
        for op in ["double"] + ["add G"] * (bit == "1"):
            Q = R if op == "double" else P
            m = slope(R, Q, p, a) if trace is not None else 0
            R = add(R, Q, p, a); ops[op == "add G"] += 1
            if trace is not None: trace.append((op, m, R))
    return R, ops

def rep(k, P, p, a):  # road two: add P to itself, one step at a time
    R = None
    for _ in range(k): R = add(R, P, p, a)
    return R

# ---- toy curve: y^2 = x^3 + 2x + 2 mod 17, base point G = (5, 1) ----
p, a, b, G = 17, 2, 2, (5, 1)
count = 1 + sum(1 for x in range(p) for y in range(p) if (y*y - x**3 - a*x - b) % p == 0)
n = next(k for k in range(1, 100) if rep(k, G, p, a) is None)
print("toy curve mod 17: points", count, " order of G", n)
assert count == 19 and n == 19

# ---- ECDH on the toy: laptop key 13, bank key 7 ----
dL, dB, tr = 13, 7, []
QL, ops = mul(dL, G, p, a, tr)
for t in tr: print(f"  {t[0]:6s} slope {t[1]:2d} -> {t[2]}")
QB = mul(dB, G, p, a)[0]
SL, SB = mul(dL, QB, p, a)[0], mul(dB, QL, p, a)[0]
print("QL = 13G", QL, " QB = 7G", QB, " doublings, additions", ops)
print("laptop 13*QB", SL, " bank 7*QL", SB, " 91 mod 19 =", 91 % 19)
assert QL == rep(13, G, p, a) and SL == SB == rep(91 % 19, G, p, a)
tries = next(k for k in range(1, n) if rep(k, G, p, a) == QL)
print("exhaustive search: laptop key found on try", tries, "of at most", n - 1)
assert tries == dL

# ---- ECDSA on the toy: signing key dS = 9, nonce k = 10, hash stand-in z = 5 ----
dS, k, z = 9, 10, 5
QS = mul(dS, G, p, a)[0]
def sign(z, k, d): return mul(k, G, p, a)[0][0] % n, inv(k, n) * (z + mul(k, G, p, a)[0][0] * d) % n
def verify(z, r, s):
    w = inv(s, n)
    u1, u2 = z * w % n, r * w % n
    R = add(mul(u1, G, p, a)[0], mul(u2, QS, p, a)[0], p, a)
    return R is not None and R[0] % n == r, u1, u2, R
r, s = sign(z, k, dS)
ok, u1, u2, R = verify(z, r, s)
print("QS = 9G", QS, " kG", mul(k, G, p, a)[0], " r", r, " s", s, " 1/k", inv(k, n))
print("verify: 1/s", inv(s, n), " u1", u1, " u2", u2, " u1 G + u2 QS", R, " valid", ok)
assert ok and R == rep(k, G, p, a) and s * k % n == (z + r * dS) % n
print("same signature, hash stand-in 6 instead of 5: valid", verify(6, r, s)[0])
assert not verify(6, r, s)[0]

# ---- what breaks: one nonce, two messages ----
z2 = 11
r2, s2 = sign(z2, k, dS)
kk = (z - z2) * inv(s - s2, n) % n
dd = (s * kk - z) * inv(r, n) % n
print("nonce reused: s2", s2, " recovered k", kk, " recovered key", dd)
assert (kk, dd) == (k, dS)

# ---- a generic attack on a 32-bit toy curve: baby step, giant step ----
p, a, G, n = 4294967291, 3, (2, 6), 4294956467
assert (G[1]**2 - G[0]**3 - a*G[0] - 22) % p == 0 and mul(n, G, p, a)[0] is None
assert all(n % q for q in range(2, isqrt(n) + 1))
secret = 3141592653
Q = mul(secret, G, p, a)[0]
m = isqrt(n - 1) + 1
table, R = {}, None
for j in range(m):
    table.setdefault(R, j); R = add(R, G, p, a)
step = (R[0], -R[1] % p)  # -mG
T, i = Q, 0
while T not in table: T, i = add(T, step, p, a), i + 1
found = i * m + table[T]
print("32-bit toy: n", n, " baby steps", m, " giant steps", i, " total", m + i)
print("found key", found, " exhaustive search would need up to", n - 1, "additions")
assert found == secret and m + i <= 2 * m

# ---- Curve25519, X25519 as in RFC 7748 ----
P25 = 2**255 - 19
N25 = 2**252 + 27742317777372353535851937790883648493
def ladder(kint, u):  # Montgomery ladder: one doubling and one addition per bit
    x1, x2, z2, x3, z3 = u, 1, 0, u, 1
    for t in range(254, -1, -1):
        if (kint >> t) & 1: x2, x3, z2, z3 = x3, x2, z3, z2
        A, B, C, D = x2 + z2, x2 - z2, x3 + z3, x3 - z3
        AA, BB, DA, CB = A * A % P25, B * B % P25, D * A % P25, C * B % P25
        E = AA - BB
        x3, z3 = (DA + CB) ** 2 % P25, x1 * (DA - CB) ** 2 % P25
        x2, z2 = AA * BB % P25, E * (AA + 121665 * E) % P25
        if (kint >> t) & 1: x2, x3, z2, z3 = x3, x2, z3, z2
    return x2 * inv(z2, P25) % P25 if z2 else 0  # O has u = 0, as in RFC 7748
def clamp(h):
    kb = bytearray.fromhex(h); kb[0] &= 248; kb[31] = (kb[31] & 127) | 64
    return int.from_bytes(kb, "little")
def x25519(h, u): return ladder(clamp(h), u).to_bytes(32, "little").hex()
def ux(h): return int.from_bytes(bytes.fromhex(h), "little") & (2**255 - 1)
a_hex = "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
b_hex = "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
KA, KB = x25519(a_hex, 9), x25519(b_hex, 9)
K1, K2 = x25519(a_hex, ux(KB)), x25519(b_hex, ux(KA))
print("laptop public", KA); print("bank public  ", KB); print("shared, both ", K1)
assert KA == "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
assert KB == "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
assert K1 == K2 == "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"
print("order check: u of nG", ladder(N25, 9), " u of (n+1)G", ladder(N25 + 1, 9))
assert ladder(N25, 9) == 0 and ladder(N25 + 1, 9) == 9
ka = clamp(a_hex)
print("laptop scalar bits", ka.bit_length(), " double-and-add: doublings", ka.bit_length() - 1,
      " additions", bin(ka).count("1") - 1, " ladder steps", 255)
print("bank sends u = 0, a point of order 2: shared", x25519(a_hex, 0))
assert x25519(a_hex, 0) == "0" * 64
print("bytes: public key 32, RSA-3072 modulus", 3072 // 8, " n has", N25.bit_length(), "bits  A", 4 * 121665 + 2)
print(f"generic attack, about sqrt(pi n / 4) steps: 2^{(log2(pi / 4) + N25.bit_length() - 1) / 2:.1f}")
print("ALL CHECKS PASS")
