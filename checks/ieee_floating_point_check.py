# IEEE 754 doubles -- the check behind the card.  Standard library only.
# struct only hands over the 64 stored bits.  Reading the fields and rounding a fraction
# in each mode are done in whole numbers, which cannot round; then the machine is checked.
import struct

def bits(x):      return struct.unpack(">Q", struct.pack(">d", x))[0]
def from_bits(b): return struct.unpack(">d", struct.pack(">Q", b))[0]
def fields(b):    return b >> 63, (b >> 52) & 0x7FF, b & ((1 << 52) - 1)

def kind(b):                           # what the exponent field says the pattern is
    s, e, f = fields(b)
    if e == 2047: return "NaN" if f else "infinity"
    if e == 0:    return "subnormal" if f else "zero"
    return "normal"

def exact(b):                          # a positive finite double as m / 2^k, from its fields alone
    s, e, f = fields(b)
    return (f, 1074) if e == 0 else ((1 << 52) + f, 1075 - e)

def encode(p, q, k, mode):             # the double for p / q / 2^k (p, q > 0), as 64 bits
    L = p.bit_length() - q.bit_length()
    if (p << max(-L, 0)) < (q << max(L, 0)): L -= 1
    E = L - k                          # the value lies in [2^E, 2^(E+1))
    if E > 1023: return 0x7FEFFFFFFFFFFFFF if mode == "down" else 0x7FF << 52
    sc = max(E, -1022) - 52            # the grid there: whole multiples of 2^sc
    t = -k - sc
    num, den = (p << t, q) if t >= 0 else (p, q << -t)
    m, r = divmod(num, den)            # m grid steps, plus a remainder r/den of a step
    if mode == "up" and r: m += 1
    if mode == "nearest" and (2 * r > den or (2 * r == den and m & 1)): m += 1
    if m >> 53: m, sc = m >> 1, sc + 1
    if m < (1 << 52): return m         # subnormal or zero: exponent field 0
    return ((sc + 1075) << 52) | (m - (1 << 52))   # field 2047 here means infinity

def decimal(m, k):                     # exact decimal expansion of m / 2^k: it always ends
    mask, out, r = (1 << k) - 1, "", m & ((1 << k) - 1)
    while r: r *= 10; out += str(r >> k); r &= mask
    return f"{m >> k}." + (out or "0")

def short(x):  return repr(x).replace("e+", "e")
def sci(x):    a, b = f"{x:.3e}".split("e"); return f"{a}e{int(b)}"
def yn(flag):  return "yes" if flag else "no"
def row(label, value): print(f"{label:<35} {value}")

# ---- 1. the three fields of 0.1, 0.2, 0.3 and the machine's 0.1 + 0.2 ----
total = 0.1 + 0.2
for name, x in (("0.1", 0.1), ("0.2", 0.2), ("0.3", 0.3), ("0.1 + 0.2", total)):
    s, e, f = fields(bits(x))
    row(f"{name}: s, e, f, E = e - 1023", f"{s} {e} {f} {e - 1023}")
for name, x, p in (("0.1", 0.1, 1), ("0.2", 0.2, 2), ("0.3", 0.3, 3)):
    assert encode(p, 10, 0, "nearest") == bits(x), name + ": own rounding must equal the parser's"
b = f"{bits(total):064b}"
row("0.1 + 0.2 as 64 bits", f"{b[0]} {b[1:12]} {b[12:]}")
row("0.1 + 0.2 printed", repr(total))
row("0.1 + 0.2 stored exactly", "{} / 2^{} = ".format(*exact(bits(total))) + decimal(*exact(bits(total))))
f3 = fields(bits(0.3))[2]             # misreading 0.3: no hidden leading 1; no bias
row("0.3 misread: no leading 1; no bias", f"{f3 / 2**52 * 2.0**-2:.4f} {sci((1 + f3 / 2**52) * 2.0**1021)}")
# ---- 2. one tenth in three rounding modes ----
for mode in ("nearest", "down", "up"):
    m, k = exact(encode(1, 10, 0, mode))
    row(f"1/10 rounded {mode}", f"{m} / 2^{k}, off {(10 * m - (1 << k)) / 10:+.1f} ulp")
gap = encode(1, 10, 0, "up") - encode(1, 10, 0, "down")
row("up minus down, in ulps", gap)
assert gap == 1, "a number that is not a double sits between two neighbours"

# ---- 3. the sum: exact sum of the stored inputs, rounded each way ----
(m1, k1), (m2, k2) = exact(bits(0.1)), exact(bits(0.2))
ex = m1 + (m2 << (k1 - k2))            # both over 2^56: no rounding yet
row("exact sum of stored inputs", f"{ex} / 2^{k1}, {ex % 4} of 4 past the grid")
for mode in ("nearest", "down", "up"):
    row(f"sum rounded {mode}", short(from_bits(encode(ex, 1, k1, mode))))
assert encode(ex, 1, k1, "nearest") == bits(total), "own rounding must equal the machine's add"
assert encode(ex, 1, k1, "down") == bits(0.3), "rounded down, the sum is the stored 0.3"
big = 2.0 ** 53 + 1.0                  # a tie whose even neighbour is below
row("2^53 + 1, a tie, rounded nearest", f"{big:.0f}")
assert bits(big) == encode(2**53 + 1, 1, 0, "nearest") == bits(2.0 ** 53), "ties go to even"

# ---- 4. the ends of the range ----
top = from_bits(0x7FEFFFFFFFFFFFFF)
assert top == (2.0 - 2.0 ** -52) * 2.0 ** 1023, "largest double from its fields"
x, doublings = 1.0, 0
while kind(bits(x)) != "infinity": x, doublings = x * 2, doublings + 1
y, halvings = 1.0, 0
while y / 2 != 0.0: y, halvings = y / 2, halvings + 1
assert (doublings, halvings, bits(y)) == (1024, 1074, 1), "range ends from loops, not from fields"
row("largest double", short(top))
row("smallest normal, 2^-1022", short(from_bits(1 << 52)))
row("smallest subnormal, 2^-1074", short(y))
row("doublings from 1 to infinity", doublings)
row("halvings from 1 before zero", halvings)
row("largest * 2: kind, bits", f"{kind(bits(top * 2))} {bits(top * 2):#018x}")
assert encode(1, 1, -1024, "nearest") == bits(top * 2), "past the top, own rounding says inf"

# ---- 5. subnormals: gradual underflow ----
a, c = 1.5 * 2.0 ** -1022, 2.0 ** -1022
flushed = 0.0 if kind(bits(a - c)) == "subnormal" else a - c   # simulated: no subnormals
row("1.5*2^-1022 - 2^-1022; if flushed", f"{short(a - c)}, {kind(bits(a - c))}; {short(flushed)}")
assert a != c and a - c != 0 and bits(a - c) == encode(1, 1, 1023, "nearest"), "x != y means x - y != 0"
tiny = 0.1 * from_bits(1 << 14)        # 0.1 times 2^-1060, deep in the subnormals
ft = fields(bits(tiny))[2]
assert bits(tiny) == encode(m1, 1, k1 + 1060, "nearest"), "own rounding into the subnormals"
rel = (ft * 2 ** 42 - m1) / m1         # against the exact product
row("0.1 * 2^-1060: f, bits, rel err", f"{ft} {ft.bit_length()} {sci(rel)}")

# ---- 6. infinity, NaN and signed zero ----
inf = top * 2; nan = inf - inf
s, e, f = fields(bits(nan))
row("inf - inf: kind, e, f nonzero", f"{kind(bits(nan))} {e} {yn(f != 0)}")
row("nan == nan, nan < 1, nan > 1", f"{yn(nan == nan)} {yn(nan < 1)} {yn(nan > 1)}")
row("nan + 1 is NaN; 1 / inf", f"{yn(kind(bits(nan + 1)) == 'NaN')} {short(1 / inf)}")
nz = 1e-200 * -1e-200
row("1e-200 * -1e-200; sign bit", f"{short(nz)} {fields(bits(nz))[0]}")
row("-0.0 == 0.0; same bits", f"{yn(nz == 0.0)} {yn(bits(nz) == bits(0.0))}")

# ---- 7. 20,000 random fractions: own rounding against the machine's divide ----
state, MASK = 2026, 2**64 - 1
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
bad, subs = 0, 0
for scale in (0, 1022):                # scale 1022 sends about half into the subnormals
    for _ in range(10000):
        p, q = splitmix() >> 11 | 1, splitmix() >> 11 | 1
        got = bits(p * 2.0 ** -scale / q)
        bad += got != encode(p, q, scale, "nearest")
        subs += kind(got) == "subnormal"
row("random divides; subnormal results", f"20000 {subs}")
row("disagreements with own rounding", bad)
assert bad == 0, "every divide must be the exact quotient, rounded to nearest"

# ---- 8. the house example and the figure ----
acc = 0.0
for _ in range(10_000_000): acc += 0.1
row("0.1 added ten million times", f"{short(acc)}, off {sci(acc - 1e6)}")
row("ulp at 1,000,000", sci(from_bits(bits(1e6) + 1) - 1e6))
row("figure, x: sign, exponent, fraction", "20-60 60-160 160-420")
print("ALL CHECKS PASS")
