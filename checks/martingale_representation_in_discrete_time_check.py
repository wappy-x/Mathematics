# Representing a martingale -- the check behind the card.  Only sqrt is imported.
# A share starts at $100 and moves $10 up (heads, +1) or down (tails, -1) on each
# of 3 days; fair coin, no interest.  Any payoff V on the 8 paths is shown to be
# M_0 + sum of H_k (S_k - S_(k-1)), each stake H_k fixed the day before.  Roads:
# backward recursion, direct averages over completions, the Walsh expansion of V
# in the coin signs, and a seeded simulation (SplitMix64, written out).
from math import sqrt
MASK = (1 << 64) - 1

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

DAYS, S0, STEP = 3, 100.0, 10.0

def paths(moves, n=DAYS):                  # every sequence of n moves, first move slowest
    out = [()]
    for _ in range(n): out = [w + (m,) for w in out for m in moves]
    return out

def name(w): return "".join("H" if e > 0 else ("T" if e < 0 else "0") for e in w) or "start"
def price(w): return S0 + STEP * sum(w)
def sign(w, S):                            # product of the coin signs picked out by S
    r = 1
    for e, s in zip(w, S): r *= e if s else 1
    return r
W2, W3 = paths((1, -1)), paths((1, 0, -1))

def recurse(V, moves=(1, -1), p=0.5):      # road 1: backward; stake = best fit to the moves
    M, H = dict(V), {}
    wt = {1: p, -1: 1 - p} if len(moves) == 2 else {m: 1 / len(moves) for m in moves}
    for n in range(DAYS - 1, -1, -1):
        for w in paths(moves, n):
            M[w] = sum(wt[m] * M[w + (m,)] for m in moves)
            H[w] = sum(m * (M[w + (m,)] - M[w]) for m in moves) / (STEP * sum(m * m for m in moves))
    return M, H

def direct(V, w):                          # road 2: average V over every way to finish
    ends = [v for x, v in V.items() if x[:len(w)] == w]
    return sum(ends) / len(ends)

def walsh(V):                              # road 3: V = sum over S of c_S x product of signs
    c = {S: sum(V[w] * sign(w, S) for w in W2) / len(W2) for S in paths((0, 1))}
    H = {w: sum(cS * sign(w, S) for S, cS in c.items() if S[n] == 1 and sum(S[n + 1:]) == 0) / STEP
         for n in range(DAYS) for w in paths((1, -1), n)}
    return c[(0,) * DAYS], H

def replay(V, M0, H): return {w: M0 + sum(H[w[:k]] * STEP * w[k] for k in range(DAYS)) for w in V}
call = {w: max(price(w) - 100.0, 0.0) for w in W2}
M, H = recurse(call)
m0, HW = walsh(call)
print(f"share ${S0:.0f}, up or down ${STEP:.0f} a day for {DAYS} days, fair coin, {len(W2)} paths")
print("call, strike 100, payoff: " + ", ".join(f"{name(w)} {call[w]:.0f}" for w in W2))
print("node: price, value M backward | direct average, stake H backward | Walsh")
for n in range(DAYS):
    for w in paths((1, -1), n):
        print(f"node {name(w)}: {price(w):.0f}, M {M[w]:.6f} | {direct(call, w):.6f}, H {H[w]:.6f} | {HW[w]:.6f}")
        assert M[w] == direct(call, w), "backward value vs direct average"
        assert H[w] == HW[w], "backward stake vs Walsh stake"
print(f"cash at the start = M - H x price = {M[()] - H[()] * S0:.6f}; Walsh start value {m0:.6f}")
R = replay(call, M[()], H)
for w in W2:
    g = [H[w[:k]] * STEP * w[k] + 0.0 for k in range(DAYS)]
    print(f"replay {name(w)}: {M[()]:.2f} " + " ".join(f"{x:+.2f}" for x in g) + f" = {R[w]:.2f}, payoff {call[w]:.2f}")
    assert R[w] == call[w], "the strategy must end at the payoff on every path"

look = {w: max(price(w[:k]) for k in range(DAYS + 1)) - 100.0 for w in W2}
LM, LH = recurse(look)
l0, LW = walsh(look)
print("lookback, highest price - 100, payoff: " + ", ".join(f"{name(w)} {look[w]:.0f}" for w in W2))
print(f"lookback: price {LM[()]:.6f} (direct {direct(look, ()):.6f}, Walsh {l0:.6f}); "
      f"stake after HT {LH[(1, -1)]:.6f}, after TH {LH[(-1, 1)]:.6f}")
assert max(abs(replay(look, LM[()], LH)[w] - look[w]) for w in W2) < 1e-12, "lookback replicated"
assert LW == LH, "lookback stakes: Walsh vs backward"
PH = dict(LH)
PH[(1, -1)] = PH[(-1, 1)] = (LH[(1, -1)] + LH[(-1, 1)]) / 2   # one stake per price, not per history
PR = replay(look, LM[()], PH)
print(f"break, lookback with one stake {PH[(1, -1)]:.6f} at price 100 on day 2, error: " + ", ".join(f"{name(w)} {PR[w] - look[w] + 0.0:+.2f}" for w in W2))
assert sorted(round(abs(PR[w] - look[w]), 9) for w in W2) == [0.0] * 4 + [STEP / 4] * 4, "one stake per price misses 4 paths by STEP / 4"

def works(V):
    M, H = recurse(V)
    m0, HW = walsh(V)
    R = replay(V, M[()], H)
    return (max(abs(R[w] - V[w]) for w in W2) < 1e-9, abs(m0 - M[()]) < 1e-12 and max(abs(HW[w] - H[w]) for w in H) < 1e-12)

rng = SplitMix64(20260929)
for label, res in (("every 0/1 payoff, 256", [works({w: float((i >> j) & 1) for j, w in enumerate(W2)}) for i in range(256)]),
                   ("random payoffs -50..50, 1000", [works({w: float(rng.next() % 101) - 50.0 for w in W2}) for _ in range(1000)])):
    print(f"{label}: replicated {sum(a for a, b in res)}, Walsh agrees {sum(b for a, b in res)}")
    assert all(a and b for a, b in res), "every payoff is a strategy, by both roads"

N, s, s2, worst = 100000, 0.0, 0.0, 0.0
for _ in range(N):
    w = tuple(1 if rng.next() >> 63 else -1 for _ in range(DAYS))
    s, s2 = s + call[w], s2 + call[w] * call[w]
    worst = max(worst, abs(R[w] - call[w]))
mean, sd = s / N, sqrt(s2 / N - (s / N) ** 2)
print(f"simulated {N} paths: mean payoff {mean:.4f} +/- {sd / sqrt(N):.4f} (exact {M[()]:.4f})")
print(f"  unhedged seller sd {sd:.4f}; hedged seller worst error {worst:.4f}")
assert abs(mean - M[()]) < 4 * sd / sqrt(N), "simulated mean within 4 standard errors"

BM, BH = recurse(call, p=0.6)
enum = sum(0.6 ** w.count(1) * 0.4 ** w.count(-1) * call[w] for w in W2)
BR = replay(call, BM[()], BH)
bl = [BR[w] - call[w] for w in W2]
print(f"break, averaging with chance 0.6 of an up day: {BM[()]:.6f} (enumerated {enum:.6f})")
print(f"  its own stakes overshoot by {min(bl):.2f} to {max(bl):.2f}; the fair hedge costs {M[()]:.2f}")
assert abs(BM[()] - enum) < 1e-12, "recursion vs weighted enumeration at chance 0.6"
assert min(bl) > 0.1, "averages at 0.6 are no representation against the share"

heads = {w: float(w.count(1)) for n in range(DAYS + 1) for w in paths((1, -1), n)}  # drifts up 0.5 a day
HH = {w: (heads[w + (1,)] - heads[w + (-1,)]) / (2 * STEP) for w in heads if len(w) < DAYS}
HR = replay({w: heads[w] for w in W2}, 0.0, HH)
left = {heads[w] - HR[w] for w in W2}
print(f"break, count of heads: left over after {DAYS} days {min(left):.6f} to {max(left):.6f} (days / 2 = {DAYS / 2:.6f})")
assert left == {DAYS / 2}, "the unrepresented part is the drift, 0.5 a day"

tcall = {w: max(price(w) - 100.0, 0.0) for w in W3}
TM, TH = recurse(tcall, moves=(1, 0, -1))
TR = replay(tcall, TM[()], TH)
err = [TR[w] - tcall[w] for w in W3]
vsd = sqrt(sum((tcall[w] - TM[()]) * (tcall[w] - TM[()]) for w in W3) / len(W3))
esd = sqrt(sum(e * e for e in err) / len(W3))
print(f"break, three moves a day: {len(W3)} paths, {1 + 1 + 3 + 9} numbers to choose; "
      f"price {TM[()]:.6f} (direct {direct(tcall, ()):.6f})")
print(f"  best hedge misses on {sum(abs(e) > 1e-9 for e in err)} paths; leftover sd {esd:.6f} against unhedged {vsd:.6f}")
assert abs(TM[()] - direct(tcall, ())) < 1e-12, "trinomial price by two roads"
assert 0.5 < esd < vsd, "hedging helps but cannot finish the job"

for d in range(DAYS + 1):
    print(f"figure, day {d}, (price) -> (x, y): " + ", ".join(
        f"({S0 + STEP * (d - 2 * j):.0f}) -> ({40 + 95 * d}, {124 - 2.7 * STEP * (d - 2 * j):.0f})" for j in range(d + 1)))
print("ALL CHECKS PASS")
