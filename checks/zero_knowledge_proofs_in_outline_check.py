# Zero-knowledge in outline -- the check behind the card.  Standard library only.
# Schnorr's proof that the laptop knows x with y = g^x mod p, in a TOY group:
# p = 23, q = 11, g = 4.  INSECURE: real proofs use a q of 256 bits (RFC 8235).
# The hash is FNV-1a, also a toy; real Fiat-Shamir uses SHA-256 or better.
from math import sqrt
P, Q, G, M64 = 23, 11, 4, (1 << 64) - 1

def power(b, e, m):                       # square-and-multiply, written out
    out, b = 1, b % m
    while e:
        if e & 1:
            out = out * b % m
        b, e = b * b % m, e >> 1
    return out

def fnv(text):                            # FNV-1a, 64 bits: a toy hash, NOT secure
    h = 0xCBF29CE484222325
    for ch in text.encode():
        h = ((h ^ ch) * 0x100000001B3) & M64
    return h

assert fnv("a") == 0xAF63DC4C8601EC8C               # FNV-1a's published 64-bit test value
print(f"FNV-1a test vector: fnv('a') = {fnv('a'):016x}, matches")

class SplitMix64:                         # seeded generator, same in Rust
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)

def verify(y, t, c, s):                   # the bank's one test: g^s = t * y^c
    return power(G, s, P) == t * power(y, c, P) % P

def fake_t(y, c, s):                      # t made backwards: g^s * y^(-c)
    return power(G, s, P) * power(y, Q - c, P) % P

def fs(y, t, msg):                        # Fiat-Shamir challenge from the hash
    return fnv(f"{G}|{y}|{t}|{msg}") % Q

def fs_weak(y, t, msg):                   # a flawed challenge: hashes t only, ignores msg
    return fnv(f"{t}") % Q

def accepts(y, t, s, msg, ch):            # check a non-interactive proof (t, s) for msg
    return verify(y, t, ch(y, t, msg), s)

def yn(b): return "yes" if b else "no"

# ---- the example: a password becomes x; the bank keeps only y ----
pw = "blue-kettle-17"
x = 1 + fnv(pw) % (Q - 1)
y = power(G, x, P)
print(f"group: p = {P}, q = {Q}, g = {G}; powers of g: {[power(G, k, P) for k in range(Q)]}")
print(f"password {pw!r} -> secret x = {x}; bank stores y = g^x mod p = {y}")
r, c = 5, 3
t, s = power(G, r, P), (r + c * x) % Q
print(f"one round: r = {r}, t = g^r = {t}; challenge c = {c}; s = r + c*x = {r + c * x} -> mod q {s}")
print(f"check: g^s = {power(G, s, P)}, t * y^c = {t} * {power(y, c, P)} mod p = "
      f"{t * power(y, c, P) % P} -> accept: {yn(verify(y, t, c, s))}")
ok = sum(verify(y, power(G, a, P), b, (a + b * x) % Q) for a in range(Q) for b in range(Q))
print(f"completeness: {ok} of {Q * Q} (r, c) pairs accepted")
# ---- soundness: two answers to one t give x away ----
c2 = 8
s2 = (r + c2 * x) % Q
ds, inv = (s - s2) % Q, power((c - c2) % Q, Q - 2, Q)   # inverse by Fermat
xx = ds * inv % Q
print(f"extraction: same t, c = {c} and {c2} give s = {s} and {s2}; x = ({s} - {s2}) / "
      f"({c} - {c2}) = {ds} * {inv} mod {Q} = {xx}")
wins = sum(verify(y, fake_t(y, g_, s_), c_, s_)
           for g_ in range(Q) for s_ in range(Q) for c_ in range(Q))
print(f"cheater without x, exact: {wins} of {Q ** 3} (guess, s, c) cases pass "
      f"= {wins / Q ** 3:.4f}; 1/q = {1 / Q:.4f}")
rng, n, hits = SplitMix64(2026), 100000, 0
for _ in range(n):
    g_, s_, c_ = rng.next() % Q, rng.next() % Q, rng.next() % Q
    hits += verify(y, fake_t(y, g_, s_), c_, s_)
rate, se = hits / n, sqrt((1 / Q) * (1 - 1 / Q) / n)
print(f"cheater, simulated over {n} rounds (seed 2026): {rate:.4f}, standard error {se:.4f}")
rounds = 1
while Q ** rounds < 10 ** 6:
    rounds += 1
print(f"rounds for under 1 in a million: {rounds} ({Q}^{rounds} = {Q ** rounds})")
print("real sizes: q of 256 bits, p of 3072 bits; cheater 2^-256 per round; "
      "finding x from y about 2^128 operations")
# ---- zero knowledge: a simulator that never sees x ----
real = sorted((power(G, a, P), b, (a + b * x) % Q) for a in range(Q) for b in range(Q))
sim = sorted((fake_t(y, b, s_), b, s_) for s_ in range(Q) for b in range(Q))
print(f"simulator: {len(real)} real transcripts, {len(sim)} simulated; same list: "
      f"{yn(real == sim)}; all distinct: {yn(len(set(real)) == len(real))}")
# ---- Fiat-Shamir: the hash plays the bank ----
msg, r3 = "login 2026-11-11 session 41", 9
t3 = power(G, r3, P)
c3 = fs(y, t3, msg)
s3 = (r3 + c3 * x) % Q
print(f"Fiat-Shamir: msg {msg!r}, r = {r3}, t = {t3}, c = h(g|y|t|msg) mod q = {c3}, "
      f"s = {s3}; verifies: {yn(verify(y, t3, fs(y, t3, msg), s3))}")
# ---- what breaks ----
tries, rng, forged, distinct = 0, SplitMix64(7), 0, set()
while forged < 1000 and tries < 10 ** 5:  # 1000 successful forgeries, by trial and error
    tries += 1
    g_, s_ = rng.next() % Q, rng.next() % Q
    t_ = fake_t(y, g_, s_)
    if fs(y, t_, msg) == g_ and verify(y, t_, fs(y, t_, msg), s_):
        forged += 1
        distinct.add((t_, s_))
print(f"break 1, toy q: forger without x grinds the hash: {forged} valid proofs ({len(distinct)} distinct), "
      f"{tries / max(forged, 1):.2f} tries each; q = {Q}")
msg2 = "login 2026-11-12 session 42"
s4 = (r3 + fs_weak(y, t3, msg) * x) % Q    # a proof for msg under the flawed hash
replay = accepts(y, t3, s4, msg2, fs_weak)  # the same proof, checked for msg2
print(f"break 2, hash of t only: copied proof replayed on {msg2!r} accepted: "
      f"{yn(replay)}; with msg hashed: {yn(accepts(y, t3, s3, msg2, fs))}")
print(f"break 3, r reused for c = {c} and {c2}: x = {xx} (same as extraction)")
early = sum(verify(y, fake_t(y, b, 0), b, 0) for b in range(Q))
print(f"break 4, challenge known before t: cheater passes {early} of {Q}")
dl = next(k for k in range(Q) if power(G, k, P) == y)
print(f"break 5, toy group: brute force finds x = {dl} from y = {y} in {dl + 1} tries")
assert ok == Q * Q and verify(y, t, c, s)                        # completeness
assert xx == x and dl == x                                       # two roads to x
assert wins * Q == Q ** 3 and abs(rate - 1 / Q) < 4 * se         # exact, formula, simulated
assert real == sim and len(set(real)) == Q * Q                   # simulator matches
assert verify(y, t3, c3, s3) and not verify(y, t3, fs(y, t3, msg2), s3)
assert replay and early == Q and abs(tries / max(forged, 1) - Q) < 1.5 and len(distinct) <= Q   # breaks 1, 2, 4
print("ALL CHECKS PASS")
