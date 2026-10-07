# Geometric and negative binomial -- the check behind the card.  Standard library only.
# Rolling a fair die until the first six (X), and until the third six (T3).
# Roads: the formula; a count over all 6^6 sequences of six rolls; the masses summed
# term by term; the binomial count of sixes; a seeded simulation (SplitMix64).
from math import sqrt

p, q, M64 = 1.0 / 6.0, 5.0 / 6.0, (1 << 64) - 1

def pw(x, n):                        # x to the power n, by repeated multiplication
    out = 1.0
    for _ in range(n):
        out *= x
    return out
def comb(n, k):                      # C(n, k), exact in integers
    out = 1
    for j in range(1, k + 1):
        out = out * (n - k + j) // j
    return out
def geo(k):                          # P(X = k): k-1 misses, then a six
    return pw(q, k - 1) * p
def negbin(r, k):                    # P(T_r = k): r-1 sixes in the first k-1 rolls, then a six
    return comb(k - 1, r - 1) * pw(p, r) * pw(q, k - r) if k >= r else 0.0
def row(label, v): print(f"{label:<46}{v:>12.6f}")

# ---- road 1: the formula ----
for label, v in (("formula  P(X=1)", geo(1)), ("formula  P(X=5)", geo(5)),
                 ("formula  P(X>3)  no six in 3 rolls", pw(q, 3)),
                 ("formula  P(X<=4) a six within 4 rolls", 1.0 - pw(q, 4)),
                 ("formula  P(X<=6) a six within 6 rolls", 1.0 - pw(q, 6)),
                 ("formula  P(X>20) no six in 20 rolls", pw(q, 20)),
                 ("formula  E[X] = 1/p", 1.0 / p), ("formula  Var(X) = q/p^2", q / (p * p)),
                 ("formula  sd(X)", sqrt(q / (p * p))), ("formula  P(T3=5)", negbin(3, 5)),
                 ("formula  E[T3] = 3/p", 3.0 / p), ("formula  Var(T3) = 3q/p^2", 3.0 * q / (p * p)),
                 ("formula  sd(T3)", sqrt(3.0 * q / (p * p))),
                 ("formula  P(T3>3 | T3>2) = 1 - p^3", 1.0 - pw(p, 3))):
    row(label, v)

# ---- road 2: count every sequence of six rolls (6^6 = 46656, all equally likely) ----
first5 = third5 = none2 = none3 = none5 = 0
for code in range(6 ** 6):
    sixes, c = [], code
    for i in range(1, 7):
        if c % 6 == 5: sixes.append(i)
        c //= 6
    first = sixes[0] if sixes else 99
    first5 += first == 5
    third5 += len(sixes) >= 3 and sixes[2] == 5
    none2 += first > 2; none3 += first > 3; none5 += first > 5
print(f"{'count  of 46656 sequences, first six on roll 5':<46}{first5:>12d}")
print(f"{'count  of 46656 sequences, third six on roll 5':<46}{third5:>12d}")
row("count  P(X=5)", first5 / 46656)
row("count  P(T3=5)", third5 / 46656)
row("count  P(X>5 | X>2)", none5 / none2)
row("count  P(X>3)", none3 / 46656)

# ---- road 3: sum the masses term by term, out to roll 600 ----
tx = m1 = m2 = tt = t1 = t2 = 0.0
for k in range(1, 601):
    gx, gt = geo(k), negbin(3, k)
    tx += gx; m1 += k * gx; m2 += k * k * gx
    tt += gt; t1 += k * gt; t2 += k * k * gt
for label, v in (("series  total mass of X, rolls 1 to 600", tx), ("series  E[X]", m1), ("series  Var(X)", m2 - m1 * m1),
                 ("series  total mass of T3", tt), ("series  E[T3]", t1), ("series  Var(T3)", t2 - t1 * t1)):
    row(label, v)

# ---- road 4: the third six comes after roll n exactly when n rolls hold fewer than 3 sixes ----
tails = []
for n in (12, 18):
    by_binom = sum(comb(n, j) * pw(p, j) * pw(q, n - j) for j in range(3))
    by_mass = 1.0 - sum(negbin(3, k) for k in range(3, n + 1))
    row(f"binomial  P(fewer than 3 sixes in {n} rolls)", by_binom)
    row(f"negbin    P(T3 > {n})", by_mass)
    tails.append((by_binom, by_mass))

# ---- road 5: seeded simulation, SplitMix64 ----
state = 20260928
def die():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    z ^= z >> 31
    return ((z * 6) >> 64) + 1       # a face from 1 to 6
def wait_for(r):
    n = got = 0
    while got < r:
        n += 1
        if die() == 6: got += 1
    return n

def mean_se(s, s2, n): return s / n, sqrt((s2 - s * s / n) / (n - 1) / n)

N, NT = 200000, 100000
s = s2 = past4 = past7 = 0
for _ in range(N):
    x = wait_for(1)
    s += x; s2 += x * x; past4 += x > 4; past7 += x > 7
mx, sex = mean_se(s, s2, N)
frac = past7 / past4
se_frac = sqrt(frac * (1.0 - frac) / past4)
s = s2 = 0
for _ in range(NT):
    t = wait_for(3)
    s += t; s2 += t * t
mt, set3 = mean_se(s, s2, NT)
for label, v in (("sim  mean wait for first six, 200000 runs", mx), ("sim    standard error", sex),
                 ("sim  P(X>7 | X>4)", frac), ("sim    standard error", se_frac),
                 ("sim  mean wait for third six, 100000 runs", mt), ("sim    standard error", set3)):
    row(label, v)

# ---- what breaks ----
deal = sum((6 - j) / 6 for j in range(6))       # six cards, no replacement: P(the 6 not in first j)
for label, v in (("wrong: count misses only, mean q/p", q / p),
                 ("wrong: T3 as 3 copies of one wait, Var 9q/p^2", 9.0 * q / (p * p)),
                 ("wrong: deal 6 cards, mean draws to the 6", deal),
                 ("wrong: deal, P(6 next | 5 misses)", (1 / 6) / ((6 - 5) / 6)),
                 # ---- try changing ----
                 ("try: coin, p=1/2, mean", 1.0 / 0.5), ("try: coin, p=1/2, variance", 0.5 / (0.5 * 0.5)),
                 ("try: r=10 sixes, mean", 10.0 / p), ("try: r=10 sixes, sd", sqrt(10.0 * q / (p * p))),
                 ("try: p=1/100, mean", 1.0 / 0.01), ("try: p=1/100, sd", sqrt(0.99 / (0.01 * 0.01))),
                 ("house: emails 12/3600 a second, mean wait s", 1.0 / (12.0 / 3600.0))):
    row(label, v)

# ---- chart points, rolls 1 to 25 ----
print("chart, k       " + " ".join(f"{k:d}" for k in range(1, 26)))
print("chart, P(X=k)  " + " ".join(f"{geo(k):.4f}" for k in range(1, 26)))
print("chart, P(T3=k) " + " ".join(f"{negbin(3, k):.4f}" for k in range(1, 26)))

assert first5 == 5 ** 4 * 6, "count of sequences vs 4 misses, a six, any sixth roll"
assert abs(third5 / 46656 - negbin(3, 5)) < 1e-15, "count vs negative binomial mass"
assert abs(none5 / none2 - none3 / 46656) < 1e-15 and abs(none3 / 46656 - pw(q, 3)) < 1e-12, "memoryless and tail, by counting"
assert abs(m1 - 1.0 / p) < 1e-9 and abs(m2 - m1 * m1 - q / (p * p)) < 1e-9, "series mean and variance vs 1/p, q/p^2"
assert abs(t2 - t1 * t1 - 3.0 * q / (p * p)) < 1e-9, "series variance vs rq/p^2"
assert all(abs(a - b) < 1e-12 for a, b in tails), "binomial tail vs negative binomial tail"
assert abs(mx - 6.0) < 4 * sex, "simulated first-six wait within 4 standard errors"
assert abs(mt - 18.0) < 4 * set3, "simulated third-six wait within 4 standard errors"
assert abs(frac - 125 / 216) < 4 * se_frac, "simulated memorylessness vs (5/6)^3"
print("ALL CHECKS PASS")
