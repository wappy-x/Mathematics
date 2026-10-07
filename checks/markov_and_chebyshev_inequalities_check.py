# Markov and Chebyshev -- the check behind the card; only math is imported.
# A fete sells 1,000 scratch tickets paying $0 to $5.  Tail shares four ways:
# a count over every ticket, the bounds from mean and variance alone, a seeded
# simulation of a million draws, and a search of 100,000 random laws.
import math

LAW = [(0, 50), (1, 230), (2, 470), (3, 210), (5, 40)]   # (payout $, tickets)
SHARP = [(0, 1), (2, 6), (4, 1)]                          # 8 tickets meeting Chebyshev
RAFFLE = [(0, 99), (100, 1)]                              # the shelf's house raffle
ONE_SIDED = [(1.5, 4), (4, 1)]                            # 5 tickets meeting Cantelli
KS = [1, 1.5, 2, 2.5, 3]

def moments(law):                            # mean and variance, by counting
    n = sum(c for _, c in law)
    m = sum(x * c for x, c in law) / n
    return m, sum((x - m) * (x - m) * c for x, c in law) / n

def share(law, keep):                        # share of tickets a test keeps
    return sum(c for x, c in law if keep(x)) / sum(c for _, c in law)

def splitmix64(s):                           # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return s, z ^ (z >> 31)

def phi_series(x):                           # normal area below x, by its series
    term, total, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + math.exp(-x * x / 2) / math.sqrt(2 * math.pi) * total

def phi_simpson(x, steps=2000):              # the same area, by Simpson's rule
    h = x / steps
    f = [math.exp(-(i * h) ** 2 / 2) / math.sqrt(2 * math.pi) for i in range(steps + 1)]
    s = f[0] + f[steps] + sum((4 if i % 2 else 2) * f[i] for i in range(1, steps))
    return 0.5 + s * h / 3

def row(label, v):
    print(f"{label:<46} {v:>11.6f}")

mu, var = moments(LAW)
sd = math.sqrt(var)
tail4 = share(LAW, lambda x: x >= 2 * mu)                # road 1: every ticket
tail2 = share(LAW, lambda x: abs(x - mu) >= 2 * sd)
markov, cheb = mu / (2 * mu), var / (mu * mu)            # road 2: moments alone
ey = moments([((x - mu) * (x - mu), c) for x, c in LAW])[0]

pay = [x for x, c in LAW for _ in range(c)]              # road 3: simulation
state, n, h4, h2 = 20260928, 1_000_000, 0, 0
for _ in range(n):
    state, z = splitmix64(state)
    x = pay[z % len(pay)]
    h4 += x >= 2 * mu
    h2 += abs(x - mu) >= 2 * sd
s4, s2 = h4 / n, h2 / n
se4, se2 = math.sqrt(s4 * (1 - s4) / n), math.sqrt(s2 * (1 - s2) / n)

worst_m, worst_c = 0.0, 0.0                              # road 4: hunt a counterexample
for _ in range(100_000):
    law = []
    for _ in range(3):
        state, z = splitmix64(state)
        state, w = splitmix64(state)
        law.append((z % 9, (w >> 11) * 2.0 ** -53))
    m, v = moments(law)
    worst_m = max(worst_m, share(law, lambda x: x >= 2 * m)) if m > 0 else worst_m
    worst_c = max(worst_c, share(law, lambda x: abs(x - m) >= 2 * math.sqrt(v))) if v > 0 else worst_c

print(f"tickets {len(pay)}")
row("mean E[X], dollars", mu)
row("variance Var(X), square dollars", var)
row("standard deviation, dollars", sd)
row("1 count: share paying $4 or more", tail4)
row("1 count: share with |X - 2| >= 2", tail2)
row("2 Markov bound E[X]/4", markov)
row("2 Chebyshev bound Var(X)/2^2", cheb)
row("2 Markov on Y = (X - 2)^2 at 4: E[Y]/4", ey / 4)
row("3 simulated, 1,000,000: share >= $4", s4)
row("3   its standard error", se4)
row("3 simulated: share |X - 2| >= 2", s2)
row("3   its standard error", se2)
row("4 of 100,000 laws, largest P(X >= 2 mean)", worst_m)
row("4 of 100,000 laws, largest P(|X-mean| >= 2 sd)", worst_c)
ms, vs = moments(SHARP)
t_sharp = share(SHARP, lambda x: abs(x - ms) >= 2)
row("sharp, 8 tickets: mean", ms)
row("sharp, 8 tickets: variance", vs)
row("sharp: share |X - 2| >= 2", t_sharp)
mr, _ = moments(RAFFLE)
row("house raffle: share paying $100", share(RAFFLE, lambda x: x >= 100))
row("house raffle: Markov bound E[X]/100", mr / 100)
row("house raffle: share paying $2 or more", share(RAFFLE, lambda x: x >= 2))
row("house raffle: Markov bound E[X]/2", mr / 2)
mo, vo = moments(ONE_SIDED)
t_one = share(ONE_SIDED, lambda x: x >= 4)
row("one-sided, 5 tickets: share paying $4 or more", t_one)
row("one-sided bound Var/(Var + 2^2)", vo / (vo + (4 - mo) ** 2))
print("chart, share of tickets at $0..$5:", " ".join(
    f"{share(LAW, lambda x: x == d):.2f}" for d in range(6)))
print("chart,   k  Chebyshev 1/k^2  tickets  normal")
for k in KS:
    tk = share(LAW, lambda x: abs(x - mu) >= k * sd)
    print(f"chart, {k:>3}  {1 / k ** 2:>15.2f}  {tk:>7.2f}  {2 * (1 - phi_series(k)):.2f}")
row("normal law: two-sided tail at k = 2", 2 * (1 - phi_series(2)))
row("normal area below 2: series", phi_series(2))
row("normal area below 2: Simpson", phi_simpson(2))
row("wrong: Markov on X - 2 at $1: 'bound'", moments([(x - 2, c) for x, c in LAW])[0] / 1)
row("wrong: actual share with X - 2 >= 1", share(LAW, lambda x: x - 2 >= 1))
heavy = [(2.0 ** j, 3 * 4.0 ** -j) for j in range(1, 61)]  # $2^j with chance 3/4^j
for top in (10, 20, 40):
    row(f"heavy ticket: E[X^2] over {top} prize levels", sum(x * x * p for x, p in heavy[:top]))
mh = sum(x * p for x, p in heavy)
th = sum(p for x, p in heavy if x >= 6)
row("heavy ticket: mean", mh)
row("heavy ticket: share paying $6 or more", th)
row("heavy ticket: Markov bound E[X]/6", mh / 6)
lo, hi = 0.0, 5.0                                        # normal quantile by bisection
for _ in range(100):
    lo, hi = (lo, (lo + hi) / 2) if phi_series((lo + hi) / 2) > 0.975 else ((lo + hi) / 2, hi)
row("poll, 5 points, 5% risk: Chebyshev size", 0.25 / (0.05 * 0.05 ** 2))
row("poll: normal quantile for 97.5%", lo)
row("poll: normal-approximation size", lo * lo * 0.25 / 0.05 ** 2)
px, py = (lambda d: 40 + 30 * d), (lambda d: 200 - 20 * d)   # 30 px per $ across, 20 up
print(f"figure, origin ({px(0)},{py(0)}), step ({px(4)},{py(0)}) to ({px(4)},{py(4)}), y=x ends ({px(8)},{py(8)})")

assert abs(s4 - tail4) < 4 * se4, "simulation vs count, $4 or more"
assert abs(s2 - tail2) < 4 * se2, "simulation vs count, two-sided"
assert abs(mu - 2) + abs(var - 1) < 1e-12 and tail4 <= tail2 <= cheb <= markov, "mean $2, sd $1; count under both bounds"
assert abs(cheb - ey / 4) < 1e-12 and moments([(x - 2, c) for x, c in LAW])[0] / 1 < share(LAW, lambda x: x - 2 >= 1), "Chebyshev = Markov on Y; Markov fails on X - 2"
assert abs(phi_simpson(lo) - 0.975) < 1e-9, "poll quantile: bisection on the series, checked by Simpson"
assert abs(t_sharp - vs / 2 ** 2) < 1e-12, "counted tail meets Chebyshev's bound"
assert abs(share(RAFFLE, lambda x: x >= 100) - mr / 100) < 1e-12, "raffle meets Markov"
assert abs(t_one - vo / (vo + (4 - mo) ** 2)) < 1e-12, "one-sided law meets Cantelli"
assert worst_m <= 0.5 and worst_c <= 0.25, "no random law beats Markov at 2 means or Chebyshev at 2 sd"
assert abs(th - 4.0 ** -2) + abs(mh - 3) < 1e-12 and all(abs(sum(x * x * p for x, p in heavy[:t]) - 3 * t) < 1e-9 for t in (10, 20, 40)), "heavy ticket: sums vs closed forms"
assert abs(phi_series(2) - phi_simpson(2)) < 1e-10, "series vs Simpson"
print("ALL CHECKS PASS")
