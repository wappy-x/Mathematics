# Channel capacity -- the check behind the card.  Standard library only: no function imported from
# math knows what capacity is.  A radio link sends 1000 bits a second and flips 1 bit in every 100.
from math import log2, sqrt, exp, cos, log, pi, comb, log10, prod

P, BITS_PER_S, LOG_BITS = 0.01, 1000, 86400 * 16  # flip chance; link speed; a day's log
B = 500.0                                 # channel width in hertz: 2B = 1000 pulses a second
MASK = (1 << 64) - 1
def splitmix64(s):                        # small seeded generator, written out
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, z ^ (z >> 31)
def uniform(s):                           # a number in (0, 1]
    s, z = splitmix64(s)
    return s, ((z >> 11) + 1) / 2.0**53

def h(p):                                 # binary entropy, in bits
    return 0.0 if p <= 0 or p >= 1 else -p * log2(p) - (1 - p) * log2(1 - p)
def mutual_info(q, p):                    # I(X;Y) straight from the joint table
    px = [1 - q, q]
    joint = [[px[x] * ((1 - p) if x == y else p) for y in (0, 1)] for x in (0, 1)]
    py = [joint[0][y] + joint[1][y] for y in (0, 1)]
    return sum(joint[x][y] * log2(joint[x][y] / (px[x] * py[y]))
               for x in (0, 1) for y in (0, 1) if joint[x][y] > 0)

# road 1: the formula; road 2: search all input mixes; road 3: send synthetic bits
C = 1 - h(P)
best_I, best_q = -1.0, -1.0
for i in range(1001):
    v = mutual_info(i / 1000, P)
    if v > best_I:
        best_I, best_q = v, i / 1000
s, N_SIM, count = 2026, 200000, [[0, 0], [0, 0]]
for _ in range(N_SIM):
    s, z = splitmix64(s)
    x = z >> 63                            # a fair random bit
    s, u = uniform(s)
    count[x][x ^ (1 if u <= P else 0)] += 1
flips_sim = (count[0][1] + count[1][0]) / N_SIM
I_sim = 0.0
for x in (0, 1):
    for y in (0, 1):
        pxy, pxs, pys = count[x][y] / N_SIM, sum(count[x]) / N_SIM, (count[0][y] + count[1][y]) / N_SIM
        I_sim += pxy * log2(pxy / (pxs * pys)) if pxy > 0 else 0.0

def rep_error(r, p):                      # majority vote over r copies: more than half flipped
    return sum(comb(r, k) * p**k * (1 - p)**(r - k) for k in range(r // 2 + 1, r + 1))
def best_decoder_error(cols, n, m, p):    # exact block error when the decoder always picks the
    seen, left, ok, w = [False] * (1 << m), 1 << m, 0.0, 0   # fewest flips that explain the output
    while left:
        x = (1 << w) - 1                  # every n-bit flip pattern with w flips, in turn
        while x < (1 << n):
            syn, y, i = 0, x, 0
            while y:
                if y & 1:
                    syn ^= cols[i]
                y, i = y >> 1, i + 1
            if not seen[syn]:
                seen[syn], left, ok = True, left - 1, ok + p**w * (1 - p)**(n - w)
            if x == 0:
                break
            c = x & -x; r = x + c
            x = (((r ^ x) >> 2) // c) | r
        w += 1
    return 1 - ok
rep3_brute = best_decoder_error([3, 1, 2], 3, 2, P)            # repetition codes, written as
rep5_brute = best_decoder_error([15, 1, 2, 4, 8], 5, 4, P)     # parity checks
rand_err, sc = {}, 2026
for n in (8, 16, 24):                     # random rate-1/2 codes: n/2 message bits, n/2 checks
    m, cols = n // 2, []
    for _ in range(n // 2):
        sc, z = splitmix64(sc)
        cols.append(z & ((1 << m) - 1))
    rand_err[n] = best_decoder_error(cols + [1 << j for j in range(m)], n, m, P)

def phi(t): return exp(-t * t / 2) / sqrt(2 * pi)
def Phi(x, k=2000):                       # bell-curve area left of x, by Simpson's rule
    hh = x / k
    tot = phi(0) + phi(x) + sum((4 if j % 2 else 2) * phi(j * hh) for j in range(1, k))
    return 0.5 + tot * hh / 3
def Phi_series(x):                        # second road, no integral: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    return 0.5 + phi(x) * sum(x ** (2 * j + 1) / prod(range(1, 2 * j + 2, 2)) for j in range(60))
lo, hi = 0.0, 10.0                        # pulse height a, in noise spreads, with Phi(-a) = P
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if Phi(-mid) > P else (lo, mid)
a = (lo + hi) / 2; snr = a * a
def diff_entropy(var, k=4000):            # -integral of f log2 f for a normal, by Simpson
    sd = sqrt(var); L = 12 * sd; hh = 2 * L / k
    f = lambda y: exp(-y * y / (2 * var)) / sqrt(2 * pi * var)
    g = lambda y: -f(y) * log2(f(y))
    return (g(-L) + g(L) + sum((4 if j % 2 else 2) * g(-L + j * hh) for j in range(1, k))) * hh / 3
per_pulse = 0.5 * log2(1 + snr)
per_pulse_num = diff_entropy(1 + snr) - diff_entropy(1.0)
neg, sg = 0, 7
for _ in range(N_SIM):                    # send +a, add normal noise (Box-Muller), read the sign
    sg, u1 = uniform(sg)
    sg, u2 = uniform(sg)
    neg += 1 if a + sqrt(-2 * log(u1)) * cos(2 * pi * u2) < 0 else 0
se = sqrt(P * (1 - P) / N_SIM)
fano = lambda R, n: 1 - C / R - (1 / (n * R) if n else 0.0)

rows = [("flip chance p", P), ("  0.01 x log2(100)", P * log2(1 / P)), ("  0.99 x log2(1/0.99)", (1 - P) * log2(1 / (1 - P))),
        ("h(p), bits of noise per bit", h(P)), ("1 formula C = 1 - h(p)", C), ("2 best I(X;Y) over 1001 input mixes", best_I), ("  at input chance q", best_q),
        ("3 simulated flip rate, 200000 bits", flips_sim), ("  simulated I(X;Y)", I_sim),
        ("capacity, bits a second", C * BITS_PER_S), ("day's log, bits", LOG_BITS),
        ("plain: minutes", LOG_BITS / BITS_PER_S / 60), ("plain: wrong bits expected", LOG_BITS * P),
        ("triple: minutes", 3 * LOG_BITS / BITS_PER_S / 60), ("triple: wrong bits expected", LOG_BITS * rep_error(3, P)),
        ("five-fold: minutes", 5 * LOG_BITS / BITS_PER_S / 60), ("five-fold: wrong bits expected", LOG_BITS * rep_error(5, P)),
        ("capacity: fewest minutes", LOG_BITS / (C * BITS_PER_S) / 60),
        ("triple vote error, formula", rep_error(3, P)), ("  by best decoder", rep3_brute),
        ("five-fold vote error, formula", rep_error(5, P)), ("  by best decoder", rep5_brute),
        ("12 bits sent plain, block error", 1 - (1 - P)**12),
        ("12 bits tripled (36 sent), block error", 1 - (1 - rep_error(3, P))**12),
        ("random code n=8, 4 bits, block error", rand_err[8]), ("random code n=16, 8 bits", rand_err[16]),
        ("random code n=24, 12 bits", rand_err[24]),
        ("n=1000: n h(p), log2 likely patterns", 1000 * h(P)), ("  log2 C(1000,10)", sum(log2((1000 - i) / (i + 1)) for i in range(10))),
        ("  n C, log2 codewords", 1000 * C), ("Fano floor, R=0.95, long blocks", fano(0.95, 0)),
        ("  R=0.95, n=1000", fano(0.95, 1000)), ("Gauss: a, height in noise spreads", a),
        ("  Phi(-a), by Simpson", Phi(-a)), ("  Phi(-a), by series", Phi_series(-a)), ("  simulated flip rate", neg / N_SIM), ("  S/N", snr), ("  S/N in dB", 10 * log10(snr)),
        ("  per pulse, 1/2 log2(1+S/N)", per_pulse), ("  per pulse, by entropies", per_pulse_num),
        ("  Shannon-Hartley, B=500 Hz", B * log2(1 + snr)), ("  sign only: 1000 x C", 1000 * C),
        ("wrong: C = 1 - p", 1 - P), ("wrong: natural log", 1 - (-P * log(P) - (1 - P) * log(1 - P))),
        ("wrong: S/N in dB in the formula", B * log2(1 + 10 * log10(snr))),
        ("try: p = 0.1", 1 - h(0.1)), ("try: p = 0.5", 1 - h(0.5)), ("try: p = 0.99", 1 - h(0.99)),
        ("try: S/N doubled", B * log2(1 + 2 * snr)), ("try: B doubled, same power", 2 * B * log2(1 + snr / 2))]
for name, v in rows:
    print(f"{name:<40} {v:>17.9f}")
print("chart, C at p = 0, 0.05, ..., 0.5:", " ".join(f"{1 - h(j / 20):.3f}" for j in range(11)))

assert abs(best_I - C) < 1e-9 and best_q == 0.5           # search lands on the formula
assert abs(flips_sim - P) < 4 * se and abs(I_sim - C) < 0.01
assert abs(rep3_brute - rep_error(3, P)) < 1e-12 and abs(rep5_brute - rep_error(5, P)) < 1e-12
assert rand_err[8] > rand_err[16] > rand_err[24]            # longer blocks, same rate, fewer errors
assert rand_err[24] < 1 - (1 - rep_error(3, P))**12         # beats tripling, at a higher rate
assert abs(Phi(-a) - Phi_series(-a)) < 1e-9 and abs(neg / N_SIM - P) < 4 * se   # two roads to the bell area
assert abs(per_pulse_num - per_pulse) < 1e-6
assert C < per_pulse and fano(0.95, 0) > 0                   # reading the sign loses information
print("ALL CHECKS PASS")
