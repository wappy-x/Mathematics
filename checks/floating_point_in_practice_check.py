# Floating point in practice -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  struct only hands over the 64 stored
# bits; every exact value is then worked out in whole numbers, which cannot round,
# and the machine's answers are checked against them.
import math, struct

U = 2.0 ** -53                                    # unit roundoff: half of machine epsilon

def bits(x):      return struct.unpack(">Q", struct.pack(">d", x))[0]
def from_bits(b): return struct.unpack(">d", struct.pack(">Q", b))[0]

def exact(x):     # a positive normal double as whole numbers: x = m / 2^k, m has 53 bits
    b = bits(x)
    return (1 << 52) + (b & ((1 << 52) - 1)), 52 - (((b >> 52) & 0x7FF) - 1023)

def round53(m, k):  # round m / 2^k to 53 significant bits, ties to the even neighbour
    drop = max(m.bit_length() - 53, 0)
    q, r, half = m >> drop, m & ((1 << drop) - 1), (1 << drop) >> 1
    if r > half or (drop > 0 and r == half and q & 1):
        q += 1
    if q >> 53:
        q, drop = q >> 1, drop + 1
    return q, k - drop

def nearest(p, q):  # the double nearest p/q, by long division in base two
    k = 0
    while (p << k) // q < (1 << 52): k += 1
    m, r = divmod(p << k, q)
    if 2 * r > q or (2 * r == q and m & 1): m += 1
    return m, k

def decimal(m, k):  # exact decimal expansion of m / 2^k: it always ends
    mask, out, r = (1 << k) - 1, "", m & ((1 << k) - 1)
    while r:
        r *= 10; out += str(r >> k); r &= mask
    return f"{m >> k}." + (out or "0")

def sci(x):
    a, b = f"{x:.3e}".split("e"); return f"{a}e{int(b)}"
def yn(flag): return "yes" if flag else "no"
def row(label, value): print(f"{label:<34} {value}")

# ---- 1. reading the 64 bits of 0.1 ----
b = bits(0.1)
s = f"{b:064b}"
row("0.1 as 64 bits", f"{s[0]} {s[1:12]} {s[12:]}")
row("sign, exponent field, fraction", f"{b >> 63} {(b >> 52) & 0x7FF} {b & ((1 << 52) - 1)}")
row("1 + f/2^52, and e - 1023", f"{1 + (b & ((1 << 52) - 1)) / 2**52!r} {((b >> 52) & 0x7FF) - 1023}")
for name, x, p in (("0.1", 0.1, 1), ("0.2", 0.2, 2), ("0.3", 0.3, 3)):
    assert exact(x) == nearest(p, 10), name + ": stored bits must be the nearest double to p/10"
    row(f"{name} stored exactly", decimal(*exact(x)))
m1, k1 = exact(0.1)
row("0.1 as a whole number over 2^k", f"{m1} / 2^{k1}")
row("0.3 as a whole number over 2^k", "{} / 2^{}".format(*exact(0.3)))
row("0.1 stored minus 1/10", sci((m1 * 10 - (1 << k1)) / (10 * (1 << k1))))

# ---- 2. the sum, rounded by hand and by the machine ----
m2, k2 = exact(0.2)
exact_sum = m1 + (m2 << (k1 - k2))                # both over 2^56, no rounding
rm, rk = round53(exact_sum, k1)
total = 0.1 + 0.2
assert (rm, rk) == exact(total), "own rounding must match the machine's sum"
assert bits(total) == bits(0.3) + 1, "the sum lands one step above stored 0.3"
assert exact_sum & 3 == 2, "the two dropped bits must be exactly half: a tie"
row("exact sum of the stored inputs", decimal(exact_sum, k1))
row("sum over 2^56; 53 bits over 2^54", f"{exact_sum}; {exact_sum >> 2} -> {rm}")
row("bits dropped to fit 53, out of", f"{exact_sum & 3} of 4: a tie, so round to even")
row("machine sum 0.1 + 0.2", f"{total!r} = {decimal(rm, rk)}")
row("gap to stored 0.3, in ulps", bits(total) - bits(0.3))
rel = (rm * 4 - exact_sum) / exact_sum            # (rounded - exact) / exact, both over 2^56
row("relative error of the add", f"{sci(rel)} = {rel / U:.4f} u")
row("0.1 + 0.2 == 0.3", yn(total == 0.3))

# ---- 3. machine epsilon: from the layout and by halving ----
eps_layout = from_bits(bits(1.0) + 1) - 1.0
eps = 1.0
while 1.0 + eps / 2 != 1.0: eps /= 2
assert eps == eps_layout == 2.0 ** -52, "halving loop must stop at the layout's gap"
row("next double after 1, minus 1", sci(eps_layout))
row("halving loop stops at", sci(eps))
row("unit roundoff u = eps/2", sci(U))
for name, x in (("0.3", 0.3), ("1", 1.0), ("100000", 1e5), ("2^53", 2.0 ** 53)):
    row(f"ulp at {name}", sci(from_bits(bits(x) + 1) - x))
big = 2.0 ** 53
row("2^53, and 2^53 + 1 - 2^53", f"{big:.0f} {big + 1.0 - big:.0f}")
assert big + 1.0 == big and big - 1.0 + 1.0 == big, "the 1 vanishes above 2^53 only"

# ---- 4. the promise, tested: 20,000 random sums and products ----
state, MASK = 2026, 2**64 - 1
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
bad, worst = 0, 0.0
for _ in range(10000):                            # exponent fields 1013..1033: 2^-10 up to 2^11
    x, y = (from_bits(((1013 + splitmix() % 21) << 52) | (splitmix() >> 12)) for _ in "xy")
    (mx, kx), (my, ky) = exact(x), exact(y)
    kk = max(kx, ky)
    for m, k, got in ((mx << (kk - kx)) + (my << (kk - ky)), kk, x + y), (mx * my, kx + ky, x * y):
        rm, rk = round53(m, k)
        bad += (rm, rk) != exact(got)
        worst = max(worst, abs((rm << (k - rk)) - m) / m / U)
row("random sums and products checked", 20000)
row("disagreements with own rounding", bad)
row("worst relative error, in u", f"{worst:.6f}")
assert bad == 0 and worst <= 1.0, "every operation must be the exact answer, rounded once"

# ---- 5. where it shows up: 0.1 added n times, 100 times 1.05 ten times ----
acc, n = 0.0, 0
for target in (10, 100, 1000, 10000, 100000, 1000000):
    while n < target: acc += 0.1; n += 1
    ma, ka = exact(acc)
    err = abs((ma << (k1 - ka)) - n * m1) / 2 ** k1  # against the exact sum of n stored 0.1s
    bound = (n - 1) * U * n * 0.1                  # worst case, to first order in u
    assert 0 < err <= bound, "the sum's error must stay under the worst-case bound"
    if n == 10: ten = acc
    if n in (10, 1000000): row(f"0.1 added {n} times", f"{acc!r}, off {sci(acc - n / 10)}")
    row(f"chart n={n}: log10 err, bound", f"{math.log10(err):.2f} {math.log10(bound):.2f}")
x = 100.0
for _ in range(10): x *= 1.05
mx, kx = exact(x)
N = 162889462677744140625                         # 100 * 1.05^10, exactly, over 10^18
rel_p = abs(mx * 10**18 - N * 2**kx) / (N * 2**kx)
row("100 * 1.05, ten times", f"{x!r}, rel. error {rel_p / U:.2f} u")
assert rel_p <= 20 * U, "a stored 1.05 and ten roundings: at most about 20 u"

# ---- 6. what breaks, and the special values ----
row("0.1 added ten times == 1.0", yn(ten == 1.0))
row("1 + 1e-17 == 1, 1e-17 == 0", f"{yn(1.0 + 1e-17 == 1.0)} {yn(1e-17 == 0.0)}")
top = from_bits(0x7FEFFFFFFFFFFFFF)
inf = top * 2
row("largest double", f"{top:.16e}".replace("e+", "e"))
row("largest * 2; is inf - inf itself", f"{inf} {yn(inf - inf == inf - inf)}")
row("-0.0 == 0.0; same bits", f"{yn(-0.0 == 0.0)} {yn(bits(-0.0) == bits(0.0))}")
print("ALL CHECKS PASS")
