# Regret -- the check behind the card.  Nothing is imported but math.  Four
# routes to work, twenty mornings, delays in minutes.  The weighted-majority
# rule (randomised form: pick a route with chance in proportion to its weight,
# shrink each weight by e^(-eta x loss)) is run and its regret is compared with
# the bound ln N / eta + eta T / 8 and with rules that fail.
import math
ROUTES, CAP = ["bus", "train", "bike", "car"], 20      # a loss is delay / 20 minutes
DELAY = [[6, 8, 5, 9, 7, 6, 10, 5, 8, 7, 6, 9, 5, 7, 8, 6, 7, 9, 6, 8],
         [1, 2, 0, 1, 2, 18, 20, 16, 19, 17, 2, 1, 0, 2, 1, 1, 2, 0, 1, 2],
         [4, 4, 5, 4, 12, 4, 5, 4, 4, 13, 4, 5, 4, 4, 14, 4, 5, 4, 4, 4],
         [9, 11, 8, 12, 10, 9, 13, 10, 11, 9, 10, 12, 8, 9, 11, 10, 9, 12, 10, 11]]
N, T = len(ROUTES), len(DELAY[0])
M64 = (1 << 64) - 1

def splitmix(state):                     # SplitMix64: next state, and a uniform in [0, 1)
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def play(eta, rounds, n, nature, leader=False):
    # road one: each weight read off the running total, w_i = e^(-eta L_i);
    # leader=True follows the route with the smallest total (eta -> infinity)
    tot, alg, probs, regret = [0.0] * n, 0.0, [], []
    for t in range(rounds):
        if leader:
            j = tot.index(min(tot))
            p = [1.0 if i == j else 0.0 for i in range(n)]
        else:
            low = min(tot)
            w = [math.exp(-eta * (x - low)) for x in tot]
            p = [x / sum(w) for x in w]
        loss = nature(t, p)
        alg += sum(a * b for a, b in zip(p, loss))
        tot = [a + b for a, b in zip(tot, loss)]
        probs.append(p)
        regret.append(alg - min(tot))
    return probs, alg, tot, regret

def commute(t, p):
    return [DELAY[i][t] / CAP for i in range(N)]

def alternating(t, p):                   # two routes: half a loss, then 1 and 0 in turn
    return [0.5, 0.0] if t == 0 else ([0.0, 1.0] if t % 2 == 1 else [1.0, 0.0])

def spiteful(t, p):                      # the hold-up lands on the likeliest route
    j = p.index(max(p))
    return [1.0 if i == j else 0.0 for i in range(len(p))]

def iterate(eta):                        # road two: multiply each weight in, morning by morning
    w, alg = [1.0] * N, 0.0
    for t in range(T):
        alg += sum(w[i] * DELAY[i][t] / CAP for i in range(N)) / sum(w)
        w = [w[i] * math.exp(-eta * DELAY[i][t] / CAP) for i in range(N)]
    return alg, w

def bound(eta, t, n):
    return math.log(n) / eta + eta * t / 8

eta = math.sqrt(8 * math.log(N) / T)
probs, alg, tot, regret = play(eta, T, N, commute)
alg2, w_end = iterate(eta)
best = min(range(N), key=lambda i: tot[i])
print("route totals, minutes: " + ", ".join(f"{r} {sum(d)}" for r, d in zip(ROUTES, DELAY)))
print(f"best single route in hindsight: {ROUTES[best]}, {tot[best] * CAP:.0f} minutes")
print(f"train's bad week, mornings 6 to 10: {sum(DELAY[1][5:10])} minutes; train, morning 6: loss {DELAY[1][5] / CAP:.4f}")
print(f"L* = {tot[best]:.4f} losses, rule {alg:.4f} losses, ln {N} = {math.log(N):.4f}")
print(f"eta = sqrt(8 ln {N} / {T}) = {eta:.4f}")
for t in (0, 1, 19):
    exp_delay = sum(p * DELAY[i][t] for i, p in enumerate(probs[t]))
    print(f"morning {t + 1}: chances " + " ".join(f"{p:.4f}" for p in probs[t]) + f", expected delay {exp_delay:.4f} min")
w1 = [math.exp(-eta * DELAY[i][0] / CAP) for i in range(N)]
print("weights after morning 1: " + " ".join(f"{x:.4f}" for x in w1) + f", sum {sum(w1):.4f}")
print(f"weighted majority, expected total: {alg * CAP:.2f} minutes (road two, multiplied in: {alg2 * CAP:.2f})")
print(f"regret R_T = {alg * CAP:.2f} - {tot[best] * CAP:.0f} = {regret[-1] * CAP:.2f} minutes")
print(f"bound ln {N}/eta + eta T/8 = {bound(eta, T, N):.4f} losses = {bound(eta, T, N) * CAP:.2f} minutes")
print(f"bound per morning: {bound(eta, T, N) * CAP / T:.2f} minutes; regret per morning {regret[-1] * CAP / T:.2f}")
phi = math.log(sum(w_end) / N)
print(f"potential ln(W/N) = {phi:.4f}, floor -eta L* - ln N = {-eta * tot[best] - math.log(N):.4f}, "
      f"ceiling -eta rule + eta^2 T/8 = {-eta * alg + eta * eta * T / 8:.4f}")
state, runs, sums, squares = 2026, 10000, 0.0, 0.0
for _ in range(runs):                    # road three: really toss the coin, 10,000 months
    month = 0
    for t in range(T):
        state, u = splitmix(state)
        i, acc = 0, probs[t][0]
        while u >= acc and i < N - 1:
            i += 1
            acc += probs[t][i]
        month += DELAY[i][t]
    sums, squares = sums + month, squares + month * month
mean = sums / runs
sd = math.sqrt(squares / runs - mean * mean)
se = sd / math.sqrt(runs)
print(f"simulated months: {runs}, mean total {mean:.2f} minutes, one month's spread {sd:.2f}, standard error {se:.2f}")
daily_best = sum(min(DELAY[i][t] for i in range(N)) for t in range(T))
print(f"mistake, best route each morning instead: {daily_best} minutes, gap {alg * CAP - daily_best:.2f}")
print(f"eta = 0.01 on the month: regret {play(0.01, T, N, commute)[3][-1] * CAP:.2f} minutes")
print(f"eta = 20 on alternating mornings: regret {play(20.0, T, 2, alternating)[3][-1]:.4f}")
_, fa, ft, fr = play(0, T, 2, alternating, leader=True)
eta2 = math.sqrt(8 * math.log(2) / T)
hr = play(eta2, T, 2, alternating)[3][-1]
print(f"alternating mornings: leader loses {fa:.1f}, best route {min(ft):.1f}, regret {fr[-1]:.1f} "
      f"= {fr[-1] * CAP:.0f} minutes; weighted majority regret {hr:.4f}")
_, sa, st, sr = play(0, T, N, spiteful, leader=True)
hs = play(eta, T, N, spiteful)[3][-1]
print(f"spiteful mornings: leader regret {sr[-1]:.1f} of {T} = {sr[-1] * CAP:.0f} minutes (T(1 - 1/N) = {T * (1 - 1 / N):.1f}); "
      f"weighted majority regret {hs:.4f}")
T2 = 240
eta3 = math.sqrt(8 * math.log(N) / T2)
lr, hr2 = play(0, T2, N, spiteful, leader=True)[3], play(eta3, T2, N, spiteful)[3]
for t in range(30, T2 + 1, 30):
    print(f"chart, t = {t}: leader {lr[t - 1]:.1f}, weighted majority {hr2[t - 1]:.2f}, bound {bound(eta3, t, N):.2f}")
row = [1]                                # Pascal's triangle, row 20
for _ in range(T):
    row = [1] + [row[k] + row[k + 1] for k in range(len(row) - 1)] + [1]
floor_sum = sum(c * abs(k - T / 2) for k, c in enumerate(row)) / 2 ** T
floor_closed = T / 2 * math.comb(T, T // 2) / 2 ** T
print(f"fair-coin mornings, two routes: every rule's expected regret {floor_sum:.4f} "
      f"(closed form {floor_closed:.4f}, about sqrt(T/2pi) = {math.sqrt(T / (2 * math.pi)):.4f}); "
      f"bound {math.sqrt(T * math.log(2) / 2):.4f}")
print(f"in minutes: floor {floor_sum * CAP:.2f}, bound {math.sqrt(T * math.log(2) / 2) * CAP:.2f}")
assert abs(alg - alg2) < 1e-9                                  # two roads to the weights
assert abs(mean - alg * CAP) < 4 * se                          # the coin, really tossed
assert all(r <= bound(eta, t + 1, N) for t, r in enumerate(regret))   # the theorem, every prefix
assert all(r <= bound(eta2, t + 1, 2) for t, r in enumerate(play(eta2, T, 2, alternating)[3]))  # and on the hostile runs
assert all(r <= bound(eta3, t + 1, N) for t, r in enumerate(hr2))
assert -eta * tot[best] - math.log(N) <= phi <= -eta * alg + eta * eta * T / 8
assert abs(fr[-1] - T / 2) < 1e-9 and abs(sr[-1] - T * (1 - 1 / N)) < 1e-9
assert abs(floor_sum - floor_closed) < 1e-12 and floor_sum <= math.sqrt(T * math.log(2) / 2)
print("ALL CHECKS PASS")
