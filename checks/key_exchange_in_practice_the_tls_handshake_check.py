# The TLS handshake -- the check behind the card.  Standard library only.  INSECURE TOY SIZES: a 62-bit
# group stands in for X25519, 64-bit RSA for 2048-bit RSA, an HMAC stream for AES-GCM, SplitMix64 for a CSPRNG.
M32, M64 = (1 << 32) - 1, (1 << 64) - 1
def iroot(x, k):                                   # largest r with r^k <= x, bit by bit
    r = 0
    for i in range(40, -1, -1): r |= (1 << i) * ((r | 1 << i) ** k <= x)
    return r
PR = [n for n in range(2, 312) if all(n % d for d in range(2, n))]
H0 = [iroot(p << 64, 2) & M32 for p in PR[:8]]     # SHA-256 constants: square roots
KK = [iroot(p << 96, 3) & M32 for p in PR[:64]]    # and cube roots of the first primes
def rotr(x, n): return ((x >> n) | (x << (32 - n))) & M32
def sha256(msg):
    h, n = H0[:], len(msg)
    msg = msg + b"\x80" + b"\x00" * ((55 - n) % 64) + (8 * n).to_bytes(8, "big")
    for i in range(0, len(msg), 64):
        w = [int.from_bytes(msg[i + 4 * j:i + 4 * j + 4], "big") for j in range(16)]
        for j in range(16, 64):
            s0 = rotr(w[j - 15], 7) ^ rotr(w[j - 15], 18) ^ (w[j - 15] >> 3)
            s1 = rotr(w[j - 2], 17) ^ rotr(w[j - 2], 19) ^ (w[j - 2] >> 10)
            w.append((w[j - 16] + s0 + w[j - 7] + s1) & M32)
        a, b, c, d, e, f, g, hh = h
        for j in range(64):
            t1 = hh + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + KK[j] + w[j]
            t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))
            a, b, c, d, e, f, g, hh = (t1 + t2) & M32, a, b, c, (d + t1) & M32, e, f, g
        h = [(x + y) & M32 for x, y in zip(h, [a, b, c, d, e, f, g, hh])]
    return b"".join(x.to_bytes(4, "big") for x in h)
def hmac(key, msg):                                # keys here are at most 64 bytes
    key = key + b"\x00" * (64 - len(key))
    return sha256(bytes(x ^ 0x5C for x in key) + sha256(bytes(x ^ 0x36 for x in key) + msg))
def expand(prk, info, n):                          # HKDF-Expand, RFC 5869
    t = [b""]
    for i in range(1, n // 32 + 2): t.append(hmac(prk, t[-1] + info + bytes([i])))
    return b"".join(t)[:n]
assert sha256(b"abc").hex() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
assert expand(hmac(bytes(range(13)), b"\x0b" * 22), bytes(range(0xF0, 0xFA)), 42).hex() == (
    "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865")
print("SHA-256 'abc' vector and RFC 5869 HKDF test 1: both match")
def mpow(x, e, m):
    r, x = 1, x % m
    while e: r, x, e = (r * x % m if e & 1 else r), x * x % m, e >> 1
    return r
def is_prime(n):                                   # Miller-Rabin, exact below 3.3 x 10^24
    if n < 2 or any(n % s == 0 for s in PR[:12]): return n in PR[:12]
    s = ((n - 1) & (1 - n)).bit_length() - 1       # n - 1 = d * 2^s with d odd
    d = (n - 1) >> s
    return all(mpow(a, d, n) == 1 or any(mpow(a, d << r, n) == n - 1 for r in range(s)) for a in PR[:12])
def inv(a, m):                                     # extended Euclid
    r0, r1, s0, s1 = m, a % m, 0, 1
    while r1: k = r0 // r1; r0, r1, s0, s1 = r1, r0 - k * r1, s1, s0 - k * s1
    assert r0 == 1
    return s0 % m
def splitmix(s):                                   # the next 64-bit output after state s
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
q = 1 << 60                                        # the group: p = 2q + 1, both prime
while not (is_prime(q) and is_prime(2 * q + 1)): q += 1
p, g = 2 * q + 1, 4                                # g = 2^2 lies in the order-q subgroup
assert mpow(g, q, p) == 1
print(f"group: p = {p} ({p.bit_length()} bits), g = {g}, order q = {q}")
def rsa(x, y):                                     # the first primes above x and y
    a, b = (next(i for i in range(v, v + 9999) if is_prime(i)) for v in (x, y))
    return a * b, inv(65537, (a - 1) * (b - 1))
nR, dR = rsa(3_000_000_000, 3_500_000_000)         # the root, in the laptop's trust store
nB, dB = rsa(2_500_000_000, 2_800_000_000)         # the bank's long-term signing key
nX, dX = rsa(2_600_000_000, 3_200_000_000)         # the attacker's own key
def hnum(data, n): return int.from_bytes(sha256(data), "big") % n
def sign(d, n, data): return mpow(hnum(data, n), d, n)
def verify(n, data, s): return mpow(s, 65537, n) == hnum(data, n)
def cert(name, n, d_by, n_by): return (b := f"subject={name};n={n};e=65537;issuer=Root".encode()), sign(d_by, n_by, b)
def check(crt, t, cv, names=True):                 # the laptop's three checks
    if not verify(nR, crt[0], crt[1]): return "rejected: root signature fails"
    f = dict(x.split("=") for x in crt[0].decode().split(";"))
    if names and f["subject"] != "bank.example": return "rejected: name is not bank.example"
    return "accepted" if verify(int(f["n"]), t + crt[0], cv) else "rejected: transcript signature fails"
def b8(x): return x.to_bytes(8, "big")
def party(seed):                                   # a fresh random and a fresh secret exponent
    s, rnd = splitmix(seed)
    x = splitmix(s)[1] % (q - 1) + 1
    return b8(rnd), x, mpow(g, x, p)
def kdf(z, label, t): return expand(hmac(b"\x00" * 32, b8(z)), label + sha256(t), 32)
def stream(k, m): return bytes(x ^ y for x, y in zip(m, expand(k, b"stream", len(m))))
def seal(k, m): return (c := stream(k, m)) + hmac(k, b"tag" + c)[:16]   # the DEM, with a tag
def unseal(k, ct): return stream(k, ct[:-16]) if hmac(k, b"tag" + ct[:-16])[:16] == ct[-16:] else None
m = b"TRANSFER 750 TO BOB."                        # ---- the honest handshake ----
rc, a, A = party(0x1A97_0B5E_ED00_2026)
rs, b, B = party(0xBA4C_0B5E_ED00_2026)
CH, SH = b"CH" + rc + b8(A), b"SH" + rs + b8(B)
Zc, Zs = mpow(B, a, p), mpow(A, b, p)
assert Zc == Zs == mpow(g, a * b % q, p)           # both sides, and the exponent road
crt = cert("bank.example", nB, dR, nR)
CV = sign(dB, nB, CH + SH + crt[0])
print(f"laptop: a = {a}, A = {A}\nbank:   b = {b}, B = {B}\nshared: Z = B^a = A^b = {Zc}")
print(f"bank's n = {nB}, root's signature = {crt[1]}, CertificateVerify = {CV}")
print("laptop's verdict:", verdict := check(crt, CH + SH, CV))
T, Td = CH + SH + crt[0] + b8(CV), bytes([CH[0] ^ 1]) + CH[1:] + SH + crt[0] + b8(CV)   # Td: one ClientHello bit changed
fin, fin_d = hmac(kdf(Zs, b"s fin", T), sha256(T)), hmac(kdf(Zs, b"s fin", Td), sha256(Td))   # the bank's Finished
Kc, Ks = kdf(Zc, b"c app", T + fin), kdf(Zs, b"c app", T + fin)
assert verdict == "accepted" and fin_d != fin and kdf(Zs, b"c app", Td + fin_d) != Kc   # Finished and K follow T
ct = seal(Kc, m)
print(f"K starts {Kc[:8].hex()}; order on the wire: {ct[:8].hex()}..., {len(ct)} bytes = {len(m)} of order + {len(ct) - len(m)} of tag")
assert unseal(Ks, ct) == m and unseal(Ks, ct[:3] + bytes([ct[3] ^ 1]) + ct[4:]) is None
print("bank opens:", unseal(Ks, ct).decode(), "| one bit flipped on the wire: rejected")
print(f"one ClientHello bit changed in transit: the bank's Finished starts {fin_d[:4].hex()}, not {fin[:4].hex()}; K changes too")
_, x, X = party(0xE7E_2026)                        # ---- a man in the middle, secret x ----
CHx, SHx = b"CH" + rc + b8(X), b"SH" + rs + b8(X)  # what the bank and the laptop now see
read = unseal(kdf(mpow(A, x, p), b"c app", CH + SHx), seal(kdf(mpow(X, a, p), b"c app", CH + SHx), m))
fwd = seal(kdf(mpow(B, x, p), b"c app", CHx + SH), b"TRANSFER 950 TO EVE.")
print("no certificate: attacker reads", read.decode(), "| bank receives", unseal(kdf(mpow(X, b, p), b"c app", CHx + SH), fwd).decode())
assert read == m
tL = CH + SHx                                      # the laptop's view of the transcript
evil = cert("evil.example", nX, dR, nR)            # a real certificate, for the wrong name
fake = cert("bank.example", nX, dX, nX)            # made by the attacker, not the root
tries = [("relay the bank's signature", crt, sign(dB, nB, CHx + SH + crt[0])),
         ("sign with his own key", crt, sign(dX, nX, tL + crt[0])),
         ("real certificate for evil.example", evil, sign(dX, nX, tL + evil[0])),
         ("self-made certificate", fake, sign(dX, nX, tL + fake[0]))]
for name, c, s in tries:
    print(f"  {name}: {check(c, tL, s)}")
    assert check(c, tL, s) != "accepted"
lax = check(evil, tL, sign(dX, nX, tL + evil[0]), names=False)
print("  evil.example with the name check skipped:", lax)
assert lax == "accepted"
pm = splitmix(7)[1] % nB                           # ---- the bank's key d leaks later ----
E = mpow(pm, 65537, nB)                            # old style: RSA carries the laptop's secret
old = seal(kdf(pm, b"c app", CH + SH), m)
print("RSA key transport, recorded, d leaked:", unseal(kdf(mpow(E, dB, nB), b"c app", CH + SH), old).decode())
assert mpow(E, dB, nB) == pm
stolen = check(crt, tL, sign(dB, nB, tL + crt[0]))
print("ephemeral DH, d leaked: a new session in the middle is", stolen)
assert stolen == "accepted"
print(f"the recorded session needs Z from A and B alone: about 2^{iroot(q, 2).bit_length() - 1} generic steps here (index calculus needs fewer), 2^126 for X25519")
_, _, A_bad = party(pid := 23451)                         # ---- a predictable seed ----
seed = next(s for s in range(32768) if party(s)[2] == A_bad)
print(f"seed from a process number, {(32768).bit_length() - 1} bits, not 128: found in {seed + 1} of 32768 tries, a = {(a_bad := party(seed)[1])}")
assert seed == pid and mpow(B, a_bad, p) == mpow(A_bad, b, p)   # attacker's Z = the bank's Z
print("figure, arrows at y = 62, 102, 142, 182, 222 on a 360 x 250 panel (schematic)")
print("ALL CHECKS PASS")
