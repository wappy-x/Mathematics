# Life annuities and insurance -- the check behind the card.  Standard library only.
# Mortality: Makeham's law, force mu(y) = A + B c^y, the law behind the Standard
# Ultimate Life Table.  Interest: 5 percent a year, effective.  Nothing imported
# knows an annuity: survival, sums, recursion, simulation and integral are all here.
from math import exp, log, sqrt

A, B, C = 0.00022, 2.7e-6, 1.124           # Makeham constants, per year
I = 0.05                                    # effective annual interest
TOP = 131                                   # nobody is followed past age 130
PAY, BEN = 10000.0, 100000.0                # the pension a year; a death benefit

def tp(x, t, b=B):                          # chance a life aged x is alive at x + t
    return exp(-A * t - b * C ** x * (C ** t - 1) / log(C))

def by_sums(x, v, p, top=TOP):              # road 1: add up birthdays alive, and years of death
    due = sum(v ** k * p(x, k) for k in range(top - x))
    ins = sum(v ** (k + 1) * p(x, k) * (1 - p(x + k, 1)) for k in range(top - x))
    return due, ins

def by_recursion(x, v, p):                  # road 2: work back from age 130 one year at a time
    due, ins = 0.0, 0.0
    for y in range(TOP - 1, x - 1, -1):
        py = p(y, 1)
        due, ins = 1 + v * py * due, v * (1 - py) + v * py * ins
    return due, ins

def rng(seed):                              # splitmix64: our own uniform numbers in (0, 1)
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        yield ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def death_time(x, u):                       # solve tp(x, t) = u by bisection
    lo, hi = 0.0, float(TOP - x)
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if tp(x, mid) > u: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

v, d, delta = 1 / (1 + I), I / (1 + I), log(1 + I)
due, ins = by_sums(65, v, tp)
due_r, ins_r = by_recursion(65, v, tp)
e65 = sum(tp(65, k) for k in range(1, TOP - 65))

N = 100000                                  # road 3: live 100,000 pensioners' lives
g = rng(20260928)
sy = syy = sz = sbar = sbb = 0.0
exact_paths = 0
for _ in range(N):
    t = death_time(65, next(g))
    k = int(t)
    y = sum(v ** j for j in range(k + 1))   # payments received, discounted
    z = v ** (k + 1)                        # benefit at the end of the death year
    if abs(d * y + z - 1) < 1e-12: exact_paths += 1
    e = exp(-delta * t)                     # benefit at the moment of death
    sy += y; syy += y * y; sz += z; sbar += e; sbb += e * e
due_mc, ins_mc, bar_mc = sy / N, sz / N, sbar / N
se_mc = sqrt((syy / N - due_mc ** 2) / N)
se_bar = sqrt((sbb / N - bar_mc ** 2) / N)

def f(t):                                   # payment at the moment of death: e^-dt t_p_65 mu(65+t)
    return exp(-delta * t) * tp(65, t) * (A + B * C ** (65 + t))
n, h = 6600, (TOP - 65) / 6600
bar = (f(0) + f(TOP - 65) + sum((4 if j % 2 else 2) * f(j * h) for j in range(1, n))) * h / 3

due40, ins40 = by_sums(40, v, tp)
e2540 = v ** 25 * tp(40, 25)
defer_direct = sum(v ** k * tp(40, k) for k in range(25, TOP - 40))
toy = lambda x, t: 0.9 ** t                 # a toy basis: 90 percent survive every year
toy_due, toy_ins = by_sums(65, v, toy, 465)  # followed 400 years

rows = [
    ("v = 1/(1+i)", v), ("d = i/(1+i)", d), ("delta = ln(1+i)", delta),
    ("1p65  alive at 66", tp(65, 1)), ("q65   dies before 66", 1 - tp(65, 1)),
    ("25p40 alive at 65, from 40", tp(40, 25)), ("e65   whole years still to live", e65),
    ("1 annuity-due, sum of survivals", due), ("2 annuity-due, backward recursion", due_r),
    ("3 annuity-due, 100000 lives", due_mc), ("  simulation standard error", se_mc),
    ("4 insurance, sum over death years", ins), ("5 insurance, backward recursion", ins_r),
    ("6 insurance, 100000 lives", ins_mc), ("  identity: 1 - d x annuity-due", 1 - d * due),
    ("  paths with dY + Z = 1", exact_paths),
    ("moment of death, integral", bar), ("moment of death, 100000 lives", bar_mc),
    ("  simulation standard error", se_bar),
    ("  v x moment of death", v * bar),
    ("pension 10,000 a year from 65", PAY * due), ("death benefit 100,000 at 65", BEN * ins),
    ("25E40 = v^25 x 25p40", e2540), ("pension bought at 40, deferred", PAY * e2540 * due),
    ("pension bought at 40, direct sum", PAY * defer_direct),
    ("annuity-due at 40", due40), ("insurance at 40", ins40),
    ("wrong: annuity-immediate", PAY * (due - 1)),
    ("wrong: certain, 1 + e65 payments", PAY * (1 - v ** (1 + e65)) / d),
    ("wrong: no interest", PAY * (1 + e65)),
    ("wrong: benefit as 1 - i x annuity", BEN * (1 - I * due)),
    ("wrong: benefit as 1 - d x immediate", BEN * (1 - d * (due - 1))),
    ("try: 3% interest, annuity-due", by_sums(65, 1 / 1.03, tp)[0]),
    ("try: age 75, annuity-due", by_sums(75, v, tp)[0]),
    ("try: ageing term doubled, annuity-due", by_sums(65, v, lambda x, t: tp(x, t, 2 * B))[0]),
    ("try: toy 0.9 survival, annuity-due", toy_due), ("try: toy 0.9 survival, insurance", toy_ins),
]
for name, val in rows:
    print(f"{name:<38} {val:>16.6f}")

print()
yrs = list(range(0, 50, 5))
print(f"{'chart, years after 65':<26}" + "".join(f"{k:>9d}" for k in yrs))
print(f"{'chart, 10,000 v^k kp65':<26}" + "".join(f"{PAY * v ** k * tp(65, k):>9.2f}" for k in yrs))
ages = list(range(40, 110, 10))
vals = [by_sums(x, v, tp) for x in ages]
print(f"{'chart, age':<26}" + "".join(f"{x:>9d}" for x in ages))
print(f"{'chart, 100 x A':<26}" + "".join(f"{100 * a:>9.2f}" for _, a in vals))
print(f"{'chart, 100 x d x due':<26}" + "".join(f"{100 * d * u:>9.2f}" for u, _ in vals))
print(f"{'chart, sum of the two':<26}" + "".join(f"{100 * (a + d * u):>9.2f}" for u, a in vals))

assert abs(due - 13.5498) < 5e-5, "published SULT annuity-due at 65, 5%"
assert abs(ins - 0.35477) < 5e-6, "published SULT insurance at 65, 5%"
assert abs(due_r - due) < 1e-9, "annuity: recursion road vs sum road"
assert abs(ins_r - ins) < 1e-9, "insurance: recursion road vs sum road"
assert abs(ins - (1 - d * due)) < 1e-12, "identity: death-year sum vs 1 - d x birthday sum"
assert abs(due_mc - due) < 4 * se_mc, "simulated lives within 4 standard errors"
assert exact_paths == N, "every simulated life satisfies dY + Z = 1"
assert abs(bar - bar_mc) < 4 * se_bar, "moment-of-death integral vs simulated lives"
assert v * bar < ins < bar, "end of death year sits between the two moment-of-death values"
assert abs(e2540 * due - defer_direct) < 1e-9, "deferral factor vs direct sum from 40"
assert abs(toy_due - 7) < 1e-9, "toy basis: 1/(1 - 0.9v) = 7 by hand"
assert abs(toy_ins - 2 / 3) < 1e-9, "toy basis: 0.1v/(1 - 0.9v) = 2/3 by hand"
print("ALL CHECKS PASS")
