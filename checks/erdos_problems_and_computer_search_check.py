# Erdos problems and computer search -- the check behind the card.  Standard
# library only.  Collatz: halve an even n, send an odd n to 3n + 1.  Searched
# to N = 1,000,000 by two roads, whose loops finishing is the proof, with the
# record walked a third way; then what the clean range proves about cycles,
# and one Erdos question a search settles completely.
import math
N, K = 1_000_000, 16

def plain(n):                                # road 3: no shortcuts, no memory
    steps, peak = 0, n
    while n != 1:
        n = n // 2 if n % 2 == 0 else 3 * n + 1
        steps, peak = steps + 1, max(peak, n)
    return steps, peak

steps = [0] * (N + 1)                        # road 1: every n to 1, with memory
for n in range(2, N + 1):
    m, s = n, 0
    while m >= n:
        m = m // 2 if m % 2 == 0 else 3 * m + 1
        s += 1
    steps[n] = s + steps[m]
best = max(range(1, N + 1), key=lambda n: steps[n])

def T(n):                                    # the shortcut map: an odd step halves at once
    return n // 2 if n % 2 == 0 else (3 * n + 1) // 2

def survivors_tree(k):                       # classes mod 2^k not yet below their start
    alive = [(0, 0, 0)]                      # (residue b, odd steps j, value t of T^i(b))
    for i in range(k):
        nxt = []
        for b, j, t in alive:
            for e in (0, 1):
                s = 3 ** j * e + t
                j2, t2 = (j, s // 2) if s % 2 == 0 else (j + 1, (3 * s + 1) // 2)
                if 3 ** j2 > 2 ** (i + 1):
                    nxt.append((b + e * 2 ** i, j2, t2))
        alive = nxt
    return sorted(b for b, _, _ in alive)

def survivors_brute(k):                      # second road: one huge member per class
    out = []
    for b in range(2 ** k):
        n = m = b + 2 ** k * 2 ** 40
        if all((m := T(m)) >= n for _ in range(k)):
            out.append(b)
    return out

surv = survivors_tree(K)
alive = set(surv)
late, fell = [], 0                           # road 2: falls below itself, shortcut map
for n in range(2, N + 1):
    m, s = n, 0
    while m >= n:
        m, s = T(m), s + 1
    fell += 1
    if s > K and n >= 2 ** K:
        late.append(n)
tested = sum(1 for n in range(2, N + 1) if n < 2 ** K or n % 2 ** K in alive)
pred = sum(1 for n in range(2 ** K, N + 1) if n % 2 ** K in alive)   # the sieve: these need > K steps

x, l2 = 1 / (3 * N), math.log(3) / math.log(2)   # a cycle avoiding 1..N needs k odd steps
k = 1
while (math.ceil(k * l2) - k * l2) * math.log(2) >= k * x:
    k += 1
L = math.ceil(k * l2)

def disc(seq):                               # largest |x_d + x_2d + ... + x_md|
    return max([abs(sum(seq[d - 1:m:d])) for d in range(1, len(seq) + 1)
                for m in range(d, len(seq) + 1, d)] + [0])

def grow(seq, n):                            # backtracking: extend while discrepancy <= 1
    if disc(seq) > 1: return 0
    return 1 if len(seq) == n else grow(seq + [1], n) + grow(seq + [-1], n)

brute = [sum(1 for c in range(2 ** n) if disc([1 - 2 * (c >> i & 1) for i in range(n)]) <= 1)
         for n in range(1, 13)]
tree = [grow([], n) for n in range(1, 13)]
five, one = [13], [1]                        # 5n + 1 from 13, and 3n + 1 from 1
for _ in range(10):
    five.append(five[-1] // 2 if five[-1] % 2 == 0 else 5 * five[-1] + 1)
for _ in range(3):
    one.append(one[-1] // 2 if one[-1] % 2 == 0 else 3 * one[-1] + 1)
s27, p27 = plain(27)
sb, pb = plain(best)
m, oddb = best, 0
while m != 1:
    oddb += m % 2
    m = m // 2 if m % 2 == 0 else 3 * m + 1
print(f"27 reaches 1 in {s27} steps, peak {p27:,}")
print(f"road 1, memory to {N:,}: every walk finished, so every start reaches 1")
print(f"slowest start below {N:,}: {best:,}, {steps[best]} steps")
print(f"road 3, plain walk of {best:,}: {sb} steps, peak {pb:,}")
print(f"road 2, starts from 2 to {N:,} that fall below themselves: {fell:,}")
for kk in (1, 2, 3, 4, 8, 12, 16):
    sv = len(survivors_tree(kk))
    print(f"sieve mod 2^{kk}: {sv:,} of {2 ** kk:,} classes still need a test ({100 * sv / 2 ** kk:.2f}%)")
print(f"survivors mod 16: {survivors_tree(4)}")
print(f"tree and brute force agree on the survivors mod 2^{K}: {'yes' if surv == survivors_brute(K) else 'no'}")
print(f"numbers the sieve mod 2^{K} leaves to test: {tested:,} of {N - 1:,} ({100 * tested / (N - 1):.2f}%)")
print("quoted, not computed here: Goldbach checked to 4,000,000,000,000,000,000; "
      "Polya fails first at 906,150,257; longest discrepancy-2 sequence 1,160")
print(f"published range 2^68 = {2 ** 68:,}, {2 ** 68 // N:,} times this one; 2^71 in 2025, {2 ** 71 // 2 ** 68} times 2^68")
print(f"starts at or above 2^{K} needing more than {K} shortcut steps: {len(late):,}; the sieve predicts {pred:,}; "
      f"outside the survivors: {sum(1 for n in late if n % 2 ** K not in alive)}")
print(f"a cycle avoiding 1 to {N:,} needs at least {k:,} odd steps, {L:,} halvings, {k + L:,} steps")
print(f"  gap k ln 3 to L ln 2: {(L - k * l2) * math.log(2):.6f} under k/(3N) = {k * x:.6f}")
print(f"discrepancy at most 1, sequences of length 1 to 12: {brute}")
print(f"backtracking count agrees: {'yes' if brute == tree else 'no'}; longest length {max(n for n in range(1, 13) if brute[n - 1])}")
print(f"mistake 1, shortcut steps for {best:,}: {sb - oddb}, not {sb} ({oddb} odd steps folded in)")
print(f"mistake 2, descent test on 1: {' -> '.join(map(str, one))}, lowest after the start {min(one[1:])}")
print(f"mistake 3, 5n + 1 from 13: {' -> '.join(map(str, five))}, a cycle of {len(five) - 1} steps")
assert sb == steps[best]                                                   # roads 1 and 3 on the record
assert (best, sb, s27, p27) == (837_799, 524, 111, 9_232)                  # published
assert surv == survivors_brute(K) and survivors_tree(4) == [7, 11, 15]     # two roads to the sieve
assert all(n % 2 ** K in alive for n in late) and len(late) == pred       # road 2 against the sieve
assert brute == tree and brute[10] > 0 and brute[11] == 0                  # longest is 11
assert five[-1] == 13 and 13 not in five[1:-1] and min(one[1:]) == 1      # the cycles
assert 3 ** k < 2 ** L and 2 ** L * (3 * N) ** k < 3 ** k * (3 * N + 1) ** k  # exact integers
print("ALL CHECKS PASS")
