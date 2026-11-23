# Streaming and sketching -- the check behind the card.  Standard library only.
# One day's visitor log is read once.  An exact count keeps every visitor; a
# HyperLogLog sketch keeps 4,096 small registers.  Random numbers and the hash
# are SplitMix64, written out, so the Rust program prints the same lines.
import math
M64 = (1 << 64) - 1

def mix64(z):                          # SplitMix64's scrambler: the hash
    z = (z + 0x9E3779B97F4A7C15) & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

class Gen:                             # SplitMix64 generator, seed stated
    def __init__(self, seed): self.s = seed
    def next(self):
        z, self.s = self.s, (self.s + 0x9E3779B97F4A7C15) & M64
        return mix64(z)

def alpha(m): return {16: 0.673, 32: 0.697, 64: 0.709}.get(m, 0.7213 / (1 + 1.079 / m))

def new_sketch(b): return [0] * (1 << b)

def add(reg, b, h):                    # first b bits pick a register; the rest give a rank
    rest = h & ((1 << (64 - b)) - 1)
    rank = (64 - b) - rest.bit_length() + 1   # leading zeros of the rest, plus 1
    j = h >> (64 - b)
    if rank > reg[j]: reg[j] = rank

def estimate(reg, correct=True):       # harmonic mean of 2^rank, scaled by alpha m^2
    m = len(reg)
    raw = alpha(m) * m * m / sum(2.0 ** -r for r in reg)
    zeros = reg.count(0)
    if correct and raw <= 2.5 * m and zeros > 0: return m * math.log(m / zeros)
    return raw

# ---- the day: 1,000,000 requests; half from 1,000 regulars, half from 999,000 others ----
N, SALT, B = 1_000_000, 2026, 12
g, seen, reg = Gen(2026), set(), new_sketch(B)
for _ in range(N):
    r = g.next()
    v = (r >> 1) % 1000 if r & 1 else 1000 + (r >> 1) % 999_000
    seen.add(v)                        # road 1: the exact count keeps every visitor
    add(reg, B, mix64(v ^ SALT))       # road 2: the sketch keeps 4,096 registers
D, m = len(seen), 1 << B
est = estimate(reg)
se = 1.04 / math.sqrt(m)
print("requests read once", N)
print("distinct visitors, exact", D)
print(f"sketch: {m} registers of 6 bits = {m * 6 // 8} bytes")
print(f"sketch estimate {est:.0f}, error {100 * (est - D) / D:+.2f}%")
print(f"promised typical error 1.04/sqrt({m}) = {100 * se:.2f}%")
print(f"one register sees about D/{m} = {D / m:.1f} visitors; log2 of that {math.log2(D / m):.2f}, "
      f"mean rank {sum(reg) / m:.2f}")
lo, hi = est / (1 + 2 * se), est / (1 - 2 * se)
print(f"95% error bar: {lo:.0f} to {hi:.0f}")
assert abs(est - D) / D < 3 * se and lo <= D <= hi   # inside the promised bar
assert 390_000 < D < 400_000           # 1,000 + 999,000 (1 - e^-0.5005), about 394,000

# ---- what exact counting costs: the visitor set itself must fit in memory ----
U = 1 << 32                            # every visitor is a 32-bit address
floor_bits = 0.0
for i in range(D): floor_bits += math.log2((U - i) / (D - i))
lg = (math.lgamma(U + 1) - math.lgamma(D + 1) - math.lgamma(U - D + 1)) / math.log(2)
print(f"exact count, floor log2 C(2^32, D) = {floor_bits / 8:.0f} bytes, {floor_bits / D:.2f} bits each")
print(f"per visitor: log2(2^32 / D) = {math.log2(U / D):.2f}, plus log2 e = {1 / math.log(2):.2f}")
print(f"exact count, plain list of 4-byte addresses = {4 * D} bytes")
print(f"floor over sketch: {floor_bits / 8 / (m * 6 // 8):.0f} times the memory")
assert abs(lg - floor_bits) < 1e-6 * floor_bits   # two roads to the same floor

# ---- the proof run on a toy: 10 possible visitors, a summary of 9 bits ----
def toy(stream): # a 9-bit bitmap: visitor v sets bit v mod 9; answers the number of 1s
    state = 0
    for v in stream: state |= 1 << (v % 9)
    return state
first, pair = {}, None
for mask in range(1 << 10):            # all 1,024 sets of the 10 visitors
    s = [v for v in range(10) if mask >> v & 1]
    st = toy(s)
    if st in first and pair is None: pair = (first[st], s)
    first.setdefault(st, s)
S, T = pair
x = next(v for v in S + T if (v in S) != (v in T))   # the probe: in one set only
ans = bin(toy(S + [x])).count("1")
print(f"toy: {len(first)} memory states for 1024 visitor sets")
print(f"toy: sets {S} and {T} leave the same memory")
print(f"toy: add visitor {x}; true counts {len(set(S + [x]))} and {len(set(T + [x]))}, "
      f"summary answers {ans} for both")
assert len(first) == 512 and toy(S + [x]) == toy(T + [x]) and len(set(S + [x])) != len(set(T + [x]))
dec = 0                                # an exact 10-bit bitmap: probing recovers every set
for mask in range(1 << 10):
    cnt = bin(mask).count("1")         # feed each visitor to a copy; count unchanged means seen
    got = sum(1 << v for v in range(10) if bin(mask | 1 << v).count("1") == cnt)
    dec += got == mask
print(f"toy: a 10-bit exact counter is decoded back to its set {dec} times in 1024")
assert dec == 1024

# ---- accuracy bought by memory: 100 days of 40,000 fresh visitors each ----
TRIALS, DD, BS = 100, 40_000, [6, 8, 10, 12]
sq, out2 = {b: 0.0 for b in BS}, {b: 0 for b in BS}
for t in range(TRIALS):
    sks, salt = {b: new_sketch(b) for b in BS}, Gen(7 + t).next()
    for i in range(DD):
        h = mix64((t * 1_000_000 + i) ^ salt)
        for b in BS: add(sks[b], b, h)
    for b in BS:
        e = (estimate(sks[b]) - DD) / DD
        sq[b] += e * e
        out2[b] += abs(e) > 2 * 1.04 / math.sqrt(1 << b)
print("registers  bytes  promised  measured  misses past 2x promise")
for b in BS:
    mm, rms = 1 << b, math.sqrt(sq[b] / TRIALS)
    print(f"{mm:9}{mm * 6 // 8:7}{100 * 1.04 / math.sqrt(mm):9.2f}%{100 * rms:9.2f}%"
          f"{out2[b]:8} of {TRIALS}")
    assert abs(rms / (1.04 / math.sqrt(mm)) - 1) < 0.3   # within a few standard errors
    assert out2[b] <= 12               # about 5% expected, 5 of 100

# ---- turning a typical error into a guarantee: the median of k sketches ----
for delta in [0.05, 0.01, 0.001]:
    k = math.ceil(8 * math.log(1 / delta))
    print(f"fail chance {delta}: median of {k} sketches, {k * m * 6 // 8} bytes")

# ---- what breaks ----
small = new_sketch(B)
for i in range(1000): add(small, B, mix64(i ^ SALT))
arith = alpha(m) * m * sum(2.0 ** r for r in reg) / m
print(f"break: count requests, not visitors: {N}")
print(f"break: 1000 visitors, no small-count correction: {estimate(small, False):.0f}"
      f" (with it {estimate(small):.0f})")
print(f"break: plain average of 2^rank, not harmonic: {arith:.0f}")
assert abs(estimate(small) - 1000) < 50 and estimate(small, False) > 2000 and arith > 2 * D
print("ALL CHECKS PASS")
