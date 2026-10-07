# Reflection principle for the fair walk -- the check behind the card.  Standard library only.
# A gambler holds 10 chips and bets 1 chip a round at fair odds.  Does the pile reach 15 within 20 rounds?
# Road 1: the reflection formula, from binomial counts.  Road 2: all 2^20 paths, walked out one by one.
# Road 3: a seeded simulation (SplitMix64, written out).  Road 4: a round-by-round recursion, which also
# prices the cases where the mirror does not apply.
from math import comb, sqrt

N, X0, L = 20, 10, 15                   # rounds, starting chips, target
A = L - X0                              # gap to the target: 5 chips

def tail(n, x, p=0.5):                  # P(X_n >= x), counting wins h: X_n = X0 + 2h - n
    return sum(comb(n, h) * p ** h * (1 - p) ** (n - h) for h in range(n + 1) if X0 + 2 * h - n >= x)
def p_end(n, x):                        # P(X_n = x) for the fair walk
    h2 = x - X0 + n
    return comb(n, h2 // 2) / 2 ** n if h2 % 2 == 0 and 0 <= h2 <= 2 * n else 0.0
def reach(n, level, p=0.5):             # the reflection principle: P(M_n >= level) = P(X_n >= level) + P(X_n > level)
    return tail(n, level, p) + tail(n, level + 1, p)
def recursion(n, level, p=0.5, floor=None):   # carry the chance forward a round at a time; stop at level (and floor)
    lo = X0 - n - 1 if floor is None else floor
    w = [0.0] * (level - lo + 1); w[X0 - lo] = 1.0; hit = 0.0
    for _ in range(n):
        new = [0.0] * len(w)
        for i in range(1, len(w) - 1):
            new[i + 1] += p * w[i]; new[i - 1] += (1 - p) * w[i]
        hit += new[-1]; new[-1] = 0.0; new[0] = 0.0
        w = new
    return hit

# ---- road 2: every path.  Bit i of w set = the gambler wins round i+1 ----
first = [0] * (N + 1)                   # first[t]: paths whose first visit to 15 is round t
touched_end, end_count, max_count = {}, {}, {}
for w in range(1 << N):
    x, top, t = X0, X0, 0
    for i in range(N):
        x += 1 if w >> i & 1 else -1
        if x > top: top = x
        if x == L and not t: t = i + 1
    end_count[x] = end_count.get(x, 0) + 1
    max_count[top] = max_count.get(top, 0) + 1
    if t:
        first[t] += 1
        touched_end[x] = touched_end.get(x, 0) + 1
reach_count = sum(first)
mirror_levels = [b for b in range(0, L) if touched_end.get(b, 0) == end_count.get(2 * L - b, 0)]

# ---- road 3: simulation.  One 64-bit draw per game; its top 20 bits are the 20 rounds ----
MASK = (1 << 64) - 1
state, games, hits = 20260929, 200000, 0
for _ in range(games):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    x = X0
    for i in range(N):
        x += 1 if z >> (63 - i) & 1 else -1
        if x == L: hits += 1; break
p_sim = hits / games
se = sqrt(p_sim * (1 - p_sim) / games)

p_form = reach(N, L)
rows = [
    ("paths in 20 rounds", 2 ** N), ("paths ending at 15 or more", sum(comb(N, h) for h in range(13, N + 1))),
    ("paths touching 15, counted", reach_count),
    ("paths touching 15, 2 x C(20,13..20)", 2 * sum(comb(N, h) for h in range(13, N + 1))),
]
for name, v in rows: print(f"{name:<40} {v:>12d}")
rows = [
    ("1 reflection formula", p_form), ("2 all paths", reach_count / 2 ** N),
    ("3 simulation, 200000 games", p_sim), ("  standard error", se),
    ("4 recursion, broke at 0 ends play", recursion(N, L, floor=0)),
    ("P(5 <= X_20 <= 14), by counting ends", sum(p_end(N, x) for x in range(X0 - A, L))),
    ("wrong: count only ends >= 15", tail(N, L)),
    ("wrong: gap 4, 2 x P(X_20 >= 14)", 2 * tail(N, 14)), ("  right, gap 4", reach(N, 14)),
    ("wrong: mirror at p = 18/38", reach(N, L, 18 / 38)), ("  right, recursion at p = 18/38", recursion(N, L, 18 / 38)),
    ("wrong: mirror, 100 rounds, no floor", reach(100, L)), ("  right, 100 rounds, broke at 0", recursion(100, L, floor=0)),
    ("try: target 11", reach(N, 11)), ("try: target 20", reach(N, 20)), ("try: 24 rounds", reach(24, L)),
]
for name, v in rows: print(f"{name:<40} {v:>12.6f}")
print(f"mirror check: touch 15 and end at b, versus end at 30 - b: equal at {len(mirror_levels)} of 15 ends b = 0..14")
print(f"end b = 12: {touched_end[12]} paths touch 15 and end at 12; {end_count[18]} paths end at 18")
print("first passage  round   all paths   (5/n) P(X_n = 15)")
for n in range(A, N, 2):
    print(f"{'':<15}{n:>5}   {first[n] / 2 ** N:.6f}    {A / n * p_end(n, L):.6f}")
print(f"ballot, 19 rounds: {comb(19, 12)} paths end at 15, {first[19] // 2} first reach it at round 19")
ms = range(X0, X0 + 15)
print("chart, best pile m      " + " ".join(f"{m:>6d}" for m in ms))
print("chart, P(M_20 = m) %    " + " ".join(f"{100 * (p_end(N, m) + p_end(N, m + 1)):6.2f}" for m in ms))
print("chart, counted %        " + " ".join(f"{100 * max_count.get(m, 0) / 2 ** N:6.2f}" for m in ms))
print("chart, rounds n         " + " ".join(f"{n:>6d}" for n in range(N + 1)))
print("chart, P(M_n >= 15) %   " + " ".join(f"{100 * reach(n, L):6.2f}" for n in range(N + 1)))
print("chart, counted %        " + " ".join(f"{100 * sum(first[:n + 1]) / 2 ** N:6.2f}" for n in range(N + 1)))
print("chart, P(X_n >= 15) %   " + " ".join(f"{100 * tail(n, L):6.2f}" for n in range(N + 1)))
steps = "WWLWWWLWWLLWLLWLWLLW"          # one fixed path: first reaches 15 at round 9, ends at 12
path = [X0]
for s in steps: path.append(path[-1] + (1 if s == "W" else -1))
t9 = path.index(L)
print("figure, path            " + " ".join(f"{v:>3d}" for v in path))
print("figure, mirrored        " + " ".join(f"{v if i <= t9 else 2 * L - v:>3d}" for i, v in enumerate(path)))

assert reach_count == 2 * sum(comb(N, h) for h in range(13, N + 1)), "every path, counted, vs the mirror count"
assert len(mirror_levels) == L, "touch-and-end-at-b must match end-at-30-b at every b"
assert abs(reach(N, 14) - sum(c for m, c in max_count.items() if m >= 14) / 2 ** N) < 1e-12, "formula, even gap"
assert all(max_count.get(m, 0) == 2 ** N * (p_end(N, m) + p_end(N, m + 1)) for m in range(X0, X0 + N + 1)), "max law"
assert all(abs(first[n] / 2 ** N - A / n * p_end(n, L)) < 1e-15 for n in range(1, N + 1)), "ballot form of first passage"
assert abs(sum(p_end(N, x) for x in range(X0 - A, L)) - (1 - p_form)) < 1e-12, "never reaching 15 = ending 5..14"
assert abs(recursion(N, L, floor=0) - p_form) < 1e-12, "recursion, with ruin at 0, vs the formula"
assert abs(p_sim - p_form) < 4 * se, "simulation within four standard errors"
print("ALL CHECKS PASS")
