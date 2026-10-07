# n-step transitions -- the check behind the card.  Nothing is imported.
# The weather chain of the markov-chains card, one step = one day, today sunny.
# Five roads to the law 7 days out: matrix powers; every path summed;
# Chapman-Kolmogorov splits; eigenvalues; a seeded simulation.  Exact values are
# whole numbers over 10^n, because every entry of P is a whole number of tenths.
NAMES = ["sunny", "cloudy", "rainy"]
P10 = [[6, 3, 1], [3, 4, 3], [2, 4, 4]]      # P in tenths
WET10 = [[4, 4, 2], [2, 4, 4], [1, 3, 6]]    # a wetter season's table, for What breaks
DAYS, WEEKS, SEED = 7, 100000, 20260929
MASK = (1 << 64) - 1

def mul(a, b):                               # exact matrix product
    return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))]
            for i in range(len(a))]

def frac(num, den, places=7):                # num / den rounded half up, fixed decimals
    s = "-" if num < 0 else ""
    v = (abs(num) * 10 ** places * 2 + den) // (2 * den)
    return f"{s}{v // 10 ** places}.{v % 10 ** places:0{places}d}"

def law(row, n):
    return " ".join(frac(x, 10 ** n) for x in row)

def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]

print("chain: sunny, cloudy, rainy; one step = one day; today sunny")
print("P rows: " + " | ".join(n + " " + " ".join(frac(x, 10, 1) for x in r) for n, r in zip(NAMES, P10)))

# Road 1: powers P^n = P P^(n-1), and the law pushed forward, mu_n = mu_(n-1) P
powers = [[[int(i == j) for j in range(3)] for i in range(3)]]
mu, fc = [[1, 0, 0]], [[5, 3, 2]]            # fc: an uncertain start in tenths, the forecast of markov-chains
for n in range(DAYS):
    powers.append(mul(P10, powers[-1]))
    mu.append(mul([mu[-1]], P10)[0])
    fc.append(mul([fc[-1]], P10)[0])
print("road 1, law by day (sunny cloudy rainy), exact:")
for n in range(DAYS + 1):
    assert mu[n] == powers[n][0] and sum(mu[n]) == 10 ** n
    print(f"  day {n}: {law(mu[n], n)}")
PN = powers[DAYS]
print(f"  P^{DAYS} row cloudy: {law(PN[1], DAYS)}; row rainy: {law(PN[2], DAYS)}")
avg = [sum(fc[0][i] * PN[i][j] for i in range(3)) for j in range(3)]      # start law times P^7: rows averaged
assert fc[DAYS] == avg and sum(avg) == 10 ** (DAYS + 1)
print(f"  forecast start, day {DAYS}: {law(fc[DAYS], DAYS + 1)}; rainy = " + " + ".join(
    f"{frac(w, 10, 1)} x {frac(PN[i][2], 10 ** DAYS)}" for i, w in enumerate(fc[0])) + f" = {frac(avg[2], 10 ** (DAYS + 1))}")

# Road 2: every path from sunny, weighted by the product along it
ends, count = [0, 0, 0], 0
for code in range(3 ** DAYS):
    x, w, c = 0, 1, code
    for _ in range(DAYS):
        y, c = c % 3, c // 3
        w, x = w * P10[x][y], y
    ends[x] += w
    count += 1
assert ends == PN[0]
print(f"road 2, {count} paths summed: {law(ends, DAYS)}")

# Road 3: Chapman-Kolmogorov, P^m P^(n-m) for every split
ok = sum(mul(powers[m], powers[DAYS - m]) == PN for m in range(DAYS + 1))
assert ok == DAYS + 1
col = [powers[DAYS - 3][k][2] for k in range(3)]
print(f"road 3, splits P^m P^({DAYS}-m) equal to P^{DAYS}: {ok} of {DAYS + 1}")
print(f"  split at day 3: P^3 sunny row {law(powers[3][0], 3)} . P^{DAYS - 3} rainy column "
      + law(col, DAYS - 3) + " = " + frac(sum(a * b for a, b in zip(powers[3][0], col)), 10 ** DAYS))

# Road 4: eigenvalues.  pi = (24, 22, 15)/61 exactly; the other two from a quadratic
PI61 = [24, 22, 15]
assert [sum(PI61[i] * P10[i][j] for i in range(3)) for j in range(3)] == [10 * x for x in PI61]
det10 = sum(P10[0][j] * cross(P10[1], P10[2])[j] for j in range(3))
s, d = (P10[0][0] + P10[1][1] + P10[2][2] - 10) / 10, det10 / 1000   # x^2 - s x + d = 0
lams = [1.0, (s + (s * s - 4 * d) ** 0.5) / 2, (s - (s * s - 4 * d) ** 0.5) / 2]
comps = []
for lam in lams:                             # left row v and right column r of P - lam I
    m = [[P10[i][j] / 10 - lam * (i == j) for j in range(3)] for i in range(3)]
    v, r = cross([m[i][0] for i in range(3)], [m[i][1] for i in range(3)]), cross(m[0], m[1])
    c = r[0] / sum(v[i] * r[i] for i in range(3))       # share of today's law (1, 0, 0) on v
    comps.append([c * x for x in v])
assert max(abs(comps[0][j] - PI61[j] / 61) for j in range(3)) < 1e-12
pw = [1.0, 1.0, 1.0]
for n in range(DAYS + 1):
    for j in range(3):
        assert abs(sum(comps[k][j] * pw[k] for k in range(3)) - mu[n][j] / 10 ** n) < 1e-12
    pw = [pw[k] * lams[k] for k in range(3)]
print(f"road 4, eigenvalues 1 and the roots of x^2 - {s:.1f} x + {d:.2f}: {lams[1]:.7f}, {lams[2]:.7f}; "
      + "long run (24 22 15)/61 = " + " ".join(frac(x, 61) for x in PI61))
print(f"  rainy_n = {comps[0][2]:.7f} + ({comps[1][2]:.7f}) x {lams[1]:.7f}^n + ({comps[2][2]:.7f}) x "
      f"{lams[2]:.7f}^n, days 0 to {DAYS} within 1e-12")
gap = [15 * 10 ** n - 61 * mu[n][2] for n in (DAYS - 1, DAYS)]
print(f"  rainy gap to long run, day {DAYS - 1}: {frac(gap[0], 61 * 10 ** (DAYS - 1))}, day {DAYS}: "
      f"{frac(gap[1], 61 * 10 ** DAYS)}, ratio {gap[1] / (10 * gap[0]):.4f}")

# Road 5: simulate WEEKS weeks with SplitMix64, a digit 0..9 picks tomorrow
state = SEED
def draw():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return ((z >> 32) * 10) >> 32
hits = [0, 0, 0]
for _ in range(WEEKS):
    x = 0
    for _ in range(DAYS):
        d, y = draw(), 0
        while d >= P10[x][y]:
            d, y = d - P10[x][y], y + 1
        x = y
    hits[x] += 1
for j in range(3):
    p = hits[j] / WEEKS
    se = (p * (1 - p) / WEEKS) ** 0.5
    assert abs(p - PN[0][j] / 10 ** DAYS) < 4 * se
    print(f"road 5, {WEEKS} simulated weeks, seed {SEED}, {NAMES[j]} on day {DAYS}: {p:.4f} +/- {se:.4f}")

# Charts: the law by day, rounded to 2 places
for j in range(3):
    print(f"chart, {NAMES[j]}: " + ", ".join(frac(mu[n][j], 10 ** n, 2) for n in range(DAYS + 1)))

# What breaks
colS = [PN[i][0] for i in range(3)]
print(f"break, P^{DAYS} times the start as a column: " + law(colS, DAYS) + ", sum " + frac(sum(colS), 10 ** DAYS))
print("break, wet table rows: " + " | ".join(" ".join(frac(x, 10, 1) for x in r) for r in WET10))
wet = [[int(i == j) for j in range(3)] for i in range(3)]
for _ in range(DAYS - 3):
    wet = mul(wet, WET10)
ordered, backwards = mul([mu[3]], wet)[0], mul(wet[:1], powers[3])[0]
assert ordered != backwards and ordered != PN[0]
print(f"break, 3 days of P then {DAYS - 3} of the wet table, rainy: {frac(ordered[2], 10 ** DAYS)}; "
      f"P^{DAYS} alone {frac(PN[0][2], 10 ** DAYS)}; wet days first {frac(backwards[2], 10 ** DAYS)}")
pat = "SSRR"                                 # two-day spells S S R R S S ..., random start
pairs = [(pat[f], pat[(f + 1) % 4]) for f in range(4)]
fit = {a: sum(1 for p in pairs if p == (a, "S")) / sum(1 for p in pairs if p[0] == a) for a in "SR"}
fit2 = fit["S"] * fit["S"] + (1 - fit["S"]) * fit["R"]
true2 = sum(1 for f in range(4) if pat[f] == "S" and pat[(f + 2) % 4] == "S") / pat.count("S")
assert fit2 != true2
print(f"break, spells of two days: fitted P^2 sunny->sunny {fit2:.4f}, true {true2:.4f}")
