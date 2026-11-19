# Erdos-Kac -- the check behind the card.  Standard library only.
# omega(n), the number of distinct primes dividing n, is built for every n up
# to a million as a literal sum of prime indicators: each prime adds 1 to each
# of its multiples.  Roads: the sieve's histogram against prime powers (the sum
# of floor(N/p) only checks the sieve's ranges); the low primes' histogram
# against an independent-indicator model; the limit law simulated with a
# SplitMix64 generator against exact Poisson sums and the bell Phi.
import math
N, Y, D, SEED = 10**6, 100, 20_000, 2026
isp = bytearray([1]) * (N + 1); isp[0] = isp[1] = 0
for i in range(2, 1001):
    if isp[i]:
        for j in range(i * i, N + 1, i): isp[j] = 0
primes = [p for p in range(2, N + 1) if isp[p]]
w, low = [0] * (N + 1), [0] * (N + 1)            # all primes; primes <= Y only
for p in primes:
    for m in range(p, N + 1, p):
        w[m] += 1
        if p <= Y: low[m] += 1
def com(n): return f"{n:,}"
def Phi(z):                                      # the bell's area left of z
    return tail(-z) if z < -3 else 1 - tail(z) if z > 3 else ser(z)
def ser(z):                                      # Taylor series of the bell's area
    t, s, k = z, z, 0
    while abs(t) > 1e-17:
        k += 1; t *= -z * z * (2 * k - 1) / (2 * k * (2 * k + 1)); s += t
    return 0.5 + s / math.sqrt(2 * math.pi)
def tail(z):                                     # area right of z > 3: continued fraction
    f = z
    for k in range(80, 0, -1): f = z + k / f
    return math.exp(-z * z / 2) / math.sqrt(2 * math.pi) / f
L = math.log(math.log(N)); s = math.sqrt(L)
H = [0] * 8
for n in range(1, N + 1): H[w[n]] += 1
pp = sum(1 for p in primes for k in range(1, 20) if p ** k <= N)   # prime powers
print(f"n <= {com(N)}: {com(len(primes))} primes; log N = {math.log(N):.4f}, L = log log N = {L:.4f},"
      f" sqrt L = {s:.4f}")
for n in (999_999, N, 510_510):
    print(f"{com(n)}: primes {', '.join(str(p) for p in primes if n % p == 0)}; omega {w[n]}")
print("omega | count   | share  | bell   | bars: # = 10,000 integers (true, then bell)")
bell = []
for k in range(8):
    lo = 0.0 if k == 0 else Phi((k - 0.5 - L) / s)
    bell.append(round(N * (Phi((k + 0.5 - L) / s) - lo)))
    print(f"{k}     | {H[k]:>7,} | {H[k] / N:.4f} | {bell[k] / N:.4f} | "
          f"{'#' * round(H[k] / 1e4):<38}|{'#' * round(bell[k] / 1e4)}")
S1 = sum(w[1:]); S2 = sum(v * v for v in w[1:]); mu = S1 / N; var = S2 / N - mu * mu
print(f"omega = 1 count {com(H[1])}; prime powers {com(pp)} = {com(len(primes))} primes + "
      f"{pp - len(primes)} higher powers")
print(f"sum of omega {com(S1)}, sum of floor(N/p) {com(sum(N // p for p in primes))}")
sp = 0.0
for p in primes: sp += 1 / p
print(f"mean {mu:.4f} (bell {L:.4f}, gap {mu - L:.4f}; sum of 1/p {sp:.4f}), variance {var:.4f}")
print("Erdos-Kac form, n from 3 to N, z_n = (omega(n) - log log n) / sqrt(log log n):")
for z in (-1.0, 0.0, 1.0):
    c = sum(1 for n in range(3, N + 1)
            if w[n] - math.log(math.log(n)) <= z * math.sqrt(math.log(math.log(n))))
    print(f"share with z_n <= {z:+.0f}: {c / (N - 2):.4f}; bell Phi({z:+.0f}) = {Phi(z):.4f}")
print("x     | mean   | variance | L = log log x")
for k in range(2, 7):
    x = 10 ** k; a1 = sum(w[1:x + 1]); a2 = sum(v * v for v in w[1:x + 1])
    m = a1 / x; v2 = a2 / x - m * m
    print(f"10^{k}  | {m:.4f} | {v2:.4f}   | {math.log(math.log(x)):.4f}")
small = [p for p in primes if p <= Y]
model = [1.0]                                    # independent indicators, chance 1/p each
for p in small:
    nxt = [0.0] * (len(model) + 1)
    for k, q in enumerate(model):
        nxt[k] += q * (1 - 1 / p); nxt[k + 1] += q / p
    model = nxt
HL = [0] * 8
for n in range(1, N + 1): HL[low[n]] += 1
gap = max(abs(HL[k] / N - model[k]) for k in range(8))
print(f"primes <= {Y} ({len(small)} of them): k | true share | independent model")
for k in range(6): print(f"  {k} | {HL[k] / N:.4f} | {model[k]:.4f}")
print(f"largest gap over k = 0..7: {gap:.4f}")
big = [w[n] - low[n] for n in range(1, N + 1)]
rb, rv = 0.0, 0.0
for p in primes:
    if p > Y: rb += 1 / p; rv += (1 / p) * (1 - 1 / p)
bm = sum(big) / N; bv = sum(b * b for b in big) / N - bm * bm
print(f"primes > {Y}: mean count {bm:.4f}, model {rb:.4f}; variance {bv:.4f}, model {rv:.4f}")
print(f"primes > {Y}: most in one n {max(big)}, since {Y + 1}^3 = {com((Y + 1) ** 3)} > N")
indep = 0.0
for p in primes: indep += (1 / p) * (1 - 1 / p)
for name, lx in (("10^9", 9), ("10^80", 80), ("2^2048", 2048 * math.log(2) / math.log(10))):
    print(f"log log {name} = {math.log(lx * math.log(10)):.4f}")
for t in (L, 10.0, 100.0):
    d = math.exp(t) / math.log(10); e = math.floor(math.log10(d)); wall = (1 - t) / math.sqrt(t)
    dd = com(round(d)) if e < 6 else f"{d / 10 ** e:.2f} x 10^{e}"
    print(f"L = {t:.2f}: log10 x = {dd}; omega = 1 sits at z = {wall:.4f};"
          f" bell area below it {Phi(wall):.4f}")
st = SEED
def u01():                                       # SplitMix64, top 53 bits
    global st
    st = (st + 0x9E3779B97F4A7C15) & (2**64 - 1); z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2**53
print(f"limit law: model count with mean L, {com(D)} draws each (seed {SEED})")
print("L      | sim share <= L | exact  | sim largest gap to bell | exact  | 1/sqrt L")
worst, gaps = 0.0, []
for lam in (L, 10.0, 100.0):
    xs = []
    for _ in range(D):
        k, prod, lim = 0, u01(), math.exp(-lam)
        while prod > lim: k += 1; prod *= u01()
        xs.append(k)
    cnt = [0] * (max(xs) + 1)
    for x in xs: cnt[x] += 1
    pk, F, G, ge, gs, e0, j = math.exp(-lam), 0.0, 0, 0.0, 0.0, 0.0, 0
    while j < 10 * lam + 60:                     # exact Poisson staircase against the bell
        b0 = Phi((j - lam) / math.sqrt(lam)); ge = max(ge, abs(F - b0))
        gs = max(gs, abs(G / D - b0)); F += pk; G += cnt[j] if j < len(cnt) else 0
        ge = max(ge, abs(F - b0)); gs = max(gs, abs(G / D - b0))
        if j <= lam: e0 = F
        j += 1; pk *= lam / j
    a0 = sum(1 for x in xs if x <= lam) / D
    worst = max(worst, abs(a0 - e0) / math.sqrt(e0 * (1 - e0) / D))
    gaps.append(ge * math.sqrt(lam))
    print(f"{lam:<6.2f} | {a0:.4f}         | {e0:.4f} | {gs:.4f}                  | {ge:.4f} |"
          f" {1 / math.sqrt(lam):.4f}")
print(f"exact gap x sqrt L: {', '.join(f'{g:.4f}' for g in gaps)}; worst simulated miss "
      f"{worst:.2f} standard errors")
print(f"mistake 1, bell read as a count: omega <= 0 (z <= {(0.5 - L) / s:.4f}) for {com(bell[0])}"
      f" integers, true {H[0]}")
print(f"mistake 2, base-10 logs: centre {math.log10(6):.4f} against {L:.4f}")
pz = sum(1 for p in primes[1:] if 1 - math.log(math.log(p)) <= 0)
print(f"mistake 3, primes only: z_n <= 0 for {com(pz)} of {com(len(primes) - 1)} odd primes,"
      f" share {pz / (len(primes) - 1):.4f}, bell 0.5000")
print(f"mistake 4, every prime independent: variance {indep:.4f} against {var:.4f}")
assert S1 == sum(N // p for p in primes) and H[1] == pp and H[0] == 1
assert len(primes) == 78498 and sum(H) == N                 # pi(10^6), known table
assert gap < 0.01 and max(big) == 2 and (Y + 1) ** 3 > N   # near-independence
assert abs(ser(3.5) - 1 + tail(3.5)) < 1e-12 and abs(ser(-3.5) - tail(3.5)) < 1e-12  # Phi, 2 roads
assert abs(Phi(1.3) - 0.5 * (1 + math.erf(1.3 / math.sqrt(2)))) < 1e-12  # erf: cross-check only
assert worst < 4 and max(gaps) < 2 * min(gaps) and abs(var - L) > 1  # rate; lopsided
print("ALL CHECKS PASS")
