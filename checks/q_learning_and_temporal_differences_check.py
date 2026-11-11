# Q-learning and temporal differences -- the check behind the card.  Standard
# library only.  A reservoir holds 0-4 units (1 unit = 10 million m3); each month
# it releases 0, 1 or 2 units, rain adds 0, 1 or 2.  Maximise discounted money,
# in GBP thousands.  Roads: (1) value iteration on the known model; (2) every one
# of the 54 rules, each solved exactly by elimination; (3) Q-learning from
# 20000 simulated months that never sees the model; (4) TD(0) against (2).
CAP, G, REV, SPILL, EMPTY = 4, 0.9, [0, 80, 120], 100, 120
RAIN = [(0, 0.3), (1, 0.4), (2, 0.3)]        # inflow units and their chances
M64 = (1 << 64) - 1
class SplitMix64:                            # the card's random numbers, seeded
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = ((self.x ^ (self.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
def acts(s): return range(min(s, 2) + 1)    # cannot release water not held
def step(s, a, w):                           # one month: release, rain, spill
    x = s - a + w
    s2 = min(x, CAP)
    return REV[a] - SPILL * max(x - CAP, 0) - (EMPTY if s2 == 0 else 0), s2
def best(Q, s):                              # greedy action, ties to less water
    b = 0
    for a in acts(s):
        if Q[s][a] > Q[s][b]: b = a
    return b
def backup(Q, s, a, g):                      # sum over rain of r + g max Q(s')
    tot = 0.0
    for w, p in RAIN:
        r, s2 = step(s, a, w)
        tot += p * (r + g * Q[s2][best(Q, s2)])
    return tot
def value_iteration(g):
    Q, k = [[0.0] * 3 for _ in range(5)], 0
    while True:
        N = [[backup(Q, s, a, g) if a <= s else 0.0 for a in range(3)] for s in range(5)]
        k, d = k + 1, max(abs(N[s][a] - Q[s][a]) for s in range(5) for a in acts(s))
        Q = N
        if d < 1e-9: return Q, k
def evaluate(pol):                           # solve (I - g P) V = r by elimination
    A = [[0.0] * 6 for _ in range(5)]
    for s in range(5):
        A[s][s] += 1.0
        for w, p in RAIN:
            r, s2 = step(s, pol[s], w)
            A[s][s2] -= G * p
            A[s][5] += p * r
    for c in range(5):
        piv = max(range(c, 5), key=lambda i: abs(A[i][c]))
        A[c], A[piv] = A[piv], A[c]
        for i in range(c + 1, 5):
            f = A[i][c] / A[c][c]
            A[i] = [A[i][j] - f * A[c][j] for j in range(6)]
    V = [0.0] * 5
    for i in range(4, -1, -1):
        V[i] = (A[i][5] - sum(A[i][j] * V[j] for j in range(i + 1, 5))) / A[i][i]
    return V
def learn(eps, seed, months, c=10, myopic=False, trace=0, marks=()):
    rng, s, earned = SplitMix64(seed), 2, 0.0
    Q, n, errs = [[0.0] * 3 for _ in range(5)], [[0] * 3 for _ in range(5)], []
    for t in range(1, months + 1):
        if rng.next() % 100 < eps: a = rng.next() % (min(s, 2) + 1)   # explore
        else: a = best(Q, s)                                           # exploit
        u = rng.next() % 10
        w = 0 if u < 3 else (1 if u < 7 else 2)
        r, s2 = step(s, a, w)
        earned += r
        n[s][a] += 1
        alpha = c / (c - 1 + n[s][a]) if c else 1.0 / n[s][a]
        target = r + (0.0 if myopic else G * Q[s2][best(Q, s2)])
        old = Q[s][a]
        Q[s][a] += alpha * (target - Q[s][a])
        if t <= trace:
            print(f"trace,{t},{s},{a},{w},{r},{s2},{old:.2f},{target:.2f},{alpha:.3f},{Q[s][a]:.2f}")
        if t in marks: errs.append((t, err(Q), max(abs(Q[x][PI[x]] - QS[x][PI[x]]) for x in range(5))))
        s = s2
    return Q, n, earned / months, errs
def err(Q): return max(abs(Q[s][a] - QS[s][a]) for s in range(5) for a in acts(s))
f2 = lambda v: f"{v:.2f}"
QS, sweeps = value_iteration(G)
PI = [best(QS, s) for s in range(5)]
for s in range(5):
    print(f"Q*,s={s}," + ",".join(f2(QS[s][a]) for a in acts(s)) + f",best={PI[s]}")
res = max(abs(backup(QS, s, a, G) - QS[s][a]) for s in range(5) for a in acts(s))
print(f"value iteration: {sweeps} sweeps from Q=0 to change < 1e-9; Bellman residual < 1e-6: {res < 1e-6}")
for w, p in RAIN:                                # by hand: targets at Q*, level 2, release 1
    r, s2 = step(2, 1, w)
    tg = r + G * QS[s2][PI[s2]]
    print(f"hand,rain {w},chance {p},next level {s2},target {tg:.2f},TD error {tg - QS[2][1]:.2f},weighted {p * tg:.2f}")
rules = [[0, a1, a2, a3, a4] for a1 in range(2) for a2 in range(3) for a3 in range(3) for a4 in range(3)]
vals = [evaluate(p) for p in rules]
top = max(range(len(rules)), key=lambda i: sum(vals[i]))
dom = all(vals[top][s] >= vals[i][s] - 1e-9 for i in range(len(rules)) for s in range(5))
gapv = max(abs(vals[top][s] - QS[s][PI[s]]) for s in range(5))
print(f"enumeration: {len(rules)} rules, best {rules[top]}, best in every state {dom}, matches value iteration {gapv < 1e-6}")
d = [0.2] * 5                                    # long-run share of months per level
for _ in range(2000):
    nd = [0.0] * 5
    for s in range(5):
        for w, p in RAIN: nd[step(s, PI[s], w)[1]] += d[s] * p
    d = nd
avg = sum(d[s] * p * step(s, PI[s], w)[0] for s in range(5) for w, p in RAIN)
print(f"best rule earns on average {avg:.2f} per month in the long run")
MARKS = (500, 1000, 2000, 5000, 10000, 20000)
Q, n, earned, errs = learn(10, 1, 20000, trace=6, marks=MARKS)
for s in range(5):
    print(f"learned,s={s}," + ",".join(f2(Q[s][a]) for a in acts(s)) + f",best={best(Q, s)}")
print("visits," + ",".join(f"{s}{a}:{n[s][a]}" for s in range(5) for a in acts(s)))
for t, e1, e2 in errs: print(f"error after {t} months: all pairs {e1:.2f}, chosen pairs {e2:.2f}")
LP = [best(Q, s) for s in range(5)]
print(f"learned rule {LP}, true rule {PI}, earned {earned:.2f} per month while learning")
for eps in (0, 10, 30, 100):
    q, _, e, _ = learn(eps, 1, 20000)
    right = sum(best(q, s) == PI[s] for s in range(5))
    print(f"explore {eps}%: earned {e:.2f}/month, short of best {avg - e:.2f}, max error {err(q):.2f}, "
          f"levels right {right}/5, rule {[best(q, s) for s in range(5)]}")
q1 = learn(10, 1, 20000, c=0)[0]
qm = learn(10, 1, 20000, myopic=True)[0]
pm = [best(qm, s) for s in range(5)]
print(f"break, step 1/n: max error {err(q1):.2f}; drop the future: rule {pm}, "
      f"worth {evaluate(pm)[2]:.2f} from level 2 against {QS[2][PI[2]]:.2f}")
print("seeds 2 and 3: max error " + ", ".join(f2(err(learn(10, sd, 20000)[0])) for sd in (2, 3)))
for g in (0.5, 0.99): print(f"gamma {g}: best rule {[best(value_iteration(g)[0], s) for s in range(5)]}")
HOLD1 = [min(s, 1) for s in range(5)]          # TD(0): judge 'release 1 if you can'
VE, V, nv, rng, s = evaluate(HOLD1), [0.0] * 5, [0] * 5, SplitMix64(7), 2
for t in range(20000):
    u = rng.next() % 10
    r, s2 = step(s, HOLD1[s], 0 if u < 3 else (1 if u < 7 else 2))
    nv[s] += 1
    V[s] += 10 / (9 + nv[s]) * (r + G * V[s2] - V[s])
    s = s2
print("TD(0) release-1 rule: exact " + ",".join(map(f2, VE)) + "; TD " + ",".join(map(f2, V)))
tde = max(abs(V[s] - VE[s]) for s in range(5))
print(f"TD(0) max error {tde:.2f}")
assert res < 1e-6 and dom and gapv < 1e-6 and rules[top] == PI      # road 1 = road 2
assert LP == PI and errs[-1][2] < 0.05 * QS[2][PI[2]]                # road 3 agrees
assert err(learn(0, 1, 20000)[0]) > 100 and pm != PI                 # the breaks bite
assert tde < 0.05 * min(VE)                                          # road 4 agrees
print("ALL CHECKS PASS")
