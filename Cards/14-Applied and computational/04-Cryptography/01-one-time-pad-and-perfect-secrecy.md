# The one-time pad: perfect secrecy, and the price that makes it impractical

[Syllabus](../../../SYLLABUS.md) → [Applied and computational](../README.md) → [Cryptography](../README.md#s04) → The one-time pad

---

## General Overview

A laptop sends one order to a bank: `TRANSFER 750 TO BOB.` That is 20 characters, so 20 bytes (one byte is 8 bits, a number from 0 to 255). Anyone on the café Wi-Fi can copy every byte that leaves the laptop.

Last week, in the branch, the customer and the bank each got a copy of the same 20 random bytes on a USB stick. These bytes are the **pad**, also called the key. Before sending, the laptop combines each character with one pad byte, using a bit-flipping rule called XOR, explained below. What travels is 20 bytes that look like noise: `77 0F CF BC 1A …`. The bank applies the same pad again, and the order comes back.

The eavesdropper holds those 20 bytes and learns **nothing** about the order except its length. For a different pad, the very same bytes spell `TRANSFER 950 TO EVE.`, and for another they spell any other 20 characters at all. Each pad is exactly as likely as every other, so the bytes favour no message. Trying all the keys does not help either. It would take 2^160 tries, about 1.4615 × 10^48, and the result would be a list of every possible message.

The catch is the price. The pad must be truly random, as long as the message, delivered secretly in advance, and **never used twice**. Use it twice and the secrecy falls apart in one line of arithmetic.

**The one-time pad adds a fresh, uniformly random key as long as the message, bit by bit mod 2; because every key is equally likely and each key turns the message into a different ciphertext, every ciphertext is equally likely whatever was sent, so seeing it changes nobody's odds about the message — and no cipher can promise that with fewer possible keys than possible messages.**

**What kind of fact this is:** a theorem, proved on this card in Why it works: the pad's perfect secrecy, and the bound that perfect secrecy needs at least as many keys as messages. Kerckhoffs's principle, also on this card, is a design rule, not a theorem.

### The picture: one order, one pad

```mermaid
flowchart LR
    A["Laptop<br/>m = TRANSFER 750 TO BOB."] -->|"c = m ⊕ k"| B["Network<br/>c = 77 0F CF BC 1A …"]
    B -->|"m = c ⊕ k"| C["Bank<br/>TRANSFER 750 TO BOB."]
    B -.->|"copies c"| E["Eavesdropper<br/>sees c only"]
    K["Pad k: 20 random bytes,<br/>handed over in person"] -.-> A
    K -.-> C
```

Schematic. The solid arrows carry the order. The dotted arrows show who holds what: both ends hold the pad, and the eavesdropper holds only c.

---

## The formula

Notation first, in words. The order is the **plaintext** m (the message as written). The pad is the **key** k. What travels is the **ciphertext** c. The sign ⊕, read "XOR" (exclusive or), compares two bits: the answer is 1 when they differ and 0 when they match. On whole bytes it works bit by bit. So ⊕ is addition mod 2 in each bit, the clock arithmetic of [Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md) with a clock of size 2.

$$c = m \oplus k, \qquad m = c \oplus k$$

**Read it aloud:** to lock, flip the bits of the message wherever the pad has a 1; to unlock, flip the same bits back.

Secrecy is a statement about chances. Write M, K and C in capitals for the message, key and ciphertext *as chosen by chance*, and lower-case m, k, c for particular values. The pad gives **perfect secrecy**:

$$P(M = m \mid C = c) = P(M = m) \quad \text{for every message } m \text{ and every ciphertext } c$$

**Read it aloud:** the eavesdropper's odds for each message after seeing the ciphertext equal the odds they had before.

In the language of [Entropy](../03-Information%20Theory/01-entropy.md), this says the ciphertext carries zero bits about the message: I(M; C) = 0, and H(M | C) = H(M) ([Conditional entropy and mutual information](../03-Information%20Theory/02-conditional-entropy-and-mutual-information.md)).

The price, proved below. If $n_k$ is the number of possible keys and $n_m$ the number of possible messages, perfect secrecy forces

$$n_k \ge n_m$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $m$, $m_2$ | the plaintext, the message as written; $m_2$ a second order | `TRANSFER 750 TO BOB.`, 20 bytes | a longer message needs a longer pad |
| $k$ | the key: the pad, random bytes shared in advance (in the phrase "k-bit security", k instead counts bits) | `23 5D 8E F2 …`, 20 bytes | must keep pace with m, byte for byte |
| $c$, $c_2$ | the ciphertext, what travels; $c_2$ the second order's | `77 0F CF BC …`, 20 bytes | — |
| $\oplus$ | XOR: 1 where two bits differ, 0 where they match; addition mod 2 | `0x37 ⊕ 0x42 = 0x75` | — |
| $M, K, C$ | message, key and ciphertext as chosen by chance | M is 750 or 950 with chance 0.5 each | — |
| $P(M = m)$ | the eavesdropper's odds before seeing c (the prior) | 0.5 for the 750 order | — |
| $P(M = m \mid C = c)$ | the odds after seeing c (the posterior) | still 0.5 | equal to the prior: that is perfect secrecy |
| $n_k$ | how many keys are possible | 256^20 = 2^160 | more keys, more messages it can hide |
| $n_m$ | how many messages are possible | 256^20 strings of 20 bytes | needs at least as many keys |
| $H(M)$, $H(K)$, $H(C)$ | entropy of the message, key or ciphertext: bits of uncertainty about it | H(M) = 1.75 bits in the toy below | — |
| $H(M \mid C)$, $H(C \mid M)$ | uncertainty left about one after seeing the other | H(M \| C) = 1.75 bits with a proper pad | falls when the pad leaks |
| $I(M; C)$ | bits the ciphertext gives away: H(M) − H(M \| C) | 0 with a proper pad | rises as the pad is weakened |

### When it holds

- **The key is uniformly random.** Every pad equally likely. Let some keys be likelier than others and the toy below leaks 0.1226 of its 1.75 bits.
- **The key is as long as the message.** A short key repeated to fill 20 bytes leaves one readable decryption when it is 1 byte long; a brute-force search finds the order in 256 tries.
- **The key is used once.** Two orders under one pad leak their XOR: 15 of 20 bytes come out 00, and one known order hands over the other.
- **The key stays secret and reaches both ends safely.** The mathematics says nothing about the USB stick. Lose it and the scheme is open.
- **Secrecy only.** The pad hides the message; it does not stop changes. An attacker who flips the right bits of c turns 750 into 950, and the bank cannot tell.

---

## Why it works

### Step 0: every key equally likely, and exactly one key per pair

Fix a message m and a ciphertext c. Exactly one key links them: k = m ⊕ c. Each key is equally likely. So the chance of seeing c is the chance of that one key, whatever the message was. The ciphertext is a uniform draw that does not depend on the message. That is the whole proof; the steps below write it out.

### Step 1: unlocking works because flipping twice changes nothing

Bit by bit, ⊕ is addition mod 2. So (m ⊕ k) ⊕ k = m ⊕ (k ⊕ k), and k ⊕ k = 0 because 2 ≡ 0 (mod 2). Unlocking with the same pad gives the message back.

Character 10 of the order is `7`, byte 0x37 (written in base 16, "hex"). In bits:

```
m   0 0 1 1 0 1 1 1    '7' = 0x37
k   0 1 0 0 0 0 1 0          0x42
c   0 1 1 1 0 1 0 1          0x75   (1 wherever m and k differ)
```

XOR the key back on and 0x75 returns to 0x37. The code checks that this bitwise sum mod 2 equals the byte XOR.

### Step 2: the ciphertext is uniform, whatever was sent

Suppose the key K is chosen uniformly from all $n_k$ = 256^20 pads, independently of the message. Given the message m, the ciphertext equals c exactly when the key is m ⊕ c. So

$$P(C = c \mid M = m) = P(K = m \oplus c) = \frac{1}{256^{20}}$$

The right-hand side does not mention m. Whether the laptop sent the 750 order or the 950 order, every 20-byte ciphertext has the same chance, 1 in 2^160.

### Step 3: Bayes' rule turns that into perfect secrecy

[Bayes' rule](../../09-Probability%20and%20statistics/01-Chance%20and%20Events/06-bayes-rule.md) turns the chance of the evidence into the chance of the cause:

$$P(M = m \mid C = c) = \frac{P(C = c \mid M = m)\, P(M = m)}{P(C = c)}$$

The top has 1/256^20 by Step 2. The bottom averages that same 1/256^20 over all messages, so it is also 1/256^20. They cancel, and the posterior equals the prior. In the words of [Independence](../../09-Probability%20and%20statistics/01-Chance%20and%20Events/07-independence.md), M and C are independent: knowing c says nothing about m.

This holds for **any** prior. If the eavesdropper already thought the 750 order far likelier than the 950 one, they think exactly that after seeing c. The pad adds no information; it does not remove what the eavesdropper knew beforehand.

The code checks this exactly on a toy: four short bank replies, coded 00 to 11, with chances 1/2, 1/4, 1/8, 1/8 (APPROVE, DECLINE, CALL ME, FREEZE), and four 2-bit keys. It works in 32nds and confirms that the posterior equals the prior in all 16 (message, ciphertext) cells. It also measures the leak, I(M; C), two different ways and gets 0.0000 bits.

### Step 4: the price, at least as many keys as messages

Shannon proved the converse in 1949: no cipher, however clever, is perfectly secret with fewer keys than messages.

The argument is short. Fix one ciphertext c that can occur. Each key unlocks c to exactly one message, so at most $n_k$ different messages can lie behind c. If $n_k < n_m$, some message m with a chance above zero cannot lie behind c. For that m, the posterior P(M = m | C = c) is 0 while the prior is not. The eavesdropper has learned something: "not m". Perfect secrecy fails.

The toy shows it. Give it 3 keys for 4 messages, each key with chance 1/3. Now 4 of the 16 cells are impossible, and the ciphertext leaks 0.3828 bits. With 1 key, the cipher is a fixed code book: 12 cells impossible, and the full 1.75 bits leak.

Shannon also proved the entropy form, H(K) ≥ H(M): the key must carry at least as much uncertainty as the message. This card states it and cites it; the counting argument above is the version proved here.

The bars show how many of the toy's 1.75 bits the ciphertext gives away under each of four key designs, 20 hashes to the bit:

```
uniform 4 keys                                                 0.0000
biased key 0.4/0.3/0.2/0.1  ##                                 0.1226
3 keys only                 ########                           0.3828
1 key only                  ###################################  1.7500
```

Only the uniform key, with as many keys as messages, gives zero.

### Step 5: why the pad must never be used twice

Send a second order, `TRANSFER 200 TO ANN.`, under the same pad. Its ciphertext is c2 = m2 ⊕ k. The eavesdropper XORs the two ciphertexts, and the key cancels:

$$c \oplus c_2 = (m \oplus k) \oplus (m_2 \oplus k) = m \oplus m_2$$

No key is left in that line. What remains is the XOR of two English orders, and that is far from random. Wherever the orders agree, the byte is 00. Here 15 of the 20 bytes are 00, which already shows the orders share their shape and differ only in the amount and the name. If the eavesdropper knows or guesses one order, XORing it on recovers the other in full: `TRANSFER 200 TO ANN.`

This is what happened to the Soviet pads in the 1940s: some pad pages were printed twice, and analysts on the American Venona project read parts of many messages. "One-time" is the whole security.

### Step 6: Kerckhoffs's principle, the secret is the key

In 1883 Auguste Kerckhoffs set out rules for military ciphers. The one that lasted: **a cipher must stay secure even when the enemy knows everything about it except the key.**

The pad passes. XOR is printed on this card, and the security proof above never assumed the method was hidden. Every bit of secrecy sits in the 160 bits of the pad. The opposite habit, keeping the method secret, fails the day the method leaks, and methods leak: through stolen devices, former staff, or reverse engineering. A key can be changed overnight; a method cannot.

Modern ciphers follow the same rule and add a measure of strength. A cipher has **"k-bit security"** if breaking it takes about 2^k operations, assuming a stated mathematical problem stays hard (here k counts bits; it is not the pad). AES-128 aims at 128-bit security: about 2^128 operations. The pad is a different kind of claim. Its security does not rest on any problem being hard; no amount of computing helps, because every answer fits.

### Step 7: what the attacker is allowed to see

Cryptographers name four attack models, from weakest attacker to strongest:

- **Ciphertext only:** the eavesdropper sees c. The pad is perfect here.
- **Known plaintext:** they also know some m and its c. Against the pad this reveals that stretch of the key, which is harmless only if the key is never used again.
- **Chosen plaintext:** they can make the laptop encrypt messages of their choice. Same answer: harmless only with a fresh pad each time.
- **Chosen ciphertext:** they can make the bank decrypt ciphertexts of their choice. The pad offers nothing here, because flipping a bit of c flips the same bit of the message the bank reads.

---

## Worked numbers, by hand

The 750 order, its pad, and an eavesdropper deciding between the 750 order and the 950 order, each with chance 0.5.

| Step | Arithmetic | Value |
| --- | --- | --- |
| order, character 10 | `7` in ASCII, the standard text code | 0x37 = 00110111 |
| pad byte 10 | from the shared pad | 0x42 = 01000010 |
| ciphertext byte 10 | 00110111 ⊕ 01000010 | 0x75 = 01110101 |
| unlock at the bank | 0x75 ⊕ 0x42 | 0x37 = `7` |
| key that would make it a `9` | 0x75 ⊕ 0x39 | 0x4C |
| pads that turn c into the 950 order | one key: c ⊕ `TRANSFER 950 TO EVE.` | exactly 1 of 2^160 |
| chance of c, given the 750 order | 1 / 256^20 | 1 in 1.4615 × 10^48 |
| chance of c, given the 950 order | 1 / 256^20 | 1 in 1.4615 × 10^48 |
| odds after seeing c | 0.5 × (1/256^20) ÷ (1/256^20) | **0.5, unchanged** |

**The eavesdropper's odds for the 750 order are 0.5 before and 0.5 after**: the 20 bytes moved them by nothing. The simulation in the code agrees. Over 100,000 synthetic orders, a guesser that reads byte 10 of c, in exactly the bits where `7` and `9` differ, wins 0.5001 of the time, within one standard error (0.0016) of a coin toss. The same guesser against a weak pad, whose bits are 1 only a quarter of the time, wins 0.7035, against an exact 0.7031. So the test can tell a weak pad from a proper one.

The key that turns c into `TRANSFER 950 TO EVE.` differs from the real pad only where the orders differ: byte 10 (0x42 becomes 0x4C) and bytes 17 to 19 (A9 43 C3 become AE 5A C4). Nothing in c points to one of them over the other.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| The same pad for two orders | 15 of 20 bytes of c ⊕ c2 are 00; knowing one order reveals `TRANSFER 200 TO ANN.`; guesser wins 1.0000 | The key cancels in c ⊕ c2, leaving m ⊕ m2 |
| A 1-byte key repeated 20 times | 256 tries, 1 readable decryption: the order | Far fewer keys than messages, so brute force finds it |
| A biased key in the toy (chances 0.4, 0.3, 0.2, 0.1) | 0.1226 bits leak of 1.75 | Some ciphertexts become likelier for some messages |
| 3 keys for 4 messages in the toy | 0.3828 bits leak; 4 of 16 cells impossible | Fewer keys than messages: Shannon's bound |
| Trusting the pad to stop tampering | flip c byte 10 by 0x0E: bank reads `TRANSFER 950 TO BOB.` | Secrecy is not integrity; flips in c become flips in m |

The repeated-key row grows as the key grows. Repeat a 1-, 2-, 3-, 4- or 5-byte key and the number of decryptions made only of capital letters, digits, spaces and full stops is 1, 2, 18, 720 and 6,300. At 20 bytes, every one of the 38^20 ≈ 3.9416 × 10^31 such strings fits. The key length is what turns "one answer" into "every answer".

---

## Code, from first principles, and it actually runs

The script encrypts the order with a 20-byte pad and unlocks it. It then reaches perfect secrecy by **three independent roads**. The first is exact counting on the four-message toy, in whole 32nds, checking the posterior against the prior in all 16 cells. The second is exhaustive enumeration over every (message, key) pair, computing the leak two different ways (directly, and as H(C) − H(C | M)) under four key designs. The third is a seeded simulation over 100,000 orders. A guesser reads the bits of c where the 750 and 950 orders differ. Against a fresh pad it must score near 0.5; against a weak pad it must score near its exact 0.7031, which proves the guesser can see a leak when there is one. The reused-pad line beside it shows the Step 5 attack. It is an XOR identity, true for every key, so it is a demonstration, not evidence. Then it runs each failure in the "What breaks" table, and counts short-key decryptions both by a formula over key positions and by brute force over all 65,536 two-byte keys. The pad bytes come from SplitMix64, a small seeded generator written out in both languages, so the two programs print the same bytes. That makes this pad **insecure**: a real pad must be unpredictable, from a hardware noise source, never from a seeded formula.

### Python

```python
# One-time pad -- the check behind the card.  Standard library only.
# The pad bytes come from SplitMix64 so Python and Rust print the same thing.
# That makes this pad INSECURE: a real pad needs bytes nobody can predict.
from math import log2, sqrt

M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def byte(self): return self.next() & 0xFF

def xor(a, b): return bytes(x ^ y for x, y in zip(a, b))
def hx(b): return " ".join(f"{x:02X}" for x in b)

# ---- the example: one 20-character order from a laptop to a bank ----
rng = SplitMix64(2026)
m = b"TRANSFER 750 TO BOB."
k = bytes(rng.byte() for _ in range(20))
c = xor(m, k)
back = xor(c, k)
print("pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad")
print("m  ", m.decode())
print("m  ", hx(m))
print("k  ", hx(k))
print("c  ", hx(c))
assert back == m
print("c xor k:", back.decode())
# char 10 (index 9), bit by bit: XOR is addition mod 2 in each bit
bits = lambda x: f"{x:08b}"
sum_mod2 = int("".join(str((int(a) + int(b)) % 2) for a, b in zip(bits(m[9]), bits(k[9]))), 2)
print(f"char 10: m {bits(m[9])} k {bits(k[9])} c {bits(c[9])}")
assert sum_mod2 == c[9]

# ---- every other message fits the same ciphertext under exactly one key ----
alt = b"TRANSFER 950 TO EVE."
k_alt = xor(c, alt)
print("key that turns c into", alt.decode() + ":", hx(k_alt))
assert xor(alt, k_alt) == c and k_alt != k
e = len(str(256**20)) - 1
print(f"keys of 20 bytes: 256^20 = 2^160 = {256**20 / 10**e:.4f} x 10^{e}")
assert 256**20 == 2**160

# ---- exhaustive toy: 4 messages (2 bits), prior 1/2, 1/4, 1/8, 1/8 ----
prior8 = [4, 2, 1, 1]                      # chances in eighths
def leak(pk):                              # pk[key] = chance of that key
    pm = [p / 8 for p in prior8]
    joint = [[pm[mm] * pk[mm ^ cc] for cc in range(4)] for mm in range(4)]
    pc = [sum(joint[mm][cc] for mm in range(4)) for cc in range(4)]
    i1 = sum(j * log2(j / (pm[mm] * pc[cc])) for mm in range(4)
             for cc in range(4) if (j := joint[mm][cc]) > 0)
    hc = -sum(p * log2(p) for p in pc if p > 0)
    hc_m = -sum(pm[mm] * q * log2(q) for mm in range(4) for q in pk if q > 0)
    zeros = sum(1 for mm in range(4) for cc in range(4) if pc[cc] > 0 and joint[mm][cc] == 0)
    return i1, hc - hc_m, zeros
hm = -sum(p / 8 * log2(p / 8) for p in prior8)
print(f"toy: H(M) = {hm:.4f} bits")
# uniform key, exact in 32nds: posterior P(m|c) must equal prior P(m) for all 16 pairs
key4 = [1, 1, 1, 1]                        # each key has chance 1/4
joint32 = [[prior8[mm] * key4[mm ^ cc] for cc in range(4)] for mm in range(4)]
pc32 = [sum(joint32[mm][cc] for mm in range(4)) for cc in range(4)]
same = all(joint32[mm][cc] * 8 == prior8[mm] * pc32[cc] for mm in range(4) for cc in range(4))
print("uniform key: posterior equals prior in all 16 cells:", same)
assert same and pc32 == [8, 8, 8, 8]
rows = [("uniform key", [0.25] * 4), ("biased key", [0.4, 0.3, 0.2, 0.1]),
        ("3 keys only", [1 / 3, 1 / 3, 1 / 3, 0.0]), ("1 key only", [1.0, 0, 0, 0])]
res = {}
for name, pk in rows:
    i1, i2, z = leak(pk)
    res[name] = (i1, z)
    print(f"{name:11}: I(M;C) = {i1:.4f} bits, H(M|C) = {hm - i1:.4f}, impossible cells = {z}")
    assert abs(i1 - i2) < 1e-12           # two formulas for the leak agree
assert abs(res["uniform key"][0]) < 1e-12 and res["uniform key"][1] == 0
assert res["biased key"][0] > 0.01 and res["3 keys only"][1] > 0
assert abs(res["1 key only"][0] - hm) < 1e-12   # no secret key: everything leaks

# ---- simulation: is it 750 or 950?  The guesser sees only c ----
N = 100_000
sim = SplitMix64(7)
win_fresh = win_weak = win_reuse = 0
old_m = b"TRANSFER 200 TO ANN."
rule = lambda c9: m if (c9 ^ m[9]) & 0x0E == 0 else alt   # reads bits 1-3, where '7' and '9' differ
for _ in range(N):
    sent = m if sim.byte() & 1 else alt
    key = bytes(sim.byte() for _ in range(20))
    ct = xor(sent, key)
    win_fresh += rule(ct[9]) == sent
    win_weak += rule(sent[9] ^ (sim.byte() & sim.byte())) == sent   # weak pad byte: each bit 1 with chance 1/4
    old_c = xor(old_m, key)                          # same key used before, old order known
    win_reuse += xor(xor(ct, old_c), old_m) == sent  # an XOR identity: shows the attack, tests only XOR
p, se = win_fresh / N, sqrt(0.25 / N)
weak = 0.5 * 0.75 ** 3 + 0.5 * (1 - 0.25 ** 3)       # exact: right if bits 1-3 are 000 (750 sent) or not 111 (950)
print(f"guessing 750 or 950 over {N} trials: fresh pad {p:.4f} (se {se:.4f}), reused pad {win_reuse / N:.4f}")
print(f"same guesser, weak pad (each bit 1 with chance 1/4): {win_weak / N:.4f}, exact {weak:.4f}")
assert abs(p - 0.5) < 4 * se                         # fails for any pad that is not uniform in those bits
assert abs(win_weak / N - weak) < 4 * se             # fails if the guesser is blind to the message
assert win_reuse == N

# ---- what breaks: the same pad used twice ----
c2 = xor(old_m, k)
leak2 = xor(c, c2)
print("c xor c2:", hx(leak2))
print("bytes equal to 00:", leak2.count(0), "of 20")
assert leak2 == xor(m, old_m)
print("c2 xor c xor m:", xor(leak2, m).decode())
assert xor(leak2, m) == old_m

# ---- what breaks: a short key repeated to fill 20 bytes ----
ok = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .")      # 38 readable characters
counts = []
for L in range(1, 6):
    ct = bytes(x ^ k[i % L] for i, x in enumerate(m))
    n_read = 1                                           # key positions are independent
    for j in range(L):
        n_read *= sum(all((x ^ b) in ok for x in ct[j::L]) for b in range(256))
    counts.append(n_read)
print("repeated key of 1 to 5 bytes, readable decryptions:", ", ".join(map(str, counts)))
ct2 = bytes(x ^ k[i % 2] for i, x in enumerate(m))     # brute force all 65,536 two-byte keys
brute2 = sum(all((x ^ (a, b)[i % 2]) in ok for i, x in enumerate(ct2)) for a in range(256) for b in range(256))
assert counts[0] == 1 and brute2 == counts[1] and all(x < y for x, y in zip(counts, counts[1:]))
print(f"pad of 20 bytes: every string of those 38 characters fits, 38^20 = {38**20 / 10**31:.4f} x 10^31")
# ---- what breaks: secrecy is not integrity ----
tampered = bytearray(c)
tampered[9] ^= ord("7") ^ ord("9")
print("flip c[9] by", f"{ord('7') ^ ord('9'):02X}", "-> bank reads:", xor(tampered, k).decode())
assert xor(tampered, k) == b"TRANSFER 950 TO BOB."

# ---- the price: pad bytes the bank must hold in advance ----
per_day = 10_000_000 * 20
print(f"pad for 10,000,000 orders a day: {per_day:,} bytes a day, {per_day * 365:,} a year")
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad
m   TRANSFER 750 TO BOB.
m   54 52 41 4E 53 46 45 52 20 37 35 30 20 54 4F 20 42 4F 42 2E
k   23 5D 8E F2 49 03 AE 2D F4 42 6D E0 18 65 39 49 A9 43 C3 19
c   77 0F CF BC 1A 45 EB 7F D4 75 58 D0 38 31 76 69 EB 0C 81 37
c xor k: TRANSFER 750 TO BOB.
char 10: m 00110111 k 01000010 c 01110101
key that turns c into TRANSFER 950 TO EVE.: 23 5D 8E F2 49 03 AE 2D F4 4C 6D E0 18 65 39 49 AE 5A C4 19
keys of 20 bytes: 256^20 = 2^160 = 1.4615 x 10^48
toy: H(M) = 1.7500 bits
uniform key: posterior equals prior in all 16 cells: True
uniform key: I(M;C) = 0.0000 bits, H(M|C) = 1.7500, impossible cells = 0
biased key : I(M;C) = 0.1226 bits, H(M|C) = 1.6274, impossible cells = 0
3 keys only: I(M;C) = 0.3828 bits, H(M|C) = 1.3672, impossible cells = 4
1 key only : I(M;C) = 1.7500 bits, H(M|C) = 0.0000, impossible cells = 12
guessing 750 or 950 over 100000 trials: fresh pad 0.5001 (se 0.0016), reused pad 1.0000
same guesser, weak pad (each bit 1 with chance 1/4): 0.7035, exact 0.7031
c xor c2: 00 00 00 00 00 00 00 00 00 05 05 00 00 00 00 00 03 01 0C 00
bytes equal to 00: 15 of 20
c2 xor c xor m: TRANSFER 200 TO ANN.
repeated key of 1 to 5 bytes, readable decryptions: 1, 2, 18, 720, 6300
pad of 20 bytes: every string of those 38 characters fits, 38^20 = 3.9416 x 10^31
flip c[9] by 0E -> bank reads: TRANSFER 950 TO BOB.
pad for 10,000,000 orders a day: 200,000,000 bytes a day, 73,000,000,000 a year
ALL CHECKS PASS
```

### Rust

```rust
// One-time pad -- the check behind the card.  std only, no crates.
// The pad bytes come from SplitMix64 so Python and Rust print the same thing.
// That makes this pad INSECURE: a real pad needs bytes nobody can predict.
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn byte(&mut self) -> u8 { (self.next() & 0xFF) as u8 }
}

fn xor(a: &[u8], b: &[u8]) -> Vec<u8> { a.iter().zip(b).map(|(x, y)| x ^ y).collect() }
fn hx(b: &[u8]) -> String { b.iter().map(|x| format!("{:02X}", x)).collect::<Vec<_>>().join(" ") }
fn txt(b: &[u8]) -> String { String::from_utf8(b.to_vec()).unwrap() }

// exhaustive toy: 4 messages (2 bits), prior in eighths; pk[key] = chance of that key
fn leak(prior8: &[u32; 4], pk: &[f64; 4]) -> (f64, f64, usize) {
    let pm: Vec<f64> = prior8.iter().map(|&p| p as f64 / 8.0).collect();
    let joint: Vec<Vec<f64>> = (0..4).map(|mm| (0..4).map(|cc| pm[mm] * pk[mm ^ cc]).collect()).collect();
    let pc: Vec<f64> = (0..4).map(|cc| (0..4).fold(0.0, |s, mm| s + joint[mm][cc])).collect();
    let (mut i1, mut hc, mut hc_m, mut zeros) = (0.0, 0.0, 0.0, 0);
    for mm in 0..4 { for cc in 0..4 {
        let j = joint[mm][cc];
        if j > 0.0 { i1 += j * (j / (pm[mm] * pc[cc])).log2(); }
    } }
    for &p in &pc { if p > 0.0 { hc += p * p.log2(); } }
    for mm in 0..4 { for &q in pk { if q > 0.0 { hc_m += pm[mm] * q * q.log2(); } } }
    for mm in 0..4 { for cc in 0..4 { if pc[cc] > 0.0 && joint[mm][cc] == 0.0 { zeros += 1; } } }
    (i1, -hc - -hc_m, zeros)
}

fn main() {
    // ---- the example: one 20-character order from a laptop to a bank ----
    let mut rng = SplitMix64 { s: 2026 };
    let m = b"TRANSFER 750 TO BOB.".to_vec();
    let k: Vec<u8> = (0..20).map(|_| rng.byte()).collect();
    let c = xor(&m, &k);
    let back = xor(&c, &k);
    println!("pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad");
    println!("m   {}", txt(&m));
    println!("m   {}", hx(&m));
    println!("k   {}", hx(&k));
    println!("c   {}", hx(&c));
    assert!(back == m);
    println!("c xor k: {}", txt(&back));
    // char 10 (index 9), bit by bit: XOR is addition mod 2 in each bit
    let mut sum_mod2 = 0u8;
    for b in (0..8).rev() { sum_mod2 = sum_mod2 * 2 + (((m[9] >> b) & 1) + ((k[9] >> b) & 1)) % 2; }
    println!("char 10: m {:08b} k {:08b} c {:08b}", m[9], k[9], c[9]);
    assert!(sum_mod2 == c[9]);

    // ---- every other message fits the same ciphertext under exactly one key ----
    let alt = b"TRANSFER 950 TO EVE.".to_vec();
    let k_alt = xor(&c, &alt);
    println!("key that turns c into {}: {}", txt(&alt), hx(&k_alt));
    assert!(xor(&alt, &k_alt) == c && k_alt != k);
    let keys = 256f64.powi(20);
    let e = keys.log10().floor() as i32;
    println!("keys of 20 bytes: 256^20 = 2^160 = {:.4} x 10^{}", keys / 10f64.powi(e), e);
    assert!(keys == 2f64.powi(160));

    // ---- exhaustive toy: 4 messages (2 bits), prior 1/2, 1/4, 1/8, 1/8 ----
    let prior8 = [4u32, 2, 1, 1];
    let hm = -prior8.iter().fold(0.0, |s, &p| s + p as f64 / 8.0 * (p as f64 / 8.0).log2());
    println!("toy: H(M) = {:.4} bits", hm);
    // uniform key, exact in 32nds: posterior P(m|c) must equal prior P(m) for all 16 pairs
    let key4 = [1u32, 1, 1, 1]; // each key has chance 1/4
    let joint32: Vec<Vec<u32>> = (0..4).map(|mm| (0..4).map(|cc| prior8[mm] * key4[mm ^ cc]).collect()).collect();
    let pc32: Vec<u32> = (0..4).map(|cc| (0..4).map(|mm| joint32[mm][cc]).sum()).collect();
    let same = (0..4).all(|mm| (0..4).all(|cc| joint32[mm][cc] * 8 == prior8[mm] * pc32[cc]));
    println!("uniform key: posterior equals prior in all 16 cells: {}", if same { "True" } else { "False" });
    assert!(same && pc32 == vec![8, 8, 8, 8]);
    let rows: [(&str, [f64; 4]); 4] = [("uniform key", [0.25; 4]), ("biased key", [0.4, 0.3, 0.2, 0.1]),
        ("3 keys only", [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 0.0]), ("1 key only", [1.0, 0.0, 0.0, 0.0])];
    let mut res = Vec::new();
    for (name, pk) in rows.iter() {
        let (i1, i2, z) = leak(&prior8, pk);
        res.push((i1, z));
        println!("{:11}: I(M;C) = {:.4} bits, H(M|C) = {:.4}, impossible cells = {}", name, i1, hm - i1, z);
        assert!((i1 - i2).abs() < 1e-12);
    }
    assert!(res[0].0.abs() < 1e-12 && res[0].1 == 0);
    assert!(res[1].0 > 0.01 && res[2].1 > 0);
    assert!((res[3].0 - hm).abs() < 1e-12);

    // ---- simulation: is it 750 or 950?  The guesser sees only c ----
    let n = 100_000;
    let mut sim = SplitMix64 { s: 7 };
    let (mut win_fresh, mut win_weak, mut win_reuse) = (0u32, 0u32, 0u32);
    let old_m = b"TRANSFER 200 TO ANN.".to_vec();
    let rule = |c9: u8| if (c9 ^ m[9]) & 0x0E == 0 { m.clone() } else { alt.clone() }; // reads bits 1-3, where '7' and '9' differ
    for _ in 0..n {
        let sent = if sim.byte() & 1 == 1 { &m } else { &alt };
        let key: Vec<u8> = (0..20).map(|_| sim.byte()).collect();
        let ct = xor(sent, &key);
        if rule(ct[9]) == *sent { win_fresh += 1; }
        if rule(sent[9] ^ (sim.byte() & sim.byte())) == *sent { win_weak += 1; } // weak pad byte: each bit 1 with chance 1/4
        let old_c = xor(&old_m, &key);
        if xor(&xor(&ct, &old_c), &old_m) == *sent { win_reuse += 1; } // an XOR identity: shows the attack, tests only XOR
    }
    let p = win_fresh as f64 / n as f64;
    let se = (0.25 / n as f64).sqrt();
    let weak = 0.5 * 0.75f64.powi(3) + 0.5 * (1.0 - 0.25f64.powi(3)); // exact: right if bits 1-3 are 000 (750 sent) or not 111 (950)
    println!("guessing 750 or 950 over {} trials: fresh pad {:.4} (se {:.4}), reused pad {:.4}", n, p, se, win_reuse as f64 / n as f64);
    println!("same guesser, weak pad (each bit 1 with chance 1/4): {:.4}, exact {:.4}", win_weak as f64 / n as f64, weak);
    assert!((p - 0.5).abs() < 4.0 * se); // fails for any pad that is not uniform in those bits
    assert!((win_weak as f64 / n as f64 - weak).abs() < 4.0 * se); // fails if the guesser is blind to the message
    assert!(win_reuse == n);

    // ---- what breaks: the same pad used twice ----
    let c2 = xor(&old_m, &k);
    let leak2 = xor(&c, &c2);
    println!("c xor c2: {}", hx(&leak2));
    println!("bytes equal to 00: {} of 20", leak2.iter().filter(|&&x| x == 0).count());
    assert!(leak2 == xor(&m, &old_m));
    println!("c2 xor c xor m: {}", txt(&xor(&leak2, &m)));
    assert!(xor(&leak2, &m) == old_m);

    // ---- what breaks: a short key repeated to fill 20 bytes ----
    let ok = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ."; // 38 readable characters
    let mut counts: Vec<u64> = Vec::new();
    for l in 1..6usize {
        let ct: Vec<u8> = m.iter().enumerate().map(|(i, x)| x ^ k[i % l]).collect();
        let mut n_read = 1u64; // key positions are independent
        for j in 0..l {
            let col: Vec<u8> = ct.iter().skip(j).step_by(l).cloned().collect();
            n_read *= (0..=255u8).filter(|&b| col.iter().all(|&x| ok.contains(&(x ^ b)))).count() as u64;
        }
        counts.push(n_read);
    }
    let shown: Vec<String> = counts.iter().map(|x| x.to_string()).collect();
    println!("repeated key of 1 to 5 bytes, readable decryptions: {}", shown.join(", "));
    let ct2: Vec<u8> = m.iter().enumerate().map(|(i, x)| x ^ k[i % 2]).collect(); // all 65,536 two-byte keys
    let mut brute2 = 0u64;
    for a in 0..=255u8 { for b in 0..=255u8 {
        if ct2.iter().enumerate().all(|(i, &x)| ok.contains(&(x ^ if i % 2 == 0 { a } else { b }))) { brute2 += 1; }
    } }
    assert!(counts[0] == 1 && brute2 == counts[1] && counts.windows(2).all(|w| w[0] < w[1]));
    println!("pad of 20 bytes: every string of those 38 characters fits, 38^20 = {:.4} x 10^31", 38f64.powi(20) / 1e31);

    // ---- what breaks: secrecy is not integrity ----
    let mut tampered = c.clone();
    tampered[9] ^= b'7' ^ b'9';
    println!("flip c[9] by {:02X} -> bank reads: {}", b'7' ^ b'9', txt(&xor(&tampered, &k)));
    assert!(xor(&tampered, &k) == b"TRANSFER 950 TO BOB.".to_vec());

    // ---- the price: pad bytes the bank must hold in advance ----
    let per_day: u64 = 10_000_000 * 20;
    println!("pad for 10,000,000 orders a day: {} bytes a day, {} a year", commas(per_day), commas(per_day * 365));
    println!("ALL CHECKS PASS");
}

fn commas(x: u64) -> String {
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad
m   TRANSFER 750 TO BOB.
m   54 52 41 4E 53 46 45 52 20 37 35 30 20 54 4F 20 42 4F 42 2E
k   23 5D 8E F2 49 03 AE 2D F4 42 6D E0 18 65 39 49 A9 43 C3 19
c   77 0F CF BC 1A 45 EB 7F D4 75 58 D0 38 31 76 69 EB 0C 81 37
c xor k: TRANSFER 750 TO BOB.
char 10: m 00110111 k 01000010 c 01110101
key that turns c into TRANSFER 950 TO EVE.: 23 5D 8E F2 49 03 AE 2D F4 4C 6D E0 18 65 39 49 AE 5A C4 19
keys of 20 bytes: 256^20 = 2^160 = 1.4615 x 10^48
toy: H(M) = 1.7500 bits
uniform key: posterior equals prior in all 16 cells: True
uniform key: I(M;C) = 0.0000 bits, H(M|C) = 1.7500, impossible cells = 0
biased key : I(M;C) = 0.1226 bits, H(M|C) = 1.6274, impossible cells = 0
3 keys only: I(M;C) = 0.3828 bits, H(M|C) = 1.3672, impossible cells = 4
1 key only : I(M;C) = 1.7500 bits, H(M|C) = 0.0000, impossible cells = 12
guessing 750 or 950 over 100000 trials: fresh pad 0.5001 (se 0.0016), reused pad 1.0000
same guesser, weak pad (each bit 1 with chance 1/4): 0.7035, exact 0.7031
c xor c2: 00 00 00 00 00 00 00 00 00 05 05 00 00 00 00 00 03 01 0C 00
bytes equal to 00: 15 of 20
c2 xor c xor m: TRANSFER 200 TO ANN.
repeated key of 1 to 5 bytes, readable decryptions: 1, 2, 18, 720, 6300
pad of 20 bytes: every string of those 38 characters fits, 38^20 = 3.9416 x 10^31
flip c[9] by 0E -> bank reads: TRANSFER 950 TO BOB.
pad for 10,000,000 orders a day: 200,000,000 bytes a day, 73,000,000,000 a year
ALL CHECKS PASS
```

> [!TIP]
> **Try changing**
> - Guess first: does a guesser that reads a different bit do better? In `rule`, change `& 0x0E` to `& 0x80`, so it reads bit 7. The fresh-pad score stays within a few standard errors of 0.5, because the ciphertext is uniform whichever order was sent. The weak-pad score also falls to about 0.5, and its assert stops the run: bit 7 is the same in `7` and `9`, so this guesser cannot see the message even through a weak pad.
> - Guess first: what does c ⊕ c2 look like if the second order repeats the first? Set `old_m` to `TRANSFER 750 TO BOB.`. Every byte comes out 00: even with no key recovered, the eavesdropper learns the same order went twice.
> - Guess first: does a uniform key leak in the toy? Change the biased row to `[0.25, 0.25, 0.25, 0.25]`. Its leak drops from 0.1226 to 0.0000 bits, the uniform row's value, and the next assert stops the run: it demands that the biased key leaks.
> - Guess first: does the pad's seed matter to the eavesdropper? Change `SplitMix64(2026)` to any other seed. The pad and c change completely, but the toy, the guesser and the bounds print the same: secrecy comes from the pad being uniform, not from any particular pad.

---

## The usual mistake

> [!warning]
> **Reusing the pad, or calling a long repeating key a pad.** The proof needs a fresh key for every message. Used twice, the key cancels: c ⊕ c2 = m ⊕ m2, and here 15 of 20 bytes come out 00 before any guessing starts. A key "stretched" by repetition is the same mistake: a 1-byte key gives 1 readable decryption out of 256.
>
> Smaller traps:
> - **Pseudorandom pads.** Bytes from a seeded generator, like this card's SplitMix64, are a formula. Whoever learns the seed learns the whole pad. That is a stream cipher (a short key stretched into a long run of pad-like bytes), secure at best against an attacker with limited computing, not perfectly secret.
> - **"Unbreakable" means "safe to use".** The pad hides the content, not the length (20 bytes says "short order") and not tampering: one flipped byte turns 750 into 950. Integrity needs a tag: [Hashes and MACs](03-hash-functions-and-macs.md).
> - **"The eavesdropper learns nothing" means "knows nothing".** Perfect secrecy keeps the prior unchanged. If the eavesdropper already knew the order is 750 or 950, they still know that.
> - **Secret method instead of secret key.** A hidden XOR rule is still XOR. Kerckhoffs: assume the method is known, and put all the secret in the key.

---

## Where you meet it in real life

- **The Moscow–Washington hotline.** The teletype link set up in 1963 used one-time tapes exchanged by diplomatic courier: the price of a pad paid in full, for a line where the volume was small and the stakes huge.
- **Spy number stations.** Shortwave stations reading out groups of digits are the classic use of paper pads: agents decode them with a pad page, then destroy the page.
- **Stream ciphers in your browser.** ChaCha20, one of the ciphers in TLS (the lock in the address bar), XORs the message with a long stream of bytes, exactly like a pad. The stream is computed from a 256-bit key and a nonce (a number used once), so a short key can serve gigabytes. The secrecy becomes computational, about 2^256 operations, and the "never reuse" rule survives as "never reuse a nonce". See [The TLS handshake](08-key-exchange-in-practice-the-tls-handshake.md).
- **AES-GCM nonce reuse.** The same failure as Step 5 in a modern dress: reuse the counter value with the same key and two messages leak their XOR. See [AES](02-symmetric-ciphers-and-aes.md).
- **Quantum key distribution.** Its pitch is to deliver pad bytes over a fibre with physics, rather than a courier. It replaces the courier, but it must still deliver 200,000,000 pad bytes a day for a bank sending 10 million 20-byte orders, 73,000,000,000 bytes a year.

> **Say it back**
> The one-time pad XORs the message with a key of random bytes as long as the message, and the receiver XORs the same key back off. Every key is equally likely and exactly one key links each message to each ciphertext, so the ciphertext is uniform whatever was sent, and seeing it leaves the odds on every message where they were. That needs at least as many keys as messages, so the key is as long as all the traffic and must be delivered in secret beforehand. Use it twice and the key cancels, leaking the XOR of two messages. Following Kerckhoffs, the method is public and every bit of the secret sits in the key.

---

## What this builds on

- [Entropy](../03-Information%20Theory/01-entropy.md): bits as a measure of uncertainty. Perfect secrecy says the ciphertext removes zero bits, and the toy's 1.75 bits is the entropy of its four replies.
- [Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md): arithmetic on a clock. XOR is addition mod 2 in each bit, which is why the same pad both locks and unlocks.

## Where this goes next

- [AES](02-symmetric-ciphers-and-aes.md): the practical answer to the pad's price. A 128- or 256-bit key (that card uses 256), reused safely for many messages, with security measured as about 2^128 or 2^256 operations if no shortcut exists, instead of perfect.

The open question this card leaves: how can a short key, used again and again, come close enough to a pad that no realistic attacker can tell the difference?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Shannon, C. E. "Communication Theory of Secrecy Systems." *Bell System Technical Journal* 28, no. 4 (1949): 656–715. [doi:10.1002/j.1538-7305.1949.tb00928.x](https://doi.org/10.1002/j.1538-7305.1949.tb00928.x). Defines perfect secrecy, proves the pad has it, and proves keys must be at least as many as messages.
- Vernam, Gilbert S. "Cipher Printing Telegraph Systems: For Secret Wire and Radio Telegraphic Communications." *Journal of the A.I.E.E.* 45, no. 2 (1926): 109–115. [doi:10.1109/JAIEE.1926.6534724](https://doi.org/10.1109/JAIEE.1926.6534724). The XOR-with-a-key-tape design for teletype that the pad is built on.
- Bellovin, Steven M. "Frank Miller: Inventor of the One-Time Pad." *Cryptologia* 35, no. 3 (2011): 203–222. [doi:10.1080/01611194.2011.583711](https://doi.org/10.1080/01611194.2011.583711). The pad's history, back to Frank Miller's 1882 telegraph code book, decades before Vernam.
- Katz, Jonathan, and Yehuda Lindell. *Introduction to Modern Cryptography*, revised 3rd ed. CRC Press. [Publisher page](https://www.routledge.com/Introduction-to-Modern-Cryptography-Revised-Third-Edition/Katz-Lindell/p/book/9781032496795). Perfect secrecy, the key-length bound, Kerckhoffs's principle and the four attack models in modern form.
