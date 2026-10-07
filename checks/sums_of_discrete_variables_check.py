# Sums of discrete variables -- the check behind the card.  Standard library only.
# Two help desks merged: billing gets 5 emails an hour on average, technical 7.
# Roads to the merged law: convolution, the closed form, moment generating
# functions, and a seeded simulation (SplitMix64, written out below).
from math import exp, log, sqrt

def pois(lam, K):                       # masses 0..K by the ratio p(k) = p(k-1) * lam / k
    p = [exp(-lam)]
    for k in range(1, K + 1):
        p.append(p[-1] * lam / k)
    return p

def pois_direct(lam, s):                # closed form through logs: e^-lam lam^s / s!
    return exp(-lam + s * log(lam) - sum(log(i) for i in range(2, s + 1)))

def conv(a, b):                         # P(X+Y=s) = sum over k of P(X=k) P(Y=s-k)
    out = [0.0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] += x * y
    return out

def binom(n, p):                        # C(n,k) by Pascal's rule, then the masses
    row = [1]
    for _ in range(n):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return [row[k] * p ** k * (1 - p) ** (n - k) for k in range(n + 1)]

def trials(n, p):                       # n one-email laws convolved one at a time
    law = [1.0]
    for _ in range(n):
        law = conv(law, [1 - p, p])
    return law

def mean_var(law):
    m = sum(k * q for k, q in enumerate(law))
    return m, sum((k - m) ** 2 * q for k, q in enumerate(law))

def mgf(law, t):                        # E[e^(tX)], summed term by term
    return sum(q * exp(t * k) for k, q in enumerate(law))

def gap(a, b):
    return max(abs(x - y) for x, y in zip(a, b))

def yn(c):
    return "yes" if c else "no"

K = 60
bill, tech = pois(5.0, K), pois(7.0, K)
merged = conv(bill, tech)[:K + 1]
print("road 1, convolution: merged total s = 12, billing's share k")
for k in range(13):
    print(f"  k={k:2d}  {bill[k]:.6f} x {tech[12 - k]:.6f} = {bill[k] * tech[12 - k]:.6f}")
closed = [pois_direct(12.0, s) for s in range(K + 1)]
tail_c, tail_f = 1 - sum(merged[:16]), 1 - sum(closed[:16])
print(f"convolution  P(S=12)        {merged[12]:.6f}   P(S>=16) {tail_c:.6f}")
print(f"road 2, closed form Poisson(12) {closed[12]:.6f}   P(S>=16) {tail_f:.6f}")
print(f"every s = 0..60 agrees to 1e-12: {yn(gap(merged, closed) < 1e-12)}")
m_prod, m_conv, m_form = mgf(bill, 0.5) * mgf(tech, 0.5), mgf(merged, 0.5), exp(12 * (exp(0.5) - 1))
print(f"road 3, MGF at t=0.5: product {m_prod:.6f}  of merged {m_conv:.6f}  formula {m_form:.6f}")
assert abs(merged[12] - closed[12]) < 1e-12
assert abs(tail_c - tail_f) < 1e-12
assert gap(merged, closed) < 1e-12
assert abs(m_prod - m_form) < 1e-9
assert abs(m_conv - m_form) < 1e-9

M64, state = (1 << 64) - 1, 20260928
def u01():                              # SplitMix64, top 53 bits as a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def draw(lam):                          # Knuth: multiply uniforms until below e^-lam
    L, k, p = exp(-lam), 0, u01()
    while p > L:
        k += 1
        p *= u01()
    return k

H, hit, over, tot, sq = 200000, 0, 0, 0, 0
for _ in range(H):
    s = draw(5.0) + draw(7.0)
    hit += s == 12; over += s >= 16; tot += s; sq += s * s
e12, eov = hit / H, over / H
se12, seov = sqrt(e12 * (1 - e12) / H), sqrt(eov * (1 - eov) / H)
sm = tot / H
print(f"road 4, simulation, seed 20260928, {H} hours")
print(f"  P(S=12) {e12:.6f} +- {se12:.6f}   P(S>=16) {eov:.6f} +- {seov:.6f}")
print(f"  mean {sm:.4f}   variance {sq / H - sm * sm:.4f}")
assert abs(e12 - closed[12]) < 4 * se12
assert abs(eov - tail_f) < 4 * seov

print("what breaks")
print(f"  only the 6 + 6 split           {bill[6] * tech[6]:.6f}")
print(f"  averaging the two laws at 12   {(bill[12] + tech[12]) / 2:.6f}")
def shock(a, b, c):                     # X = A + C, Y = B + C: C emails copied to both desks
    pc = pois(c, K)
    twice = [0.0] * (2 * K + 1)
    for i, q in enumerate(pc):
        twice[2 * i] = q
    return conv(conv(pois(a, K), pois(b, K)), twice)[:K + 1], conv(pois(a, K), pc)[:K + 1]
sh, marg = shock(3.0, 5.0, 2.0)
shm, shv = mean_var(sh)
print(f"  copied emails: billing still Poisson(5): {yn(gap(marg, bill) < 1e-12)}")
print(f"  copied emails  P(S=12) {sh[12]:.6f}   mean {shm:.4f}   variance {shv:.4f}")
assert gap(marg, bill) < 1e-12
assert abs(shv - (3 + 5 + 4 * 2)) < 1e-9
assert abs(sh[12] - closed[12]) > 0.005

mon, tue, both = binom(20, 0.7), binom(30, 0.7), binom(50, 0.7)
print("binomial: 20 then 30 replies, each resolves with chance 0.7")
print(f"  convolution P(T=35) {conv(mon, tue)[35]:.6f}   Binomial(50, 0.7) {both[35]:.6f}")
print(f"  50 one-email laws convolved {trials(50, 0.7)[35]:.6f}")
assert gap(conv(mon, tue), both) < 1e-12
assert gap(trials(50, 0.7), both) < 1e-12
mixed, pooled = conv(mon, binom(30, 0.5)), binom(50, 0.58)
mv, pv = mean_var(mixed)[1], mean_var(pooled)[1]
print(f"  chances 0.7 and 0.5: P(T=29) {mixed[29]:.6f}   variance {mv:.4f}")
print(f"  pooled Binomial(50, 0.58): P(T=29) {pooled[29]:.6f}   variance {pv:.4f}")
assert abs(mv - (20 * 0.7 * 0.3 + 30 * 0.25)) < 1e-9
assert abs(pv - mv) > 0.3

print("try changing")
print(f"  desks at 2 and 10: P(S=12) {conv(pois(2.0, K), pois(10.0, K))[12]:.6f}")
sh2 = shock(1.0, 3.0, 4.0)[0]
print(f"  copies Poisson(4), A 1, B 3: P(S=12) {sh2[12]:.6f}   variance {mean_var(sh2)[1]:.4f}")
print("chart, s = 0..24, merged:  " + " ".join(f"{merged[s]:.3f}" for s in range(25)))
print("chart, s = 0..24, copied:  " + " ".join(f"{sh[s]:.3f}" for s in range(25)))
