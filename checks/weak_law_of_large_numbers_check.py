# The weak law of large numbers on a fair die: the check behind the card.
# Standard library only. Fraction for exact bounds; own dynamic program, minimiser and RNG.
import math
from fractions import Fraction as F

def f6(v): return f"{float(v):.6f}"
faces = range(1, 7)
mu = F(sum(faces), 6); var = F(sum(x * x for x in faces), 6) - mu * mu
eps, delta = F(1, 10), F(1, 100)
c = var / eps**2                                     # Chebyshev: P(miss by 0.1 or more) <= c / n
q = c / delta; N = -(-q.numerator // q.denominator)   # the smallest n with c / n <= delta
print(f"one roll: mean {f6(mu)}, variance {var} = {f6(var)}; margin 0.1, confidence 0.99")
print(f"Chebyshev: P(|average - 3.5| >= 0.1) <= {c} / n = {f6(c)} / n")
print(f"n = {N} gives {float(c / N):.8f}; n = {N - 1} gives {float(c / (N - 1)):.8f}")
assert c / N <= delta < c / (N - 1)
assert N % 2 == 1                                    # code guard: two dice per draw below need an odd N

# road 2: the exact law of the sum of n dice, one roll at a time (a sliding sum of six chances)
def step(p):
    new, w = [0.0] * (len(p) + 6), 0.0
    for s in range(len(new)):
        if 1 <= s <= len(p): w += p[s - 1]
        if s >= 7: w -= p[s - 7]
        new[s] = w / 6
    return new
def tail(p, n, k):                                   # P(|S/n - 3.5| >= 1/k), tested in whole numbers
    t = 0.0
    for s, ps in enumerate(p):
        if abs(2 * k * s - 7 * k * n) >= 2 * n: t += ps
    return t
p, ex = [1.0], {}
for n in range(1, 1001):
    p = step(p)
    if n % 100 == 0 or n == 295: ex[n] = tail(p, n, 10)
    if n == 15: ind15 = tail(p, 15, 1)
    if n == 4: ex4 = tail(p, 4, 4)
v1000 = 0.0
for s, ps in enumerate(p): v1000 += ps * (s / 1000 - 3.5) ** 2
print(f"exact law at n = 1000: variance of the average {v1000:.9f}, formula 35/12/1000 = {float(var / 1000):.9f}")
assert abs(v1000 - float(var) / 1000) < 1e-12

# road 3: the Chernoff bound, 2 * exp(n * min over t of [log M(t) - 3.6 t]), M(t) = average of e^(t k)
def gss(f, lo, hi):
    g = (math.sqrt(5) - 1) / 2
    for _ in range(100):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) < f(b): hi = b
        else: lo = a
    return (lo + hi) / 2
def logm(t):
    m = 0.0
    for k in faces: m += math.exp(t * k)
    return math.log(m / 6)
t = gss(lambda t: logm(t) - 3.6 * t, 0.0, 5.0); r = logm(t) - 3.6 * t
print(f"Chernoff: best t {t:.6f}, exponent per roll {r:.9f}")
print("n, Chebyshev bound, exact P(miss), Chernoff bound")
for n in range(100, 1001, 100):
    ch = 2 * math.exp(n * r)
    print(f"  {n}, {f6(c / n)}, {f6(ex[n])}, {f6(ch)}")
    assert ex[n] <= min(1.0, float(c / n)) and ex[n] <= ch
print("chart, Chebyshev capped at 1:", " ".join(f"{min(1.0, float(c / n)):.2f}" for n in range(100, 1001, 100)))
print("chart, exact:", " ".join(f"{ex[n]:.2f}" for n in range(100, 1001, 100)))
print(f"at n = {N}: Chebyshev {float(c / N):.8f}, Chernoff {2 * math.exp(N * r):.3e}")

# road 4: simulate 1000 runs of N rolls; SplitMix64, seed 20260929, two dice per 64-bit draw
st, MASK, R = 20260929, (1 << 64) - 1, 1000
fails = 0; ss = worst = 0.0
for _ in range(R):
    tot = 0
    for j in range(N // 2 + 1):
        st = (st + 0x9E3779B97F4A7C15) & MASK; z = st
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK; z ^= z >> 31
        tot += ((z >> 32) * 6 >> 32) + 1
        if j < N // 2: tot += ((z & 0xFFFFFFFF) * 6 >> 32) + 1
    d = tot / N - 3.5; ss += d * d; worst = max(worst, abs(d)); fails += abs(10 * tot - 35 * N) >= N
rms, sd = math.sqrt(ss / R), math.sqrt(float(var) / N)
print(f"simulated, {R} runs of {N} rolls: misses {fails}; largest |average - 3.5| {worst:.6f}")
print(f"root-mean-square miss {rms:.6f}; theory sqrt(35/12/{N}) = {sd:.6f}")
assert fails == 0 and abs(rms - sd) < 4 * sd / math.sqrt(2 * R)

# pairwise independent faces: 4 real dice x_i in 0..5 give 15 faces, (sum of a subset mod 6) + 1
outs = []
for code in range(6**4):
    x = [code // 6**i % 6 for i in range(4)]
    outs.append([sum(x[i] for i in range(4) if m >> i & 1) % 6 + 1 for m in range(1, 16)])
pairs_ok = True
for a in range(15):
    for b in range(a + 1, 15):
        cnt = [0] * 36
        for f in outs: cnt[6 * (f[a] - 1) + f[b] - 1] += 1
        pairs_ok = pairs_ok and cnt == [36] * 36
T = [sum(f) for f in outs]
v15 = F(sum((2 * s - 105)**2 for s in T), 900 * 6**4)
t15 = F(sum(abs(2 * s - 105) >= 30 for s in T), 6**4)
trip = F(sum(f[0] == f[1] == f[2] == 1 for f in outs), 6**4)
e4 = F(sum(abs(4 * (f[0] + f[1] + f[3] + f[7]) - 56) >= 4 for f in outs), 6**4)   # faces 1, 2, 4, 8 are the dice
print(f"exact law checked by listing 4 dice: P(|average - 3.5| >= 0.25) = {e4} = {f6(e4)}; dynamic program {f6(ex4)}")
assert abs(float(e4) - ex4) < 1e-12
print(f"15 faces from 4 dice: every pair uniform on 36 outcomes: {'yes' if pairs_ok else 'no'}")
print(f"  faces 1, 2 and 1+2 all show 1 with chance {trip} (independent faces: 1/216)")
print(f"  variance of the average {v15}, formula (35/12)/15 = {var / 15}")
print(f"  P(|average - 3.5| >= 1): {f6(t15)}; 15 independent dice {f6(ind15)}; Chebyshev {f6(var / 15)}")
assert pairs_ok and trip == F(1, 36) and v15 == var / 15 and t15 <= var / 15

# finite mean, infinite variance: Pareto P(X > x) = x^-1.5 on x >= 1, mean 3, margin 0.5
def tb(n): return n**-0.5 + 12 * (math.sqrt(n) - 1) / (n * 0.25)
print("truncation bound n^-0.5 + 12(sqrt(n) - 1)/(0.25 n):", ", ".join(f"n = 10^{k}: {tb(10**k):.6f}" for k in (4, 6, 8)))
n2, R2 = 10**4, 200; f2 = big = 0
for _ in range(R2):
    tot = 0.0; top = 0.0
    for _ in range(n2):
        st = (st + 0x9E3779B97F4A7C15) & MASK; z = st
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK; z ^= z >> 31
        xv = (1.0 - (z >> 11) / 2.0**53) ** (-2 / 3); tot += xv; top = max(top, xv)
    f2 += abs(tot / n2 - 3) >= 0.5; big += top > n2
print(f"simulated, {R2} runs of {n2} Pareto draws: misses {f2}; runs with a draw above n {big} (bound n^-0.5 = 0.01)")
assert f2 / R2 <= tb(n2)

# what breaks
cop = F(sum(abs(10 * x - 35) >= 1 for x in faces), 6)
n_sd = math.ceil(math.sqrt(float(var)) / float(delta * eps**2)); n_1d = math.ceil(float(c / (1 - delta)))
print(f"breaks: every roll a copy of the first: P(miss) {f6(cop)} at every n; variance of the average {f6(var)}")
print(f"breaks: standard deviation for variance: n = {n_sd}, Chebyshev there {f6(c / n_sd)}")
print(f"breaks: 1 - delta for delta: n = {n_1d}, Chebyshev there {f6(c / n_1d)}, exact P(miss) {f6(ex[295])}")
assert cop == 1 and c / n_sd > delta and n_1d == 295 and ex[295] > delta
