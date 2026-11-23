# Kolmogorov complexity -- the check behind the card.  Standard library only.
# K(x) is never computed: no program can.  It is only bounded above, by named
# programs whose length in bytes is measured and printed.  Pi's digits come two
# independent ways (Gibbons' spigot, Machin's formula in whole numbers), the coin
# flips come from SplitMix64, and the Berry construction runs on a real estimator E.
from math import log2, log10

# >>> named program: the first n digits of pi
def pi_digits(n):
    q, r, t, k, m, x = 1, 0, 1, 1, 3, 3
    out = []
    while len(out) < n:
        if 4 * q + r - t < m * t:
            out.append(m)
            q, r, m = 10 * q, 10 * (r - m * t), 10 * (3 * q + r) // t - 10 * m
        else:
            q, r, t, k, m, x = (q * k, (2 * q + r) * x, t * x, k + 1,
                                (q * (7 * k + 2) + r * x) // (t * x), x + 2)
    return "".join(map(str, out))
# <<< named program

def machin(n):                    # road 2: pi = 16 atan(1/5) - 4 atan(1/239), whole numbers only
    one = 10 ** (n + 10)
    def atan_inv(x):
        total, term, k, sign = 0, one // x, 1, 1
        while term:
            total += sign * (term // k)
            term //= x * x; k += 2; sign = -sign
        return total
    return str(16 * atan_inv(5) - 4 * atan_inv(239))[:n]

def flips(seed, n):               # SplitMix64, top bit of each output: pseudo-random coin flips
    x, out = seed, []
    for _ in range(n):
        x = (x + 0x9E3779B97F4A7C15) % 2**64
        z = (x ^ x >> 30) * 0xBF58476D1CE4E5B9 % 2**64
        z = (z ^ z >> 27) * 0x94D049BB133111EB % 2**64
        out.append(str((z ^ z >> 31) >> 63))
    return "".join(out)

# >>> named program: the Berry search
def gamma(r):                     # Elias gamma code of r >= 1: (length - 1) zeros, then r in binary
    b = ""
    while r: b, r = str(r % 2) + b, r // 2
    return "0" * (len(b) - 1) + b
def describe(x):                  # estimator E's description: first bit, then each run length in gamma
    out, i = [x[0]], 0
    while i < len(x):
        j = i
        while j < len(x) and x[j] == x[i]: j += 1
        out.append(gamma(j - i)); i = j
    return "".join(out)
def E(x): return len(describe(x))
def berry(L):                     # the construction: the first string, shortest first, that E rates above L
    m = 1
    while True:
        for v in range(2 ** m):
            x = "".join(str(v >> (m - 1 - i) & 1) for i in range(m))
            if E(x) > L: return x
        m += 1
# <<< named program

def decode(d):                    # E's decoder: the description alone gives back x
    bit, i, out = d[0], 1, []
    while i < len(d):
        z = 0
        while d[i] == "0": z, i = z + 1, i + 1
        r = 0
        for c in d[i:i + z + 1]: r = 2 * r + int(c)
        i += z + 1
        out.append(bit * r); bit = "1" if bit == "0" else "0"
    return "".join(out)

src = open(__file__).read()
pi_prog = src.split("# >>> named program: the first n digits of pi\n")[1].split("# <<< named program")[0]
def pi_prog_bytes(n): return len(pi_prog) + len(f"print(pi_digits({n}))\n")

N = 1000
pi_a, pi_b = pi_digits(N), machin(N)
counts = [pi_a.count(str(d)) for d in range(10)]
h_emp = sum(c / N * log2(N / c) for c in counts)
print("pi, spigot road, first 30 digits ", pi_a[:30])
print("pi, Machin road, first 30 digits ", pi_b[:30])
print("pi, roads agree on digits        ", sum(1 for a, b in zip(pi_a, pi_b) if a == b), "of", N)
print("pi, six 9s start at place        ", pi_a.find("999999"))
print("pi, digit counts 0..9            ", " ".join(str(c) for c in counts))
print(f"pi, digit-frequency entropy      {h_emp:.4f} bits per digit (log2 10 = {log2(10):.4f})")
print("named pi program, bytes          ", len(pi_prog), "+ call line")
for n in (10, 1000, 1000000):
    print(f"n = {n:>7}: pi as text {8 * n:>7} bits, packed {int(n * log2(10)) + 1:>7} bits,"
          f" named program {8 * pi_prog_bytes(n):>5} bits")

F = 1000000
coins = flips(2026, F)
ones = coins.count("1")
print("flips, seed 2026, first 32       ", coins[:32])
print("flips, ones out of 1000000       ", ones)
print("flips, E in bits                 ", E(coins))
fl_prog = 'x = 2026\nfor i in range(10**6):\n    x = (x + 0x9E3779B97F4A7C15) % 2**64\n' \
          '    z = (x ^ x >> 30) * 0xBF58476D1CE4E5B9 % 2**64\n' \
          '    z = (z ^ z >> 27) * 0x94D049BB133111EB % 2**64\n    print((z ^ z >> 31) >> 63, end="")\n'
print("flips, named generator program   ", len(fl_prog), "bytes =", 8 * len(fl_prog), "bits")

patt = "0011" * 250000
print("0011 x 250000: E", E(patt), "bits; program print('0011' * 250000) is", 8 * len("print('0011' * 250000)\n"), "bits")
alt = "01" * 500000
print("01 x 500000:   E", E(alt), "bits; program print('01' * 500000) is", 8 * len("print('01' * 500000)\n"), "bits")

n, total, small = 16, 0, [0] * 5
for v in range(2 ** n):
    x = "".join(str(v >> (n - 1 - i) & 1) for i in range(n))
    assert decode(describe(x)) == x, "E's descriptions must decode back"
    for k in range(5):
        small[k] += E(x) < n - k
for k in range(5):
    print(f"16-bit strings with E < {n - k}: {small[k]:>5} of 65536; any method: at most {2 ** (n - k) - 1:>5}")
print("chance K < 999980 for 1000000 true flips: below 1 in", 2 ** 20)

for L in (4, 8, 12, 16, 20):
    x = berry(L)
    print(f"berry({L:>2}) prints {x:<14} E = {E(x):>2}, length {len(x):>2}")
b_prog = src.split("# >>> named program: the Berry search\n")[1].split("# <<< named program")[0]
print("berry program bytes, L = 1000000 ", len(b_prog) + len("print(berry(1000000))\n"))
print("chart, log10 n               ", " ".join(f"{e:>5}" for e in range(1, 7)))
print("chart, log10 bits, pi packed ", " ".join(f"{log10(int(10**e * log2(10)) + 1):5.2f}" for e in range(1, 7)))
print("chart, log10 bits, pi program", " ".join(f"{log10(8 * pi_prog_bytes(10**e)):5.2f}" for e in range(1, 7)))
print("chart, log10 bits, true flips", " ".join(f"{float(e):5.2f}" for e in range(1, 7)))

assert pi_a == pi_b, "spigot and Machin roads must agree on every digit"
assert pi_a.startswith("31415926535897932384626433832795"), "published opening digits"
assert pi_a.find("999999") == 762, "the six 9s start at decimal place 762"
assert all(small[k] <= 2 ** (n - k) - 1 for k in range(5)), "counting bound"
assert E(patt) == 1 + 3 * 500000 and E(alt) == 1 + 1000000, "E by runs against E by formula"
assert abs(ones - F / 2) < 3 * (F ** 0.5) / 2, "flips within 3 standard errors of half"
print("ALL CHECKS PASS")
