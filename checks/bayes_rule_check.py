# Bayes' rule -- the check behind the card.  Standard library only.
# A screening test: 1% of people carry the condition, the test flags 99% of
# carriers and 1% of non-carriers.  Every number quoted on the card is printed.
# Roads: the formula, an exact count over equally likely cases, the odds form,
# and a seeded simulation with its standard error.
from math import sqrt

base, hit, false_alarm = 0.01, 0.99, 0.01   # P(H), P(E | H), P(E | not H)

def bayes(p, s, f):                           # road 1: the formula
    return s * p / (s * p + f * (1.0 - p))

def by_odds(p, s, f):                         # road 3: odds times likelihood ratio
    after = (p / (1.0 - p)) * (s / f)
    return after / (1.0 + after)

def row(label, v):
    print(f"{label:<44} {v:>12.6f}")

# ---- road 1: formula ----
pe = hit * base + false_alarm * (1.0 - base)
post = bayes(base, hit, false_alarm)
row("formula  carrier and positive 0.99*0.01", hit * base)
row("formula  clear and positive 0.01*0.99", false_alarm * (1.0 - base))
row("formula  P(E) = 0.99*0.01 + 0.01*0.99", pe)
row("formula  P(H|E)", post)

# ---- road 2: count.  100 equally likely status slots (slot 0 carries),
# 100 equally likely test slots (slot 0 is the test's error). ----
pos = carriers_pos = 0
for status in range(100):
    for test in range(100):
        carrier = status == 0
        positive = (test != 0) if carrier else (test == 0)
        if positive:
            pos += 1
            carriers_pos += carrier
count_post = carriers_pos / pos
print(f"count    cases 10000, positive {pos}, carriers among them {carriers_pos}")
row("count    P(H|E) = carriers / positives", count_post)

# ---- road 3: odds ----
row("odds     before, 1 to 99", base / (1.0 - base))
row("odds     likelihood ratio 0.99 / 0.01", hit / false_alarm)
row("odds     after", (base / (1.0 - base)) * (hit / false_alarm))
row("odds     P(H|E) = odds / (1 + odds)", by_odds(base, hit, false_alarm))

# ---- road 4: seeded simulation (SplitMix64, seed 20260928) ----
MASK = (1 << 64) - 1
state = 20260928
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return (z >> 11) / 9007199254740992.0
n, sim_pos, sim_car = 400000, 0, 0
for _ in range(n):
    carrier = uniform() < base
    positive = uniform() < (hit if carrier else false_alarm)
    if positive:
        sim_pos += 1
        sim_car += carrier
est = sim_car / sim_pos
se = sqrt(est * (1.0 - est) / sim_pos)
print(f"simulate people {n}, positive {sim_pos}, carriers among them {sim_car}")
row("simulate P(H|E) estimate", est)
row("simulate standard error", se)

# ---- a second, independent positive: count over 100^3 equally likely cases ----
both = both_car = repeat = repeat_car = 0
for status in range(100):
    carrier = status == 0
    for t1 in range(100):
        p1 = (t1 != 0) if carrier else (t1 == 0)
        if p1:                                  # a repeat of the same sample copies t1
            repeat += 1
            repeat_car += carrier
        for t2 in range(100):
            p2 = (t2 != 0) if carrier else (t2 == 0)
            if p1 and p2:
                both += 1
                both_car += carrier
two_count = both_car / both
two_odds = by_odds(post, hit, false_alarm)
print(f"second   cases 1000000, both positive {both}, carriers {both_car}")
row("second   count P(H|E1,E2)", two_count)
row("second   odds 1 x 99 = 99, P(H|E1,E2)", two_odds)

# ---- house example: two dice.  H = first die 6, E = total 10 ----
dice = [(a, b) for a in range(1, 7) for b in range(1, 7)]
ten = [d for d in dice if d[0] + d[1] == 10]
dice_count = sum(1 for d in ten if d[0] == 6) / len(ten)
# P(E) by total probability over the first die, not from the count above
dice_pe = sum((1 / 6) * sum(1 for b in range(1, 7) if a + b == 10) / 6 for a in range(1, 7))
dice_formula = (1 / 6) * (1 / 6) / dice_pe
row("dice     count P(first 6 | total 10)", dice_count)
row("dice     formula (1/6)(1/6)/(3/36)", dice_formula)

# ---- what breaks ----
row("wrong: hit rate read as the answer", hit)
row("wrong: healthy positives left out of P(E)", hit * base / (hit * base))
row("wrong: probability (not odds) times 99", base * hit / false_alarm)
row("wrong: same, at a 2% base rate", 0.02 * hit / false_alarm)
row("  right, at a 2% base rate", bayes(0.02, hit, false_alarm))
row("wrong: repeat of one sample as 2nd test", two_odds)
row("  right, repeat of one sample (count)", repeat_car / repeat)
row("court: innocent matches, 1 in 10000 of 1e6", 1e6 / 10000)

# ---- try changing ----
row("try: base rate 10%", bayes(0.10, hit, false_alarm))
row("try: false alarms 0.1%", bayes(base, hit, 0.001))
row("try: likelihood ratio 0.99 / 0.001", hit / 0.001)
row("try: hit rate 90%", bayes(base, 0.90, false_alarm))
row("try: base rate 50%", bayes(0.50, hit, false_alarm))

# ---- chart: the same test at other base rates (percent) ----
for b in (0.1, 0.5, 1, 2, 5, 10, 20, 50):
    print(f"sweep    base rate {b:>4}%  ->  P(H|E) {100 * bayes(b / 100, hit, false_alarm):6.2f}%")
print("figure, tree: 10000 -> 100 carriers (99 pos, 1 neg), 9900 not (99 pos, 9801 neg)")

# ---- asserts: each side is reached by a different road ----
assert carriers_pos == 99 and pos == 198            # the count, against the tree
assert abs(post - count_post) < 1e-12               # formula vs count
assert abs(by_odds(base, hit, false_alarm) - count_post) < 1e-12   # odds vs count
assert abs(est - post) < 4 * se                     # simulation vs formula
assert abs(two_count - two_odds) < 1e-12            # two tests: count vs odds
assert abs(repeat_car / repeat - two_odds) > 0.4    # a repeat is not a second test
assert abs(dice_count - dice_formula) < 1e-12       # dice: count vs formula
print("all checks passed")
