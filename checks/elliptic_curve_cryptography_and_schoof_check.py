# Curves for keys -- the check behind the card.  Standard library only; nothing
# imported counts points or adds them.  The toy curve is y^2 = x^3 + 2x + 4 over
# F_13, with 17 points; the house curve y^2 = x^3 - 2 is reduced mod 7, 13 and 41.
# P-256 is quoted from SEC 2 as sizes only.  Every toy curve here is insecure.
import math
def inv(a, m): return pow(a % m, m - 2, m)  # reciprocal mod a prime m, by Fermat
def add(P, Q, a, p):                    # chord and tangent, coordinates mod p
    if P is None or Q is None: return P or Q
    (x1, y1), (x2, y2) = P, Q
    if x1 == x2 and (y1 + y2) % p == 0: return None
    if P == Q: m = (3 * x1 * x1 + a) * inv(2 * y1, p) % p
    else: m = (y2 - y1) * inv(x2 - x1, p) % p
    x3 = (m * m - x1 - x2) % p
    return (x3, (m * (x1 - x3) - y1) % p)
def mul(k, P, a, p):                    # double-and-add, top bit first
    R = None
    for bit in bin(k)[2:]:
        R = add(R, R, a, p)
        if bit == '1': R = add(R, P, a, p)
    return R
def rep(k, P, a, p):                    # second road: add P to itself k times
    R = None
    for _ in range(k): R = add(R, P, a, p)
    return R
def points(a, b, p):                    # every pair (x, y) tried; O is not listed
    return [(x, y) for x in range(p) for y in range(p) if (y * y - x**3 - a * x - b) % p == 0]
def count_euler(a, b, p):               # O, plus 1 + (Euler's square test) for each x
    n = 1
    for x in range(p):
        e = pow((x**3 + a * x + b) % p, (p - 1) // 2, p)
        n += 1 if e == 0 else 2 if e == 1 else 0
    return n
def order(P, a, p):
    k, R = 1, P
    while R is not None: k, R = k + 1, add(R, P, a, p)
    return k
def pmod(u, f, p):                      # remainder of polynomial u by f, mod p, low degree first
    u = [c % p for c in u]
    while u and u[-1] == 0: u.pop()
    while len(u) >= len(f):
        c, s = u[-1] * inv(f[-1], p) % p, len(u) - len(f)
        for i, fi in enumerate(f): u[s + i] = (u[s + i] - c * fi) % p
        while u and u[-1] == 0: u.pop()
    return u
def pmulmod(u, v, f, p):
    w = [0] * (len(u) + len(v) - 1)
    for i, ui in enumerate(u):
        for j, vj in enumerate(v): w[i + j] += ui * vj
    return pmod(w, f, p)
def two_step(a, b, p):                  # Schoof's l = 2 step: x^p mod f, then gcd(f, x^p - x)
    f, xp, sq, e = [b % p, a % p, 0, 1], [1], [0, 1], p
    while e:
        if e & 1: xp = pmulmod(xp, sq, f, p)
        sq, e = pmulmod(sq, sq, f, p), e >> 1
    g, h = f, pmod(xp[:1] + [xp[1] - 1 if len(xp) > 1 else -1] + xp[2:], f, p)
    while h: g, h = h, pmod(g, h, p)
    return xp, len(g) - 1
def is_prime(l): return l > 1 and all(l % d for d in range(2, l))
def emb_degree(q, p):                   # least k with q dividing p^k - 1; none if q = p
    return None if q == p else next(k for k in range(1, q) if pow(p, k, q) == 1)
p, a, b, n, G = 13, 2, 4, 17, (0, 2)
pts, ordG, rt = points(a, b, p), order(G, a, p), 2 * math.sqrt(p)
in_window = [m for m in range(1, 40) if m % ordG == 0 and p + 1 - rt <= m <= p + 1 + rt]
print(f"toy curve y^2 = x^3 + 2x + 4 over F_13; Hasse window 14 +/- {rt:.2f}")
print(f"count 1, every pair (x, y): {len(pts) + 1}")
print(f"count 2, Euler's square test on 13 values of x: {count_euler(a, b, p)}")
print(f"count 3, order of G = {G} is {ordG}; multiples of it in the window: {in_window}")
(xp, deg), t = two_step(a, b, p), p + 1 - n
roots = [x for x in range(p) if (x**3 + a * x + b) % p == 0]
print(f"Schoof l = 2: x^13 = {xp[2]}x^2 + {xp[1]}x + {xp[0]} mod f; gcd(f, x^13 - x) has degree "
      f"{deg}; roots by trial {len(roots)}; a_p = 14 - 17 = {t}, odd")
need, prod, l = [], 1, 1
while prod <= 2 * rt:
    l += 1
    if is_prime(l): need, prod = need + [l], prod * l
bits, cnt, l = 0.0, 0, 1
while bits <= 130:
    l += 1
    if is_prime(l): bits, cnt = bits + math.log2(l), cnt + 1
print(f"Schoof primes for p = 13: {need}, product {prod} > 4 sqrt(p) = {2 * rt:.2f}")
print(f"Schoof primes for a 256-bit p: {cnt} primes, 2 up to {l}, product 2^{bits:.1f} > 2^130")
dP, dL = 6, 9                           # the phone's and the lock's secret numbers
QP, QL = mul(dP, G, a, p), mul(dL, G, a, p)
SP, SL = mul(dP, QL, a, p), mul(dL, QP, a, p)
print(f"ECDH: phone 6G = {QP}, lock 9G = {QL}; phone 6 QL = {SP}, lock 9 QP = {SL}")
print(f"6 x 9 = 54 = {dP * dL % n} mod 17; 3G by repeated addition = {rep(dP * dL % n, G, a, p)}")
print("double-and-add, 6 = 110 in binary: " + ", ".join(f"{k}G {rep(k, G, a, p)}" for k in (1, 2, 3, 6)))
tries = next(k for k in range(1, n) if rep(k, G, a, p) == QP)
print(f"listener tries G, 2G, 3G, ...: phone's key found on try {tries} of at most 16")
def toy_hash(msg):                      # a stated stand-in for SHA-256, NOT a real hash
    h = 0
    for c in msg.encode(): h = (h * 31 + c) % 65521
    return h
def verify(z, r, s, Q):
    w = inv(s, n)
    X = add(mul(z * w % n, G, a, p), mul(r * w % n, Q, a, p), a, p)
    return X is not None and X[0] % n == r, w, z * w % n, r * w % n, X
dS, k = 5, 8                            # the maker's signing key, the one-time number
QS, hz, R = mul(dS, G, a, p), toy_hash("fw 1.4"), mul(k, G, a, p)
z, r = hz % n, R[0] % n
s = inv(k, n) * (z + r * dS) % n
ok, w, u1, u2, X = verify(z, r, s, QS)
z2, s13 = toy_hash("fw 1.5") % n, inv(k, p) * (z + r * dS) % p
print(f"ECDSA: QS = 5G = {QS}; toy hash of 'fw 1.4' = {hz}, z = {z}; 8G = {R}, r = {r}, 1/8 = {inv(k, n)}, s = {s}")
print(f"verify: 1/s = {w}, u1 = {u1}, u2 = {u2}, u1 G + u2 QS = {X}, valid {ok}")
print(f"same signature on 'fw 1.5' (z = {z2}): valid {verify(z2, r, s, QS)[0]}")
print(f"mistake, s worked mod 13 not 17: s = {s13}, valid {verify(z, r, s13, QS)[0]}")
print("curve           points  cubic roots  largest prime  anomalous  embedding degree")
table = []
for name, aa, bb, pp in [("toy, mod 13", 2, 4, 13), ("house, mod 7", 0, -2, 7),
                         ("house, mod 13", 0, -2, 13), ("house, mod 41", 0, -2, 41)]:
    N = len(points(aa, bb, pp)) + 1
    q = max(d for d in range(2, N + 1) if N % d == 0 and is_prime(d))
    kd, rts = emb_degree(q, pp), two_step(aa, bb, pp)[1]
    pj = [pp ** j % q for j in range(1, q)]  # second road: list p^j mod q; the first 1 is at kappa
    table.append((N, q, N == pp, kd, rts, pj.index(1) + 1 if 1 in pj else None))
    print(f"{name:<15} {N:>6}  {rts:>11}  {q:>13}  {'yes' if N == pp else 'no':>9}  {'-' if kd is None else kd:>16}")
G41 = next(P for P in points(0, -2, 41) if order(P, 0, 41) == 42)
d, trials, res = 29, 0, []
Q41 = mul(d, G41, 0, 41)
for q in (2, 3, 7):                     # Pohlig-Hellman: solve in each small piece
    Gq, Qq, e = mul(42 // q, G41, 0, 41), mul(42 // q, Q41, 0, 41), 0
    while rep(e, Gq, 0, 41) != Qq: e += 1
    trials, res = trials + e + 1, res + [e]
found = next(x for x in range(42) if [x % 2, x % 3, x % 7] == res)
print(f"Pohlig-Hellman mod 41: G = {G41}, Q = {d}G = {Q41}; key mod 2, 3, 7 = {res}; "
      f"key {found} in {trials} trials, against {d} by trying G, 2G, ...")
print("P-256 (SEC 2): p = 2^256 - 2^224 + 2^192 + 2^96 - 1, 256 bits; n prime, 256 bits; cofactor 1")
for nb, mod in [(224, 2048), (256, 3072), (384, 7680), (521, 15360)]:
    print(f"n of {nb} bits: rho about 2^{0.5 * (nb + math.log2(math.pi / 4)):.1f} steps; "
          f"SP 800-57 modulus at that level {mod} bits")
print("figure, points " + " ".join(f"({x},{y})" for x, y in pts) + f"; G {G} QP {QP} QL {QL} S {SP}")
assert len(pts) + 1 == count_euler(a, b, p) == n and in_window == [n]   # three counts agree
assert deg == len(roots) and all((r[4] > 0) == (r[0] % 2 == 0) for r in table)  # l = 2 step
assert SP == SL == rep(dP * dL % n, G, a, p) and QP == rep(dP, G, a, p)  # ECDH, two roads
assert ok and X == R and not verify(z2, r, s, QS)[0]                     # ECDSA checks, tamper fails
assert found == d and trials == sum(d % q + 1 for q in (2, 3, 7))         # Pohlig-Hellman, two roads
assert table[1][2] and table[3][1] == 7                                     # anomalous and smooth flags
assert all(r[3] == r[5] for r in table) and [r[3] for r in table[:4]] == [4, None, 18, 2]  # kappa, two roads
print("ALL CHECKS PASS")
