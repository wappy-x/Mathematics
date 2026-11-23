# Quantum advantage -- the check behind the card.  Standard library only: math
# gives sqrt, exp and log10; bisect finds a place in a sorted list.
# Part 1: what a hardware run on 15 really needs, and "factoring" by coin flip.
# Part 2: random circuits on 12 qubits and the cross-entropy test (XEB).
# Part 3: the 2019 claim and the 2022 classical answer, in numbers.
from bisect import bisect_right
from math import exp, log10, sqrt

def gcd(a, b):                                   # Euclid's algorithm, written out
    while b:
        a, b = b, a % b
    return a

def powmod(a, e, n):                             # square and multiply, wrapped at n
    r, a = 1, a % n
    while e:
        if e & 1:
            r = r * a % n
        a, e = a * a % n, e >> 1
    return r

def order(a, n):                                 # multiply until the powers return to 1
    r, x = 1, a % n
    while x != 1:
        x, r = x * a % n, r + 1
    return r

def tot(xs):                                     # plain left-to-right sum, as in Rust
    acc = 0.0
    for x in xs:
        acc += x
    return acc

def is_prime(m):                                 # trial division, an independent road
    d = 3
    while d * d <= m:
        if m % d == 0:
            return False
        d += 2
    return m == 2 or (m > 2 and m % 2 == 1)

print("Part 1: Shor's circuit for N = 15, base by base")
good = 0
for a in [b for b in range(2, 15) if gcd(b, 15) == 1]:
    r = order(a, 15)
    bits = r.bit_length() - 1                    # the oracle needs only the last log2(r) bits of x
    assert all(powmod(a, x, 15) == powmod(a, x % r, 15) for x in range(256))
    h = powmod(a, r // 2, 15)
    g1, g2 = gcd(h - 1, 15), gcd(h + 1, 15)
    good += g1 not in (1, 15)
    print(f"  a = {a:2}: period {r}, oracle uses the last {bits} bit(s) of x, gcds {g1} and {g2}{'  (fails)' if g1 == 1 else ''}")
t = (15 * 15 - 1).bit_length()
print(f"textbook circuit: {t} counting + 4 work = {t + 4} qubits; bases that split 15: {good} of 7")
print("quoted runs on 15: 2001 NMR, 7 qubits; 2016 ion trap, 7 qubits + 4 cache, success over 90%")
p, q = 2147483647, 4294967291                    # the answer, known before the run
N = p * q
a = 1 + p * ((q - 2) * powmod(p, q - 2, q) % q)  # a = 1 mod p and a = -1 mod q: built from the answer
s = 1 / sqrt(2)
v = [s, 0.0, s, 0.0]                             # index 2c + w; H on the counting qubit c
v[2], v[3] = v[3], v[2]                          # c = 1 multiplies by a: work bit w goes 1 -> a
v = [s * (v[0] + v[2]), s * (v[1] + v[3]), s * (v[0] - v[2]), s * (v[1] - v[3])]
pc = [v[0] * v[0] + v[1] * v[1], v[2] * v[2] + v[3] * v[3]]
g1, g2 = gcd(a - 1, N), gcd(a + 1, N)
print(f"pretend run, 2 qubits: N = {N}, a = {a}, a^2 mod N = {powmod(a, 2, N)}")
print(f"  counting qubit reads 0 with chance {pc[0]:.4f}, 1 with chance {pc[1]:.4f}: a fair coin")
print(f"  reading 1 gives 1/2, period 2: gcd(a - 1, N) = {g1}, gcd(a + 1, N) = {g2}, both prime by trial division: {'yes' if is_prime(g1) and is_prime(g2) else 'no'}")
assert powmod(a, 2, N) == 1 and a not in (1, N - 1) and g1 * g2 == N and is_prime(g1) and is_prime(g2)

M64 = (1 << 64) - 1
S = [20191023]
def rnd():                                       # SplitMix64, the same stream in Rust
    S[0] = (S[0] + 0x9E3779B97F4A7C15) & M64
    z = S[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)

n, D, CYC = 12, 1 << 12, 12                      # 12 qubits on a 3 by 4 grid, 12 cycles
G = [(complex(.5, .5), complex(.5, -.5), complex(.5, -.5), complex(.5, .5)),     # square root of X
     (complex(.5, .5), complex(-.5, -.5), complex(.5, .5), complex(.5, .5)),     # square root of Y
     (complex(s, 0), complex(-.5, -.5), complex(.5, -.5), complex(s, 0))]        # square root of W
PAIRS = [[(4 * r, 4 * r + 1) for r in range(3)] + [(4 * r + 2, 4 * r + 3) for r in range(3)],
         [(4 * r + 1, 4 * r + 2) for r in range(3)], [(c, 4 + c) for c in range(4)], [(4 + c, 8 + c) for c in range(4)]]
amp, prev, E = [complex(1, 0)] + [complex(0, 0)] * (D - 1), [3] * n, []
for cyc in range(CYC):
    for k in range(n):
        g = rnd() % 3 if prev[k] == 3 else (prev[k] + 1 + rnd() % 2) % 3
        prev[k], m, b = g, G[g], 1 << k
        for i in range(D):
            if not i & b:
                x, y = amp[i], amp[i | b]
                amp[i], amp[i | b] = m[0] * x + m[1] * y, m[2] * x + m[3] * y
    for (j, k) in PAIRS[cyc % 4]:                # controlled-Z: flip the sign when both qubits are 1
        for i in range(D):
            if i >> j & 1 and i >> k & 1:
                amp[i] = -amp[i]
    P = [z.real * z.real + z.imag * z.imag for z in amp]
    E.append(max(D * tot(x * x for x in P) - 1, 0.0))   # XEB a perfect device scores: 2^n sum p^2 - 1
print(f"Part 2: random circuit, {n} qubits, {CYC} cycles; total probability {tot(P):.4f}")
print("  exact XEB of a perfect device after each cycle: " + ", ".join(f"{e:.2f}" for e in E))
cdf, acc = [], 0.0
for x in P:
    acc += x
    cdf.append(acc)
def draw():                                      # one sample from the ideal distribution
    return min(bisect_right(cdf, (rnd() >> 11) / 9007199254740992), D - 1)
def device(f):                                   # right with chance f, else a uniform random string
    return draw() if (rnd() >> 11) / 9007199254740992 < f else rnd() % D
def xeb(xs):                                     # estimate and its standard error
    vals = [D * P[x] for x in xs]
    mu = tot(vals) / len(vals)
    var = tot((y - mu) * (y - mu) for y in vals) / (len(vals) - 1)
    return mu - 1, sqrt(var / len(vals))
K = 20000
res = {}
for name, f in [("perfect device", 1.0), ("noisy device, f = 0.05", 0.05), ("uniform guesser", 0.0), ("noisy device, f = 0.002", 0.002)]:
    res[f] = xeb([device(f) for _ in range(K)])
    print(f"  {name}, {K} samples: XEB {res[f][0]:.4f}, standard error {res[f][1]:.4f}, expected {f * E[-1]:.4f}")
share = sum(1 for x in P if D * x > 1) / D
print(f"  share of strings with 2^n p > 1: {share:.4f}; Porter-Thomas predicts exp(-1) = {exp(-1):.4f}")
for f in (1.0, 0.05, 0.0):
    assert abs(res[f][0] - f * E[-1]) < 5 * res[f][1]   # sampled XEB against the exact sum
assert abs(share - exp(-1)) < 0.03                    # Porter-Thomas shape against the exact list
assert E[0] < 1e-9 < E[1]                             # one layer of gates leaves every string equally likely
assert abs(tot(P) - 1) < 1e-9                         # the gates keep total probability 1

yr = 365.25 * 86400
claim, chip, gpu = 10000 * yr, 200, 15 * 3600
print("Part 3: the 2019 claim, 53 qubits, 20 cycles, a million samples")
print(f"  2^53 = {2 ** 53} amplitudes; at 8 bytes each {8 * 2 ** 53} bytes")
print(f"  claimed classical time / chip time: {claim / chip:.0f}; 2022 run, 512 GPUs: {gpu} s, {gpu / chip:.0f} times the chip")
for lab, sec in [("claim 2019, 10000 years", claim), ("classical 2022, 15 hours", gpu), ("chip 2019, 200 seconds", chip)]:
    print(f"  {lab:25} {'#' * round(2 * log10(sec)):24} log10 s = {log10(sec):.2f}")
se = 1 / sqrt(30e6)
print(f"  XEB 0.00224 from 30000000 samples: standard error {se:.6f}, {0.00224 / se:.1f} errors above 0")
print(f"  samples to see f = 0.002 at 5 errors: (5/0.002)^2 = {(5 / 0.002) * (5 / 0.002):.0f}")
print("  later claims, quoted: 2020 photons, up to 76 clicks, 1e14 times; 2024 sampling, 67 qubits, 32 cycles; 2025 sampling, 83 qubits, 32 cycles, 6.4e9 years")
print(f"  2025 claim, 65 qubits: 3.2 years / 2.1 hours = {3.2 * yr / (2.1 * 3600):.0f}; 2^65 amplitudes at 8 bytes = {8 * 2 ** 65} bytes")
print("ALL CHECKS PASS")
