# Typical sequences -- the check behind the card.  Standard library only: math
# for log2 and sqrt.  A weather station sends one reading a day: sunny (chance
# 1/2), cloudy (1/4), rain (1/8) or snow (1/8), days independent.  A record is
# N = 1,000 readings.  Surprise of one reading: s = -log2 p, so 1, 2, 3, 3 bits.
# Typical set: the records whose surprise per day is within EPS of H.
from math import log2, sqrt
P, S = [1/2, 1/4, 1/8, 1/8], [1, 2, 3, 3]
N, EPS = 1000, 0.05
H = sum(p * s for p, s in zip(P, S))                    # entropy: mean surprise
H2 = sum(-p * log2(p) for p in P)                       # the same, from the chances
MS = sum(p * s * s for p, s in zip(P, S))              # mean square of one surprise
VAR = MS - H * H                                        # its variance

def typical(L, n):      # total surprise L bits over n days: |L/n - 1.75| <= 0.05
    return abs(20 * L - 35 * n) <= n                    # whole numbers, no rounding

def lse(xs):            # log2 of a sum of 2^x, without overflow
    m = max(xs)
    return m + log2(sum(2 ** (x - m) for x in xs))

def smallest(dist, share):  # most likely records first (L upward), the last level in part
    acc, L, logs = 0.0, 0, []
    while acc + dist[L] < share:
        if dist[L] > 0: acc += dist[L]; logs.append(log2(dist[L]) + L)
        L += 1
    return lse(logs + [log2(share - acc) + L])    # (share - acc) x 2^L records of level L

# Road 1: the law of a record's total surprise, built one day at a time.
# dist[L] = chance the total is L bits.  Every record with total L has chance
# exactly 2^-L, so the number of records with total L is dist[L] * 2^L.
dist, by_n = [1.0], {}
for n in range(1, N + 1):
    new = [0.0] * (len(dist) + 3)
    for L, v in enumerate(dist):
        new[L + 1] += v / 2; new[L + 2] += v / 4; new[L + 3] += v / 4
    dist = new
    if n % 100 == 0 or n == 8:
        inA = [L for L in range(len(dist)) if typical(L, n)]
        by_n[n] = (sum(dist[L] for L in inA), lse([log2(dist[L]) + L for L in inA]),
                   smallest(dist, 0.95), dist)
pA, logA, log95, _ = by_n[N]
mL = sum(L * v for L, v in enumerate(dist))             # mean and variance of the
vL = sum(L * L * v for L, v in enumerate(dist)) - mL * mL  # total, from the law itself

# Road 2: count records by type: a sunny, b cloudy, c wet (rain or snow) days.
# N!/(a! b! c!) orders, times 2^c ways to make each wet day rain or snow.
lf = [0.0]
for k in range(1, N + 1): lf.append(lf[-1] + log2(k))
terms, pA2 = [], 0.0
for b in range(N + 1):
    for c in range(N - b + 1):
        L = N + b + 2 * c
        if typical(L, N):
            lc = lf[N] - lf[N - b - c] - lf[b] - lf[c] + c
            terms.append(lc); pA2 += 2 ** (lc - L)
logA2 = lse(terms)

# Road 3: every record of 8 days, all 65,536 of them, listed and tested.
cnt8, p8 = 0, 0.0
for code in range(4 ** 8):
    L, pr = 0, 1.0
    for _ in range(8):
        L += S[code % 4]; pr *= P[code % 4]; code //= 4
    if typical(L, 8): cnt8 += 1; p8 += pr
pA8, logA8 = by_n[8][0], by_n[8][1]

# Road 4: simulate 2,000 records of 1,000 days with SplitMix64, seed 2026.
state, MASK = 2026, (1 << 64) - 1
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
COST = [1, 1, 1, 1, 2, 2, 3, 3]     # top 3 bits: 4 of 8 sunny, 2 cloudy, 1 rain, 1 snow
RUNS, hits, tot = 2000, 0, 0
for _ in range(RUNS):
    L = sum(COST[splitmix() >> 61] for _ in range(N))
    hits += typical(L, N); tot += L
sim, se = hits / RUNS, sqrt(pA * (1 - pA) / RUNS)

# The converse: the most likely records, up to 2^(N(H - 2 EPS)) of them.
room, logs, held = N * (H - 2 * EPS), [], 0.0
for L in range(len(dist)):
    if dist[L] > 0:
        if lse(logs + [log2(dist[L]) + L]) > room:   # fill up from this total's records
            held += 2 ** (room - L) - 2 ** (lse(logs) - L); break
        logs.append(log2(dist[L]) + L); held += dist[L]
promise = 2 ** (-N * EPS) + 1 - pA
cheb = 1 - VAR / (N * EPS * EPS)
lab = int(logA) + 1                 # whole bits to number every typical record
code = (1 + lab) * pA + (1 + 2 * N) * (1 - pA)      # flag bit, then label or raw
sunny, stuck = N * S[0], sum(P[k] for k in range(4) if typical(N * S[k], N))  # all sunny; day 1 repeated

print(f"surprises {S} bits; entropy H = {H:.4f} = {H2:.4f} bits a day; "
      f"mean square {MS:.4f}, variance {VAR:.4f}")
print(f"records of {N} days: 4^{N} = 2^{2 * N}; typical window {H - EPS:.2f} to {H + EPS:.2f} bits a day,"
      f" chance 2^-{N * (H + EPS):.0f} to 2^-{N * (H - EPS):.0f}")
print(f"centre record, 500 sunny 250 cloudy 125 rain 125 snow: {500 * 1 + 250 * 2 + 250 * 3} bits")
print(f"chance a record is typical, road 1 (day by day): {pA:.4f}")
print(f"chance a record is typical, road 2 (by type):    {pA2:.4f}")
print(f"chance a record is typical, road 4 (2,000 runs): {sim:.4f}, standard error {se:.4f}")
print(f"mean surprise per day over the 2,000 runs: {tot / (RUNS * N):.4f}")
print(f"Chebyshev: miss at most {VAR:.4f}/({N} x {EPS}^2) = {1 - cheb:.4f}, floor {cheb:.4f}")
print(f"log2 of the typical set's size, road 1: {logA:.2f}; road 2: {logA2:.2f}")
print(f"bounds: {log2(pA) + N * (H - EPS):.2f} <= log2 size <= {N * (H + EPS):.2f}")
print(f"typical share of all records: 2^{logA - 2 * N:.1f}")
print(f"8 days: {4 ** 8} listed, {cnt8} typical (total {7 * 8 // 4} bits), chance {p8:.4f}; "
      f"road 1: 2^{logA8:.4f} = {2 ** logA8:.1f}, chance {pA8:.4f}")
print(f"code: 1 flag bit + {lab}-bit label, else 1 + {2 * N} raw bits: "
      f"{code:.1f} bits on average, {code / N:.4f} a day")
print(f"smallest set holding 95%: log2 size {log95:.2f}, {log95 / N:.4f} bits a day")
print(f"most likely 2^{room:.0f} records hold {held:.6f}; "
      f"promise at most 2^-{N * EPS:.0f} + {1 - pA:.4f} = {promise:.4f}")
print(f"mistake, all-sunny record: chance 2^-{sunny}, {sunny / N:.2f} bits a day, "
      f"typical: {'yes' if typical(sunny, N) else 'no'}")
print(f"mistake, stuck station: {S[0]:.2f}, {S[1]:.2f} or {S[2]:.2f} bits a day, typical chance {stuck:.4f}")
print(f"mistake, natural log: {H * 0.6931471805599453:.4f} a day, 2^{N * H * 0.6931471805599453:.0f}; "
      f"2^{N * H:.0f} read as the count: "
      f"short by 2^{logA - N * H:.1f}")
print("chance by surprise per day, bins centred 1.50, 1.55, ..., 2.00:")
for n in (100, 1000):
    dd = by_n[n][3]
    row = [sum(dd[L] for L in range(len(dd)) if (2 * k - 1) * n <= 40 * L < (2 * k + 1) * n)
           for k in range(30, 41)]
    print(f"n = {n}: " + ", ".join(f"{x:.3f}" for x in row))
print("n, chance typical, Chebyshev floor, bits a day: typical set, smallest 95% set")
for n in range(100, N + 1, 100):
    t = by_n[n]
    print(f"{n}, {t[0]:.4f}, {max(0.0, 1 - VAR / (n * EPS * EPS)):.4f}, {t[1] / n:.4f}, {t[2] / n:.4f}")

assert S == [-log2(p) for p in P] and abs(H - H2) < 1e-12        # surprise table is right
assert abs(mL / N - H) < 1e-9 and abs(vL / N - VAR) < 1e-9        # mean and variance add up
assert abs(pA - pA2) < 1e-9 and abs(logA - logA2) < 1e-6          # road 1 meets road 2
assert cnt8 == round(2 ** logA8) and abs(p8 - pA8) < 1e-12        # road 1 meets the list
assert abs(sim - pA) < 4 * se                                     # road 4, the simulation
assert cheb <= pA and log2(pA) + N * (H - EPS) <= logA <= N * (H + EPS)   # the theorem's bounds
assert held <= promise and log95 < logA                           # the converse
assert not typical(sunny, N) and stuck == 0                       # broken hypotheses: not typical
print("ALL CHECKS PASS")
