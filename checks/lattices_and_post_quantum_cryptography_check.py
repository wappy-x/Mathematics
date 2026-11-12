# Lattices and post-quantum cryptography -- the check behind the card.  Standard library only.
# Kyber-768's inner encryption (K-PKE in FIPS 203) at real sizes; INSECURE: SplitMix64, no SHAKE/NTT/FO.
from math import pi, sqrt, exp
M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
Q, N, K = 3329, 256, 3
def cbd(rng, eta):                         # eta coin flips minus eta coin flips: a small number
    x, m = rng.next(), (1 << eta) - 1
    return bin(x & m).count("1") - bin((x >> eta) & m).count("1")
def small(rng, eta): return [cbd(rng, eta) for _ in range(N)]
def pmul(a, b):                            # polynomial product with X^256 = -1, mod q (a is small)
    c = [0] * (2 * N)
    for i, ai in enumerate(a):
        if ai:
            for j, bj in enumerate(b): c[i + j] += ai * bj
    return [(c[i] - c[i + N]) % Q for i in range(N)]
def padd(*ps): return [sum(x) % Q for x in zip(*ps)]
def centred(x): x %= Q; return x - Q if x > Q // 2 else x
def compress(x, d): return ((x << (d + 1)) + Q) // (2 * Q) % (1 << d)
def decompress(y, d): return (y * Q * 2 + (1 << d)) >> (d + 1)
def pack(polys, d):                        # every number in d bits, 8 bits to a byte
    bits = [(c >> i) & 1 for p in polys for c in p for i in range(d)]
    return bytes(sum(bits[j + i] << i for i in range(8)) for j in range(0, len(bits), 8))
def keygen(rng, eta):
    A = [[[rng.next() % Q for _ in range(N)] for _ in range(K)] for _ in range(K)]
    s, e = [small(rng, eta) for _ in range(K)], [small(rng, eta) for _ in range(K)]
    t = [padd(*[pmul(s[j], A[i][j]) for j in range(K)], e[i]) for i in range(K)]   # t = A s + e
    return A, s, e, t
def encrypt(rng, A, t, m, eta):
    r, e1, e2 = [small(rng, eta) for _ in range(K)], [small(rng, eta) for _ in range(K)], small(rng, eta)
    u = [padd(*[pmul(r[i], A[i][j]) for i in range(K)], e1[j]) for j in range(K)]  # u = A^T r + e1
    v = padd(*[pmul(r[i], t[i]) for i in range(K)], e2, [1665 * b for b in m])      # v = t.r + e2 + 1665 m
    return [[compress(x, 10) for x in p] for p in u], [compress(x, 4) for x in v], (r, e1, e2, u, v)
def decrypt(s, cu, cv):                    # w = v - s.u, then round each number to 0 or 1665
    u = [[decompress(x, 10) for x in p] for p in cu]
    w = [(decompress(y, 4) - z) % Q for y, z in zip(cv, padd(*[pmul(s[i], u[i]) for i in range(K)]))]
    return [compress(x, 1) for x in w], w
def run(eta, trials, seed):                # wrong bits and the largest noise over several messages
    rng = SplitMix64(seed); A, s, e, t = keygen(rng, eta); bad = big = 0
    for _ in range(trials):
        m = [rng.next() & 1 for _ in range(N)]
        cu, cv, _ = encrypt(rng, A, t, m, eta); got, w = decrypt(s, cu, cv)
        bad += sum(x != y for x, y in zip(got, m)); big = max(big, max(abs(centred(x - 1665 * b)) for x, b in zip(w, m)))
    return bad, big, (A, s, e, t, cu, cv, m, rng)
print("Kyber-768 inner scheme, k = 3, n = 256, q = 3329, eta = 2; SplitMix64 seed 2026: INSECURE")
bad, big, (A, s, e, t, cu, cv, m, rng) = run(2, 8, 2026)
pk, ct = pack(t, 12) + bytes(32), pack(cu, 10) + pack([cv], 4)   # + 32-byte seed that rebuilds A
print(f"public key bytes: 3 x 256 x 12 bits / 8 = {384 * K}, + 32 = {384 * K + 32}, packed {len(pk)}")
print(f"ciphertext bytes: 3 x 256 x 10 / 8 = {320 * K}, + 256 x 4 / 8 = 128, total {32 * (10 * K + 4)}, packed {len(ct)}")
print(f"secret numbers hidden in the key: {K * N}; shared secret 32 bytes = 256 bits")
print(f"8 messages, {8 * N} bits: wrong bits {bad}, largest noise {big}, margin q/4 = {Q // 4}")
assert len(pk) == 384 * K + 32 == 1184 and len(ct) == 32 * (10 * K + 4) == 1088 and bad == 0 and big < Q // 4
r, e1, e2, u, v = encrypt(SplitMix64(5), A, t, m, 2)[2]   # Step 3's identity, uncompressed
lhs = [(x - y) % Q for x, y in zip(v, padd(*[pmul(s[i], u[i]) for i in range(K)]))]
rhs = [(a - b + c + 1665 * d) % Q for a, b, c, d in zip(padd(*[pmul(r[i], e[i]) for i in range(K)]),
       padd(*[pmul(s[i], e1[i]) for i in range(K)]), e2, m)]
print("v - s.u equals e.r - s.e1 + e2 + 1665 m in all 256 places:", lhs == rhs)
assert lhs == rhs and pmul([0] * (N - 1) + [1], [0, 1] + [0] * (N - 2)) == [Q - 1] + [0] * (N - 1)   # and X^255 * X = -1
print(f"X25519 key 32 bytes; Kyber-768 key {len(pk) / 32:.1f} times larger; hybrid shares {len(pk) + 32} and {len(ct) + 32}")
print("; ".join(f"Kyber-{nm}: key {384 * kk + 32}, ciphertext {32 * (du * kk + dv)} bytes" for nm, kk, du, dv in (("512", 2, 10, 4), ("1024", 4, 11, 5))))
# ---- what breaks ----
bad24, big24, _ = run(24, 1, 2026)
print(f"noise too wide, eta = 24: wrong bits {bad24} of 256, largest noise {big24}")
assert bad24 > 0 and big24 > Q // 4
m1, m2 = [rng.next() & 1 for _ in range(N)], [rng.next() & 1 for _ in range(N)]
v1, v2 = encrypt(SplitMix64(99), A, t, m1, 2)[1], encrypt(SplitMix64(99), A, t, m2, 2)[1]
guess = [1 if 4 <= (a - b) % 16 <= 12 else 0 for a, b in zip(v1, v2)]
same = sum(g == x ^ y for g, x, y in zip(guess, m1, m2))
print(f"randomness reused for two messages: their XOR read off in {same} of 256 places")
assert same == 256
def mpow(b, k, mod): return 1 if k == 0 else mpow(b * b % mod, k >> 1, mod) * (b if k & 1 else 1) % mod
def solve(Am, b):                          # Gaussian elimination mod q, inverse by Fermat
    M = [row[:] + [x] for row, x in zip(Am, b)]
    for c in range(len(M)):
        p = next(i for i in range(c, len(M)) if M[i][c]); M[c], M[p] = M[p], M[c]
        iv = mpow(M[c][c], Q - 2, Q); M[c] = [x * iv % Q for x in M[c]]
        for i in range(len(M)):
            if i != c: f = M[i][c]; M[i] = [(x - f * y) % Q for x, y in zip(M[i], M[c])]
    return [centred(row[-1]) for row in M]
g = SplitMix64(7); At = [[g.next() % Q for _ in range(8)] for _ in range(8)]
st, et = [cbd(g, 2) for _ in range(8)], [cbd(g, 2) for _ in range(8)]
b0 = [sum(a * x for a, x in zip(row, st)) % Q for row in At]
s0, s1 = solve(At, b0), solve(At, [(x + y) % Q for x, y in zip(b0, et)])
print(f"toy LWE, 8 unknowns: secret {st}\n  no noise, elimination gives {s0}\n  with noise it gives {s1}")
assert s0 == st and s1 != st
# ---- the lattice picture: a good basis and a bad one for the same grid ----
dot, det = lambda a, b: a[0] * b[0] + a[1] * b[1], lambda p, q: p[0] * q[1] - p[1] * q[0]
def comb(x, y, p, q): return (x * p[0] + y * q[0], x * p[1] + y * q[1])
def rnd(n, d): return (2 * n + d) // (2 * d) if d > 0 else rnd(-n, -d)
g1, g2 = (4, 1), (-1, 3); c1, c2 = comb(5, 3, g1, g2), comb(3, 2, g1, g2)
def gauss(a, b):                           # Lagrange-Gauss: subtract the nearest multiple, swap, repeat
    steps = 0
    while True:
        if dot(a, a) > dot(b, b): a, b = b, a
        k = rnd(dot(a, b), dot(a, a))
        if k == 0: return a, b, steps
        b, steps = comb(-k, 1, a, b), steps + 1
brute = min(dot(p, p) for x in range(-20, 21) for y in range(-20, 21) if (p := comb(x, y, g1, g2)) != (0, 0))
ra, rb, st2 = gauss(c1, c2)
print(f"bad basis {c1} {c2}, area {det(c1, c2)}; good basis {g1} {g2}, area {det(g1, g2)}")
print(f"Gauss reduction of the bad basis, {st2} steps: {ra} {rb}; shortest by brute force has length^2 {brute}")
assert dot(ra, ra) == brute == 10 and abs(det(ra, rb)) == 13
def babai(tg, p, q):                       # write the target in the basis, round each amount
    d = det(p, q); return comb(rnd(det(tg, q), d), rnd(det(p, tg), d), p, q)
tg = (6, 10); okp, badp = babai(tg, g1, g2), babai(tg, c1, c2); dist2 = lambda a: (a[0] - tg[0]) ** 2 + (a[1] - tg[1]) ** 2
print(f"target {tg}: rounding in good basis -> {okp}, distance^2 {dist2(okp)}; in bad basis -> {badp}, distance^2 {dist2(badp)}")
assert dist2(okp) == 2 and dist2(badp) == 25 and min((dist2(p), p) for x in range(-20, 21) for y in range(-20, 21) for p in [comb(x, y, g1, g2)])[1] == okp
print(f"bad = 5 g1 + 3 g2 and 3 g1 + 2 g2, mix area 5 x 2 - 3 x 3 = {5 * 2 - 3 * 3}; amounts good {det(tg, g2)}/13 {det(g1, tg)}/13, bad {det(tg, c2)}/13 {det(c1, tg)}/13")
print(f"figure, good {g1} {g2}; bad {c1} {c2}; target {tg}; right {okp}; bad-basis answer {badp}")
# ---- security estimate (primal attack, core-SVP rule) and what Shor ends ----
def delta(b): return ((pi * b) ** (1 / b) * b / (2 * pi * exp(1))) ** (1 / (2 * (b - 1)))
def beta(n, sigma, q=Q, top=0):            # smallest BKZ block size that finds the short vector
    best = top = top or n                  # m, the samples used, runs up to top (Kyber gives n)
    for m in range(n // 2, top + 1):
        d = n + m + 1
        best = next((b for b in range(60, best) if sigma * sqrt(b) <= delta(b) ** (2 * b - d - 1) * q ** (m / d)), best)
    return best
bs = [beta(512, sqrt(1.5)), beta(768, 1.0), beta(1024, 1.0)]
print("block size beta for Kyber-512/768/1024:", bs, "-> classical 2^(0.292 beta):",
      " ".join(f"{0.292 * b:.1f}" for b in bs), "quantum 2^(0.265 beta):", " ".join(f"{0.265 * b:.1f}" for b in bs))
assert bs[0] < bs[1] < bs[2] and 0.292 * bs[1] > 128
nh = beta(1024, sqrt(8), 12289, 2048); print(f"same rule on New Hope, n = 1024, q = 12289: beta {nh}; its paper, Table 1: 967"); assert abs(nh - 967) <= 2
for nm, tau, eta, ga, gb, k, l, lam, om in (("44", 39, 2, 2 ** 17, 95232, 4, 4, 128, 80),
        ("65", 49, 4, 2 ** 19, 261888, 6, 5, 192, 55), ("87", 60, 2, 2 ** 19, 261888, 8, 7, 256, 75)):
    reps = exp(256 * tau * eta * (l / ga + k / gb))   # expected tries before a signature is safe to release
    sig = lam // 4 + l * 32 * (1 + (ga.bit_length() - 1)) + om + k
    print(f"ML-DSA-{nm}: public key {32 + 320 * k} bytes, signature {sig} bytes, expected tries {reps:.2f}")
    assert abs(reps - {"44": 4.25, "65": 5.1, "87": 3.85}[nm]) < 0.01 and (32 + 320 * k, sig) == {"44": (1312, 2420), "65": (1952, 3309), "87": (2592, 4627)}[nm]   # FIPS 204, Tables 1 and 2
R, a = 3233, 3; r = next(r for r in range(1, R) if mpow(a, r, R) == 1)   # the step Shor does on a quantum computer
gcd = lambda x, y: x if y == 0 else gcd(y, x % y); h = mpow(a, r // 2, R); f1, f2 = gcd(h - 1, R), gcd(h + 1, R)
print(f"Shor's idea on RSA modulus {R}: period of {a} is {r}; {a}^{r // 2} = {h}; factors {f1} x {f2}")
assert f1 * f2 == R and 1 < f1 < R
print(f"period of 2 is {next(r for r in range(1, R) if mpow(2, r, R) == 1)}: 2^390 = {mpow(2, 390, R)} = -1, no factor")
print("ALL CHECKS PASS")
