# Backward induction on a hydro reservoir -- the check behind the card.  Standard library only.
# Water in units of 10 million m3, money in GBP thousand.  Months k = 0 (Jan) .. 11 (Dec); k = 12 is 31 Dec.
# Roads: (1) backward induction; (2) the read-off rule run forward over every rain outcome;
# (3) every storage-to-release rule for Oct-Dec listed and scored, the best compared with the table;
# (4) every one-month change to the rule, followed by the rule, scored by running forward: none may gain.
from itertools import product

MONTHS = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()
PRICE = [150, 140, 120, 100, 90, 80, 85, 90, 100, 115, 140, 150]  # GBP thousand per unit released
WET, DRY = (0.2, 0.5, 0.3), (0.5, 0.4, 0.1)                        # chance of 0, 1, 2 units of rain
RAIN = [WET] * 3 + [DRY] * 6 + [WET] * 3
CAP, TURBINE, END_VALUE, START = 4, 2, 100, 2                      # units, units a month, GBP k a unit, units

def total(terms):                       # plain left-to-right sum, the same order as the Rust check
    s = 0.0
    for t in terms:
        s += t
    return s

def nxt(x, u, w):                       # storage next month; anything above CAP spills
    return min(x - u + w, CAP)

def backup(V1, k, x, u, rain, price):   # this month's income plus the average value of next month's storage
    return price[k] * u + total(p * V1[nxt(x, u, w)] for w, p in enumerate(rain[k]))

def solve(price=PRICE, rain=RAIN, end=END_VALUE, turbine=TURBINE, see_rain=False):
    V = [[0.0] * (CAP + 1) for _ in range(13)]
    rule = [[0] * (CAP + 1) for _ in range(12)]
    V[12] = [float(end * x) for x in range(CAP + 1)]
    for k in range(11, -1, -1):                       # December first, then back
        for x in range(CAP + 1):
            choices = range(min(x, turbine) + 1)
            if see_rain:                              # wrong: choose after the rain is known
                V[k][x] = total(p * max(price[k] * u + V[k + 1][nxt(x, u, w)] for u in choices)
                              for w, p in enumerate(rain[k]))
                continue
            best, best_u = -1.0, 0
            for u in choices:                         # ties keep the smaller release
                q = backup(V[k + 1], k, x, u, rain, price)
                if q > best + 1e-9:
                    best, best_u = q, u
            V[k][x], rule[k][x] = best, best_u
    return V, rule

def run_forward(rule, x0, first=0, end=END_VALUE):    # road 2: carry the storage distribution forward
    dist, income = [1.0 if x == x0 else 0.0 for x in range(CAP + 1)], 0.0
    for k in range(first, 12):
        new = [0.0] * (CAP + 1)
        for x in range(CAP + 1):
            u = rule[k][x]
            income += dist[x] * PRICE[k] * u
            for w, p in enumerate(RAIN[k]):
                new[nxt(x, u, w)] += dist[x] * p
        dist = new
    return income + total(dist[x] * end * x for x in range(CAP + 1))

V, rule = solve()
print("December backups, 31 Dec water worth 100 a unit:")
for x in range(CAP + 1):
    qs = "  ".join(f"u={u}: {backup(V[12], 11, x, u, RAIN, PRICE):6.2f}" for u in range(min(x, TURBINE) + 1))
    print(f"  x={x}  {qs}")
qs = "  ".join(f"u={u}: {backup(V[11], 10, 2, u, RAIN, PRICE):6.2f}" for u in range(3))
print(f"November, x=2  {qs}")
print("month price | release for x=0..4 | value V_k(x) for x=0..4")
for k in range(12):
    print(f"{MONTHS[k]} {PRICE[k]:5d} | {' '.join(str(u) for u in rule[k])} | "
          + " ".join(f"{v:7.2f}" for v in V[k]))
print("31 Dec      |           | " + " ".join(f"{v:7.2f}" for v in V[12]))

best = V[0][START]
forward = run_forward(rule, START)
print(f"road 1, backward induction, V_0(2)      {best:9.2f}")
print(f"road 2, rule run forward over the rain  {forward:9.2f}")
assert abs(best - forward) < 1e-6
gain = 0.0                                        # road 4: change one month's release, then follow the rule
for k, x in product(range(12), range(CAP + 1)):
    for u in range(min(x, TURBINE) + 1):
        dev = PRICE[k] * u + total(p * run_forward(rule, nxt(x, u, w), first=k + 1) for w, p in enumerate(RAIN[k]))
        gain = max(gain, dev - run_forward(rule, x, first=k))
print(f"road 4, largest gain, one-month change  {gain:9.4f}")
assert gain < 1e-6

tables = list(product(*[range(min(x, TURBINE) + 1) for x in range(CAP + 1)]))
print(f"rules per month {len(tables)}; whole-year rule tables {len(tables) ** 12}")
top = [-1.0] * (CAP + 1)
for r9, r10, r11 in product(tables, repeat=3):  # road 3: score every Oct-Dec rule table
    W = [float(END_VALUE * x) for x in range(CAP + 1)]
    for k, r in ((11, r11), (10, r10), (9, r9)):
        W = [backup(W, k, x, r[x], RAIN, PRICE) for x in range(CAP + 1)]
    top = [max(a, b) for a, b in zip(top, W)]
print(f"road 3, best of {len(tables) ** 3} Oct-Dec tables: " + " ".join(f"{v:.2f}" for v in top))
assert all(abs(top[x] - V[9][x]) < 1e-6 for x in range(CAP + 1))
assert abs(V[11][2] - (300 + 100 * (0.5 * 1 + 0.3 * 2))) < 1e-9   # December by hand: release 2, keep the rain
assert abs(backup(V[12], 11, 4, 0, RAIN, PRICE) - 400) < 1e-9     # December by hand: full, release 0, all rain spills

story_rain = [2, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 2]
x, income, line_x, line_u = START, 0, [], []
for k in range(12):
    u = rule[k][x]
    line_x.append(x); line_u.append(u); income += PRICE[k] * u
    x = nxt(x, u, story_rain[k])
print("story rain    " + " ".join(map(str, story_rain)))
print("story storage " + " ".join(map(str, line_x)) + f"  -> {x} on 31 Dec")
print("story release " + " ".join(map(str, line_u)) + f"  income {income}, plus {END_VALUE * x} in store")

greedy = run_forward([[min(x, TURBINE) for x in range(CAP + 1)] for _ in range(12)], START)
see, _ = solve(see_rain=True)
_, rule0 = solve(end=0)
mode = [tuple(1.0 if w == max(range(3), key=lambda i: r[i]) else 0.0 for w in range(3)) for r in RAIN]
Vm, rule_m = solve(rain=mode)
rows = [("wrong: release all the turbine takes", greedy),
        ("wrong: choose after seeing the rain", see[0][START]),
        ("wrong: water left on 31 Dec worth 0", run_forward(rule0, START)),
        ("wrong: most likely rain, promised", Vm[0][START]),
        ("wrong: most likely rain, delivered", run_forward(rule_m, START))]
for name, v in rows:
    print(f"{name:<40}{v:9.2f}")
assert greedy < best - 1
assert see[0][START] > best + 1
assert rows[2][1] < best - 1
assert rows[4][1] < best - 1

tries = [("try: end value 0, plan and score", solve(end=0)[0][0][START]),
         ("try: turbine 1 unit a month", solve(turbine=1)[0][0][START]),
         ("try: every month wet", solve(rain=[WET] * 12)[0][0][START]),
         ("try: July price 200", solve(price=PRICE[:6] + [200] + PRICE[7:])[0][0][START])]
for name, v in tries:
    print(f"{name:<40}{v:9.2f}")
print("end value 0, Sep and Oct release for x=0..4: " + " ".join(map(str, rule0[8])) + " | " + " ".join(map(str, rule0[9])))
print("ALL CHECKS PASS")
