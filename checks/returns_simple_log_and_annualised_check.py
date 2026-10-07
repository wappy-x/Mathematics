# Returns: simple, log, and annualised -- the check behind the card.  Standard
# library only.  One stock, $100, that moves up or down 10% a month.  Roads: logs
# by math.log and by their own series; a year's spread by the square-root rule,
# by listing all 4096 up/down paths, and by 200,000 simulated years from a
# home-made random number generator; a loss's chance by path count and binomial.
from math import log, exp, sqrt

A, P0, MONTHS = 0.10, 100.0, 12

def ln_series(x):                 # ln x = 2(y + y^3/3 + y^5/5 + ...), y = (x-1)/(x+1)
    y = (x - 1.0) / (x + 1.0)
    term, total, k = y, 0.0, 1
    while abs(term) > 1e-18:
        total += term / k
        term *= y * y
        k += 2
    return 2.0 * total

def sd(xs):                       # spread: root of the average squared distance from the mean
    m = sum(xs) / len(xs)
    return sqrt(sum((x - m) ** 2 for x in xs) / len(xs))

def median(xs):                   # the lists here always have an even length
    s = sorted(xs)
    return 0.5 * (s[len(s) // 2 - 1] + s[len(s) // 2])

def all_paths(n, a):              # year-end wealth factor of every up/down sequence of n months
    out = []
    for mask in range(2 ** n):
        w = 1.0
        for i in range(n):
            w *= (1.0 + a) if (mask >> i) & 1 else (1.0 - a)
        out.append(w)
    return out

def chance_below_start(n, a):     # binomial count: k ups out of n, every sequence equally likely
    p, total = 0.5 ** n, 0.0
    for k in range(n + 1):
        if k * log(1.0 + a) + (n - k) * log(1.0 - a) < 0.0:
            total += p
        p = p * (n - k) / (k + 1)
    return total

def simulate(years, a, seed=2026):  # home-made 64-bit LCG; its top bit is the coin
    x, logs, simple = seed, [], []
    for _ in range(years):
        w = 1.0
        for _ in range(MONTHS):
            x = (x * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
            w *= (1.0 + a) if x >> 63 else (1.0 - a)
        logs.append(log(w))
        simple.append(w - 1.0)
    return sd(logs), sd(simple)

def row(label, *vals):
    print(f"{label:<40}" + "".join(f"{v:>12.6f}" for v in vals))

def chart(label, vals):
    print(f"{label:<28}" + " ".join(f"{v:.2f}" for v in vals))

up, down = 1.0 + A, 1.0 - A
r_up, r_dn = log(up), log(down)
g = (r_up + r_dn) / 2.0                 # mean log return a month: the growth rate
sig_log = (r_up - r_dn) / 2.0           # spread of the monthly log return
row("up 10% then down 10%, dollars", P0 * up * down)
row("average of the two simple returns", (A + (-A)) / 2.0)
row("two-month simple return", up * down - 1.0)
row("log returns, up month and down month", r_up, r_dn)
row("sum of the two log returns", r_up + r_dn)
row("ln 0.99 by its own series", ln_series(0.99))
row("exp(sum) - 1, back to simple", exp(r_up + r_dn) - 1.0)
row("geometric mean a month, simple", sqrt(up * down) - 1.0)
row("growth rate g a month, exact", g)
row("mu - sigma^2/2, approximate", 0.0 - A * A / 2.0)
for R in (0.50, 0.10, 0.01, -0.01, -0.10, -0.50):
    row(f"convert R = {R:+.2f}: log, R - R^2/2", log(1.0 + R), R - R * R / 2.0)
row("portfolio half each: value, dollars", 50.0 * up + 50.0 * down)
row("wrong: average of the two log returns", (r_up + r_dn) / 2.0)

paths = all_paths(MONTHS, A)
sd_log_enum = sd([log(w) for w in paths])
sd_simple_enum = sd([w - 1.0 for w in paths])
closed_simple = sqrt((1.0 + A * A) ** MONTHS - 1.0)   # E[w^2] = (1 + a^2)^12 and E[w] = 1
mc_log, mc_simple = simulate(200000, A)
mean_w, med_w = P0 * sum(paths) / len(paths), P0 * median(paths)
below_enum = sum(1 for w in paths if w < 1.0) / len(paths)
below_binom = chance_below_start(MONTHS, A)
alt = [P0]
for i in range(MONTHS):
    alt.append(alt[-1] * (up if i % 2 == 0 else down))
alt_down_first = P0 * (down * up) ** 6
row("monthly spread of the log return", sig_log)
row("rule: 0.10 x sqrt 12, simple", A * sqrt(MONTHS))
row("rule: log spread x sqrt 12", sig_log * sqrt(MONTHS))
row("all 4096 paths: spread, log", sd_log_enum)
row("all 4096 paths: spread, simple", sd_simple_enum)
row("closed form sqrt(1.01^12 - 1)", closed_simple)
row("200000 simulated years: log, simple", mc_log, mc_simple)
row("all paths: mean year-end, dollars", mean_w)
row("all paths: median year-end, dollars", med_w)
row("100 x 0.99^6, dollars", P0 * (up * down) ** 6)
row("chance of ending below $100: paths", below_enum)
row("chance of ending below $100: binomial", below_binom)
row("alternating year: end, dollars", alt[-1])
row("alternating years: spread of the end", sd([alt[-1], alt_down_first]))
row("annual log drift, 12 x g", MONTHS * g)
row("median year; monthly geo mean ^ 12", med_w / P0 - 1.0, sqrt(up * down) ** MONTHS - 1.0)
row("wrong: spread scaled by 12, not sqrt 12", A * MONTHS)

for n in (12, 60, 120, 240):
    print(f"horizon {n:>3} months: median {P0 * (up * down) ** (n / 2):7.2f}  below $100 "
          f"{chance_below_start(n, A):.4f}  drift {n * g:+.4f}  spread {sig_log * sqrt(n):.4f}")
cross = (sig_log / g) ** 2
row("drift overtakes spread: months, years", cross, cross / 12.0)

enum_by_n = [sd([log(w) for w in all_paths(n, A)]) for n in range(1, MONTHS + 1)]
chart("chart, alternating path", alt)
chart("chart, spread %, sqrt rule", [100 * sig_log * sqrt(n) for n in range(1, MONTHS + 1)])
chart("chart, spread %, all paths", [100 * s for s in enum_by_n])
chart("chart, spread %, if linear", [100 * sig_log * n for n in range(1, MONTHS + 1)])

row("house fund: 8% - 0.15^2/2", 0.08 - 0.15 * 0.15 / 2.0)
row("house fund: spread monthly, daily", 0.15 / sqrt(12.0), 0.15 / sqrt(252.0))
wk = sum(1 for d in range(365) if (3 + d) % 7 < 5)   # 1 Jan 2026 is a Thursday; Monday = 0
row("2026: weekdays, less 10 NYSE holidays", wk, wk - 10)
row("try a = 0.20: two months, median year", P0 * 1.2 * 0.8, P0 * (1.2 * 0.8) ** 6)
row("try a = 0.50: two months, dollars", P0 * 1.5 * 0.5)
row("try a = 0.50: g exact, approximate", (log(1.5) + log(0.5)) / 2.0, -0.5 * 0.5 / 2.0)
row("try daily 1%: x sqrt 252", 0.01 * sqrt(252.0))

assert abs(ln_series(0.99) - (r_up + r_dn)) < 1e-12, "series log of the product vs sum of logs"
assert abs(sd_log_enum - sig_log * sqrt(MONTHS)) < 1e-12, "square-root rule vs every path, log"
assert abs(sd_simple_enum - closed_simple) < 1e-12, "every path vs closed form, simple"
assert sd_simple_enum - A * sqrt(MONTHS) > 0.005, "the rule is only approximate for simple returns"
assert abs(mc_log - sd_log_enum) < 0.003, "simulation vs every path"
assert abs(med_w - alt[-1]) < 1e-9, "median of all paths vs the alternating path"
assert abs(below_enum - below_binom) < 1e-12, "counting paths vs the binomial count"
assert abs(sqrt(up * down) ** MONTHS - med_w / P0) < 1e-12, "monthly geometric mean, compounded, vs median year"
assert all(abs(e - sig_log * sqrt(n + 1)) < 1e-12 for n, e in enumerate(enum_by_n)), "rule at every horizon"
print("ALL CHECKS PASS")
