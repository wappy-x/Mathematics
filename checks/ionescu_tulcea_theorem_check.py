# The Ionescu-Tulcea theorem -- the check behind the card.  Standard library only.
# Roads: (1) compose the urn's kernels step by step, in exact fractions;
# (2) the same chances as an integral over a uniform share p, by Simpson's rule;
# (3) build the draws from uniform numbers (SplitMix64, seed 20261123) and count.
from fractions import Fraction as Fr
from itertools import product
def urn(past, colour):                       # kernel: chance the next draw is `colour`
    red = Fr(1 + sum(past), len(past) + 2)   # 1 = red, 0 = black
    return red if colour == 1 else 1 - red
def sticky(past, colour, stay=Fr(4, 5), switch=Fr(1, 5)):
    if not past:
        return Fr(1, 2)
    return stay if colour == past[-1] else switch
def compose(law, kernel):                    # P_{n+1}(x, y) = P_n(x) * kernel(x, y)
    return {x + (y,): p * kernel(x, y) for x, p in law.items() for y in (0, 1)}
def laws(kernel, n):                         # P_1, ..., P_n
    out, law = [], {(): Fr(1)}
    for _ in range(n):
        law = compose(law, kernel)
        out.append(law)
    return out
def word(x): return "".join("R" if c else "B" for c in x)
# ---- road 1: kernels composed, exact ----
P = laws(urn, 10)
print("urn kernel after R:   P(R) = %s, P(B) = %s" % (urn((1,), 1), urn((1,), 0)))
print("urn kernel after R,R: P(R) = %s, P(B) = %s" % (urn((1, 1), 1), urn((1, 1), 0)))
rrr = P[2][(1, 1, 1)]
print("P(R, R, R) = 1/2 x 2/3 x 3/4 =", rrr, "=", f"{float(rrr):.6f}")
assert rrr == Fr(1, 2) * Fr(2, 3) * Fr(3, 4)
pasts = [()] + [x for n in (1, 2) for x in sorted(P[n - 1], reverse=True)]
print("tree, P(next R) after each past:", ", ".join(f"{word(x) or 'start'} {urn(x, 1)}" for x in pasts))
print("tree, three draws:", ", ".join(f"{word(x)} {p}" for x, p in sorted(P[2].items(), reverse=True)))
print(f"consistency at R,R: P(RRR) + P(RRB) = {rrr} + {P[2][(1, 1, 0)]} = {rrr + P[2][(1, 1, 0)]} = P(RR)")
for n in range(1, 10):                       # consistency: sum out the last draw
    for x, p in P[n - 1].items():
        assert P[n][x + (0,)] + P[n][x + (1,)] == p
    assert sum(P[n].values()) == 1
print("urn laws consistent for n = 1 to 10: yes; total of every law = 1")
for n in (3, 10):
    counts = [sum(p for x, p in P[n - 1].items() if sum(x) == k) for k in range(n + 1)]
    assert all(c == Fr(1, n + 1) for c in counts)
    print(f"number of reds in {n} draws: each of 0..{n} has chance {counts[0]}")
print("order does not matter: P(RRB) = %s, P(RBR) = %s, P(BRR) = %s"
      % (P[2][(1, 1, 0)], P[2][(1, 0, 1)], P[2][(0, 1, 1)]))
h1 = {1: urn((1,), 1) * urn((1, 1), 1), 0: Fr(0)}   # chance of R,R,R given the first draw
h0 = sum(urn((), c) * h1[c] for c in (1, 0))
print(f"proof's h for event RRR: h1(R) = {h1[1]}, h1(B) = 0, h0 = 1/2 x {h1[1]} = {h0}")
assert h0 == rrr
S = laws(sticky, 10)
for n in range(1, 10):
    for x, p in S[n - 1].items():
        assert S[n][x + (0,)] + S[n][x + (1,)] == p
hhh = S[2][(1, 1, 1)]
print("sticky coin: P(H, H, H) = 0.5 x 0.8 x 0.8 =", f"{float(hhh):.2f}" + "; consistent to n = 10: yes")
assert hhh == Fr(8, 25)
# ---- road 2: a uniform share p, then independent draws with chance p ----
def pw(q, k):                                # q to the power k, by repeated multiplying
    out = 1.0
    for _ in range(k):
        out *= q
    return out
def simpson(f, m=1000):
    h = 1.0 / m
    s = f(0.0) + f(1.0) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, m))
    return s * h / 3
worst = 0.0
for n in range(1, 9):
    for x in product((0, 1), repeat=n):
        k = sum(x)
        v = simpson(lambda q: pw(q, k) * pw(1 - q, n - k))
        worst = max(worst, abs(v - float(P[n - 1][x])))
assert worst < 1e-9
print(f"all 510 patterns of 1 to 8 draws: kernel product = integral of p^k (1-p)^(n-k); largest gap {worst:.0e}")
print(f"integral of p^3 over 0..1 = {simpson(lambda q: pw(q, 3)):.6f}")
# ---- what breaks ----
indep = Fr(1, 2) ** 3
print(f"draws treated as independent halves: P(RRR) = {float(indep):.6f}, not {float(rrr):.6f}")
B = laws(lambda x, y: sticky(x, y, Fr(4, 5), Fr(3, 10)), 3)
print(f"kernel weights 0.8 + 0.3 = 1.1: P_2(HH) = {float(B[1][(1, 1)]):.2f},"
      f" P_3 summed over toss 3 = {float(B[2][(1, 1, 1)] + B[2][(1, 1, 0)]):.2f}, total of P_3 = {float(sum(B[2].values())):.2f}")
assert B[2][(1, 1, 1)] + B[2][(1, 1, 0)] != B[1][(1, 1)]
mk = laws(lambda x, y: urn(x[-1:], y), 3)[2][(1, 1, 1)]   # "Markov" misreading: the kernel sees the last draw only
print(f"kernel that sees only the last draw: P(RRR) = 1/2 x 2/3 x 2/3 = {float(mk):.6f}, not {float(rrr):.6f}")
assert mk != rrr
from math import comb
cnt = {0: Fr(1)}                             # the kernel composed on the count of reds, 100 draws
for n in range(100):
    nxt = dict.fromkeys(range(n + 2), Fr(0))
    for r, p in cnt.items():
        for y in (0, 1):
            nxt[r + y] += p * urn((1,) * r + (0,) * (n - r), y)
    cnt = nxt
urn25 = sum(cnt[r] for r in range(26))
assert urn25 == Fr(26, 101)                  # Step 6: each count from 0 to 100 has chance 1/101
coin25 = Fr(sum(comb(100, k) for k in range(26)), 2 ** 100)
print(f"at most 25 reds in 100 draws: urn {urn25} = {float(urn25):.6f}, the kernel composed 100 times; fair coin {float(coin25) * 1e7:.2f} x 10^-7")
assert coin25 < Fr(1, 10 ** 6)
# ---- road 3: the draws built from uniform numbers ----
M = (1 << 64) - 1
state = 20261123
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
def urn_run(n):                              # draw n+1 is red when U < (1 + reds) / (n + 2)
    reds = 0
    for i in range(n):
        if uniform() < (1 + reds) / (i + 2):
            reds += 1
    return reds
runs = 200000
hits = sum(urn_run(3) == 3 for _ in range(runs))
est, se = hits / runs, (0.25 * 0.75 / runs) ** 0.5
print(f"simulated urn, {runs} runs: P(RRR) = {est:.6f}; exact 0.250000; standard error {se:.6f}")
assert abs(est - 0.25) < 4 * se
long_runs = 20000
low = sum(urn_run(100) <= 25 for _ in range(long_runs))
est2 = low / long_runs
se2 = (float(urn25) * (1 - float(urn25)) / long_runs) ** 0.5
print(f"simulated urn, {long_runs} runs of 100 draws: P(at most 25 reds) = {est2:.6f};"
      f" exact {float(urn25):.6f}; standard error {se2:.6f}")
assert abs(est2 - float(urn25)) < 4 * se2
hh = 0
for _ in range(runs):
    t1 = uniform() < 0.5
    t2 = t1 if uniform() < 0.8 else not t1
    t3 = t2 if uniform() < 0.8 else not t2
    hh += t1 and t2 and t3
est3, se3 = hh / runs, (0.32 * 0.68 / runs) ** 0.5
print(f"simulated sticky coin, {runs} runs: P(HHH) = {est3:.6f}; exact 0.320000; standard error {se3:.6f}")
assert abs(est3 - 0.32) < 4 * se3
print("ALL CHECKS PASS")
