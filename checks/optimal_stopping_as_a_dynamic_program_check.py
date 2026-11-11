# Optimal stopping as a dynamic program -- the check behind the card.  Standard library only.
# One block of stored water (10 million m3) and a forward price x for it, GBP thousand, on the grid
# 60, 70, ..., 140.  Each month the price moves 10 up or 10 down, pulled toward 100; at the ends of the
# grid the blocked move becomes "stay".  Storing costs C a month.  Months k = 0 (1 June) .. N = 6
# (1 December), when the block must be sold.  Maximise the average sale price minus storage costs.
# Roads: (1) backward induction; (2) the rule run forward over every price path; (3) every stop set for
# October and November listed and scored; (4) a simulation with SplitMix64, seed 20261111.
X = [60 + 10 * i for i in range(9)]
MONTHS = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
N, C, PULL, START = 6, 1.0, 0.02, 2           # months, GBP k a month, pull per step, start at x = 80

def moves(i, pull=PULL):                      # (next index, chance): down, up; a blocked move stays put
    up, dn = 0.5 - pull * (i - 4), 0.5 + pull * (i - 4)
    if i == 0: return [(0, dn), (1, up)]
    if i == 8: return [(7, dn), (8, up)]
    return [(i - 1, dn), (i + 1, up)]

def tot(terms):                               # plain left-to-right sum, the same order as the Rust check
    s = 0.0
    for t in terms: s += t
    return s

def wait_value(V1, i, c, pull):               # pay a month's storage, then the average of next month
    return tot(q * V1[j] for j, q in moves(i, pull)) - c

def solve(c=C, pull=PULL, n=N):
    V = [None] * (n + 1); W = [None] * n; stop = [None] * n
    V[n] = [float(x) for x in X]              # 1 December: sell at whatever the price is
    for k in range(n - 1, -1, -1):
        W[k] = [wait_value(V[k + 1], i, c, pull) for i in range(9)]
        stop[k] = [X[i] >= W[k][i] for i in range(9)]
        V[k] = [max(X[i], W[k][i]) for i in range(9)]
    return V, W, stop

def run_forward(stop, i0, c=C, n=N):         # road 2: carry the chance of each unsold price forward
    mass, value, sold = [0.0] * 9, 0.0, []
    mass[i0] = 1.0
    for k in range(n + 1):
        here = tot(mass[i] for i in range(9) if k == n or stop[k][i])
        value += tot(mass[i] * (X[i] - c * k) for i in range(9) if k == n or stop[k][i])
        sold.append(here)
        nxt = [0.0] * 9
        for i in range(9):
            if k < n and not stop[k][i]:
                for j, q in moves(i): nxt[j] += q * mass[i]
        mass = nxt
    return value, sold

V, W, stop = solve()
bar = [min(X[i] for i in range(9) if stop[k][i]) for k in range(N)]
print("price x            " + " ".join(f"{x:7d}" for x in X))
print("chance of a rise   " + " ".join(f"{moves(i)[-1][1]:7.2f}" for i in range(9)))
print("month  bar | value V_k(x), GBP k")
for k in range(N):
    assert all(stop[k][i] == (X[i] >= bar[k]) for i in range(9))     # the stop set is one threshold
    print(f"{MONTHS[k]}  {bar[k]:5d} | " + " ".join(f"{v:7.2f}" for v in V[k]))
print(f"Dec   sell | " + " ".join(f"{v:7.2f}" for v in V[N]))
print("Nov wait values  " + " ".join(f"{w:6.2f}" for w in W[5]))
print("Jun wait values  " + " ".join(f"{w:6.2f}" for w in W[0]))
print("Jun gap W_0(x)-x " + " ".join(f"{W[0][i] - X[i]:6.2f}" for i in range(9)))
for i in (2, 3, 4): print(f"wait value at x={X[i]}, Jun..Nov  " + " ".join(f"{W[k][i]:6.2f}" for k in range(N)))
assert abs(W[5][2] - (0.46 * 70 + 0.54 * 90 - 1)) < 1e-9 and abs(W[5][3] - (0.48 * 80 + 0.52 * 100 - 1)) < 1e-9
best = V[0][START]
fwd, sold = run_forward(stop, START)
print(f"road 1, backward induction, V_0(80)       {best:8.3f}")
print(f"road 2, rule run forward over the prices  {fwd:8.3f}")
assert abs(best - fwd) < 1e-9
print("chance of selling in " + " ".join(f"{m} {s:.3f}" for m, s in zip(MONTHS, sold)))
held = tot(k * s for k, s in enumerate(sold))
print(f"average months held {held:.3f}, average sale price {best + C * held:.3f}")
top = [-1e9] * 9                               # road 3: every stop set for Oct and Nov
for a in range(512):
    for b in range(512):
        s4 = [a >> i & 1 for i in range(9)]; s5 = [b >> i & 1 for i in range(9)]
        v5 = [X[i] if s5[i] else wait_value(V[N], i, C, PULL) for i in range(9)]
        for i in range(9):
            v4 = X[i] if s4[i] else wait_value(v5, i, C, PULL)
            if v4 > top[i]: top[i] = v4
print("road 3, best of 262144 Oct-Nov rules: " + " ".join(f"{v:.2f}" for v in top))
assert all(abs(top[i] - V[4][i]) < 1e-9 for i in range(9))
MASK = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = s; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, (z ^ (z >> 31)) >> 11
seed, total, total2, R = 20261111, 0.0, 0.0, 200000
for _ in range(R):                             # road 4: simulate sellers who follow the rule
    i, k = START, 0
    while k < N and not stop[k][i]:
        seed, r = splitmix(seed)
        i = moves(i)[-1][0] if r / 2.0 ** 53 < moves(i)[-1][1] else moves(i)[0][0]
        k += 1
    g = X[i] - C * k; total += g; total2 += g * g
mean = total / R; se = ((total2 / R - mean * mean) / (R - 1)) ** 0.5
print(f"road 4, {R} simulated sellers   {mean:8.3f}  (standard error {se:.3f})")
assert abs(mean - best) < 4 * se
story = [80, 70, 80, 90, 80, 90]
k = 0
while k < N and story[k] < bar[k]: k += 1
print("story: prices " + " ".join(map(str, story)) + f"; sold in {MONTHS[k]} at {story[k]}, net {story[k] - C * k:.0f}")
print("rule's sale in Aug at 80?", stop[2][2], "| in Oct at 80?", stop[4][2])
never = [[False] * 9 for _ in range(N)]
hold = run_forward(never, START)[0]
myopic = [[X[i] >= wait_value(X, i, C, PULL) for i in range(9)] for _ in range(N)]
fixed = max((run_forward([[x >= t for x in X] for _ in range(N)], START)[0], t) for t in X)
def prophet(k, i, best_so_far):                # sees the whole price path, then picks the best month
    g = max(best_so_far, X[i] - C * k)
    return g if k == N else tot(q * prophet(k + 1, j, g) for j, q in moves(i))
pi = [1.0] * 9                                 # the long-run spread of prices, from balance up = down
for i in range(8): pi[i + 1] = pi[i] * moves(i)[-1][1] / moves(i + 1)[0][1]
z = tot(pi); pi = [p / z for p in pi]
Vi = [tot(p * x for p, x in zip(pi, X)) - C]   # wrong model: each month a fresh price from that spread
for _ in range(N - 1): Vi.append(tot(p * max(x, Vi[-1]) for p, x in zip(pi, X)) - C)
indep = [[X[i] >= Vi[N - 1 - k] for i in range(9)] for k in range(N)]
rows = [("wrong: sell on 1 June", float(X[START])),
        ("wrong: hold to 1 December", hold),
        ("wrong: look one month ahead only", run_forward(myopic, START)[0]),
        (f"wrong: best fixed bar ({fixed[1]})", fixed[0]),
        ("wrong: fresh price each month, delivered", run_forward(indep, START)[0]),
        ("wrong: prophet who sees the whole path", prophet(0, START, -1e9))]
for name, v in rows: print(f"{name:<42}{v:8.3f}")
assert all(v < best - 0.02 for _, v in rows[:5]) and rows[5][1] > best + 0.5
print("fresh-price model's bars " + " ".join(f"{v:.2f}" for v in Vi[::-1]))
for name, (c, pull, n) in [("try: no storage cost", (0.0, PULL, N)), ("try: no pull to 100", (C, 0.0, N)),
                           ("try: a 12-month season", (C, PULL, 12)), ("try: cost 3 a month", (3.0, PULL, N))]:
    Vt, _, st = solve(c, pull, n)
    bars = [min([X[i] for i in range(9) if st[k][i]]) for k in range(n)]
    print(f"{name:<24}V_0(80) {Vt[0][START]:7.3f}  bars " + " ".join(map(str, bars)))
print("chart, V_0(x) and V_5(x): " + " ".join(f"{v:.2f}" for v in V[0]) + " | " + " ".join(f"{v:.2f}" for v in V[5]))
print("ALL CHECKS PASS")
