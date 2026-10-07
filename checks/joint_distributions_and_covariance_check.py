# Joint distributions and covariance -- the check behind the card.  Nothing is
# imported.  A street stall logs 100 days: X = 1 on a wet day, 0 on a dry day;
# Y = umbrellas sold that day.  Profit = $8 per umbrella minus a $5 canopy fee
# on each wet day.  Covariance is reached four ways, the profit variance two.
COUNTS = [[30, 20, 8, 2],   # dry days: 0, 1, 2, 3 umbrellas sold
          [4, 8, 12, 16]]   # wet days
XS, YS = [0, 1], [0, 1, 2, 3]  # the values of X (rows) and Y (columns)
N, PRICE, FEE, SEED, DRAWS = 100, 8, 5, 2026, 10000

def moments(table, xs, ys): # road 1: margins, then E[XY] - E[X]E[Y]
    tot = sum(map(sum, table))
    p = [[k / tot for k in row] for row in table]
    I, J = range(len(xs)), range(len(ys))
    r = [sum(row) for row in p]
    c = [sum(p[i][j] for i in I) for j in J]
    ex = sum(xs[i] * r[i] for i in I)
    ey = sum(ys[j] * c[j] for j in J)
    vx = sum(xs[i] ** 2 * r[i] for i in I) - ex * ex
    vy = sum(ys[j] ** 2 * c[j] for j in J) - ey * ey
    exy = sum(xs[i] * ys[j] * p[i][j] for i in I for j in J)
    return r, c, ex, ey, vx, vy, exy, exy - ex * ey

r, c, ex, ey, vx, vy, exy, cov = moments(COUNTS, XS, YS)
sx, sy = vx ** 0.5, vy ** 0.5
rho = cov / (sx * sy)
days = [(x, y) for x in range(2) for y in range(4) for _ in range(COUNTS[x][y])]
mx = sum(d[0] for d in days) / N                     # road 2: the 100 days, centred
my = sum(d[1] for d in days) / N
cov_days = sum((x - mx) * (y - my) for x, y in days) / N
dry_avg = sum(j * COUNTS[0][j] for j in range(4)) / sum(COUNTS[0])
wet_avg = sum(j * COUNTS[1][j] for j in range(4)) / sum(COUNTS[1])
cov_yesno = vx * (wet_avg - dry_avg)                 # road 3: a yes/no X
profit = [PRICE * y - FEE * x for x, y in days]
pm = sum(profit) / N
var_days = sum((v - pm) ** 2 for v in profit) / N    # profit variance, brute force
var_formula = PRICE ** 2 * vy + FEE ** 2 * vx - 2 * PRICE * FEE * cov
var_no_cross = PRICE ** 2 * vy + FEE ** 2 * vx

state = SEED                                         # road 4: SplitMix64 draws
def draw():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    z ^= z >> 31
    return days[((z >> 11) * N) >> 53]               # one of the 100 days
sample = [draw() for _ in range(DRAWS)]
ax = sum(d[0] for d in sample) / DRAWS
ay = sum(d[1] for d in sample) / DRAWS
prods = [(x - ax) * (y - ay) for x, y in sample]
cov_sim = sum(prods) / DRAWS
se = (sum((q - cov_sim) ** 2 for q in prods) / (DRAWS - 1) / DRAWS) ** 0.5

indep = [[r[i] * c[j] * N for j in range(4)] for i in range(2)]
mi = moments(indep, XS, YS)
cov_indep = mi[7]
var_indep = PRICE ** 2 * mi[5] + FEE ** 2 * mi[4] - 2 * PRICE * FEE * cov_indep
WIND = [[0, 1], [1, 0], [0, 1]]   # rows W = -1, 0, +1; columns: upright, blown over (= W^2)
wr, wc, *_, cov_wind = moments(WIND, [-1, 0, 1], [0, 1])
both_calm = WIND[1][0] / 3                            # calm and upright: one day in three
calm_times_calm = wr[1] * wc[0]                       # what independence would give
dz = moments(COUNTS, XS, [y / 12 for y in YS])        # Y counted in dozens
dozens, rho_dz = dz[7], dz[7] / (dz[4] * dz[5]) ** 0.5

print("joint counts, dry row:", COUNTS[0], " wet row:", COUNTS[1])
print(f"margin of X (dry, wet): {r[0]:.2f}, {r[1]:.2f}")
print("margin of Y (0,1,2,3 sold):", ", ".join(f"{v:.2f}" for v in c))
print(f"E[X] = {ex:.4f}   E[Y] = {ey:.4f}   E[XY] = {exy:.4f}")
print(f"E[Y^2] = {vy + ey * ey:.4f}   E[Y]^2 = {ey * ey:.4f}   E[X]E[Y] = {ex * ey:.4f}")
print(f"Var(X) = {vx:.4f}   Var(Y) = {vy:.4f}")
print(f"sd(X) = {sx:.4f}   sd(Y) = {sy:.4f}")
print(f"covariance, road 1 (E[XY] - E[X]E[Y]):    {cov:.4f}")
print(f"covariance, road 2 (centred, 100 days):   {cov_days:.4f}")
print(f"average sold: dry days {dry_avg:.4f}, wet days {wet_avg:.4f}, gap {wet_avg - dry_avg:.4f}")
print(f"covariance, road 3 (Var(X) x gap):        {cov_yesno:.4f}")
print(f"covariance, road 4 (simulated, {DRAWS} days, seed {SEED}): {cov_sim:.4f}, standard error {se:.4f}")
print(f"correlation = {rho:.4f}")
print(f"profit: mean ${pm:.2f}")
print(f"profit variance, formula with cross term: {var_formula:.4f}  (sd ${var_formula ** 0.5:.4f})")
print(f"profit variance, brute force over 100 days: {var_days:.4f}")
print(f"pieces: 64 Var(Y) = {PRICE ** 2 * vy:.4f}, 25 Var(X) = {FEE ** 2 * vx:.4f}")
print(f"cross term 2 x 8 x (-5) x Cov = {-2 * PRICE * FEE * cov:.4f}")
print(f"mistake 1, cross term dropped: {var_no_cross:.4f}  (sd ${var_no_cross ** 0.5:.4f})")
print(f"mistake 2, E[XY] read as covariance: {exy:.4f}")
print(f"mistake 3, wind: Cov(W, W^2) = {cov_wind:.4f}; P(calm and upright) = {both_calm:.4f}"
      f" vs product {calm_times_calm:.4f}")
print(f"independent table (margins multiplied): Cov = {abs(cov_indep):.4f}, profit variance {var_indep:.4f}")
print(f"Var(X/sd + Y/sd) = 2 + 2 rho = {2 + 2 * rho:.4f};  Var(X/sd - Y/sd) = 2 - 2 rho = {2 - 2 * rho:.4f}")
print(f"try: umbrellas in dozens: Cov = {dozens:.4f}, correlation {rho_dz:.4f}")
print(f"try: fee $5 as a rainy-day bonus: variance {var_no_cross + 2 * PRICE * FEE * cov:.4f}")
print(f"try: no fee at all: variance {PRICE ** 2 * vy:.4f}")
pl = sorted((PRICE * y - FEE * x, COUNTS[x][y]) for x in range(2) for y in range(4))
print("figure, profit bars ($: days):", ", ".join(f"{v}: {k}" for v, k in pl))
print("figure, disc radii 3 x sqrt(days):", ", ".join(f"{3 * k ** 0.5:.1f}" for row in COUNTS for k in row))
assert abs(cov - cov_days) < 1e-12                                     # margins vs centred days
assert abs(cov - cov_yesno) < 1e-12                                    # vs the yes/no gap
assert abs(var_formula - var_days) < 1e-9                              # formula vs brute force
assert abs(cov_sim - cov) < 4 * se                                     # simulation, within 4 SE
assert abs(cov_indep) < 1e-12                                          # independence -> zero
assert abs(cov_wind) < 1e-12                                           # wind: zero covariance
assert both_calm - calm_times_calm > 0.2                               # ...yet dependent
assert abs(rho_dz - rho) < 1e-12 and abs(12 * dozens - cov) < 1e-12   # units: rho unchanged
print("ALL CHECKS PASS")
