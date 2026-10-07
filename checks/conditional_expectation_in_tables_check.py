# Conditional expectation on a claims table -- the check behind the card.
# Nothing is imported.  X is one claim's size in dollars, Y its region.  The
# table holds 100 claims' worth of counts, so each probability is a count / 100.
# Road 1 divides the table by P(region).  Road 2 walks a ledger of the 100
# claims with whole-number sums.  Road 3 draws claims with SplitMix64, seed 2026.
SIZES = [1000, 5000, 20000]
REGIONS = ["North", "Inland", "Coast"]
COUNTS = [[30, 15, 5], [15, 12, 3], [6, 6, 8]]      # rows: regions; columns: sizes
N_TENTHS = [1, 3, 4, 2]                             # P(N = 0) ... P(N = 3), in tenths
N_LAW = [c / 10 for c in N_TENTHS]                 # claims in a month
MASK = (1 << 64) - 1

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

def below(state, n):                                # a whole number from 0 to n - 1
    state, z = splitmix(state)
    return state, ((z >> 11) * n) >> 53

def sqrt(v):                                        # Newton's method for a square root
    r = v if v > 1 else 1.0
    for _ in range(60):
        r = 0.5 * (r + v / r)
    return r

def mean_and_se(s, sq, n):                          # sample mean and its standard error
    var = (sq - s * s / n) / (n - 1)
    return s / n, sqrt(var / n)

joint = [[c / 100 for c in row] for row in COUNTS]  # P(X = x, Y = y)
p_y = [sum(row) for row in joint]                   # P(Y = y), row sums
g = [sum(x * p for x, p in zip(SIZES, row)) / py for row, py in zip(joint, p_y)]
col = [sum(joint[r][j] for r in range(3)) for j in range(3)]    # P(X = x), column sums
ledger = [(r, SIZES[j]) for r in range(3) for j in range(3) for _ in range(COUNTS[r][j])]

print("Conditional expectation on a claims table, dollars")
for r in range(3):
    print(f"joint, {REGIONS[r]}, " + ", ".join(f"{p:.2f}" for p in joint[r]))
print("P(X = x) for 1000, 5000, 20000, " + ", ".join(f"{p:.2f}" for p in col))
print("region, P(region), E[X | region] by division, by ledger")
for r in range(3):
    tot = sum(x for rr, x in ledger if rr == r)
    cnt = sum(1 for rr, x in ledger if rr == r)
    print(f"{REGIONS[r]}, {p_y[r]:.2f}, {g[r]:.2f}, {tot / cnt:.2f}")
    assert abs(tot / cnt - g[r]) < 1e-9, "table road and ledger road disagree"
coast_law = [p / p_y[2] for p in joint[2]]         # P(X = x | Coast)
print("Coast weights given Coast, " + ", ".join(f"{p:.2f}" for p in coast_law))
print("tower terms, " + ", ".join(f"{py * gy:.2f}" for py, gy in zip(p_y, g)))
e_tower = sum(py * gy for py, gy in zip(p_y, g))
e_col = sum(x * p for x, p in zip(SIZES, col))
e_ledger = sum(x for _, x in ledger) / len(ledger)
print(f"tower, sum of P(region) times E[X | region], {e_tower:.2f}")
print(f"column, sum of x times P(X = x), {e_col:.2f}")
print(f"ledger, grand average of 100 claims, {e_ledger:.2f}")
assert abs(e_tower - e_col) < 1e-9, "tower rule fails against the column road"
assert abs(e_tower - e_ledger) < 1e-9, "tower rule fails against the ledger road"

st, n, s, sq, cs, csq, cn = 2026, 200000, 0, 0, 0, 0, 0
for _ in range(n):
    st, k = below(st, 100)
    r, x = ledger[k]
    s, sq = s + x, sq + x * x
    if r == 2:
        cs, csq, cn = cs + x, csq + x * x, cn + 1
m, se = mean_and_se(float(s), float(sq), n)
print(f"sim, {n} claims, E[X] {m:.2f}, se {se:.2f}")
cm, cse = mean_and_se(float(cs), float(csq), cn)
print(f"sim, {cn} Coast claims, E[X | Coast] {cm:.2f}, se {cse:.2f}")
assert abs(m - e_col) < 4 * se, "simulation misses E[X]"
assert abs(cm - g[2]) < 4 * cse, "simulation misses E[X | Coast]"

def mse(h):                                         # E[(X - h(Y))^2] for a guess h per region
    return sum((SIZES[j] - h[r]) ** 2 * joint[r][j] for r in range(3) for j in range(3))
total = sum(x * x * p for x, p in zip(SIZES, col)) - e_col ** 2
within = mse(g)
between = sum(py * (gy - e_col) ** 2 for py, gy in zip(p_y, g))
print(f"variance, total {total:.2f}, within {within:.2f}, between {between:.2f}")
print(f"best guess, squared error with region means {within:.2f}, with E[X] alone {mse([e_col] * 3):.2f}")
up, down = mse([gy + 500 for gy in g]), mse([gy - 500 for gy in g])
print(f"best guess, region means + 500 {up:.2f}, region means - 500 {down:.2f}")
print(f"best guess, extra error from a 500 shift {up - within:.2f}")
print(f"share of squared error removed by the region {between / total:.2f}")
assert abs(within + between - total) < 1e-3, "variance does not split"
assert within < min(up, down), "shifted region means beat the region means"
assert within <= mse([e_col] * 3) + 1e-6, "one flat guess beats the region means"

def enum_total(law_for):                            # E[S] by walking every month outcome
    out = 0.0
    for k, pn in enumerate(N_LAW):
        combos = [(1.0, 0)]
        for _ in range(k):
            combos = [(w * p, t + x) for w, t in combos for x, p in zip(SIZES, law_for(k))]
        out += pn * sum(w * t for w, t in combos)
    return out
e_n = sum(k * p for k, p in enumerate(N_LAW))
plain = enum_total(lambda k: col)
print("P(N = n) for n = 0 to 3, " + ", ".join(f"{p:.2f}" for p in N_LAW))
print(f"random sum, E[N] {e_n:.2f}, E[N] x E[X] {e_n * e_col:.2f}, enumeration {plain:.2f}")
print("E[S | N = n] for n = 0 to 3, " + ", ".join(f"{k * e_col:.2f}" for k in range(4)))
assert abs(plain - e_n * e_col) < 1e-6, "random-sum shortcut fails"
st, months, s, sq = 7, 100000, 0, 0
for _ in range(months):
    st, u = below(st, 10)
    k = 0
    while u >= sum(N_TENTHS[:k + 1]):
        k += 1
    t = 0
    for _ in range(k):
        st, j = below(st, 100)
        t += ledger[j][1]
    s, sq = s + t, sq + t * t
m, se = mean_and_se(float(s), float(sq), months)
print(f"random sum sim, {months} months, E[S] {m:.2f}, se {se:.2f}")
assert abs(m - e_n * e_col) < 4 * se, "random-sum simulation misses"

storm = enum_total(lambda k: coast_law if k == 3 else col)
storm_tower = sum(p * k * (g[2] if k == 3 else e_col) for k, p in enumerate(N_LAW))
print(f"breaks, equal weights on the region means {sum(g) / 3:.2f}")
print(f"breaks, Coast row not divided by P(Coast) {sum(x * p for x, p in zip(SIZES, joint[2])):.2f}")
print(f"breaks, storm months: enumeration {storm:.2f}, tower {storm_tower:.2f}, E[N] x E[X] {e_n * e_col:.2f}")
assert abs(storm - storm_tower) < 1e-6, "tower misses the storm enumeration"
assert abs(storm - e_n * e_col) > 1, "storm case should break the shortcut"
print(f"figure, bars North {g[0]:.2f}, Inland {g[1]:.2f}, Coast {g[2]:.2f}, line {e_col:.2f}")
print("All checks passed.")
