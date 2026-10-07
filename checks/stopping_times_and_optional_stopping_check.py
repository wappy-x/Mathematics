# Stopping times and optional stopping -- the check behind the card.  Standard library only.
# A fair game at 1 dollar a round.  The rule: quit the first time 5 dollars ahead,
# and stop at round 100 whatever happens.  Three roads to the answer: exact path
# counts carried round by round, the reflection principle, a seeded simulation.
from math import comb, log, exp, sqrt

A, N = 5, 100                                  # target in dollars, deadline in rounds
MASK = (1 << 64) - 1

def splitmix(s):                               # SplitMix64: new state and 64 random bits
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, z ^ (z >> 31)

def dp(N, one, half):
    # Road 1: carry the weight of every path still playing; fortune f sits at index f + N + 1.
    w = [0 * one] * (N + A + 3); w[N + 1] = one
    hit, hits, possum, alive = 0 * one, [], [], []
    for n in range(N + 1):
        if n > 0:
            w = [0 * one] + [half(w[i - 1] + w[i + 1]) for i in range(1, N + A + 2)] + [0 * one]
            hit += w[N + A + 1]; w[N + A + 1] = 0 * one        # reached +A: quits, leaves the board
        hits.append(hit)
        possum.append(sum((i - N - 1) * w[i] for i in range(N + A + 3)))
        alive.append(sum(w))
    sq = A * A * hit + sum((i - N - 1) ** 2 * w[i] for i in range(N + A + 3))
    return hits, possum, alive, sq

def reflect(N):
    # Road 2: a path that touched +A and ends at s mirrors to one ending at 2A - s.
    end = lambda s: comb(N, (N + s) // 2) if (N + s) % 2 == 0 and -N <= s <= N else 0
    hit = sum((2 if s > A else 1) * end(s) for s in range(A, N + 1))
    lose = [(s, end(s) - end(2 * A - s)) for s in range(-N, A)]
    return hit, sum(s * c for s, c in lose), sum(s * s * c for s, c in lose)

def reflect_float(N):                          # the same mirror, in floating point, for long games
    lc, pmf = 0.0, []
    for k in range(N + 1):
        pmf.append(exp(lc - N * log(2.0)))
        if k < N: lc += log(N - k) - log(k + 1)
    end = lambda s: pmf[(N + s) // 2] if (N + s) % 2 == 0 and -N <= s <= N else 0.0
    p = sum((2.0 if s > A else 1.0) * end(s) for s in range(A, N + 1))
    return p, sum(s * (end(s) - end(2 * A - s)) for s in range(-N, A))

T = 1 << N
hits, possum, alive, sq = dp(N, T, lambda x: x // 2)
h2, lsum2, lsq2 = reflect(N)
assert hits[N] == h2                                           # road 1 = road 2, exact integers
assert all(A * hits[n] + possum[n] == 0 for n in range(N + 1))  # E[S at min(n, tau)] = 0 at every n
assert A * h2 + lsum2 == 0                                      # E[S_tau] = 0 by the mirror count
assert sum(alive[:N]) == A * A * h2 + lsq2                     # E[tau] = E[S_tau^2]
assert sq == A * A * h2 + lsq2                                  # road 1 = road 2 for E[S_tau^2]
p = hits[N] / T
print(f"rule: quit at +{A} dollars, deadline {N} rounds, 1 dollar a round")
print(f"P(quit {A} up)  exact path counts   {p:.6f}")
print(f"P(quit {A} up)  reflection          {h2 / T:.6f}")
print(f"E[S_tau]  exact path counts       {(A * hits[N] + possum[N]) / T:.6f}")
print(f"E[S_tau]  reflection              {(A * h2 + lsum2) / T:.6f}")
print(f"E[S_min(n,tau)] = 0 at rounds 0..{N}: {sum(A * hits[n] + possum[n] == 0 for n in range(N + 1))} of {N + 1}")
print(f"P(still playing at round {N})     {alive[N] / T:.6f}")
print(f"losers' mean at round {N}          {possum[N] / alive[N]:.6f}")
print(f"E[tau] rounds, from survival       {sum(alive[:N]) / T:.6f}")
print(f"E[S_tau^2], from final fortunes    {sq / T:.6f}")
print("chart, round       " + " ".join(f"{n:6d}" for n in range(0, N + 1, 10)))
print("chart, quitters    " + " ".join(f"{A * hits[n] / T:6.2f}" for n in range(0, N + 1, 10)))
print("chart, players     " + " ".join(f"{possum[n] / T:6.2f}" for n in range(0, N + 1, 10)))

# Road 3: simulation.  Player j draws 128 bits; bit n-1 is round n (1 = win a dollar).
P, seed = 100000, 20260929
s, g, g2, nh, pk, pk2, fig = seed, 0, 0, 0, 0, 0, None
for j in range(P):
    s, b1 = splitmix(s); s, b2 = splitmix(s)
    bits, x, y, tau, lead, path, free = b1 | (b2 << 64), 0, 0, N, N, [0], [0]
    for n in range(1, N + 1):
        up = (bits >> (n - 1)) & 1
        if not up and lead == N: lead = n - 1                # peek rule: stop before the first loss
        y += 1 if up else -1
        if tau == N and x != A: x = y
        if x == A and tau == N: tau = n
        path.append(x); free.append(y)
    g += x; g2 += x * x; nh += x == A; pk += lead; pk2 += lead * lead
    if fig is None and 20 <= tau <= 40: fig = (j, tau, path[:51], free[:51])
m, ph, mp = g / P, nh / P, pk / P
se, seh, sep = sqrt((g2 / P - m * m) / P), sqrt(ph * (1 - ph) / P), sqrt((pk2 / P - mp * mp) / P)
assert abs(m) < 4 * se
assert abs(ph - p) < 4 * seh
print(f"simulation, {P} players, seed {seed}")
print(f"P(quit {A} up)  simulated           {ph:.6f}  se {seh:.6f}")
print(f"E[S_tau]  simulated               {m:.6f}  se {se:.6f}")

print(f"no deadline: N, P(quit {A} up by N), losers' mean, theorem's -{A}p/(1-p)")
for M in (100, 1000, 10000, 100000):
    pf, lf = reflect_float(M)
    assert abs(lf / (1 - pf) + A * pf / (1 - pf)) < 1e-9 * (1 + A * pf / (1 - pf))
    print(f"  {M:6d}  {pf:.6f}  {lf / (1 - pf):11.4f}  {-A * pf / (1 - pf):11.4f}")
hf, pf_, af, _ = dp(1000, 1.0, lambda x: 0.5 * x)
assert abs(hf[1000] - reflect_float(1000)[0]) < 1e-12
print(f"  1000 by path weights: P(quit {A} up) {hf[1000]:.6f}, losers' mean {pf_[1000] / af[1000]:.4f}")

exact_peek = 1 - 2.0 ** -N
assert abs(mp - exact_peek) < 4 * sep
print(f"peek rule (quit before the first loss): simulated {mp:.6f} se {sep:.6f}, exact {exact_peek:.6f}")
K, tot, ruin = 10, 0, 0                         # doubling, stakes 1, 2, 4, ... for at most K rounds
for mask in range(1 << K):
    gain, stake = 0, 1
    for n in range(K):
        if (mask >> n) & 1: gain += stake; break
        gain -= stake; stake *= 2
    tot += gain; ruin += gain < 0
assert tot == 0                                 # capped doubling: mean gain 0
assert ruin == 1
print(f"doubling, {K} rounds: P(win 1) {1 - ruin / 2 ** K:.6f}, P(lose {2 ** K - 1}) {ruin / 2 ** K:.6f} (1 in {2 ** K}), mean {tot / 2 ** K:.6f}")
print(f"figure, player {fig[0]} quits at round {fig[1]}")
print("figure, fortune  " + " ".join(str(v) for v in fig[3]))
print("figure, stopped  " + " ".join(str(v) for v in fig[2]))
