# Random variables: a number for each outcome, and the table of its chances.
# Raffle: 100 tickets, one number drawn, the held ticket (37) pays $100.
# Roads: count every outcome; multiply single-raffle counts; seeded simulation.
M = 2**64 - 1
MINE = 37


def X(drawn):                      # the random variable: number drawn -> payout
    return 100 if drawn == MINE else 0


def table(values):                 # pool outcomes by value: value -> outcome count
    t = {}
    for v in values:
        t[v] = t.get(v, 0) + 1
    return dict(sorted(t.items()))


def cdf(t, x):                     # running total of a table: count of values <= x
    return sum(c for v, c in t.items() if v <= x)


def splitmix64(s):
    s = (s + 0x9E3779B97F4A7C15) & M
    z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return s, z ^ (z >> 31)


# One raffle: 100 outcomes pooled into two values
one = table(X(w) for w in range(1, 101))
print(f"one raffle, tickets 1-100, held ticket {MINE}, pooled to 0: {one[0]}, pooled to 100: {one[100]}")
for v, c in one.items():
    print(f"pmf X, {v}, {c / 100:.6f}")
for x in (-50, -1, 0, 50, 99, 100, 150):
    direct = sum(1 for w in range(1, 101) if X(w) <= x)
    assert cdf(one, x) == direct
    print(f"cdf X, {x}, {cdf(one, x) / 100:.6f}")
print(f"jump of F at 0: {(cdf(one, 0) - cdf(one, -1)) / 100:.6f}, at 100: {(cdf(one, 100) - cdf(one, 99)) / 100:.6f}")
print(f"P(0 < X <= 100) = F(100) - F(0) = {(cdf(one, 100) - cdf(one, 0)) / 100:.6f}")

# A different space with the same table: last two digits of a number 000-999 are 77
bet = table(100 if n % 100 == 77 else 0 for n in range(1000))
assert {v: c * 100 for v, c in bet.items()} == {v: c * 1000 for v, c in one.items()}
print(f"77 bet, 1000 outcomes, {bet[100]} pay, pmf 0: {bet[0] / 1000:.6f}, pmf 100: {bet[100] / 1000:.6f}")

# A function of X is a random variable: net gain Y = X - 2 for a $2 ticket
net = table(X(w) - 2 for w in range(1, 101))
for v, c in net.items():
    print(f"pmf Y, {v}, {c / 100:.6f}")
print(f"cdf Y, 0, {cdf(net, 0) / 100:.6f}")

# Three separate raffles, one ticket in each: T = total payout
vals = [X(w) for w in range(1, 101)]
three, le100 = {}, 0
for a in vals:
    for b in vals:
        for c in vals:
            s = a + b + c
            three[s] = three.get(s, 0) + 1
            le100 += s <= 100
three = dict(sorted(three.items()))
prod = {}                          # road 2: multiply the single-raffle counts
for a, ca in one.items():
    for b, cb in one.items():
        for c, cc in one.items():
            prod[a + b + c] = prod.get(a + b + c, 0) + ca * cb * cc
assert prod == three
assert cdf(prod, 100) == le100
for v, c in three.items():
    print(f"pmf T, {v}, count {c} of 1000000, {c / 10**6:.6f}")
for x in (0, 100, 200, 300):
    print(f"cdf T, {x}, {cdf(prod, x) / 10**6:.6f}")
win = 1 - cdf(prod, 0) / 10**6
print(f"P(T >= 100) = 1 - F(0) = {win:.6f}, {10**6 - cdf(prod, 0)} of 1000000, about 1 in {1 / win:.2f}")

# Road 3: seeded simulation of 200,000 three-raffle weeks
N, s, sim = 200_000, 2026, {}
print(f"simulation, {N} weeks, seed {s}")
for _ in range(N):
    tot = 0
    for _ in range(3):
        s, r = splitmix64(s)
        tot += X(r % 100 + 1)
    sim[tot] = sim.get(tot, 0) + 1
for v in (0, 100, 200, 300):
    p, q = prod[v] / 10**6, sim.get(v, 0) / N
    se = (p * (1 - p) / N) ** 0.5
    assert abs(q - p) <= 4 * se
    print(f"simulated T, {v}, {q:.6f}, exact {p:.6f}, se {se:.6f}")

# What breaks
print(f"break, four values read as equally likely, P(T=0) = {1 / 4:.6f}")
print(f"break, strict < in place of <=, P(T<100) = {cdf(prod, 99) / 10**6:.6f}")
print(f"break, three win chances added, {3 * one[100] / 100:.6f}")
print(f"break, one outcome's chance read as P(X=0), {1 / 100:.6f}")
print("all checks passed")
