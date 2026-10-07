# Variance and standard deviation -- the check behind the card.  Nothing is
# imported.  The raffle ticket pays $100 with chance 0.01 and $0 otherwise.
# Its variance is reached four ways: the definition, the shortcut, a count
# over a raffle of 100 real tickets, and a seeded simulation of a million.
LAW = [(0.0, 0.99), (100.0, 0.01)]          # (payout in dollars, chance)

def mean(law):
    return sum(p * x for x, p in law)

def var_definition(law):                    # road 1: average squared distance
    m = mean(law)
    return sum(p * (x - m) ** 2 for x, p in law)

def var_shortcut(law):                      # road 2: E[X^2] minus the mean squared
    return sum(p * x * x for x, p in law) - mean(law) ** 2

def sqrt(v):                                # Newton's method, written out here
    if v == 0.0:
        return 0.0
    r = v if v > 1.0 else 1.0
    for _ in range(100):
        r = 0.5 * (r + v / r)
    return r

def splitmix64(state):                      # the generator both languages share
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

def enumerate_tickets(pay, a=1, b=0):       # road 3: 100 tickets, ticket 37 wins
    vals = [a * (pay if t == 37 else 0) + b for t in range(100)]
    total = sum(vals)                       # whole numbers: no rounding at all
    sq = sum((100 * v - total) ** 2 for v in vals)
    return total / 100, sq / 100 ** 3

mu, v_def, v_short = mean(LAW), var_definition(LAW), var_shortcut(LAW)
ex2 = sum(p * x * x for x, p in LAW)
m_enum, v_enum = enumerate_tickets(100)
v_indicator = 100 ** 2 * (0.01 * (1 - 0.01))  # a = 100 times a 0-or-1 indicator
sd = sqrt(v_def)

# road 4: a seeded simulation, one million tickets, variance by the definition
n, state, draws = 1_000_000, 20260928, []
for _ in range(n):
    state, z = splitmix64(state)
    draws.append(100.0 if (z >> 11) * 2.0 ** -53 < 0.01 else 0.0)
m_sim = sum(draws) / n
v_sim = sum((d - m_sim) ** 2 for d in draws) / n
m4_sim = sum((d - m_sim) ** 4 for d in draws) / n
se_v = sqrt((m4_sim - v_sim ** 2) / n)      # standard error of the variance
sd_sim = sqrt(v_sim)
se_sd = se_v / (2 * sd_sim)                 # and of its square root

def row(label, v):
    print(f"{label:<40} {v:>14.6f}")

row("mean E[X]", mu)
row("E[X^2]", ex2)
row("1 definition: sum p (x - mean)^2", v_def)
row("2 shortcut: E[X^2] - mean^2", v_short)
row("3 count, 100 tickets: mean", m_enum)
row("3 count, 100 tickets: variance", v_enum)
row("4 simulated, 1,000,000: mean", m_sim)
row("4 simulated: variance", v_sim)
row("4 simulated: standard error of it", se_v)
row("5 indicator alone: p(1 - p)", 0.01 * (1 - 0.01))
row("5 prize^2 times p(1 - p)", v_indicator)
row("standard deviation sqrt(99)", sd)
row("simulated standard deviation", sd_sim)
row("  its standard error", se_sd)
row("mean +/- one sd: low end", mu - sd)
row("mean +/- one sd: high end", mu + sd)
print()
print("scaled ticket aX + b     a      b    mean  var by count   a^2 Var(X)      sd")
for name, a, b in (("net of a $2 price", 1, -2), ("organiser: 2 - X", -1, 2),
                   ("double prize: 2X", 2, 0), ("in cents: 100X", 100, 0)):
    m_ab, v_ab = enumerate_tickets(100, a, b)
    print(f"{name:<20} {a:>6} {b:>6} {m_ab:>7.2f} {v_ab:>14.2f} {a * a * v_def:>12.2f} {sqrt(v_ab):>7.2f}")
    assert abs(v_ab - a * a * v_def) < 1e-6 * (1 + a * a * v_def), name
print()
row("wrong: no square, sum p (x - mean)", sum(p * (x - mu) for x, p in LAW))
row("wrong: average distance, no square", sum(p * abs(x - mu) for x, p in LAW))
row("wrong: Var(2X) = 2 Var(X)", 2 * v_def)
row("wrong: 2X, E[Y^2] - E[Y] not E[Y]^2", 4 * ex2 - 2 * mu)
row("wrong: Var(2 - X) = -Var(X) + 2", -v_def + 2)
row("try: $1,000 prize, chance 0.001: var", var_definition([(0.0, 0.999), (1000.0, 0.001)]))
row("try: $1,000 prize, chance 0.001: sd", sqrt(var_definition([(0.0, 0.999), (1000.0, 0.001)])))
row("try: $2 prize, chance 0.5: var", var_definition([(0.0, 0.5), (2.0, 0.5)]))
row("chart, contribution of a loss", 0.99 * (0.0 - mu) ** 2)
row("chart, contribution of a win", 0.01 * (100.0 - mu) ** 2)
print("figure, x of $0 {:.2f}, $1 {:.2f}, $100 {:.2f}, band {:.2f} to {:.2f}".format(
    *[(v + 10) * 3 for v in (0.0, mu, 100.0, mu - sd, mu + sd)]))

assert abs(v_def - v_enum) < 1e-9, "definition vs whole-number count"
assert abs(m_enum - mu) < 1e-12, "mean vs whole-number count"
assert abs(v_short - v_enum) < 1e-9, "shortcut vs whole-number count"
assert abs(var_shortcut([(0.0, 0.99), (200.0, 0.01)]) - enumerate_tickets(100, 2)[1]) < 1e-9, "shortcut, 2X"
assert abs(v_indicator - v_def) < 1e-9, "indicator road vs definition"
assert abs(v_sim - v_enum) < 4 * se_v, "simulation within four standard errors"
assert abs(sd * sd - v_enum) < 1e-9, "Newton square root vs the count"
print("ALL CHECKS PASS")
