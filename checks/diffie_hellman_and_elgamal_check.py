# Diffie-Hellman and ElGamal -- the check behind the card.  Standard library only.
# TOY SIZES, INSECURE: a 15-bit prime stands in for the 3,072-bit prime of RFC 7919.
# Nothing imported.  No three-argument pow: powers are square-and-multiply written out.
P = 20123                     # the clock: a prime with P = 2Q + 1
Q = (P - 1) // 2              # 10061, also prime: the order of the group we use
G = 4                         # 2 squared; its powers are the Q squares on the clock
ROOT = 2                      # a primitive root: its powers reach all P - 1 slots
def power(b, e, p=P):         # square and multiply
    out, b = 1, b % p
    while e:
        if e & 1: out = out * b % p
        b, e = b * b % p, e >> 1
    return out
def inverse(a, p=P):          # extended Euclid: the number that multiplies a back to 1
    t0, t1, s0, s1 = p, a % p, 0, 1
    while t1: k = t0 // t1; t0, t1, s0, s1 = t1, t0 - k * t1, s1, s0 - k * s1
    return s0 % p
def is_prime(n): return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))
def is_square(y, p=P): return power(y, (p - 1) // 2, p) == 1    # Euler's test
state = 2026                  # SplitMix64, seed 2026: stands in for the laptops' coins
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2 ** 64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2 ** 64
    return z ^ (z >> 31)
def secret(q=Q): return splitmix() % (q - 1) + 1          # a count from 1 to q - 1
def brute_log(y, g=G, p=P):   # road 1 for the listener: try every count in turn
    x, t = 0, 1
    while t != y: t, x = t * g % p, x + 1
    return x, x
def bsgs_log(y, q, g=G, p=P): # road 2: baby-step giant-step, about 2 sqrt(q) steps
    m = int(q ** 0.5) + 1
    baby, t = {}, 1
    for j in range(m): baby[t] = j; t = t * g % p
    shift, gamma = inverse(power(g, m, p), p), y
    for i in range(m):
        if gamma in baby: return i * m + baby[gamma], m + i + 1
        gamma = gamma * shift % p
assert is_prime(P) and is_prime(Q) and power(G, Q) == 1
assert power(ROOT, Q) == P - 1 and power(ROOT, 2) != 1
print(f"group: clock P = {P}, order Q = {Q} (prime), generator G = {G}; TOY SIZE, INSECURE")
print(f"G = {G} has order {Q}: {G}^{Q} = {power(G, Q)}; ROOT = {ROOT} has order {P - 1}: {ROOT}^{Q} = {power(ROOT, Q)}")
# ---- the exchange over cafe wifi ----
a, b = secret(), secret()
A, B = power(G, a), power(G, b)
key_a, key_b, key_direct = power(B, a), power(A, b), power(G, a * b % Q)
print(f"laptop 1 keeps a = {a}, sends A = {A}; laptop 2 keeps b = {b}, sends B = {B}")
print(f"laptop 1: B^a = {key_a}; laptop 2: A^b = {key_b}; G^(ab mod Q) = {key_direct}")
assert key_a == key_b == key_direct and is_square(key_a)
print(f"laptop 1's work: a has {a.bit_length()} bits, {bin(a).count('1')} of them 1s, so {a.bit_length() - 1} squarings and {bin(a).count('1') - 1} multiplications")
# ---- the listener: two roads to the discrete log ----
x1, n1 = brute_log(A)
x2, n2 = bsgs_log(A, Q)
print(f"listener, every count in turn: a = {x1} after {n1} multiplications")
M = int(Q ** 0.5) + 1
print(f"listener, baby-step giant-step: a = {x2} = {x2 // M} x {M} + {x2 % M} after {n2} steps ({M} baby, {n2 - M} giant)")
assert x1 == a and x2 == a and n2 <= 2 * M and n2 < n1
print("cost:              bits(P)       Q  worst: every count   baby-giant   one run: every count vs baby-giant")
for p in (2063, 20123, 524387, 8389163):
    q = (p - 1) // 2
    y = power(4, secret(q), p)
    xb, nb = brute_log(y, 4, p)
    xg, ng = bsgs_log(y, q, 4, p)
    assert xb == xg and power(4, xg, p) == y and ng <= 2 * (int(q ** 0.5) + 1)
    print(f"cost, p = {p:>7}: {p.bit_length():>9} {q:>7} {q - 1:>20} {2 * (int(q ** 0.5) + 1):>12} {nb:>20} vs {ng}")
print(f"real size, RFC 7919 ffdhe3072: P of 3072 bits, counts of 275+ bits; a 256-bit count takes about 2^{256 // 2} baby-giant steps")
# ---- ElGamal: laptop 2 publishes H = G^x once; laptop 1 sends a PIN with no reply needed ----
x = secret()
H = power(G, x)
pin = 4071
enc = pin if is_square(pin) else P - pin              # put the PIN inside the group
assert is_square(enc)
def encrypt(e, r): return power(G, r), e * power(H, r) % P
def decrypt(c1, c2):
    e = c2 * inverse(power(c1, x)) % P                 # road 1: extended Euclid
    e2 = c2 * power(c1, Q - x) % P                     # road 2: c1^(Q-x) undoes c1^x
    assert e == e2
    return min(e, P - e)
r1, r2 = secret(), secret()
c, c_again = encrypt(enc, r1), encrypt(enc, r2)
print(f"laptop 2: x = {x}, publishes H = {H}")
print(f"PIN {pin} is a square: {is_square(pin)}; sent inside the group as {enc}")
print(f"encrypt with r = {r1}: (c1, c2) = {c}; mask H^r = {power(H, r1)}")
print(f"decrypt: c1^x = {power(c[0], x)}, its inverse {inverse(power(c[0], x))}, PIN = {decrypt(*c)}")
print(f"same PIN, fresh r = {r2}: (c1, c2) = {c_again}, PIN = {decrypt(*c_again)}")
assert decrypt(*c) == pin and decrypt(*c_again) == pin and c != c_again and power(H, r1) == power(c[0], x)
# ---- what breaks ----
pin2 = 9306
enc2 = pin2 if is_square(pin2) else P - pin2
d = encrypt(enc2, r1)                                  # the same r used twice
leak = c[1] * inverse(d[1]) % P
guess = enc * inverse(leak) % P
print(f"break, reuse r: second PIN {pin2}; c2/c2' = {leak}; knowing the first PIN gives {min(guess, P - guess)}")
assert min(guess, P - guess) == pin2
bad = P - 1                                            # a forged B of order 2
vals = {power(bad, t) for t in range(1, 5)}
print(f"break, unchecked B = {bad}: shared key B^a = {power(bad, a)}, one of only {len(vals)} values")
assert power(bad, a) == (1 if a % 2 == 0 else P - 1) and len(vals) == 2 and not is_square(bad)
wrong = power(G, a * b % P)
print(f"break, exponent reduced mod P not mod Q: {wrong} instead of {key_a}")
assert wrong != key_a
raw = pin2                                             # skip the encoding step
cr = encrypt(raw, r2)
print(f"break, raw PIN {raw} outside the group: c2 is a square: {is_square(cr[1])}, so the PIN is not")
assert is_square(cr[1]) == is_square(raw) == False
# ---- the parity leak: a DDH guessing game, 4000 rounds each ----
def ddh_game(g, q, rounds=4000):     # q: the size of the group g generates
    wins = 0
    for _ in range(rounds):
        u, v, w = secret(q), secret(q), secret(q)
        real = splitmix() % 2 == 1
        Z = power(g, u * v) if real else power(g, w)
        sq_u, sq_v = is_square(power(g, u)), is_square(power(g, v))
        predicted = sq_u or sq_v                       # g^(uv) is a square if u or v is even
        says_real = is_square(Z) == predicted
        wins += (says_real == real)
    return wins / rounds
win_root, win_sub = ddh_game(ROOT, P - 1), ddh_game(G, Q)
print(f"break, DDH game with generator {ROOT} (all {P - 1} slots), 4000 rounds: guesser wins {win_root:.4f}; theory 0.75")
print(f"DDH game with generator {G} (the {Q} squares), 4000 rounds: guesser wins {win_sub:.4f}; theory 0.50")
assert abs(win_root - 0.75) < 0.03 and abs(win_sub - 0.5) < 0.03
print("ALL CHECKS PASS")
